--!strict
--[[
    Chapter1_Intro.luau
    Chapter 1: The Accident
    
    A driving cutscene where the player receives devastating news
    and crashes their car.
]]

local Workspace = game:GetService("Workspace")

-- Get Director and Actions using relative paths
local Story = script.Parent.Parent
local Director = require(Story:WaitForChild("Director"))
local Chapter = require(Story:WaitForChild("Chapter"))
local Actions = Director.Actions

-- ============================================
-- WORKSPACE REFERENCES
-- ============================================

-- Cutscene Rig (the animated character)
local cutsceneRig = Workspace:WaitForChild("CutsceneRig")  -- Your animated R6 rig
local rigHead = cutsceneRig:WaitForChild("Head")

--[[
    Helper function to start this chapter
]]
local function StartChapter1()
    local scene = Chapter.getScene("chapter1", "driving_cutscene")
    if scene then
        Director:PlaySequence(scene.actions, `Chapter1/{scene.id}`)
    end
end

--[[
    Helper function to play a specific scene
]]
local function PlayScene(sceneId: string)
    local scene = Chapter.getScene("chapter1", sceneId)
    if scene then
        Director:PlaySequence(scene.actions, `Chapter1/{scene.id}`)
    else
        warn(`[Chapter1] Scene not found: {sceneId}`)
    end
end

-- Car model (Model with PrimaryPart set!)
local carModel = Workspace:WaitForChild("Sedan")
local hull = carModel:WaitForChild("hull")
local carSeat = carModel:WaitForChild("DriveSeat")  -- Where rig sits

-- Car path waypoints (invisible parts for car to tween between)
local carWaypoints = Workspace:WaitForChild("CarWaypoints")
local waypoint1 = carWaypoints:WaitForChild("Waypoint1")  -- Start position
local waypoint1point5 = carWaypoints:WaitForChild("Waypoint1point5")  -- Start position
local waypoint2 = carWaypoints:WaitForChild("Waypoint2")  -- Normal driving
local waypoint3 = carWaypoints:WaitForChild("Waypoint3")  -- Crash position (near lamp post)

-- Exit/Spawn position after crash
local crashExitPoint = Workspace:WaitForChild("CrashExitPoint")
local scene2Trigger = Workspace:WaitForChild("chapter1scene2part")

-- ============================================
-- AUDIO ASSET IDs
-- Replace these with your actual asset IDs!
-- ============================================

local AUDIO = {
    -- Looping sounds
    CAR_ENGINE = "rbxassetid://5830439961", -- "rbxassetid://98076378627817" (second option)           Car engine loop
    RADIO_STATIC = "rbxassetid://372770465",         -- Radio static/changing
    RADIO_MUSIC_1 = "rbxassetid://1837748907",        -- Radio station 1
    RADIO_MUSIC_2 = "rbxassetid://102484277510318",        -- Radio station 2
    
    -- One-shot sounds
    PHONE_NOTIFICATION = "rbxassetid://73722479618078",   -- Phone buzz
    CAR_CRASH = "rbxassetid://119917536605552",            -- Crash impact
    GLASS_SHATTER = "rbxassetid://9103909576",        -- Windshield breaking
    TIRES_SCREECH = "rbxassetid://73429750798250",        -- Tire screech before crash
    EARS_RINGING = "rbxassetid://9069161602",         -- Ears ringing after crash
    HEARTBEAT = "rbxassetid://161024765",            -- Heartbeat during panic
    
    -- Voicelines (your voice acting!)
    VO_SIGH = "rbxassetid://128374011323781",              -- *sigh*
    VO_HUMMING = "rbxassetid://0",           -- Humming to music
    VO_PHONE_REACTION = "rbxassetid://0",    -- "Huh? What's this..."
    VO_PANIC_1 = "rbxassetid://0",           -- "No... no no no..."
    VO_PANIC_2 = "rbxassetid://0",           -- "I need to get there!"
    VO_GASP = "rbxassetid://0",              -- *gasp* seeing girl
    VO_SCREAM = "rbxassetid://0",            -- Scream during crash
    VO_GROAN = "rbxassetid://0",             -- Groan after crash
}

-- ============================================
-- ANIMATION IDs
-- Replace these with your actual animations!
-- ============================================

local ANIMS = {
    DRIVING_RELAXED = "rbxassetid://0",      -- Relaxed driving, changing radio
    LOOKING_AT_PHONE = "rbxassetid://0",     -- Looking down at phone
    PANIC_DRIVING = "rbxassetid://0",        -- Panicked, distracted
    CRASH_REACTION = "rbxassetid://0",       -- Seeing girl, slamming wheel
}

--[[\
    Chapter 1: The Accident
    Opens with the player driving, receiving bad news, and crashing
]]

