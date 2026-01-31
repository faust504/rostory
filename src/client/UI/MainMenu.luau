--!strict
--[[
    MainMenu.luau
    Eerie typewriter-styled main menu
    Camera looks at map from mainmenupart, no black background
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local _Remotes = require(Shared:WaitForChild("Remotes"))

-- Lazy-load UIManager to avoid cyclic dependency
local Controllers = script.Parent.Parent:WaitForChild("Controllers")
local UIManager: any = nil
local function GetUIManager()
    if not UIManager then
        UIManager = require(Controllers:WaitForChild("UIManager"))
    end
    return UIManager
end

local MainMenu = {
    Name = "MainMenu",
}

-- UI references
local screenGui: ScreenGui? = nil
local mainFrame: Frame? = nil
local focusLayer: Frame? = nil -- Dark overlay for menus
local settingsFrame: CanvasGroup? = nil
local creditsFrame: CanvasGroup? = nil
local isBuilt = false

-- Settings state (defaults)
local settings = {
    GlobalShadows = true,
    MusicVolume = 0.5,
    SFXVolume = 1.0,
}

-- Theme colors (eerie, uncolorful)
local THEME = {
    Text = Color3.fromRGB(220, 215, 205),           -- Aged paper white
    TextDim = Color3.fromRGB(175, 175, 175),
    SubtitleColor = Color3.fromRGB(187, 187, 187),        -- Faded
    TextHover = Color3.fromRGB(255, 255, 255),      -- Bright on hover
    Stroke = Color3.fromRGB(0, 0, 0),               -- Black outline
    ButtonBg = Color3.fromRGB(0, 0, 0),             -- Semi-transparent black
    Overlay = Color3.fromRGB(0, 0, 0),              -- Dark overlay
}

-- Camera connection for menu
local menuCameraConnection: RBXScriptConnection? = nil

--[[
    Set camera to look at the map from mainmenupart
]]
local function SetupMenuCamera()
    local RunService = game:GetService("RunService")
    local camera = Workspace.CurrentCamera
    local menuPart = Workspace:FindFirstChild("mainmenupart")
    
    if not camera then
        warn("[MainMenu] Camera not found!")
        return
    end
    
    if not menuPart then
        warn("[MainMenu] mainmenupart not found in Workspace!")
        return
    end
    
    -- Set camera to scriptable
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Disconnect any existing connection
    if menuCameraConnection then
        menuCameraConnection:Disconnect()
    end
    
    -- Keep camera locked to menu part every frame
    menuCameraConnection = RunService.RenderStepped:Connect(function()
        if camera and menuPart then
            camera.CFrame = menuPart.CFrame
        end
    end)
    
    print("[MainMenu] Camera locked to mainmenupart")
end

--[[
    Reset camera to player control
]]
local function ResetCamera()
    -- Disconnect the camera lock
    if menuCameraConnection then
        menuCameraConnection:Disconnect()
        menuCameraConnection = nil
    end
    
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        print("[MainMenu] Camera reset to player control")
    end
end

--[[
    Create text with typewriter stroke effect
]]
local function CreateStyledText(parent: GuiObject, name: string, text: string, size: number, yPos: number, alignment: Enum.TextXAlignment?): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 0, size + 10)
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.TextSize = size
    label.Font = Enum.Font.SpecialElite
    label.TextXAlignment = alignment or Enum.TextXAlignment.Center
    label.Parent = parent
    
    -- Black stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Stroke
    stroke.Thickness = 2
    stroke.Parent = label
    
    return label
end

--[[
    Create a menu button with typewriter style
]]
local function CreateMenuButton(parent: GuiObject, text: string, order: number, callback: () -> ()): TextButton
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = UDim2.new(0, 300, 0, 45)
    button.BackgroundColor3 = THEME.ButtonBg
    button.BackgroundTransparency = 0.7
    button.BorderSizePixel = 0
    button.Text = "[ " .. text .. " ]"
    button.TextColor3 = THEME.TextDim
    button.TextSize = 24
    button.Font = Enum.Font.SpecialElite
    button.LayoutOrder = order
    button.AutoButtonColor = false
    button.Parent = parent
    
    -- Subtle stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            TextColor3 = THEME.TextHover,
            BackgroundTransparency = 0.5,
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            TextColor3 = THEME.TextDim,
            BackgroundTransparency = 0.7,
        }):Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

