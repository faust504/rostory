--!strict
--[[
    UIManager.luau
    Manages UI state machine and screen transitions
    Handles Menu, Gameplay, Cutscene UI states with fade effects
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type UIState = Types.UIState
type GameState = Types.GameState

local UIManager = {
    Name = "UIManager",
}

-- Internal state
local currentState: UIState = {
    currentScreen = "None",
    previousScreen = nil,
    isTransitioning = false,
}

local screens: { [string]: ScreenGui } = {}
local fadeFrame: Frame? = nil
local playerGui: PlayerGui? = nil
local isInitialized = false

-- Screen modules registry
local screenModules: { [string]: any } = {}

--[[
    Initialize the UIManager
]]
function UIManager:Initialize(): ()
    if isInitialized then
        return
    end

    local player = Players.LocalPlayer
    playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

    -- Create the main UI container and fade overlay
    self:CreateUIContainer()

    isInitialized = true
end

--[[
    Start the UIManager
]]
function UIManager:Start(): ()
    -- Load and initialize MainMenu
    -- UI is a sibling of Controllers, so go up one level (Parent.Parent)
    local Client = script.Parent.Parent
    local UI = Client:WaitForChild("UI")
    local MainMenu = require(UI:WaitForChild("MainMenu"))
    MainMenu:Init()
    
    -- Show main menu by default
    self:ShowScreen("MainMenu")
    print("[UIManager] MainMenu shown")

    -- Listen for UI state change events from server
    Remotes.GetEvent("UIStateChanged").OnClientEvent:Connect(function(newState: string)
        self:ShowScreen(newState)
    end)
end

--[[
    Create the main UI container and fade overlay
]]
function UIManager:CreateUIContainer(): ()
    -- Create core UI ScreenGui
    local coreUI = Instance.new("ScreenGui")
    coreUI.Name = "CoreUI"
    coreUI.ResetOnSpawn = false
    coreUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    coreUI.DisplayOrder = 100
    coreUI.IgnoreGuiInset = true  -- Cover full screen
    coreUI.Parent = playerGui

    -- Create fade overlay frame
    fadeFrame = Instance.new("Frame")
    fadeFrame.Name = "FadeOverlay"
    fadeFrame.Size = UDim2.fromScale(1, 1)
    fadeFrame.Position = UDim2.fromScale(0, 0)
    fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    fadeFrame.BackgroundTransparency = 1 -- Start invisible
    fadeFrame.BorderSizePixel = 0
    fadeFrame.ZIndex = 999
    fadeFrame.Parent = coreUI

    screens["Core"] = coreUI
end

--[[
    Register a screen module
]]
function UIManager:RegisterScreen(name: string, screenModule: any): ()
    screenModules[name] = screenModule
    print(`[UIManager] Registered screen: {name}`)
end

--[[
    Create or get a screen
]]
function UIManager:GetOrCreateScreen(name: string): ScreenGui
    if screens[name] then
        return screens[name]
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = name
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    screens[name] = screenGui
    return screenGui
end

--[[
    Show a screen by name
]]
function UIManager:ShowScreen(name: string, instant: boolean?): ()
    if currentState.isTransitioning then
        return
    end

    -- Hide current screen
    if currentState.currentScreen ~= "None" and screens[currentState.currentScreen] then
        screens[currentState.currentScreen].Enabled = false
    end

    -- Show new screen
    local screen = self:GetOrCreateScreen(name)
    screen.Enabled = true

    -- Update state
    currentState.previousScreen = currentState.currentScreen
    currentState.currentScreen = name

    -- Call screen module's Show method if available
    local screenModule = screenModules[name]
    if screenModule and screenModule.Show then
        screenModule:Show()
    end

    print(`[UIManager] Showing screen: {name}`)
end

--[[
    Hide a screen by name
]]
function UIManager:HideScreen(name: string): ()
    if screens[name] then
        screens[name].Enabled = false
    end

    -- Call screen module's Hide method if available
    local screenModule = screenModules[name]
    if screenModule and screenModule.Hide then
        screenModule:Hide()
    end
end

--[[
    Hide all screens
]]
function UIManager:HideAllScreens(): ()
    for name, screen in screens do
        if name ~= "Core" then
            screen.Enabled = false
        end
    end
end

--[[
    Fade to black
]]
function UIManager:FadeOut(duration: number?): ()
    local dur = duration or 1

    if not fadeFrame then
        return
    end

    currentState.isTransitioning = true

    local tweenInfo = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(fadeFrame, tweenInfo, { BackgroundTransparency = 0 })
    tween:Play()
    tween.Completed:Wait()

    currentState.isTransitioning = false
end

--[[
    Fade from black
]]
function UIManager:FadeIn(duration: number?): ()
    local dur = duration or 1

    if not fadeFrame then
        return
    end

    currentState.isTransitioning = true

    local tweenInfo = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween = TweenService:Create(fadeFrame, tweenInfo, { BackgroundTransparency = 1 })
    tween:Play()
    tween.Completed:Wait()

    currentState.isTransitioning = false
end

--[[
    Transition between screens with fade
]]
function UIManager:TransitionTo(name: string, fadeDuration: number?): ()
    local dur = fadeDuration or 0.5

    task.spawn(function()
        self:FadeOut(dur)
        self:HideAllScreens()
        self:ShowScreen(name, true)
        self:FadeIn(dur)
    end)
end

--[[
    Get current screen name
]]
function UIManager:GetCurrentScreen(): string
    return currentState.currentScreen
end

--[[
    Check if currently transitioning
]]
function UIManager:IsTransitioning(): boolean
    return currentState.isTransitioning
end

--[[
    Get the screen container for building UI
]]
function UIManager:GetScreenContainer(name: string): ScreenGui
    return self:GetOrCreateScreen(name)
end

return UIManager
