# Main Menu & Cutscene Not Showing - Debug Notes

## Issues Found

### 1. **MainMenu Auto-Initialization Problem**
- `MainMenu:Init()` is called at line 278 when the module is required
- This happens during bootstrap before UIManager is fully ready
- Creates a race condition

### 2. **Missing Character Restoration**
- Character is hidden in `init.client.luau` (line 60)
- Character is never made visible after cutscene starts
- Player remains invisible throughout the game

### 3. **Initialization Order**
- UIManager:Start() tries to show MainMenu (line 60)
- But MainMenu might not be properly registered yet
- Need to ensure proper initialization order

## Fixes Applied

### Fix 1: Remove Auto-Init from MainMenu
- Remove the auto-initialization at line 278
- Let UIManager handle the initialization

### Fix 2: Add Character Visibility Restoration
- Add action to restore character visibility after teleport in Chapter1

### Fix 3: Ensure MainMenu is Loaded
- Explicitly require MainMenu in UIManager before showing it

### Fix 4: Add Debug Logging
- Add more logging to track initialization flow
