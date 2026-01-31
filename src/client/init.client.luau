--!strict
--[[
    Client Bootstrapper (init.client.luau)
    Initializes all client-side controllers in the correct order
    Entry point for all client-side game logic
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

-- Controller references
local Controllers = script:WaitForChild("Controllers")
local UIManager = require(Controllers:WaitForChild("UIManager"))
local CutsceneController = require(Controllers:WaitForChild("CutsceneController"))
local AnimationController = require(Controllers:WaitForChild("AnimationController"))

-- Story modules
local Story = script:WaitForChild("Story")
local Director = require(Story:WaitForChild("Director"))

-- Controller registry for ordered initialization
local controllerRegistry: { any } = {
    UIManager,
    CutsceneController,
    AnimationController,
    Director,
}

-- Wait for player to be fully loaded
local LocalPlayer = Players.LocalPlayer

-- Hide character initially (player will see MainMenu first)
local function HideCharacterInitially()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    -- Make character invisible
    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = 1
        end
    end
    
    -- Disable character rendering
    if character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(0, -1000, 0) -- Move far away
    end
end

local function WaitForCharacter(): ()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
end

-- Hide character on first spawn
HideCharacterInitially()

--[[
    Bootstrap the client
]]
local function Bootstrap(): ()
    print("[Client] Bootstrapping...")

    -- Wait for remotes to be available
    Remotes.WaitForRemotes()

    -- Initialize all controllers
    for _, controller in controllerRegistry do
        if controller.Initialize then
            controller:Initialize()
            print(`[Client] Initialized: {controller.Name}`)
        end
    end

    -- Wait for character before starting controllers
    WaitForCharacter()

    -- Start all controllers
    for _, controller in controllerRegistry do
        if controller.Start then
            task.spawn(function()
                controller:Start()
                print(`[Client] Started: {controller.Name}`)
            end)
        end
    end

    print("[Client] Bootstrap complete!")
end

-- Run bootstrap
Bootstrap()
