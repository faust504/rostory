--!strict
--[[
    Actions.luau
    Chainable story actions library for the Director system
    Each action returns a function that executes the action when called
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actions = {}

export type StoryAction = () -> ()

-- Local player reference
local LocalPlayer = Players.LocalPlayer

-- UI References (lazy loaded)
local fadeFrame: Frame? = nil
local dialogueText: TextLabel? = nil

-- ============================================
-- SKIP SYSTEM (Developer Feature)
-- Press 'P' to skip current dialogue/action
-- ============================================
local UserInputService = game:GetService("UserInputService")
local skipRequested = false

-- Set up skip key listener
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        skipRequested = true
    end
end)

-- Helper: Check if skip was requested and reset flag
local function checkSkip(): boolean
    if skipRequested then
        skipRequested = false
        return true
    end
    return false
end

-- Helper: Wait with skip support (returns true if skipped)
local function waitWithSkip(seconds: number): boolean
    local elapsed = 0
    while elapsed < seconds do
        if checkSkip() then
            return true  -- Was skipped
        end
        task.wait(0.05)
        elapsed += 0.05
    end
    return false  -- Completed normally
end

--[[
    Get or create the fade overlay frame
]]
local function getFadeFrame(): Frame
    if fadeFrame then
        return fadeFrame
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local coreUI = playerGui:FindFirstChild("CoreUI")
    if coreUI then
        fadeFrame = coreUI:FindFirstChild("FadeOverlay") :: Frame
    end

    if not fadeFrame then
        -- Create fallback fade frame
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DirectorUI"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 999
        screenGui.IgnoreGuiInset = true  -- Cover full screen
        screenGui.Parent = playerGui

        fadeFrame = Instance.new("Frame")
        fadeFrame.Name = "FadeOverlay"
        fadeFrame.Size = UDim2.fromScale(1, 1)
        fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        fadeFrame.BackgroundTransparency = 1
        fadeFrame.BorderSizePixel = 0
        fadeFrame.ZIndex = 999
        fadeFrame.Parent = screenGui
    end

    return fadeFrame :: Frame
end

--[[
    Get or create the dialogue UI (clean text-only version)
]]
local function getDialogueUI(): TextLabel
    if dialogueText then
        return dialogueText
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("DirectorUI") :: ScreenGui

    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DirectorUI"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 998
        screenGui.Parent = playerGui
    end

    -- Just the dialogue text - no background, no speaker label
    dialogueText = Instance.new("TextLabel")
    dialogueText.Name = "DialogueText"
    dialogueText.Size = UDim2.new(0.8, 0, 0.3, 0)  -- Wider for centered text
    dialogueText.Position = UDim2.new(0.1, 0, 0.7, 0)  -- Bottom center
    dialogueText.AnchorPoint = Vector2.new(0, 0)
    dialogueText.BackgroundTransparency = 1  -- No background!
    dialogueText.Text = ""
    dialogueText.TextColor3 = Color3.fromRGB(230, 230, 230)  -- Slightly off-white
    dialogueText.TextSize = 32
    dialogueText.Font = Enum.Font.SpecialElite  -- Your requested font!
    dialogueText.TextXAlignment = Enum.TextXAlignment.Center
    dialogueText.TextYAlignment = Enum.TextYAlignment.Top
    dialogueText.TextWrapped = true
    dialogueText.Visible = false
    dialogueText.Parent = screenGui

    -- Text stroke (outline)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)  -- Black outline
    stroke.Thickness = 2
    stroke.Transparency = 0
    stroke.Parent = dialogueText

    return dialogueText :: TextLabel
end

--[[
    Fade the screen to black (skippable with P)
]]
function Actions.FadeOut(duration: number): StoryAction
    return function()
        local frame = getFadeFrame()
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 0 })
        tween:Play()
        
        local skipped = waitWithSkip(duration)
        if skipped then
            tween:Cancel()
            frame.BackgroundTransparency = 0  -- Complete fade immediately
        end
    end
end

--[[
    Fade the screen from black (skippable with P)
]]
function Actions.FadeIn(duration: number): StoryAction
    return function()
        local frame = getFadeFrame()
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 1 })
        tween:Play()
        
        local skipped = waitWithSkip(duration)
        if skipped then
            tween:Cancel()
            frame.BackgroundTransparency = 1  -- Complete fade immediately
        end
    end
end

--[[
    Show dialogue text with customizable font and color
    New signature: Dialogue(text, duration, color, font, textSize)
    
    Press 'P' to skip!
    - During typewriter: instantly shows full text
    - During wait: immediately ends dialogue
    
    Examples:
    Actions.Dialogue("Hello world!", 2)  -- White text, Special Elite, 2 seconds
    Actions.Dialogue("I'm scared...", 2, Color3.fromRGB(200, 200, 255))  -- Light blue
    Actions.Dialogue("DANGER!", 1.5, Color3.fromRGB(255, 100, 100), Enum.Font.GothamBold, 40)  -- Red, bold, large
]]
function Actions.Dialogue(
    text: string, 
    duration: number?,
    color: Color3?,
    font: Enum.Font?,
    textSize: number?
): StoryAction
    return function()
        local textLabel = getDialogueUI()

        -- Apply custom styling
        textLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)  -- Default white
        textLabel.Font = font or Enum.Font.SpecialElite  -- Default Special Elite
        textLabel.TextSize = textSize or 32  -- Default size
        textLabel.Text = ""
        textLabel.Visible = true

        -- Typewriter effect (skippable)
        local skippedTypewriter = false
        for i = 1, #text do
            if checkSkip() then
                -- Skip pressed - show full text immediately
                textLabel.Text = text
                skippedTypewriter = true
                break
            end
            textLabel.Text = string.sub(text, 1, i)
            task.wait(0.03)
        end

        -- Wait for duration (skippable)
        if not skippedTypewriter then
            -- If typewriter completed normally, wait for duration
            if waitWithSkip(duration or 2) then
                -- Skipped during wait
            end
        else
            -- If typewriter was skipped, give brief moment to read then wait
            if waitWithSkip(0.3) then
                -- Skipped again, continue immediately
            end
        end

        -- Hide dialogue
        textLabel.Visible = false
    end
