--[[
    CombinedData
    Description:
        Provides a single API that merges Tower Ownership, Golden Skin/Perks detection,
        Tower EXP progression, Skill‑tree extraction, and Player Stats (Level/EXP/Coins/Gems).
        • Accurate Golden tower ownership (checks Inventory.Skins, not just equipped state).
        • Active Golden perks detector (checks if perk is enabled in loadout).
        • Full Tower EXP progression for all 8 towers (progress, required, max level, uncapped).
        • Fast Cache-based Player Stats: Values.Level, Values.Experience, Experience(level + 1),
          Values.Coins, and Values.Gems with safe fallback layers.
        • Skill‑tree extraction from Workspace["1"] … Workspace["17"].
        • Lightweight, synchronous, and safe for mobile/third-party executors.
]]--

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- ---------------------------------------------------------------------
-- Core helpers (LocalPlayer, PlayerGui, number parsing)
-- ---------------------------------------------------------------------
local function getLocalPlayer()
    local lp = Players.LocalPlayer
    if not lp then
        pcall(function()
            Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end)
        lp = Players.LocalPlayer
    end
    return lp
end

local function getPlayerGui(timeout)
    timeout = timeout or 1
    local lp = getLocalPlayer()
    if not lp then return nil end
    local pgui = lp:FindFirstChild("PlayerGui")
    if not pgui and timeout > 0 then
        pgui = lp:WaitForChild("PlayerGui", timeout)
    end
    return pgui
end

local function parseNumber(str)
    if not str then return 0 end
    local cleaned = tostring(str):gsub("<[^>]+>", ""):match("[%d,]+")
    cleaned = cleaned and cleaned:gsub("%D", "") or ""
    return tonumber(cleaned) or 0
end

-- ---------------------------------------------------------------------
-- Internal Cache & Game Module Access
-- ---------------------------------------------------------------------
local Cache = nil
local Experience = nil
local TowerExpUtil = nil
local Content = nil
local InventoryController = nil
local MatchmakingTrialData = nil

pcall(function()
    Cache = require(ReplicatedStorage.Client.Modules.Cache)
end)
pcall(function()
    Experience = require(ReplicatedStorage.Shared.Modules.Experience)
end)
pcall(function()
    TowerExpUtil = require(ReplicatedStorage.Shared.Modules.TowerExpUtil)
end)
pcall(function()
    Content = require(ReplicatedStorage.Shared.Modules.Content)
end)
pcall(function()
    InventoryController = require(ReplicatedStorage.Client.Interfaces.LegacyInterface.Controllers.InventoryController)
end)
pcall(function()
    MatchmakingTrialData = require(ReplicatedStorage.Client.Interfaces.Lobby.Components.NewMatchmaking.MatchmakingTrialData)
end)

local StoryModeClient = nil
local StoryModeSerialization = nil
local inMemoryStoryProgress = nil

getgenv().AutoProg_LastKnownStats = getgenv().AutoProg_LastKnownStats or {}
local statsEnv = getgenv().AutoProg_LastKnownStats

local function getStoryModeClient()
    if not StoryModeClient then
        pcall(function()
            local client = ReplicatedStorage:FindFirstChild("Client")
            local modules = client and client:FindFirstChild("Modules")
            local smc = modules and modules:FindFirstChild("StoryModeClient")
            if smc then
                StoryModeClient = require(smc)
            end
        end)
    end
    return StoryModeClient
end

local function getStoryModeSerialization()
    if not StoryModeSerialization then
        pcall(function()
            local shared = ReplicatedStorage:FindFirstChild("Shared")
            local modules = shared and shared:FindFirstChild("Modules")
            local sms = modules and modules:FindFirstChild("StoryModeSerialization")
            if sms then
                StoryModeSerialization = require(sms)
            end
        end)
    end
    return StoryModeSerialization
end

local PlayerStatsStore = nil
local function getPlayerStatsStore()
    if not PlayerStatsStore then
        pcall(function()
            local client = ReplicatedStorage:FindFirstChild("Client")
            local ifaces = client and client:FindFirstChild("Interfaces")
            local stores = ifaces and ifaces:FindFirstChild("Stores")
            local shared = stores and stores:FindFirstChild("Shared")
            local pss = shared and shared:FindFirstChild("PlayerStatsStore")
            if pss then
                PlayerStatsStore = require(pss)
            end
        end)
    end
    return PlayerStatsStore
end
getPlayerStatsStore()

-- Helper to safely get value even if still downloading on fresh join
local function getStat(name)
    if not Cache then
        pcall(function()
            local cModule = ReplicatedStorage:FindFirstChild("Client")
            cModule = cModule and cModule:FindFirstChild("Modules")
            cModule = cModule and cModule:FindFirstChild("Cache")
            if cModule then
                Cache = require(cModule)
            end
        end)
    end
    if Cache and (type(Cache) == "table" or type(Cache) == "function") then
        local ok, val = pcall(function()
            local atom = Cache(name)
            if atom then
                -- 1. Check synchronous cached value first
                if type(atom.GetValue) == "function" then
                    local fastVal = atom:GetValue()
                    if fastVal ~= nil then
                        return fastVal
                    end
                end
                -- 2. If nil (e.g. freshly joined lobby), fetch and await the cache promise
                if type(atom.Get) == "function" then
                    local promise = atom:Get()
                    if promise and type(promise.await) == "function" then
                        local pSuccess, pResult = promise:await()
                        if setthreadidentity then pcall(setthreadidentity, 8) end
                        if pSuccess and pResult ~= nil then
                            return pResult
                        end
                    end
                end
            end
            return nil
        end)
        if setthreadidentity then pcall(setthreadidentity, 8) end
        if ok and val ~= nil then
            return val
        end
    end
    return nil
end

local function getCacheValue(cacheName)
    return getStat(cacheName)
end

-- ---------------------------------------------------------------------
-- Main Module Definition
-- ---------------------------------------------------------------------
local CombinedData = {}
CombinedData.__index = CombinedData

local SkillTreeData = {
    [1] = { Name = "Enhanced Optics" },
    [2] = { Name = "Resourcefulness" },
    [3] = { Name = "Fortify" },
    [4] = { Name = "Over-Heal" },
    [5] = { Name = "Fight Dirty" },
    [6] = { Name = "Extreme Conditioning" },
    [7] = { Name = "Stonks" },
    [8] = { Name = "Expanded Barracks" },
    [9] = { Name = "Improved Gunpowder" },
    [10] = { Name = "Beefed Up Minions" },
    [11] = { Name = "Precision" },
    [12] = { Name = "Scavenger" },
    [13] = { Name = "Accelerator" },
    [14] = { Name = "Re-enforcements" },
    [15] = { Name = "Bigger Budget" },
    [16] = { Name = "Bandages" },
    [17] = { Name = "Scholar" },
}

CombinedData.SkillTreeData = SkillTreeData

-- List of all 8 towers with progression systems
CombinedData.ProgressionTowers = {
    "Scout",
    "Shotgunner",
    "Crook Boss",
    "Minigunner",
    "EvolvedOperator",
    "EvolvedEnforcer",
    "EvolvedKingpin",
    "EvolvedJuggernaut"
}

