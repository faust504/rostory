--!strict
--[[
    AnimationController.luau
    Manages player animations including first-person driving
    Handles animation state machine and blending
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationController = {
    Name = "AnimationController",
}

-- Internal state
local animator: Animator? = nil
local loadedAnimations: { [string]: AnimationTrack } = {}
local currentAnimation: AnimationTrack? = nil
local isInitialized = false

-- Animation IDs (replace with actual Roblox animation asset IDs)
local ANIMATION_IDS: { [string]: string } = {
    Idle = "rbxassetid://0", -- Replace with actual ID
    Driving = "rbxassetid://0", -- Replace with actual ID
    Walking = "rbxassetid://0", -- Replace with actual ID
}

-- Player reference
local LocalPlayer = Players.LocalPlayer

--[[
    Initialize the AnimationController
]]
function AnimationController:Initialize(): ()
    if isInitialized then
        return
    end

    isInitialized = true
end

--[[
    Start the AnimationController
]]
function AnimationController:Start(): ()
    -- Wait for character and setup animator
    self:SetupAnimator()

    -- Re-setup on respawn
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.1) -- Small delay for character to fully load
        self:SetupAnimator()
    end)
end

--[[
    Setup the animator from the character
]]
function AnimationController:SetupAnimator(): ()
    local character = LocalPlayer.Character
    if not character then
        return
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end

    animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    -- Preload animations
    self:PreloadAnimations()

    print("[AnimationController] Animator setup complete")
end

--[[
    Preload all animations
]]
function AnimationController:PreloadAnimations(): ()
    if not animator then
        return
    end

    for name, assetId in ANIMATION_IDS do
        if assetId ~= "rbxassetid://0" then
            local animation = Instance.new("Animation")
            animation.AnimationId = assetId

            local track = animator:LoadAnimation(animation)
            loadedAnimations[name] = track
            print(`[AnimationController] Loaded animation: {name}`)
        end
    end
end

--[[
    Play an animation by name
]]
function AnimationController:PlayAnimation(name: string, fadeTime: number?, weight: number?, speed: number?): AnimationTrack?
    local track = loadedAnimations[name]
    if not track then
        warn(`[AnimationController] Animation not found: {name}`)
        return nil
    end

    -- Stop current animation
    if currentAnimation and currentAnimation ~= track then
        currentAnimation:Stop(fadeTime or 0.2)
    end

    -- Play new animation
    track:Play(fadeTime or 0.2, weight or 1, speed or 1)
    currentAnimation = track

    return track
end

--[[
    Stop the current animation
]]
function AnimationController:StopCurrentAnimation(fadeTime: number?): ()
    if currentAnimation then
        currentAnimation:Stop(fadeTime or 0.2)
        currentAnimation = nil
    end
end

--[[
    Stop a specific animation by name
]]
function AnimationController:StopAnimation(name: string, fadeTime: number?): ()
    local track = loadedAnimations[name]
    if track then
        track:Stop(fadeTime or 0.2)
        if currentAnimation == track then
            currentAnimation = nil
        end
    end
end

--[[
    Play driving animation (first-person car)
]]
function AnimationController:StartDriving(): ()
    self:PlayAnimation("Driving", 0.3, 1, 1)
    print("[AnimationController] Started driving animation")
end

--[[
    Stop driving animation
]]
function AnimationController:StopDriving(): ()
    self:StopAnimation("Driving", 0.3)
    print("[AnimationController] Stopped driving animation")
end

--[[
    Set animation speed
]]
function AnimationController:SetAnimationSpeed(name: string, speed: number): ()
    local track = loadedAnimations[name]
    if track then
        track:AdjustSpeed(speed)
    end
end

--[[
    Check if an animation is playing
]]
function AnimationController:IsPlaying(name: string): boolean
    local track = loadedAnimations[name]
    if track then
        return track.IsPlaying
    end
    return false
end

--[[
    Get a loaded animation track
]]
function AnimationController:GetTrack(name: string): AnimationTrack?
    return loadedAnimations[name]
end

--[[
    Load a custom animation at runtime
]]
function AnimationController:LoadAnimation(name: string, assetId: string): AnimationTrack?
    if not animator then
        return nil
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = assetId

    local track = animator:LoadAnimation(animation)
    loadedAnimations[name] = track

    return track
end

return AnimationController
