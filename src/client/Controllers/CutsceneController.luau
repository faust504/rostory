--!strict
--[[
    CutsceneController.luau
    Orchestrates cutscenes with camera control and player lock
    Uses TweenService for smooth camera movements
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type CameraShot = Types.CameraShot
type CinematicSequence = Types.CinematicSequence

local CutsceneController = {
    Name = "CutsceneController",
}

-- Internal state
local camera: Camera? = nil
local originalCameraType: Enum.CameraType? = nil
local isPlayingCutscene = false
local currentSequence: CinematicSequence? = nil
local isInitialized = false

-- Player reference
local LocalPlayer = Players.LocalPlayer

--[[
    Initialize the CutsceneController
]]
function CutsceneController:Initialize(): ()
    if isInitialized then
        return
    end

    camera = workspace.CurrentCamera

    isInitialized = true
end

--[[
    Start the CutsceneController
]]
function CutsceneController:Start(): ()
    -- Listen for cutscene events from server
    Remotes.GetEvent("PlayCutscene").OnClientEvent:Connect(function(cutsceneId: string)
        self:PlayCutscene(cutsceneId)
    end)
end

--[[
    Lock player controls during cutscene
]]
function CutsceneController:LockPlayerControls(): ()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
    end

    -- Set camera to scriptable mode
    if camera then
        originalCameraType = camera.CameraType
        camera.CameraType = Enum.CameraType.Scriptable
    end
end

--[[
    Unlock player controls after cutscene
]]
function CutsceneController:UnlockPlayerControls(): ()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
    end

    -- Restore camera type
    if camera and originalCameraType then
        camera.CameraType = originalCameraType
    end
end

--[[
    Move camera to a position over duration
]]
function CutsceneController:MoveCamera(targetCFrame: CFrame, duration: number, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?): ()
    if not camera then
        return
    end

    local style = easingStyle or Enum.EasingStyle.Quad
    local direction = easingDirection or Enum.EasingDirection.InOut

    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(camera, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
end

--[[
    Play a camera shot
]]
function CutsceneController:PlayShot(shot: CameraShot): ()
    self:MoveCamera(
        shot.cframe,
        shot.duration,
        shot.easingStyle,
        shot.easingDirection
    )
end

--[[
    Play a sequence of camera shots
]]
function CutsceneController:PlaySequence(sequence: CinematicSequence): ()
    if isPlayingCutscene then
        warn("[CutsceneController] Already playing a cutscene")
        return
    end

    isPlayingCutscene = true
    currentSequence = sequence

    if sequence.lockPlayerControls then
        self:LockPlayerControls()
    end

    print(`[CutsceneController] Playing sequence: {sequence.id}`)

    -- Play each shot in order
    for i, shot in sequence.shots do
        self:PlayShot(shot)
    end

    if sequence.lockPlayerControls then
        self:UnlockPlayerControls()
    end

    isPlayingCutscene = false
    currentSequence = nil

    -- Fire completion event
    Remotes.GetEvent("CutsceneCompleted"):FireServer(sequence.id)

    print(`[CutsceneController] Completed sequence: {sequence.id}`)
end

--[[
    Play a predefined cutscene by ID
]]
function CutsceneController:PlayCutscene(cutsceneId: string): ()
    -- Cutscene definitions - can be moved to a separate data module
    local cutscenes: { [string]: CinematicSequence } = {
        Intro = {
            id = "Intro",
            shots = {
                {
                    cframe = CFrame.new(0, 10, -50) * CFrame.Angles(0, math.rad(180), 0),
                    duration = 2,
                    easingStyle = Enum.EasingStyle.Quad,
                    easingDirection = Enum.EasingDirection.Out,
                },
                {
                    cframe = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-15), 0, 0),
                    duration = 3,
                    easingStyle = Enum.EasingStyle.Sine,
                    easingDirection = Enum.EasingDirection.InOut,
                },
            },
            lockPlayerControls = true,
        },
    }

    local sequence = cutscenes[cutsceneId]
    if sequence then
        self:PlaySequence(sequence)
    else
        warn(`[CutsceneController] Unknown cutscene: {cutsceneId}`)
    end
end

--[[
    Set camera to a specific CFrame immediately
]]
function CutsceneController:SetCameraPosition(cframe: CFrame): ()
    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = cframe
    end
end

--[[
    Get current camera CFrame
]]
function CutsceneController:GetCameraPosition(): CFrame?
    if camera then
        return camera.CFrame
    end
    return nil
end

--[[
    Check if a cutscene is currently playing
]]
function CutsceneController:IsPlaying(): boolean
    return isPlayingCutscene
end

--[[
    Skip the current cutscene (if skippable)
]]
function CutsceneController:SkipCutscene(): ()
    if isPlayingCutscene then
        -- In a full implementation, we'd cancel tweens and jump to end
        warn("[CutsceneController] Skip not fully implemented")
    end
end

return CutsceneController
