<div align="center">
<img src="./Assets/Logo.png" style="width:256px;height:256px;">
<h1>
ROpen
</h1>
</div>

ROpen is a cli tool to launch Roblox Studio for a specific place in the game

## Installation

### [GitHub Releases](https://github.com/Barocena/ROpen/releases/latest)

There are pre-built versions of ropen under the [releases page](https://github.com/Barocena/ROpen/releases) available for direct downloads.

### [Rokit](https://github.com/rojo-rbx/rokit)

When using [Rokit](https://github.com/rojo-rbx/rokit), install ROpen with the command:

```bash
rokit add Barocena/ROpen
```

## Usage

`ropen init` to generate a `ropen.yaml` file

`ropen GameName/PlaceName` to open a place under the given game with studio

`ropen` to select the game and place to launch with an interactive picker

---

`ropen.yaml` is manifest file for the places.

the template of this file is

```yaml
Crossroads:
  UniverseId: 13058 # required
  Lobby: 1818 # place id
  Arena: 1818 # place id
```

this file can be anywhere in the project,

ROpen manifest file can be synced with rojo so it is possible to use this file as environment manifest at runtime.
