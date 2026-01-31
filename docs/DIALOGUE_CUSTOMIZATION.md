# Dialogue Customization Guide 🎨

## New Dialogue System

The dialogue system has been completely redesigned to be **clean and minimal**:

✅ **Just text** - no background boxes
✅ **No speaker labels** - text color indicates who's talking
✅ **Text stroke outline** - black outline for readability
✅ **Special Elite font** - default font (customizable)
✅ **Typewriter animation** - character-by-character reveal
✅ **Fully customizable** - color, font, size per dialogue

---

## New Dialogue Signature

### Before (Old):
```lua
Actions.Dialogue(text, speaker, duration)
Actions.Dialogue("Hello!", "Player", 2)
```

### After (New):
```lua
Actions.Dialogue(text, duration, color, font, textSize)
Actions.Dialogue("Hello!", 2)  -- White text, Special Elite, 32px
```

---

## Basic Usage

### Default (White Text):
```lua
Actions.Dialogue("...", 1),
Actions.Dialogue("Where... am I?", 2),
Actions.Dialogue("My head... it hurts...", 2),
```

**Result:** White text, Special Elite font, 32px, centered at bottom of screen

---

## Custom Colors (Who's Talking)

### Player (White):
```lua
Actions.Dialogue("I need to figure out where I am.", 2)
```

### Mysterious Voice (Light Blue):
```lua
Actions.Dialogue(
    "You shouldn't be here...", 
    2, 
    Color3.fromRGB(150, 200, 255)  -- Light blue
)
```

### Danger/Warning (Red):
```lua
Actions.Dialogue(
    "RUN!", 
    1, 
    Color3.fromRGB(255, 100, 100)  -- Red
)
```

### Narrator/System (Gray):
```lua
Actions.Dialogue(
    "The door creaks open...", 
    2, 
    Color3.fromRGB(180, 180, 180)  -- Gray
)
```

---

## Custom Fonts

### Available Fonts:
- `Enum.Font.SpecialElite` (default - typewriter style)
- `Enum.Font.Gotham` (clean, modern)
- `Enum.Font.GothamBold` (bold, impactful)
- `Enum.Font.Creepster` (horror/spooky)
- `Enum.Font.FredokaOne` (playful)
- `Enum.Font.Bangers` (comic/action)

### Examples:
```lua
-- Horror atmosphere
Actions.Dialogue(
    "They're coming...", 
    2, 
    Color3.fromRGB(200, 100, 100),  -- Dark red
    Enum.Font.Creepster  -- Spooky font
)

-- Important announcement
Actions.Dialogue(
    "CHAPTER 1 COMPLETE", 
    3, 
    Color3.fromRGB(255, 215, 0),  -- Gold
    Enum.Font.GothamBold,
    48  -- Larger text
)
```

---

## Custom Text Size

### Small (Whisper):
```lua
Actions.Dialogue(
    "...help...", 
    1.5, 
    Color3.fromRGB(150, 150, 150),  -- Gray
    Enum.Font.SpecialElite,
    24  -- Smaller
)
```

### Normal (Default):
```lua
Actions.Dialogue("Hello!", 2)  -- 32px (default)
```

### Large (Shout/Important):
```lua
Actions.Dialogue(
    "LOOK OUT!", 
    1, 
    Color3.fromRGB(255, 50, 50),  -- Bright red
    Enum.Font.GothamBold,
    50  -- Much larger
)
```

---

## Complete Examples

### Scene with Different Speakers:

```lua
Chapter.scene("example", "Example Scene", {
    -- Mysterious opening (light blue, creepy font)
    Actions.Dialogue(
        "Wake up...", 
        2, 
        Color3.fromRGB(150, 200, 255),
        Enum.Font.Creepster
    ),
    
    -- Player confused (white, default)
    Actions.Dialogue("Where am I?", 2),
    
    -- Narrator (gray, italic feel)
    Actions.Dialogue(
        "The room is dark and cold.", 
        2, 
        Color3.fromRGB(180, 180, 180),
        Enum.Font.Gotham,
        28
    ),
    
    -- Player scared (light white/blue)
    Actions.Dialogue(
        "I need to get out of here!", 
        2, 
        Color3.fromRGB(220, 220, 255)
    ),
    
    -- Warning (red, bold, large)
    Actions.Dialogue(
        "DANGER!", 
        1, 
        Color3.fromRGB(255, 100, 100),
        Enum.Font.GothamBold,
        45
    ),
}),
```

