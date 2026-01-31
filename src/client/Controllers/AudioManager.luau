--!strict
--[[
    AudioManager.luau
    Manages background music, ambience, and sound effects
    Supports crossfading and layered audio
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AudioManager = {
    Name = "AudioManager",
}

-- Audio channels
local musicChannel: Sound? = nil
local ambienceChannel: Sound? = nil
local sfxGroup: SoundGroup? = nil

-- State
local currentMusicId: string? = nil
local currentAmbienceId: string? = nil
local masterVolume = 1
local musicVolume = 0.8
local sfxVolume = 1
local ambienceVolume = 0.6
local isInitialized = false

--[[
    Initialize the AudioManager
]]
function AudioManager:Initialize(): ()
    if isInitialized then
        return
    end

    -- Create music channel
    musicChannel = Instance.new("Sound")
    musicChannel.Name = "MusicChannel"
    musicChannel.Looped = true
    musicChannel.Volume = 0
    musicChannel.Parent = SoundService

    -- Create ambience channel
    ambienceChannel = Instance.new("Sound")
    ambienceChannel.Name = "AmbienceChannel"
    ambienceChannel.Looped = true
    ambienceChannel.Volume = 0
    ambienceChannel.Parent = SoundService

    -- Create SFX group
    sfxGroup = Instance.new("SoundGroup")
    sfxGroup.Name = "SFXGroup"
    sfxGroup.Volume = sfxVolume
    sfxGroup.Parent = SoundService

    isInitialized = true
    print("[AudioManager] Initialized")
end

--[[
    Start the AudioManager
]]
function AudioManager:Start(): ()
    -- Nothing to do on start
end

--[[
    Play background music with optional crossfade
]]
function AudioManager:PlayMusic(soundId: string, fadeTime: number?): ()
    if not musicChannel then
        self:Initialize()
    end

    musicChannel = musicChannel :: Sound
    local fadeDuration = fadeTime or 1

    if currentMusicId == soundId then
        return -- Already playing
    end

    -- Fade out current music
    if musicChannel.IsPlaying then
        local fadeOut = TweenService:Create(musicChannel, TweenInfo.new(fadeDuration), {
            Volume = 0
        })
        fadeOut:Play()
        fadeOut.Completed:Wait()
    end

    -- Set new music and fade in
    musicChannel.SoundId = soundId
    musicChannel.Volume = 0
    musicChannel:Play()
    currentMusicId = soundId

    local fadeIn = TweenService:Create(musicChannel, TweenInfo.new(fadeDuration), {
        Volume = musicVolume * masterVolume
    })
    fadeIn:Play()

    print(`[AudioManager] Playing music: {soundId}`)
end

--[[
    Stop music with fade out
]]
function AudioManager:StopMusic(fadeTime: number?): ()
    if not musicChannel then
        return
    end

    musicChannel = musicChannel :: Sound
    local fadeDuration = fadeTime or 1

    local fadeOut = TweenService:Create(musicChannel, TweenInfo.new(fadeDuration), {
        Volume = 0
    })
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        musicChannel:Stop()
        currentMusicId = nil
    end)
end

--[[
    Play ambient sound
]]
function AudioManager:PlayAmbience(soundId: string, fadeTime: number?): ()
    if not ambienceChannel then
        self:Initialize()
    end

    ambienceChannel = ambienceChannel :: Sound
    local fadeDuration = fadeTime or 2

    if currentAmbienceId == soundId then
        return
    end

    -- Fade out current ambience
    if ambienceChannel.IsPlaying then
        local fadeOut = TweenService:Create(ambienceChannel, TweenInfo.new(fadeDuration), {
            Volume = 0
        })
        fadeOut:Play()
        fadeOut.Completed:Wait()
    end

    -- Set new ambience and fade in
    ambienceChannel.SoundId = soundId
    ambienceChannel.Volume = 0
    ambienceChannel:Play()
    currentAmbienceId = soundId

    local fadeIn = TweenService:Create(ambienceChannel, TweenInfo.new(fadeDuration), {
        Volume = ambienceVolume * masterVolume
    })
    fadeIn:Play()

    print(`[AudioManager] Playing ambience: {soundId}`)
end

--[[
    Stop ambience with fade out
]]
function AudioManager:StopAmbience(fadeTime: number?): ()
    if not ambienceChannel then
        return
    end

    ambienceChannel = ambienceChannel :: Sound
    local fadeDuration = fadeTime or 2

    local fadeOut = TweenService:Create(ambienceChannel, TweenInfo.new(fadeDuration), {
        Volume = 0
    })
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        ambienceChannel:Stop()
        currentAmbienceId = nil
    end)
end

--[[
    Play a one-shot sound effect
]]
function AudioManager:PlaySFX(soundId: string, volume: number?, pitch: number?): Sound
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = (volume or 1) * sfxVolume * masterVolume
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = SoundService

    if sfxGroup then
        sound.SoundGroup = sfxGroup
    end

    sound:Play()

    -- Cleanup after playing
    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    return sound
end

--[[
    Play a positional 3D sound
]]
function AudioManager:PlaySFX3D(soundId: string, position: BasePart | Vector3, volume: number?): Sound
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = (volume or 1) * sfxVolume * masterVolume
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMinDistance = 10
    sound.RollOffMaxDistance = 100

    if typeof(position) == "Vector3" then
        -- Create an attachment at the position
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)
        part.Position = position
        part.Parent = workspace
        sound.Parent = part

        sound.Ended:Connect(function()
            part:Destroy()
        end)
    else
        sound.Parent = position
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end

    sound:Play()
    return sound
end

--[[
    Set master volume
]]
function AudioManager:SetMasterVolume(volume: number): ()
    masterVolume = math.clamp(volume, 0, 1)

    if musicChannel then
        musicChannel.Volume = musicVolume * masterVolume
    end
    if ambienceChannel then
        ambienceChannel.Volume = ambienceVolume * masterVolume
    end
end

--[[
    Set music volume
]]
function AudioManager:SetMusicVolume(volume: number): ()
    musicVolume = math.clamp(volume, 0, 1)
    if musicChannel then
        musicChannel.Volume = musicVolume * masterVolume
    end
end

--[[
    Set SFX volume
]]
function AudioManager:SetSFXVolume(volume: number): ()
    sfxVolume = math.clamp(volume, 0, 1)
    if sfxGroup then
        sfxGroup.Volume = sfxVolume
    end
end

--[[
    Set ambience volume
]]
function AudioManager:SetAmbienceVolume(volume: number): ()
    ambienceVolume = math.clamp(volume, 0, 1)
    if ambienceChannel then
        ambienceChannel.Volume = ambienceVolume * masterVolume
    end
end

--[[
    Duck music volume temporarily (for dialogue/cutscenes)
]]
function AudioManager:DuckMusic(targetVolume: number, duration: number): ()
    if not musicChannel then
        return
    end

    musicChannel = musicChannel :: Sound
    local tween = TweenService:Create(musicChannel, TweenInfo.new(duration), {
        Volume = targetVolume * masterVolume
    })
    tween:Play()
end

--[[
    Restore music volume after ducking
]]
function AudioManager:RestoreMusic(duration: number): ()
    if not musicChannel then
        return
    end

    musicChannel = musicChannel :: Sound
    local tween = TweenService:Create(musicChannel, TweenInfo.new(duration), {
        Volume = musicVolume * masterVolume
    })
    tween:Play()
end

return AudioManager
