# Scene Transitions - Important Pattern 🎬

## The Problem We Solved

### ❌ What Doesn't Work:
```lua
-- Scene 1
Actions.ShowObjective("Explore"),
Actions.WaitForProximityPrompt(gatePrompt),  // ❌ BLOCKS Scene 1!
Actions.Call(function()
    Director:PlaySequence(Scene2)  // ❌ ERROR: Already playing!
end),
```

**Why it fails:**
- `WaitForProximityPrompt` **blocks** Scene 1 from completing
- Scene 1 is still "playing" when you try to start Scene 2
- Director says: "Already playing a sequence, queuing not implemented"

---

## ✅ The Solution: Background Listeners

### How It Works Now:
```lua
-- Scene 1
Actions.ShowObjective("Explore"),

-- Set up a background listener (non-blocking)
Actions.ListenForPrompt(gatePrompt, function()
    -- This callback runs AFTER Scene 1 ends
    task.wait(0.1)  // Ensure Scene 1 is fully done
    
    local scene2 = Chapter.getScene("chapter1", "discovery")
    Director:PlaySequence(scene2.actions, "Chapter1/discovery")
end),

// Scene 1 ENDS here immediately
// Player can explore freely
// When they press E on gate, Scene 2 starts!
```

**Why it works:**
1. `ListenForPrompt` sets up a listener in the **background**
2. Scene 1 **ends immediately** after this action
3. Player can explore freely
4. When player presses E, the **callback fires**
5. Scene 2 starts (no conflict because Scene 1 is done!)

---

## The Two Types of Actions

### 🔴 Blocking Actions (Wait)
These **pause** the scene until something happens:
- `WaitForProximity(part, distance)`
- `WaitForProximityPrompt(prompt)`
- `WaitForToolEquip(toolName)`
- `WaitForToolActivation(toolName)`

**Use when:** The scene should pause and wait (e.g., "Wait for player to press button")

### 🟢 Non-Blocking Actions (Listen)
These **set up listeners** and continue immediately:
- `ListenForProximity(part, distance, callback)`
- `ListenForPrompt(prompt, callback)`

**Use when:** You want to end the scene but trigger something later (e.g., scene transitions)

---

## When to Use Each

### Use Blocking (Wait) Actions:
```lua
// Example: Puzzle that must be solved before continuing
Actions.Dialogue("I need to find the key...", "Player", 2),
Actions.WaitForToolEquip("Key"),  // ⏸️ WAIT here
Actions.Dialogue("Got it!", "Player", 1),
Actions.WaitForToolOnPrompt(doorPrompt, "Key"),  // ⏸️ WAIT here
Actions.Dialogue("The door opens!", nil, 1),
// Scene continues...
```

### Use Non-Blocking (Listen) Actions:
```lua
// Example: Scene transition
Actions.ShowObjective("Explore the area"),
Actions.ListenForPrompt(gatePrompt, function()
    // ▶️ This runs later, in the background
    task.wait(0.1)
    local nextScene = Chapter.getScene("chapter1", "nextScene")
    Director:PlaySequence(nextScene.actions, "Chapter1/nextScene")
end),
// Scene ENDS here - player can explore
```

---

## Current Chapter1_Intro Flow

```
┌─────────────────────────────────────────────┐
│ Scene 1 (intro) STARTS                      │
├─────────────────────────────────────────────┤
│ • FadeOut                                   │
│ • LockPlayer                                │
│ • PlayMusic                                 │
│ • SetCamera                                 │
│ • Dialogue ("Ah..")                         │
│ • TeleportPlayer                            │
│ • Restore visibility                        │
│ • ResetCamera                               │
│ • UnlockPlayer                              │
│ • ShowObjective("Explore")                  │
│                                             │
│ • ListenForPrompt(gatePrompt, callback) ◄── Sets up listener
│                                             │
├─────────────────────────────────────────────┤
│ Scene 1 ENDS ✅                             │
└─────────────────────────────────────────────┘
         │
         │ Player explores...
         │
         ▼
┌─────────────────────────────────────────────┐
│ Player presses E on GatePart                │
├─────────────────────────────────────────────┤
│ Callback fires! ◄────────────────────────── Background listener
│ task.wait(0.1)                              │
│ Director:PlaySequence(Scene 2)              │
└─────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│ Scene 2 (discovery) STARTS ✅               │
├─────────────────────────────────────────────┤
│ • LockPlayer                                │
│ • Dialogue ("What is this place?")         │
│ • Choice (Yes/No)                           │
│ • ...                                       │
└─────────────────────────────────────────────┘
```

---

## Multiple Scene Transitions

You can set up multiple listeners for different triggers:

```lua
-- Scene 1
Actions.ShowObjective("Explore and find clues"),

-- Listener for gate (goes to Scene 2)
Actions.ListenForPrompt(gatePrompt, function()
    task.wait(0.1)
    local scene2 = Chapter.getScene("chapter1", "discovery")
    Director:PlaySequence(scene2.actions, "Chapter1/discovery")
end),

-- Listener for secret area (optional side scene)
Actions.ListenForProximity(secretPart, 5, function()
    Director:PlaySequence({
        Actions.Dialogue("You found a secret!", nil, 2),
        Actions.PlaySound("rbxassetid://123456"),
    }, "SecretFound")
end),

// Scene 1 ends - both listeners are active!
// Player can trigger either one (or both!)
```

---

## Troubleshooting

### "Already playing a sequence" error?
✅ **Use `ListenForPrompt`** instead of `WaitForProximityPrompt` for scene transitions

### Scene 2 doesn't start?
1. Check Output for `[Chapter1] Gate triggered!` message
2. Verify the callback is firing
3. Add more logging:
```lua
Actions.ListenForPrompt(gatePrompt, function()
    print("🔥 CALLBACK FIRED!")
    task.wait(0.1)
    print("🔥 About to start Scene 2...")
    local scene2 = Chapter.getScene("chapter1", "discovery")
    if scene2 then
        print("🔥 Scene 2 found, starting...")
        Director:PlaySequence(scene2.actions, "Chapter1/discovery")
    else
        warn("❌ Scene 2 not found!")
    end
end),
```

### Need to wait WITHIN a scene?
✅ **Use `WaitForProximityPrompt`** - it's perfect for that:
```lua
// Scene 2
Actions.Dialogue("I need to unlock this door...", "Player", 2),
Actions.WaitForToolOnPrompt(doorPrompt, "Key"),  // ⏸️ WAIT
Actions.Dialogue("It's open!", "Player", 1),
// Scene continues...
```

---

## Quick Reference

| Scenario | Action to Use |
|----------|---------------|
| **Transition to next scene** | `ListenForPrompt(prompt, callback)` |
| **Transition when player approaches** | `ListenForProximity(part, dist, callback)` |
| **Wait for puzzle solution** | `WaitForToolOnPrompt(prompt, tool)` |
| **Wait for player to pick up item** | `WaitForToolEquip(toolName)` |
| **Wait for player to press button** | `WaitForProximityPrompt(prompt)` |
| **Wait for player to get close** | `WaitForProximity(part, distance)` |

---

## Summary

**The Golden Rule:**
- **Blocking actions** (`Wait...`) = Scene pauses until condition is met
- **Non-blocking actions** (`Listen...`) = Scene ends, callback fires later

**For scene transitions:**
Always use **`ListenForPrompt`** or **`ListenForProximity`** so the current scene can end before the next one starts!

Now Scene 2 should trigger perfectly when you interact with the gate! 🎉
