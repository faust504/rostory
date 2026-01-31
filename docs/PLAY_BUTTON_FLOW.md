# Play Button Flow - Complete Connection Map 🎮

## The Complete Journey: From Click to Cutscene

Here's **exactly** how the Play button connects to all the teleport, camera, and dialogue logic:

---

## 📍 Step-by-Step Flow

### **1. Player Clicks "Play" Button**
**File:** `src/client/UI/MainMenu.luau` (Line 205)

```lua
button.MouseButton1Click:Connect(callback)
```

When you click the Play button, it calls the `callback` function, which is:

---

### **2. OnPlayClicked() is Called**
**File:** `src/client/UI/MainMenu.luau` (Lines 213-233)

```lua
function MainMenu:OnPlayClicked(): ()
    print("[MainMenu] Play clicked")
    
    task.spawn(function()
        -- Fade screen to black
        UIManager:FadeOut(1)
        
        -- Hide the menu
        self:Hide()
        
        -- Load Chapter 1
        local Chapter1 = require(Chapters:WaitForChild("Chapter1_Intro"))
        
        -- ⭐ THIS IS THE KEY LINE - Start Chapter 1!
        Chapter1.Start()
    end)
end
```

**What happens:**
- ✅ Screen fades to black (1 second)
- ✅ Main menu is hidden
- ✅ Chapter 1 module is loaded
- ✅ `Chapter1.Start()` is called

---

### **3. Chapter1.Start() Executes**
**File:** `src/client/Story/Chapters/Chapter1_Intro.luau` (Lines 126-131)

```lua
local function StartChapter1()
    local scene = Chapter.getScene("chapter1", "intro")
    if scene then
        -- ⭐ THIS CALLS THE DIRECTOR!
        Director:PlaySequence(scene.actions, `Chapter1/{scene.id}`)
    end
end
```

**What happens:**
- ✅ Gets the "intro" scene from Chapter 1
- ✅ Extracts the list of actions from the scene
- ✅ Passes those actions to the **Director**

---

### **4. Director:PlaySequence() Runs the Actions**
**File:** `src/client/Story/Director.luau` (Lines 59-85)

```lua
function Director:PlaySequence(actions: { StoryAction }, sequenceName: string?): ()
    isPlayingSequence = true
    currentSequenceName = sequenceName or "Anonymous"
    
    print(`[Director] Playing sequence: {currentSequenceName}`)
    
    -- ⭐ THIS IS WHERE THE MAGIC HAPPENS!
    -- Execute each action in order
    for i, action in actions do
        action()  -- Calls each action function one by one
    end
    
    isPlayingSequence = false
    print(`[Director] Sequence complete`)
end
```

**What happens:**
- ✅ Loops through each action in the scene
- ✅ Executes them **one at a time, in order**
- ✅ Each action is a function that does something (fade, teleport, dialogue, etc.)

---

### **5. The Scene Actions Execute**
**File:** `src/client/Story/Chapters/Chapter1_Intro.luau` (Lines 28-64)

Here's the **actual list of actions** that run when you click Play:

```lua
Chapter.scene("intro", "The Awakening", {
    -- Action 1: Fade to black instantly
    Actions.FadeOut(0),
    
    -- Action 2: Lock player movement
    Actions.LockPlayer(),
    
    -- Action 3: Log to console
    Actions.Log("Starting Chapter 1: The Awakening"),
    
    -- Action 4: Play background music
    Actions.PlayMusic("rbxassetid://1837849285", 2),
    
    -- Action 5: Set camera position
    Actions.SetCamera(CFrame.new(0, 5, 10) * CFrame.Angles(math.rad(-10), 0, 0)),
    
    -- Action 6: Wait 1 second
    Actions.Wait(1),
    
    -- Action 7: Fade in from black
    Actions.FadeIn(2),
    
    -- Action 8: Wait 1 second
    Actions.Wait(1),
    
    -- Action 9: Show dialogue "..."
    Actions.Dialogue("...", nil, 1),
    
    -- Action 10: Show dialogue "Where... am I?"
    Actions.Dialogue("Where... am I?", "???", 2),
    
    -- Action 11: Shake the screen
    Actions.ScreenShake(0.3, 0.5),
    
    -- Action 12: Play eerie sound
    Actions.PlaySound("rbxassetid://5982052366"),
    
    -- Action 13: Wait 0.5 seconds
    Actions.Wait(0.5),
    
    -- Action 14: Show dialogue "My head... it hurts..."
    Actions.Dialogue("My head... it hurts...", "???", 2),
    
    -- Action 15: Fade to black
    Actions.FadeOut(1),
    
    -- Action 16: Wait 0.5 seconds
    Actions.Wait(0.5),
    
    -- Action 17: ⭐ TELEPORT THE PLAYER!
    Actions.TeleportPlayer(CFrame.new(0, 3, 0)),
    
    -- Action 18: Make character visible again
    Actions.Call(function()
        local character = Players.LocalPlayer.Character
        if character then
            for _, part in character:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                end
            end
        end
    end),
    
    -- Action 19: ⭐ RESET CAMERA to follow player
    Actions.ResetCamera(),
    
    -- Action 20: Fade in from black
    Actions.FadeIn(1.5),
    
    -- Action 21: Unlock player movement
    Actions.UnlockPlayer(),
    
    -- Action 22: Show dialogue
    Actions.Dialogue("I need to figure out where I am.", "Player", 2),
    
    -- Action 23: Show objective notification
    Actions.ShowObjective("Explore the Environment"),
})
```

