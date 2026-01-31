--!strict
--[[
    CinematicAction.luau
    TweenService-based cinematic system for scripted sequences
    Supports camera movements, object animations, and chained actions
]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CinematicAction = {}

export type ActionResult = {
    success: boolean,
    message: string?,
}

export type CinematicConfig = {
    duration: number,
    easingStyle: Enum.EasingStyle?,
    easingDirection: Enum.EasingDirection?,
    delay: number?,
}

-- Default configuration
local DEFAULT_CONFIG: CinematicConfig = {
    duration = 1,
    easingStyle = Enum.EasingStyle.Quad,
    easingDirection = Enum.EasingDirection.InOut,
    delay = 0,
}

--[[
    Merge config with defaults
]]
local function mergeConfig(config: CinematicConfig?): CinematicConfig
    if not config then
        return DEFAULT_CONFIG
    end

    return {
        duration = config.duration or DEFAULT_CONFIG.duration,
        easingStyle = config.easingStyle or DEFAULT_CONFIG.easingStyle,
        easingDirection = config.easingDirection or DEFAULT_CONFIG.easingDirection,
        delay = config.delay or DEFAULT_CONFIG.delay,
    }
end

--[[
    Create a TweenInfo from config
]]
local function createTweenInfo(config: CinematicConfig): TweenInfo
    return TweenInfo.new(
        config.duration,
        config.easingStyle or Enum.EasingStyle.Quad,
        config.easingDirection or Enum.EasingDirection.InOut,
        0, -- Repeat count
        false, -- Reverses
        config.delay or 0
    )
end

--[[
    Move camera to a target CFrame
]]
function CinematicAction.MoveCamera(targetCFrame: CFrame, config: CinematicConfig?): ActionResult
    local camera = Workspace.CurrentCamera
    if not camera then
        return { success = false, message = "No camera found" }
    end

    local cfg = mergeConfig(config)
    camera.CameraType = Enum.CameraType.Scriptable

    local tweenInfo = createTweenInfo(cfg)
    local tween = TweenService:Create(camera, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()

    return { success = true }
end

--[[
    Look at a target position from current camera position
]]
function CinematicAction.LookAt(targetPosition: Vector3, config: CinematicConfig?): ActionResult
    local camera = Workspace.CurrentCamera
    if not camera then
        return { success = false, message = "No camera found" }
    end

    local currentPos = camera.CFrame.Position
    local targetCFrame = CFrame.lookAt(currentPos, targetPosition)

    return CinematicAction.MoveCamera(targetCFrame, config)
end

--[[
    Move an object/part to a target CFrame
]]
function CinematicAction.MoveObject(object: BasePart | Model, targetCFrame: CFrame, config: CinematicConfig?): ActionResult
    local cfg = mergeConfig(config)
    local tweenInfo = createTweenInfo(cfg)

    if object:IsA("Model") then
        local primaryPart = object.PrimaryPart
        if not primaryPart then
            return { success = false, message = "Model has no PrimaryPart" }
        end

        -- For models, we need to tween the PrimaryPart and use PivotTo
        local startCFrame = object:GetPivot()
        local startTime = tick()

        while tick() - startTime < cfg.duration do
            local alpha = (tick() - startTime) / cfg.duration
            -- Apply easing (simplified quad easing)
            alpha = alpha * alpha
            local currentCFrame = startCFrame:Lerp(targetCFrame, alpha)
            object:PivotTo(currentCFrame)
            task.wait()
        end

        object:PivotTo(targetCFrame)
    else
        local tween = TweenService:Create(object :: BasePart, tweenInfo, { CFrame = targetCFrame })
        tween:Play()
        tween.Completed:Wait()
    end

    return { success = true }
end

--[[
    Car driving intro sequence - camera looks at road, car drives from behind camera to focal point
]]
function CinematicAction.CarDriveIntro(
    car: Model,
    startPosition: CFrame,
    endPosition: CFrame,
    cameraPosition: CFrame,
    config: CinematicConfig?
): ActionResult
    local camera = Workspace.CurrentCamera
    if not camera then
        return { success = false, message = "No camera found" }
    end

    if not car.PrimaryPart then
        return { success = false, message = "Car model needs a PrimaryPart" }
    end

    local cfg = mergeConfig(config)

    -- Setup camera to look at the road
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = cameraPosition

    -- Position car behind camera at start
    car:PivotTo(startPosition)

    -- Animate car driving forward
    local tweenInfo = TweenInfo.new(
        cfg.duration,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.Out
    )

    local startCFrame = startPosition
    local endCFrame = endPosition
    local startTime = tick()

    while tick() - startTime < cfg.duration do
        local alpha = (tick() - startTime) / cfg.duration
        -- Smooth easing
        alpha = 1 - math.pow(1 - alpha, 3)
        local currentCFrame = startCFrame:Lerp(endCFrame, alpha)
        car:PivotTo(currentCFrame)
        task.wait()
    end

    car:PivotTo(endCFrame)

    return { success = true }
end

--[[
    Pan camera along a path defined by waypoints
]]
function CinematicAction.CameraPan(waypoints: { CFrame }, config: CinematicConfig?): ActionResult
    local camera = Workspace.CurrentCamera
    if not camera then
        return { success = false, message = "No camera found" }
    end

    local cfg = mergeConfig(config)
    camera.CameraType = Enum.CameraType.Scriptable

    local durationPerWaypoint = cfg.duration / #waypoints

    for _, waypointCFrame in waypoints do
        local tweenInfo = TweenInfo.new(
            durationPerWaypoint,
            cfg.easingStyle or Enum.EasingStyle.Sine,
            cfg.easingDirection or Enum.EasingDirection.InOut
        )
        local tween = TweenService:Create(camera, tweenInfo, { CFrame = waypointCFrame })
        tween:Play()
        tween.Completed:Wait()
    end

    return { success = true }
end

--[[
    Shake camera effect
]]
function CinematicAction.CameraShake(intensity: number, duration: number): ActionResult
    local camera = Workspace.CurrentCamera
    if not camera then
        return { success = false, message = "No camera found" }
    end

    local originalCFrame = camera.CFrame
    local startTime = tick()

    while tick() - startTime < duration do
        local elapsed = tick() - startTime
        local decay = 1 - (elapsed / duration)
        local offset = Vector3.new(
            math.random() * 2 - 1,
            math.random() * 2 - 1,
            math.random() * 2 - 1
        ) * intensity * decay

        camera.CFrame = originalCFrame * CFrame.new(offset)
        task.wait()
    end

    camera.CFrame = originalCFrame
    return { success = true }
end

--[[
    Dolly zoom effect (Hitchcock zoom)
]]
function CinematicAction.DollyZoom(
    targetPosition: Vector3,
    startFOV: number,
    endFOV: number,
    config: CinematicConfig?
): ActionResult
    local camera = Workspace.CurrentCamera
    if not camera then
        return { success = false, message = "No camera found" }
    end

    local cfg = mergeConfig(config)
    camera.CameraType = Enum.CameraType.Scriptable

    local startPosition = camera.CFrame.Position
    local startTime = tick()

    -- Calculate distance changes to maintain subject size
    local startDistance = (startPosition - targetPosition).Magnitude
    local fovRatio = math.tan(math.rad(startFOV / 2)) / math.tan(math.rad(endFOV / 2))
    local endDistance = startDistance * fovRatio

    while tick() - startTime < cfg.duration do
        local alpha = (tick() - startTime) / cfg.duration
        alpha = alpha * alpha -- Quad easing

        local currentFOV = startFOV + (endFOV - startFOV) * alpha
        local currentDistance = startDistance + (endDistance - startDistance) * alpha

        local direction = (startPosition - targetPosition).Unit
        local newPosition = targetPosition + direction * currentDistance

        camera.FieldOfView = currentFOV
        camera.CFrame = CFrame.lookAt(newPosition, targetPosition)
        task.wait()
    end

    camera.FieldOfView = endFOV
    return { success = true }
end

--[[
    Fade object transparency
]]
function CinematicAction.FadeObject(object: BasePart, targetTransparency: number, config: CinematicConfig?): ActionResult
    local cfg = mergeConfig(config)
    local tweenInfo = createTweenInfo(cfg)

    local tween = TweenService:Create(object, tweenInfo, { Transparency = targetTransparency })
    tween:Play()
    tween.Completed:Wait()

    return { success = true }
end

return CinematicAction
