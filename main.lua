-- Name Tags
-- Gives each Pokémon you catch a random nickname from the lists in names/,
-- so every catch is someone without you having to think up a name.
-- Gen 1: the catch.nickname hook answers "Do you want to give a nickname?"
-- for the player, so no question is asked.
-- Gen 2 and Gen 3 have no call site for that hook yet, so the name goes on in
-- pokemon.caught, before the game asks, and NICKNAME QUESTION answers NO for
-- the player through mod.input. If a later engine raises catch.nickname there
-- too, the question goes away on its own with no change here.
-- Names can follow gender: [male], [female] and [neutral] sections, with
-- genderless Pokémon drawing neutral names only. Gen 1 uses the Gen 2 rule.
-- Gifts go through pokemon.before_give (Gen 1 and Gen 3) when GIFTS is AUTO.
-- In-game trades keep their own names, and the Name Rater still works as usual.
-- ------------------

-- Each .txt file in names/ is a set the player can switch off. Inside a file:
--   [all]                   names any Pokémon can get
--   [type FIRE]             names only for that type
--   [species NINETALES]     names only for those species
-- A header can list several ids. Lines starting with # are notes.
local NAMES_DIR = "names"

-- The naming screen's limit in all three generations, and the one
-- catch.nickname clips to (BattleState:offerNickname in src/battle/BattleState.lua).
local MAX_LEN = 10

-- Chance a themed pool is tried before the general one, per THEMED NAMES.
local THEME_WEIGHTS = {
  sometimes = { species = 0.15, type = 0.25 },
  often = { species = 0.35, type = 0.40 },
}

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Species ids differ in spelling between games (MR_MIME on Gen 1 and Gen 3,
-- MR__MIME on Gen 2), so they're compared with only letters and digits kept.
local function speciesKey(id)
  if id == nil then return nil end
  return (tostring(id):upper():gsub("[^%w]", ""))
end

-- Gen 1 calls the type PSYCHIC_TYPE; Gen 2 and Gen 3 call it PSYCHIC.
local function typeKey(id)
  if id == nil then return nil end
  return (tostring(id):upper():gsub("_TYPE$", ""))
end

-- Letters and single inner hyphens only: every generation's font has every
-- letter in both cases, and a hyphen, but nothing that reads as a screen name.
local function validName(name)
  if #name < 1 or #name > MAX_LEN then return false, "longer than 10 letters" end
  if not name:match("^[A-Za-z][A-Za-z%-]*[A-Za-z]$") and not name:match("^[A-Za-z]$") then
    return false, "only letters and an inner hyphen are allowed"
  end
  if name:find("%-%-") then return false, "two hyphens in a row" end
  return true
end

local function newLibrary()
  return { sets = {}, order = {}, rejected = {} }
end

-- Gender sections: [male], [female], and [neutral] for names that suit anyone.
-- nonbinary and unisex are read as neutral.
local GENDER_HEADERS = { male = "male", female = "female", neutral = "neutral",
  nonbinary = "neutral", unisex = "neutral" }

local function newSet()
  return { all = {}, types = {}, species = {}, seen = {}, count = 0, defaultOn = true,
    gender = { male = {}, female = {}, neutral = {} }, trainers = {} }
end

