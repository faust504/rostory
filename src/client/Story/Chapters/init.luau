--!strict
--[[
    Chapters/init.luau
    Container for all story chapters
    Chapters are loaded on-demand, not at startup
]]

-- This module exists to prevent auto-loading issues
-- Individual chapters should be required directly when needed:
-- local Chapter1 = require(Chapters.Chapter1_Intro)

return {
    -- Add chapter references here as needed for quick access
    -- Chapter1 = script:WaitForChild("Chapter1_Intro"),
}
