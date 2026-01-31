--!strict
--[[
    DialogueBox.luau
    Advanced dialogue UI component with character portraits and choices
    Supports typewriter effect, speaker names, and branching choices
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local DialogueBox = {}

export type DialogueConfig = {
    text: string,
    speaker: string?,
    portrait: string?, -- Image asset ID
    choices: { { text: string, callback: () -> () } }?,
    typeSpeed: number?,
    autoAdvance: boolean?,
    autoAdvanceDelay: number?,
}

-- UI References
local playerGui: PlayerGui? = nil
local screenGui: ScreenGui? = nil
local dialogueFrame: Frame? = nil
local speakerLabel: TextLabel? = nil
local textLabel: TextLabel? = nil
local portraitImage: ImageLabel? = nil
local choicesFrame: Frame? = nil
local continueIndicator: TextLabel? = nil

-- State
local isShowing = false
local isTyping = false
local currentText = ""
local skipRequested = false

-- Colors
local COLORS = {
    Background = Color3.fromRGB(15, 15, 25),
    BackgroundAlt = Color3.fromRGB(25, 25, 40),
    Primary = Color3.fromRGB(100, 120, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 200),
    Speaker = Color3.fromRGB(120, 180, 255),
}

--[[
    Build the dialogue UI
]]
function DialogueBox.Build(): ()
    local player = Players.LocalPlayer
    playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DialogueBoxUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 500
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    -- Main dialogue container
    dialogueFrame = Instance.new("Frame")
    dialogueFrame.Name = "DialogueFrame"
    dialogueFrame.Size = UDim2.new(0.7, 0, 0.25, 0)
    dialogueFrame.Position = UDim2.new(0.15, 0, 0.72, 0)
    dialogueFrame.BackgroundColor3 = COLORS.Background
    dialogueFrame.BackgroundTransparency = 0.1
    dialogueFrame.BorderSizePixel = 0
    dialogueFrame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 16)
    frameCorner.Parent = dialogueFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = COLORS.Primary
    frameStroke.Thickness = 2
    frameStroke.Transparency = 0.3
    frameStroke.Parent = dialogueFrame

    -- Portrait image (left side)
    portraitImage = Instance.new("ImageLabel")
    portraitImage.Name = "Portrait"
    portraitImage.Size = UDim2.new(0, 120, 0, 120)
    portraitImage.Position = UDim2.new(0, 15, 0.5, -60)
    portraitImage.BackgroundColor3 = COLORS.BackgroundAlt
    portraitImage.BorderSizePixel = 0
    portraitImage.Image = ""
    portraitImage.ScaleType = Enum.ScaleType.Crop
    portraitImage.Visible = false
    portraitImage.Parent = dialogueFrame

    local portraitCorner = Instance.new("UICorner")
    portraitCorner.CornerRadius = UDim.new(0, 12)
    portraitCorner.Parent = portraitImage

    -- Text container
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -30, 1, -20)
    textContainer.Position = UDim2.new(0, 15, 0, 10)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = dialogueFrame

    -- Speaker name
    speakerLabel = Instance.new("TextLabel")
    speakerLabel.Name = "Speaker"
    speakerLabel.Size = UDim2.new(1, 0, 0, 28)
    speakerLabel.Position = UDim2.new(0, 0, 0, 0)
    speakerLabel.BackgroundTransparency = 1
    speakerLabel.Text = ""
    speakerLabel.TextColor3 = COLORS.Speaker
    speakerLabel.TextSize = 22
    speakerLabel.Font = Enum.Font.GothamBold
    speakerLabel.TextXAlignment = Enum.TextXAlignment.Left
    speakerLabel.Parent = textContainer

    -- Dialogue text
    textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, 0, 1, -40)
    textLabel.Position = UDim2.new(0, 0, 0, 32)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = ""
    textLabel.TextColor3 = COLORS.Text
    textLabel.TextSize = 20
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.Parent = textContainer

    -- Continue indicator
    continueIndicator = Instance.new("TextLabel")
    continueIndicator.Name = "ContinueIndicator"
    continueIndicator.Size = UDim2.new(0, 100, 0, 20)
    continueIndicator.Position = UDim2.new(1, -110, 1, -30)
    continueIndicator.BackgroundTransparency = 1
    continueIndicator.Text = "▼ Click to continue"
    continueIndicator.TextColor3 = COLORS.TextSecondary
    continueIndicator.TextSize = 14
    continueIndicator.Font = Enum.Font.Gotham
    continueIndicator.TextXAlignment = Enum.TextXAlignment.Right
    continueIndicator.Visible = false
    continueIndicator.Parent = dialogueFrame

    -- Choices container
    choicesFrame = Instance.new("Frame")
    choicesFrame.Name = "ChoicesFrame"
    choicesFrame.Size = UDim2.new(1, -30, 0, 0)
    choicesFrame.Position = UDim2.new(0, 15, 1, -10)
    choicesFrame.AnchorPoint = Vector2.new(0, 1)
    choicesFrame.BackgroundTransparency = 1
    choicesFrame.Visible = false
    choicesFrame.AutomaticSize = Enum.AutomaticSize.Y
    choicesFrame.Parent = dialogueFrame

    local choicesLayout = Instance.new("UIListLayout")
    choicesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    choicesLayout.Padding = UDim.new(0, 8)
    choicesLayout.Parent = choicesFrame

    -- Click to advance
    dialogueFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            if isTyping then
                skipRequested = true
            end
        end
    end)

    print("[DialogueBox] UI built")
