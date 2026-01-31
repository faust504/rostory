--!strict
--[[
    Types.luau
    Centralized type definitions for the Story Game Framework
    All shared types used across client and server
]]

export type GameState = "Menu" | "Playing" | "Cutscene" | "Paused" | "Loading"

export type UIState = {
    currentScreen: string,
    previousScreen: string?,
    isTransitioning: boolean,
}

export type Objective = {
    id: string,
    title: string,
    description: string,
    isCompleted: boolean,
    isActive: boolean,
}

export type DialogueEntry = {
    speaker: string?,
    text: string,
    duration: number?,
    voiceId: string?,
}

export type StoryChapter = {
    id: string,
    name: string,
    scenes: { string },
}

export type StoryState = {
    currentChapter: string,
    currentScene: string,
    completedObjectives: { string },
    flags: { [string]: boolean },
    timestamp: number,
}

export type StoryAction = {
    actionType: string,
    params: { [string]: any },
    execute: ((self: StoryAction) -> ())?,
}

export type CameraShot = {
    cframe: CFrame,
    duration: number,
    easingStyle: Enum.EasingStyle?,
    easingDirection: Enum.EasingDirection?,
}

export type CinematicSequence = {
    id: string,
    shots: { CameraShot },
    lockPlayerControls: boolean,
}

-- Service/Controller interfaces
export type Service = {
    Name: string,
    Initialize: (self: Service) -> (),
    Start: (self: Service) -> (),
}

export type Controller = {
    Name: string,
    Initialize: (self: Controller) -> (),
    Start: (self: Controller) -> (),
}

-- Remote event types for type-safe networking
export type RemoteEvents = {
    StartGame: RemoteEvent,
    StoryStateChanged: RemoteEvent,
    ObjectiveUpdated: RemoteEvent,
    PlayCutscene: RemoteEvent,
    DialogueRequest: RemoteEvent,
}

export type RemoteFunctions = {
    GetStoryState: RemoteFunction,
    GetObjectives: RemoteFunction,
}

return nil
