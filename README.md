# Haven: Bounce Back

Hostile AI has taken over Haven. As the last known human survivor, fight through different arenas, recover lost memories, and help Echo bring the city back.

## Open the game

1. Download [Godot 4.6.3 Standard](https://godotengine.org/download/archive/4.6.3-stable/).
2. On GitHub, choose **Code → Download ZIP** and extract it, or clone the repository.
3. Open Godot, choose **Import**, select `project.godot` inside the extracted folder, and choose **Import & Edit**.
4. Wait for the first asset import to finish, then press **F5** to run. Pick a guest or local player name and follow Echo's introduction.

If you have an older ZIP, download the latest one into a new folder and import its `project.godot`. Keep the entire extracted folder together.

## Accounts and saved progress

Choose **Sign up**, **Sign in**, or **Play as guest** when the game opens. Accounts are local to this computer, not cloud accounts. Sign up with a username and a game-specific password of at least eight characters; sign in after restarting to restore your display name, coins, unlocks, gear, story progress, character, ID, friends and settings. Account usernames are unique without regard to letter case; display names can be changed separately. Settings contains **Sign out**.

Guest play is temporary and cannot overwrite account progress. Launching the game no longer deletes saved progress. Passwords are stored as salted PBKDF2-HMAC-SHA256 verifiers, not plaintext. There is no email recovery or cross-device sync; keep your game-specific password somewhere safe. Local files can be modified by someone with access to your computer; this is not server authentication or anti-cheat.

Saves live in Godot's user-data folder under `haven_accounts`. Back up that entire directory to preserve account credentials and progress. Saves are written through a temporary file before replacing the previous save. A damaged save produces an error instead of silently resetting progress.

## Play

| Control | Action |
| --- | --- |
| W / A / S / D | Move in any direction |
| Mouse | Look and aim |
| Left mouse | Fire a visible pulse |
| Shift | Sprint |
| Space | Jump |
| Q | Dash |
| E | Dodge roll (brief protection and a cooldown) |
| Esc | Match menu; pauses solo matches |

Choose from three different human fighters. Find glowing beams in the arena: **green** restores health, **blue** adds shield, and **gold** recharges your dash. The health and shield indicators are at the bottom of the screen.

- **Vs Bots:** pick an arena and difficulty. Recover eight echoes before time expires; you have three lives.
- **Survival:** fight increasingly tough waves without a timer. Clear each wave to earn coins, and continue until all lives are used.
- **Story Missions:** five playable levels unlock in order. Echo gives short briefings that you can advance with **Next**.
- **Market & Loadout:** spend earned coins on different weapons, a shield, armor, headgear and a stronger dash. Pictures and descriptions explain each item; an unaffordable purchase displays a message. Gear bonuses and pickups work in solo and story/survival; online stats remain balanced and headgear is cosmetic.
- **Arenas:** AI Citadel, Desert Outpost, Overgrown Garden, Archive Vault and Skyline Yard have different scenery and layouts. Choose one or select Random.
- **Help:** controls, FAQs, a community code of conduct and support details.

The UI uses a warmer palette, readable type, and animated bot backgrounds on menu pages. Fighters use imported human models and animation clips. The arenas and animation are still stylized and much simpler than a large commercial game.

### Friends and online matches

Signed-in accounts keep a stable 128-bit random Haven ID and local friend bookmarks. IDs are not centrally registered, so global uniqueness cannot be guaranteed. Friends are **local bookmarks**, not reciprocal requests; search covers saved and recent private-match players on this device only. Guest profiles and friends are temporary. Global search, Google sign-in and cross-device accounts require an online account service.

For a private same-network match, one player chooses **Online Multiplayer → Host a Match** and shares their computer's local IP address. The other player enters it under **Host Address**. The game uses UDP port **7777**; both players need the same version, and a firewall may need to allow it. `127.0.0.1` works only for two instances on the same computer. Internet play may need router port forwarding or a networking service and has not been verified across separate networks. Play with trusted friends; this direct connection has no matchmaking, encryption or robust anti-cheat.

## Credits and tests

See [asset credits](docs/ASSET_CREDITS.md) for models, sounds, textures, skies and fonts. The historical design documents may describe earlier ideas rather than the current game.

After importing once, run `godot --headless --path . --script res://tests/smoke.gd` to exercise match flow, movement, actions, maps, the market, pickups, survival and local accounts. `tests/network_peer.gd` checks host/client communication on one machine; it is not a two-device internet test.

### Environment quality update

The forest and desert now use premade Poly Haven scanned assets rather than sphere trees and primitive cover. The forest includes wind-driven trees, ferns and grass plus three foxes with a native walking animation. The desert has rocky escarpments, cracked ground and ribbed cacti. Natural arena boundaries are concealed behind scenery; the combat area remains 50 metres wide. The original home-page design is retained.

Human fighters now use Quaternius Universal Base Characters with detailed faces, hairstyles, adult proportions, field-suit material variants and the matching Universal Animation Library. These replace the earlier cartoon models. The levels are assembled from licensed assets, not imported complete premade maps. Attribution and modification details are in `docs/ASSET_CREDITS.md`.

The richer scenery uses more GPU memory and geometry. A dedicated GPU is recommended; performance on your machine needs checking. Four-sample MSAA is enabled; reduce `Rendering > Anti Aliasing > Quality > MSAA 3D` in Project Settings if needed. Existing controls, survival and purchases remain available. Signed-in accounts now persist between launches; guests remain temporary.

Run `godot --headless --path . --script res://tests/accounts.gd` to verify account creation, wrong-password rejection, account isolation, restart persistence, guest isolation and damaged-save handling.

Shots now use tapered bright cores and fading tracer shells, muzzle flashes, surface-aligned impact rings and sparks. Pulse Rifle, Scatter Blaster and Longshot use distinct local tracer colours; the scatter weapon draws all seven local pellets. Hits still use immediate raycasts; projectile travel is a visual effect. `tests/shots.gd` checks miss handling, impact effects, cleanup and pellet visibility.

### Opening screens and pursuing bots

The opening screen and lobby use a charcoal, ivory and burnt-orange palette, a brighter live 3D backdrop, a human character showcase and one clear primary play action. Supporting menus use the same neutral controls.

Bots now share a collision-clearance pathfinding grid built once per match. They pursue the player around cover instead of stopping at 13 metres. Ground robots play their native running animations. The three robot types use different fighting distances; the flanker repositions, while the closer-range robot presses forward. Bots keep separation from teammates, require line of sight to fire, and give a brief reaction window after acquiring the player. Difficulty still controls speed, attack frequency and accuracy. `tests/bot_navigation.gd` checks pursuit, cover routing, animation, blocked shots and respawn.