---

## Color Palette Suggestions

### Character Colors:
```lua
-- Player
local PLAYER_COLOR = Color3.fromRGB(255, 255, 255)  -- White

-- Mysterious Voice
local MYSTERY_COLOR = Color3.fromRGB(150, 200, 255)  -- Light blue

-- Villain
local VILLAIN_COLOR = Color3.fromRGB(255, 100, 120)  -- Red-pink

-- Friend/Ally
local ALLY_COLOR = Color3.fromRGB(150, 255, 150)  -- Light green

-- Narrator
local NARRATOR_COLOR = Color3.fromRGB(180, 180, 180)  -- Gray

-- System/Important
local SYSTEM_COLOR = Color3.fromRGB(255, 215, 0)  -- Gold
```

### Usage:
```lua
Actions.Dialogue("Hello!", 2, PLAYER_COLOR),
Actions.Dialogue("Who are you?", 2, MYSTERY_COLOR),
```

---

## Updating Your Existing Dialogues

### Old Format:
```lua
Actions.Dialogue("...", nil, 1),
Actions.Dialogue("Ah..", "???", 2),
Actions.Dialogue("What is this place..", "Player", 2),
```

### New Format (Simple):
```lua
Actions.Dialogue("...", 1),
Actions.Dialogue("Ah..", 2),
Actions.Dialogue("What is this place..", 2),
```

### New Format (With Colors):
```lua
Actions.Dialogue("...", 1, Color3.fromRGB(200, 200, 200)),  -- Gray
Actions.Dialogue("Ah..", 2, Color3.fromRGB(150, 200, 255)),  -- Mystery voice
Actions.Dialogue("What is this place..", 2),  -- Player (white)
```

---

## Visual Appearance

### What You'll See:
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│         Where am I...?                  │  ← Centered text
│                                         │  ← Black outline
│                                         │  ← No background!
└─────────────────────────────────────────┘
```

- **Position:** Bottom center of screen
- **Background:** None (transparent)
- **Outline:** 3px black stroke
- **Animation:** Typewriter effect (0.03s per character)
- **Font:** Special Elite (default)
- **Size:** 32px (default)
- **Color:** White (default)

---

## Advanced: Dynamic Dialogue

### Change color mid-scene:
```lua
-- Start calm
Actions.Dialogue("It's quiet...", 2, Color3.fromRGB(180, 180, 180)),

-- Build tension
Actions.Dialogue("Too quiet...", 2, Color3.fromRGB(200, 200, 150)),

-- Panic!
Actions.Dialogue("SOMETHING'S WRONG!", 1, Color3.fromRGB(255, 100, 100)),
```

### Combine with other actions:
```lua
-- Whisper with screen shake
Actions.Dialogue("Did you hear that?", 2, Color3.fromRGB(150, 150, 150), Enum.Font.SpecialElite, 24),
Actions.ScreenShake(0.2, 0.5),

-- Loud with flash
Actions.FlashScreen(Color3.new(1, 0, 0), 0.1),
Actions.Dialogue("GET OUT!", 1, Color3.fromRGB(255, 50, 50), Enum.Font.GothamBold, 50),
```

---

## Summary

**New Dialogue Parameters:**
1. `text` (string) - The dialogue text
2. `duration` (number, optional) - How long to show (default: 2)
3. `color` (Color3, optional) - Text color (default: white)
4. `font` (Enum.Font, optional) - Font style (default: SpecialElite)
5. `textSize` (number, optional) - Text size (default: 32)

**Quick Reference:**
```lua
-- Minimal
Actions.Dialogue("Hello!", 2)

-- With color
Actions.Dialogue("Hello!", 2, Color3.fromRGB(150, 200, 255))

-- Full custom
Actions.Dialogue("HELLO!", 2, Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold, 48)
```

Now your dialogue system is fully customizable! 🎨✨
