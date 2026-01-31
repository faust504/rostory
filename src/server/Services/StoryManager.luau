--!strict
--[[
    StoryManager.luau
    Core story state machine - handles chapters, scenes, and game progression
    Manages save/load functionality via centralized StoryState
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type StoryState = Types.StoryState

local StoryManager = {
    Name = "StoryManager",
}

-- Internal state
local playerStates: { [Player]: StoryState } = {}
local isInitialized = false

-- Default starting state
local DEFAULT_STATE: StoryState = {
    currentChapter = "Chapter1",
    currentScene = "Intro",
    completedObjectives = {},
    flags = {},
    timestamp = 0,
}

--[[
    Initialize the StoryManager
]]
function StoryManager:Initialize(): ()
    if isInitialized then
        return
    end

    -- Setup remote function handlers
    local getStoryState = Remotes.GetFunction("GetStoryState")
    getStoryState.OnServerInvoke = function(player: Player): StoryState?
        return self:GetPlayerState(player)
    end

    isInitialized = true
end

--[[
    Start the StoryManager - listen for player events
]]
function StoryManager:Start(): ()
    -- Initialize state for existing players
    for _, player in Players:GetPlayers() do
        self:InitializePlayerState(player)
    end

    -- Handle new players
    Players.PlayerAdded:Connect(function(player: Player)
        self:InitializePlayerState(player)
    end)

    -- Cleanup on player leave
    Players.PlayerRemoving:Connect(function(player: Player)
        self:SavePlayerState(player)
        playerStates[player] = nil
    end)

    -- Handle StartGame remote
    Remotes.GetEvent("StartGame").OnServerEvent:Connect(function(player: Player)
        self:StartGame(player)
    end)
end

--[[
    Initialize state for a player (load from DataStore or use default)
]]
function StoryManager:InitializePlayerState(player: Player): ()
    -- TODO: Load from DataStore
    local loadedState = self:LoadPlayerState(player)
    playerStates[player] = loadedState or table.clone(DEFAULT_STATE)
    playerStates[player].timestamp = os.time()
    print(`[StoryManager] Initialized state for {player.Name}`)
end

--[[
    Get the current state for a player
]]
function StoryManager:GetPlayerState(player: Player): StoryState?
    return playerStates[player]
end

--[[
    Update the story state for a player
]]
function StoryManager:SetPlayerState(player: Player, newState: StoryState): ()
    playerStates[player] = newState
    newState.timestamp = os.time()

    -- Notify client of state change
    Remotes.GetEvent("StoryStateChanged"):FireClient(player, newState)
end

--[[
    Set a story flag
]]
function StoryManager:SetFlag(player: Player, flagName: string, value: boolean): ()
    local state = playerStates[player]
    if state then
        state.flags[flagName] = value
        Remotes.GetEvent("StoryStateChanged"):FireClient(player, state)
    end
end

--[[
    Check a story flag
]]
function StoryManager:GetFlag(player: Player, flagName: string): boolean
    local state = playerStates[player]
    if state then
        return state.flags[flagName] or false
    end
    return false
end

--[[
    Progress to the next chapter/scene
]]
function StoryManager:ProgressTo(player: Player, chapter: string, scene: string): ()
    local state = playerStates[player]
    if state then
        state.currentChapter = chapter
        state.currentScene = scene
        state.timestamp = os.time()
        Remotes.GetEvent("StoryStateChanged"):FireClient(player, state)
        print(`[StoryManager] {player.Name} progressed to {chapter}/{scene}`)
    end
end

--[[
    Mark an objective as completed
]]
function StoryManager:CompleteObjective(player: Player, objectiveId: string): ()
    local state = playerStates[player]
    if state and not table.find(state.completedObjectives, objectiveId) then
        table.insert(state.completedObjectives, objectiveId)
        print(`[StoryManager] {player.Name} completed objective: {objectiveId}`)
    end
end

--[[
    Start the game for a player
]]
function StoryManager:StartGame(player: Player): ()
    print(`[StoryManager] Starting game for {player.Name}`)
    
    local state = playerStates[player]
    if state then
        -- Fire event to trigger cutscene/intro on client
        Remotes.GetEvent("PlayCutscene"):FireClient(player, "Intro")
    end
end

--[[
    Load player state from DataStore (placeholder)
]]
function StoryManager:LoadPlayerState(player: Player): StoryState?
    -- TODO: Implement DataStore loading
    -- local DataStoreService = game:GetService("DataStoreService")
    -- local storyStore = DataStoreService:GetDataStore("StoryProgress")
    -- local success, data = pcall(function()
    --     return storyStore:GetAsync(tostring(player.UserId))
    -- end)
    return nil
end

--[[
    Save player state to DataStore (placeholder)
]]
function StoryManager:SavePlayerState(player: Player): ()
    local state = playerStates[player]
    if not state then
        return
    end

    -- TODO: Implement DataStore saving
    -- local DataStoreService = game:GetService("DataStoreService")
    -- local storyStore = DataStoreService:GetDataStore("StoryProgress")
    -- pcall(function()
    --     storyStore:SetAsync(tostring(player.UserId), state)
    -- end)
    print(`[StoryManager] Saved state for {player.Name}`)
end

return StoryManager
