--!strict
--[[
    Chapter.luau
    Defines a story chapter/scene structure
    Allows organizing story content into reusable modules
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type SceneDefinition = {
    id: string,
    name: string,
    actions: { () -> () },
    onEnter: (() -> ())?,
    onExit: (() -> ())?,
}

export type ChapterDefinition = {
    id: string,
    name: string,
    scenes: { SceneDefinition },
    startScene: string?,
}

local Chapter = {}
Chapter.__index = Chapter

-- Registry of all chapters
local chapterRegistry: { [string]: ChapterDefinition } = {}

--[[
    Create a new chapter definition
]]
function Chapter.new(definition: ChapterDefinition): ChapterDefinition
    assert(definition.id, "[Chapter] Chapter must have an id")
    assert(definition.name, "[Chapter] Chapter must have a name")
    assert(definition.scenes and #definition.scenes > 0, "[Chapter] Chapter must have at least one scene")

    -- Register chapter
    chapterRegistry[definition.id] = definition
    print(`[Chapter] Registered: {definition.name} ({#definition.scenes} scenes)`)

    return definition
end

--[[
    Create a scene definition
]]
function Chapter.scene(id: string, name: string, actions: { () -> () }): SceneDefinition
    return {
        id = id,
        name = name,
        actions = actions,
    }
end

--[[
    Get a registered chapter by ID
]]
function Chapter.get(chapterId: string): ChapterDefinition?
    return chapterRegistry[chapterId]
end

--[[
    Get a scene from a chapter
]]
function Chapter.getScene(chapterId: string, sceneId: string): SceneDefinition?
    local chapter = chapterRegistry[chapterId]
    if not chapter then
        return nil
    end

    for _, scene in chapter.scenes do
        if scene.id == sceneId then
            return scene
        end
    end

    return nil
end

--[[
    Get all registered chapters
]]
function Chapter.getAll(): { [string]: ChapterDefinition }
    return chapterRegistry
end

--[[
    Clear all registered chapters (for testing)
]]
function Chapter.clearRegistry(): ()
    chapterRegistry = {}
end

return Chapter