-- ---------------------------------------------------------------------
-- Tower Ownership (Cache -> InventoryController -> UI Scan)
-- ---------------------------------------------------------------------
local function getScrollingContainer(idx)
    local pgui = getPlayerGui()
    if not pgui then return nil end
    local path = {
        "ReactUniversalInventoryView",
        "Holder",
        "windowFrame",
        "towersInventoryFrame",
        "towerContainer",
        idx .. "scrolling"
    }
    local node = pgui
    for _, childName in ipairs(path) do
        node = node:FindFirstChild(childName)
        if not node then return nil end
    end
    return node
end

function CombinedData:IsTowerOwned(towerName)
    if not towerName or towerName == "" then return false end

    -- 1. Fast Cache Check
    local troops = getCacheValue("Inventory.Troops")
    if troops and type(troops) == "table" then
        if troops[towerName] ~= nil then
            return true
        end
    end

    -- 2. InventoryController Check
    if InventoryController and type(InventoryController.getItems) == "function" then
        local success, items = pcall(function() return InventoryController:getItems() end)
        if success and items then
            for _, item in pairs(items) do
                if type(item) == "table" and item.type == "tower" and item.name == towerName then
                    return true
                end
            end
        end
    end

    -- 3. UI Scrolling Container Fallback
    for i = 1, 7 do
        local container = getScrollingContainer(i)
        if container then
            local towerNode = container:FindFirstChild(towerName)
            if towerNode then
                local main = towerNode:FindFirstChild("main")
                if main and main:FindFirstChild("amountLeft") then
                    return true
                end
            end
        end
    end

    return false
end

-- ---------------------------------------------------------------------
-- Golden Towers Ownership & Active Perks
-- ---------------------------------------------------------------------

--- Checks if the player OWNS the Golden version of a tower (even if another skin is equipped)
function CombinedData:IsGoldenOwned(towerName)
    if not towerName or towerName == "" then return false end

    -- 1. Check Inventory.Skins (Direct ownership list)
    local skins = getCacheValue("Inventory.Skins")
    if skins and type(skins) == "table" and skins[towerName] then
        for _, skin in ipairs(skins[towerName]) do
            if type(skin) == "table" and skin.Name == "Golden" then
                return true
            end
        end
    end

    -- 2. Check Inventory.Troops (Equipped / Perk state)
    local troops = getCacheValue("Inventory.Troops")
    if troops and type(troops) == "table" and troops[towerName] then
        local tData = troops[towerName]
        if tData.GoldenPerks == true or tData.Skin == "Golden" then
            return true
        end
    end

    -- 3. InventoryController Fallback
    if InventoryController and type(InventoryController.getItems) == "function" then
        local success, items = pcall(function() return InventoryController:getItems() end)
        if success and items then
            for _, item in pairs(items) do
                if type(item) == "table" and item.type == "tower" and item.name == towerName then
                    if item.golden == true or item.skin == "Golden" then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--- Returns a list and a set of all Golden Towers owned by the player
function CombinedData:GetGoldenOwned()
    local list = {}
    local set = {}

    local skins = getCacheValue("Inventory.Skins")
    if skins and type(skins) == "table" then
        for tower, skinList in pairs(skins) do
            if type(skinList) == "table" then
                for _, skin in ipairs(skinList) do
                    if type(skin) == "table" and skin.Name == "Golden" then
                        table.insert(list, tower)
                        set[tower] = true
                        break
                    end
                end
            end
        end
    end

    local troops = getCacheValue("Inventory.Troops")
    if troops and type(troops) == "table" then
        for tower, data in pairs(troops) do
            if not set[tower] and type(data) == "table" and (data.GoldenPerks == true or data.Skin == "Golden") then
                table.insert(list, tower)
                set[tower] = true
            end
        end
    end

    table.sort(list)
    return list, set
end

--- Checks if a tower currently has its Golden Perk toggled ON
function CombinedData:IsGoldenPerkActive(towerName)
    if not towerName or towerName == "" then return false end

    local troops = getCacheValue("Inventory.Troops")
    if troops and type(troops) == "table" and troops[towerName] then
        return troops[towerName].GoldenPerks == true
    end

    if InventoryController and type(InventoryController.getItems) == "function" then
        local success, items = pcall(function() return InventoryController:getItems() end)
        if success and items then
            for _, item in pairs(items) do
                if type(item) == "table" and item.type == "tower" and item.name == towerName then
                    return item.golden == true
                end
            end
        end
    end

    return false
end

--- Returns a list of all towers that currently have Golden Perks enabled
function CombinedData:GetActiveGoldenPerks()
    local activeList = {}
    local troops = getCacheValue("Inventory.Troops")
    if troops and type(troops) == "table" then
        for tower, data in pairs(troops) do
            if type(data) == "table" and data.GoldenPerks == true then
                table.insert(activeList, tower)
            end
        end
    end
    table.sort(activeList)
    return activeList
end

-- ---------------------------------------------------------------------
-- Tower EXP & Progression System
-- ---------------------------------------------------------------------
local function calculateExpStats(currentExp, baseExp, growthRate, maxLevel)
    currentExp = currentExp or 0
    baseExp = baseExp or 50
    growthRate = growthRate or 1.09
    maxLevel = maxLevel or 20

    local totalRequiredForMax = 0
    local levelCosts = {}
    for i = 1, maxLevel do
        local cost = math.floor(baseExp * (growthRate ^ (i - 1)))
        totalRequiredForMax = totalRequiredForMax + cost
        levelCosts[i] = cost
    end

    local sum = 0
    local cappedLevel = 0
    for i = 1, maxLevel do
        sum = sum + levelCosts[i]
        if currentExp < sum then break end
        cappedLevel = i
    end

    local totalExpCurrentLevel = 0
    for i = 1, cappedLevel do
        totalExpCurrentLevel = totalExpCurrentLevel + levelCosts[i]
    end

    local nextLevelCost = 0
    if cappedLevel < maxLevel then
        nextLevelCost = math.floor(baseExp * (growthRate ^ cappedLevel))
    else
        nextLevelCost = levelCosts[maxLevel] or 0
    end

    local currentProgress = math.max(currentExp - totalExpCurrentLevel, 0)
    local isMax = cappedLevel >= maxLevel
    if isMax then
        currentProgress = nextLevelCost
    end

    local uncappedSum = 0
    local uncappedLevel = 0
    while true do
        local cost = math.floor(baseExp * (growthRate ^ uncappedLevel))
        if currentExp < uncappedSum + cost then break end
        uncappedSum = uncappedSum + cost
        uncappedLevel = uncappedLevel + 1
    end

    local progressDisplay = ""
    if isMax then
        progressDisplay = string.format("MAX (%d EXP)", currentExp)
    else
        progressDisplay = string.format("%d / %d EXP", currentProgress, nextLevelCost)
    end

    local overallDisplay = string.format("%d / %d EXP", currentExp, totalRequiredForMax)

    return {
        level = cappedLevel,
        uncappedLevel = uncappedLevel,
        totalRequiredForMax = totalRequiredForMax,
        currentProgress = currentProgress,
        nextLevelCost = nextLevelCost,
        progressDisplay = progressDisplay,
        overallDisplay = overallDisplay,
        isMax = isMax
    }
end

