# Scene Trigger System - Complete Guide 🎬

## Overview

You can now trigger scenes directly from your chapter files using these new actions:

| Action | Description | Use Case |
|--------|-------------|----------|
| `WaitForProximity(part, distance)` | Wait until player is near a part | "Approach the door" |
| `WaitForProximityPrompt(prompt)` | Wait for player to interact with prompt | "Press E to interact" |
| `WaitForToolEquip(toolName)` | Wait for player to equip a tool | "Pick up the key" |
| `WaitForToolActivation(toolName)` | Wait for player to use/click a tool | "Use the flashlight" |
| `WaitForToolOnPrompt(prompt, toolName)` | Wait for player to use tool on prompt | "Use key on door" |

---

## How It Works Now in Chapter1_Intro

At the end of Scene 1 (intro), the game now:
1. Shows "Explore the Environment" objective
2. **Waits for player to interact with GatePart's ProximityPrompt**
3. Automatically triggers Scene 2 (discovery)

```lua
-- At the end of Scene 1:
Actions.ShowObjective("Explore the Environment"),

-- Wait for gate interaction
Actions.WaitForProximityPrompt(gatePrompt),

-- Trigger Scene 2
Actions.Call(function()
    local discoveryScene = Chapter.getScene("chapter1", "discovery")
    if discoveryScene then
        Director:PlaySequenceAsync(discoveryScene.actions, "Chapter1/discovery")
    end
end),
```

---

## All New Trigger Actions

### 1. WaitForProximity
**Wait until player gets close to a part**

```lua
-- Get the trigger part
local gatePart = workspace:FindFirstChild("GatePart")

-- In your scene actions:
Actions.WaitForProximity(gatePart, 10), -- Wait until player is within 10 studs
Actions.Dialogue("You found the gate!", "Player", 2),
```

### 2. WaitForProximityPrompt
**Wait for player to interact with a ProximityPrompt (press E)**

```lua
-- Get the prompt
local gatePart = workspace:FindFirstChild("GatePart")
local gatePrompt = gatePart:FindFirstChildOfClass("ProximityPrompt")

-- In your scene actions:
Actions.WaitForProximityPrompt(gatePrompt),
Actions.Dialogue("The gate is locked...", "Player", 2),
```

### 3. WaitForToolEquip
**Wait for player to equip a specific tool**

```lua
-- In your scene actions:
Actions.ShowObjective("Find the Flashlight"),
Actions.WaitForToolEquip("Flashlight"),
Actions.Dialogue("Good, now I can see in the dark.", "Player", 2),
```

### 4. WaitForToolActivation
**Wait for player to click/use a tool**

```lua
-- In your scene actions:
Actions.WaitForToolEquip("Knife"),
Actions.Dialogue("Use the knife to cut the rope.", nil, 2),
Actions.WaitForToolActivation("Knife"),
Actions.Dialogue("The rope is cut!", nil, 1),
```

### 5. WaitForToolOnPrompt
**Wait for player to use a specific tool on a ProximityPrompt**
Perfect for puzzles like "use key on door"!

```lua
-- Setup
local doorPart = workspace:FindFirstChild("LockedDoor")
local doorPrompt = doorPart:FindFirstChildOfClass("ProximityPrompt")

-- In your scene actions:
Actions.ShowObjective("Find the key and unlock the door"),
Actions.ConfigurePrompt(doorPrompt, {
    ActionText = "Use Key",
    ObjectText = "Locked Door",
}),
Actions.WaitForToolOnPrompt(doorPrompt, "Key"),
Actions.Dialogue("The door unlocks!", nil, 1),
```

---

## Helper Actions

### SetPromptEnabled
**Show or hide a ProximityPrompt**

```lua
-- Hide prompt until player has the key
Actions.SetPromptEnabled(doorPrompt, false),
Actions.WaitForToolEquip("Key"),
Actions.SetPromptEnabled(doorPrompt, true), -- Now show it
```

### ConfigurePrompt
**Change prompt properties dynamically**

```lua
Actions.ConfigurePrompt(doorPrompt, {
    ActionText = "Open",        -- What shows when pressing E
    ObjectText = "Door",        -- What the object is called
    HoldDuration = 0.5,         -- How long to hold E
    MaxActivationDistance = 8,  -- How close player needs to be
    RequiresLineOfSight = true, -- Must be able to see it
}),
```

---

## Background Listeners (Non-Blocking)

These run in the background and call a function when triggered.
Use for **optional** interactions that don't block the story.

### ListenForProximity
```lua
-- Start a background listener
Actions.ListenForProximity(secretArea, 5, function()
    -- This runs when player approaches, without blocking
    print("Player found the secret area!")
end),

-- Scene continues immediately, listener runs in background
Actions.Dialogue("Let's explore...", "Player", 2),
```

### ListenForPrompt
```lua
-- Optional interaction
Actions.ListenForPrompt(hintPrompt, function()
    Director:PlaySequenceAsync({
        Actions.Dialogue("Hint: Try looking behind the bookshelf.", nil, 2),
    })
end),
```

