# Name Tags

Every Pokémon you catch gets a name of its own, picked at random from themed sets: people, pets, food, baked goods, nature, myths, space, names that only suit a certain type or species, and canon nicknames from the games, anime and manga. Pop culture and meme names are there too, for when you want them. A Fire type might come out as **Cinder** or **Sriracha**, a Ninetales as **Kyubi**, a Pikachu as **Volty**, and a Ditto as **Frankie**.

Trainers' Pokémon can have names too. Gym leaders and other trainers from the games, anime and manga bring their canon names into battle: Lt. Surge sends out **Volty**, Jasmine sends out **Rusty**, and Red on Mt. Silver sends out **Pika**.

Names follow the Pokémon's gender: a female gets female and neutral names, a male gets male and neutral names, and a genderless Pokémon (Magnemite, Staryu, Ditto) gets neutral names only.

If you have a better name in mind, the Name Rater still works as usual.

Works in Red, Blue and Yellow, Gold, Silver and Crystal, and the Gen 3 games.

## What happens after a catch

- **Gen 1:** no question. The Pokémon just has its name.
- **Gen 2 and Gen 3:** the game still asks "Give a nickname to SIENNA?", and Name Tags answers NO for you. The question is up for about a second in Gold, Silver and Crystal, and about two in the Gen 3 games, where the text has to finish first. The engine doesn't yet let a mod skip that question in these games. Once it does, Name Tags skips it there too, with no update needed.

## Trainers' Pokémon

When **TRAINER TEAMS** is **CANON**, a trainer whose Pokémon has a canon nickname sends it out under that name. These are the trainers you can battle in Gen 1 to Gen 3 with a matching Pokémon:

| Trainer | Names | Where |
|---|---|---|
| Lt. Surge | Volty | his Pikachu in Red, Blue, FireRed and LeafGreen, his Raichu in Yellow, Gold, Silver and Crystal |
| Brock | one of Geoone to Geosix | his Geodude in Red, Blue, Yellow, FireRed and LeafGreen, his Graveler in Gold, Silver and Crystal |
| Brock | Hornlette | his Rhyhorn in Gold, Silver and Crystal |
| Erika | Angela | her Tangela in every Kanto game |
| Whitney | Fafa, MilMil | her Clefairy and Miltank in Gold, Silver and Crystal |
| Jasmine | Rusty | her Steelix in Gold, Silver and Crystal |
| Red | Pika, Vee, Lax or Snor, Saur | his Pikachu, Espeon, Snorlax and Venusaur on Mt. Silver |
| Flannery | Meg, Mag | her Slugma and Magcargo in Ruby, Sapphire and Emerald |
| Wallace | Elizabeth, Charles, Richard, Phillip | his Luvdisc, Seaking, Sealeo and Whiscash in Ruby and Sapphire, his Whiscash in Emerald |
| Steven | Iron | his Metagross in Ruby, Sapphire and Emerald |

A name goes to the exact species first, and otherwise to the nearest member of its family, which is how Surge's Raichu is Volty. Where a trainer has more than one canon name for a Pokémon, one is picked and stays the same every time you battle them.

**ALL** also names every other trainer's Pokémon from your switched-on sets. Each trainer's team gets the same names every time, so Youngster Joey's Rattata keeps its name on a rematch. **OFF** leaves trainers' Pokémon alone.

**Where this works today:** Gold, Silver and Crystal. Red, Blue, Yellow and the Gen 3 games need a small engine change before the names show in battle. It's been suggested upstream, and Name Tags picks it up with no update once it's in.

## Options

Set these in the mod manager.

- **CATCHES**: **AUTO** names every catch. **ASK** leaves catches to the game, the way it is without the mod.
- **GIFTS**: starters, Eevee, Lapras, fossils and the other gifts. **ASK** by default, so the Pokémon you're handed at the start is still yours to name. **AUTO** names them too. That's tested in Gen 1. Gen 3 gifts take the name, but their own nickname question may still appear, and Gen 2 gifts aren't named yet.
- **LETTERS**: **CAPS** (MABEL) matches the game's own names. **Mixed** (Mabel) writes them as people do.
- **THEMED NAMES**: how often a type or species name is picked over a general one, when one fits. **SOMETIMES** is about two catches in five, **OFTEN** about three in four.
- **MATCH GENDER**: **ON** keeps male, female and neutral names to Pokémon of that gender. **OFF** lets any name go to any Pokémon.
- **NICKNAME QUESTION** (Gen 2 and Gen 3): **ANSWER NO** lets Name Tags answer for you. **ASK ME** leaves the question up, so you can press YES and pick your own name.
- **TRAINER TEAMS**: **CANON** gives canon trainers' Pokémon their names, **ALL** names every trainer's Pokémon, **OFF** leaves them alone. See above.
- One row per set: **BAKED GOODS**, **CANON**, **FOOD**, **MEMES**, **MYTHS**, **NATURE**, **PEOPLE**, **PETS**, **POP CULTURE**, **SPACE**, **SPECIES**, **TYPES**. Switching **CANON** off also stops the canon trainer names. All start **ON** except **MEMES** and **POP CULTURE**, which start **OFF**, since they aren't the everyday names the rest stick to. Leave only **FOOD** on for a team of snacks, or only **BAKED GOODS** for a bakery.