function CombinedData:GetTowerExp(towerName)
    if not towerName or towerName == "" then return nil end

    local expCache = getCacheValue("TowerExp") or {}
    local currentExp = expCache[towerName] or 0

    local baseExp = 50
    local growthRate = 1.09
    local maxLevel = 20
    local evolvedTo = nil

    if Content then
        local ok, towerFolder = pcall(Content, "Tower")
        if ok and towerFolder then
            local towerInst = towerFolder:FindFirstChild(towerName)
            local stats = towerInst and towerInst:FindFirstChild("Stats")
            if stats and stats:IsA("ModuleScript") then
                local success, mod = pcall(require, stats)
                if success and mod and mod.Properties and mod.Properties.Progression then
                    local prog = mod.Properties.Progression
                    baseExp = prog.BaseExp or baseExp
                    growthRate = prog.GrowthRate or growthRate
                    maxLevel = prog.MaxLevel or maxLevel
                    evolvedTo = mod.Properties.EvolvedTo
                end
            end
        end
    end

    local statsData = calculateExpStats(currentExp, baseExp, growthRate, maxLevel)

    return {
        Name = tostring(towerName),
        Exp = currentExp,
        Level = statsData.level,
        MaxLevel = maxLevel,
        MaxExp = statsData.totalRequiredForMax,
        CurrentProgress = statsData.currentProgress,
        RequiredForNext = statsData.nextLevelCost,
        ProgressDisplay = statsData.progressDisplay or tostring(currentExp),
        OverallDisplay = statsData.overallDisplay or tostring(currentExp),
        UncappedLevel = statsData.uncappedLevel,
        IsMaxLevel = statsData.isMax,
        EvolvedTo = evolvedTo
    }
end

function CombinedData:GetAllTowerExp()
    local result = {}
    for _, towerName in ipairs(self.ProgressionTowers) do
        local data = self:GetTowerExp(towerName)
        if data then
            table.insert(result, data)
        end
    end
    table.sort(result, function(a, b) return a.Name < b.Name end)
    return result
end

function CombinedData:FormatTowerExp(towerName)
    local data = self:GetTowerExp(towerName)
    if not data then return tostring(towerName) .. ": Not found" end

    local evoText = data.EvolvedTo and (" -> Evolves to " .. data.EvolvedTo) or ""
    if data.IsMaxLevel then
        local uncapped = (data.UncappedLevel > data.MaxLevel) and string.format(" [Uncapped Lvl %d]", data.UncappedLevel) or ""
        return string.format("%-18s: Level %2d/%2d [MAX] | Total: %6d / %4d EXP%s%s",
            data.Name, data.Level, data.MaxLevel, data.Exp, data.MaxExp, uncapped, evoText)
    else
        return string.format("%-18s: Level %2d/%2d (%s to Lvl %d) | Total: %6d / %4d EXP%s",
            data.Name, data.Level, data.MaxLevel, data.ProgressDisplay, data.Level + 1, data.Exp, data.MaxExp, evoText)
    end
end

-- ---------------------------------------------------------------------
-- Coins / Gems / Level / Player EXP (Values.* Cache with Fallbacks)
-- ---------------------------------------------------------------------
local function getLobbyHud()
    local pgui = getPlayerGui(2)
    if not pgui then return nil end
    return pgui:FindFirstChild("ReactLobbyHud") or pgui:WaitForChild("ReactLobbyHud", 2)
end

function CombinedData:GetLevel()
    -- 1. Check PlayerStatsStore (Primary Live Store in Charm)
    local pss = getPlayerStatsStore()
    if pss and type(pss.getLevel) == "function" then
        local ok, lvl = pcall(pss.getLevel)
        if ok and lvl ~= nil and tonumber(lvl) and tonumber(lvl) > 0 then
            return tonumber(lvl), tostring(lvl)
        end
    end

    -- 2. Direct Cache lookup (Values.Level)
    local lvl = getStat("Values.Level")
    if lvl ~= nil and tonumber(lvl) then
        return tonumber(lvl), tostring(lvl)
    end

    -- 3. Fallback: Lobby HUD TextLabel
    local hud = getLobbyHud()
    if hud then
        local curLvl = hud:FindFirstChild("currentLevel", true)
            or (hud:FindFirstChild("Frame", true) and hud.Frame:FindFirstChild("centerElements", true) and hud.Frame.centerElements:FindFirstChild("level", true) and hud.Frame.centerElements.level:FindFirstChild("content", true) and hud.Frame.centerElements.level.content:FindFirstChild("currentLevel", true))

        if curLvl and curLvl:IsA("TextLabel") then
            local txt = curLvl.Text
            return parseNumber(txt), txt
        end
    end

    -- 4. Fallback: LocalPlayer ValueBase
    local lp = getLocalPlayer()
    if lp then
        local val = lp:FindFirstChild("Level")
        if val and val:IsA("ValueBase") then
            local v = val.Value
            return tonumber(v) or parseNumber(v), tostring(v)
        end
    end

    return 0, "0"
end

function CombinedData:GetCoins()
    -- 1. Check PlayerStatsStore (Primary Live Store in Charm)
    local pss = getPlayerStatsStore()
    if pss and type(pss.getCoins) == "function" then
        local ok, coins = pcall(pss.getCoins)
        if ok and coins ~= nil and tonumber(coins) then
            return tonumber(coins), tostring(coins)
        end
    end

    -- 2. Direct Cache lookup (Values.Coins)
    local coins = getStat("Values.Coins")
    if coins ~= nil and tonumber(coins) then
        return tonumber(coins), tostring(coins)
    end

    -- 3. Fallback: Lobby HUD TextLabel
    local hud = getLobbyHud()
    if hud then
        local path = {"Frame", "leftElements", "currencies", "coins", "content", "currency", "currencyValue"}
        local node = hud
        for _, child in ipairs(path) do
            node = node:FindFirstChild(child, true) or (node and node:FindFirstChild(child))
            if not node then break end
        end
        if node and node:IsA("TextLabel") then
            local txt = node.Text
            return parseNumber(txt), txt
        end
    end

    -- 4. Fallback: LocalPlayer ValueBase
    local lp = getLocalPlayer()
    if lp then
        local val = lp:FindFirstChild("Coins") or lp:FindFirstChild("Gold")
        if val and val:IsA("ValueBase") then
            local v = val.Value
            return tonumber(v) or parseNumber(v), tostring(v)
        end
    end

    return 0, "0"
end

function CombinedData:GetGems()
    -- 1. Check PlayerStatsStore (Primary Live Store in Charm)
    local pss = getPlayerStatsStore()
    if pss and type(pss.getGems) == "function" then
        local ok, gems = pcall(pss.getGems)
        if ok and gems ~= nil and tonumber(gems) then
            return tonumber(gems), tostring(gems)
        end
    end

    -- 2. Direct Cache lookup (Values.Gems)
    local gems = getStat("Values.Gems")
    if gems ~= nil and tonumber(gems) then
        return tonumber(gems), tostring(gems)
    end

    -- 3. Fallback: Lobby HUD TextLabel
    local hud = getLobbyHud()
    if hud then
        local path = {"Frame", "leftElements", "currencies", "gems", "content", "currency", "currencyValue"}
        local node = hud
        for _, child in ipairs(path) do
            node = node:FindFirstChild(child, true) or (node and node:FindFirstChild(child))
            if not node then break end
        end
        if node and node:IsA("TextLabel") then
            local txt = node.Text
            return parseNumber(txt), txt
        end
    end

    -- 4. Fallback: LocalPlayer ValueBase
    local lp = getLocalPlayer()
    if lp then
        local val = lp:FindFirstChild("Gems") or lp:FindFirstChild("Diamonds")
        if val and val:IsA("ValueBase") then
            local v = val.Value
            return tonumber(v) or parseNumber(v), tostring(v)
        end
    end

    return 0, "0"
