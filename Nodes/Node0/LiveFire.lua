if TDS and TDS.RemoveIndex then pcall(function() TDS:RemoveIndex() end) end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local NetworkMod = require(ReplicatedStorage.Shared.Modules.Network)

local stateReplicators = ReplicatedStorage:WaitForChild("StateReplicators")
local rep = stateReplicators:WaitForChild("GameStateReplicator")

local function normalizeDialogText(value)
    value = tostring(value or "")
    value = value:gsub("<.->", "")
    value = value:gsub("%s+", " ")
    value = value:lower()
    return value
end

local function getDialogTextLabel()
    local dialog = PlayerGui:FindFirstChild("ReactOverridesDialog")
    local frame = dialog and dialog:FindFirstChild("Frame")
    local content = frame and frame:FindFirstChild("content")
    return content and content:FindFirstChild("dialogRichText") or nil
end

local function waitForDialogText(expectedText, timeoutSeconds)
    local wanted = normalizeDialogText(expectedText)
    local deadline = os.clock() + (timeoutSeconds or 90)

    while os.clock() < deadline do
        if rep:GetAttribute("GameOver") == true then
            return false
        end

        local textLabel = getDialogTextLabel()

        if textLabel then
            local current = normalizeDialogText(textLabel.Text)

            if current == wanted or current:find(wanted, 1, true) then
                return true
            end
        end

        task.wait(0.05)
    end

    return false
end

-- Chapter 0 Mission 2: Live Fire
-- Story already provides its own loadout.

local demomanDialog =
    "Boot camp isn’t over yet. Demoman is built for crowds—place him near the bend so every blast hits more than one target."

local demoman1Position = Vector3.new(
    42.55751037597656,
    -18.749990463256836,
    -13.660003662109375
)

local demoman2Position = Vector3.new(
    46.68422317504883,
    -18.749990463256836,
    -14.015838623046875
)

if not waitForDialogText(demomanDialog, 90) then
    return
end

pcall(function()
    NetworkMod.Channel("TutorialFlow"):FireServer(
        "PromptShown",
        "DemomanSelectionPromptShown"
    )
end)

task.wait(0.15)

pcall(function()
    NetworkMod.Channel("Hotbar"):FireServer("Click", 3)
end)

task.wait(0.15)

TDS:Place("Demoman", demoman1Position.X, demoman1Position.Y, demoman1Position.Z) -- 1
TDS:Upgrade(1)
TDS:Upgrade(1)

TDS:Place("Demoman", demoman2Position.X, demoman2Position.Y, demoman2Position.Z) -- 2
TDS:Upgrade(2)
