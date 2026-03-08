<div align="center">
<img src="./assets/Logo.png">
<h1>
ROpen
</h1>
</div>

ROpen is a cli tool to a launch the roblox studio for specific place under the game

## Installation

### [GitHub Releases](https://github.com/Barocena/ROpen/releases/latest)

There are pre-built versions of ropen under the [releases page](https://github.com/Barocena/ROpen/releases) available for direct downloads.

### [Rokit](https://github.com/rojo-rbx/rokit)

When using [Rokit](https://github.com/rojo-rbx/rokit), install ROpen with the command:

```bash
rokit add Barocena/ROpen
```

## Usage

`ropen init` will generate a `ROpen.yaml` file

`ropen "GameName/PlaceName"` to open a place under the given game with studio

`ropen` to list the games and places under the chosen game to launch

---

`ROpen.yaml` is config file for the places.

the template of this file is

```yaml
Crossroads:
  UniverseId: 13058 # required
  Lobby: 1818 # place id
  Arena: 1818 # place id
```

this file can be anywhere in the project,

ROpen config file can be synced with rojo so it is possible to use this file as environment manifest.