end

function CombinedData:GetTimescaleTickets()
    -- 1. Check PlayerStatsStore (Primary Live Store in Charm)
    local pss = getPlayerStatsStore()
    if pss and type(pss.getTimescaleTickets) == "function" then
        local ok, tickets = pcall(pss.getTimescaleTickets)
        if ok and tickets ~= nil and tonumber(tickets) then
            return tonumber(tickets), tostring(tickets)
        end
    end
    if pss and type(pss.getState) == "function" then
        local ok, state = pcall(pss.getState, pss)
        if ok and type(state) == "table" and state.timescaletickets ~= nil then
            local val = tonumber(state.timescaletickets)
            if val then return val, tostring(val) end
        end
    end

    -- 2. Direct Cache lookup (Values.TimescaleTickets)
    local tickets = getStat("Values.TimescaleTickets")
    if tickets ~= nil and tonumber(tickets) then
        return tonumber(tickets), tostring(tickets)
    end

    -- 3. Fallback: LocalPlayer ValueBase
    local lp = getLocalPlayer()
    if lp then
        local val = lp:FindFirstChild("TimescaleTickets")
        if val and val:IsA("ValueBase") then
            local v = val.Value
            return tonumber(v) or parseNumber(v), tostring(v)
        end
    end

    return 0, "0"
end

--- Returns current player EXP, required EXP for next level, and formatted string
function CombinedData:GetPlayerExp()
    -- 1. Check PlayerStatsStore (Primary Live Store in Charm)
    local exp = nil
    local pss = getPlayerStatsStore()
    if pss and type(pss.getExperience) == "function" then
        local ok, e = pcall(pss.getExperience)
        if ok and e ~= nil and tonumber(e) then
            exp = tonumber(e)
        end
    end

    -- 2. Direct Cache lookup (Values.Experience)
    if exp == nil then
        local cachedExp = getStat("Values.Experience")
        if cachedExp ~= nil and tonumber(cachedExp) then
            exp = tonumber(cachedExp)
        end
    end

    -- 3. Fallback: LocalPlayer ValueBase
    if exp == nil then
        local lp = getLocalPlayer()
        if lp then
            local val = lp:FindFirstChild("Experience")
            if val and val:IsA("ValueBase") then
                exp = tonumber(val.Value)
            end
        end
    end

    exp = exp or 0

    local level = self:GetLevel() or 0
    local nextLevelExp = 0

    if not Experience then
        pcall(function()
            Experience = require(ReplicatedStorage.Shared.Modules.Experience)
        end)
    end

    if Experience then
        local ok, nExp = pcall(Experience, level + 1)
        if ok and nExp then
            nextLevelExp = nExp
        end

        -- Seamless rollover when EXP reaches or exceeds level threshold (e.g. 1524/1520 -> Lvl +1, 4/1522)
        while nextLevelExp and nextLevelExp > 0 and exp >= nextLevelExp do
            level = level + 1
            exp = exp - nextLevelExp
            local okNext, higherExp = pcall(Experience, level + 1)
            if okNext and higherExp then
                nextLevelExp = higherExp
            else
                break
            end
        end
    end

    return exp, nextLevelExp, string.format("%d / %d", exp, nextLevelExp), level
end

--- Returns a table containing Level, EXP, NextLevelExp, Coins, Gems, and TimescaleTickets
function CombinedData:GetPlayerStats()
    local exp, nextLevelExp, expDisplay, normalizedLevel = self:GetPlayerExp()
    local level = normalizedLevel or self:GetLevel()
    local coins = self:GetCoins()
    local gems = self:GetGems()
    local timescaleTickets = self:GetTimescaleTickets()

    return {
        Level = level,
        Exp = exp,
        NextLevelExp = nextLevelExp,
        ExpDisplay = expDisplay,
        Coins = coins,
        Gems = gems,
        TimescaleTickets = timescaleTickets,
    }
end

--- Returns the required XP for a specific level using official Experience module or mathematical formula
function CombinedData:GetRequiredExpForLevel(lvl)
    lvl = tonumber(lvl) or 1
    if Experience then
        local ok, nExp = pcall(Experience, lvl)
        if ok and type(nExp) == "number" and nExp > 0 then
            return nExp
        end
    end
    local v1 = 10 + 35 * (1 + lvl / 10)
    if 40 < lvl then
        v1 = 245 + 15 * (1 + lvl / 10)
    elseif 10 < lvl then
        v1 = -80 + 80 * (1 + lvl / 10)
    end
    return math.floor(v1 + 0.5)
end

--- Calculates XP progression towards a target level.
-- Computes total cumulative account EXP earned vs total cumulative EXP required for targetLevel.
-- @param targetLevel number Target level (0 = infinite / next level only)
-- @param currentLevel number? Optional (defaults to current player level)
-- @param currentExp number? Optional (defaults to current player EXP)
-- @return table info Detailed progress table
function CombinedData:GetTargetLevelProgress(targetLevel, currentLevel, currentExp)
    currentLevel = tonumber(currentLevel) or (self:GetLevel() or 0)
    if currentExp == nil then
        local liveExp = self:GetPlayerExp()
        currentExp = liveExp or 0
    else
        currentExp = tonumber(currentExp) or 0
    end
    targetLevel = tonumber(targetLevel) or 0

    local nextLevelReq = self:GetRequiredExpForLevel(currentLevel + 1)
    local nextLevelRem = math.max(0, nextLevelReq - currentExp)

    if targetLevel <= 0 then
        return {
            CurrentLevel = currentLevel,
            TargetLevel = 0,
            CurrentExp = currentExp,
            NextLevelReq = nextLevelReq,
            NextLevelRem = nextLevelRem,
            TotalEarnedExp = currentExp,
            TotalTargetExp = 0,
            TotalRemaining = 0,
            Percent = 1,
            IsReached = false,
            Display = string.format("Level: %d / 0 | Requires: %d / 0", currentLevel, currentExp)
        }
    end

    -- 1. Calculate total EXP required to reach targetLevel from level 0
    local totalTargetExp = 0
    for lvl = 1, targetLevel do
        totalTargetExp = totalTargetExp + self:GetRequiredExpForLevel(lvl)
    end

    -- 2. Calculate total EXP earned so far across account (levels 1 to currentLevel + currentExp)
    local totalEarnedExp = 0
    for lvl = 1, currentLevel do
        totalEarnedExp = totalEarnedExp + self:GetRequiredExpForLevel(lvl)
    end
    totalEarnedExp = totalEarnedExp + currentExp

    local totalRemaining = math.max(0, totalTargetExp - totalEarnedExp)
    local percent = (totalTargetExp > 0) and math.clamp(totalEarnedExp / totalTargetExp, 0, 1) or 1
    local levelsLeft = math.max(0, targetLevel - currentLevel)

    return {
        CurrentLevel = currentLevel,
        CurrentExp = currentExp,
        TargetLevel = targetLevel,
        LevelsLeft = levelsLeft,
        TotalEarnedExp = totalEarnedExp,
        TotalTargetExp = totalTargetExp,
        TotalRemaining = totalRemaining,
        Percent = percent,
        NextLevelReq = nextLevelReq,
        NextLevelRem = nextLevelRem,
        IsReached = currentLevel >= targetLevel,
        Display = string.format("Level: %d / %d | Requires: %d / %d", currentLevel, targetLevel, totalEarnedExp, totalTargetExp)
    }