end

--[[
    Teleport player to a position
]]
function Actions.TeleportPlayer(position: CFrame | Vector3): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then
            return
        end

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not humanoidRootPart then
            return
        end

        if typeof(position) == "Vector3" then
            humanoidRootPart.CFrame = CFrame.new(position)
        else
            humanoidRootPart.CFrame = position :: CFrame
        end
    end
end

--[[
    Wait for a duration (skippable with P)
]]
function Actions.Wait(seconds: number): StoryAction
    return function()
        waitWithSkip(seconds)
    end
end

--[[
    Play a sound effect
]]
function Actions.PlaySound(soundId: string, volume: number?, delay: number?): StoryAction
    return function()
        if delay and delay > 0 then
            waitWithSkip(delay)
        end

        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 1
        sound.Parent = SoundService
        sound:Play()

        -- Cleanup after playing
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

--[[
    Stop a specific sound by its SoundId with optional fade out
]]
function Actions.StopSound(soundId: string, fadeDuration: number?): StoryAction
    return function()
        -- Find and stop all sounds with matching SoundId in SoundService
        for _, child in ipairs(SoundService:GetChildren()) do
            if child:IsA("Sound") and child.SoundId == soundId then
                if fadeDuration and fadeDuration > 0 then
                    local tween = TweenService:Create(child, TweenInfo.new(fadeDuration), { Volume = 0 })
                    tween:Play()
                    task.delay(fadeDuration, function()
                        if child and child.Parent then
                            child:Stop()
                            child:Destroy()
                        end
                    end)
                else
                    child:Stop()
                    child:Destroy()
                end
            end
        end
    end
end

function Actions.MoveCamera(targetCFrame: CFrame, duration: number?): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end

        camera.CameraType = Enum.CameraType.Scriptable

        local dur = duration or 1
        local tweenInfo = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local tween = TweenService:Create(camera, tweenInfo, { CFrame = targetCFrame })
        tween:Play()
        
        -- Wait for tween with skip support
        local skipped = waitWithSkip(dur)
        if skipped then
            tween:Cancel()
            camera.CFrame = targetCFrame  -- Snap to final position
        end
    end
end

--[[
    Set camera position instantly (skippable brief pause)
    Press P to skip the automatic 0.5s pause
]]
function Actions.SetCamera(targetCFrame: CFrame): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = targetCFrame
            -- Brief pause to let player see the camera position (skippable)
            waitWithSkip(0.1)
        end
    end
end

--[[
    Reset camera to player follow mode
]]
function Actions.ResetCamera(): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            -- Reset tilt
            TweenService:Create(camera, TweenInfo.new(0.5), {
                CFrame = camera.CFrame * CFrame.Angles(0, 0, -math.rad(camera.CFrame:ToEulerAnglesXYZ()))
            }):Play()
        end
    end
end

--[[
    Tilt the camera by an angle (in degrees)
]]
function Actions.CameraTilt(angle: number, duration: number?): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        camera.CameraType = Enum.CameraType.Scriptable
        local targetCFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(angle))
        
        if duration and duration > 0 then
            local tween = TweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame = targetCFrame
            })
            tween:Play()
            waitWithSkip(duration)
        else
            camera.CFrame = targetCFrame
        end
    end
end

--[[
    Apply a blur effect to the screen
]]
function Actions.SetBlur(size: number, duration: number?): StoryAction
    return function()
        local lighting = game:GetService("Lighting")
        local blur = lighting:FindFirstChildOfClass("BlurEffect")
        if not blur then
            blur = Instance.new("BlurEffect")
            blur.Size = 0
            blur.Parent = lighting
        end
        
        if duration and duration > 0 then
            local tween = TweenService:Create(blur, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = size
            })
            tween:Play()
            waitWithSkip(duration)
        else
            blur.Size = size
        end
    end
end

--[[
    Perform a "blink" effect (Fade in/out quickly)
]]
function Actions.Blink(holdDuration: number?): StoryAction
    return function()
        local frame = getFadeFrame()
        -- Open eye
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }):Play()
        waitWithSkip(0.2)
        
        -- Hold
        if holdDuration then
            waitWithSkip(holdDuration)
        end
        
        -- Close eye
        TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 0 }):Play()
        waitWithSkip(0.1)
    end
end

--[[
    Play an animation on a target (NPC or player)
]]
function Actions.PlayAnimation(target: Model | Humanoid, animationId: string, waitForComplete: boolean?): StoryAction
    return function()
        local humanoid: Humanoid?

        if target:IsA("Model") then
            humanoid = target:FindFirstChildOfClass("Humanoid")
        else
            humanoid = target :: Humanoid
        end

        if not humanoid then
            warn("[Actions.PlayAnimation] No humanoid found")
            return
        end

        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end

        local animation = Instance.new("Animation")
        animation.AnimationId = animationId

        local track = (animator :: Animator):LoadAnimation(animation)
        track:Play()

        if waitForComplete then
            track.Stopped:Wait()
        end
    end
end

--[[
    Wait for a trigger part to be touched
]]
function Actions.WaitForTrigger(triggerPart: BasePart): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then
            LocalPlayer.CharacterAdded:Wait()
            character = LocalPlayer.Character
        end

        local touched = false

        local connection: RBXScriptConnection
        connection = triggerPart.Touched:Connect(function(hit)
            if hit:IsDescendantOf(character :: Model) then
                touched = true
                connection:Disconnect()
            end
        end)

        -- Wait until touched
        while not touched do
            task.wait(0.1)
        end
    end
end

