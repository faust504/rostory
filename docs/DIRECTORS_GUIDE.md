# 📖 Story Director's Guide

A comprehensive guide to creating story content for your Roblox game using the Director system.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [📁 File Structure & Where to Put Your Code](#-file-structure--where-to-put-your-code)
3. [🎬 Creating Your First Cutscene](#-creating-your-first-cutscene)
4. [Core Concepts](#core-concepts)
5. [Actions Reference](#actions-reference)
6. [Creating Chapters](#creating-chapters)
7. [Best Practices](#best-practices)
8. [Examples](#examples)

---

## Quick Start

### Your First Scene

```lua
local Director = require(path.to.Director)
local Actions = Director.Actions

Director:PlaySequence({
    Actions.FadeOut(1),
    Actions.Dialogue("Hello, world!", "NPC"),
    Actions.FadeIn(1),
})
```

That's it! The Director executes each action in order, waiting for each to complete.

---

## 📁 File Structure & Where to Put Your Code

### Complete Project Structure

```
robloxgame1/
├── src/
│   ├── client/                    # CLIENT-SIDE CODE
│   │   ├── init.client.luau       # ❌ DON'T EDIT (bootstrapper)
│   │   ├── Controllers/           # ❌ DON'T EDIT (framework)
│   │   │   ├── UIManager.luau
│   │   │   ├── CutsceneController.luau
│   │   │   ├── AnimationController.luau
│   │   │   └── AudioManager.luau
│   │   ├── UI/                    # ❌ DON'T EDIT (framework UI)
│   │   │   ├── MainMenu.luau
│   │   │   └── DialogueBox.luau
│   │   ├── Cinematics/            # ❌ DON'T EDIT (framework)
│   │   │   └── CinematicAction.luau
│   │   └── Story/                 # ✅ YOUR STORY CODE GOES HERE
│   │       ├── Director.luau      # ❌ DON'T EDIT (framework)
│   │       ├── Actions.luau       # ❌ DON'T EDIT (30+ actions)
│   │       ├── Chapter.luau       # ❌ DON'T EDIT (framework)
│   │       └── Chapters/          # ✅ CREATE YOUR CHAPTERS HERE
│   │           ├── init.luau      # ❌ DON'T EDIT
│   │           ├── Chapter1_Intro.luau    # ✅ EXAMPLE - COPY THIS
│   │           ├── Chapter2_YourStory.luau   # ✅ CREATE NEW FILES HERE
│   │           └── Chapter3_YourStory.luau   # ✅ CREATE NEW FILES HERE
│   │
│   ├── server/                    # SERVER-SIDE CODE
│   │   ├── init.server.luau       # ❌ DON'T EDIT
│   │   └── Services/              # ❌ DON'T EDIT (framework)
│   │       ├── StoryManager.luau
│   │       └── ObjectiveService.luau
│   │
│   └── shared/                    # SHARED CODE
│       ├── Types.luau             # ❌ DON'T EDIT
│       └── Remotes.luau           # ❌ DON'T EDIT
│
└── docs/
    └── DIRECTORS_GUIDE.md         # 📖 THIS DOCUMENT
```

### 🎯 Key Locations for Directors

| What You Want To Do | Where To Put It |
|---------------------|-----------------|
| **Create a new chapter** | `src/client/Story/Chapters/ChapterX_Name.luau` |
| **Write dialogue sequences** | Inside chapter scenes (see below) |
| **Create cutscenes** | Inside chapter scenes (see below) |
| **Add custom actions** | Contact framework developer (or edit `Actions.luau` carefully) |
| **Trigger a chapter to play** | From another script, require the chapter file |

---

## 🎬 Creating Your First Cutscene

### Step 1: Create a New Chapter File

Create a new file: `src/client/Story/Chapters/MyChapter.luau`

```lua
--!strict
--[[
    MyChapter.luau
    My first story chapter
]]

-- ⚠️ REQUIRED: Import the framework modules
local Story = script.Parent.Parent -- Go up from Chapters to Story folder
local Director = require(Story:WaitForChild("Director"))
local Chapter = require(Story:WaitForChild("Chapter"))
local Actions = Director.Actions

-- Continue below...
```

### Step 2: Define Your Chapter Structure

**Add this code starting at line 11 (after the imports):**

```lua
--[[
    Define your chapter with scenes
]]

local MyChapter = Chapter.new({
    id = "mychapter",           -- Unique ID for this chapter
    name = "My First Chapter",  -- Display name
    startScene = "opening",     -- Which scene to start with
    
    scenes = {
        -- Your scenes go here (see Step 3)
    }
})

return MyChapter
```

### Step 3: Add Scenes with Dialogue and Cutscenes

**Replace the `scenes = {}` part with your actual scenes:**

```lua
    scenes = {
        -- SCENE 1: Opening cutscene
        Chapter.scene("opening", "Opening Cutscene", {
            -- ⬇️ YOUR CUTSCENE CODE STARTS HERE
            
            Actions.LockPlayer(),                    -- Lock player controls
            Actions.FadeOut(0),                      -- Start with black screen
            
            Actions.PlayMusic("rbxassetid://123456", 2),  -- Background music
            
            Actions.SetCamera(                       -- Position camera
                CFrame.new(0, 10, 20) * CFrame.Angles(math.rad(-15), 0, 0)
            ),
            
            Actions.Wait(1),
            Actions.FadeIn(2),                       -- Fade in from black
            
            -- DIALOGUE SEQUENCE
            Actions.Dialogue("Where am I?", "Player", 2),
            Actions.Wait(0.5),
            Actions.Dialogue("This place looks familiar...", "Player", 2),
            
            -- CAMERA MOVEMENT
            Actions.MoveCamera(
                CFrame.new(10, 5, 15),
                3  -- 3 seconds to move
            ),
            
            Actions.Wait(1),
            
            -- TELEPORT PLAYER AND RESET
            Actions.FadeOut(1),
            Actions.TeleportPlayer(CFrame.new(0, 5, 0)),
            Actions.ResetCamera(),                   -- Return camera to player
            Actions.FadeIn(1),
            
            Actions.UnlockPlayer(),                  -- Unlock controls
            Actions.ShowObjective("Explore the area"),
            
            -- ⬆️ YOUR CUTSCENE CODE ENDS HERE
        }),
        
        -- SCENE 2: Player makes a choice
        Chapter.scene("decision", "The Decision", {
            Actions.LockPlayer(),
            Actions.Dialogue("I see two paths ahead...", "Player", 2),
            
            -- BRANCHING DIALOGUE
            Actions.Choice("Which path should I take?", {
                {
                    text = "Take the left path",
                    callback = function()
                        -- LEFT PATH SEQUENCE
                        Director:PlaySequence({
                            Actions.Dialogue("The left path it is.", "Player", 1.5),
                            Actions.FadeOut(1),
                            -- Add more actions here
                        })
                    end
                },
                {
                    text = "Take the right path",
                    callback = function()
                        -- RIGHT PATH SEQUENCE  
                        Director:PlaySequence({
                            Actions.Dialogue("Let's see where this leads...", "Player", 1.5),
                            Actions.FadeOut(1),
                            -- Add more actions here
                        })
                    end
                }
            }),
            
            Actions.UnlockPlayer(),
        }),
        
        -- ADD MORE SCENES HERE following the same pattern
    }
```

### Step 4: Play Your Chapter

**To trigger your chapter from another script:**

```lua
-- Example: Trigger when player joins
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for your chapter to load
local Story = LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Story")
local Chapters = Story:WaitForChild("Chapters")
local MyChapter = require(Chapters:WaitForChild("MyChapter"))

-- Get the opening scene
local scene = Chapter.getScene("mychapter", "opening")
if scene then
    local Director = require(Story:WaitForChild("Director"))
    Director:PlaySequence(scene.actions, "MyChapter/opening")
end
```

### 📝 Template Structure Summary

Every chapter file follows this structure:

```lua
-- Lines 1-10: Imports
local Story = script.Parent.Parent
local Director = require(Story:WaitForChild("Director"))
local Chapter = require(Story:WaitForChild("Chapter"))
local Actions = Director.Actions

-- Lines 11+: Chapter definition
local MyChapter = Chapter.new({
    id = "...",
    name = "...",
    startScene = "...",
    scenes = {
        Chapter.scene("scene_id", "Scene Name", {
            -- ACTIONS GO HERE
            Actions.FadeOut(1),
            Actions.Dialogue("Text", "Speaker"),
            -- ... more actions ...
        }),
    }
})

return MyChapter
```

---

## Core Concepts

### The Director
The `Director` is your story orchestrator. Think of it as a movie director calling "Action!" on each scene beat.

```lua
-- Play a sequence (blocks until complete)
Director:PlaySequence(actions, "SceneName")

-- Play async (doesn't block)
Director:PlaySequenceAsync(actions, "SceneName")

-- Check if playing
if Director:IsPlaying() then ... end

-- Cancel current sequence
Director:CancelSequence()
```

### Actions
Actions are the building blocks of your story. Each action returns a function that executes when called.

```lua
-- Actions are just functions that return functions
local fadeOut = Actions.FadeOut(1)  -- Creates the action
fadeOut()  -- Executes the action

-- But normally you just pass them to PlaySequence:
Director:PlaySequence({
    Actions.FadeOut(1),  -- Created and queued
    Actions.Dialogue("Text"),
})
```

### Chapters & Scenes
Organize your story into logical chunks:

```lua
local Chapter = require(path.to.Chapter)

local MyChapter = Chapter.new({
    id = "chapter1",
    name = "The Beginning",
    scenes = {
        Chapter.scene("intro", "Introduction", {
            Actions.FadeIn(1),
            Actions.Dialogue("Welcome..."),
        }),
    },
})
```

---

## Actions Reference

### 🎬 Screen Effects

| Action | Description |
|--------|-------------|
| `FadeOut(duration)` | Fade to black |
| `FadeIn(duration)` | Fade from black |
| `FadeToColor(color, duration)` | Fade to any color |
| `FadeFromColor(duration)` | Fade back to transparent |
| `FlashScreen(color, duration?)` | Quick flash effect |
| `ScreenShake(intensity, duration)` | Camera shake |

**Examples:**
```lua
Actions.FadeOut(1.5)
Actions.FadeToColor(Color3.new(1, 0, 0), 2)  -- Fade to red
Actions.FlashScreen(Color3.new(1, 1, 1), 0.1)  -- White flash
Actions.ScreenShake(0.5, 1)  -- Shake for 1 second
```

---

### 💬 Dialogue

| Action | Description |
|--------|-------------|
| `Dialogue(text, speaker?, duration?)` | Show dialogue with typewriter |
| `Choice(prompt, choices)` | Show choices, wait for selection |

**Examples:**
```lua
-- Simple dialogue
Actions.Dialogue("Hello there!", "Guard", 2)

-- Dialogue with choices
Actions.Choice("What do you want to do?", {
    {
        text = "Go left",
        callback = function()
            -- Handle left path
        end
    },
    {
        text = "Go right", 
        callback = function()
            -- Handle right path
        end
    }
})
```

---

### 📷 Camera

| Action | Description |
|--------|-------------|
| `MoveCamera(cframe, duration?)` | Smooth camera movement |
| `SetCamera(cframe)` | Instant camera position |
| `ResetCamera()` | Return to player follow |

**Examples:**
```lua
-- Dramatic camera pan
Actions.SetCamera(CFrame.new(0, 50, 0) * CFrame.Angles(math.rad(-90), 0, 0))
Actions.MoveCamera(CFrame.new(10, 5, 0), 3)
Actions.ResetCamera()
```

---

### 🎮 Player Control

| Action | Description |
|--------|-------------|
| `LockPlayer()` | Disable movement (WalkSpeed=0) |
| `UnlockPlayer()` | Enable movement (WalkSpeed=16) |
| `TeleportPlayer(CFrame or Vector3)` | Move player instantly |

**Examples:**
```lua
-- Cutscene pattern
Actions.LockPlayer()
-- ... cutscene actions ...
Actions.UnlockPlayer()

-- Teleport
Actions.TeleportPlayer(CFrame.new(100, 5, 50))
```

---

### 🔊 Audio

| Action | Description |
|--------|-------------|
| `PlaySound(soundId, volume?)` | Play one-shot sound |
| `PlaySoundAndWait(soundId, volume?)` | Play and wait for completion |
| `PlayMusic(soundId, fadeTime?)` | Start looping music with crossfade |
| `StopMusic(fadeTime?)` | Fade out music |

**Examples:**
```lua
-- Ambient sound
Actions.PlaySound("rbxassetid://123456")

-- Background music with crossfade
Actions.PlayMusic("rbxassetid://987654", 2)  -- 2 second fade

-- Stop music
Actions.StopMusic(3)  -- 3 second fade out
```

---

### 🎭 Animation

| Action | Description |
|--------|-------------|
| `PlayAnimation(target, animId, wait?)` | Play animation on model/humanoid |

**Example:**
```lua
local npc = workspace.Characters.Guard
Actions.PlayAnimation(npc, "rbxassetid://123456", true)  -- Wait for completion
```

---

### ⏱️ Timing & Flow

| Action | Description |
|--------|-------------|
| `Wait(seconds)` | Pause sequence |
| `WaitForTrigger(part)` | Wait for player to touch part |
| `WaitForInput()` | Wait for any key/click |

**Examples:**
```lua
Actions.Wait(2.5)
Actions.WaitForTrigger(workspace.DoorTrigger)
Actions.WaitForInput()  -- Press any key to continue
```

---

### 🔀 Control Flow

| Action | Description |
|--------|-------------|
| `Parallel(...)` | Run actions simultaneously (fire and forget) |
| `ParallelWait(...)` | Run simultaneously, wait for all |
| `If(condition, thenAction, elseAction?)` | Conditional execution |
| `Call(function)` | Run custom code |
| `Log(message)` | Print debug message |

**Examples:**
```lua
-- Parallel effects
Actions.ParallelWait(
    Actions.ScreenShake(0.5, 2),
    Actions.PlaySound("rbxassetid://boom")
)

-- Conditional
Actions.If(
    function() return hasKey end,
    Actions.Dialogue("The door opens!"),
    Actions.Dialogue("It's locked...")
)

-- Custom code
Actions.Call(function()
    workspace.Light.Enabled = false
end)
```

---

### 📋 UI

| Action | Description |
|--------|-------------|
| `ShowUI(guiName)` | Enable a ScreenGui |
| `HideUI(guiName)` | Disable a ScreenGui |
| `ShowObjective(title, description?)` | Show objective notification |

**Example:**
```lua
Actions.ShowObjective("Find the Key")
Actions.HideUI("MainMenu")
```

---

## Creating Chapters

### Structure

```lua
-- src/client/Story/Chapters/Chapter1.luau
local Chapter = require(script.Parent.Parent.Chapter)
local Director = require(script.Parent.Parent.Director)
local Actions = Director.Actions

return Chapter.new({
    id = "chapter1",
    name = "Chapter 1: The Beginning",
    startScene = "intro",
    scenes = {
        Chapter.scene("intro", "Introduction", { ... }),
        Chapter.scene("middle", "The Middle", { ... }),
        Chapter.scene("climax", "The Climax", { ... }),
    }
})
```

### Playing Chapters

```lua
local Chapter1 = require(path.to.Chapter1)

-- Get a scene
local scene = Chapter.getScene("chapter1", "intro")

-- Play it
Director:PlaySequence(scene.actions, "Chapter1/intro")
```

---

## Best Practices

### 1. Always Lock/Unlock Player for Cutscenes
```lua
{
    Actions.LockPlayer(),
    -- cutscene content
    Actions.UnlockPlayer(),
}
```

### 2. Use Fades for Transitions
```lua
{
    Actions.FadeOut(0.5),
    Actions.TeleportPlayer(newLocation),
    Actions.FadeIn(0.5),
}
```

### 3. Add Audio for Immersion
```lua
{
    Actions.PlayMusic("rbxassetid://ambient", 2),
    Actions.Dialogue("The wind howls outside..."),
    Actions.PlaySound("rbxassetid://wind"),
}
```

### 4. Use Log for Debugging
```lua
{
    Actions.Log("Starting boss fight sequence"),
    Actions.FadeOut(1),
    Actions.Log("Player teleported"),
}
```

### 5. Group Related Actions with Parallel
```lua
-- Bad: sequential when they could be parallel
Actions.PlayMusic("id"),
Actions.Wait(0),
Actions.SetCamera(cframe),

-- Good: simultaneous setup
Actions.Parallel(
    Actions.PlayMusic("id"),
    Actions.SetCamera(cframe)
)
```

---

## Examples

### Dramatic Reveal
```lua
{
    Actions.LockPlayer(),
    Actions.FadeOut(0.5),
    Actions.PlayMusic("rbxassetid://dramatic", 0.5),
    Actions.FadeIn(1),
    Actions.MoveCamera(revealCFrame, 3),
    Actions.Wait(0.5),
    Actions.PlaySound("rbxassetid://impact"),
    Actions.ScreenShake(0.3, 0.5),
    Actions.Dialogue("No... it can't be...", "Player"),
    Actions.ResetCamera(),
    Actions.UnlockPlayer(),
}
```

### Player Choice Branching
```lua
{
    Actions.Dialogue("A fork in the road.", nil, 1),
    Actions.Choice("Which path?", {
        { text = "The dark forest", callback = function()
            Director:PlaySequence(forestPath)
        end},
        { text = "The sunny meadow", callback = function()
            Director:PlaySequence(meadowPath)
        end},
    }),
}
```

### Horror Jump Scare
```lua
{
    Actions.StopMusic(0.1),
    Actions.Wait(0.5),
    Actions.ParallelWait(
        Actions.FlashScreen(Color3.new(1, 1, 1), 0.05),
        Actions.PlaySound("rbxassetid://scream"),
        Actions.ScreenShake(1, 0.5)
    ),
    Actions.Dialogue("AAAAAH!", "Player", 0.5),
}
```

---

## Tips for Story Writing

1. **Pace your dialogue** - Don't spam dialogue boxes, let moments breathe
2. **Use environmental storytelling** - Sometimes silence and visuals say more
3. **Give players agency** - Use `Choice` at key moments
4. **Test timing extensively** - What feels right in code may feel too fast/slow in-game
5. **Layer audio** - Music + ambience + SFX creates immersion
6. **Lock and unlock carefully** - Always unlock player after a cutscene
7. **Use Log() for debugging** - Add `Actions.Log("Scene starting")` to track progress
8. **Build incrementally** - Test one scene at a time, don't write everything first

---

## Quick Reference Card

### Common Cutscene Pattern
```lua
Chapter.scene("id", "Name", {
    Actions.LockPlayer(),           -- 1. Lock controls
    Actions.FadeOut(0),             -- 2. Start black
    Actions.SetCamera(cframe),      -- 3. Position camera
    Actions.FadeIn(1),              -- 4. Reveal scene
    -- Dialogue and action here
    Actions.FadeOut(1),             -- 5. Fade to transition
    Actions.TeleportPlayer(pos),    -- 6. Move player
    Actions.ResetCamera(),          -- 7. Return camera
    Actions.FadeIn(1),              -- 8. Fade back in
    Actions.UnlockPlayer(),         -- 9. Unlock controls
})
```

### Where Actions Are Defined
All 30+ actions live in: `src/client/Story/Actions.luau`

You **use** them in: `src/client/Story/Chapters/YourChapter.luau`

---

*Happy storytelling! 🎬*

