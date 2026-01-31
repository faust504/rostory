# Animated Cutscene Guide 🎬

## Overview

This guide shows you how to create cinematic cutscenes using Roblox animations, similar to games like GTA, Uncharted, or story-driven games.

---

## New Cutscene Actions

### **PlayCutsceneAnimation**
Plays an animation on the player and waits for it to complete.

```lua
Actions.PlayCutsceneAnimation("rbxassetid://123456789")
```

- ✅ Automatically waits for animation to finish
- ✅ Skippable with 'P' key
- ✅ Cleans up after itself

---

### **ParallelActions**
Run multiple actions at the same time (animation + dialogue + sound).

```lua
Actions.ParallelActions({
    Actions.PlayCutsceneAnimation("rbxassetid://123"),
    Actions.Dialogue("I'm driving to work...", 3),
    Actions.PlaySound("rbxassetid://car_engine")
})
```

---

### **WeldToObject / UnweldFromObject**
Attach player to a moving object (car, elevator, etc.).

```lua
Actions.WeldToObject(carSeat)  -- Player moves with car
-- ... animation plays ...
Actions.UnweldFromObject()  -- Release player
```

---

### **HideCharacter / ShowCharacter**
Make player invisible (useful if you have a custom animated rig).

```lua
Actions.HideCharacter()  -- Player becomes invisible
-- ... show custom rig ...
Actions.ShowCharacter()  -- Player visible again
```

---

## Complete Example: Driving Cutscene

### **Your Scenario:**
Player drives a car while looking at phone, then parks and gets out.

### **Workspace Setup:**

```
Workspace
├── Car (Model)
│   ├── Seat (Part) - Where player sits
│   ├── ParkingSpot (Part) - Where to teleport after
│   └── ... other car parts
└── CutsceneCameras (Folder)
    ├── CarInterior (Part) - Camera inside car
    └── ExteriorView (Part) - Camera outside car
```

### **Chapter Code:**

```lua
local Chapter = require(script.Parent.Parent.Chapter)
local Actions = require(script.Parent.Parent.Actions)
local Director = require(script.Parent.Parent.Director)

local Workspace = game:GetService("Workspace")

-- Get references
local car = Workspace:WaitForChild("Car")
local carSeat = car:WaitForChild("Seat")
local parkingSpot = car:WaitForChild("ParkingSpot")
local cameras = Workspace:WaitForChild("CutsceneCameras")
local interiorCam = cameras:WaitForChild("CarInterior")

return Chapter.create("chapter1", "Chapter 1: The Beginning", {
    
    -- Scene 1: Driving Cutscene
    Chapter.scene("driving", "Driving to Work", {
        -- Lock player and fade in
        Actions.LockPlayer(),
        Actions.FadeIn(1),
        
        -- Teleport player into car seat
        Actions.TeleportPlayer(carSeat.CFrame),
        
        -- Weld player to car (so they move with it)
        Actions.WeldToObject(carSeat),
        
        -- Set camera inside car
        Actions.SetCamera(interiorCam.CFrame),
        
        -- Play the driving animation + dialogue + sound in parallel
        Actions.ParallelActions({
            -- Your driving animation (player looking at phone)
            Actions.PlayCutsceneAnimation("rbxassetid://YOUR_DRIVING_ANIM_ID"),
            
            -- Dialogue during driving
            Actions.Dialogue("Just another day...", 2),
        }),
        
        -- More dialogue
        Actions.Dialogue("Wait, what's that notification?", 2),
        Actions.Dialogue("No way... it can't be...", 2.5),
        
        -- Play parking animation
        Actions.PlayCutsceneAnimation("rbxassetid://YOUR_PARKING_ANIM_ID"),
        
        -- Unweld from car
        Actions.UnweldFromObject(),
        
        -- Fade out
        Actions.FadeOut(0.5),
        
        -- Teleport player outside car
        Actions.TeleportPlayer(parkingSpot.CFrame),
        
        -- Reset camera
        Actions.ResetCamera(),
        
        -- Fade back in
        Actions.FadeIn(1),
        
        -- Unlock player
        Actions.UnlockPlayer(),
        
        -- Give objective
        Actions.ShowObjective("Investigate the building"),
        
        Actions.Log("Driving cutscene complete!"),
    }),
    
    -- Scene 2: Continue your story...
    Chapter.scene("investigation", "The Investigation", {
        -- ... rest of your chapter
    }),
})
```

---

## Advanced Example: Multiple Camera Angles

```lua
Chapter.scene("cinematic_intro", "Epic Intro", {
    Actions.LockPlayer(),
    Actions.FadeIn(1),
    
    -- Camera 1: Wide shot
    Actions.SetCamera(cam1.CFrame),
    Actions.ParallelActions({
        Actions.PlayCutsceneAnimation("rbxassetid://walk_anim"),
        Actions.Dialogue("Where am I?", 2),
    }),
    
    -- Camera 2: Close-up
    Actions.MoveCamera(cam2.CFrame, 1.5),  -- Smooth transition
    Actions.Dialogue("This place... I remember it.", 3),
    
    -- Camera 3: Dramatic angle
    Actions.MoveCamera(cam3.CFrame, 1),
    Actions.ParallelActions({
        Actions.PlayCutsceneAnimation("rbxassetid://shocked_anim"),
        Actions.Dialogue("No... it can't be!", 2),
        Actions.FlashScreen(Color3.new(1, 1, 1), 0.2),
    }),
    
    -- Reset
    Actions.FadeOut(1),
    Actions.ResetCamera(),
    Actions.UnlockPlayer(),
})
```

