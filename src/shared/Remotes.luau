--!strict
--[[
    Remotes.luau
    Centralized remote event/function registry
    Creates and provides type-safe access to all network remotes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Remote containers
local eventsFolder: Folder
local functionsFolder: Folder

-- Remote event definitions
local eventNames = {
    "StartGame",
    "StoryStateChanged",
    "ObjectiveUpdated",
    "PlayCutscene",
    "DialogueRequest",
    "UIStateChanged",
    "CutsceneCompleted",
}

-- Remote function definitions
local functionNames = {
    "GetStoryState",
    "GetObjectives",
    "GetCurrentChapter",
}

--[[
    Initialize the remotes system
    Should be called by server bootstrapper first
]]
function Remotes.InitializeServer(): ()
    -- Create folders if they don't exist
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "RemoteEvents"
    eventsFolder.Parent = ReplicatedStorage

    functionsFolder = Instance.new("Folder")
    functionsFolder.Name = "RemoteFunctions"
    functionsFolder.Parent = ReplicatedStorage

    -- Create all remote events
    for _, name in eventNames do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = eventsFolder
    end

    -- Create all remote functions
    for _, name in functionNames do
        local remote = Instance.new("RemoteFunction")
        remote.Name = name
        remote.Parent = functionsFolder
    end

    print("[Remotes] Server remotes initialized")
end

--[[
    Wait for remotes to be available (client-side)
]]
function Remotes.WaitForRemotes(): ()
    eventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents") :: Folder
    functionsFolder = ReplicatedStorage:WaitForChild("RemoteFunctions") :: Folder

    -- Wait for all events
    for _, name in eventNames do
        eventsFolder:WaitForChild(name)
    end

    -- Wait for all functions
    for _, name in functionNames do
        functionsFolder:WaitForChild(name)
    end

    print("[Remotes] Client remotes ready")
end

--[[
    Get a remote event by name
]]
function Remotes.GetEvent(name: string): RemoteEvent
    if not eventsFolder then
        eventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents") :: Folder
    end
    return eventsFolder:FindFirstChild(name) :: RemoteEvent
end

--[[
    Get a remote function by name
]]
function Remotes.GetFunction(name: string): RemoteFunction
    if not functionsFolder then
        functionsFolder = ReplicatedStorage:WaitForChild("RemoteFunctions") :: Folder
    end
    return functionsFolder:FindFirstChild(name) :: RemoteFunction
end

-- Convenience accessors for type safety
Remotes.Events = setmetatable({}, {
    __index = function(_, key: string): RemoteEvent
        return Remotes.GetEvent(key)
    end,
}) :: { [string]: RemoteEvent }

Remotes.Functions = setmetatable({}, {
    __index = function(_, key: string): RemoteFunction
        return Remotes.GetFunction(key)
    end,
}) :: { [string]: RemoteFunction }

return Remotes