## How names are picked

- A name already worn by a Pokémon in your party, your boxes or the Day-Care isn't picked again. Only once every name is taken does it allow repeats.
- Every name has the same chance, so a bigger set comes up more often than a small one.
- A dual-type Pokémon can draw from both types' names. Some sets have their own type names too: the Food set gives Fire types Chili or Jalapeno, and Water types Sushi or Chowder. Baked Goods gives Ice types Meringue or Pavlova, and Rock types Biscotti or Rock-Cake.
- **Gender:** Gold, Silver, Crystal and the Gen 3 games say what each Pokémon is. Gen 1 has no gender, so Name Tags works it out the way Gold, Silver and Crystal do for a Pokémon traded forward, from its Attack DV and species. That's the same rule as the Gen 1 Gender mod, so the name always matches the symbol it draws. A gift is named before the game has made the Pokémon, so a gift can get any name.
- A name that's male or female in People or Myths is kept out of the other sets, so a female Pokémon is never named Rufus from the pet list. Canon names are the exception: they're what a real Pokémon was called, so a Nidorino can still be Tony.
- In-game trades keep the names they come with. If another mod has already named a catch, Name Tags leaves it alone.
- Naming uses its own random numbers, so it never changes what happens in battles or encounters.

## Limits

- **Names are up to 10 letters,** the same as the naming screen in all three generations. The engine clips a catch's nickname to 10 itself, because the party, summary and battle boxes have no room for more.
- Letters only, with a hyphen allowed inside a name (Mary-Jo). Every generation's font draws those.
- Gen 2 gifts still ask, as the game has no place for a mod to name them first. Gen 3 gifts haven't been played through yet.

## Adding names and sets

The lists are plain text in `names/`, one name per line. Each file is a set with its own ON/OFF row, named after the file: add `colours.txt` and a **COLOURS** row appears. Put `#! default off` on its own line to have a set start switched off.

```
# a note
[neutral]
Riley

[female]
Mabel

[male]
Arthur

[all]
Biscuit

[type FIRE]
Cinder

[species NINETALES VULPIX]
Kyubi

[trainer Lt. Surge: PIKACHU PICHU RAICHU]
Volty
```

- **[male]**, **[female]** and **[neutral]** follow the Pokémon's gender. **[nonbinary]** and **[unisex]** work the same as **[neutral]**.
- **[all]**, **[type ...]** and **[species ...]** go to any Pokémon that fits, whatever its gender.
- **[trainer Name: SPECIES ...]** names that trainer's own Pokémon in battle. The first species is the one the name belongs to, and the rest are its family. The trainer's name is matched however the game spells it, so Lt. Surge matches LT.SURGE and LT. SURGE.
- Headers use the game's own ids. Types: FIRE, WATER, PSYCHIC, DARK, STEEL and the rest. Species: NINETALES, MR_MIME, NIDORAN_F, FARFETCHD. Underscores don't matter, so Gold's MR__MIME matches MR_MIME. A header can name several.

What makes a good name for the list: something you could call a living thing out loud. People names from anywhere, pet names, a word that works as a name (Pepper, Juniper). Not usernames (EZFrank32), not jokes that only work once, and outside the Pop Culture set, not the names of well-known characters or brands. Lines that break the letter rules are skipped and named in the log with their file and line, so a typo never stops the mod loading.

The Memes set leaves out memes with hateful histories, memes that mock a group of people, and memes about real people's looks. Please keep it that way when you send names for it.

Suggestions are welcome on the Discord. Send them as a list and I'll add the ones that fit.

## For other mods

`mod.find("name_tags").exports.nameFor(speciesId, game)` returns a fresh name for a species, in the player's LETTERS setting and switched-on sets, skipping names already in use. It has no Pokémon to read a gender from, so any name can come back. Useful for a rename tool or a reroll button. `exports.version` is 1.

## Tests

`luajit tests/run_tests.lua` from this folder checks every list line, the picker, the sets, gender, the NO answer and the hook and event wiring.

## Credits

Made by Elvie. Idea from a request on the gen1recomp Discord, with thanks to everyone in that thread. The Gen 1 gender rule is the one from my Gen 1 Gender mod. The canon names come from the games, anime and manga, gathered with help from Jdrawer's list of Pokémon with nicknames on Bulbapedia. The other name lists were written for this mod and are free to use with credit.
