# Haven: Bounce Back

Haven fell silent, but its memories are still alive. Fight through three arenas to help the AI Echo recover the people and places that made the city home.

## Open and play

1. Download [Godot 4.6.3 Standard](https://godotengine.org/download/archive/4.6.3-stable/) for your computer.
2. On GitHub, choose **Code → Download ZIP** and extract the complete ZIP, or clone this repository.
3. Open Godot, choose **Import**, select `project.godot` inside the extracted folder, and click **Import & Edit**.
4. Let Godot import the assets. Press **F5** to run the project. Enter Haven and choose **Play vs AI** or **Story Missions**.

The `.godot` cache is created locally and is intentionally not included. Imported resources may take a few minutes on first opening. Windows, Linux and macOS use the appropriate Godot editor for that platform. Export templates are only needed when exporting a standalone game.

## Controls

| Control | Action |
| --- | --- |
| W / A / S / D | Move |
| Mouse | Look and aim |
| Left mouse | Fire |
| Space | Jump |
| Q | Rebound dash (three-second cooldown) |
| Esc | Match menu; pauses offline matches |

Aim at the enemy and recover eight echoes within three minutes. You have three lives and a brief protection period after respawning. Easy, Medium and Hard change the bots' speed, aim and fire rate. A victory earns coins; spend them in **Loadout** to unlock and equip different weapons. Coins, unlocks, story progression, and settings are stored locally on your own device.

## Modes

- **Play vs AI:** pick Core Courtyard, Transit Station, Overgrown Garden or Random; select difficulty and fight four bots.
- **Story Missions:** three linked missions unlock in order. The opening is an animated flyover with text and can be revisited from Story Missions.
- **Online Multiplayer:** private host/join matches for up to four players. The host chooses the map. First to eight eliminations wins. Choose one of three soldier appearances; it is visible to other players in online matches. Online matches do not include bots.
- **Settings:** change master volume and mouse sensitivity.

### Online connection

For a same-network test, the host chooses **Online Multiplayer → Host a Match** and gives the other player their computer's local IP address. The joining player enters it under **Host Address**. The match uses UDP port **7777**. Both players need the same project version, and a firewall may need to allow it. `127.0.0.1` works only when host and client run on the same computer. Internet play may require router port forwarding or a networking service and has not been verified across two separate networks. Play with trusted friends: this direct-connect implementation does not include matchmaking, account systems, encryption, or robust anti-cheat.

## Assets and project status

Models and sounds from third-party artists are included under their stated licences; see [asset credits](docs/ASSET_CREDITS.md). We used a small selection of downloaded materials, not complete purchased packs. Some 3D materials are generated in the project. The project currently uses simple arena architecture and a brief text-led story; it does not yet have the cinematic, character animation, visual polish, and production scale of a finished AAA shooter. It needs a real playtest on the team's target hardware and a two-device network test before tournament use.

The design brainstorm, roadmap and engine decision in `docs/` are historical planning documents; this README describes what is currently implemented.

## Technical checks

After opening/importing once, run `godot --headless --path . --script res://tests/smoke.gd` to exercise match flow, shooting, map creation, saving and story unlocks. The network check in `tests/network_peer.gd` launches as separate host and client processes; it checks localhost connectivity rather than real internet conditions.