--[[
    Create a toggle setting
]]
local function CreateToggle(parent: GuiObject, text: string, yPos: number, default: boolean, onChange: (boolean) -> ()): Frame
    local container = Instance.new("Frame")
    container.Name = text .. "Toggle"
    container.Size = UDim2.new(1, -40, 0, 40)
    container.Position = UDim2.new(0, 20, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.TextSize = 18
    label.Font = Enum.Font.SpecialElite
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Stroke
    stroke.Thickness = 1
    stroke.Parent = label
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 80, 0, 30)
    button.Position = UDim2.new(1, -80, 0.5, -15)
    button.BackgroundColor3 = THEME.ButtonBg
    button.BackgroundTransparency = 0.5
    button.Text = default and "ON" or "OFF"
    button.TextColor3 = default and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 100, 100)
    button.TextSize = 16
    button.Font = Enum.Font.SpecialElite
    button.AutoButtonColor = false
    button.Parent = container
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = THEME.Stroke
    btnStroke.Thickness = 1
    btnStroke.Parent = button
    
    local state = default
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        button.TextColor3 = state and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 100, 100)
        onChange(state)
    end)
    
    return container
end

--[[
    Build the main menu UI
]]
function MainMenu:Build(): ()
    if isBuilt then
        return
    end

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Create ScreenGui (NO background - we see the game world!)
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10
    screenGui.IgnoreGuiInset = true  -- Cover full screen including top bar
    screenGui.Enabled = true
    screenGui.Parent = playerGui

    -- Subtle dark vignette overlay (dark edges, clear center)
    local vignette = Instance.new("Frame")
    vignette.Name = "Vignette"
    vignette.Size = UDim2.fromScale(1, 1)
    vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    vignette.BackgroundTransparency = 1
    vignette.BorderSizePixel = 0
    vignette.Parent = screenGui
    
    -- Radial gradient for proper vignette (dark edges, very gradual fade)
    local vignetteGradient = Instance.new("UIGradient")
    vignetteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),       -- Fully clear center
        NumberSequenceKeypoint.new(0.5, 0.95),  -- Still mostly clear
        NumberSequenceKeypoint.new(0.75, 0.7),  -- Start fading
        NumberSequenceKeypoint.new(0.9, 0.4),   -- More visible
        NumberSequenceKeypoint.new(1, 0.2),     -- Dark edges
    })
    vignetteGradient.Rotation = 90
    vignetteGradient.Parent = vignette

    vignetteGradient.Parent = vignette

    -- Focus layer (darkens background when menus open)
    focusLayer = Instance.new("Frame")
    focusLayer.Name = "FocusLayer"
    focusLayer.Size = UDim2.fromScale(1, 1)
    focusLayer.BackgroundColor3 = Color3.new(0, 0, 0)
    focusLayer.BackgroundTransparency = 1 -- Start transparent
    focusLayer.Visible = false
    focusLayer.ZIndex = 5
    focusLayer.Parent = screenGui

    -- Main container (left side, like old horror game menus)
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainContainer"
    mainFrame.Size = UDim2.new(0.35, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.6
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 1
    mainFrame.Parent = screenGui

    -- Gradient on main frame
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    gradient.Rotation = 0
    gradient.Parent = mainFrame

    -- Title (large, eerie) - moved down to compensate for IgnoreGuiInset
    local _title = CreateStyledText(mainFrame, "Title", "Hereafter", 52, 130)
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 25)
    subtitle.Position = UDim2.new(0, 0, 0, 190)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "a story of loss"
    subtitle.TextColor3 = THEME.SubtitleColor
    subtitle.TextSize = 16
    subtitle.Font = Enum.Font.SpecialElite
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    subtitle.Parent = mainFrame

    -- Button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 250)
    buttonContainer.Position = UDim2.new(0, 0, 0, 270)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mainFrame

    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Padding = UDim.new(0, 12)
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.Parent = buttonContainer

    -- Create buttons
    CreateMenuButton(buttonContainer, "START", 1, function()
        self:OnPlayClicked()
    end)

    CreateMenuButton(buttonContainer, "SETTINGS", 2, function()
        self:ShowSettings()
    end)

    CreateMenuButton(buttonContainer, "CREDITS", 3, function()
        self:ShowCredits()
    end)

    -- Version text (bottom left)
    local version = Instance.new("TextLabel")
    version.Name = "Version"
    version.Size = UDim2.new(0, 150, 0, 20)
    version.Position = UDim2.new(0, 20, 1, -40)
    version.BackgroundTransparency = 1
    version.Text = "v0.1.0 - Development Build"
    version.TextColor3 = THEME.TextDim
    version.TextSize = 12
    version.Font = Enum.Font.SpecialElite
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Parent = mainFrame
    
    local versionStroke = Instance.new("UIStroke")
    versionStroke.Color = THEME.Stroke
    versionStroke.Thickness = 0.5
    versionStroke.Parent = version

    -- Build settings frame (hidden initially)
    self:BuildSettingsFrame()
    
    -- Build credits frame (hidden initially)
    self:BuildCreditsFrame()

    isBuilt = true
    print("[MainMenu] UI built with eerie theme")
