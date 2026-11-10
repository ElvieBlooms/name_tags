# Name Tags

Every Pokémon you catch gets a name of its own, picked at random from themed sets: people, pets, food, nature, myths, space, and names that only suit a certain type or species. Pop culture and meme names are there too, for when you want them. A Fire type might come out as **Cinder** or **Sriracha**, a Ninetales as **Kyubi**, an Umbreon as **Licorice**, and a Ditto as **Frankie**.

Names follow the Pokémon's gender: a female gets female and neutral names, a male gets male and neutral names, and a genderless Pokémon (Magnemite, Staryu, Ditto) gets neutral names only.

If you have a better name in mind, the Name Rater still works as usual.

Works in Red, Blue and Yellow, Gold, Silver and Crystal, and the Gen 3 games.

## What happens after a catch

- **Gen 1:** no question. The Pokémon just has its name.
- **Gen 2 and Gen 3:** the game still asks "Give a nickname to SIENNA?", and Name Tags answers NO for you. The question is up for about a second in Gold, Silver and Crystal, and about two in the Gen 3 games, where the text has to finish first. The engine doesn't yet let a mod skip that question in these games. Once it does, Name Tags skips it there too, with no update needed.

## Options

Set these in the mod manager.

- **CATCHES**: **AUTO** names every catch. **ASK** leaves catches to the game, the way it is without the mod.
- **GIFTS**: starters, Eevee, Lapras, fossils and the other gifts. **ASK** by default, so the Pokémon you're handed at the start is still yours to name. **AUTO** names them too. That's tested in Gen 1. Gen 3 gifts take the name, but their own nickname question may still appear, and Gen 2 gifts aren't named yet.
- **LETTERS**: **CAPS** (MABEL) matches the game's own names. **Mixed** (Mabel) writes them as people do.
- **THEMED NAMES**: how often a type or species name is picked over a general one, when one fits. **SOMETIMES** is about two catches in five, **OFTEN** about three in four.
- **MATCH GENDER**: **ON** keeps male, female and neutral names to Pokémon of that gender. **OFF** lets any name go to any Pokémon.
- **NICKNAME QUESTION** (Gen 2 and Gen 3): **ANSWER NO** lets Name Tags answer for you. **ASK ME** leaves the question up, so you can press YES and pick your own name.
- One row per set: **FOOD**, **MEMES**, **MYTHS**, **NATURE**, **PEOPLE**, **PETS**, **POP CULTURE**, **SPACE**, **SPECIES**, **TYPES**. All start **ON** except **MEMES** and **POP CULTURE**, which start **OFF**, since they aren't the everyday names the rest stick to. Leave only **FOOD** on for a team of snacks.

## How names are picked

- A name already worn by a Pokémon in your party, your boxes or the Day-Care isn't picked again. Only once every name is taken does it allow repeats.
- Every name has the same chance, so a bigger set comes up more often than a small one.
- A dual-type Pokémon can draw from both types' names. Some sets have their own type names too: the Food set gives Fire types Chili or Jalapeno, and Water types Sushi or Chowder.
- **Gender:** Gold, Silver, Crystal and the Gen 3 games say what each Pokémon is. Gen 1 has no gender, so Name Tags works it out the way Gold, Silver and Crystal do for a Pokémon traded forward, from its Attack DV and species. That's the same rule as the Gen 1 Gender mod, so the name always matches the symbol it draws. A gift is named before the game has made the Pokémon, so a gift can get any name.
- A name that's male or female in People or Myths is kept out of the other sets, so a female Pokémon is never named Rufus from the pet list.
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
```

- **[male]**, **[female]** and **[neutral]** follow the Pokémon's gender. **[nonbinary]** and **[unisex]** work the same as **[neutral]**.
- **[all]**, **[type ...]** and **[species ...]** go to any Pokémon that fits, whatever its gender.
- Headers use the game's own ids. Types: FIRE, WATER, PSYCHIC, DARK, STEEL and the rest. Species: NINETALES, MR_MIME, NIDORAN_F, FARFETCHD. Underscores don't matter, so Gold's MR__MIME matches MR_MIME. A header can name several.

What makes a good name for the list: something you could call a living thing out loud. People names from anywhere, pet names, a word that works as a name (Pepper, Juniper). Not usernames (EZFrank32), not jokes that only work once, and outside the Pop Culture set, not the names of well-known characters or brands. Lines that break the letter rules are skipped and named in the log with their file and line, so a typo never stops the mod loading.

The Memes set leaves out memes with hateful histories, memes that mock a group of people, and memes about real people's looks. Please keep it that way when you send names for it.

Suggestions are welcome on the Discord. Send them as a list and I'll add the ones that fit.

## For other mods

`mod.find("name_tags").exports.nameFor(speciesId, game)` returns a fresh name for a species, in the player's LETTERS setting and switched-on sets, skipping names already in use. It has no Pokémon to read a gender from, so any name can come back. Useful for a rename tool or a reroll button. `exports.version` is 1.

## Tests

`luajit tests/run_tests.lua` from this folder checks every list line, the picker, the sets, gender, the NO answer and the hook and event wiring.

## Credits

Made by Elvie. Idea from a request on the gen1recomp Discord, with thanks to everyone in that thread. The Gen 1 gender rule is the one from my Gen 1 Gender mod. The name lists were written for this mod and are free to use with credit.
