-- Name Tags tests. Run from the mod folder: luajit tests/run_tests.lua
-- Covers the shipped lists, the picker, and the hook and event wiring with a
-- stand-in mod object. The in-game checks live in the engine drivers.
-- ------------------

local failures, passes = 0, 0
local function check(cond, msg)
  if cond then passes = passes + 1 else failures = failures + 1; print("FAIL " .. msg) end
end

local function readFile(path)
  local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end

local entry = assert(loadfile("main.lua"))()
local Core = entry(nil)

local FILES = {}
do
  local p = io.popen("ls names")
  for f in p:lines() do if f:match("%.txt$") then FILES[#FILES + 1] = f end end
  p:close()
  table.sort(FILES)
end

-- Shipped lists
local lib = Core.newLibrary()
for _, f in ipairs(FILES) do
  local key = Core.setOption(f)
  Core.parseList(lib, readFile("names/" .. f), f, key)
end
for _, r in ipairs(lib.rejected) do print("  rejected " .. r) end
check(#lib.rejected == 0, "shipped lists have no rejected lines")
local want = { "set_baked_goods", "set_canon", "set_food", "set_memes", "set_myths", "set_nature", "set_people", "set_pets", "set_pop_culture",
  "set_space", "set_species", "set_types" }
check(table.concat(lib.order, ",") == table.concat(want, ","), "twelve sets in file order: " .. table.concat(lib.order, ","))
check(lib.sets.set_memes.defaultOn == false and lib.sets.set_pop_culture.defaultOn == false, "memes and pop culture start off")
check(lib.sets.set_people.defaultOn == true, "people starts on")
local pg = lib.sets.set_people.gender
check(#pg.male > 300 and #pg.female > 300 and #pg.neutral > 100, "people split by gender")
check(#lib.sets.set_people.all == 0, "every people name is in a gender section")
local pools = Core.combine(lib)
local general = #pools.all + #pools.gender.male + #pools.gender.female + #pools.gender.neutral
check(general >= 1900, "1900+ general names across sets (" .. general .. ")")
for _, t in ipairs({ "NORMAL", "FIGHTING", "FLYING", "POISON", "GROUND", "ROCK", "BUG", "GHOST",
  "FIRE", "WATER", "GRASS", "ELECTRIC", "PSYCHIC", "ICE", "DRAGON", "DARK", "STEEL" }) do
  check(pools.types[t] and #pools.types[t] >= 10, "type pool " .. t)
end
check(pools.species.MRMIME and #pools.species.MRMIME > 0, "MR_MIME keyed without underscores")
check(pools.species.NINETALES and #pools.species.NINETALES > 0, "Ninetales names")
for key, list in pairs(pools.species) do
  for _, n in ipairs(list) do check(#n <= 10, key .. " name length " .. n) end
end

-- Ids across games
check(Core.speciesKey("MR__MIME") == Core.speciesKey("MR_MIME"), "Gen 2 Mr. Mime matches")
check(Core.speciesKey("MR. MIME") == "MRMIME", "display name matches too")
check(Core.typeKey("PSYCHIC_TYPE") == "PSYCHIC" and Core.typeKey("psychic") == "PSYCHIC", "psychic spellings")

-- Validation
check(Core.validName("Mary-Jo"), "inner hyphen ok")
check(not Core.validName("EZFrank32"), "digits refused")
check(not Core.validName("Bartholomew"), "11 letters refused")
check(not Core.validName("-Jo"), "leading hyphen refused")
check(not Core.validName("Jo--Jo"), "double hyphen refused")
check(not Core.validName("Zoë"), "letters outside the fonts refused")

-- Parsing edge cases
local l2 = Core.newLibrary()
Core.parseList(l2, "# note\n[all]\nAnna\nanna\n\n[type fire, psychic_type]\nBlaze\n[species vulpix MR__MIME]\nKit\n[bogus]\nNope\n[all]\nBob\r\n", "t.txt", "set_t")
check(#l2.sets.set_t.all == 2, "duplicates fold case-insensitively, CRLF tolerated")
check(l2.sets.set_t.types.FIRE[1] == "Blaze" and l2.sets.set_t.types.PSYCHIC[1] == "Blaze", "header ids normalised")
check(l2.sets.set_t.species.MRMIME[1] == "Kit", "species header normalised")
check(#l2.rejected == 1 and l2.rejected[1]:find("t.txt:10"), "unknown header reported with file:line")

-- Sets switch on and off
local l3 = Core.newLibrary()
Core.parseList(l3, "[all]\nAnna\n", "a.txt", "set_a")
Core.parseList(l3, "[all]\nBiscuit\n[type FIRE]\nChili\n", "b.txt", "set_b")
local onlyA = Core.combine(l3, function(id) return id == "set_a" end)
check(#onlyA.all == 1 and onlyA.all[1] == "Anna" and onlyA.types.FIRE == nil, "a switched-off set adds nothing")
local both = Core.combine(l3)
check(#both.all == 2 and both.types.FIRE[1] == "Chili", "both sets merged")
local k, label = Core.setOption("pet_names.txt")
check(k == "set_pet_names" and label == "PET NAMES", "option key and label from file name")

-- Gender
local l5 = Core.newLibrary()
Core.parseList(l5, "[all]\nBiscuit\n[male]\nArthur\n[female]\nMabel\n[nonbinary]\nRiley\n", "g", "g")
local p5 = Core.combine(l5)
local function every(gender)
  local got = {}
  for i = 0, 3 do
    local r = { (i + 0.5) / 4 }
    local n = Core.pickName(p5, "X", {}, {}, "sometimes", function() return r[1] end, gender)
    got[n] = true
  end
  return got
end
local function picks(gender)
  local got, used = {}, {}
  for _ = 1, 4 do
    local n = Core.pickName(p5, "X", {}, used, "sometimes", function() return 0.99 end, gender)
    if n then got[n] = true; used[n:upper()] = true end
  end
  return got
end
local male, female, none, any = picks("male"), picks("female"), picks("none"), picks(nil)
check(male.Arthur and male.Riley and male.Biscuit and not male.Mabel, "male: male, neutral and ungendered")
check(female.Mabel and female.Riley and female.Biscuit and not female.Arthur, "female: female, neutral and ungendered")
check(none.Riley and none.Biscuit and not none.Arthur and not none.Mabel, "genderless: neutral and ungendered only")
check(any.Arthur and any.Mabel and any.Riley and any.Biscuit, "unknown: everything")
check(Core.genderOf("VULPIX", { gender = "female" }) == "female", "Gen 2 female")
check(Core.genderOf("MAGNEMITE", { gender = "unknown" }) == "none", "Gen 2 genderless")
check(Core.genderOf("VULPIX", { gender = "M" }) == "male" and Core.genderOf("STARYU", { gender = "U" }) == "none", "Gen 3 M and U")
check(Core.genderOf("VULPIX", { dvs = { attack = 11 } }) == "female", "Gen 1 Vulpix at Attack DV 11 is female")
check(Core.genderOf("VULPIX", { dvs = { attack = 12 } }) == "male", "Gen 1 Vulpix at Attack DV 12 is male")
check(Core.genderOf("PIDGEY", { dvs = { attack = 7 } }) == "female" and Core.genderOf("PIDGEY", { dvs = { attack = 8 } }) == "male", "Gen 1 50/50")
check(Core.genderOf("NIDORAN_M", { dvs = { attack = 0 } }) == "male", "Gen 1 always male")
check(Core.genderOf("DITTO", { dvs = { attack = 0 } }) == "none", "Gen 1 genderless")
check(Core.genderOf("EEVEE", nil) == nil, "a gift with no mon yet has no gender")

-- Picker
local function seq(values)
  local i = 0
  return function() i = i % #values + 1; return values[i] end
end
local l4 = Core.newLibrary()
Core.parseList(l4, "[all]\nAnna\nBob\n[type FIRE]\nBlaze\n[species NINETALES]\nKyubi\n", "t", "s")
local p4 = Core.combine(l4)
check(Core.pickName(p4, "NINETALES", { "FIRE" }, {}, "sometimes", seq({ 0.10, 0 })) == "Kyubi", "low roll picks species")
check(Core.pickName(p4, "NINETALES", { "FIRE" }, {}, "sometimes", seq({ 0.30, 0 })) == "Blaze", "middle roll picks type")
check(Core.pickName(p4, "NINETALES", { "FIRE" }, {}, "sometimes", seq({ 0.90, 0.99 })) == "Bob", "high roll picks general")
check(Core.pickName(p4, "VULPIX", { "FIRE" }, {}, "often", seq({ 0.10, 0 })) == "Blaze", "no species pool falls to type")
check(Core.pickName(p4, "RATTATA", { "NORMAL" }, { ANNA = true }, "sometimes", seq({ 0.9, 0 })) == "Bob", "names in use skipped")
check(Core.pickName(p4, "NINETALES", { "FIRE" }, { ANNA = true, BOB = true }, "sometimes", seq({ 0.9, 0 })) == "Kyubi",
  "general all used falls to themed")
check(Core.pickName(p4, "RATTATA", {}, { ANNA = true, BOB = true }, "sometimes", seq({ 0.9, 0 })) == "Anna", "repeats last")
check(Core.pickName(Core.combine(Core.newLibrary()), "RATTATA", {}, {}, "sometimes", seq({ 0.5 })) == nil, "empty gives nil")
check(Core.applyCase("McKenzie", "caps") == "MCKENZIE" and Core.applyCase("McKenzie", "mixed") == "McKenzie", "case")

-- Nickname state across games
check(Core.isUnnamed({ species = "VULPIX" }, "VULPIX"), "Gen 2: no nickname field")
check(Core.isUnnamed({ species = 37, nickname = "", name = "VULPIX" }, "VULPIX"), "Gen 3: empty nickname")
check(Core.isUnnamed({ species = 122, nickname = "MR. MIME", name = "MR. MIME" }, "MR_MIME"), "species name counts as none")
check(not Core.isUnnamed({ species = "VULPIX", nickname = "RUSSET" }, "VULPIX"), "a real nickname is kept")

local used = Core.namesInUse({
  party = { { species = "PIDGEY", nickname = "Anna" }, { species = "PIDGEY" } },
  boxes = { { { species = "X", nickname = "bob" } }, {} },
  daycare = { mon = { species = "Y", nickname = "Kit" } },
  flags = { { species = "Z", nickname = "NOTAMON" } },
}, { { species = 37, nickname = "Gen3" } })
check(used.ANNA and used.BOB and used.KIT and used.GEN3, "party, boxes, Day-Care and a party list counted")
check(not used.NOTAMON, "unrelated save tables not walked")

-- Wiring with a stand-in mod object
local function load(opts, extra)
  local m = { exports = {}, logs = {} }
  m.options = { define = function(_, rows) m.rows = rows end, get = function(_, key)
    if opts[key] ~= nil then return opts[key] end
    for _, row in ipairs(m.rows or {}) do if row.key == key then return row.default end end
  end }
  local hooks, events = {}, {}
  m.hooks = { wrap = function(_, name, fn) hooks[name] = fn end }
  m.events = { on = function(_, name, fn, prio) events[name] = { fn = fn, prio = prio } end }
  m.list = function() return FILES end
  m.read = function(_, rel) return readFile(rel) end
  m.content = { pokemon = { get = function(_, id) return (extra or {})[id] end } }
  local function logger(level) return function(_, fmt, ...) m.logs[#m.logs + 1] = level .. " " .. fmt:format(...) end end
  m.log = { info = logger("info"), warn = logger("warn"), error = logger("error") }
  entry(m)
  return m, hooks, events
end

local records = { NINETALES = { types = { "FIRE" } }, EEVEE = { types = { "NORMAL" } }, UMBREON = { types = { "DARK" } } }
local game = { save = { party = {}, boxes = {} } }

local m, hooks, events = load({}, records)
check(#m.rows == 19, "7 setting rows + 12 set toggles (" .. #m.rows .. ")")
check(m.rows[8].label == "BAKED GOODS" and m.rows[8].default == true, "BAKED GOODS starts on")
check(m.rows[7].key == "trainers" and m.rows[7].default == "canon", "TRAINER TEAMS defaults to CANON")
check(m.rows[9].type == "toggle" and m.rows[9].default == true and m.rows[9].label == "CANON", "CANON starts on")
check(m.rows[11].label == "MEMES" and m.rows[11].default == false, "MEMES starts off")
check(m.rows[16].label == "POP CULTURE" and m.rows[16].default == false, "POP CULTURE starts off")
check(m.logs[#m.logs]:find("names in 12 sets"), "load logs the set count")
local name = hooks["catch.nickname"](function() return true end, { species = "NINETALES" }, { game = game })
check(type(name) == "string" and name == name:upper() and #name <= 10, "Gen 1 catch gets a CAPS name: " .. tostring(name))
check(hooks["catch.nickname"](function() return false end, { species = "NINETALES" }, { game = game }) == false, "false stands")
check(hooks["catch.nickname"](function() return "SPOT" end, { species = "NINETALES" }, { game = game }) == "SPOT", "a name stands")

-- Gen 2 / Gen 3 path
local g2 = { species = "UMBREON", name = "UMBREON", types = { "DARK", "DARK" } }
events["pokemon.caught"].fn({ mon = g2, species = "UMBREON", game = game })
check(type(g2.nickname) == "string" and #g2.nickname > 0, "Gen 2 catch named in pokemon.caught: " .. tostring(g2.nickname))
local g3 = { species = 37, speciesId = 37, nickname = "", name = "VULPIX" }
events["pokemon.caught"].fn({ mon = g3, species = "VULPIX", game = {} })
check(g3.nickname ~= "", "Gen 3 catch named: " .. tostring(g3.nickname))
local keep = { species = "PIDGEY", nickname = "SKY" }
events["pokemon.caught"].fn({ mon = keep, species = "PIDGEY", game = game })
check(keep.nickname == "SKY", "a caught mon with a name keeps it")
-- the hook after the event (a future Gen 2 call site) reuses the event's name
local g2b = { species = "UMBREON", name = "UMBREON" }
events["pokemon.caught"].fn({ mon = g2b, species = "UMBREON", game = game })
check(hooks["catch.nickname"](function() return true end, g2b, { game = game }) == g2b.nickname, "hook reuses the event's name")
local copy = { species = 197, name = "UMBREON", nickname = "NYX" }
check(hooks["catch.nickname"](function() return true end, copy, { game = game }) == "NYX", "hook keeps a name a copy already wears")
check(events["pokemon.caught"].prio < 0, "caught listener runs late")

local gift = { species = "EEVEE", level = 25, ctx = { game = game } }
events["pokemon.before_give"].fn(gift)
check(gift.nickname == nil, "GIFTS ASK leaves gifts alone")
check(m.exports.version == 1 and type(m.exports.nameFor) == "function", "exports")

local _, hooks2, events2 = load({ catches = "ask", gifts = "auto", case = "mixed" }, records)
check(hooks2["catch.nickname"](function() return true end, { species = "NINETALES" }, { game = game }) == true, "CATCHES ASK keeps the prompt")
local asked = { species = "UMBREON", name = "UMBREON" }
events2["pokemon.caught"].fn({ mon = asked, species = "UMBREON", game = game })
check(asked.nickname == nil, "CATCHES ASK leaves Gen 2/3 catches unnamed")
local gift2 = { species = "EEVEE", ctx = { game = game } }
events2["pokemon.before_give"].fn(gift2)
check(type(gift2.nickname) == "string" and gift2.nickname ~= gift2.nickname:upper(), "GIFTS AUTO, Mixed: " .. tostring(gift2.nickname))

-- Only BAKED GOODS on: every general pick is a baked good
do
  local onlyBaked = { set_food = false, set_canon = false, set_people = false, set_pets = false, set_nature = false,
    set_myths = false, set_space = false, set_types = false, set_species = false, set_memes = false, set_pop_culture = false }
  local _, hb = load(onlyBaked, records)
  local baked = {}
  for _, n in ipairs(lib.sets.set_baked_goods.all) do baked[n:upper()] = true end
  for _, list in pairs(lib.sets.set_baked_goods.types) do for _, n in ipairs(list) do baked[n:upper()] = true end end
  local allBaked, seen = true, nil
  for _ = 1, 50 do
    local n = hb["catch.nickname"](function() return true end, { species = "NINETALES" }, { game = { save = {} } })
    if not baked[n] then allBaked = false; seen = n end
  end
  check(allBaked, "only BAKED GOODS switched on gives only baked goods: " .. tostring(seen))
end

-- Only FOOD on: every general pick is a food name
local onlyFood = { set_baked_goods = false, set_canon = false, set_people = false, set_pets = false, set_nature = false, set_myths = false,
  set_space = false, set_types = false, set_species = false, set_memes = false, set_pop_culture = false }
local _, hooks3 = load(onlyFood, records)
local foodNames = {}
for _, n in ipairs(lib.sets.set_food.all) do foodNames[n:upper()] = true end
for _, list in pairs(lib.sets.set_food.types) do for _, n in ipairs(list) do foodNames[n:upper()] = true end end
local allFood = true
for _ = 1, 50 do
  local n = hooks3["catch.nickname"](function() return true end, { species = "NINETALES" }, { game = { save = {} } })
  if not foodNames[n] then allFood = false; print("  not food: " .. tostring(n)) end
end
check(allFood, "only FOOD switched on gives only food names")

-- Pop culture names only come up when switched on
local popNames = {}
for _, sec in ipairs({ lib.sets.set_pop_culture.all, lib.sets.set_pop_culture.gender.male,
  lib.sets.set_pop_culture.gender.female, lib.sets.set_memes.all }) do
  for _, n in ipairs(sec) do popNames[n:upper()] = true end
end
-- every name in a set that starts on, in any section
local onNames, ungendered = {}, {}
for id, set in pairs(lib.sets) do
  if set.defaultOn then
    local function add(list, plain)
      for _, n in ipairs(list) do onNames[n:upper()] = true; if plain then ungendered[n:upper()] = true end end
    end
    local plain = id ~= "set_canon"
    add(set.all, plain)
    for _, list in pairs(set.types) do add(list, plain) end
    for _, list in pairs(set.species) do add(list, plain) end
    for g, list in pairs(set.gender) do add(list, g == "neutral") end
  end
end
local peopleNames = onNames
local both = {}
for id, set in pairs(lib.sets) do
  -- canon names are what a real Pokémon was called, gender and all
  if set.defaultOn and id ~= "set_canon" then
    for g, list in pairs(set.gender) do
      if g ~= "neutral" then
        for _, n in ipairs(list) do if ungendered[n:upper()] then both[#both + 1] = id .. ":" .. n end end
      end
    end
  end
end
check(#both == 0, "no male or female name is also in an ungendered list: " .. table.concat(both, ", "))
local leaked = false
for _ = 1, 300 do
  local n = hooks["catch.nickname"](function() return true end, { species = "PIDGEY", dvs = { attack = 3 } }, { game = { save = {} } })
  if popNames[n] and not peopleNames[n] then leaked = true; print("  pop name while off: " .. n) end
end
check(not leaked, "no pop culture or meme names while those sets are off")

-- Genderless Gen 1 catch never gets a gendered people name
local gendered = {}
for g, sec in pairs(lib.sets.set_people.gender) do
  if g ~= "neutral" then for _, n in ipairs(sec) do gendered[n:upper()] = true end end
end
for g, sec in pairs(lib.sets.set_myths.gender) do
  if g ~= "neutral" then for _, n in ipairs(sec) do gendered[n:upper()] = true end end
end
local neutralOk = true
local neutralNames = {}
for _, n in ipairs(lib.sets.set_people.gender.neutral) do neutralNames[n:upper()] = true end
for _ = 1, 300 do
  local n = hooks["catch.nickname"](function() return true end, { species = "DITTO", dvs = { attack = 5 } }, { game = { save = {} } })
  if gendered[n] and not ungendered[n] then neutralOk = false; print("  gendered name on Ditto: " .. n) end
end
check(neutralOk, "Ditto never gets a male or female name")

-- Auto NO on Gen 2 / Gen 3: a stand-in battle and input
do
  local snap = nil
  local taps = 0
  local m4, hooks4, events4 = load({}, records)
  m4.battle = { snapshot = function() return snap end }
  local held = 0
  m4.input = { press = function(_, _, btn) if btn == "b" then taps = taps + 1; held = held + 1 end return { btn } end,
    release = function() held = held - 1 end }
  local mon = { species = "UMBREON", name = "UMBREON" }
  events4["pokemon.caught"].fn({ mon = mon, species = "UMBREON", game = {} })
  local nick = mon.nickname
  local function frames(n) for _ = 1, n do hooks4["input.step"](function() end, {}, 1 / 60) end end
  snap = { message = { "Gotcha! " .. nick .. " was caught!" } }
  frames(60)
  check(taps == 0, "no press before the question")
  snap = { message = { "Give a nickname to", nick .. "?" } }
  frames(9)
  check(taps == 0, "waits for the question to settle")
  frames(3)
  check(taps == 1, "presses B once the question is up")
  frames(32)
  check(taps == 2, "presses again while the question is still up")
  check(held == 0, "each press is released")
  snap = { message = { "Got away safely!" } }
  frames(60)
  snap = { message = { "Give a nickname to", nick .. "?" } }
  frames(100)
  check(taps == 2, "done after the question goes")
  check(held == 0, "the B hold is always released")

  -- ASK ME: never presses
  local taps5 = 0
  local m5, hooks5, events5 = load({ question = "ask" }, records)
  m5.battle = { snapshot = function() return { message = { "Give a nickname to?" } } end }
  m5.input = { press = function() taps5 = taps5 + 1 return {} end, release = function() end }
  local mon5 = { species = "UMBREON", name = "UMBREON" }
  events5["pokemon.caught"].fn({ mon = mon5, species = "UMBREON", game = {} })
  m5.battle.snapshot = function() return { message = { "Give a nickname to " .. mon5.nickname .. "?" } } end
  for _ = 1, 200 do hooks5["input.step"](function() end, {}, 1 / 60) end
  check(taps5 == 0, "ASK ME leaves the question to the player")

  -- a catch.nickname call site (patched engine) clears the watch
  local taps6 = 0
  local m6, hooks6, events6 = load({}, records)
  m6.input = { press = function() taps6 = taps6 + 1 return {} end, release = function() end }
  local mon6 = { species = "UMBREON", name = "UMBREON" }
  events6["pokemon.caught"].fn({ mon = mon6, species = "UMBREON", game = {} })
  hooks6["catch.nickname"](function() return true end, mon6, { game = {} })
  m6.battle = { snapshot = function() return { message = { "Give a nickname to " .. mon6.nickname .. "?" } } end }
  for _ = 1, 200 do hooks6["input.step"](function() end, {}, 1 / 60) end
  check(taps6 == 0, "the hook clears the watch")

  -- input.step always runs the game
  local ran = false
  hooks6["input.step"](function() ran = true end, {}, 1 / 60)
  check(ran, "input.step calls next")
end

-- Canon names from the shipped list
local canon = lib.sets.set_canon
check(canon and #canon.trainers >= 5, "canon trainer sections parsed (" .. #(canon and canon.trainers or {}) .. ")")
local volty = false
for _, n in ipairs(canon.species.RAICHU or {}) do volty = volty or n == "Volty" end
check(volty, "Volty is a Raichu name too (family)")
check(canon.species.MRMIME and #canon.species.MRMIME >= 3, "Mr. Mime trade names land on MR_MIME")
local function has(list, want) for _, n in ipairs(list or {}) do if n == want then return true end end return false end
check(has(canon.species.NIDORANM, "MrNIDO") and has(canon.species.NIDORANF, "MsNIDO"), "the reviewed Nidoran names land on each Nidoran")
check(has(canon.species.LUGIA, "XD-One") and has(canon.species.DEOXYS, "EntityTwo"), "new Lugia and Deoxys sections parse")

-- Trainer teams
do
  local cp = Core.combine(lib)
  local function types() return {} end
  local function team(name, seed, rows, mode)
    return Core.trainerNames(cp, name, seed, rows, mode or "canon", "sometimes", types, "none")
  end
  local rb = { { species = "VOLTORB", level = 21 }, { species = "PIKACHU", level = 18 }, { species = "RAICHU", level = 24 } }
  local n = team("LT.SURGE", "OPP_LT_SURGE|1", rb)
  check(n[2] == "Volty" and n[1] == nil and n[3] == nil, "Red: Surge's Pikachu is Volty, the rest keep species names")
  local y = team("LT.SURGE", "OPP_LT_SURGE|1", { { species = "RAICHU", level = 28 } })
  check(y[1] == "Volty", "Yellow: Surge's Raichu is Volty")
  local fr = team("LT. SURGE", "84|416", rb)
  check(fr[2] == "Volty", "FireRed's spelling LT. SURGE matches")
  local c = team("LT.SURGE", "LT_SURGE|LT_SURGE1", { { species = "RAICHU", level = 44 }, { species = "ELECTRODE", level = 40 } })
  check(c[1] == "Volty" and c[2] == nil, "Crystal: Raichu is Volty")
  local j = team("JASMINE", "JASMINE|JASMINE1", { { species = "MAGNEMITE" }, { species = "MAGNEMITE" }, { species = "STEELIX" } })
  check(j[3] == "Rusty" and j[1] == nil, "Jasmine's Steelix is Rusty")
  local st = team("STEVEN", "50|804", { { species = "SKARMORY" }, { species = "METAGROSS", level = 78 } })
  check(st[2] == "Iron", "Steven's Metagross is Iron (Beldum's family)")
  local red = team("RED", "RED|RED1", { { species = "PIKACHU" }, { species = "ESPEON" }, { species = "SNORLAX" },
    { species = "VENUSAUR" }, { species = "CHARIZARD" }, { species = "BLASTOISE" } })
  check(red[1] == "Pika" and red[2] == "Vee" and (red[3] == "Lax" or red[3] == "Snor") and red[4] == "Saur"
    and red[5] == nil and red[6] == nil, "Red's team")
  local red2 = team("RED", "RED|RED1", { { species = "PIKACHU" }, { species = "ESPEON" }, { species = "SNORLAX" } })
  check(red2[3] == red[3], "Lax or Snor stays the same every battle")
  check(next(team("YOUNGSTER", "OPP_YOUNGSTER|1", { { species = "RATTATA" } })) == nil, "CANON leaves other trainers alone")
  local joey = { { species = "RATTATA", level = 4 }, { species = "PIDGEY", level = 5 }, { species = "RATTATA", level = 6 } }
  local a1 = team("JOEY", "YOUNGSTER|JOEY1", joey, "all")
  local a2 = team("JOEY", "YOUNGSTER|JOEY1", joey, "all")
  check(a1[1] and a1[2] and a1[3], "ALL names every slot")
  check(a1[1] == a2[1] and a1[2] == a2[2] and a1[3] == a2[3], "the same trainer gets the same names every battle")
  check(a1[1] ~= a1[3], "no two the same in one party")
  local other = team("JOEY", "YOUNGSTER|JOEY2", joey, "all")
  check(other[1] ~= a1[1] or other[2] ~= a1[2], "a different trainer gets different names")
  local fl = team("FLANNERY", "32|268", { { species = "SLUGMA", level = 24 }, { species = "MAGCARGO", level = 26 } })
  check(fl[1] == "Meg" and fl[2] == "Mag", "Flannery: Slugma is Meg, Magcargo is Mag")
  local flrs = team("FLANNERY", "32|268", { { species = "SLUGMA", level = 24 }, { species = "SLUGMA", level = 26 } })
  check(flrs[1] == "Meg" and flrs[2] == "Mag", "Ruby: no Magcargo, so Mag goes to the other Slugma")
  local br = team("BROCK", "OPP_BROCK|1", { { species = "GEODUDE", level = 12 }, { species = "ONIX", level = 14 } })
  check(br[1] and br[1]:match("^Geo") and br[2] == nil, "Brock's Geodude gets one of his Geo names: " .. tostring(br[1]))
  local wh = team("WHITNEY", "WHITNEY|WHITNEY1", { { species = "CLEFAIRY" }, { species = "MILTANK" } })
  check(wh[1] == "Fafa", "Whitney's Clefairy is Fafa")
  check(wh[2] == "MilMil", "Whitney's Miltank is MilMil")
  local sa = team("LT.SURGE", "OPP_LT_SURGE|1", rb, "all")
  check(sa[2] == "Volty" and sa[1] and sa[3] and sa[3] ~= "Volty", "ALL keeps the canon name and fills the rest")
end

-- Trainer teams through the hook, with a stand-in registry
do
  local regs = {
    OPP_LT_SURGE = { name = "LT.SURGE" },
    LT_SURGE = { name = "LEADER", trainers = { { id = "LT_SURGE1", name = "LT.SURGE" } } },
    ["416"] = { name = "LT. SURGE" },
  }
  local function loadT(opts)
    local m, h = load(opts, records)
    m.content.trainers = { get = function(_, id) return regs[id] end }
    return m, h
  end
  local _, ht = loadT({})
  local shared = { { species = "VOLTORB", level = 21 }, { species = "PIKACHU", level = 18 }, { species = "RAICHU", level = 24 } }
  local out = ht["trainer.party"](function(_, _, p) return p end, "OPP_LT_SURGE", 1, shared)
  check(out ~= shared and out[2].nickname == "VOLTY" and out[1].nickname == nil, "Gen 1 ids: Pikachu named VOLTY in CAPS")
  check(shared[2].nickname == nil, "the game's own party table is never changed")
  local g2 = ht["trainer.party"](function(_, _, p) return p end, "LT_SURGE", "LT_SURGE1", { { species = "RAICHU", level = 44 } })
  check(g2[1].nickname == "VOLTY", "Gen 2 ids: member id finds the trainer")
  local g3 = ht["trainer.party"](function(_, _, p) return p end, 84, 416, { { species = "PIKACHU", level = 18 } })
  check(g3[1].nickname == "VOLTY", "Gen 3 ids: trainer number finds the trainer")
  local kept = ht["trainer.party"](function(_, _, p) return p end, "OPP_LT_SURGE", 1,
    { { species = "PIKACHU", level = 18, nickname = "SPARKY" } })
  check(kept[1].nickname == "SPARKY", "a row with a nickname keeps it")
  local _, hoff = loadT({ trainers = "off" })
  local same = { { species = "PIKACHU", level = 18 } }
  check(hoff["trainer.party"](function(_, _, p) return p end, "OPP_LT_SURGE", 1, same) == same, "OFF passes the party through")
  local _, hcanonoff = loadT({ set_canon = false })
  check(hcanonoff["trainer.party"](function(_, _, p) return p end, "OPP_LT_SURGE", 1, same) == same, "CANON set off: no canon names")
  local _, hall = loadT({ trainers = "all", case = "mixed" })
  local joey = hall["trainer.party"](function(_, _, p) return p end, "OPP_YOUNGSTER", 1, { { species = "RATTATA", level = 4 } })
  check(type(joey[1].nickname) == "string" and joey[1].nickname ~= joey[1].nickname:upper(), "ALL, Mixed: " .. tostring(joey[1].nickname))
  local mt = { __index = { kind = "mon" } }
  local withMt = setmetatable({ species = "PIKACHU", level = 18 }, mt)
  local g2o = ht["trainer.party"](function(_, _, p) return p end, "OPP_LT_SURGE", 1, { withMt })
  check(getmetatable(g2o[1]) == mt and g2o[1].kind == "mon", "copies keep a Gen 2 Pokémon's metatable")
end

-- No repeats across a long run while names remain
local seen, dup, box = {}, false, {}
local g = { save = { party = {}, boxes = { box } } }
for _ = 1, 800 do
  local n = hooks["catch.nickname"](function() return true end, { species = "EEVEE" }, { game = g })
  if seen[n] then dup = true end
  seen[n] = true
  box[#box + 1] = { species = "EEVEE", nickname = n }
end
check(not dup, "800 catches, no repeated names")

print(("%d passed, %d failed"):format(passes, failures))
os.exit(failures == 0 and 0 or 1)