end

-- Helper to fade focus layer
local function FadeFocusLayer(visible: boolean)
    if not focusLayer then return end
    
    if visible then
        focusLayer.Visible = visible
        TweenService:Create(focusLayer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.3 -- Dim the background
        }):Play()
    else
        local fade = TweenService:Create(focusLayer, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        fade:Play()
        fade.Completed:Connect(function()
            focusLayer.Visible = false
        end)
    end
end

-- Helper for eerie menu animation (Slide up + Fade in, no bounce)
local function AnimateOpen(frame: CanvasGroup)
    if not frame then return end
    
    frame.Visible = true
    frame.GroupTransparency = 1
    frame.Position = UDim2.new(0.5, 0, 0.5, 30) -- Start slightly lower
    
    -- Fade in focus layer
    FadeFocusLayer(true)
    
    -- Tween transparency
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        GroupTransparency = 0
    }):Play()
    
    -- Tween position (float up) - Quint for smooth stop, no bounce
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
end

-- Helper for closing animation (Fade out + Slide down)
local function AnimateClose(frame: CanvasGroup, callback: (() -> ())?)
    if not frame then return end
    
    -- Fade out focus layer
    FadeFocusLayer(false)
    
    -- Tween transparency
    local fade = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        GroupTransparency = 1
    })
    fade:Play()
    
    -- Tween position (sink down)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 0.5, 20)
    }):Play()
    
    fade.Completed:Connect(function()
        frame.Visible = false
        if callback then callback() end
    end)
end