--[[
    Lock player movement
]]
function Actions.LockPlayer(): StoryAction
    return function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
            end
        end
    end
end

--[[
    Unlock player movement
]]
function Actions.UnlockPlayer(): StoryAction
    return function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end
        end
    end
end

--[[
    Shake the screen
]]
function Actions.ScreenShake(intensity: number, duration: number): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end

        local originalCFrame = camera.CFrame
        local startTime = tick()

        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local decay = 1 - (elapsed / duration)
            local offset = Vector3.new(
                (math.random() * 2 - 1) * intensity * decay,
                (math.random() * 2 - 1) * intensity * decay,
                0
            )
            camera.CFrame = originalCFrame * CFrame.new(offset)
            task.wait()
        end

        camera.CFrame = originalCFrame
    end
end

--[[
    Show/hide a UI element
]]
function Actions.ShowUI(guiName: string): StoryAction
    return function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local gui = playerGui:FindFirstChild(guiName)
        if gui and gui:IsA("ScreenGui") then
            gui.Enabled = true
        end
    end
end

function Actions.HideUI(guiName: string): StoryAction
    return function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local gui = playerGui:FindFirstChild(guiName)
        if gui and gui:IsA("ScreenGui") then
            gui.Enabled = false
        end
    end
end

--[[
    Run multiple actions in parallel
]]
function Actions.Parallel(...: StoryAction): StoryAction
    local actions = { ... }
    return function()
        local threads: { thread } = {}
        for _, action in actions do
            table.insert(threads, task.spawn(action))
        end

        -- Wait for all threads (simplified - they should complete on their own)
        task.wait(0.1) -- Give threads time to start
    end
end

--[[
    Run multiple actions in parallel and wait for all to complete
]]
function Actions.ParallelWait(...: StoryAction): StoryAction
    local actions = { ... }
    return function()
        local completed = 0
        local total = #actions

        for _, action in actions do
            task.spawn(function()
                action()
                completed += 1
            end)
        end

        while completed < total do
            task.wait(0.1)
        end
    end
end

--[[
    Play background music (uses AudioManager if available)
]]
function Actions.PlayMusic(soundId: string, fadeTime: number?): StoryAction
    return function()
        local sound = Instance.new("Sound")
        sound.Name = "BackgroundMusic"
        sound.SoundId = soundId
        sound.Looped = true
        sound.Volume = 0
        sound.Parent = SoundService

        -- Remove any existing background music
        for _, child in SoundService:GetChildren() do
            if child.Name == "BackgroundMusic" and child ~= sound then
                local fadeDur = fadeTime or 1
                local fadeOut = TweenService:Create(child, TweenInfo.new(fadeDur), { Volume = 0 })
                fadeOut:Play()
                fadeOut.Completed:Connect(function()
                    child:Destroy()
                end)
            end
        end

        sound:Play()
        local fadeIn = TweenService:Create(sound, TweenInfo.new(fadeTime or 1), { Volume = 0.8 })
        fadeIn:Play()
    end
end

--[[
    Stop background music
]]
function Actions.StopMusic(fadeTime: number?): StoryAction
    return function()
        for _, child in SoundService:GetChildren() do
            if child.Name == "BackgroundMusic" and child:IsA("Sound") then
                local fadeDur = fadeTime or 1
                local fadeOut = TweenService:Create(child, TweenInfo.new(fadeDur), { Volume = 0 })
                fadeOut:Play()
                fadeOut.Completed:Connect(function()
                    child:Destroy()
                end)
            end
        end
    end
end

--[[
    Show dialogue with choice options (blocks until player chooses)
    Fallout-style: Clean text with brackets, no backgrounds
]]
function Actions.Choice(prompt: string, choices: { { text: string, callback: () -> () } }): StoryAction
    return function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local screenGui = playerGui:FindFirstChild("DirectorUI") :: ScreenGui

        if not screenGui then
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = "DirectorUI"
            screenGui.ResetOnSpawn = false
            screenGui.DisplayOrder = 998
            screenGui.Parent = playerGui
        end

        -- Create choice container (lower on screen, like Fallout)
        local choiceFrame = Instance.new("Frame")
        choiceFrame.Name = "ChoiceFrame"
        choiceFrame.Size = UDim2.new(0.8, 0, 0.4, 0)
        choiceFrame.Position = UDim2.new(0.1, 0, 0.55, 0)  -- Lower position
        choiceFrame.BackgroundTransparency = 1  -- No background!
        choiceFrame.Parent = screenGui

        -- Prompt text (smaller, above choices)
        local promptLabel = Instance.new("TextLabel")
        promptLabel.Name = "PromptText"
        promptLabel.Size = UDim2.new(1, 0, 0, 40)
        promptLabel.Position = UDim2.new(0, 20, 0, 0)
        promptLabel.BackgroundTransparency = 1
        promptLabel.Text = ""
        promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        promptLabel.TextSize = 24
        promptLabel.Font = Enum.Font.SpecialElite
        promptLabel.TextXAlignment = Enum.TextXAlignment.Left  -- Left-aligned!
        promptLabel.TextYAlignment = Enum.TextYAlignment.Top
        promptLabel.TextWrapped = true
        promptLabel.Parent = choiceFrame

        -- Prompt text stroke (black outline)
        local promptStroke = Instance.new("UIStroke")
        promptStroke.Color = Color3.fromRGB(0, 0, 0)
        promptStroke.Thickness = 3
        promptStroke.Parent = promptLabel

        -- Typewriter the prompt (skippable)
        for i = 1, #prompt do
            if checkSkip() then
                promptLabel.Text = prompt
                break
            end
            promptLabel.Text = string.sub(prompt, 1, i)
            task.wait(0.03)
        end

        task.wait(0.3)  -- Brief pause before showing choices

        -- Create choice buttons container
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, 0, 1, -60)
        buttonContainer.Position = UDim2.new(0, 20, 0, 60)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.Parent = choiceFrame

        local choiceSelected = false
        local hoveredButton: TextButton? = nil

        for idx, choice in choices do
            -- Clean text button (no background, just text)
            local button = Instance.new("TextButton")
            button.Name = `Choice{idx}`
            button.Size = UDim2.new(1, -40, 0, 35)
            button.Position = UDim2.new(0, 0, 0, (idx - 1) * 40)
            button.BackgroundTransparency = 1  -- No background!
            button.BorderSizePixel = 0
            button.Text = `[{idx}] {choice.text}`  -- Brackets like Fallout!
            button.TextColor3 = Color3.fromRGB(200, 200, 200)  -- Default gray
            button.TextSize = 22
            button.Font = Enum.Font.SpecialElite  -- Special Elite!
            button.TextXAlignment = Enum.TextXAlignment.Left  -- Left-aligned!
            button.AutoButtonColor = false
            button.Parent = buttonContainer

            -- Text stroke (black outline)
            local textStroke = Instance.new("UIStroke")
            textStroke.Color = Color3.fromRGB(0, 0, 0)
            textStroke.Thickness = 3
            textStroke.Parent = button

            -- Hover effect (change text color only, like Fallout)
            button.MouseEnter:Connect(function()
                hoveredButton = button
                button.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White on hover
            end)

            button.MouseLeave:Connect(function()
                if hoveredButton == button then
                    hoveredButton = nil
                end
                button.TextColor3 = Color3.fromRGB(200, 200, 200)  -- Back to gray
            end)

            button.MouseButton1Click:Connect(function()
                choiceSelected = true
                choiceFrame:Destroy()
                choice.callback()
            end)
        end

        -- Wait for choice
        while not choiceSelected do
            task.wait(0.1)
        end
    end
