# Game concept: Haven — Bounce Back

All names and mechanics below are proposals for the team, not finished features.

## The pitch

Haven is a once-thriving refuge powered by an unstable energy core. After the core fractures, rival recovery teams enter a training arena built from its ruins. Players compete to recover energy and prove they can bring Haven back. Every hit can knock a fighter off course—but skilled fighters use that force to return stronger.

A stylized, fast 3D arena shooter where movement, ricochets, and comebacks give the name **Bounce Back** meaning. The same arena can support offline bot matches, a future online mode, and short story encounters.

## Core experience

1. Pick a mode and difficulty from the home screen.
2. Enter the arena, move between cover, aim, and fire.
3. Collect a small amount of rebound energy by surviving hits or using arena bounce surfaces.
4. Spend a full meter on a short **Bounce Back dash**: a directional burst that helps escape, return to the fight, or reach higher ground. It is not automatic invulnerability.
5. Score eliminations or recover energy for your team, then see results and replay.

Prototype a simple shot and dash first. If knockback or energy gain rewards losing too much, cap the charge and tune it through playtests. Players should always have a chance to understand what hit them.

## Modes and home screen

- **Play vs bots:** choose easy, medium, or hard, then start a match. This is the first playable target.
- **Online:** later, create or join a private lobby with a code or address, select a mode, and play with friends. Show connection errors clearly; avoid promising public matchmaking for the jam.
- **Story:** short narrated missions using the same arena and bots; begin with a brief intro and one encounter rather than a long campaign.
- **Settings:** mouse sensitivity, sound, fullscreen/windowed, and controls. Include a quit button.

First match idea: free-for-all, one human plus two or three bots, first to five eliminations or a three-minute timer. Respawn after a short delay. Exact numbers are placeholders to test.

## The arena

**The Core Yard:** a wide industrial courtyard within the damaged Haven. A central energy core is surrounded by two elevated walkways, cover, and distinct routes on either side. Bright bounce pads offer visible movement choices; no large empty open area. Use silhouettes and color to help players navigate. Start with one compact grey-box map, then expand only if matches need more room. A big-feeling map still needs enough encounters to stay fun.

Potential interaction: a timed energy surge activates several bounce pads, briefly changing routes. Add this only after movement, shooting, bots, and match flow work.

## Weapons and bounce mechanics

- **Pulse blaster:** the default, straightforward projectile with readable feedback. Limit shots or add a short cooldown.
- **Ricochet shot:** a later weapon or alternate fire whose projectile can bounce once off marked hard surfaces. Show a distinct color and prevent infinite bouncing.
- **Bounce pads:** launch anyone who steps on them; use clear colors and sounds.
- **Bounce Back dash:** earned recovery movement, with a meter, cooldown, and a visible effect. Tune to keep aim and movement fair.

Start with a single weapon; additional weapons are optional. Decide early whether the camera is first-person or third-person: first-person is a simpler starting point for a small team, while third-person displays character animation and identity better.

## Bots and difficulty

Use navigation and straightforward behavior states: patrol, spot a target, chase or take cover, aim/fire, and recover or respawn. Easy/medium/hard are tuning profiles for the same behaviors, not separate AI systems:

| Difficulty | Reaction and aim | Movement |
| --- | --- | --- |
| Easy | Slower reactions, wider aim spread, longer pauses | Moves between a few points; gives the player time |
| Medium | Moderate reaction and accuracy | Chases and sometimes seeks cover |
| Hard | Faster reactions, better but imperfect aim | Uses cover and bounce pads more often |

Test that all profiles miss sometimes and obey the same health and movement rules as the player. Avoid bots tracking players through walls. Keep navigation simple on the first map.

## Story direction

**Opening:** Haven's core has broken, and a pilot enters the Core Yard to train for a recovery mission. The arena's AI, Echo, guides them. During the match a surge suggests that the core might still be alive.

**Three possible beats:** train against a bot; survive a sudden energy surge; recover a core fragment and hear Echo hint at the next mission. Deliver through a few text cards, arena details, and a results-screen reveal. The concept can expand later into several arenas and rival teams; avoid building a full campaign before a match is fun.

## Online design direction

Design gameplay so the same match rules work with player and bot participants. A later private host/join prototype needs an authoritative host for hits, health, and scores; synchronized player movement; lobby setup; disconnect handling; and real tests on separate devices and networks. Godot's high-level multiplayer can be investigated for this, but connection setup, hosting, latency, and security require dedicated work. Test a local offline match first. Public matchmaking, accounts, anti-cheat, and dedicated servers are outside the initial jam scope.

## Look, sound, and accessibility

Aim for a cohesive stylized sci-fi look: dark metal and warm Haven architecture with cyan energy and orange danger markers. Prioritize clear targets, strong hit feedback, legible UI, and responsive controls before extra visual effects. Use short sounds for firing, damage, respawn, charging, and victory. Provide volume and sensitivity controls, and avoid relying on color alone for important cues.

## Choices for the team

1. First-person or third-person camera?
2. How much jam time and how many developers are available?
3. Does online multiplayer need to be in the submitted build, or can it be a later milestone?
4. Is the game intended for Windows only, or other platforms too?
5. Is the story tone hopeful and colorful, or darker and more serious?
6. Are there tournament rules about themes, allowed assets, code reuse, or online play?
