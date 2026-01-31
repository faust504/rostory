# Using Choice Actions - Important Pattern 🎯

## The Problem with Nested Sequences

### ❌ What Doesn't Work:
```lua
Actions.Choice("Should I go inside?", {
    {
        text = "Yes",
        callback = function()
            Director:PlaySequence({  // ❌ ERROR!
                Actions.Dialogue("Okay...", "Player", 1),
            })
        end
    }
}),
```

**Why it fails:**
- The Choice action is **part of a running sequence** (Scene 2)
- The callback tries to start a **new sequence** with `Director:PlaySequence()`
- Director says: "Already playing a sequence, queuing not implemented"
- Player gets frozen!

---

## ✅ The Solution: Execute Actions Directly

### How It Works:
```lua
Actions.Choice("Should I go inside?", {
    {
        text = "Yes",
        callback = function()
            // Execute actions directly - we're already in a sequence!
            local dialogue = Actions.Dialogue("Okay...", "Player", 1)
            dialogue()  // Call the action function
            
            local fadeOut = Actions.FadeOut(1)
            fadeOut()
        end
    }
}),
```

**Why it works:**
1. Actions return **functions** (not execute immediately)
2. We call those functions **directly** in the callback
3. No new sequence is started - we're still in Scene 2
4. Everything flows smoothly!

---

## Current Scene 2 Implementation

```lua
Chapter.scene("discovery", "First Discovery", {
    Actions.LockPlayer(),
    Actions.Dialogue("What is this place?", "Player", 2),

    Actions.Choice("Should I go inside?", {
        {
            text = "Yes, let's investigate",
            callback = function()
                // ✅ Execute actions directly
                local dialogue = Actions.Dialogue("No turning back now...", "Player", 1.5)
                dialogue()
                
                local fadeOut = Actions.FadeOut(1)
                fadeOut()
                
                print("[Chapter1] Player chose to go inside")
            end
        },
        {
            text = "No, I should look around more first",
            callback = function()
                // ✅ Execute actions directly
                local dialogue = Actions.Dialogue("Better to be careful.", "Player", 1.5)
                dialogue()
                
                local unlock = Actions.UnlockPlayer()
                unlock()
                
                local objective = Actions.ShowObjective("Search for clues outside")
                objective()
                
                print("[Chapter1] Player chose to explore more")
            end
        }
    }),
    
    Actions.Log("Scene 2 complete"),
}),
```

---

## Pattern: Actions in Choice Callbacks

### Single Action:
```lua
callback = function()
    local action = Actions.Dialogue("Hello!", "Player", 1)
    action()  // Execute it
end
```

### Multiple Actions:
```lua
callback = function()
    // Create all actions
    local dialogue1 = Actions.Dialogue("First...", "Player", 1)
    local dialogue2 = Actions.Dialogue("Then...", "Player", 1)
    local unlock = Actions.UnlockPlayer()
    
    // Execute them in order
    dialogue1()
    dialogue2()
    unlock()
end
```

### With Scene Transition:
```lua
callback = function()
    // Execute some actions
    local dialogue = Actions.Dialogue("Here we go!", "Player", 1)
    dialogue()
    
    local fadeOut = Actions.FadeOut(1)
    fadeOut()
    
    // Then trigger next scene (after current scene ends)
    task.spawn(function()
        task.wait(0.1)  // Let current scene finish
        local nextScene = Chapter.getScene("chapter1", "revelation")
        if nextScene then
            Director:PlaySequence(nextScene.actions, "Chapter1/revelation")
        end
    end)
end
```

---

## When to Use Each Approach

### Use Direct Execution (in callbacks):
```lua
// ✅ Inside Choice callbacks
Actions.Choice("Question?", {
    {
        text = "Answer",
        callback = function()
            local action = Actions.Dialogue("Response", "Player", 1)
            action()  // Direct execution
        end
    }
}),
```

### Use Director:PlaySequence (for new scenes):
```lua
// ✅ For starting new scenes (from listeners)
Actions.ListenForPrompt(prompt, function()
    task.wait(0.1)
    Director:PlaySequence(nextScene.actions, "SceneName")
end),
```

---

## Complete Flow Example

```lua
-- Scene 2
Chapter.scene("discovery", "First Discovery", {
    Actions.LockPlayer(),
    Actions.Dialogue("You found a locked door.", nil, 2),
    
    Actions.Choice("What do you do?", {
        {
            text = "Try to open it",
            callback = function()
                // Execute actions directly
                local shake = Actions.ScreenShake(0.2, 0.5)
                shake()
                
                local dialogue = Actions.Dialogue("It's locked tight.", nil, 1.5)
                dialogue()
                
                local unlock = Actions.UnlockPlayer()
                unlock()
                
                local objective = Actions.ShowObjective("Find the key")
                objective()
            end
        },
        {
            text = "Look for another way",
            callback = function()
                local dialogue = Actions.Dialogue("Maybe there's a window...", "Player", 1.5)
                dialogue()
                
                local fadeOut = Actions.FadeOut(1)
                fadeOut()
                
                // Trigger next scene
                task.spawn(function()
                    task.wait(0.1)
                    local scene3 = Chapter.getScene("chapter1", "alternate_path")
                    if scene3 then
                        Director:PlaySequence(scene3.actions, "Chapter1/alternate_path")
                    end
                end)
            end
        }
    }),
    
    // Scene continues after choice...
    Actions.Log("Scene 2 complete"),
}),
```

---

## Troubleshooting

### Player freezes after choice?
✅ **Don't use `Director:PlaySequence()` in callbacks**
✅ **Execute actions directly instead**

### Need to transition to new scene after choice?
```lua
callback = function()
    // Execute immediate actions
    local fadeOut = Actions.FadeOut(1)
    fadeOut()
    
    // Then spawn new scene
    task.spawn(function()
        task.wait(0.1)
        Director:PlaySequence(nextScene.actions, "NextScene")
    end)
end
```

### Need multiple actions in sequence?
```lua
callback = function()
    // Just call them one after another!
    Actions.Dialogue("First", "Player", 1)()
    Actions.Wait(0.5)()
    Actions.Dialogue("Second", "Player", 1)()
    Actions.UnlockPlayer()()
end
```

Or more readable:
```lua
callback = function()
    local d1 = Actions.Dialogue("First", "Player", 1)
    d1()
    
    local wait = Actions.Wait(0.5)
    wait()
    
    local d2 = Actions.Dialogue("Second", "Player", 1)
    d2()
    
    local unlock = Actions.UnlockPlayer()
    unlock()
end
```

---

## Quick Reference

| Scenario | Pattern |
|----------|---------|
| **Single action in choice** | `local a = Actions.X(); a()` |
| **Multiple actions in choice** | Create all, then call in order |
| **Transition to new scene** | Use `task.spawn()` + `task.wait(0.1)` |
| **Continue current scene** | Just execute actions directly |

---

## Summary

**The Golden Rule for Choice Callbacks:**
- ✅ **Execute actions directly** - call the action functions
- ❌ **Don't use `Director:PlaySequence()`** - you're already in a sequence!

**For Scene Transitions:**
- Use `task.spawn()` to start the new scene asynchronously
- Add `task.wait(0.1)` to ensure current scene finishes first

Now your choices should work without freezing! 🎯
