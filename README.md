# Roblox Story Game Framework

A modular, type-safe Luau framework for creating single-player story games.

## Features

- 🎬 **Director System** - Write story sequences like movie scripts
- 📖 **Chapter Organization** - Structure your story into chapters and scenes
- 🎭 **30+ Actions** - Fades, dialogue, camera, audio, choices, and more
- 💾 **Save/Load Ready** - Centralized state management via StoryManager
- 🎨 **Polished UI** - MainMenu, DialogueBox with choices, objective notifications
- 🔊 **Audio System** - Music crossfading, ambience, 3D positional audio

## Quick Start

```lua
local Director = require(path.to.Director)
local Actions = Director.Actions

Director:PlaySequence({
    Actions.FadeOut(1),
    Actions.Dialogue("Hello, traveler...", "Old Man"),
    Actions.PlayMusic("rbxassetid://123456"),
    Actions.FadeIn(1),
    Actions.ShowObjective("Find the ancient artifact"),
})
```

## Documentation

- 🚀 [Quick Start Guide](docs/QUICKSTART.md) - Step-by-step setup instructions
- 📖 [Director's Guide](docs/DIRECTORS_GUIDE.md) - Deep dive into story creation
- 🌐 [Full API Documentation](https://faust504.github.io/rostory/) - Complete interactive documentation (index.html)

## Project Structure

```
src/
├── client/
│   ├── Controllers/       # UI, Camera, Animation, Audio
│   ├── UI/               # MainMenu, DialogueBox
│   ├── Cinematics/       # Camera sequences
│   └── Story/            # Director, Actions, Chapters
├── server/
│   └── Services/         # StoryManager, ObjectiveService
└── shared/               # Types, Remotes
```

## Requirements

- Roblox Studio
- [Rojo v7](https://rojo.space/) for syncing

## Getting Started

1. Clone this repository
2. Run `rojo serve` in the project directory
3. Connect Roblox Studio to Rojo
4. Press Play to test

## License

MIT