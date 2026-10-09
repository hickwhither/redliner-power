# Development Guide

See [README.md](README.md) for the published release and import command.

Modular Luau source builds into `dist/redliner.lua`. Flask serves that file without URL rewriting or per-request builds.

```text
src/*.luau -> Darklua -> dist/redliner.lua -> Flask GET /
```

Fluent loads online at runtime, as requested. Project modules do not load through HTTP.
The deployment has one project artifact, but it is not fully self-contained.

## Requirements

- [Rokit](https://github.com/rojo-rbx/rokit#installation) 1.2.0 or compatible.
- Wally 0.3.2 and Darklua 0.19.0, pinned in `rokit.toml`.
- Python 3.13 or newer and [uv](https://docs.astral.sh/uv/).
- A Roblox client environment with `Drawing`, `loadstring`, HTTP access, and permission to use `CoreGui`.

## First Setup

Clone the repository:

```sh
git clone https://github.com/hickwhither/redliner-power.git
cd redliner-power
```

Install the tools and Python dependencies:

```sh
rokit install
uv sync
```

Rokit is already configured. Do not run `rokit init` again.
The tool manifest preserves the existing Wally and Darklua pins.

## Install Dependencies

```sh
wally install
```

Wally is the package manager, not Wally UI. The manifest has no registry dependencies yet.
The generated `wally.lock` records this empty dependency set. No unofficial Fluent package is used.
Wally 0.3.2 does not support the newer documented `install --locked` flag.

## Build

On Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
```

On macOS or Linux, run:

```sh
sh scripts/build.sh
```

Both scripts install Wally dependencies, create `dist`, run Darklua, and verify the nonempty artifact.
The underlying command is:

```sh
darklua process src/main.luau dist/redliner.lua --config .darklua.json
```

Darklua uses recursive path-mode bundling without minification. `Packages/` and `dist/` are ignored by Git.
Build before you start the server. Deploy `dist/redliner.lua` together with the Flask files and Python dependencies.
The server does not need `src/`, Rokit, Wally, or Darklua in production.

### Release Artifact

After the build, generate the versioned release asset:

```sh
darklua process src/main.luau dist/redliner-v1.lua --config .darklua.json
```

The `v1` GitHub release contains `redliner-v1.lua`. Flask still serves `dist/redliner.lua` during local development.
Both files contain the same bundled project code. Release assets do not need a local Flask server.

## Run Server

```sh
uv run python main.py
```

The server listens on port 5000. `GET /` returns the exact artifact bytes with `text/plain; charset=utf-8`.
A missing artifact returns HTTP 503. `/src/...` no longer exists.
The built-in Flask server is for development, not public production traffic.

In a compatible Roblox client, load the artifact:

```lua
loadstring(game:HttpGet("http://127.0.0.1:5000/"))()
```

## Development Workflow

```text
edit src/* -> build -> dist/redliner.lua -> Flask serves dist/redliner.lua
```

Rebuild after each source change. Flask reads the artifact on each request but never builds it.

## Architecture

```text
src/
  main.luau
  core/
    Controller.luau
    LightingOwnership.luau
    Runtime.luau
    Utils.luau
  ui/
    UI.luau
  mods/
    AutoAim.luau
    ESP.luau
    Fullbright.luau
    NoFog.luau
scripts/
  build.ps1
  build.sh
dist/
  redliner.lua             # generated, ignored
```

UI callbacks call feature modules directly. Each feature owns its enabled state and exposes `enable`, `disable`, `destroy`, and `isEnabled`.
`Controller` initializes the Aim status and cleans project resources. `Runtime` isolates the only global execution guard.
ESP cancels delayed character callbacks during disable or unload.
`LightingOwnership` prevents competing FogEnd locks. NoFog takes priority while both lighting features are enabled.
The last owner restores the original property value.

## UI Dependency

The project uses Fluent 1.1.0 from [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent), under the MIT license.
[LunaPhs](https://lunaphs.gitbook.io/lunaphs-english/luna-library) lists Fluent, but does not document its control APIs.
The integration uses the official [Example.lua](https://github.com/dawid-scripts/Fluent/blob/78ba067d6f927fe45557c79da05853331b89480e/Example.lua) and upstream source.
Fluent provides windows, tabs, toggles, configurable keybinds, buttons, and `Destroy()`.
Orion's linked source has no verified license. Rayfield has more runtime downloads.

The loader uses the official release URL:

```text
https://github.com/dawid-scripts/Fluent/releases/download/1.1.0/main.lua
```

No library source is vendored. No optional SaveManager or InterfaceManager loads.
The release tag fixes the version, but GitHub release assets can change and no checksum is enforced.

## Controls And Cleanup

- Fullbright, NoFog, AutoAim, and ESP each have a toggle and a native configurable keybind.
- AutoAim defaults to `V`. Other feature keybinds default to `None`.
- Backquote hides or shows the window through Fluent.
- STOP / Unload stops project features, removes their resources, destroys Fluent, and resets the execution guard.
- Confirmed titlebar close uses the same unload path.
- The configurable Unload key replaces the old Ctrl + Backquote shortcut. There is no custom input listener.

## Validation And Limitations

Run the server tests:

```sh
uv run python -m unittest discover -s tests -v
```

Darklua parses the Luau modules during the build. The server tests verify artifact bytes, content type, missing-build handling, and removed source routes.

Roblox gameplay, rendering, and real input timing need client validation.
The existing game-specific AutoAim filters and ESP health fields remain unchanged.
The online Fluent release requires network access and executes third-party code.
Its upstream destructor does not fully clean temporary key-capture listeners or animation tasks.
Project cleanup is explicit, but complete cleanup of those upstream resources cannot be guaranteed without a patched library.
Fluent also retains its upstream global library reference and Roblox asset dependencies.