---

## Tips & Best Practices

### **1. Animation IDs**
Upload your animations to Roblox and get the asset ID:
```lua
"rbxassetid://123456789"  -- Your animation ID
```

### **2. Camera Positioning**
Place empty Parts in Workspace as camera markers:
```lua
local camPart = Workspace.Cameras.IntroCamera
Actions.SetCamera(camPart.CFrame)
```

### **3. Timing**
Match dialogue duration to animation length:
```lua
-- If animation is 5 seconds long:
Actions.ParallelActions({
    Actions.PlayCutsceneAnimation("rbxassetid://123"),
    Actions.Dialogue("Long dialogue here...", 5),  -- Same duration!
})
```

### **4. Skippable Cutscenes**
All animations and waits are skippable with 'P' key automatically!

### **5. Audio Sync**
Play sounds alongside animations:
```lua
Actions.ParallelActions({
    Actions.PlayCutsceneAnimation("rbxassetid://anim"),
    Actions.PlaySound("rbxassetid://sound"),
    Actions.Dialogue("Dialogue", 3),
})
```

---

## Common Patterns

### **Pattern 1: Simple Animation**
```lua
Actions.LockPlayer(),
Actions.PlayCutsceneAnimation("rbxassetid://123"),
Actions.UnlockPlayer(),
```

### **Pattern 2: Animation + Dialogue**
```lua
Actions.LockPlayer(),
Actions.ParallelActions({
    Actions.PlayCutsceneAnimation("rbxassetid://123"),
    Actions.Dialogue("I'm doing something!", 3),
}),
Actions.UnlockPlayer(),
```

### **Pattern 3: Vehicle Cutscene**
```lua
Actions.LockPlayer(),
Actions.TeleportPlayer(vehicleSeat.CFrame),
Actions.WeldToObject(vehicleSeat),
Actions.PlayCutsceneAnimation("rbxassetid://driving"),
Actions.UnweldFromObject(),
Actions.TeleportPlayer(exitPoint.CFrame),
Actions.UnlockPlayer(),
```

### **Pattern 4: Custom Rig Cutscene**
```lua
Actions.LockPlayer(),
Actions.HideCharacter(),  -- Hide player
-- Show your custom animated rig here
Actions.Wait(5),  -- Let custom rig animation play
-- Hide your custom rig
Actions.ShowCharacter(),  -- Show player again
Actions.UnlockPlayer(),
```

---

## Troubleshooting

### **Animation not playing?**
- Check the animation ID is correct
- Make sure animation is published
- Verify animation is for R15 or R6 (match your game)

### **Player not moving with object?**
- Use `WeldToObject` before animation
- Make sure the object is a BasePart
- Don't forget `UnweldFromObject` after!

### **Camera stuck?**
- Always call `ResetCamera()` after cutscene
- Use `SetCamera` for instant, `MoveCamera` for smooth

### **Dialogue out of sync?**
- Use `ParallelActions` to run them together
- Match dialogue duration to animation length

---

## Full Workflow

1. **Create animations** in Roblox Animation Editor
2. **Upload animations** and get asset IDs
3. **Place camera markers** in Workspace (empty Parts)
4. **Place teleport markers** for player positions
5. **Write scene** using the actions above
6. **Test and adjust** timings
7. **Press P** to skip during testing!

---

## Example: Your Driving Scene

```lua
Chapter.scene("intro_drive", "The Drive", {
    -- Setup
    Actions.LockPlayer(),
    Actions.FadeOut(0),
    Actions.TeleportPlayer(carSeat.CFrame),
    Actions.WeldToObject(carSeat),
    Actions.SetCamera(carInteriorCam.CFrame),
    Actions.FadeIn(1),
    
    -- Driving cutscene
    Actions.ParallelActions({
        Actions.PlayCutsceneAnimation("rbxassetid://DRIVING_PHONE_ANIM"),
        Actions.Dialogue("Just checking my messages...", 3),
        Actions.PlaySound("rbxassetid://CAR_ENGINE"),
    }),
    
    Actions.Dialogue("Wait, what's this notification?", 2),
    
    -- Parking
    Actions.PlayCutsceneAnimation("rbxassetid://PARKING_ANIM"),
    Actions.Dialogue("Alright, I'm here.", 2),
    
    -- Exit car
    Actions.FadeOut(0.5),
    Actions.UnweldFromObject(),
    Actions.TeleportPlayer(parkingSpot.CFrame),
    Actions.ResetCamera(),
    Actions.FadeIn(1),
    Actions.UnlockPlayer(),
    
    Actions.ShowObjective("Enter the building"),
}),
```

Now you have full cinematic control! 🎬✨
