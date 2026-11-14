# Game-jam roadmap

The final deadline, team size, target platform, and tournament rules are not yet known. Treat this as a priority order, not a promise about schedule.

## 1. Prove the fun — first playable

- Create a Godot 4 project; agree on the exact editor version and commit `project.godot` and source scenes.
- Build a small grey-box arena with cover and safe spawn points.
- Implement one player, movement, camera, aiming, one weapon, damage and respawn.
- Add one bot that can navigate, see and shoot the player without seeing through walls.
- Add a score limit, timer, results screen and restart.
- Add one bounce pad and experiment with the Bounce Back dash.
- Playtest continuously: is movement responsive, is it clear why you were hit, and is the match fun for three minutes?

**Done when:** a fresh player can launch a build, understand the controls, complete a match against a bot, and replay without a blocker.

## 2. Make it a presentable offline game

- Add a home screen, bot difficulty selector, more bots, and pause/settings.
- Add a short story intro and a results-screen reveal.
- Replace selected blockout assets with a consistent licensed art set; add audio, effects, readable HUD and accessibility settings.
- Test on the target platform, fix critical bugs, and package a build before the deadline.

## 3. Stretch goals

- Prototype private online host/join; test with two machines and a real network before presenting it as working.
- Add a ricochet weapon, energy surge, or extra story encounter only if the core is stable.
- Expand the arena and bot behaviors based on actual playtests.

If online play is a mandatory tournament requirement, move its minimal two-player connectivity test to the first milestone so feasibility is established early. If the core is behind schedule, reduce bot count, map size, and story length rather than skipping match completion or testing.

## Suggested Godot organization

Once implementation begins: `project.godot` at the root; `scenes/` for menus, arena, player and bots; `scripts/` for behavior; `assets/` for art and sound; and `docs/` for design and asset credits. Keep third-party license information with the project. Use placeholders until the interaction is fun.