local Chapter1 = Chapter.new({
    id = "chapter1",
    name = "Chapter 1: The Accident",
    startScene = "driving_cutscene",
    scenes = {
        
        -- ============================================
        -- SCENE 1: THE DRIVE (Main Cutscene)
        -- ============================================
        Chapter.scene("driving_cutscene", "The Drive", {
            
            -- === INITIAL SETUP ===
            Actions.FadeOut(0),  -- Start black
            Actions.LockPlayer(),
            Actions.HideCharacter(),  -- Hide player (we'll use rig)
            Actions.Log("Starting Chapter 1: The Accident"),
            
            -- Position car hull at start waypoint (ensure it's anchored first!)
            Actions.Call(function()
                print("[Chapter1] Positioning hull at waypoint1")
                hull.Anchored = true
                task.wait(0.1)
                hull.CFrame = waypoint1.CFrame
                print(`[Chapter1] Hull positioned at {hull.CFrame}`)
            end),
            
            Actions.Wait(0.1),
            
            -- Weld the cutscene rig to the car seat
            Actions.WeldRigToSeat(cutsceneRig, carSeat),
            
            -- === START CAMERA FOLLOWING RIG'S HEAD ===
            Actions.FollowPart(rigHead),
            
            -- === START LOOPING AUDIO ===
            Actions.PlayLoopingSound(AUDIO.CAR_ENGINE, "CarEngine", 0.4),
            Actions.PlayLoopingSound(AUDIO.RADIO_MUSIC_1, "RadioMusic", 0.15),
            
            -- ========================================
            -- START CAR MOVING BEFORE FADE-IN!
            -- Car moves continuously in the background
            -- Duration = how long to reach each waypoint
            -- Speed auto-adjusts based on distance!
            -- ========================================
            Actions.StartBackgroundTween(hull, {
                { target = waypoint1point5, duration = 9},
                { target = waypoint2, duration = 16.69 },  -- 20 seconds of relaxed driving
                { target = waypoint3, duration = 0.65 }, -- 1.5 seconds crash swerve (fast!)
            }),
            
            -- === FADE IN - CUTSCENE BEGINS ===
            -- (Car is already moving!)
            Actions.FadeIn(2),
            
            -- === PART 1: RELAXED DRIVING ===
            -- Driving animation plays while car moves in background
            Actions.PlayCutsceneAnimation(ANIMS.DRIVING_RELAXED),
            
            -- Voiceline: *sigh*
            Actions.PlaySound(AUDIO.VO_SIGH, 1),
            Actions.Wait(1),
            
            -- Change radio station
            Actions.StopLoopingSound("RadioMusic", 0.3),
            Actions.PlaySound(AUDIO.RADIO_STATIC, 0.7),
            Actions.Wait(0.3),
            Actions.StopSound(AUDIO.RADIO_STATIC, 0),
            Actions.PlayLoopingSound(AUDIO.RADIO_MUSIC_2, "RadioMusic", 0.15),
            
            -- Voiceline: humming
            Actions.PlaySound(AUDIO.VO_HUMMING, 0.6),
            Actions.Wait(2),
            
            -- === PART 2: PHONE NOTIFICATION ===
            Actions.PlaySound(AUDIO.PHONE_NOTIFICATION, 0.8),
            Actions.Wait(0.5),
            
            -- Voiceline: "Huh?"
            Actions.PlaySound(AUDIO.VO_PHONE_REACTION, 1),
            
            -- Play looking at phone animation
            Actions.PlayCutsceneAnimation(ANIMS.LOOKING_AT_PHONE),
            
            -- Dialogue: Reading the message
            Actions.Dialogue("Dad?", 1.5, Color3.fromRGB(230, 230, 230)),
            Actions.Wait(0.5),
            Actions.Dialogue("\"Your mom just had another stroke.\"", 2.5, Color3.fromRGB(255, 200, 200)),
            Actions.Dialogue("\"Come to the hospital ASAP.\"", 2, Color3.fromRGB(255, 200, 200)),
            
            -- === PART 3: PANIC ===
            Actions.StopLoopingSound("RadioMusic", 0.5),
            
            -- Voiceline: panic
            Actions.PlaySound(AUDIO.VO_PANIC_1, 1),
            Actions.Dialogue("No... no no no...", 2, Color3.fromRGB(230, 230, 230)),
            
            -- Panic visuals (blur + heartbeat)
            Actions.ParallelActions({
                Actions.SetBlur(10, 2),
                Actions.PlayLoopingSound(AUDIO.HEARTBEAT, "Heartbeat", 0.4),
                Actions.ScreenShake(0.2, 0.5),
            }),
            
            Actions.PlaySound(AUDIO.VO_PANIC_2, 1),
            Actions.Dialogue("I need to get there. Now.", 2, Color3.fromRGB(230, 230, 230)),
            
            -- Panic driving animation (car is still moving in background)
            Actions.ParallelActions({
                Actions.PlayCutsceneAnimation(ANIMS.PANIC_DRIVING),
                Actions.ScreenShake(0.1, 3),
            }),
            
            -- === PART 4: THE CRASH ===
            -- By now the background tween should be reaching waypoint3 (crash point)
            
            -- *GASP*
            Actions.PlaySound(AUDIO.VO_GASP, 1),
            Actions.Wait(0.2),
            
            -- Dialogue: Seeing the girl
            Actions.ParallelActions({
                Actions.Dialogue("WATCH OUT!", 0.8, Color3.fromRGB(158, 38, 38), Enum.Font.SpecialElite, 40),
                Actions.Wait(3),
                
            }),
            
            -- Tire screech + crash animation
            Actions.PlaySound(AUDIO.CAR_CRASH, 2),
            Actions.ParallelActions({
                Actions.PlayCutsceneAnimation(ANIMS.CRASH_REACTION),
                Actions.ScreenShake(1.2, 1.5),
                Actions.SetBlur(20, 0.2), -- Immediate heavy blur on impact
                Actions.PlaySound(AUDIO.EARS_RINGING, 0.2), -- Ringing starts early but quiet
            }),
            
            -- === IMPACT ===
            Actions.Wait(1),
            Actions.FadeToColor(Color3.new(1, 1, 1), 0.5),
            Actions.ScreenShake(1.5, 0.5),
            Actions.FadeOut(0.3),
            Actions.FadeToColor(Color3.new(0, 0, 0), 0.5),
            
            -- Scream 
            Actions.PlaySound(AUDIO.VO_SCREAM, 1),
            
            -- === FADE TO BLACK ===
            Actions.FadeOut(0.5),
            Actions.StopLoopingSound("CarEngine", 1),  -- Engine dies
            Actions.StopLoopingSound("Heartbeat", 1),  -- Heartbeat fades
            Actions.StopFollowing(),  -- Stop camera following
            Actions.UnweldRigFromSeat(cutsceneRig),  -- Unweld rig from seat
            
            -- === CONCUSION / BLACKOUT ===
            Actions.Call(function() print("[Chapter1] Player is unconscious") end),
            Actions.Wait(3),  -- Total silence for a moment
            
            -- === EARS RINGING ===
            Actions.PlaySound(AUDIO.EARS_RINGING, 1),
            Actions.Wait(1),
            
            -- === CINEMATIC WAKE UP (Blinking) ===
            -- Set initial dazed state
            Actions.SetBlur(15, 0),
            Actions.CameraTilt(10, 0), -- Tilted head
            
            -- Blink 1: Quick glance at wreckage
            Actions.Blink(0.2),
            Actions.Wait(0.8),
            
            -- Blink 2: See smoke/detail
            Actions.Blink(0.5),
            Actions.Wait(0.5),
            
            -- Blink 3: Groan and stay awake
            Actions.PlaySound(AUDIO.VO_GROAN, 0.8),
            Actions.ParallelActions({
                Actions.FadeIn(4),
                Actions.SetBlur(0, 5), -- Vision clears slowly
                Actions.CameraTilt(-10, 3), -- Wrighting the head
                Actions.StopSound(AUDIO.EARS_RINGING, 4), -- Ringing fades out as vision clears
            }),
            
            -- Teleport player to crash site
            Actions.TeleportPlayer(crashExitPoint.CFrame),
            
            -- Show player again
            Actions.ShowCharacter(),
            
            -- Camera snap to crash site part
            Actions.Call(function()
				local camera = workspace.CurrentCamera
				-- This snaps the camera to the part's orientation
				camera.CFrame = crashExitPoint.CFrame
			end),
            
            -- Reset camera
            Actions.ResetCamera(),

            -- Fade back in slowly
            Actions.FadeIn(2),
            
            -- Unlock player
            Actions.UnlockPlayer(),
            
            -- Dialogue: Dazed
            Actions.Dialogue("...", 1.5, Color3.fromRGB(200, 200, 200)),
            Actions.Dialogue("What... what happened?", 2, Color3.fromRGB(220, 220, 220)),
            
            -- Give objective
            Actions.ShowObjective("Look around"),
            
            Actions.Log("Driving cutscene complete - Player is now at crash site"),
            
            -- Wait for player to approach the wreckage/specific area to trigger Scene 2
            Actions.WaitForProximity(scene2Trigger, 12),
            
            -- Transition to Scene 2 (Aftermath)
            Actions.Call(function()
                task.defer(function()
                    PlayScene("aftermath")
                end)
            end),
        }),
        
        -- ============================================
        -- SCENE 2: AFTERMATH (After player looks around)
        -- ============================================
        Chapter.scene("aftermath", "Aftermath", {
            Actions.LockPlayer(),
            
            Actions.Dialogue("The car... it's totaled.", 2),
            Actions.Dialogue("Mom...", 1.5),
            Actions.Dialogue("I need to find a phone. Call for help.", 2.5),
            
            Actions.UnlockPlayer(),
            Actions.ShowObjective("Find a way to contact help"),
            
            Actions.Log("Scene 2: Aftermath complete"),
        }),
    },
})

-- Export functions for external use
return {
    Chapter = Chapter1,
    Start = StartChapter1,
    PlayScene = PlayScene,
}