--[[
    Build settings panel
]]
function MainMenu:BuildSettingsFrame()
    -- Use CanvasGroup for group opacity animation
    settingsFrame = Instance.new("CanvasGroup")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
    settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    settingsFrame.BackgroundTransparency = 0.1
    settingsFrame.GroupTransparency = 1 -- Start hidden
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Visible = false
    settingsFrame.ZIndex = 10
    settingsFrame.Parent = screenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.TextDim
    stroke.Thickness = 1
    stroke.Parent = settingsFrame
    
    -- Title
    CreateStyledText(settingsFrame, "Title", "SETTINGS", 28, 20)
    
    -- Settings options
    local yOffset = 80
    
    -- Global Shadows toggle
    CreateToggle(settingsFrame, "Global Shadows", yOffset, settings.GlobalShadows, function(enabled)
        settings.GlobalShadows = enabled
        Lighting.GlobalShadows = enabled
        print(`[Settings] Global Shadows: {enabled}`)
    end)
    yOffset += 50
    
    -- Atmosphere toggle  
    CreateToggle(settingsFrame, "Atmosphere Effects", yOffset, true, function(enabled)
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Density = enabled and 0.3 or 0
        end
        print(`[Settings] Atmosphere: {enabled}`)
    end)
    yOffset += 50
    
    -- Bloom toggle
    CreateToggle(settingsFrame, "Bloom Effects", yOffset, true, function(enabled)
        local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
        if bloom then
            bloom.Enabled = enabled
        end
        print(`[Settings] Bloom: {enabled}`)
    end)
    yOffset += 50
    
    -- Blur toggle
    CreateToggle(settingsFrame, "Depth of Field", yOffset, true, function(enabled)
        local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
        if dof then
            dof.Enabled = enabled
        end
        print(`[Settings] DOF: {enabled}`)
    end)
    yOffset += 50
    
    -- Back button
    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackButton"
    backBtn.Size = UDim2.new(0, 150, 0, 40)
    backBtn.Position = UDim2.new(0.5, -75, 1, -60)
    backBtn.BackgroundColor3 = THEME.ButtonBg
    backBtn.BackgroundTransparency = 0.5
    backBtn.Text = "[ BACK ]"
    backBtn.TextColor3 = THEME.TextDim
    backBtn.TextSize = 18
    backBtn.Font = Enum.Font.SpecialElite
    backBtn.AutoButtonColor = false
    backBtn.Parent = settingsFrame
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = THEME.Stroke
    btnStroke.Thickness = 1
    btnStroke.Parent = backBtn
    
    backBtn.MouseEnter:Connect(function()
        backBtn.TextColor3 = THEME.TextHover
    end)
    backBtn.MouseLeave:Connect(function()
        backBtn.TextColor3 = THEME.TextDim
    end)
    backBtn.MouseButton1Click:Connect(function()
        self:HideSettings()
    end)
end

--[[
    Build credits panel
]]
function MainMenu:BuildCreditsFrame()
    -- Use CanvasGroup for group opacity animation
    creditsFrame = Instance.new("CanvasGroup")
    creditsFrame.Name = "CreditsFrame"
    creditsFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
    creditsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    creditsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    creditsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    creditsFrame.BackgroundTransparency = 0.1
    creditsFrame.GroupTransparency = 1 -- Start hidden
    creditsFrame.BorderSizePixel = 0
    creditsFrame.Visible = false
    creditsFrame.ZIndex = 10
    creditsFrame.Parent = screenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.TextDim
    stroke.Thickness = 1
    stroke.Parent = creditsFrame
    
    -- Title
    CreateStyledText(creditsFrame, "Title", "CREDITS", 28, 20)
    
    -- Scrolling frame for credits content
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "CreditsScroll"
    scrollFrame.Size = UDim2.new(1, -40, 1, -120)
    scrollFrame.Position = UDim2.new(0, 20, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = THEME.TextDim
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)  -- Will be set after adding content
    scrollFrame.Parent = creditsFrame
    
    -- Credits content
    local credits = {
        "",
        "Hereafter",
        "",
        "Created by",
        "@abubakarrashya",
        "",
        "Voice Acting",
        "@abubakarrashya",
        "",
        "Programming",
        "@abubakarrashya",
        "",
        "Story & Writing",
        "@abubakarrashya",
        "",
        "Special Thanks",
        "You, for playing.",
        "",
    }
    
    local yOffset = 10
    for _, line in ipairs(credits) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 22)
        label.Position = UDim2.new(0, 0, 0, yOffset)
        label.BackgroundTransparency = 1
        label.Text = line
        label.TextColor3 = line:find("%[") and THEME.Text or THEME.SubtitleColor
        label.TextSize = line == "Hereafter" and 24 or 16
        label.Font = Enum.Font.SpecialElite
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Parent = scrollFrame
        
        if line ~= "" then
            local lineStroke = Instance.new("UIStroke")
            lineStroke.Color = THEME.Stroke
            lineStroke.Thickness = 1
            lineStroke.Parent = label
        end
        
        yOffset += 22
    end
    
    -- Set canvas size to fit all content
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
    
    -- Back button
    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackButton"
    backBtn.Size = UDim2.new(0, 150, 0, 40)
    backBtn.Position = UDim2.new(0.5, -75, 1, -60)
    backBtn.BackgroundColor3 = THEME.ButtonBg
    backBtn.BackgroundTransparency = 0.5
    backBtn.Text = "[ BACK ]"
    backBtn.TextColor3 = THEME.TextDim
    backBtn.TextSize = 18
    backBtn.Font = Enum.Font.SpecialElite
    backBtn.AutoButtonColor = false
    backBtn.Parent = creditsFrame
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = THEME.Stroke
    btnStroke.Thickness = 1
    btnStroke.Parent = backBtn
    
    backBtn.MouseEnter:Connect(function()
        backBtn.TextColor3 = THEME.TextHover
    end)
    backBtn.MouseLeave:Connect(function()
        backBtn.TextColor3 = THEME.TextDim
    end)
    backBtn.MouseButton1Click:Connect(function()
        self:HideCredits()
    end)