end

--[[
    Flash the screen a color
]]
function Actions.FlashScreen(color: Color3, duration: number?): StoryAction
    return function()
        local frame = getFadeFrame()
        local originalColor = frame.BackgroundColor3
        frame.BackgroundColor3 = color
        frame.BackgroundTransparency = 0

        task.wait(duration or 0.1)

        local tween = TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Wait()
        frame.BackgroundColor3 = originalColor
    end
end

--[[
    Fade to a specific color (not just black)
]]
function Actions.FadeToColor(color: Color3, duration: number): StoryAction
    return function()
        local frame = getFadeFrame()
        frame.BackgroundColor3 = color
        local tween = TweenService:Create(frame, TweenInfo.new(duration), { BackgroundTransparency = 0 })
        tween:Play()
        tween.Completed:Wait()
    end
end

--[[
    Fade from a specific color back to transparent
]]
function Actions.FadeFromColor(duration: number): StoryAction
    return function()
        local frame = getFadeFrame()
        local tween = TweenService:Create(frame, TweenInfo.new(duration), { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Wait()
        frame.BackgroundColor3 = Color3.new(0, 0, 0) -- Reset to black
    end
end

--[[
    Call a custom function
]]
function Actions.Call(callback: () -> ()): StoryAction
    return function()
        callback()
    end
end

--[[
    Conditional action - only runs if condition is true
]]
function Actions.If(condition: () -> boolean, thenAction: StoryAction, elseAction: StoryAction?): StoryAction
    return function()
        if condition() then
            thenAction()
        elseif elseAction then
            elseAction()
        end
    end
end

--[[
    Print to output (for debugging)
]]
function Actions.Log(message: string): StoryAction
    return function()
        print(`[Director] {message}`)
    end
end

--[[
    Show objective notification (eerie typewriter theme)
]]
function Actions.ShowObjective(title: string, description: string?): StoryAction
    return function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")

        -- Remove any existing objective notification
        local existing = playerGui:FindFirstChild("ObjectiveNotification")
        if existing then existing:Destroy() end

        -- Create notification
        local notifGui = Instance.new("ScreenGui")
        notifGui.Name = "ObjectiveNotification"
        notifGui.ResetOnSpawn = false
        notifGui.DisplayOrder = 50
        notifGui.Parent = playerGui

        -- Notification frame (top left, minimalist)
        local notifFrame = Instance.new("Frame")
        notifFrame.Name = "NotifFrame"
        notifFrame.Size = UDim2.new(0, 350, 0, 70)
        notifFrame.Position = UDim2.new(0, -360, 0, 30)  -- Start off-screen
        notifFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        notifFrame.BackgroundTransparency = 0.6
        notifFrame.BorderSizePixel = 0
        notifFrame.Parent = notifGui

        -- Subtle border
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(80, 80, 80)
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = notifFrame

        -- "NEW OBJECTIVE" header
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Name = "Header"
        headerLabel.Size = UDim2.new(1, -20, 0, 20)
        headerLabel.Position = UDim2.new(0, 15, 0, 10)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = "NEW OBJECTIVE"
        headerLabel.TextColor3 = Color3.fromRGB(160, 150, 140)
        headerLabel.TextSize = 12
        headerLabel.Font = Enum.Font.SpecialElite
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Parent = notifFrame

        local headerStroke = Instance.new("UIStroke")
        headerStroke.Color = Color3.fromRGB(0, 0, 0)
        headerStroke.Thickness = 1
        headerStroke.Parent = headerLabel

        -- Objective text
        local objLabel = Instance.new("TextLabel")
        objLabel.Name = "ObjectiveText"
        objLabel.Size = UDim2.new(1, -30, 0, 35)
        objLabel.Position = UDim2.new(0, 15, 0, 30)
        objLabel.BackgroundTransparency = 1
        objLabel.Text = ""
        objLabel.TextColor3 = Color3.fromRGB(220, 215, 205)
        objLabel.TextSize = 20
        objLabel.Font = Enum.Font.SpecialElite
        objLabel.TextXAlignment = Enum.TextXAlignment.Left
        objLabel.TextWrapped = true
        objLabel.Parent = notifFrame

        local objStroke = Instance.new("UIStroke")
        objStroke.Color = Color3.fromRGB(0, 0, 0)
        objStroke.Thickness = 2
        objStroke.Parent = objLabel

        -- Slide in
        local slideIn = TweenService:Create(notifFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 20, 0, 30)
        })
        slideIn:Play()
        slideIn.Completed:Wait()

        -- Typewriter effect for objective
        for i = 1, #title do
            if checkSkip() then
                objLabel.Text = title
                break
            end
            objLabel.Text = string.sub(title, 1, i)
            task.wait(0.04)
        end

        -- Wait before sliding out
        waitWithSkip(4)

        -- Slide out
        local slideOut = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -360, 0, 30)
        })
        slideOut:Play()
        slideOut.Completed:Connect(function()
            notifGui:Destroy()
        end)
    end