end

function CombinedData:GetExpToTarget(targetLevel, currentLevel, currentExp)
    local data = self:GetTargetLevelProgress(targetLevel, currentLevel, currentExp)
    return data.TotalRemaining, data.NextLevelRem, data.NextLevelReq, data
end

-- ---------------------------------------------------------------------
-- Skill‑tree extraction
-- ---------------------------------------------------------------------
local skillTreeCacheFile = "ProjectOptimazation/CachedSkillTree.json"
local inMemorySkillTreeCache = {}

function CombinedData:GetSkillTree()
    local list = {}
    for i = 1, 17 do
        local tile = Workspace:FindFirstChild(tostring(i))
        if tile then
            local surfaceGui = tile:FindFirstChild("TileSurfaceGui")
            if surfaceGui then
                local frame = surfaceGui:FindFirstChild("Frame")
                if frame then
                    local nameLabel  = frame:FindFirstChild("SkillName")
                    local levelLabel = frame:FindFirstChild("SkillLevel")

                    local name = nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text or ("Skill #" .. i)
                    local lvlStr = levelLabel and levelLabel:IsA("TextLabel") and levelLabel.Text or "0"

                    local formattedLvl = lvlStr
                    local numericLvl = parseNumber(lvlStr)
                    local maxLvl = nil
                    local isMaxed = false

                    local curMatch, maxMatch = lvlStr:match("(%d+)%s*/%s*(%d+)")
                    if curMatch and maxMatch then
                        numericLvl = tonumber(curMatch) or numericLvl
                        maxLvl = tonumber(maxMatch)
                        if numericLvl >= maxLvl then
                            isMaxed = true
                        end
                    end

                    if string.upper(lvlStr):find("MAX") then
                        isMaxed = true
                        local numInFmt = string.upper(lvlStr):match("(%d+)")
                        if numInFmt then
                            maxLvl = tonumber(numInFmt) or maxLvl
                            if numericLvl == 0 or numericLvl < (maxLvl or 0) then
                                numericLvl = maxLvl or numericLvl
                            end
                        end
                        formattedLvl = "MAX" .. (numericLvl > 0 and numericLvl or "")
                    end

                    table.insert(list, {
                        Id = tostring(i),
                        Name = name,
                        Level = numericLvl,
                        MaxLevel = maxLvl,
                        IsMaxed = isMaxed,
                        LevelFormatted = formattedLvl,
                    })
                end
            end
        end
    end

    if #list > 0 then
        inMemorySkillTreeCache = list
        pcall(function()
            if writefile and HttpService then
                local encoded = HttpService:JSONEncode(list)
                pcall(writefile, "[SomethingNew]/userskilltree.json", encoded)
                pcall(writefile, "userskilltree.json", encoded)
                pcall(writefile, "[ATF]/CachedSkillTree.json", encoded)
                pcall(writefile, skillTreeCacheFile, encoded)
            end
        end)
        return list
    end

    if #inMemorySkillTreeCache > 0 then
        return inMemorySkillTreeCache
    end

    local cacheCandidates = {
        "[SomethingNew]/userskilltree.json",
        "[SomethingNew]\\userskilltree.json",
        "userskilltree.json",
        "[ATF]/CachedSkillTree.json",
        "[ATF]\\CachedSkillTree.json",
        skillTreeCacheFile,
        "ProjectOptimazation\\CachedSkillTree.json",
    }
    pcall(function()
        if not (isfile and readfile and HttpService) then return end
        for _, path in ipairs(cacheCandidates) do
            local ok, exists = pcall(isfile, path)
            if ok and exists then
                local rOk, raw = pcall(readfile, path)
                if rOk and raw and raw ~= "" then
                    local dOk, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
                    if dOk and type(decoded) == "table" and #decoded > 0 then
                        inMemorySkillTreeCache = decoded
                        break
                    end
                end
            end
        end
    end)

    return inMemorySkillTreeCache
end

-- ---------------------------------------------------------------------
-- Requirements Validation API
-- ---------------------------------------------------------------------
function CombinedData:CheckRequirements(requirements)
    local missing = {}
    local passed = true

    -- 1. Check Player Level
    if requirements.Level then
        local currentLevel = self:GetLevel()
        if currentLevel < requirements.Level then
            passed = false
            table.insert(missing, string.format("Level: required %d, current %d", requirements.Level, currentLevel))
        end
    end

    -- 2. Check Skill Tree (supports both .Skill and .SkillTree)
    local skillReqs = requirements.SkillTree or requirements.Skill
    if skillReqs and type(skillReqs) == "table" then
        local currentSkills = {}
        for _, skill in ipairs(self:GetSkillTree()) do
            currentSkills[skill.Name] = skill.Level
        end

        for skillName, requiredLvl in pairs(skillReqs) do
            local currentLvl = currentSkills[skillName] or 0
            if currentLvl < requiredLvl then
                passed = false
                table.insert(missing, string.format("Skill '%s': required level %d, current %d", skillName, requiredLvl, currentLvl))
            end
        end
    end

    -- 3. Check Coins
    if requirements.Coins then
        local currentCoins = self:GetCoins()
        if currentCoins < requirements.Coins then
            passed = false
            table.insert(missing, string.format("Coins: required %d, current %d", requirements.Coins, currentCoins))
        end
    end

    -- 4. Check Gems
    if requirements.Gems then
        local currentGems = self:GetGems()
        if currentGems < requirements.Gems then
            passed = false
            table.insert(missing, string.format("Gems: required %d, current %d", requirements.Gems, currentGems))
        end
    end

    -- 5. Check Towers Owned
    if requirements.Towers and type(requirements.Towers) == "table" then
        for _, towerName in ipairs(requirements.Towers) do
            if not self:IsTowerOwned(towerName) then
                passed = false
                table.insert(missing, string.format("Missing Tower: %s", towerName))
            end
        end
    end

    -- 6. Check Golden Towers Owned
    if requirements.Golden and type(requirements.Golden) == "table" then
        for _, towerName in ipairs(requirements.Golden) do
            if not self:IsGoldenOwned(towerName) then
                passed = false
                table.insert(missing, string.format("Golden %s - not owned", towerName))
            end
        end
    end

    -- 7. Check Tower EXP / Levels
    if requirements.TowerExp and type(requirements.TowerExp) == "table" then
        for towerName, req in pairs(requirements.TowerExp) do
            local data = self:GetTowerExp(towerName)
            local currentExp = data and data.Exp or 0
            local currentLvl = data and data.Level or 0

            if type(req) == "number" then
                if currentExp < req then
                    passed = false
                    table.insert(missing, string.format("%s EXP: required %d, current %d", towerName, req, currentExp))
                end
            elseif type(req) == "table" then
                if req.Level and currentLvl < req.Level then
                    passed = false
                    table.insert(missing, string.format("%s Level: required %d, current %d", towerName, req.Level, currentLvl))
                end
                if req.Exp and currentExp < req.Exp then
                    passed = false
                    table.insert(missing, string.format("%s EXP: required %d, current %d", towerName, req.Exp, currentExp))
                end
            end
        end
    end

    return passed, missing