---

## 🔗 The Connection Chain

Here's the **complete chain** from button to action:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. PLAYER CLICKS "PLAY" BUTTON                                  │
│    File: MainMenu.luau (line 205)                               │
│    Code: button.MouseButton1Click:Connect(callback)             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. MainMenu:OnPlayClicked() IS CALLED                           │
│    File: MainMenu.luau (lines 213-233)                          │
│    Actions:                                                      │
│    - Fades screen to black (UIManager:FadeOut)                  │
│    - Hides the menu                                             │
│    - Loads Chapter1_Intro module                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Chapter1.Start() IS CALLED                                   │
│    File: Chapter1_Intro.luau (lines 126-131)                    │
│    Actions:                                                      │
│    - Gets the "intro" scene definition                          │
│    - Extracts the list of actions from the scene                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Director:PlaySequence(actions) IS CALLED                     │
│    File: Director.luau (lines 59-85)                            │
│    Actions:                                                      │
│    - Loops through each action in the list                      │
│    - Executes them ONE BY ONE in order                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. EACH ACTION EXECUTES (23 actions total)                      │
│    File: Actions.luau (various functions)                       │
│                                                                  │
│    Action Examples:                                              │
│    ┌──────────────────────────────────────────────────────────┐│
│    │ Actions.FadeOut(0)                                       ││
│    │ → File: Actions.luau (lines 136-144)                     ││
│    │ → Creates a tween to fade screen to black                ││
│    └──────────────────────────────────────────────────────────┘│
│                                                                  │
│    ┌──────────────────────────────────────────────────────────┐│
│    │ Actions.SetCamera(CFrame.new(0, 5, 10))                  ││
│    │ → File: Actions.luau (lines 277-285)                     ││
│    │ → Sets camera to scriptable mode                         ││
│    │ → Positions camera at specified CFrame                   ││
│    └──────────────────────────────────────────────────────────┘│
│                                                                  │
│    ┌──────────────────────────────────────────────────────────┐│
│    │ Actions.Dialogue("Where... am I?", "???", 2)             ││
│    │ → File: Actions.luau (lines 162-187)                     ││
│    │ → Shows dialogue UI                                      ││
│    │ → Typewriter effect for text                             ││
│    │ → Waits for duration                                     ││
│    └──────────────────────────────────────────────────────────┘│
│                                                                  │
│    ┌──────────────────────────────────────────────────────────┐│
│    │ Actions.TeleportPlayer(CFrame.new(0, 3, 0))              ││
│    │ → File: Actions.luau (lines 192-210)                     ││
│    │ → Gets player's HumanoidRootPart                         ││
│    │ → Sets CFrame to teleport position                       ││
│    └──────────────────────────────────────────────────────────┘│
│                                                                  │
│    ┌──────────────────────────────────────────────────────────┐│
│    │ Actions.ResetCamera()                                    ││
│    │ → File: Actions.luau (lines 290-297)                     ││
│    │ → Sets camera back to Custom (follow player)             ││
│    └──────────────────────────────────────────────────────────┘│
│                                                                  │
│    ┌──────────────────────────────────────────────────────────┐│
│    │ Actions.UnlockPlayer()                                   ││
│    │ → File: Actions.luau (lines 382-393)                     ││
│    │ → Restores WalkSpeed to 16                               ││
│    │ → Restores JumpPower to 50                               ││
│    └──────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎬 How Each Action Works