end

--[[
    Wait for player input (any key or click)
]]
function Actions.WaitForInput(): StoryAction
    return function()
        local UserInputService = game:GetService("UserInputService")
        local inputReceived = false

        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed then
                inputReceived = true
            end
        end)

        while not inputReceived do
            task.wait(0.1)
        end

        connection:Disconnect()
    end
end

--[[
    Wait until player is within a certain distance of a part
    Great for triggering scenes when player approaches an area
]]
function Actions.WaitForProximity(part: BasePart, distance: number?): StoryAction
    return function()
        local maxDistance = distance or 10
        local character = LocalPlayer.Character
        if not character then
            LocalPlayer.CharacterAdded:Wait()
            character = LocalPlayer.Character
        end

        local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

        print(`[Actions] Waiting for player to be within {maxDistance} studs of {part.Name}`)

        while true do
            local dist = (humanoidRootPart.Position - part.Position).Magnitude
            if dist <= maxDistance then
                print(`[Actions] Player reached {part.Name}`)
                break
            end
            task.wait(0.1)
        end
    end
end

--[[
    Wait for a ProximityPrompt to be triggered
    Perfect for interactive objects like doors, buttons, items
]]
function Actions.WaitForProximityPrompt(prompt: ProximityPrompt): StoryAction
    return function()
        print(`[Actions] Waiting for ProximityPrompt: {prompt.Name}`)
        
        local triggered = false
        local connection: RBXScriptConnection
        
        connection = prompt.Triggered:Connect(function(playerWhoTriggered)
            if playerWhoTriggered == LocalPlayer then
                triggered = true
                connection:Disconnect()
            end
        end)

        while not triggered do
            task.wait(0.1)
        end

        print(`[Actions] ProximityPrompt triggered: {prompt.Name}`)
    end
end

--[[
    Wait for player to equip a specific tool
    Useful for "use the key on the door" type puzzles
]]
function Actions.WaitForToolEquip(toolName: string): StoryAction
    return function()
        print(`[Actions] Waiting for tool: {toolName}`)
        
        local character = LocalPlayer.Character
        if not character then
            LocalPlayer.CharacterAdded:Wait()
            character = LocalPlayer.Character
        end

        local equipped = false
        
        -- Check if already equipped
        local existingTool = character:FindFirstChild(toolName)
        if existingTool and existingTool:IsA("Tool") then
            print(`[Actions] Tool already equipped: {toolName}`)
            return
        end

        -- Wait for tool to be equipped
        local connection: RBXScriptConnection
        connection = character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and child.Name == toolName then
                equipped = true
                connection:Disconnect()
            end
        end)

        while not equipped do
            task.wait(0.1)
        end

        print(`[Actions] Tool equipped: {toolName}`)
    end
end

--[[
    Wait for player to activate a tool (click while holding)
    Useful for "use knife on rope" type interactions
]]
function Actions.WaitForToolActivation(toolName: string): StoryAction
    return function()
        print(`[Actions] Waiting for tool activation: {toolName}`)
        
        local character = LocalPlayer.Character
        if not character then
            LocalPlayer.CharacterAdded:Wait()
            character = LocalPlayer.Character
        end

        local activated = false

        -- Function to set up activation listener
        local function setupToolListener(tool: Tool)
            if tool.Name == toolName then
                local activateConnection: RBXScriptConnection
                activateConnection = tool.Activated:Connect(function()
                    activated = true
                    activateConnection:Disconnect()
                end)
            end
        end

        -- Check existing tools
        for _, child in character:GetChildren() do
            if child:IsA("Tool") then
                setupToolListener(child)
            end
        end

        -- Also listen for new tools
        local addConnection = character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                setupToolListener(child)
            end
        end)

        while not activated do
            task.wait(0.1)
        end

        addConnection:Disconnect()
        print(`[Actions] Tool activated: {toolName}`)
    end
end

--[[
    Combined: Wait for ProximityPrompt while holding specific tool
    Perfect for "use key on door" scenarios
]]
function Actions.WaitForToolOnPrompt(prompt: ProximityPrompt, toolName: string): StoryAction
    return function()
        print(`[Actions] Waiting for {toolName} to be used on {prompt.Name}`)
        
        local triggered = false
        local connection: RBXScriptConnection
        
        connection = prompt.Triggered:Connect(function(playerWhoTriggered)
            if playerWhoTriggered == LocalPlayer then
                -- Check if player has the required tool equipped
                local character = LocalPlayer.Character
                if character then
                    local tool = character:FindFirstChild(toolName)
                    if tool and tool:IsA("Tool") then
                        triggered = true
                        connection:Disconnect()
                        print(`[Actions] Used {toolName} on {prompt.Name}`)
                    else
                        print(`[Actions] Need to equip {toolName} first!`)
                    end
                end
            end
        end)

        while not triggered do
            task.wait(0.1)
        end
    end
end

--[[
    Enable or disable a ProximityPrompt
    Useful for showing/hiding interact options during story
]]
function Actions.SetPromptEnabled(prompt: ProximityPrompt, enabled: boolean): StoryAction
    return function()
        prompt.Enabled = enabled
        print(`[Actions] ProximityPrompt {prompt.Name} enabled: {enabled}`)
    end
