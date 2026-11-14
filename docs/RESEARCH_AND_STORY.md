# Research and story direction — 14 November 2026

This is a brainstorm, not a finished game. The team's existing maps and the tournament rules have not been supplied or checked.

## A hidden meaning of Bounce Back: echoes

Haven's emergency system, ECHO, saved fragments of people's memories when the city fell. The arena is a simulation used to reconstruct those memories. Every opponent is an echo of someone who helped build Haven. Players think they are fighting for a prize, then discover that their matches are helping the city remember its people. The thing that bounces back is a community's hope, carried from one person to another.

As the player wins offline matches, they earn coins for weapon sidegrades and recover a memory fragment for the story. These are separate rewards; the arena mode remains fun on its own. Begin with short text and simple animation, then add voice, effects, and richer cinematics if time permits.

### Opening cutscene proposal (30–45 seconds)

1. A quiet aerial view of the ruined courtyard. Dim lights flicker on as a signal spreads across Haven.
2. Echo appears as a small robot or hologram. “Haven remembers pieces. Help me find the rest.”
3. Several distinct fighters materialise from light. A pulse reveals their silhouettes to be incomplete.
4. The gate opens; a quick montage shows a firefight across a courtyard and other locations.
5. Title: **HAVEN: BOUNCE BACK**. Continue to the home screen. Optional: allow the player to skip or replay it.

Early twist: a defeated opponent's voice seems familiar. Later reveal: the fighters are echoes, and restoring Haven means piecing their stories together. This does not require explaining the entire story before the first match.

Alternative interpretations: (1) a team restores a shared city and every victory visibly repairs it; (2) an unreliable arena AI replays the consequences of past choices. The echo concept is the recommended starting point, not an established decision.

## Match, maps, progression, characters

- Home screen: Play vs AI, Online, Story, Loadout, Settings.
- AI setup: pick Easy/Medium/Hard and a map, or select random; start a match and earn coins when the player beats bots.
- Online: host/join private matches; host selects a map or random; a spinner is a visual reveal of a random choice rather than a requirement for selecting it. Avoid promising working online matchmaking until networking is implemented and tested.
- Arena ideas: Core Courtyard; a tight abandoned transit station; an elevated energy plant with walkways; and a garden overgrown around old technology. These are ideas, not existing or downloaded maps. The user's own maps can be evaluated when provided.
- Weapon progression: start with a balanced pulse rifle; unlock a close-range scatter blaster, precise marksman rifle, and slower energy launcher using earned coins. Make each a sidegrade with strengths and weaknesses rather than an automatic upgrade; the starting weapon should remain viable online. The downloaded files are visual models, not working weapons.
- Avatars: distinct silhouettes, colours and outfits for a Scout, Engineer, Guardian and the robot guide Echo. Character assets, animation retargeting and customization still need to be integrated and tested. Start with cosmetic differences to keep multiplayer balanced.
- Physical bounce remains a possible optional movement mechanic; the emotional meaning is the central theme.

## Downloaded research assets

These are stored locally in `research-assets/`; they have not been imported into Godot or added to a remote repository. ZIP integrity tests passed. Keep the models and textures together when importing and verify materials, scale, animations and performance in the Godot version the team chooses.

| File | Author and source | Contents and limits | License evidence |
| --- | --- | --- | --- |
| `models.zip` | Quaternius, [Sci-Fi Essentials Kit on OpenGameArt](https://opengameart.org/content/sci-fi-essentials-kit) | Free Standard subset: 37 glTF models including robot enemies, guns and props, with corresponding FBX/OBJ files. This is not a complete arena. | Downloaded ZIP states CC0 1.0. |
| `textures.zip` | Quaternius, [same source](https://opengameart.org/content/sci-fi-essentials-kit) | 36 PNG textures for the kit. | Same creator's listing identifies the release as CC0. |
| `animated-robot.zip` | Quaternius, [Animated LowPoly Robot on OpenGameArt](https://opengameart.org/content/animated-lowpoly-robot) | One robot, FBX/Blend/OBJ; the [itch.io page](https://quaternius.itch.io/lowpoly-robot) lists 14 animations. Import and animation compatibility not yet tested. | Downloaded ZIP states CC0 1.0. |

SHA-256: models `f5cb9382a029730f9fa8f93e7fdb103c1aaaec094a22b1397833ce0e48bd1016`; textures `d80b61c7be7200c68e584f25292df6d0620516d5eb4d2043aec2cc54decb1e55`; robot `5128d2cf906835895b931f6c1e764296ba2e01d3a30d809035fc6c1ee8a1c1ee`.

## Additional candidates, not downloaded

- [Universal Base Characters](https://quaternius.itch.io/universal-base-characters): six humanoid base models; page labels CC0. Verify free-version contents and rig compatibility; actual unique outfits and animated avatars require work.
- [Universal Animation Library 2](https://quaternius.itch.io/universal-animation-library-2): humanoid animations; page labels CC0. Requires retargeting and validation in the chosen Godot project.
- [Modular Sci-Fi MegaKit](https://quaternius.itch.io/modular-sci-fi-megakit): modular environment pieces; page labels CC0. Free Standard and paid tiers differ; not a ready-made map.

Godot [recommends glTF 2.0](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html); some of the robot formats need extra import steps. Check the exact downloaded licences, competition rules, and any map-specific permissions before integrating or redistributing assets. Credit the artists even where optional.
