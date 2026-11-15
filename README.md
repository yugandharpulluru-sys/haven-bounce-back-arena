# Haven: Bounce Back

Hostile AI has taken over Haven. As the last known human survivor, fight through different arenas, recover lost memories, and help Echo bring the city back.

## Open the game

1. Download [Godot 4.6.3 Standard](https://godotengine.org/download/archive/4.6.3-stable/).
2. On GitHub, choose **Code → Download ZIP** and extract it, or clone the repository.
3. Open Godot, choose **Import**, select `project.godot` inside the extracted folder, and choose **Import & Edit**.
4. Wait for the first asset import to finish, then press **F5** to run. Pick a guest or local player name and follow Echo's introduction.

If you have an older ZIP, download the latest one into a new folder and import its `project.godot`. Keep the entire extracted folder together.

## Important: every run resets

As requested for this version, **every time the game is launched from Godot, it deletes the local save and starts fresh**. Coins, weapon and equipment unlocks, story levels, settings, local name, Haven ID and the local friends list reset. Your support contact in the Help screen is part of the game and does not change. A new local ID is generated after you choose a name; share that new ID with friends each run.

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

The optional local name is not a password-protected account. The 128-bit random Haven ID is not centrally registered or verified, so global uniqueness cannot be guaranteed. Friends are **local bookmarks**, not reciprocal requests; search covers saved and recent private-match players on this device only. Restarting the game clears the profile, ID and friends. Global search, lasting friend lists, Google sign-in and cross-device accounts require an online account service.

For a private same-network match, one player chooses **Online Multiplayer → Host a Match** and shares their computer's local IP address. The other player enters it under **Host Address**. The game uses UDP port **7777**; both players need the same version, and a firewall may need to allow it. `127.0.0.1` works only for two instances on the same computer. Internet play may need router port forwarding or a networking service and has not been verified across separate networks. Play with trusted friends; this direct connection has no matchmaking, encryption or robust anti-cheat.

## Credits and tests

See [asset credits](docs/ASSET_CREDITS.md) for models, sounds, textures, skies and fonts. The historical design documents may describe earlier ideas rather than the current game.

After importing once, run `godot --headless --path . --script res://tests/smoke.gd` to exercise match flow, movement, actions, maps, the market, pickups, survival and resets. `tests/network_peer.gd` checks host/client communication on one machine; it is not a two-device internet test.

### Environment quality update

The forest and desert now use premade Poly Haven scanned assets rather than sphere trees and primitive cover. The forest includes wind-driven trees, ferns and grass plus three foxes with a native walking animation. The desert has rocky escarpments, cracked ground and ribbed cacti. Natural arena boundaries are concealed behind scenery; the combat area remains 50 metres wide. The original home-page design is retained.

Human fighters now use Quaternius Universal Base Characters with detailed faces, hairstyles, adult proportions, field-suit material variants and the matching Universal Animation Library. These replace the earlier cartoon models. The levels are assembled from licensed assets, not imported complete premade maps. Attribution and modification details are in `docs/ASSET_CREDITS.md`.

The richer scenery uses more GPU memory and geometry. A dedicated GPU is recommended; performance on your machine needs checking. Four-sample MSAA is enabled; reduce `Rendering > Anti Aliasing > Quality > MSAA 3D` in Project Settings if needed. Existing controls, survival, purchases and reset-on-launch behaviour are unchanged.