end

--[[
    Configure a ProximityPrompt's properties
    Change the text, hold duration, etc.
]]
function Actions.ConfigurePrompt(prompt: ProximityPrompt, config: {
    ActionText: string?,
    ObjectText: string?,
    HoldDuration: number?,
    MaxActivationDistance: number?,
    RequiresLineOfSight: boolean?,
}): StoryAction
    return function()
        if config.ActionText then prompt.ActionText = config.ActionText end
        if config.ObjectText then prompt.ObjectText = config.ObjectText end
        if config.HoldDuration then prompt.HoldDuration = config.HoldDuration end
        if config.MaxActivationDistance then prompt.MaxActivationDistance = config.MaxActivationDistance end
        if config.RequiresLineOfSight ~= nil then prompt.RequiresLineOfSight = config.RequiresLineOfSight end
        print(`[Actions] Configured ProximityPrompt: {prompt.Name}`)
    end
end

--[[
    Start listening for triggers in the background (non-blocking)
    Calls a callback when triggered - use for ambient triggers
]]
function Actions.ListenForProximity(part: BasePart, distance: number, callback: () -> ()): StoryAction
    return function()
        local maxDistance = distance or 10
        
        task.spawn(function()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

            print(`[Actions] Background listener started for {part.Name}`)

            while true do
                local dist = (humanoidRootPart.Position - part.Position).Magnitude
                if dist <= maxDistance then
                    print(`[Actions] Background trigger: {part.Name}`)
                    callback()
                    break
                end
                task.wait(0.2)
            end
        end)
    end
end

--[[
    Start listening for a ProximityPrompt in the background (non-blocking)
    Calls a callback when triggered - use for optional interactions
]]
function Actions.ListenForPrompt(prompt: ProximityPrompt, callback: () -> ()): StoryAction
    return function()
        task.spawn(function()
            print(`[Actions] Background listener started for prompt: {prompt.Name}`)
            
            local connection: RBXScriptConnection
            connection = prompt.Triggered:Connect(function(playerWhoTriggered)
                if playerWhoTriggered == LocalPlayer then
                    print(`[Actions] Background prompt triggered: {prompt.Name}`)
                    connection:Disconnect()
                    callback()
                end
            end)
        end)
    end
end

-- ============================================
-- CUTSCENE ANIMATION ACTIONS
-- ============================================

--[[
    Play a cutscene animation on the player and wait for it to complete
    Perfect for animated cutscenes like driving, sitting, etc.
    
    Example:
    Actions.PlayCutsceneAnimation("rbxassetid://123456789")
]]
function Actions.PlayCutsceneAnimation(animationId: string): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then
            warn("[Actions.PlayCutsceneAnimation] No character found")
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            warn("[Actions.PlayCutsceneAnimation] No humanoid found")
            return
        end

        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end

        local animation = Instance.new("Animation")
        animation.AnimationId = animationId

        print(`[Actions] Playing cutscene animation: {animationId}`)
        local track = animator:LoadAnimation(animation)
        track:Play()
        
        -- Wait for animation to complete (skippable with P)
        local animLength = track.Length
        local elapsed = 0
        
        while track.IsPlaying and elapsed < animLength + 1 do
            if checkSkip() then
                print("[Actions] Animation skipped!")
                track:Stop()
                break
            end
            task.wait(0.1)
            elapsed += 0.1
        end
        
        track:Stop()
        animation:Destroy()
    end
end

--[[
    Run multiple actions in parallel (at the same time)
    Useful for playing animation + dialogue + sound simultaneously
    
    Example:
    Actions.ParallelActions({
        Actions.PlayCutsceneAnimation("rbxassetid://123"),
        Actions.Dialogue("I'm driving...", 3),
        Actions.PlaySound("rbxassetid://456")
    })
]]
function Actions.ParallelActions(actions: { StoryAction }): StoryAction
    return function()
        local threads = {}
        
        -- Start all actions in parallel
        for _, action in actions do
            table.insert(threads, task.spawn(function()
                action()
            end))
        end
        
        -- Wait a frame to let them all start
        task.wait()
    end
end

--[[
    Hide the player character (make invisible)
    Useful when you want to show a different model/rig for cutscenes
]]
function Actions.HideCharacter(): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then return end
        
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = 1
            end
        end
    end
end

--[[
    Show the player character (make visible again)
]]
function Actions.ShowCharacter(): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then return end
        
        for _, part in character:GetDescendants() do
            -- Skip HumanoidRootPart - it should always be invisible!
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            elseif part:IsA("Decal") then
                part.Transparency = 0
            end
        end
    end
end

--[[
    Make camera follow a part continuously (perfect for first-person cutscenes!)
    The camera will track the part's position and rotation in real-time
    
    Example:
    local rig = workspace.CutsceneRig
    local head = rig:FindFirstChild("Head")
    
    Actions.FollowPart(head)  -- Camera follows head
    Actions.PlayCutsceneAnimation("rbxassetid://123")  -- Animation plays
    Actions.StopFollowing()  -- Stop following
]]
function Actions.FollowPart(part: BasePart, offset: CFrame?): StoryAction
    return function()
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        camera.CameraType = Enum.CameraType.Scriptable
        
        -- Create a RunService connection to update camera every frame
        local RunService = game:GetService("RunService")
        local connection: RBXScriptConnection
        
        connection = RunService.RenderStepped:Connect(function()
            if not part or not part.Parent then
                -- Part was destroyed, stop following
                connection:Disconnect()
                return
            end
            
            -- Update camera to match part's CFrame (with optional offset)
            if offset then
                camera.CFrame = part.CFrame * offset
            else
                camera.CFrame = part.CFrame
            end
        end)
        
        -- Store connection so we can stop it later
        camera:SetAttribute("FollowConnection", true)
        
        -- Store in a global table (hacky but works)
        if not _G.CameraFollowConnection then
            _G.CameraFollowConnection = connection
        else
            -- Disconnect old one if exists
            if _G.CameraFollowConnection.Connected then
                _G.CameraFollowConnection:Disconnect()
            end
            _G.CameraFollowConnection = connection
        end
        
        print(`[Actions] Camera now following: {part.Name}`)
    end
