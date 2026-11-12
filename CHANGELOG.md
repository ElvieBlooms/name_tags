# Changelog

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