end

-- ---------------------------------------------------------------------
-- Trials Data & Progression
-- ---------------------------------------------------------------------
local currentTrialCacheFile = "ProjectOptimazation/CachedCurrentTrial.json"
local nextTrialCacheFile = "ProjectOptimazation/CachedNextTrial.json"
local inMemoryCurrentTrial = nil
local inMemoryNextTrial = nil

function CombinedData:GetCurrentTrial(forceRefresh: boolean?)
    if forceRefresh then
        inMemoryCurrentTrial = nil
    end

    if MatchmakingTrialData then
        local ok, res = pcall(function()
            local currentTime = os.time()
            local rotation = MatchmakingTrialData.getCurrentRotation(currentTime)
            local details = MatchmakingTrialData.resolve(rotation)
            if setthreadidentity then pcall(setthreadidentity, 8) end
            local secondsLeft = math.max(0, (rotation.expiresAt or currentTime) - currentTime)
            local formattedTimer = MatchmakingTrialData.formatSecondsLeft(secondsLeft)
            if setthreadidentity then pcall(setthreadidentity, 8) end

            return {
                Name = rotation and rotation.trialName,
                ExpiresAt = rotation and rotation.expiresAt,
                TimeRemaining = formattedTimer,
                Map = details and details.mapName,
                Title = details and details.title,
                Subtitle = details and details.subtitle
            }
        end)
        if ok and res and res.Title then
            inMemoryCurrentTrial = res
            pcall(function()
                if writefile and HttpService then
                    writefile(currentTrialCacheFile, HttpService:JSONEncode(res))
                end
            end)
            return res
        end
    end

    if inMemoryCurrentTrial then return inMemoryCurrentTrial end

    pcall(function()
        if isfile and readfile and HttpService and isfile(currentTrialCacheFile) then
            local raw = readfile(currentTrialCacheFile)
            if raw and raw ~= "" then
                local decoded = HttpService:JSONDecode(raw)
                if type(decoded) == "table" and decoded.Title then
                    inMemoryCurrentTrial = decoded
                end
            end
        end
    end)

    return inMemoryCurrentTrial
end

function CombinedData:GetNextTrial(forceRefresh: boolean?)
    if forceRefresh then
        inMemoryNextTrial = nil
    end

    if MatchmakingTrialData then
        local ok, res = pcall(function()
            local currentTime = os.time()
            local currentRotation = MatchmakingTrialData.getCurrentRotation(currentTime)
            local timeOfNextTrial = (currentRotation and currentRotation.expiresAt or currentTime) + 1 
            local nextRotation = MatchmakingTrialData.getCurrentRotation(timeOfNextTrial)
            local nextDetails = MatchmakingTrialData.resolve(nextRotation)
            if setthreadidentity then pcall(setthreadidentity, 8) end
            local secondsLeft = math.max(0, (currentRotation and currentRotation.expiresAt or currentTime) - currentTime)
            local formattedTimer = MatchmakingTrialData.formatSecondsLeft(secondsLeft)
            if setthreadidentity then pcall(setthreadidentity, 8) end

            return {
                Name = nextRotation and nextRotation.trialName,
                Map = nextDetails and nextDetails.mapName,
                Title = nextDetails and nextDetails.title,
                TimeRemaining = formattedTimer,
                ExpiresAt = nextRotation and nextRotation.expiresAt
            }
        end)
        if ok and res and res.Title then
            inMemoryNextTrial = res
            pcall(function()
                if writefile and HttpService then
                    writefile(nextTrialCacheFile, HttpService:JSONEncode(res))
                end
            end)
            return res
        end
    end

    if inMemoryNextTrial then return inMemoryNextTrial end

    pcall(function()
        if isfile and readfile and HttpService and isfile(nextTrialCacheFile) then
            local raw = readfile(nextTrialCacheFile)
            if raw and raw ~= "" then
                local decoded = HttpService:JSONDecode(raw)
                if type(decoded) == "table" and decoded.Title then
                    inMemoryNextTrial = decoded
                end
            end
        end
    end)

    return inMemoryNextTrial
end

local StaticTrialDefinitions = {
    { Name = "Broke", Title = "Broke", Map = "Medieval Times" },
    { Name = "Committed", Title = "Committed", Map = "Retro Zone" },
    { Name = "ExplodingEnemies", Title = "Exploding Enemies", Map = "Wrecked Battlefield II" },
    { Name = "FlyingEnemies", Title = "Flying Enemies", Map = "Sacred Mountains" },
    { Name = "Fog", Title = "Fog", Map = "Winter Abyss" },
    { Name = "Glass", Title = "Glass", Map = "Stained Temple" },
    { Name = "HealthyEnemies", Title = "Healthy Enemies", Map = "Four Seasons" },
    { Name = "HiddenEnemies", Title = "Hidden Enemies", Map = "Forgetten Docks" },
    { Name = "Inflation", Title = "Inflation", Map = "Cyber City" },
    { Name = "Jailed", Title = "Jailed", Map = "Night Station" },
    { Name = "Limitation", Title = "Limitation", Map = "Coral Deep" },
    { Name = "Quarantine", Title = "Quarantine", Map = "Dusty Bridges" },
    { Name = "SpeedyEnemies", Title = "Speedy Enemies", Map = "Wrecked Battlefield" },
}

CombinedData.StaticTrialDefinitions = StaticTrialDefinitions

local function buildModifiersLookup(ownedModifiers)
    local lookup = {}
    if type(ownedModifiers) == "table" then
        for _, mod in ipairs(ownedModifiers) do
            lookup[mod] = true
            local clean = string.lower(tostring(mod)):gsub("%s+", "")
            lookup[clean] = true
            if mod == "JailedTowers" or mod == "Jailed" or clean == "jailedtowers" or clean == "jailed" then
                lookup["Jailed"] = true
                lookup["JailedTowers"] = true
                lookup["jailed"] = true
                lookup["jailedtowers"] = true
            end
        end
    end
    return lookup
end

function CombinedData:GetTrialsStatus()
    if setthreadidentity then pcall(setthreadidentity, 8) end
    local allTrials = nil
    if MatchmakingTrialData and type(MatchmakingTrialData.getTrialNames) == "function" then
        pcall(function()
            allTrials = MatchmakingTrialData.getTrialNames()
        end)
    end
    if setthreadidentity then pcall(setthreadidentity, 8) end

    if not allTrials or #allTrials == 0 then
        allTrials = {}
        for _, t in ipairs(StaticTrialDefinitions) do
            table.insert(allTrials, t.Name)
        end
    end

    local ownedModifiers = getCacheValue("Inventory.Modifiers") or {}
    if setthreadidentity then pcall(setthreadidentity, 8) end

    local lookup = buildModifiersLookup(ownedModifiers)

    local won = {}
    local notWon = {}

    for _, trialName in ipairs(allTrials) do
        local isWon = lookup[trialName] == true or lookup[string.lower(tostring(trialName)):gsub("%s+", "")] == true
        if not isWon and (trialName == "Jailed" or trialName == "JailedTowers") then
            isWon = (lookup["Jailed"] == true or lookup["JailedTowers"] == true)
        end
        if isWon then
            table.insert(won, trialName)
        else
            table.insert(notWon, trialName)
        end
    end

    return {
        Won = won,
        NotWon = notWon
    }
