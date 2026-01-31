--!strict
--[[
    Director.luau
    Story sequence orchestrator - the "secret sauce" for story games
    Allows writing story segments as simple sequential action lists
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Story = script.Parent
local Actions = require(Story:WaitForChild("Actions"))

type StoryAction = Actions.StoryAction

local Director = {
    Name = "Director",
}

-- Internal state
local isPlayingSequence = false
local currentSequenceName: string? = nil
local isInitialized = false

-- Sequence registry for named sequences
local registeredSequences: { [string]: { StoryAction } } = {}

--[[
    Initialize the Director
]]
function Director:Initialize(): ()
    if isInitialized then
        return
    end

    isInitialized = true
end

--[[
    Start the Director
]]
function Director:Start(): ()
    print("[Director] Ready to orchestrate stories")
end

--[[
    Play a sequence of actions in order
    This is the core API for story scripting

    Example usage:
    Director:PlaySequence({
        Actions.FadeOut(1),
        Actions.TeleportPlayer(SpawnPoint),
        Actions.FadeIn(1),
        Actions.Dialogue("Who... who is there?"),
        Actions.Wait(2),
        Actions.PlaySound("rbxassetid://123456")
    })
]]
function Director:PlaySequence(actions: { StoryAction }, sequenceName: string?): ()
    if isPlayingSequence then
        warn("[Director] Already playing a sequence, queuing not implemented")
        return
    end

    isPlayingSequence = true
    currentSequenceName = sequenceName or "Anonymous"

    print(`[Director] Playing sequence: {currentSequenceName}`)

    -- Execute each action in order
    for i, action in actions do
        if not isPlayingSequence then
            -- Sequence was cancelled
            print(`[Director] Sequence cancelled at action {i}`)
            break
        end

        action()
    end

    isPlayingSequence = false
    currentSequenceName = nil

    print(`[Director] Sequence complete`)
end

--[[
    Play a sequence asynchronously (doesn't block)
]]
function Director:PlaySequenceAsync(actions: { StoryAction }, sequenceName: string?): ()
    task.spawn(function()
        self:PlaySequence(actions, sequenceName)
    end)
end

--[[
    Register a named sequence for later playback
]]
function Director:RegisterSequence(name: string, actions: { StoryAction }): ()
    registeredSequences[name] = actions
    print(`[Director] Registered sequence: {name}`)
end

--[[
    Play a registered sequence by name
]]
function Director:PlayRegisteredSequence(name: string): ()
    local actions = registeredSequences[name]
    if actions then
        self:PlaySequence(actions, name)
    else
        warn(`[Director] Sequence not found: {name}`)
    end
end

--[[
    Cancel the current sequence
]]
function Director:CancelSequence(): ()
    if isPlayingSequence then
        isPlayingSequence = false
        print(`[Director] Cancelling sequence: {currentSequenceName or "Unknown"}`)
    end
end

--[[
    Check if a sequence is currently playing
]]
function Director:IsPlaying(): boolean
    return isPlayingSequence
end

--[[
    Get the name of the current sequence
]]
function Director:GetCurrentSequence(): string?
    return currentSequenceName
end

--[[
    Create a sub-sequence that can be used as a single action
    Useful for grouping related actions
]]
function Director:CreateSubSequence(actions: { StoryAction }): StoryAction
    return function()
        for _, action in actions do
            action()
        end
    end
end

--[[
    Wait until no sequence is playing
]]
function Director:WaitForCompletion(): ()
    while isPlayingSequence do
        task.wait(0.1)
    end
end

-- Provide access to Actions for convenience
Director.Actions = Actions

return Director