end

--[[
    Stop camera from following a part
    Call this after your animation finishes
]]
function Actions.StopFollowing(): StoryAction
    return function()
        if _G.CameraFollowConnection and _G.CameraFollowConnection.Connected then
            _G.CameraFollowConnection:Disconnect()
            _G.CameraFollowConnection = nil
            print("[Actions] Stopped following part")
        end
    end
end

--[[
    Weld player to a part (for vehicle cutscenes, sitting, etc.)
    The player will move with the part
]]
function Actions.WeldToObject(object: BasePart): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
        if not hrp then return end
        
        local weld = Instance.new("WeldConstraint")
        weld.Name = "CutsceneWeld"
        weld.Part0 = hrp
        weld.Part1 = object
        weld.Parent = hrp
        
        print(`[Actions] Welded player to {object.Name}`)
    end
end

--[[
    Unweld player from any object
]]
function Actions.UnweldFromObject(): StoryAction
    return function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local weld = hrp:FindFirstChild("CutsceneWeld")
        if weld then
            weld:Destroy()
            print("[Actions] Unwelded player")
        end
    end
end

--[[
    Tween a model from its current position to a target part's position
    Perfect for moving cars, elevators, etc.
    
    Example:
    Actions.TweenModel(carModel, targetPart, 5, Enum.EasingStyle.Linear)
]]
function Actions.TweenModel(model: Model, targetPart: BasePart, duration: number, easingStyle: Enum.EasingStyle?): StoryAction
    return function()
        local primaryPart = model.PrimaryPart
        if not primaryPart then
            warn("[Actions.TweenModel] Model has no PrimaryPart set!")
            return
        end
        
        local startCFrame = primaryPart.CFrame
        local targetCFrame = targetPart.CFrame
        local style = easingStyle or Enum.EasingStyle.Linear
        
        print(`[Actions] Tweening {model.Name} to {targetPart.Name} over {duration}s`)
        
        local elapsed = 0
        
        while elapsed < duration do
            if checkSkip() then
                -- Skip to final position
                model:PivotTo(targetCFrame)
                return
            end
            
            local dt = task.wait()
            elapsed += dt
            
            local alpha = math.min(elapsed / duration, 1)
            
            -- Apply easing
            if style == Enum.EasingStyle.Quad then
                alpha = alpha * alpha
            elseif style == Enum.EasingStyle.Cubic then
                alpha = alpha * alpha * alpha
            elseif style == Enum.EasingStyle.Sine then
                alpha = 1 - math.cos(alpha * math.pi / 2)
            end
            
            local currentCFrame = startCFrame:Lerp(targetCFrame, alpha)
            model:PivotTo(currentCFrame)
        end
        
        -- Ensure final position
        model:PivotTo(targetCFrame)
    end
end

--[[
    Tween a single PART (and all welded children) to a target position
    Perfect for cars where hull is the main welded part
    
    Example:
    Actions.TweenPart(carHull, targetWaypoint, 5, Enum.EasingStyle.Linear)
]]
function Actions.TweenPart(part: BasePart, targetPart: BasePart, duration: number, easingStyle: Enum.EasingStyle?): StoryAction
    return function()
        local startCFrame = part.CFrame
        local targetCFrame = targetPart.CFrame
        local style = easingStyle or Enum.EasingStyle.Linear
        
        -- Keep part anchored during tween (welded parts will follow via CFrame)
        if not part.Anchored then
            warn(`[Actions.TweenPart] Part {part.Name} should be anchored! Anchoring it now.`)
            part.Anchored = true
        end
        
        print(`[Actions] Tweening part {part.Name} from {startCFrame} to {targetCFrame} over {duration}s`)
        
        local elapsed = 0
        
        while elapsed < duration do
            if checkSkip() then
                -- Skip to final position
                part.CFrame = targetCFrame
                print(`[Actions] Tween skipped, final position: {part.CFrame}`)
                return
            end
            
            local dt = task.wait()
            elapsed += dt
            
            local alpha = math.min(elapsed / duration, 1)
            
            -- Apply easing
            if style == Enum.EasingStyle.Quad then
                alpha = alpha * alpha
            elseif style == Enum.EasingStyle.Cubic then
                alpha = alpha * alpha * alpha
            elseif style == Enum.EasingStyle.Sine then
                alpha = 1 - math.cos(alpha * math.pi / 2)
            end
            
            local currentCFrame = startCFrame:Lerp(targetCFrame, alpha)
            part.CFrame = currentCFrame
        end
        
        -- Ensure final position
        part.CFrame = targetCFrame
        print(`[Actions] Tween complete, final position: {part.CFrame}`)
    end
end