end

--[[
    Show settings panel
]]
function MainMenu:ShowSettings()
    if settingsFrame and not settingsFrame.Visible then
        AnimateOpen(settingsFrame :: CanvasGroup)
    end
end

--[[
    Hide settings panel
]]
function MainMenu:HideSettings()
    if settingsFrame and settingsFrame.Visible then
        AnimateClose(settingsFrame :: CanvasGroup)
    end
end

--[[
    Show credits panel
]]
function MainMenu:ShowCredits()
    if creditsFrame and not creditsFrame.Visible then
        AnimateOpen(creditsFrame :: CanvasGroup)
    end
end

--[[
    Hide credits panel
]]
function MainMenu:HideCredits()
    if creditsFrame and creditsFrame.Visible then
        AnimateClose(creditsFrame :: CanvasGroup)
    end
end

--[[
    Handle Play button click
]]
function MainMenu:OnPlayClicked(): ()
    print("[MainMenu] Play clicked")

    task.spawn(function()
        print("[MainMenu] Starting fade out...")
        GetUIManager():FadeOut(1)
        
        print("[MainMenu] Hiding menu...")
        self:Hide()
        
        -- Reset camera before starting game
        ResetCamera()
        
        -- Load and start Chapter 1
        print("[MainMenu] Loading Chapter 1...")
        local Story = script.Parent.Parent:WaitForChild("Story")
        local Chapters = Story:WaitForChild("Chapters")
        local Chapter1 = require(Chapters:WaitForChild("Chapter1_Intro"))
        
        print("[MainMenu] Starting Chapter 1 intro scene...")
        Chapter1.Start()
        
        print("[MainMenu] Chapter 1 started!")
    end)
end

--[[
    Show the main menu
]]
function MainMenu:Show(): ()
    print("[MainMenu] Show() called")
    
    if not isBuilt then
        print("[MainMenu] Building UI...")
        self:Build()
    end

    -- Set camera to menu view
    SetupMenuCamera()

    if screenGui then
        screenGui.Enabled = true
        if mainFrame then mainFrame.Visible = true end
        if settingsFrame then settingsFrame.Visible = false end
        if creditsFrame then creditsFrame.Visible = false end
        print("[MainMenu] ScreenGui enabled")
    else
        warn("[MainMenu] ScreenGui is nil!")
    end
end

--[[
    Hide the main menu
]]
function MainMenu:Hide(): ()
    if screenGui then
        screenGui.Enabled = false
    end
end

--[[
    Initialize and register with UIManager
]]
function MainMenu:Init(): ()
    self:Build()
    GetUIManager():RegisterScreen("MainMenu", self)
end

return MainMenu
