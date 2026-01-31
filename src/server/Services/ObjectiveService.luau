--!strict
--[[
    ObjectiveService.luau
    Tracks and manages player objectives
    Handles ProximityPrompt triggers and objective state synchronization
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type Objective = Types.Objective

local ObjectiveService = {
    Name = "ObjectiveService",
}

-- Internal state
local playerObjectives: { [Player]: { Objective } } = {}
local triggerConnections: { RBXScriptConnection } = {}
local isInitialized = false

-- Objective definitions
local OBJECTIVES: { [string]: Objective } = {
    explore = {
        id = "explore",
        title = "Explore the Environment",
        description = "Look around and find points of interest.",
        isCompleted = false,
        isActive = true,
    },
    enter_building = {
        id = "enter_building",
        title = "Go Inside the Building",
        description = "Enter through the gate and explore the interior.",
        isCompleted = false,
        isActive = false,
    },
}

--[[
    Initialize the ObjectiveService
]]
function ObjectiveService:Initialize(): ()
    if isInitialized then
        return
    end

    -- Setup remote function handlers
    local getObjectives = Remotes.GetFunction("GetObjectives")
    getObjectives.OnServerInvoke = function(player: Player): { Objective }
        return self:GetPlayerObjectives(player)
    end

    isInitialized = true
end

--[[
    Start the ObjectiveService
]]
function ObjectiveService:Start(): ()
    -- Initialize objectives for existing players
    for _, player in Players:GetPlayers() do
        self:InitializePlayerObjectives(player)
    end

    -- Handle new players
    Players.PlayerAdded:Connect(function(player: Player)
        self:InitializePlayerObjectives(player)
    end)

    -- Cleanup on player leave
    Players.PlayerRemoving:Connect(function(player: Player)
        playerObjectives[player] = nil
    end)

    -- Setup trigger parts
    self:SetupTriggers()
end

--[[
    Initialize objectives for a player
]]
function ObjectiveService:InitializePlayerObjectives(player: Player): ()
    local objectives: { Objective } = {}
    
    for id, template in OBJECTIVES do
        local objective = table.clone(template)
        table.insert(objectives, objective)
    end

    playerObjectives[player] = objectives

    -- Set first objective as active
    self:SetActiveObjective(player, "explore")
    print(`[ObjectiveService] Initialized objectives for {player.Name}`)
end

--[[
    Get all objectives for a player
]]
function ObjectiveService:GetPlayerObjectives(player: Player): { Objective }
    return playerObjectives[player] or {}
end

--[[
    Get a specific objective for a player
]]
function ObjectiveService:GetObjective(player: Player, objectiveId: string): Objective?
    local objectives = playerObjectives[player]
    if objectives then
        for _, obj in objectives do
            if obj.id == objectiveId then
                return obj
            end
        end
    end
    return nil
end

--[[
    Set the active objective for a player
]]
function ObjectiveService:SetActiveObjective(player: Player, objectiveId: string): ()
    local objectives = playerObjectives[player]
    if not objectives then
        return
    end

    for _, obj in objectives do
        obj.isActive = (obj.id == objectiveId)
    end

    local objective = self:GetObjective(player, objectiveId)
    if objective then
        Remotes.GetEvent("ObjectiveUpdated"):FireClient(player, objective)
        print(`[ObjectiveService] {player.Name} new objective: {objective.title}`)
    end
end

--[[
    Complete an objective and optionally activate the next one
]]
function ObjectiveService:CompleteObjective(player: Player, objectiveId: string, nextObjectiveId: string?): ()
    local objective = self:GetObjective(player, objectiveId)
    if not objective then
        return
    end

    objective.isCompleted = true
    objective.isActive = false
    Remotes.GetEvent("ObjectiveUpdated"):FireClient(player, objective)
    print(`[ObjectiveService] {player.Name} completed: {objective.title}`)

    -- Activate next objective if specified
    if nextObjectiveId then
        self:SetActiveObjective(player, nextObjectiveId)
    end
end

--[[
    Setup trigger parts in the workspace with ProximityPrompts
]]
function ObjectiveService:SetupTriggers(): ()
    -- Look for GatePart trigger
    local workspace = game:GetService("Workspace")
    local gatePart = workspace:FindFirstChild("GatePart", true)

    if gatePart and gatePart:IsA("BasePart") then
        self:CreateTrigger(gatePart :: BasePart, "explore", "enter_building", "Explore Gate")
    else
        -- Create a placeholder warning - in production, the part should exist in the place
        warn("[ObjectiveService] GatePart not found in Workspace. Create a Part named 'GatePart' to enable trigger.")
    end
end

--[[
    Create a ProximityPrompt trigger on a part
]]
function ObjectiveService:CreateTrigger(
    part: BasePart,
    completesObjective: string,
    activatesObjective: string?,
    promptText: string?
): ()
    -- Create or get ProximityPrompt
    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = promptText or "Interact"
        prompt.ActionText = "Explore"
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 10
        prompt.Parent = part
    end

    -- Connect trigger
    local connection = prompt.Triggered:Connect(function(player: Player)
        local objective = self:GetObjective(player, completesObjective)
        if objective and objective.isActive and not objective.isCompleted then
            self:CompleteObjective(player, completesObjective, activatesObjective)
        end
    end)

    table.insert(triggerConnections, connection)
    print(`[ObjectiveService] Created trigger on {part.Name}`)
end

--[[
    Add a new objective at runtime
]]
function ObjectiveService:AddObjective(player: Player, objective: Objective): ()
    local objectives = playerObjectives[player]
    if objectives then
        table.insert(objectives, objective)
        Remotes.GetEvent("ObjectiveUpdated"):FireClient(player, objective)
    end
end

return ObjectiveService