--[[
    Tween a part through multiple waypoints WITHOUT stopping between them
    Each waypoint has its own duration - so speed is based on distance/duration
    
    Example:
    Actions.TweenPartThroughWaypoints(hull, {
        { target = waypoint1, duration = 0 },   -- Start here instantly
        { target = waypoint2, duration = 10 },  -- 10 seconds to reach wp2
        { target = waypoint3, duration = 2 },   -- 2 seconds to reach wp3 (fast!)
    })
    
    If waypoints are far apart with short duration = fast speed
    If waypoints are close with long duration = slow speed
]]
function Actions.TweenPartThroughWaypoints(part: BasePart, waypoints: { { target: BasePart, duration: number } }): StoryAction
    return function()
        if not part.Anchored then
            warn(`[Actions.TweenPartThroughWaypoints] Part {part.Name} should be anchored!`)
            part.Anchored = true
        end
        
        print(`[Actions] Starting continuous tween through {#waypoints} waypoints`)
        
        for i, wp in ipairs(waypoints) do
            local targetCFrame = wp.target.CFrame
            local duration = wp.duration
            
            -- If duration is 0, snap instantly
            if duration <= 0 then
                part.CFrame = targetCFrame
                print(`[Actions] Snapped to waypoint {i}: {wp.target.Name}`)
                continue
            end
            
            local startCFrame = part.CFrame
            print(`[Actions] Tweening to waypoint {i}: {wp.target.Name} over {duration}s`)
            
            local elapsed = 0
            
            while elapsed < duration do
                if checkSkip() then
                    -- Skip to final waypoint
                    part.CFrame = waypoints[#waypoints].target.CFrame
                    print("[Actions] Tween skipped, jumped to final waypoint")
                    return
                end
                
                local dt = task.wait()
                elapsed += dt
                
                local alpha = math.min(elapsed / duration, 1)
                part.CFrame = startCFrame:Lerp(targetCFrame, alpha)
            end
            
            -- Ensure we hit the waypoint exactly
            part.CFrame = targetCFrame
        end
        
        print("[Actions] Completed all waypoints")
    end
end

--[[
    Start a background tween that runs independently
    This allows you to start movement and do other actions at the same time
    
    Returns immediately - the tween runs in the background
    
    Example:
    Actions.StartBackgroundTween(hull, {
        { target = waypoint2, duration = 15 },
        { target = waypoint3, duration = 2 },
    })
    -- Other actions continue while car is moving...
]]
function Actions.StartBackgroundTween(part: BasePart, waypoints: { { target: BasePart, duration: number } }): StoryAction
    return function()
        if not part.Anchored then
            part.Anchored = true
        end
        
        print(`[Actions] Starting BACKGROUND tween through {#waypoints} waypoints`)
        
        -- Spawn the tween in a separate thread
        task.spawn(function()
            for i, wp in ipairs(waypoints) do
                local targetCFrame = wp.target.CFrame
                local duration = wp.duration
                
                if duration <= 0 then
                    part.CFrame = targetCFrame
                    continue
                end
                
                local startCFrame = part.CFrame
                local elapsed = 0
                
                while elapsed < duration do
                    local dt = task.wait()
                    elapsed += dt
                    local alpha = math.min(elapsed / duration, 1)
                    part.CFrame = startCFrame:Lerp(targetCFrame, alpha)
                end
                
                part.CFrame = targetCFrame
            end
            print("[Actions] Background tween completed")
        end)
    end
end

--[[
    Weld a rig (Model) to a seat part
    The rig's HumanoidRootPart will be welded to the seat
    
    Example:
    Actions.WeldRigToSeat(cutsceneRig, carSeat)
]]
function Actions.WeldRigToSeat(rig: Model, seat: BasePart): StoryAction
    return function()
        local hrp = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not hrp then
            -- Try Torso for R6
            hrp = rig:FindFirstChild("Torso") :: BasePart?
        end
        
        if not hrp then
            warn("[Actions.WeldRigToSeat] Rig has no HumanoidRootPart or Torso!")
            return
        end
        
        -- Position rig at seat
        hrp.CFrame = seat.CFrame * CFrame.new(0, 1, 0)  -- Slightly above seat
        
        -- Create weld
        local weld = Instance.new("WeldConstraint")
        weld.Name = "RigSeatWeld"
        weld.Part0 = hrp
        weld.Part1 = seat
        weld.Parent = hrp
        
        print(`[Actions] Welded rig {rig.Name} to seat {seat.Name}`)
    end
end

--[[
    Unweld rig from seat
]]
function Actions.UnweldRigFromSeat(rig: Model): StoryAction
    return function()
        local hrp = rig:FindFirstChild("HumanoidRootPart")
        if not hrp then
            hrp = rig:FindFirstChild("Torso")
        end
        
        if not hrp then return end
        
        local weld = hrp:FindFirstChild("RigSeatWeld")
        if weld then
            weld:Destroy()
            print(`[Actions] Unwelded rig {rig.Name} from seat`)
        end
    end
end

--[[
    Play a looping sound (like car engine, ambient noise)
    Returns immediately, sound keeps playing until stopped
    
    Example:
    Actions.PlayLoopingSound("rbxassetid://123", "CarEngine", 0.5)
]]
function Actions.PlayLoopingSound(soundId: string, name: string, volume: number?): StoryAction
    return function()
        local sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = soundId
        sound.Volume = volume or 0.5
        sound.Looped = true
        sound.Parent = SoundService
        sound:Play()
        
        print(`[Actions] Started looping sound: {name}`)
    end
end

--[[
    Stop a looping sound by name
]]
function Actions.StopLoopingSound(name: string, fadeTime: number?): StoryAction
    return function()
        for _, child in SoundService:GetChildren() do
            if child.Name == name and child:IsA("Sound") then
                if fadeTime and fadeTime > 0 then
                    local fadeOut = TweenService:Create(child, TweenInfo.new(fadeTime), { Volume = 0 })
                    fadeOut:Play()
                    fadeOut.Completed:Connect(function()
                        child:Destroy()
                    end)
                else
                    child:Destroy()
                end
                print(`[Actions] Stopped looping sound: {name}`)
            end
        end
    end
end

--[[
    Play sound and wait for it to complete (blocking)
]]
function Actions.PlaySoundAndWait(soundId: string, volume: number?): StoryAction
    return function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 1
        sound.Parent = SoundService
        sound:Play()
        
        -- Wait for sound with skip support
        local soundLength = sound.TimeLength
        if soundLength > 0 then
            local skipped = waitWithSkip(soundLength)
            if skipped then
                sound:Stop()
            end
        else
            sound.Ended:Wait()
        end
        
        sound:Destroy()
    end
end

return Actions

