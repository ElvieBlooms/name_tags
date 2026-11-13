# Changelog

## 1.3.0

Trainer achievements for Red, Blue, Yellow and the Gen 3 games, now that engine 0.4.4 shows trainers' names there.

- Lightning Rod now counts in Red, Blue, Yellow, FireRed and LeafGreen too.
- New for the Kanto games (and Gold, Silver and Crystal): **Rock Solid** (Brock), **Tangled Up** (Erika's Angela) and **Kanto Classics** (Brock, Lt. Surge and Erika).
- New for Ruby, Sapphire and Emerald: **Hot Spring** (Flannery), **Royal Court** (all of Wallace's named Pokémon), **Iron Will** (Steven's Iron) and **Hoenn Headliners** (all three).
- Name Recognition, Hometown Heroes, Fafa and MilMil, and Red's four stay in Gold, Silver and Crystal.
- Gen 3's double battles count either foe Pokémon that's out.

## 1.2.0

Achievements, for players with Recomp Achievements installed.

- 14 achievements on their own **NAME TAGS** tab: nine for catches in every game (first name, 25 and 100 names, a canon name on its own family, a type name, baked goods, a full party from one set, a hidden one for pop culture), and five for canon trainers in Gold, Silver and Crystal (Lt. Surge's Volty, Red's four, Whitney's two, 10 named Pokémon faced, five trainers).
- Recomp Achievements is an optional dependency. Without it, nothing changes.

## 1.1.0

Trainers' Pokémon get names too, and canon nicknames from the games, anime and manga join the mix.

- New **TRAINER TEAMS** option. **CANON** (the default) gives trainers their canon names: Lt. Surge's Volty, Jasmine's Rusty, Erika's Angela, Whitney's Fafa and MilMil, Brock's Geo brothers and Hornlette, Red's Pika, Vee, Snor and Saur, Flannery's Meg and Mag, Wallace's four, and Steven's Iron. **ALL** names every trainer's Pokémon from your sets. **OFF** leaves them alone.
- A trainer's names are the same every time you battle them.
- New **CANON** set: nearly 300 nicknames from the games, anime and manga, for the species they belonged to and their families. Canon names skip the gender filter, since they're what a real Pokémon was called.
- New **BAKED GOODS** set: breads, cakes, pastries, pies and cookies, and nothing fried or griddled, with its own type names (a Rock type might be Biscotti, an Ice type Meringue). It starts ON. Leave only it on for a bakery team.
- Name files can name a trainer's own Pokémon with a `[trainer Name: SPECIES ...]` header.
- Trainer names show in Gold, Silver and Crystal today. Red, Blue, Yellow and Gen 3 need a small engine change, suggested upstream. Until then nothing changes in those games.

## 1.0.0

First release. Every Pokémon you catch gets a name of its own, picked at random from themed sets and matched to its gender.

- Works in Red, Blue and Yellow, Gold, Silver and Crystal, and the Gen 3 games.
- Nearly 2,400 different names in ten sets: PEOPLE, PETS, FOOD, NATURE, MYTHS, SPACE, TYPES, SPECIES, POP CULTURE and MEMES. Each has its own ON/OFF row. POP CULTURE and MEMES start OFF.
- Names follow gender: male, female and neutral, with genderless Pokémon getting neutral names only. Gen 1 uses the same Attack DV rule as the Gen 1 Gender mod.
- Gen 1 asks nothing. In Gen 2 and Gen 3 the game still asks "Give a nickname to...?", and Name Tags answers NO for you.
- Options: CATCHES, GIFTS, LETTERS, THEMED NAMES, MATCH GENDER and NICKNAME QUESTION.
- Names are plain text in names/. Any .txt file added there becomes a set of its own.
