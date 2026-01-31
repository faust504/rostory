# Quick Start Guide for Story Directors

## 📍 Where To Put Your Code

### ✅ You Work Here:
```
src/client/Story/Chapters/
├── Chapter1_Intro.luau    ← EXAMPLE (copy this!)
├── Chapter2_YourStory.luau ← CREATE NEW FILES HERE
└── Chapter3_YourStory.luau ← CREATE NEW FILES HERE
```

### ❌ Don't Touch These (Framework Files):
- Everything in `Controllers/`
- Everything in `UI/`
- Everything in `Services/`
- `Director.luau`, `Actions.luau`, `Chapter.luau`

---

## 🎬 Create a New Cutscene in 3 Steps

### Step 1: Create File
**File:** `src/client/Story/Chapters/MyChapter.luau`

**Lines 1-10:** Copy this exactly:
```lua
--!strict
local Story = script.Parent.Parent
local Director = require(Story:WaitForChild("Director"))
local Chapter = require(Story:WaitForChild("Chapter"))
local Actions = Director.Actions
```

### Step 2: Define Chapter
**Lines 11-20:** Add your chapter structure:
```lua
local MyChapter = Chapter.new({
    id = "mychapter",
    name = "My First Chapter",
    startScene = "opening",
    scenes = {
        -- Continue to Step 3...
    }
})

return MyChapter
```

### Step 3: Add Your Cutscene
**Inside `scenes = { }`:** Add your scenes:
```lua
        Chapter.scene("opening", "Opening", {
            Actions.LockPlayer(),
            Actions.FadeOut(0),
            Actions.SetCamera(CFrame.new(0, 10, 20)),
            Actions.FadeIn(1),
            Actions.Dialogue("Where am I?", "Player", 2),
            Actions.UnlockPlayer(),
        }),
```

---

## 🎯 At What Line Do I Add...?

| What | Where |
|------|-------|
| **New chapter file** | Create `src/client/Story/Chapters/MyChapter.luau` |
| **Imports** | Lines 1-10 (copy from Chapter1) |
| **Chapter definition start** | Line 11 |
| **Your first scene** | Inside `scenes = {}` array |
| **Dialogue** | Inside scene actions: `Actions.Dialogue("text", "speaker")` |
| **Camera movement** | Inside scene actions: `Actions.SetCamera(cframe)` |
| **Player choices** | Inside scene actions: `Actions.Choice(prompt, {...})` |

---

## 📖 Full Documentation

See **[DIRECTORS_GUIDE.md](DIRECTORS_GUIDE.md)** for:
- Complete actions reference (30+ actions!)
- Detailed examples
- Best practices
- Advanced patterns

---

## 🚀 Your First 5 Minutes

1. Open `src/client/Story/Chapters/Chapter1_Intro.luau`
2. Copy the entire file
3. Save as `src/client/Story/Chapters/MyFirstChapter.luau`
4. Change line 23: `id = "myfirstchapter"`
5. Edit the dialogue and camera positions to match your story
6. Done! Rojo will sync it automatically.

---

*Need help? Read the full guide: [DIRECTORS_GUIDE.md](DIRECTORS_GUIDE.md)*