### **Teleport Logic**
**File:** `src/client/Story/Actions.luau` (Lines 192-210)

```lua
function Actions.TeleportPlayer(position: CFrame | Vector3): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- ⭐ THIS IS THE ACTUAL TELEPORT!
        if typeof(position) == "Vector3" then
            humanoidRootPart.CFrame = CFrame.new(position)
        else
            humanoidRootPart.CFrame = position
        end
    end
end
```

---

### **Camera Logic**
**File:** `src/client/Story/Actions.luau` (Lines 277-297)

```lua
-- Set camera to a specific position
function Actions.SetCamera(targetCFrame: CFrame): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if camera then
            -- ⭐ SWITCH TO SCRIPTABLE MODE (cutscene camera)
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = targetCFrame
        end
    end
end

-- Reset camera to follow player
function Actions.ResetCamera(): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if camera then
            -- ⭐ SWITCH BACK TO CUSTOM MODE (normal gameplay)
            camera.CameraType = Enum.CameraType.Custom
        end
    end
end
```

---

### **Dialogue Logic**
**File:** `src/client/Story/Actions.luau` (Lines 162-187)

```lua
function Actions.Dialogue(text: string, speaker: string?, duration: number?): StoryAction
    return function()
        local frame, textLabel, speakerLabel = getDialogueUI()
        
        speakerLabel.Text = speaker or ""
        textLabel.Text = ""
        frame.Visible = true
        
        -- ⭐ TYPEWRITER EFFECT!
        for i = 1, #text do
            textLabel.Text = string.sub(text, 1, i)
            task.wait(0.03)  -- 30ms per character
        end
        
        -- ⭐ WAIT FOR PLAYER TO READ
        task.wait(duration or 2)
        
        -- ⭐ FADE OUT DIALOGUE
        local tween = TweenService:Create(frame, TweenInfo.new(0.3), 
            { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Wait()
        
        frame.Visible = false
        frame.BackgroundTransparency = 0.2
    end
end
```

---

## 🧩 The Key Design Pattern

The system uses a **functional programming pattern** called **"Actions as Functions"**:

1. **Each action returns a function** (not executes immediately)
2. **Director collects all these functions** in a list
3. **Director executes them one by one** in sequence
4. **Each function waits until complete** before moving to the next

This is why you can write story content like a **movie script**:

```lua
{
    Actions.FadeOut(1),           -- Wait 1 second
    Actions.Dialogue("Hello!"),   -- Wait for dialogue
    Actions.TeleportPlayer(pos),  -- Instant
    Actions.FadeIn(1),            -- Wait 1 second
}
```

Each action **blocks** until it's done, so they execute in perfect sequence!

---

## 📂 File Reference Quick Guide

| What You Want to Change | File to Edit |
|------------------------|--------------|
| **Play button appearance** | `src/client/UI/MainMenu.luau` |
| **What happens when Play is clicked** | `src/client/UI/MainMenu.luau` (OnPlayClicked) |
| **Which chapter starts** | `src/client/UI/MainMenu.luau` (line 224) |
| **The cutscene sequence** | `src/client/Story/Chapters/Chapter1_Intro.luau` |
| **Add new actions (fade, teleport, etc.)** | `src/client/Story/Actions.luau` |
| **How actions are executed** | `src/client/Story/Director.luau` |

---

## 🎯 Summary

**The Play Button Flow:**
1. **Click** → `MainMenu:OnPlayClicked()`
2. **Fade & Hide Menu** → `UIManager:FadeOut()` + `self:Hide()`
3. **Load Chapter** → `require(Chapter1_Intro)`
4. **Start Scene** → `Chapter1.Start()`
5. **Get Actions** → `Chapter.getScene("chapter1", "intro")`
6. **Execute Sequence** → `Director:PlaySequence(actions)`
7. **Run Each Action** → Loop through actions, call each function
8. **Actions Do Their Thing** → Teleport, camera, dialogue, etc.

**It's like a chain reaction:** Click → Load → Execute → Magic! ✨

---

Want to add more cutscenes or modify the existing one? Just edit the actions list in `Chapter1_Intro.luau`! 🎬
