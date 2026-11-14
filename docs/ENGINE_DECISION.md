# Engine decision

Choose **Godot 4.6.3 stable, standard edition**, for the first prototype. The user already knows Godot and this version is installed in the development environment. Using the same version across the team reduces compatibility surprises. The game and the project file have not yet been created.

Godot is MIT licensed, supports 3D navigation and a high-level multiplayer API, and recommends glTF 2.0 for 3D imports. This suits a code-driven arena shooter and the researched assets. Online lobbies, hosting and synchronization still require implementation and testing; the engine does not automatically supply a production multiplayer service.

GDevelop has real 3D and multiplayer tools and is a reasonable no-code option; its hosted multiplayer and publishing features have free-plan limits. Unreal offers advanced 3D tooling but has a steeper learning/setup burden and conditional royalty terms. For a game jam and this team's existing experience, Godot is the recommended balance rather than a claim that it is universally the most powerful engine.

No special paid ChatGPT or Godot plugin is needed for a file-based workflow. The connected GitHub app can access authorized repository contents but did not have permission to create a repository; once the user creates `haven-bounce-back-arena` and grants the app access, transfer the work there.

Sources: [Godot license](https://godotengine.org/license/), [Godot downloads](https://godotengine.org/download/archive/4.6.3-stable/), [3D imports](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), [3D navigation](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_3d.html), [multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html), [GDevelop features](https://gdevelop.io/features) and [plans](https://gdevelop.io/pricing), [Unreal licensing](https://www.unrealengine.com/license).