end

function CombinedData:GetAllTrialsList()
    if setthreadidentity then pcall(setthreadidentity, 8) end
    local ownedModifiers = getCacheValue("Inventory.Modifiers") or {}
    if setthreadidentity then pcall(setthreadidentity, 8) end

    local lookup = buildModifiersLookup(ownedModifiers)

    local list = {}
    local trialNames = nil
    if MatchmakingTrialData and type(MatchmakingTrialData.getTrialNames) == "function" then
        pcall(function()
            trialNames = MatchmakingTrialData.getTrialNames()
        end)
    end
    if setthreadidentity then pcall(setthreadidentity, 8) end

    if trialNames and #trialNames > 0 then
        for _, trialName in ipairs(trialNames) do
            local resolved = nil
            pcall(function()
                resolved = MatchmakingTrialData.resolve({ trialName = trialName })
            end)
            if setthreadidentity then pcall(setthreadidentity, 8) end
            local title = resolved and resolved.title or trialName
            local mapName = resolved and resolved.mapName or "Unknown"
            local isWon = lookup[trialName] == true or lookup[string.lower(tostring(trialName)):gsub("%s+", "")] == true
            if not isWon and (trialName == "Jailed" or trialName == "JailedTowers") then
                isWon = (lookup["Jailed"] == true or lookup["JailedTowers"] == true)
            end
            table.insert(list, {
                Name = trialName,
                Title = title,
                Map = mapName,
                IsWon = isWon,
                Status = isWon and "YES" or "NO"
            })
        end
    else
        for _, t in ipairs(StaticTrialDefinitions) do
            local isWon = lookup[t.Name] == true or lookup[string.lower(tostring(t.Name)):gsub("%s+", "")] == true
            if not isWon and (t.Name == "Jailed" or t.Name == "JailedTowers") then
                isWon = (lookup["Jailed"] == true or lookup["JailedTowers"] == true)
            end
            table.insert(list, {
                Name = t.Name,
                Title = t.Title,
                Map = t.Map,
                IsWon = isWon,
                Status = isWon and "YES" or "NO"
            })
        end
    end

    return list
end

function CombinedData:IsTrialWon(trialName)
    if not trialName then return false end
    if setthreadidentity then pcall(setthreadidentity, 8) end
    local ownedModifiers = getCacheValue("Inventory.Modifiers") or {}
    if setthreadidentity then pcall(setthreadidentity, 8) end

    local lookup = buildModifiersLookup(ownedModifiers)
    local target = string.lower(tostring(trialName)):gsub("%s+", "")
    if lookup[trialName] == true or lookup[target] == true then
        return true
    end
    if (target == "jailed" or target == "jailedtowers") and (lookup["Jailed"] or lookup["JailedTowers"] or lookup["jailed"] or lookup["jailedtowers"]) then
        return true
    end

    -- Also check display titles
    for _, t in ipairs(StaticTrialDefinitions) do
        local tClean = string.lower(t.Name):gsub("%s+", "")
        local titleClean = string.lower(t.Title):gsub("%s+", "")
        if tClean == target or titleClean == target then
            if lookup[t.Name] or lookup[tClean] then
                return true
            end
            if t.Modifier and (lookup[t.Modifier] or lookup[string.lower(t.Modifier)]) then
                return true
            end
        end
    end
    return false
end

-- ---------------------------------------------------------------------
-- Story Mode Progression (Chapter 0: TDS: Boot Camp)
-- ---------------------------------------------------------------------
CombinedData.Chapter0Missions = {
    [1] = { Number = 1, Id = "boot-camp", Title = "Boot Camp", Map = "Tutorial" },
    [2] = { Number = 2, Id = "live-fire", Title = "Live Fire", Map = "Tutorial" },
    [3] = { Number = 3, Id = "breach-protocol", Title = "Breach Protocol", Map = "Tutorial" },
    [4] = { Number = 4, Id = "brute-force", Title = "Brute Force", Map = "Tutorial" },
}

function CombinedData:GetStoryProgress(forceServerFetch)
    if setthreadidentity then pcall(setthreadidentity, 8) end

    -- 1. Try in-memory cached progress if not forcing server fetch
    if not forceServerFetch and inMemoryStoryProgress and inMemoryStoryProgress.Chapters then
        return inMemoryStoryProgress
    end

    -- 2. Try Cache("StoryMode") atom from client Cache module
    local cached = getCacheValue("StoryMode")
    if (not cached or not cached.Chapters) and Cache then
        pcall(function()
            local atom = Cache("StoryMode")
            if atom and type(atom.GetValue) == "function" then
                cached = atom:GetValue()
            end
        end)
    end

    if not forceServerFetch and cached and type(cached) == "table" and cached.Chapters then
        inMemoryStoryProgress = cached
        return cached
    end

    -- 3. Fetch from StoryModeClient:getProgress()
    local client = getStoryModeClient()
    if client and type(client.getProgress) == "function" then
        local ok, res = pcall(function()
            return client.getProgress()
        end)
        if ok and type(res) == "table" and res.Chapters then
            inMemoryStoryProgress = res
            return res
        end
    end

    -- 4. Direct NewNetwork invocation fallback
    pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        local modules = shared and shared:FindFirstChild("Modules")
        local nnModule = modules and modules:FindFirstChild("NewNetwork")
        local NewNetwork = nnModule and require(nnModule)
        if NewNetwork and type(NewNetwork.Channel) == "function" then
            local channel = NewNetwork.Channel("Chapters")
            local raw = channel:invokeServer("GetProgress")
            local ser = getStoryModeSerialization()
            local deserialized = (ser and type(ser.deserialize) == "function") and ser.deserialize(raw) or raw
            if type(deserialized) == "table" and deserialized.Chapters then
                inMemoryStoryProgress = deserialized
            end
        end
    end)

    return inMemoryStoryProgress or cached
end

function CombinedData:IsStoryMissionCompleted(chapterNumber, missionNumber)
    if setthreadidentity then pcall(setthreadidentity, 8) end
    local progress = self:GetStoryProgress()
    if not progress or type(progress) ~= "table" or not progress.Chapters then
        return false
    end

    local numChap = tonumber(chapterNumber)
    local strChap = tostring(chapterNumber)
    local chapter = (numChap ~= nil and progress.Chapters[numChap]) or progress.Chapters[strChap]
    if not chapter or type(chapter) ~= "table" or not chapter.Missions then
        return false
    end

    local numMis = tonumber(missionNumber)
    local strMis = tostring(missionNumber)
    local mission = (numMis ~= nil and chapter.Missions[numMis]) or chapter.Missions[strMis]

    return mission ~= nil