local function addName(set, list, name)
  set.seen[list] = set.seen[list] or {}
  local key = name:upper()
  if set.seen[list][key] then return end
  set.seen[list][key] = true
  list[#list + 1] = name
  set.count = set.count + 1
end

-- Parse one list file into its set. Bad lines go to lib.rejected with their
-- file and line, so the log can point at them.
local function parseList(lib, text, fileName, setId)
  local set = lib.sets[setId]
  if not set then
    set = newSet()
    lib.sets[setId] = set
    lib.order[#lib.order + 1] = setId
  end
  local targets = { set.all }
  local lineNo = 0
  for raw in (text .. "\n"):gmatch("([^\n]*)\n") do
    lineNo = lineNo + 1
    local line = trim((raw:gsub("\r$", "")))
    if line:match("^#!%s*default%s+off%s*$") then
      -- a set that starts switched off (pop culture, memes)
      set.defaultOn = false
    elseif line == "" or line:sub(1, 1) == "#" then
      -- blank or a note
    elseif line:sub(1, 1) == "[" then
      local kind, rest = line:match("^%[%s*(%a+)%s*(.-)%s*%]$")
      kind = kind and kind:lower()
      targets = {}
      if kind == "all" then
        targets[1] = set.all
      elseif kind and GENDER_HEADERS[kind] and rest == "" then
        targets[1] = set.gender[GENDER_HEADERS[kind]]
      elseif kind == "trainer" then
        -- [trainer Lt. Surge: PIKACHU PICHU RAICHU]: a battled trainer's own
        -- Pokémon. The first species is the one the name belongs to.
        local who, ids = rest:match("^(.-)%s*:%s*(.+)$")
        if who and who ~= "" then
          local entry = { trainer = who, key = speciesKey(who), species = {}, names = {} }
          for id in ids:gmatch("[^%s,]+") do entry.species[#entry.species + 1] = speciesKey(id) end
          if #entry.species > 0 then
            set.trainers[#set.trainers + 1] = entry
            targets[1] = entry.names
          end
        end
      elseif kind == "type" or kind == "species" then
        local bucket = kind == "type" and set.types or set.species
        for id in rest:gmatch("[^%s,]+") do
          local key = kind == "type" and typeKey(id) or speciesKey(id)
          bucket[key] = bucket[key] or {}
          targets[#targets + 1] = bucket[key]
        end
      end
      if #targets == 0 then
        lib.rejected[#lib.rejected + 1] = ("%s:%d: unknown header %s"):format(fileName, lineNo, line)
      end
    else
      local ok, why = validName(line)
      if not ok then
        lib.rejected[#lib.rejected + 1] = ("%s:%d: %s (%s)"):format(fileName, lineNo, line, why)
      else
        for _, list in ipairs(targets) do addName(set, list, line) end
      end
    end
  end
  return lib
end

-- The switched-on sets merged into one set of pools.
local function combine(lib, enabled)
  local pools = { all = {}, types = {}, species = {},
    gender = { male = {}, female = {}, neutral = {} }, trainers = {} }
  local function append(into, list)
    for _, name in ipairs(list) do into[#into + 1] = name end
  end
  for _, setId in ipairs(lib.order) do
    if enabled == nil or enabled(setId) then
      local set = lib.sets[setId]
      append(pools.all, set.all)
      append(pools.trainers, set.trainers)
      for g, list in pairs(set.gender) do append(pools.gender[g], list) end
      for key, list in pairs(set.types) do
        pools.types[key] = pools.types[key] or {}
        append(pools.types[key], list)
      end
      for key, list in pairs(set.species) do
        pools.species[key] = pools.species[key] or {}
        append(pools.species[key], list)
      end
    end
  end
  return pools
end

-- Every nickname already worn by a Pokémon you have, in capitals. Walks the
-- party, the boxes and the Day-Care wherever this game keeps them.
local STORAGE_KEYS = { "party", "boxes", "box", "daycare", "dayCare", "pc", "storage" }
local function namesInUse(...)
  local used, visited = {}, {}
  local function walk(t, depth)
    if type(t) ~= "table" or visited[t] or depth > 4 then return end
    visited[t] = true
    if t.species ~= nil and type(t.nickname) == "string" and t.nickname ~= "" then
      used[t.nickname:upper()] = true
      return
    end
    for _, v in pairs(t) do walk(v, depth + 1) end
  end
  for i = 1, select("#", ...) do
    local root = select(i, ...)
    if type(root) == "table" then
      if root.species ~= nil or root[1] ~= nil then
        walk(root, 0)
      else
        for _, key in ipairs(STORAGE_KEYS) do walk(root[key], 0) end
      end
    end
  end
  return used
end

local function unused(list, used, out)
  out = out or {}
  for _, name in ipairs(list or {}) do
    if not used[name:upper()] then out[#out + 1] = name end
  end
  return out
end

-- Which gender sections a Pokémon can draw from. A genderless one gets
-- neutral names only; an unknown gender (MATCH GENDER off) gets all three.
local GENDER_POOLS = {
  male = { "male", "neutral" }, female = { "female", "neutral" },
  none = { "neutral" }, unknown = { "male", "female", "neutral" },
}

-- Pick a name. types is a list of type ids; gender is male, female, none or
-- nil; rand() returns a float in [0, 1). Returns nil only when every
-- switched-on list is empty.
local function pickName(pools, species, types, used, themed, rand, gender)
  local weights = THEME_WEIGHTS[themed] or THEME_WEIGHTS.sometimes
  local speciesPool = unused(pools.species[speciesKey(species)], used)
  local typePool, seenType = {}, {}
  for _, t in ipairs(types or {}) do
    local key = typeKey(t)
    if not seenType[key] then
      seenType[key] = true
      unused(pools.types[key], used, typePool)
    end
  end
  local function from(list) return list[math.floor(rand() * #list) + 1] end

  local roll = rand()
  if #speciesPool > 0 and roll < weights.species then return from(speciesPool) end
  if #typePool > 0 and roll < weights.species + weights.type then return from(typePool) end
  local everyone = {}
  for _, name in ipairs(pools.all) do everyone[#everyone + 1] = name end
  for _, g in ipairs(GENDER_POOLS[gender or "unknown"] or GENDER_POOLS.unknown) do
    for _, name in ipairs(pools.gender and pools.gender[g] or {}) do everyone[#everyone + 1] = name end
  end
  local general = unused(everyone, used)
  if #general > 0 then return from(general) end
  -- Every general name is taken: themed names next, then repeats.
  if #speciesPool > 0 then return from(speciesPool) end
  if #typePool > 0 then return from(typePool) end
  if #everyone > 0 then return from(everyone) end
  return nil
end

-- Gen 1 has no gender, so it's worked out the way Gold, Silver and Crystal do
-- for a traded-in Pokémon: female when the Attack DV is at or under the
-- species' threshold. Same table and rule as the Gen 1 Gender mod, so the
-- name always matches the symbol that mod draws.
local F12, F25, F50, F75 = 1, 3, 7, 11
local GEN1_RATIO = {
  BULBASAUR = F12, IVYSAUR = F12, VENUSAUR = F12, CHARMANDER = F12, CHARMELEON = F12,
  CHARIZARD = F12, SQUIRTLE = F12, WARTORTLE = F12, BLASTOISE = F12, EEVEE = F12,
  VAPOREON = F12, JOLTEON = F12, FLAREON = F12, OMANYTE = F12, OMASTAR = F12,
  KABUTO = F12, KABUTOPS = F12, AERODACTYL = F12, SNORLAX = F12,
  GROWLITHE = F25, ARCANINE = F25, ABRA = F25, KADABRA = F25, ALAKAZAM = F25,
  MACHOP = F25, MACHOKE = F25, MACHAMP = F25, ELECTABUZZ = F25, MAGMAR = F25,
  VULPIX = F75, NINETALES = F75, CLEFAIRY = F75, CLEFABLE = F75, JIGGLYPUFF = F75,
  WIGGLYTUFF = F75,
  NIDORANM = "male", NIDORINO = "male", NIDOKING = "male", HITMONLEE = "male",
  HITMONCHAN = "male", TAUROS = "male",
  NIDORANF = "female", NIDORINA = "female", NIDOQUEEN = "female", CHANSEY = "female",
  JYNX = "female", KANGASKHAN = "female",
  MAGNEMITE = "none", MAGNETON = "none", VOLTORB = "none", ELECTRODE = "none",
  STARYU = "none", STARMIE = "none", PORYGON = "none", DITTO = "none",
  ARTICUNO = "none", ZAPDOS = "none", MOLTRES = "none", MEWTWO = "none", MEW = "none",
}
local function gen1Gender(species, mon)
  local r = GEN1_RATIO[speciesKey(species)] or F50
  if type(r) == "string" then return r end
  local atk = mon and type(mon.dvs) == "table" and mon.dvs.attack
  if type(atk) ~= "number" then return nil end
  return atk <= r and "female" or "male"
end

-- Gen 2 says male, female or unknown; Gen 3 says M, F or U.
local GENDER_VALUES = { male = "male", m = "male", female = "female", f = "female",
  unknown = "none", u = "none", none = "none", genderless = "none" }
local function genderOf(species, mon)
  local g = mon and mon.gender
  if g ~= nil then return GENDER_VALUES[tostring(g):lower()] end
  if mon and type(mon.dvs) == "table" then return gen1Gender(species, mon) end
  return nil
end

-- A repeatable random stream from a string, so a trainer's team gets the
-- same names every time you battle them. Plain arithmetic: no bit library.
local function seededRand(seed)
  local state = 7
  for i = 1, #seed do state = (state * 31 + seed:byte(i)) % 2147483647 end
  if state == 0 then state = 1 end
  return function()
    state = (state * 48271) % 2147483647
    return state / 2147483647
  end
end

-- Names for a trainer's party, by slot (nil keeps the species name).
-- Canon names come first: an entry for this trainer names the slot holding
-- its exact species, or failing that the highest-level member of its family,
-- and each entry names one slot. With mode "all" the other slots get names
-- from the switched-on sets, never two the same in one party.
local function trainerNames(pools, trainerName, seed, rows, mode, themed, typesOf, gender)
  local names, used = {}, {}
  local tkey = trainerName and speciesKey(trainerName)
  if tkey and tkey ~= "" then
    local mine = {}
    for _, entry in ipairs(pools.trainers or {}) do
      if entry.key == tkey and #entry.names > 0 then mine[#mine + 1] = entry end
    end
    local function give(slot, entry)
      local r = seededRand(seed .. "|canon|" .. entry.species[1])
      local name = entry.names[math.floor(r() * #entry.names) + 1]
      names[slot] = name
      used[name:upper()] = true
      entry = nil
    end
    -- exact species first, for every entry, so a family fallback never takes
    -- a slot another entry names exactly (Flannery's Slugma and Magcargo)
    local done = {}
    for e, entry in ipairs(mine) do
      for i, row in ipairs(rows) do
        if not names[i] and speciesKey(row.species) == entry.species[1] then
          give(i, entry); done[e] = true
          break
        end
      end
    end
    for e, entry in ipairs(mine) do
      if not done[e] then
        local slot
        for i, row in ipairs(rows) do
          if not names[i] then
            local key = speciesKey(row.species)
            for j = 2, #entry.species do
              if key == entry.species[j]
                  and (not slot or (tonumber(row.level) or 0) > (tonumber(rows[slot].level) or 0)) then
                slot = i
              end
            end
          end
        end
        if slot then give(slot, entry) end
      end
    end
  end
  if mode == "all" then
    for i, row in ipairs(rows) do
      if not names[i] then
        local r = seededRand(seed .. "|" .. i .. "|" .. tostring(row.species))
        local name = pickName(pools, row.species, typesOf(row.species, row), used, themed, r, gender)
        if name then
          names[i] = name
          used[name:upper()] = true
        end
      end
    end
  end
  return names
end

local function applyCase(name, case)
  if case == "mixed" then return name end
  return name:upper()
end

-- A caught Pokémon still wearing its species name (or none) has no nickname
-- yet. Gen 3 stores "" and Gen 2 stores nothing until one is given.
local function isUnnamed(mon, species)
  local nick = mon and mon.nickname
  if nick == nil or nick == "" then return true end
  local key = speciesKey(nick)
  return key == speciesKey(species) or key == speciesKey(mon.name)
end

-- Option key and label for a list file: food.txt is set_food, FOOD.
local function setOption(fileName)
  local stem = fileName:gsub("%.[Tt][Xx][Tt]$", "")
  local key = "set_" .. stem:lower():gsub("[^%w]", "_")
  local label = stem:upper():gsub("[_%-]", " ")
  return key, label
end

-- Pure parts, reachable from tests/ without the engine.
local Core = {
  parseList = parseList, newLibrary = newLibrary, combine = combine,
  validName = validName, namesInUse = namesInUse, pickName = pickName,
  applyCase = applyCase, isUnnamed = isUnnamed, setOption = setOption,
  genderOf = genderOf, gen1Gender = gen1Gender,
  trainerNames = trainerNames, seededRand = seededRand,
  speciesKey = speciesKey, typeKey = typeKey, MAX_LEN = MAX_LEN,
}

return function(mod)
  if mod == nil then return Core end

  local files = {}
  for _, file in ipairs(mod:list(NAMES_DIR) or {}) do
    if file:lower():match("%.txt$") then files[#files + 1] = file end
  end
  table.sort(files)

  local rows = {
    { key = "catches", type = "choice", label = "CATCHES", default = "auto",
      choices = { { "AUTO", "auto" }, { "ASK", "ask" } } },
    { key = "gifts", type = "choice", label = "GIFTS", default = "ask",
      choices = { { "AUTO", "auto" }, { "ASK", "ask" } } },
    { key = "case", type = "choice", label = "LETTERS", default = "caps",
      choices = { { "CAPS", "caps" }, { "Mixed", "mixed" } } },
    { key = "themed", type = "choice", label = "THEMED NAMES", default = "sometimes",
      choices = { { "SOMETIMES", "sometimes" }, { "OFTEN", "often" } } },
    { key = "gender", type = "toggle", label = "MATCH GENDER", default = true },
    { key = "question", type = "choice", label = "NICKNAME QUESTION", default = "no",
      choices = { { "ANSWER NO", "no" }, { "ASK ME", "ask" } } },
    { key = "trainers", type = "choice", label = "TRAINER TEAMS", default = "canon",
      choices = { { "CANON", "canon" }, { "ALL", "all" }, { "OFF", "off" } } },
  }
  local lib = newLibrary()
  local setKeys = {}
  for _, file in ipairs(files) do
    local text, err = mod:read(NAMES_DIR .. "/" .. file)
    if text then
      local key, label = setOption(file)
      parseList(lib, text, file, key)
      setKeys[key] = true
      rows[#rows + 1] = { key = key, type = "toggle", label = label,
        default = lib.sets[key].defaultOn }
    else
      mod.log:warn("could not read %s/%s: %s", NAMES_DIR, file, tostring(err))
    end
  end
  mod.options:define(rows)
  for _, line in ipairs(lib.rejected) do mod.log:warn("skipped name %s", line) end
  local total = 0
  for _, setId in ipairs(lib.order) do total = total + lib.sets[setId].count end
  mod.log:info("%d names in %d sets", total, #lib.order)

  -- Its own generator, so naming never moves the game's battle or encounter RNG.
  local rng
  if love and love.math and love.math.newRandomGenerator then
    rng = love.math.newRandomGenerator(os.time())
  end
  local function rand()
    if rng then return rng:random() end
    return math.random()
  end

  -- Merged pools, rebuilt only when a set is switched on or off.
  local cachedPools, cachedSig
  local function pools()
    local sig = {}
    for _, setId in ipairs(lib.order) do
      sig[#sig + 1] = mod.options:get(setId) == false and "0" or "1"
    end
    sig = table.concat(sig)
    if sig ~= cachedSig then
      cachedSig = sig
      cachedPools = combine(lib, function(setId) return mod.options:get(setId) ~= false end)
    end
    return cachedPools
  end

  -- Type ids for a species: the mon's own list when it carries one (Gen 2),
  -- otherwise the species record.
  local function typesOf(species, mon)
    if mon and type(mon.types) == "table" and mon.types[1] then return mon.types end
    local ok, rec = pcall(function() return mod.content.pokemon:get(species) end)
    if ok and type(rec) == "table" and type(rec.types) == "table" then return rec.types end
    local game = mod.game
    local def = game and game.data and game.data.pokemon and game.data.pokemon[species]
    return def and def.types or {}
  end

  local function inUse(game)
    local ok, party = pcall(function() return mod.world and mod.world:party() end)
    if not ok or type(party) ~= "table" then party = nil end
    return namesInUse(game and game.save, party)
  end

  local function nameFor(species, mon, game)
    game = game or mod.game
    local gender = mod.options:get("gender") ~= false and genderOf(species, mon) or nil
    local name = pickName(pools(), species, typesOf(species, mon), inUse(game),
      mod.options:get("themed"), rand, gender)
    return name and applyCase(name, mod.options:get("case"))
  end

  -- Mons this mod named, so the hook and the event never name one twice.
  local named = setmetatable({}, { __mode = "k" })

  -- Answering NO for the player on Gen 2 and Gen 3, where the question can't
  -- be skipped yet. After naming a catch, watch the battle message once a
  -- step; when it's a question with the new name in it, press B, which is
  -- NO on both games. Gives up after a minute or once the battle is over.
  -- If the engine raises catch.nickname there, the hook clears this first.
  local pending
  -- Gen 3 only sees a button that's held across a step, so NO is a short
  -- hold (mod.input:press, then release a few steps later), not a tap.
  local HOLD_STEPS = 4
  local function clearPending()
    if pending and pending.token then
      pcall(function() mod.input:release(pending.token) end)
    end
    pending = nil
  end
  local function armQuestion(mon, name)
    if mod.options:get("question") == "ask" then return end
    clearPending()
    pending = { mon = mon, name = name:upper(), frames = 0, settled = 0, taps = 0, lastTap = -999 }
  end
  local function messageText(snap)
    local m = snap and snap.message
    if type(m) == "table" then return table.concat(m, " ") end
    return type(m) == "string" and m or ""
  end
  local function pollQuestion(game)
    local p = pending
    p.frames = p.frames + 1
    if p.token and p.frames - p.lastTap >= HOLD_STEPS then
      pcall(function() mod.input:release(p.token) end)
      p.token = nil
    end
    if p.frames > 3600 then return clearPending() end
    local ok, snap = pcall(function() return mod.battle and mod.battle:snapshot() end)
    if not ok or not snap then
      if p.frames > 120 then clearPending() end
      return
    end
    local text = messageText(snap):upper()
    local asking = text:find(p.name, 1, true) and text:find("?", 1, true)
    if not asking then
      p.settled = 0
      -- the question was up and has gone: answered
      if p.taps > 0 and not p.token then clearPending() end
      return
    end
    -- Press every half second while the question is up. In Gen 3 the yes/no
    -- box opens a couple of seconds after the text starts (sooner on fast
    -- text); a B before then only finishes the text, and the first one after
    -- it is NO.
    p.settled = p.settled + 1
    if p.settled >= 10 and not p.token and p.frames - p.lastTap >= 30 then
      if p.taps >= 20 then return clearPending() end
      local okP, token = pcall(function() return mod.input:press(game, "b") end)
      if okP then p.token = token end
      p.taps, p.lastTap = p.taps + 1, p.frames
    end
  end
  -- input.step runs once per fixed step in all three games, just before
  -- queued presses land, so a tap made here is read on the very next step.
  mod.hooks:wrap("input.step", function(next, game, dt)
    next(game, dt)
    if pending then pollQuestion(game) end
  end)

  -- Gen 1 catches. Another mod's answer (false, or its own name) stands; only
  -- the vanilla "ask" is replaced.
  mod.hooks:wrap("catch.nickname", function(next, mon, ctx)
    -- the engine is answering the question itself, so there's nothing to press
    clearPending()
    local verdict = next(mon, ctx)
    if verdict ~= true or mod.options:get("catches") ~= "auto" then return verdict end
    -- already named at the ball throw (Gen 3 may hand over a copy by now)
    if type(mon.nickname) == "string" and not isUnnamed(mon, mon.species) then return mon.nickname end
    local name = nameFor(mon.species, mon, ctx and ctx.game)
    if name then named[mon] = true end
    return name or verdict
  end)

  -- Gen 2 and Gen 3 catches: the mon is already in the party or box when this
  -- fires, and the nickname question comes after. On Gen 1 the hook has
  -- already named it by now, so this leaves it alone.
  mod.events:on("pokemon.caught", function(ev)
    if mod.options:get("catches") ~= "auto" then return end
    local mon = ev.mon
    local species = ev.species or (mon and mon.species)
    if type(mon) ~= "table" or named[mon] or not isUnnamed(mon, species) then return end
    local name = nameFor(species, mon, ev.game)
    if name then
      mon.nickname = name
      named[mon] = true
      armQuestion(mon, name)
    end
  end, -100)

  -- Gen 3 hands over the caught Pokémon with the ball throw, before it's
  -- stored. A catch headed for the PC is only stored (and pokemon.caught only
  -- fires) after the nickname question and the transfer line, so naming it
  -- here is what puts the new name in both. Gen 1 and Gen 2 don't send the
  -- Pokémon with this event, and are named above.
  mod.events:on("battle.ball_thrown", function(ev)
    if not ev.caught or mod.options:get("catches") ~= "auto" then return end
    local mon = ev.mon
    local species = ev.species or (type(mon) == "table" and mon.species)
    if type(mon) ~= "table" or named[mon] or not isUnnamed(mon, species) then return end
    local name = nameFor(species, mon, ev.game)
    if name then
      mon.nickname = name
      named[mon] = true
      armQuestion(mon, name)
    end
  end, -100)

  -- The name of the trainer about to battle, from the trainers registry.
  -- Gen 1 passes the class id and party number (OPP_LT_SURGE, 1), Gen 2 the
  -- class and member ids (LT_SURGE, LT_SURGE1), Gen 3 the class and trainer
  -- numbers (84, 416), and the Gen 3 registry is keyed by "416".
  local function trainerNameOf(cls, idx)
    local ok, name = pcall(function()
      local trainers = mod.content.trainers
      if type(idx) == "number" and type(cls) ~= "string" then
        local rec = trainers:get(tostring(idx))
        return rec and rec.name
      end
      local rec = trainers:get(cls)
      if type(rec) ~= "table" then return nil end
      if type(idx) == "string" then
        for _, row in ipairs(rec.trainers or {}) do
          if row.id == idx then return row.name end
        end
        return nil
      end
      local personal = rec.partyNames and rec.partyNames[idx]
      if type(personal) == "string" and personal ~= "" then return personal end
      return rec.name
    end)
    return ok and type(name) == "string" and name or nil
  end

  -- Trainers' Pokémon. The party comes back as copies with a nickname on
  -- them, so the game's own trainer data is never changed. A row that
  -- already has a nickname (another mod's, or a link partner's) keeps it.
  -- Gold, Silver and Crystal show these names today; Red, Blue, Yellow and
  -- the Gen 3 games need the engine to carry a party row's nickname into the
  -- battle (see the README).
  mod.hooks:wrap("trainer.party", function(nextHook, cls, idx, party)
    local rows = nextHook(cls, idx, party)
    local mode = mod.options:get("trainers")
    if mode == "off" or type(rows) ~= "table" or #rows == 0 then return rows end
    local gender = mod.options:get("gender") ~= false and "none" or nil
    local names = trainerNames(pools(), trainerNameOf(cls, idx), tostring(cls) .. "|" .. tostring(idx),
      rows, mode, mod.options:get("themed"), typesOf, gender)
    local any = false
    for _ in pairs(names) do any = true break end
    if not any then return rows end
    local case = mod.options:get("case")
    local out = {}
    for i, row in ipairs(rows) do
      if type(row) == "table" then
        local copy = {}
        for k, v in pairs(row) do copy[k] = v end
        local mt = getmetatable(row)
        if mt then setmetatable(copy, mt) end
        if names[i] and (row.nickname == nil or row.nickname == "") then
          copy.nickname = applyCase(names[i], case)
        end
        out[i] = copy
      else
        out[i] = row
      end
    end
    return out
  end)

  -- Gifts: starters, Eevee, fossils, Lapras and the rest (Gen 1 and Gen 3).
  -- Runs late so a mod that swaps the gift's species has already done so.
  mod.events:on("pokemon.before_give", function(gift)
    if gift.nickname or mod.options:get("gifts") ~= "auto" then return end
    local ctx = gift.ctx or {}
    gift.nickname = nameFor(gift.species, nil, ctx.game)
  end, -100)

  -- For rename tools and other mods: a fresh name for a species, in the
  -- player's LETTERS setting and switched-on sets, avoiding names in use.
  mod.exports.version = 1
  mod.exports.nameFor = function(species, game)
    return nameFor(species, nil, game)
  end
end
