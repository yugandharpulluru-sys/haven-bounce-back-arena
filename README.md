# Haven: Bounce Back

Haven fell silent, but its memories are still alive. Fight through five levels and help Echo recover the people and places that made the city home.

## Open and play

1. Download [Godot 4.6.3 Standard](https://godotengine.org/download/archive/4.6.3-stable/) for your computer.
2. On GitHub, choose **Code → Download ZIP** and extract the ZIP, or clone this repository.
3. Open Godot, choose **Import**, select `project.godot` inside the extracted folder, and choose **Import & Edit**.
4. Wait for Godot to import the assets, then press **F5**. On first opening, choose a local player name or play as a guest, and follow Echo's introduction.

If you downloaded the game before this update, download and extract the latest ZIP into a new folder, then import that folder's `project.godot`. Keep the entire extracted folder together. The `.godot` cache is created locally and is not included in the repository. The first import can take a few minutes.

## Controls

| Control | Action |
| --- | --- |
| W / A / S / D | Move in third person |
| Mouse | Look and aim |
| Left mouse | Shoot |
| Space | Jump |
| Q | Dash |
| Esc | Match menu; pauses solo matches |

Aim at opponents and recover eight echoes within three minutes. You have three lives and brief protection after respawning. Glowing pickups restore health or shields or recharge your dash. Health and shield appear on the HUD.

## Levels, equipment and story

- **Story Missions:** five levels unlock in order, with Echo's dialogue and a Next Level option after a win.
- **Play vs AI:** choose Core Courtyard, Transit Station, Overgrown Garden, Archive Vault, Skyline Yard, or Random, then choose bot difficulty.
- **Market & Loadout:** win coins to buy and equip weapons, a shield, armor, headgear, and a super dash. Equipment bonuses and pickups work in solo and story matches. Online matches use balanced equipment stats; headgear remains cosmetic there.
- **Online Multiplayer:** private host/join matches for up to four players; the host chooses the map. First to eight eliminations wins. Choose one of three soldier appearances. Online matches do not include bots.
- **Friends:** copy your local Haven ID; add a friend by ID and name; search saved friends and recent private-match players; optionally save a host IP and join a friend.
- **Help:** review controls and the community code of conduct.
- **Settings:** change master volume, mouse sensitivity, and local player name.

A guest or local player name and all coins, unlocks, progress and settings are saved on the current device. A Haven ID is generated from 128 random bits and saved with the local profile; it is not centrally registered or verified, so uniqueness across all devices cannot be guaranteed and copying a save also copies the ID. The local name is not a password-protected account and is not shared between devices. Google sign-in and cloud saves are not configured.

The friends screen is a local address book: it can search only people you saved or encountered in a private match, not every player in the world. Adding someone is a local bookmark, not a reciprocal friend request. Players can share names, and the ID distinguishes local entries. Joining requires the host's IP address and network connectivity. Global player search, verified IDs and two-way friends require an online account service.

### Online connection

For a same-network test, the host chooses **Online Multiplayer → Host a Match** and gives the other player the host computer's local IP address. The joining player enters it under **Host Address**. The match uses UDP port **7777**. Both players need the same project version, and a firewall may need to allow it. `127.0.0.1` works only when host and client run on the same computer. Internet play may require router port forwarding or a networking service and has not been verified across separate networks. Play with trusted friends: this direct-connect implementation does not include matchmaking, account systems, encryption, or robust anti-cheat.

## Assets and project status

Models, sounds and font from third-party artists are included under their stated licences; see [asset credits](docs/ASSET_CREDITS.md). The arenas use simple architecture, and character movement/shooting use procedural animation; further art, voice, animation and gameplay polish is needed to approach a finished high-end shooter. Test the game on the team's target hardware and test online play on two devices before tournament use.

The original brainstorm, roadmap and engine decision in `docs/` are historical planning documents; this README describes the current implementation.

## Technical checks

After opening/importing once, run `godot --headless --path . --script res://tests/smoke.gd` to exercise movement, shooting, maps, equipment, pickups, saving, local ID/friends and level unlocks. The network check in `tests/network_peer.gd` launches as separate host and client processes; it checks localhost connectivity, including visual shot messages, rather than real internet conditions.
