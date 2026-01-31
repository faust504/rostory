# How to Trigger Cutscenes from Buttons

## ✅ What I Just Did

Modified `MainMenu.luau` so the **Play button** triggers Chapter 1's intro cutscene.

---

## 🎬 How It Works Now

**When player clicks "Play":**

1. Screen fades to black (`UIManager:FadeOut(1)`)
2. Main menu hides
3. Chapter1_Intro loads
4. `Chapter1.Start()` runs → triggers the "intro" scene
5. Your cutscene plays (camera, dialogue, teleport, etc.)

---

## 📝 The Code (Lines 212-227 in MainMenu.luau)

```lua
function MainMenu:OnPlayClicked(): ()
    print("[MainMenu] Play clicked")

    -- Fade out UI and start Chapter 1
    task.spawn(function()
        UIManager:FadeOut(1)
        self:Hide()
        
        -- Load and start Chapter 1
        local Story = script.Parent.Parent:WaitForChild("Story")
        local Chapters = Story:WaitForChild("Chapters")
        local Chapter1 = require(Chapters:WaitForChild("Chapter1_Intro"))
        
        -- Start the intro scene
        Chapter1.Start()  -- ← This triggers the cutscene!
    end)
end
```

---

## 🎯 How to Trigger ANY Chapter from ANY Button

### Pattern 1: Trigger from a UI Button

```lua
-- In any UI script (like MainMenu.luau)
button.MouseButton1Click:Connect(function()
    local Story = script.Parent.Parent:WaitForChild("Story")
    local Chapters = Story:WaitForChild("Chapters")
    local MyChapter = require(Chapters:WaitForChild("MyChapter"))
    
    MyChapter.Start()  -- Starts the chapter's startScene
    
    -- OR play a specific scene:
    MyChapter.PlayScene("scene_id")
end)
```

### Pattern 2: Trigger from a ProximityPrompt

```lua
-- In a LocalScript attached to a Part with ProximityPrompt
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local prompt = script.Parent:WaitForChild("ProximityPrompt")

prompt.Triggered:Connect(function(player)
    if player == LocalPlayer then
        local Story = LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Story")
        local Chapters = Story:WaitForChild("Chapters")
        local Chapter2 = require(Chapters:WaitForChild("Chapter2"))
        
        Chapter2.Start()
    end
end)
```

### Pattern 3: Trigger when Player Touches a Part

```lua
-- In a LocalScript attached to a trigger Part
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local triggerPart = script.Parent

triggerPart.Touched:Connect(function(hit)
    if hit.Parent == LocalPlayer.Character then
        local Story = LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Story")
        local Chapters = Story:WaitForChild("Chapters")
        local Chapter3 = require(Chapters:WaitForChild("Chapter3"))
        
        Chapter3.Start()
        
        -- Disable trigger so it only fires once
        triggerPart.CanTouch = false
    end
end)
```

### Pattern 4: Auto-trigger on Player Join

```lua
-- In a LocalScript in StarterPlayer > StarterPlayerScripts
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for character to load
LocalPlayer.CharacterAdded:Wait()
task.wait(1)  -- Small delay for everything to load

-- Trigger intro cutscene
local Story = LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Story")
local Chapters = Story:WaitForChild("Chapters")
local Intro = require(Chapters:WaitForChild("Chapter1_Intro"))

Intro.Start()
```

---

## 🔧 What Chapter1.Start() Actually Does

Looking at `Chapter1_Intro.luau` lines 127-134:

```lua
local function StartChapter1()
    local scene = Chapter.getScene("chapter1", "intro")  -- Get the "intro" scene
    if scene then
        Director:PlaySequence(scene.actions, `Chapter1/{scene.id}`)  -- Play it!
    end
end
```

It:
1. Gets the scene with id `"intro"` from the chapter
2. Passes all the actions to `Director:PlaySequence()`
3. Director executes each action in order

---

## 🎮 Testing It

1. **Start Roblox Studio** with Rojo connected
2. **Press Play**
3. **Click the "Play" button** in the main menu
4. **Watch the cutscene:**
   - Screen fades to black
   - Camera positions
   - Dialogue appears
   - Player gets teleported
   - Controls unlock

---

## 💡 Pro Tips

1. **Always use `task.spawn()`** when triggering cutscenes from buttons to avoid blocking the UI thread
2. **Hide the menu first** before starting cutscenes (like we do with `self:Hide()`)
3. **Use `Chapter.Start()`** to play the default scene, or `Chapter.PlayScene("id")` for specific scenes
4. **Test one scene at a time** - don't write all scenes before testing!

---

*Now your Play button triggers the full Chapter 1 intro cutscene! 🎬*
