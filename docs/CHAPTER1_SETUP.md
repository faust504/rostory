# Chapter 1 Setup Guide 🚗💥

## Overview

This guide explains how to set up the Workspace objects needed for the Chapter 1 driving cutscene.

---

## Required Workspace Structure

Create this hierarchy in **Workspace**:

```
Workspace
├── CutsceneRig (Model) - Your animated R6 character
│   ├── Head
│   ├── Torso
│   ├── Left Arm, Right Arm
│   ├── Left Leg, Right Leg
│   └── HumanoidRootPart
│
├── PlayerCar (Model) - The car
│   ├── Body (Part)
│   ├── Wheels (Parts)
│   ├── DriverSeat (Part) - Where rig sits
│   └── [Set PrimaryPart = Body!]
│
├── CarWaypoints (Folder) - Invisible path markers
│   ├── Waypoint1 (Part) - Start position
│   ├── Waypoint2 (Part) - During normal driving
│   └── Waypoint3 (Part) - Crash position near lamp post
│
├── LampPost (Model) - What the car crashes into
│
└── CrashExitPoint (Part) - Where player spawns after crash
```

---

## Step-by-Step Setup

### 1. Create the Cutscene Rig

1. **Insert** → **Rig Builder** → **R6** (or R15)
2. **Rename** to `CutsceneRig`
3. **Position** inside the car's driver seat
4. **Optional**: Add Shirt, Pants to match player appearance

**Important**: This rig will be animated! The camera will follow its Head.

---

### 2. Create the Car Model

1. Build or import your car model
2. Make sure it's a **Model** container
3. **Set PrimaryPart**:
   - Select the car Model
   - In Properties → **PrimaryPart** → Select the main body part
   - This is REQUIRED for `TweenModel` to work!

4. Create a **DriverSeat** Part:
   - Position it where the driver sits
   - The rig should be positioned here
   - **Anchor it** (Anchored = true)

5. Make car CanCollide = false (optional, prevents physics issues)

---

### 3. Create Car Waypoints

Create a **Folder** called `CarWaypoints` with 3 **Parts**:

| Part Name | Purpose | Position |
|-----------|---------|----------|
| `Waypoint1` | Starting position | Where cutscene begins |
| `Waypoint2` | Normal driving | Further down the road |
| `Waypoint3` | Crash position | Next to lamp post |

**Settings for each waypoint:**
- Transparency = 1 (invisible)
- CanCollide = false
- Anchored = true

**The car will tween between these positions!**

---

### 4. Create Crash Exit Point

1. Create a **Part** called `CrashExitPoint`
2. Position it near the crashed car (where player wakes up)
3. Set Transparency = 1, CanCollide = false, Anchored = true

---

### 5. Create Your Animations

Open **Animation Editor** and create these animations on your rig:

| Animation | Description |
|-----------|-------------|
| `DRIVING_RELAXED` | Hands on wheel, looking forward, changing radio |
| `LOOKING_AT_PHONE` | Head looks down at phone in hand |
| `PANIC_DRIVING` | Frantic movements, looking around, stressed |
| `CRASH_REACTION` | Sees girl, yanks wheel, braces for impact |

**Animation Tips:**
- Animate the **Head** for first-person camera movement!
- When head looks down, camera will look down
- When head turns, camera will turn
- Add subtle movements (breathing, fidgeting) for realism

---

### 6. Upload Audio

Upload your audio files and get the asset IDs:

| Audio | Description |
|-------|-------------|
| Car engine | Looping engine sound |
| Radio music (2) | Two radio stations |
| Radio static | Changing stations sound |
| Phone notification | Buzz/ding |
| Tire screech | Before crash |
| Car crash | Impact sound |
| Glass shatter | Windshield |
| Ears ringing | After crash |
| Voice lines | Your voice acting! |

---

### 7. Update the Script

In `Chapter1_Intro.luau`, replace the placeholder IDs:

```lua
local AUDIO = {
    CAR_ENGINE = "rbxassetid://YOUR_ID_HERE",
    RADIO_MUSIC_1 = "rbxassetid://YOUR_ID_HERE",
    -- etc...
}

local ANIMS = {
    DRIVING_RELAXED = "rbxassetid://YOUR_ID_HERE",
    LOOKING_AT_PHONE = "rbxassetid://YOUR_ID_HERE",
    -- etc...
}
```

---

## How The Cutscene Works

### Flow:

```
1. Screen fades from black
2. Camera locks to rig's Head (first-person view)
3. Car engine starts (looping)
4. Radio music plays (looping)
5. Car tweens from Waypoint1 → Waypoint2 (8 seconds)
6. Player changes radio station
7. Phone buzzes
8. Head looks down at phone (animation)
9. Dialogue: reads message about mom
10. Player panics, radio fades out
11. Screen shakes subtly
12. More panicked dialogue
13. Player sees little girl
14. Tires screech, car swerves to Waypoint3
15. CRASH! Flash, shake, sounds
16. Fade to black + ears ringing (3 seconds)
17. Fade back in at CrashExitPoint
18. Player unlocked, objective given
```

---

## Timeline Visualization

```
0s          5s          10s         15s         20s         25s         30s
|-----------|-----------|-----------|-----------|-----------|-----------|
[  CAR ENGINE LOOP  ------------------------------------------>]
[  RADIO 1  ---->][static][  RADIO 2  -------->]
                                        ^phone buzz
                            [LOOKING AT PHONE ANIM]
                                  [panicked dialogue]
                                              [SCREECH]
                                                  [CRASH!]
                                                     [BLACK + RINGING]
                                                             [WAKE UP]
```

---

## Testing Tips

1. **Press P** to skip through the cutscene quickly
2. Test each part separately first
3. Start with placeholder audio, add real ones later
4. Use print statements to debug timing

---

## Troubleshooting

### Car not moving?
- Check that `PlayerCar.PrimaryPart` is set!
- Make sure waypoint Parts exist

### Camera not following head?
- Check that `CutsceneRig.Head` exists
- Make sure you're using `FollowPart(rigHead)`

### Animation not playing?
- Check animation ID is correct
- Verify animation is published
- Ensure animation matches rig type (R6/R15)

### Audio not playing?
- Check that asset IDs are correct
- Verify audio is published and approved
- Audio might need to load, add a small wait

---

## Quick Test Scene

If you want to test without all the assets, use this minimal version:

```lua
Chapter.scene("test_drive", "Test Drive", {
    Actions.LockPlayer(),
    Actions.HideCharacter(),
    Actions.FollowPart(rigHead),
    Actions.FadeIn(1),
    
    -- Just move the car
    Actions.TweenModel(carModel, waypoint2, 5),
    Actions.Dialogue("Driving...", 2),
    
    Actions.StopFollowing(),
    Actions.ShowCharacter(),
    Actions.ResetCamera(),
    Actions.UnlockPlayer(),
})
```

---

## Next Steps

After the crash scene, you can:

1. Add Scene 2: Player explores crash site
2. Add interaction prompts (phone booth, NPC, etc.)
3. Continue the story from there

Good luck with your cutscene! 🎬
