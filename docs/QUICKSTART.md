# Quick Start Guide

Welcome to the Story Engine! This guide will help you set up the codebase for your own Roblox game.

## Prerequisites

1.  **Roblox Studio**: Ensure you have Roblox Studio installed.
2.  **Rojo**: This project uses Rojo for file syncing. Install the [Rojo plugin](https://rojo.space/docs/installation/) in Roblox Studio and the CLI tool.
3.  **Git**: Recommended for version control.

## Setup Instructions

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/faust504/rostory.git
    cd rostory
    ```

2.  **Sync with Roblox Studio**
    *   Open a new place in Roblox Studio.
    *   Start the Rojo server in your terminal:
        ```bash
        rojo serve
        ```
    *   In Roblox Studio, open the Rojo plugin and connect to the server. This will sync the files into the game.

3.  **Verify Project Structure**
    Ensure the following folders are synced correctly:
    *   `src/client` -> `StarterPlayer/StarterPlayerScripts/Client`
    *   `src/server` -> `ServerScriptService/Server`
    *   `src/shared` -> `ReplicatedStorage/Shared`
    *   `assets` -> `ReplicatedStorage/Assets` (You may need to create this manually if not synced or populate it with your own assets).

4.  **Configure Main Menu**
    *   The Main Menu logic is in `src/client/UI/MainMenu.luau`.
    *   Ensure your `StarterGui` has a ScreenGui named "MainMenu" with a "PlayButton" if you are using the default UI setup. The script expects standard UI naming conventions.

## Creating Your First Story Chapter

1.  **Create a Chapter File**
    Create a new ModuleScript in `src/client/Story/Chapters/` (e.g., `MyChapter.luau`).

2.  **Define the Chapter**
    ```lua
    local Chapter = require(game.ReplicatedStorage.Story.Chapter)
    local Actions = require(game.ReplicatedStorage.Story.Actions)

    local MyChapter = Chapter.new({
        id = "my_chapter",
        name = "The Beginning",
        startScene = "intro",
        scenes = {
            -- Scenes go here
        }
    })
    
    -- Define a Scene
    Chapter.scene("intro", "Intro Sequence", {
        Actions.FadeOut(0),
        Actions.Wait(1),
        Actions.Dialogue("Welcome to my new game!", 3),
        Actions.FadeIn(2),
    })

    return MyChapter
    ```

3.  **Register the Chapter**
    In your game initialization script (e.g., `src/client/Story/StoryController.luau`), ensure you require your new chapter file so it registers itself.

## Running the Story

To start the story when the game begins or when a button is clicked:

```lua
local Director = require(game.ReplicatedStorage.Story.Director)
local MyChapter = require(path.to.MyChapter)

-- direct play
Director:PlaySequence(MyChapter.scenes[1].actions)
```

## Next Steps

*   Check out the [full documentation](../index.html) (or the hosted GitHub Pages version) for a complete list of 30+ Actions.
*   Explore `src/client/Story/Actions.luau` to see how custom actions are built.