end

function CombinedData:GetStoryMissionStars(chapterNumber, missionNumber)
    if setthreadidentity then pcall(setthreadidentity, 8) end
    local progress = self:GetStoryProgress()
    if not progress or type(progress) ~= "table" or not progress.Chapters then
        return 0
    end

    local numChap = tonumber(chapterNumber)
    local strChap = tostring(chapterNumber)
    local chapter = (numChap ~= nil and progress.Chapters[numChap]) or progress.Chapters[strChap]
    if not chapter or type(chapter) ~= "table" or not chapter.Missions then
        return 0
    end

    local numMis = tonumber(missionNumber)
    local strMis = tostring(missionNumber)
    local mission = (numMis ~= nil and chapter.Missions[numMis]) or chapter.Missions[strMis]

    if type(mission) == "table" and type(mission.Stars) == "number" then
        return math.clamp(math.floor(mission.Stars), 0, 3)
    elseif mission ~= nil then
        return 1
    end

    return 0
end

-- Chapter 0 ("TDS: Boot Camp") specific helpers
function CombinedData:IsBootCampBeaten()
    return self:IsStoryMissionCompleted(0, 1)
end

function CombinedData:IsLiveFireBeaten()
    return self:IsStoryMissionCompleted(0, 2)
end

function CombinedData:IsBreachProtocolBeaten()
    return self:IsStoryMissionCompleted(0, 3)
end

function CombinedData:IsBruteForceBeaten()
    return self:IsStoryMissionCompleted(0, 4)
end

function CombinedData:IsChapter0Beaten()
    local beaten = self:IsBootCampBeaten() 
       and self:IsLiveFireBeaten() 
       and self:IsBreachProtocolBeaten() 
       and self:IsBruteForceBeaten()

    if beaten then
        statsEnv.Chapter0Beaten = true
        return true
    end

    if statsEnv.Chapter0Beaten then
        return true
    end

    -- High-level accounts (Level >= 15) are guaranteed past Chapter 0
    local curLvl = self:GetLevel() or 0
    if curLvl >= 15 then
        statsEnv.Chapter0Beaten = true
        return true
    end

    return false
end

function CombinedData:GetChapter0Status()
    local m1 = self:IsBootCampBeaten()
    local m2 = self:IsLiveFireBeaten()
    local m3 = self:IsBreachProtocolBeaten()
    local m4 = self:IsBruteForceBeaten()

    local s1 = self:GetStoryMissionStars(0, 1)
    local s2 = self:GetStoryMissionStars(0, 2)
    local s3 = self:GetStoryMissionStars(0, 3)
    local s4 = self:GetStoryMissionStars(0, 4)

    local curLvl = self:GetLevel() or 0
    if curLvl >= 15 and not (m1 and m2 and m3 and m4) then
        m1, m2, m3, m4 = true, true, true, true
        if s1 == 0 then s1 = 3 end
        if s2 == 0 then s2 = 3 end
        if s3 == 0 then s3 = 3 end
        if s4 == 0 then s4 = 3 end
    end

    local completed = (m1 and 1 or 0) + (m2 and 1 or 0) + (m3 and 1 or 0) + (m4 and 1 or 0)

    return {
        Chapter = 0,
        Title = "TDS: Boot Camp (Chapter 0)",
        TotalMissions = 4,
        CompletedCount = completed,
        AllBeaten = (completed == 4),
        Missions = {
            ["Boot Camp"] = { Number = 1, Id = "boot-camp", Title = "Boot Camp", Beaten = m1, Stars = s1, Status = m1 and "BEATEN" or "NOT BEATEN" },
            ["Live Fire"] = { Number = 2, Id = "live-fire", Title = "Live Fire", Beaten = m2, Stars = s2, Status = m2 and "BEATEN" or "NOT BEATEN" },
            ["Breach Protocol"] = { Number = 3, Id = "breach-protocol", Title = "Breach Protocol", Beaten = m3, Stars = s3, Status = m3 and "BEATEN" or "NOT BEATEN" },
            ["Brute Force"] = { Number = 4, Id = "brute-force", Title = "Brute Force", Beaten = m4, Stars = s4, Status = m4 and "BEATEN" or "NOT BEATEN" },
        },
        List = {
            { Name = "Boot Camp", Number = 1, Id = "boot-camp", Beaten = m1, Stars = s1, Status = m1 and "BEATEN" or "NOT BEATEN" },
            { Name = "Live Fire", Number = 2, Id = "live-fire", Beaten = m2, Stars = s2, Status = m2 and "BEATEN" or "NOT BEATEN" },
            { Name = "Breach Protocol", Number = 3, Id = "breach-protocol", Beaten = m3, Stars = s3, Status = m3 and "BEATEN" or "NOT BEATEN" },
            { Name = "Brute Force", Number = 4, Id = "brute-force", Beaten = m4, Stars = s4, Status = m4 and "BEATEN" or "NOT BEATEN" },
        }
    }
end

-- Primary CheckOwnedStoryMode / checkOwnedStoryMode helper method
function CombinedData:CheckOwnedStoryMode()
    local status = self:GetChapter0Status()
    return {
        AllBeaten = status.AllBeaten,
        CompletedCount = status.CompletedCount,
        TotalCount = status.TotalMissions,
        BootCamp = status.Missions["Boot Camp"].Beaten,
        LiveFire = status.Missions["Live Fire"].Beaten,
        BreachProtocol = status.Missions["Breach Protocol"].Beaten,
        BruteForce = status.Missions["Brute Force"].Beaten,
        Stars = {
            BootCamp = status.Missions["Boot Camp"].Stars,
            LiveFire = status.Missions["Live Fire"].Stars,
            BreachProtocol = status.Missions["Breach Protocol"].Stars,
            BruteForce = status.Missions["Brute Force"].Stars,
        },
        Details = status.List
    }
end

-- Aliases to support colon, dot, and camelCase calls
CombinedData.checkOwnedStoryMode = function(self_or_first, ...)
    if self_or_first == CombinedData then
        return CombinedData:CheckOwnedStoryMode(...)
    else
        return CombinedData:CheckOwnedStoryMode(self_or_first, ...)
    end
end

CombinedData.CheckStoryMode = function(...) return CombinedData:CheckOwnedStoryMode(...) end
CombinedData.checkStoryMode = function(...) return CombinedData:CheckOwnedStoryMode(...) end
CombinedData.GetOwnedStoryMode = function(...) return CombinedData:CheckOwnedStoryMode(...) end

function CombinedData:PrintStoryModeStatus()
    local res = self:CheckOwnedStoryMode()
    print("========================================")
    print("   TDS: Story Mode (Chapter 0) Status   ")
    print("========================================")
    print(string.format("Progress: %d / %d missions beaten", res.CompletedCount, res.TotalCount))
    print(string.format("All Beaten: %s", res.AllBeaten and "YES" or "NO"))
    print("----------------------------------------")
    for _, m in ipairs(res.Details) do
        print(string.format("[%s] Mission %d: %-16s | Stars: %d", m.Status, m.Number, m.Name, m.Stars))
    end
    print("========================================")
    return res
end

CombinedData.printStoryModeStatus = function(...) return CombinedData:PrintStoryModeStatus(...) end

return CombinedData