end

--[[
    Show dialogue with configuration
]]
function DialogueBox.Show(config: DialogueConfig): ()
    if not screenGui then
        DialogueBox.Build()
    end

    screenGui = screenGui :: ScreenGui
    dialogueFrame = dialogueFrame :: Frame
    speakerLabel = speakerLabel :: TextLabel
    textLabel = textLabel :: TextLabel
    portraitImage = portraitImage :: ImageLabel
    continueIndicator = continueIndicator :: TextLabel
    choicesFrame = choicesFrame :: Frame

    isShowing = true
    screenGui.Enabled = true

    -- Set speaker
    speakerLabel.Text = config.speaker or ""
    speakerLabel.Visible = config.speaker ~= nil

    -- Set portrait
    if config.portrait then
        portraitImage.Image = config.portrait
        portraitImage.Visible = true
        -- Adjust text container position
    else
        portraitImage.Visible = false
    end

    -- Clear choices
    for _, child in choicesFrame:GetChildren() do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    choicesFrame.Visible = false

    -- Typewriter effect
    textLabel.Text = ""
    continueIndicator.Visible = false
    isTyping = true
    skipRequested = false
    currentText = config.text

    local typeSpeed = config.typeSpeed or 0.03

    for i = 1, #config.text do
        if skipRequested then
            textLabel.Text = config.text
            break
        end
        textLabel.Text = string.sub(config.text, 1, i)
        task.wait(typeSpeed)
    end

    textLabel.Text = config.text
    isTyping = false

    -- Show choices if provided
    if config.choices and #config.choices > 0 then
        DialogueBox.ShowChoices(config.choices)
    else
        continueIndicator.Visible = true

        -- Auto advance if configured
        if config.autoAdvance then
            task.wait(config.autoAdvanceDelay or 2)
            DialogueBox.Hide()
        end
    end
end

--[[
    Show choice buttons
]]
function DialogueBox.ShowChoices(choices: { { text: string, callback: () -> () } }): ()
    choicesFrame = choicesFrame :: Frame
    choicesFrame.Visible = true

    for i, choice in choices do
        local button = Instance.new("TextButton")
        button.Name = `Choice{i}`
        button.Size = UDim2.new(1, 0, 0, 40)
        button.BackgroundColor3 = COLORS.BackgroundAlt
        button.BorderSizePixel = 0
        button.Text = `{i}. {choice.text}`
        button.TextColor3 = COLORS.Text
        button.TextSize = 18
        button.Font = Enum.Font.GothamMedium
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.AutoButtonColor = false
        button.LayoutOrder = i
        button.Parent = choicesFrame

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button

        local buttonPadding = Instance.new("UIPadding")
        buttonPadding.PaddingLeft = UDim.new(0, 15)
        buttonPadding.Parent = button

        -- Hover effect
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {
                BackgroundColor3 = COLORS.Primary
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {
                BackgroundColor3 = COLORS.BackgroundAlt
            }):Play()
        end)

        button.MouseButton1Click:Connect(function()
            DialogueBox.Hide()
            choice.callback()
        end)
    end
end

--[[
    Hide the dialogue box
]]
function DialogueBox.Hide(): ()
    if screenGui then
        screenGui.Enabled = false
    end
    isShowing = false
end

--[[
    Check if dialogue is showing
]]
function DialogueBox.IsShowing(): boolean
    return isShowing
end

--[[
    Wait for dialogue to be dismissed
]]
function DialogueBox.WaitForDismiss(): ()
    while isShowing do
        task.wait(0.1)
    end
end

return DialogueBox
