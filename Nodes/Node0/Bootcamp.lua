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

-- Chapter 0 Mission 1: Boot Camp
-- Story already provides its own loadout.

local scoutPosition = Vector3.new(
    43.767669677734375,
    -18.749990463256836,
    -11.349769592285156
)

local sniperPosition = Vector3.new(
    48.01165008544922,
    -13.720335006713867,
    14.519698143005371
)

if not waitForDialogText("Start by placing a scout.", 90) then
    return
end

pcall(function()
    NetworkMod.Channel("TutorialFlow"):FireServer(
        "PromptShown",
        "ScoutSelectionPromptShown"
    )
end)

task.wait(0.15)

pcall(function()
    NetworkMod.Channel("Hotbar"):FireServer("Click", 1)
end)

task.wait(0.15)

TDS:Place("Scout", scoutPosition.X, scoutPosition.Y, scoutPosition.Z) -- 1

if not waitForDialogText("Select the sniper tower.", 90) then
    return
end

pcall(function()
    NetworkMod.Channel("TutorialFlow"):FireServer(
        "PromptShown",
        "SniperSelectionPromptShown"
    )
end)

task.wait(0.15)

pcall(function()
    NetworkMod.Channel("Hotbar"):FireServer("Click", 2)
end)

task.wait(0.15)

TDS:Place("Sniper", sniperPosition.X, sniperPosition.Y, sniperPosition.Z) -- 2

local scoutUpgradeDeadline = os.clock() + 45

while os.clock() < scoutUpgradeDeadline do
    if rep:GetAttribute("AllowedUpgradeTower") == "Scout"
        and rep:GetAttribute("AllowedUpgradeType") == "Upgrade" then
        break
    end

    if rep:GetAttribute("GameOver") == true then
        return
    end

    task.wait(0.1)
end

pcall(function()
    NetworkMod.Channel("TutorialFlow"):FireServer(
        "PromptShown",
        "ScoutUpgradePromptShown"
    )
end)

task.wait(0.3)
TDS:Upgrade(1)
TDS:Upgrade(1)

local sniperUpgradeDeadline = os.clock() + 45

while os.clock() < sniperUpgradeDeadline do
    if rep:GetAttribute("AllowedUpgradeTower") == "Sniper"
        and rep:GetAttribute("AllowedUpgradeType") == "Upgrade" then
        break
    end

    if rep:GetAttribute("GameOver") == true then
        return
    end

    task.wait(0.1)
end

pcall(function()
    NetworkMod.Channel("TutorialFlow"):FireServer(
        "PromptShown",
        "SniperUpgradePromptShown"
    )
end)

task.wait(0.3)
TDS:Upgrade(2)
TDS:Upgrade(2)
