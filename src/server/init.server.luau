--!strict
--[[
    Server Bootstrapper (init.server.luau)
    Initializes all server-side services in the correct order
    Entry point for all server-side game logic
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

-- Service references
local Services = script:WaitForChild("Services")
local StoryManager = require(Services:WaitForChild("StoryManager"))
local ObjectiveService = require(Services:WaitForChild("ObjectiveService"))

-- Service registry for ordered initialization
local serviceRegistry: { any } = {
    StoryManager,
    ObjectiveService,
}

--[[
    Bootstrap the server
]]
local function Bootstrap(): ()
    print("[Server] Bootstrapping...")

    -- Initialize remotes first
    Remotes.InitializeServer()

    -- Initialize all services
    for _, service in serviceRegistry do
        if service.Initialize then
            service:Initialize()
            print(`[Server] Initialized: {service.Name}`)
        end
    end

    -- Start all services
    for _, service in serviceRegistry do
        if service.Start then
            task.spawn(function()
                service:Start()
                print(`[Server] Started: {service.Name}`)
            end)
        end
    end

    print("[Server] Bootstrap complete!")
end

-- Run bootstrap
Bootstrap()