---

## Complete Scene Transition Example

Here's how Scene 1 triggers Scene 2 in Chapter1_Intro:

```lua
-- At the top of the file, get the trigger parts:
local gatePart = workspace:FindFirstChild("GatePart")
local gatePrompt = gatePart and gatePart:FindFirstChildOfClass("ProximityPrompt")

-- In Scene 1 (intro), at the end:
Chapter.scene("intro", "The Awakening", {
    -- ... all your intro actions ...
    
    Actions.UnlockPlayer(),
    Actions.ShowObjective("Explore the Environment"),
    
    -- SCENE TRIGGER: Wait for gate interaction
    Actions.WaitForProximityPrompt(gatePrompt),
    
    -- Trigger Scene 2!
    Actions.Call(function()
        local discoveryScene = Chapter.getScene("chapter1", "discovery")
        if discoveryScene then
            Director:PlaySequenceAsync(discoveryScene.actions, "Chapter1/discovery")
        end
    end),
}),

-- Scene 2 (discovery) will automatically play when player interacts with gate!
Chapter.scene("discovery", "First Discovery", {
    Actions.LockPlayer(),
    Actions.Dialogue("What is this place?", "Player", 2),
    -- ... rest of scene 2 ...
}),
```

---

## Two Ways to Trigger Scenes

### Option A: Proximity (just get close)
```lua
Actions.WaitForProximity(gatePart, 8),  -- Within 8 studs
```

### Option B: ProximityPrompt (press E)
```lua
Actions.WaitForProximityPrompt(gatePrompt),  -- Must press E
```

**Currently Active:** Option B (ProximityPrompt)

To switch to Option A, edit `Chapter1_Intro.luau`:
- Comment out the `WaitForProximityPrompt` line
- Uncomment the `WaitForProximity` line

---

## Creating New Scene Triggers

### Step 1: Add part reference at top of file
```lua
-- At the top of Chapter1_Intro.luau:
local myTriggerPart = workspace:FindFirstChild("MyTriggerPart")
local myPrompt = myTriggerPart and myTriggerPart:FindFirstChildOfClass("ProximityPrompt")
```

### Step 2: Add trigger at end of current scene
```lua
-- At the end of your current scene:
Actions.WaitForProximityPrompt(myPrompt),
Actions.Call(function()
    local nextScene = Chapter.getScene("chapter1", "nextSceneId")
    if nextScene then
        Director:PlaySequenceAsync(nextScene.actions, "Chapter1/nextSceneId")
    end
end),
```

### Step 3: Create the next scene
```lua
Chapter.scene("nextSceneId", "Scene Name", {
    -- Your scene actions here
}),
```

---

## Setup in Roblox Studio

### For GatePart (or any trigger part):

1. **Create or select the part** in Workspace
2. **Add a ProximityPrompt** as a child:
   - Right-click the part → Insert Object → ProximityPrompt
3. **Configure the prompt:**
   - `ActionText`: "Interact" (or whatever you want)
   - `ObjectText`: "Gate" (or the object name)
   - `HoldDuration`: 0 (instant) or 0.5 (slight hold)
   - `MaxActivationDistance`: 5-10 studs
4. **Name the part** something recognizable (e.g., "GatePart")

---

## Troubleshooting

### Scene doesn't trigger?
1. Check Output for `[Actions] Waiting for...` messages
2. Verify the part exists: `print(gatePart)` should not be nil
3. Verify the prompt exists: `print(gatePrompt)` should not be nil
4. Make sure ProximityPrompt is a child of the part

### Getting "nil" errors?
```lua
-- Add safety checks:
local gatePart = workspace:FindFirstChild("GatePart")
if not gatePart then
    warn("GatePart not found in workspace!")
end
```

### Prompt not showing?
- Check `Enabled` property is true
- Check `MaxActivationDistance` isn't too small
- Check `RequiresLineOfSight` - can player see it?

---

## Quick Reference

| What You Want | Action to Use |
|--------------|---------------|
| Player walks near something | `WaitForProximity(part, distance)` |
| Player presses E on something | `WaitForProximityPrompt(prompt)` |
| Player picks up an item | `WaitForToolEquip(toolName)` |
| Player uses/clicks a tool | `WaitForToolActivation(toolName)` |
| Player uses tool on object | `WaitForToolOnPrompt(prompt, toolName)` |
| Show/hide interact option | `SetPromptEnabled(prompt, bool)` |
| Change prompt text | `ConfigurePrompt(prompt, config)` |
| Background trigger (non-blocking) | `ListenForProximity()` / `ListenForPrompt()` |

---

## Summary

Your story now flows like this:
1. **Scene 1 (intro)** plays on game start
2. Player explores the environment
3. **Player interacts with GatePart**
4. **Scene 2 (discovery)** automatically plays!
5. Player makes a choice
6. Story continues...

All defined directly in `Chapter1_Intro.luau` - no external scripts needed! 🎬
