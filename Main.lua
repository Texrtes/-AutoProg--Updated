--!strict
--==============================================================================
-- [SomethingNew] Main.lua
-- Production-ready Automation Hub powered by CoreRevamp Glassmorphism API
--
-- Tabs:
-- 1. Overview Tab
-- 2. Auto Progress
-- 3. Auto Currency
-- 4. Product
-- 5. Misc
--==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function()
        LocalPlayer = Players.PlayerAdded:Wait()
    end)
end
local PlayerGui = (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 10)) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))

-- Filter placement, upgrade, and nil tower retry warning spam from console
do
    local rawWarn = warn
    local function cleanWarn(...)
        local msg = ...
        if type(msg) == "string" then
            if msg:find("%[TDS:Place%]") or msg:find("%[TDS:Upgrade%]")
                or msg:find("Waiting to place") or msg:find("Waiting to upgrade")
                or msg:find("Attempted to upgrade a nil tower") then
                return
            end
        end
        return rawWarn(...)
    end
    warn = cleanWarn
    if getgenv then
        getgenv().warn = cleanWarn
    end
end

local Logger = {
    Info = function(self, msg) warn("[INFO] " .. tostring(msg)) end,
    Success = function(self, msg) print("[SUCCESS] " .. tostring(msg)) end,
    Warn = function(self, msg) warn("[WARN] " .. tostring(msg)) end,
    Error = function(self, msg) warn("[ERROR] " .. tostring(msg)) end,
}

--==============================================================================
-- Early Boot: Anti-Stuck Monitor & Disconnect Auto-Recovery
-- (Fires first before loading UI or rest of features)
--==============================================================================
local LOBBY_PLACE_ID = 3260590327

local function earlyExtractPrivateServerCode(linkOrCode: string?): string
    if not linkOrCode or type(linkOrCode) ~= "string" then return "" end
    local trimmed = linkOrCode:gsub("^%s*(.-)%s*$", "%1")
    if trimmed == "" then return "" end
    local psCode = trimmed:match("privateServerLinkCode=([%w%-%_]+)")
    if psCode and #psCode > 0 then return psCode end
    local shareCode = trimmed:match("[?&]code=([%w%-%_]+)")
    if shareCode and #shareCode > 0 then return shareCode end
    local linkCode = trimmed:match("[?&]linkCode=([%w%-%_]+)")
    if linkCode and #linkCode > 0 then return linkCode end
    if trimmed:find("roblox.com") or trimmed:find("http") then
        local pathCode = trimmed:match("/([%w%-%_]+)%s*$")
        if pathCode and #pathCode > 0 then return pathCode end
    end
    return trimmed
end

local function earlyErrorTeleport()
    local lobbyId = LOBBY_PLACE_ID
    pcall(function()
        local platform = UserInputService:GetPlatform()
        local IsMobile = (platform == Enum.Platform.IOS or platform == Enum.Platform.Android)
        local rawCode = (State and State.Misc and (State.Misc.PrivateCode or State.Misc.PrivateServerCode))
            or (Globals and (Globals.PrivateCode or Globals.PrivateServerCode or Globals.MultiplayerPrivateServerLink))
            or ""
        local pCode = earlyExtractPrivateServerCode(rawCode)
        if not IsMobile and pCode ~= "" then
            local expService = game:GetService("ExperienceService")
            if expService then
                expService:LaunchExperience({
                    placeId = lobbyId, 
                    linkCode = pCode
                })
            else
                TeleportService:Teleport(lobbyId)
            end
        else
            TeleportService:Teleport(lobbyId)
        end
    end)
end

local isReconnectingEarly = false
local function earlyReconnect(customReason: string?)
    if isReconnectingEarly then return end
    isReconnectingEarly = true
    task.spawn(function()
        local initialCode = nil
        pcall(function() initialCode = GuiService:GetErrorCode() end)
        task.wait(4)
        if not customReason and (not initialCode or initialCode == Enum.ConnectionError.OK) then
            isReconnectingEarly = false
            return
        end
        warn("[Reconnect] Attempting error recovery: " .. tostring(customReason or initialCode or "Error"))
        pcall(function()
            TeleportService:TeleportReconnect()
        end)
        task.wait(12)
        pcall(earlyErrorTeleport)
        isReconnectingEarly = false
    end)
end

-- Continuous Error & Prompt Listeners (Hooked immediately)
pcall(function()
    GuiService.ErrorMessageChanged:Connect(function()
        local code = GuiService:GetErrorCode()
        if code and code ~= Enum.ConnectionError.OK then
            task.wait(4)
            pcall(function() TeleportService:TeleportReconnect() end)
            task.wait(6)
            pcall(earlyErrorTeleport)
        end
    end)
end)

pcall(function()
    local CoreGui = game:GetService("CoreGui")
    local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
    if promptGui then
        local promptOverlay = promptGui:FindFirstChild("promptOverlay")
        if promptOverlay then
            promptOverlay.ChildAdded:Connect(function()
                task.wait(3)
                pcall(function() TeleportService:TeleportReconnect() end)
                task.wait(5)
                pcall(earlyErrorTeleport)
            end)
        end
    end
end)

-- Anti-Stuck Monitor (Starts immediately)
local function earlyAntiStuck()
    task.spawn(function()
        local secondsStuck = 0
        while true do 
            task.wait(1)
            local attrLoading = LocalPlayer and LocalPlayer:GetAttribute("Loading") == true
            local attrTeleporting = LocalPlayer and LocalPlayer:GetAttribute("Teleporting") == true
            
            local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
            local loadScreen = pg and pg:FindFirstChild("LoadingScreen")
            local loadContent = loadScreen and loadScreen:FindFirstChild("content")
            local isLoadVisible = loadContent and loadContent.Visible == true
            
            local countScreen = pg and pg:FindFirstChild("PlayerCountdown")
            local countFrame = countScreen and countScreen:FindFirstChild("Frame")
            local isCountVisible = countFrame and countFrame.Visible == true

            if attrLoading or attrTeleporting or isLoadVisible or isCountVisible then
                secondsStuck = secondsStuck + 1
                if secondsStuck >= 60 then
                    pcall(earlyErrorTeleport)
                    secondsStuck = 0 
                end
            else
                secondsStuck = 0 
            end
        end
    end)
end

-- Fire Anti-Stuck & Error Recovery immediately at script start!
earlyAntiStuck()
task.spawn(earlyReconnect)

--==============================================================================
-- GitHub Configuration & Remote Asset Loader
--==============================================================================
local GITHUB_RAW_BASE = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/"

local function fetchGithubScript(fileName: string): string?
    local url = GITHUB_RAW_BASE .. fileName
    local ok, content = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(content) == "string" and #content > 0 then
        return content
    end
    return nil
end

--==============================================================================
-- 1. Robust API Loader via GitHub loadstring (with local readfile fallback)
--==============================================================================
local function loadLibrary()
    -- 1. Try local workspace files first
    local candidates = {
        "[SomethingNew]/CoreRevampNewAPI.lua",
        "[SomethingNew]\\CoreRevampNewAPI.lua",
        "CoreRevampNewAPI.lua",
    }
    local source = nil
    for _, path in ipairs(candidates) do
        local ok, content = pcall(function()
            if typeof(isfile) == "function" and not isfile(path) then
                return nil
            end
            if typeof(readfile) == "function" then
                return readfile(path)
            end
            return nil
        end)
        if ok and type(content) == "string" and #content > 0 then
            source = content
            break
        end
    end

    if not source then
        local ok, fallback = pcall(readfile, "[SomethingNew]/CoreRevampNewAPI.lua")
        if ok and type(fallback) == "string" then
            source = fallback
        end
    end

    if source then
        local loader, parseErr = loadstring(source, "CoreRevampNewAPI")
        if loader then
            local ok, lib = pcall(loader)
            if ok and lib then
                return lib
            end
        else
            warn("[SomethingNew] Compile error in local CoreRevampNewAPI: " .. tostring(parseErr))
        end
    end

    -- 2. Fallback to GitHub
    local remoteSource = fetchGithubScript("CoreRevampNewAPI.lua")
    if remoteSource then
        local loader, parseErr = loadstring(remoteSource, "CoreRevampNewAPI")
        if loader then
            local ok, lib = pcall(loader)
            if ok and lib then
                return lib
            end
        else
            warn("[SomethingNew] GitHub compile error in CoreRevampNewAPI: " .. tostring(parseErr))
        end
    end

    error("[SomethingNew] Unable to load CoreRevampNewAPI from workspace or GitHub.")
end

local Library = loadLibrary()
local Window: any = nil

--==============================================================================
-- 2. Load Pure Progression Configs (Settings.lua via GitHub loadstring)
--==============================================================================
local function loadProgressConfig(): { [string]: any }
    -- 1. Try local workspace files first
    local candidates = {
        "[SomethingNew]/Settings.lua",
        "[SomethingNew]\\Settings.lua",
        "Settings.lua",
    }
    local source = nil
    for _, path in ipairs(candidates) do
        local ok, content = pcall(function()
            if typeof(isfile) == "function" and not isfile(path) then
                return nil
            end
            if typeof(readfile) == "function" then
                return readfile(path)
            end
            return nil
        end)
        if ok and type(content) == "string" and #content > 0 then
            source = content
            break
        end
    end
    if not source then
        local ok, fallback = pcall(readfile, "[SomethingNew]/Settings.lua")
        if ok and type(fallback) == "string" then
            source = fallback
        end
    end
    if source then
        local loader, parseErr = loadstring(source, "ProgressionConfig")
        if loader then
            local ok, res = pcall(loader)
            if ok and type(res) == "table" then
                return res
            end
        else
            warn("[SomethingNew] Compile error in local Settings.lua: " .. tostring(parseErr))
        end
    end

    -- 2. Fallback to GitHub
    local remoteSource = fetchGithubScript("Settings.lua")
    if remoteSource then
        local loader, parseErr = loadstring(remoteSource, "ProgressionConfig")
        if loader then
            local ok, res = pcall(loader)
            if ok and type(res) == "table" then
                return res
            end
        else
            warn("[SomethingNew] GitHub compile error in Settings.lua: " .. tostring(parseErr))
        end
    end
    return {}
end

local ProgressionConfig = loadProgressConfig()

--==============================================================================
-- 2.5 Load DataHandler API & Live Data Helpers (via GitHub loadstring)
--==============================================================================
local function loadDataHandler()
    -- 1. Try local workspace files first
    local candidates = {
        "[SomethingNew]/DataHandler.lua",
        "[SomethingNew]\\DataHandler.lua",
        "DataHandler.lua",
    }
    local source = nil
    for _, path in ipairs(candidates) do
        local ok, content = pcall(function()
            if typeof(isfile) == "function" and not isfile(path) then
                return nil
            end
            if typeof(readfile) == "function" then
                return readfile(path)
            end
            return nil
        end)
        if ok and type(content) == "string" and #content > 0 then
            source = content
            break
        end
    end
    if not source then
        local ok, fallback = pcall(readfile, "[SomethingNew]/DataHandler.lua")
        if ok and type(fallback) == "string" then
            source = fallback
        end
    end
    if source then
        local loader, parseErr = loadstring(source, "DataHandler")
        if loader then
            local ok, res = pcall(loader)
            if ok and res then
                return res
            end
        else
            warn("[SomethingNew] Compile error in local DataHandler.lua: " .. tostring(parseErr))
        end
    end

    -- 2. Fallback to GitHub
    local remoteSource = fetchGithubScript("DataHandler.lua")
    if remoteSource then
        local loader, parseErr = loadstring(remoteSource, "DataHandler")
        if loader then
            local ok, res = pcall(loader)
            if ok and res then
                return res
            end
        else
            warn("[SomethingNew] GitHub compile error in DataHandler.lua: " .. tostring(parseErr))
        end
    end

    return nil
end

local DataHandler = loadDataHandler()
local PlayerDataHandler = DataHandler

--==============================================================================
-- 2.6 Load TDS In-Game API (API.lua via GitHub loadstring)
--==============================================================================
local cachedTDSAPI = nil
local function loadTDSAPI()
    local api = cachedTDSAPI or shared.TDSTable or shared["TDS_Table"] or (getgenv and getgenv().TDS) or _G.TDS
    if api and type(api) == "table" then
        cachedTDSAPI = api
        if getgenv then getgenv().TDS = api end
        _G.TDS = api
        shared.TDSTable = api
        return cachedTDSAPI
    end

    -- 1. Try local workspace files first
    local candidates = {
        "[SomethingNew]/API.lua",
        "[SomethingNew]\\API.lua",
        "API.lua",
    }
    local source = nil
    for _, path in ipairs(candidates) do
        local ok, content = pcall(function()
            if typeof(isfile) == "function" and not isfile(path) then
                return nil
            end
            if typeof(readfile) == "function" then
                return readfile(path)
            end
            return nil
        end)
        if ok and type(content) == "string" and #content > 0 then
            source = content
            break
        end
    end
    if not source then
        local ok, fallback = pcall(readfile, "[SomethingNew]/API.lua")
        if ok and type(fallback) == "string" then
            source = fallback
        end
    end
    if source then
        local loader, parseErr = loadstring(source, "TDS_API")
        if loader then
            local ok, res = pcall(loader)
            if ok and res then
                cachedTDSAPI = res
                if getgenv then getgenv().TDS = res end
                _G.TDS = res
                shared.TDSTable = res
                return cachedTDSAPI
            end
        else
            warn("[SomethingNew] Compile error in local API.lua: " .. tostring(parseErr))
        end
    end

    -- 2. Fallback to GitHub
    local remoteSource = fetchGithubScript("API.lua")
    if remoteSource then
        local loader, parseErr = loadstring(remoteSource, "TDS_API")
        if loader then
            local ok, res = pcall(loader)
            if ok and res then
                cachedTDSAPI = res
                if getgenv then getgenv().TDS = res end
                _G.TDS = res
                shared.TDSTable = res
                return cachedTDSAPI
            end
        else
            warn("[SomethingNew] GitHub compile error in API.lua: " .. tostring(parseErr))
        end
    end
    return nil
end

local function formatCommas(amount: number): string
    local formatted = tostring(math.floor(amount or 0))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local SKILLTREE_FILE = "[SomethingNew]/userskilltree.json"
local SKILLTREE_FILE_ROOT = "userskilltree.json"

local function getLiveSkillTree(): { any }
    local tree = nil
    if DataHandler then
        local ok, res = pcall(function() return DataHandler:GetSkillTree() end)
        if ok and res and type(res) == "table" and #res > 0 then
            tree = res
        end
    end

    if tree and #tree > 0 then
        pcall(function()
            if typeof(writefile) == "function" and HttpService then
                local encoded = HttpService:JSONEncode(tree)
                writefile(SKILLTREE_FILE, encoded)
                writefile(SKILLTREE_FILE_ROOT, encoded)
            end
        end)
        return tree
    end

    local cacheCandidates = { SKILLTREE_FILE, SKILLTREE_FILE_ROOT }
    for _, path in ipairs(cacheCandidates) do
        if typeof(isfile) == "function" and isfile(path) and typeof(readfile) == "function" then
            local ok, raw = pcall(readfile, path)
            if ok and raw and raw ~= "" then
                local decOk, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
                if decOk and type(decoded) == "table" and #decoded > 0 then
                    return decoded
                end
            end
        end
    end
    return {}
end

local function getSkillTreeDict(): { [string]: number }
    local tree = getLiveSkillTree()
    if (not tree or #tree == 0) and PlayerDataHandler and typeof(PlayerDataHandler.GetSkillTree) == "function" then
        pcall(function() tree = PlayerDataHandler:GetSkillTree() end)
    end

    local dict: { [string]: number } = {}
    if type(tree) == "table" then
        for _, skill in ipairs(tree) do
            if type(skill) == "table" and skill.Name then
                local lvl = tonumber(skill.Level) or 0
                if skill.IsMaxed then
                    local maxVal = tonumber(skill.MaxLevel) or 999
                    if lvl < maxVal then
                        lvl = maxVal
                    end
                end
                dict[skill.Name] = lvl
                local norm = string.lower(string.gsub(skill.Name, "[^%w]", ""))
                if norm ~= "" then
                    dict["_norm_" .. norm] = lvl
                end
            end
        end
        -- Handle dictionary format if already mapped
        for k, v in pairs(tree) do
            if type(k) == "string" and type(v) == "number" then
                dict[k] = v
                local norm = string.lower(string.gsub(k, "[^%w]", ""))
                if norm ~= "" then
                    dict["_norm_" .. norm] = v
                end
            end
        end
    end
    return dict
end

local function getSkillLevel(dict: { [string]: number }?, skillName: string): number
    if not dict or not skillName then return 0 end
    if dict[skillName] ~= nil then
        return dict[skillName]
    end
    local norm = string.lower(string.gsub(skillName, "[^%w]", ""))
    if dict["_norm_" .. norm] ~= nil then
        return dict["_norm_" .. norm]
    end
    return 0
end

local function getSkillTreeSummaryText(): string
    local tree = getLiveSkillTree()
    if not tree or #tree == 0 then
        return "Skill Tree: Not Available"
    end
    local maxedCount = 0
    local totalCount = #tree
    for _, skill in ipairs(tree) do
        if skill.IsMaxed then
            maxedCount = maxedCount + 1
        end
    end
    if maxedCount == totalCount then
        return string.format("Skill Tree: %d/%d Maxed (Complete ✓)", maxedCount, totalCount)
    else
        return string.format("Skill Tree: %d/%d Maxed (%d Skills)", maxedCount, totalCount, totalCount)
    end
end

local function getUserDataChecklist(): { string }
    local lvl = 0
    local coins = 0
    local gems = 0
    local timescaleTickets = 0
    local expDisplay = "0 / 0"
    local goldenCount = 0

    if DataHandler then
        local ok, stats = pcall(function() return DataHandler:GetPlayerStats() end)
        if ok and stats then
            lvl = stats.Level or 0
            coins = stats.Coins or 0
            gems = stats.Gems or 0
            timescaleTickets = stats.TimescaleTickets or 0
            expDisplay = stats.ExpDisplay or "0 / 0"
        end
        if (not timescaleTickets or timescaleTickets == 0) and typeof(DataHandler.GetTimescaleTickets) == "function" then
            pcall(function()
                timescaleTickets = DataHandler:GetTimescaleTickets() or 0
            end)
        end
        local gOk, gList = pcall(function() return DataHandler:GetGoldenOwned() end)
        if gOk and gList then
            goldenCount = #gList
        end
    end

    local items = {
        string.format("Level: %d", lvl),
        string.format("Coins: %s", formatCommas(coins)),
        string.format("Gems: %s", formatCommas(gems)),
        string.format("Timescales: %s", formatCommas(timescaleTickets)),
        string.format("EXP: %s", expDisplay),
        string.format("Golden Towers: %d Owned", goldenCount),
        getSkillTreeSummaryText(),
    }

    local tree = getLiveSkillTree()
    if tree and #tree > 0 then
        for _, s in ipairs(tree) do
            local statText = string.format("Skill: %s (Lvl %s)", s.Name, s.LevelFormatted or tostring(s.Level))
            table.insert(items, statText)
        end
    end

    return items
end

local function getAllTowersList(): { string }
    local towers = {}
    pcall(function()
        local Content = require(game:GetService("ReplicatedStorage").Shared.Modules.Content)
        local ok, towerFolder = pcall(Content, "Tower")
        if ok and towerFolder then
            for _, t in ipairs(towerFolder:GetChildren()) do
                table.insert(towers, t.Name)
            end
        end
    end)
    if #towers > 0 then
        table.sort(towers)
        return towers
    end
    return {
        "Accelerator", "Ace Pilot", "Archer", "Assassin", "Biologist", "Boomerang",
        "Brawler", "Commander", "Commando", "Cowboy", "Crook Boss", "Cryomancer",
        "DJ Booth", "Demoman", "Electroshocker", "Elementalist", "Elf Camp", "Engineer",
        "Executioner", "Farm", "Firework Technician", "Freezer", "Frost Blaster",
        "Gatling Gun", "Gladiator", "Hacker", "Hallow Punk", "Harvester", "Hunter",
        "Jester", "Mecha Base", "Medic", "Mercenary Base", "Militant", "Military Base",
        "Minigunner", "Mortar", "Necromancer", "Paintballer", "Pulse Trooper", "Pursuit",
        "Pyromancer", "Ranger", "Rocketeer", "Saboteur", "Scout", "Shotgunner",
        "Slasher", "Sledger", "Slime Trooper", "Sniper", "Snowballer", "Soldier",
        "Spotlight Tech", "Swarmer", "Tesla", "Toxic Gunner", "Trapper", "Turret",
        "Warden", "War Machine", "Warlock"
    }
end

local cachedOwnedTowersList = nil
local function getOwnedTowersChecklist(forceRefresh: boolean?): { string }
    if cachedOwnedTowersList and not forceRefresh then
        return cachedOwnedTowersList
    end
    local allTowers = getAllTowersList()
    local list = {}
    for _, name in ipairs(allTowers) do
        local owned = false
        if DataHandler then
            local ok, res = pcall(function() return DataHandler:IsTowerOwned(name) end)
            owned = ok and (res == true)
        end
        if owned then
            table.insert(list, name .. ": Owned (✓)")
        else
            table.insert(list, name .. ": Not Owned [X]")
        end
    end
    cachedOwnedTowersList = list
    return list
end

local cachedOwnedTrialsList = nil
local cachedWonTrialsList = nil
local cachedNotWonTrialsList = nil

local function getOwnedTrialsData(forceRefresh: boolean?): ({ string }, { string }, { string })
    if cachedOwnedTrialsList and not forceRefresh then
        return cachedOwnedTrialsList, cachedWonTrialsList, cachedNotWonTrialsList
    end

    local allList = {}
    local wonList = {}
    local notWonList = {}

    local trials = nil
    if DataHandler and typeof(DataHandler.GetAllTrialsList) == "function" then
        pcall(function()
            trials = DataHandler:GetAllTrialsList()
        end)
    end

    if not trials or #trials == 0 then
        if DataHandler and DataHandler.StaticTrialDefinitions then
            trials = {}
            for _, t in ipairs(DataHandler.StaticTrialDefinitions) do
                local won = false
                pcall(function() won = DataHandler:IsTrialWon(t.Name) end)
                table.insert(trials, {
                    Name = t.Name,
                    Title = t.Title or t.Name,
                    Map = t.Map or "Unknown",
                    IsWon = won,
                    Status = won and "YES" or "NO",
                })
            end
        end
    end

    -- Reconcile modifiers from Inventory.Modifiers (ensures Jailed / JailedTowers ownership is always accurately detected)
    pcall(function()
        local ownedMods = nil
        local cModule = game:GetService("ReplicatedStorage"):FindFirstChild("Client")
        cModule = cModule and cModule:FindFirstChild("Modules")
        cModule = cModule and cModule:FindFirstChild("Cache")
        if cModule then
            local Cache = require(cModule)
            local atom = Cache("Inventory.Modifiers")
            if atom and type(atom.GetValue) == "function" then
                ownedMods = atom:GetValue()
            end
        end
        if type(ownedMods) == "table" and trials then
            local modLookup = {}
            for _, m in ipairs(ownedMods) do
                modLookup[tostring(m)] = true
                local clean = string.lower(tostring(m)):gsub("%s+", "")
                modLookup[clean] = true
                if m == "JailedTowers" or m == "Jailed" or clean == "jailedtowers" or clean == "jailed" then
                    modLookup["Jailed"] = true
                    modLookup["JailedTowers"] = true
                    modLookup["jailed"] = true
                    modLookup["jailedtowers"] = true
                end
            end
            for _, t in ipairs(trials) do
                local tName = tostring(t.Name or "")
                local tTitle = tostring(t.Title or "")
                local cleanName = string.lower(tName):gsub("%s+", "")
                local cleanTitle = string.lower(tTitle):gsub("%s+", "")
                if modLookup[tName] or modLookup[cleanName] or modLookup[tTitle] or modLookup[cleanTitle] then
                    t.IsWon = true
                    t.Status = "YES"
                elseif (cleanName == "jailed" or cleanName == "jailedtowers" or cleanTitle == "jailed") and (modLookup["Jailed"] or modLookup["JailedTowers"] or modLookup["jailed"] or modLookup["jailedtowers"]) then
                    t.IsWon = true
                    t.Status = "YES"
                end
            end
        end
    end)

    local wonCount = 0
    local totalCount = trials and #trials or 0
    if trials then
        for _, t in ipairs(trials) do
            if t.IsWon then wonCount = wonCount + 1 end
        end
    end

    local summaryText = string.format("Completed Trials: %d / %d (%d%%)", wonCount, totalCount, totalCount > 0 and math.floor((wonCount / totalCount) * 100) or 0)
    table.insert(allList, summaryText)
    table.insert(wonList, string.format("Won Modifiers: %d / %d Completed", wonCount, totalCount))
    table.insert(notWonList, string.format("Remaining Trials: %d Pending", totalCount - wonCount))

    if trials and #trials > 0 then
        for _, t in ipairs(trials) do
            local displayName = t.Title or t.Name
            if t.IsWon then
                local line = string.format("%s: Won (✓) [Map: %s]", displayName, t.Map or "N/A")
                table.insert(allList, line)
                table.insert(wonList, line)
            else
                local line = string.format("%s: Not Won [X] [Map: %s]", displayName, t.Map or "N/A")
                table.insert(allList, line)
                table.insert(notWonList, line)
            end
        end
    else
        table.insert(allList, "No trials data available.")
        table.insert(wonList, "None completed.")
        table.insert(notWonList, "None pending.")
    end

    cachedOwnedTrialsList = allList
    cachedWonTrialsList = wonList
    cachedNotWonTrialsList = notWonList

    return allList, wonList, notWonList
end

local function getOwnedTrialsChecklist(forceRefresh: boolean?): { string }
    local all = getOwnedTrialsData(forceRefresh)
    return all
end

local LOBBY_PLACE_ID = 3260590327

local function attemptBuyMissingTowersList(missingTowers)
    local remote = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if not (remote and remote:IsA("RemoteFunction")) then return false end
    local boughtAny = false
    for _, tower in ipairs(missingTowers) do
        local ok, res = pcall(function()
            return remote:InvokeServer("Shop", "Purchase", "Tower", tower)
        end)
        if ok and res ~= false then
            boughtAny = true
            Logger:Info(string.format("Shop: Purchase remote invoked for tower '%s'.", tostring(tower)))
            task.wait(0.5)
        end
    end
    return boughtAny
end

--==============================================================================
-- 2.7 Auto Currency Module & Map Voting Helpers
--==============================================================================
local SmartTeleportToLobby
SmartTeleportToLobby = function(...)
    if AutoGoldModule and AutoGoldModule.SmartTeleportToLobby then
        return AutoGoldModule.SmartTeleportToLobby(...)
    end
    if Globals and Globals.SmartTeleportToLobby then
        return Globals.SmartTeleportToLobby(...)
    end
    if shared and shared.SmartTeleportToLobby then
        return shared.SmartTeleportToLobby(...)
    end
    pcall(function()
        local sharedMod = ReplicatedStorage:FindFirstChild("Shared")
        local modules = sharedMod and sharedMod:FindFirstChild("Modules")
        local newNet = modules and modules:FindFirstChild("NewNetwork")
        if newNet then
            local NewNetwork = require(newNet)
            NewNetwork.Channel("Teleport"):fireServer("backToLobby")
        end
    end)
    pcall(function()
        local netFolder = ReplicatedStorage:FindFirstChild("Network")
        local tpFolder = netFolder and netFolder:FindFirstChild("Teleport")
        local reBack = tpFolder and tpFolder:FindFirstChild("RE:backToLobby")
        if reBack and reBack:IsA("RemoteEvent") then
            reBack:FireServer()
        end
    end)
    pcall(function()
        local rf = ReplicatedStorage:FindFirstChild("RemoteFunction")
        local re = ReplicatedStorage:FindFirstChild("RemoteEvent")
        if re then re:FireServer("Teleport", "backToLobby") end
        if rf then rf:InvokeServer("Teleport", "backToLobby") end
    end)
end
local AutoGoldModule = {
    CrateConfigs = (ProgressionConfig and ProgressionConfig.AutoCurrency) or {},
    Configs = (ProgressionConfig and ProgressionConfig.AutoCurrency) or {},
    cachedMapDisplays = nil,
    lastMapDisplayScanTime = 0,
    AutoGatlingRunning = false,
    GatlingExecuted = false,
}

function AutoGoldModule.ExecuteGatlingLoader(forceChoice: string?)
    local choice = forceChoice
        or (State and State.AdvancFunc and State.AdvancFunc.SelectedGatling)
        or (Globals and Globals.SelectedGatling)
        or "Railgun"

    local gatlingUrl = (choice == "Gatlify")
        and "https://raw.githubusercontent.com/avtryxz/Gatlify/refs/heads/main/Gatlify.lua"
        or "https://raw.githubusercontent.com/avtryxz/autogutlin/refs/heads/main/autogutlin.lua"

    AutoGoldModule.GatlingExecuted = true
    Logger:Info(string.format("Auto Gatling: Loading %s script from %s...", choice, gatlingUrl))
    if Window and typeof(Window.Notify) == "function" then
        pcall(function()
            Window:Notify({
                Title = "Auto Gatling",
                Desc = string.format("Executing %s loader...", choice),
                Duration = 2.5,
            })
        end)
    end

    task.spawn(function()
        local ok, err = pcall(function()
            local chunk = game:HttpGet(gatlingUrl)
            local fn = loadstring(chunk)
            if fn then fn() end
        end)
        if ok then
            Logger:Success(string.format("Auto Gatling: %s loaded successfully.", choice))
            if Window and typeof(Window.Notify) == "function" then
                pcall(function()
                    Window:Notify({
                        Title = "Auto Gatling",
                        Desc = string.format("%s loaded successfully!", choice),
                        Duration = 3,
                    })
                end)
            end
        else
            Logger:Warn(string.format("Auto Gatling: Failed loading %s: %s", choice, tostring(err)))
            if Window and typeof(Window.Notify) == "function" then
                pcall(function()
                    Window:Notify({
                        Title = "Auto Gatling Error",
                        Desc = "Failed to load " .. tostring(choice) .. ": " .. tostring(err),
                        Duration = 4,
                    })
                end)
            end
        end
    end)
end

function AutoGoldModule.StartAutoGatling()
    if AutoGoldModule.AutoGatlingRunning then return end
    local isEnabled = (State and State.AdvancFunc and (State.AdvancFunc.AutoGatling or State.AdvancFunc.ConditionGatlingLoader))
        or (Globals and (Globals.AutoGatling or Globals.ConditionGatlingLoader))
    if not isEnabled then return end
    AutoGoldModule.AutoGatlingRunning = true

    task.spawn(function()
        while (State and State.AdvancFunc and (State.AdvancFunc.AutoGatling or State.AdvancFunc.ConditionGatlingLoader))
            or (Globals and (Globals.AutoGatling or Globals.ConditionGatlingLoader)) do
            if game.PlaceId ~= 3260590327 then
                if not AutoGoldModule.GatlingExecuted then
                    task.wait(2) -- Allow placements and match initialization
                    if State and State.AdvancFunc and State.AdvancFunc.AutoGatling then
                        AutoGoldModule.ExecuteGatlingLoader(State.AdvancFunc.SelectedGatling or "Railgun")
                    elseif State and State.AdvancFunc and State.AdvancFunc.ConditionGatlingLoader then
                        AutoGoldModule.ExecuteGatlingLoader(State.AdvancFunc.ConditionGatlingScript or "Railgun")
                    end
                end
            else
                AutoGoldModule.GatlingExecuted = false
            end
            task.wait(1)
        end
        AutoGoldModule.AutoGatlingRunning = false
    end)
end

function AutoGoldModule.CastMapVote(mapId, posVec)
    local targetMap = mapId or "Lay By"
    local targetPos = posVec or Vector3.new(0, 0, 0)
    local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
    local remoteFunc = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if remoteEvent then
        remoteEvent:FireServer("LobbyVoting", "Vote", targetMap, targetPos)
    elseif remoteFunc then
        remoteFunc:InvokeServer("LobbyVoting", "Vote", targetMap, targetPos)
    end
end

function AutoGoldModule.LobbyReadyUp()
    pcall(function()
        local remoteFunc = ReplicatedStorage:FindFirstChild("RemoteFunction")
        if remoteFunc and remoteFunc:IsA("RemoteFunction") then
            remoteFunc:InvokeServer("LobbyVoting", "Ready")
        end
    end)
    pcall(function()
        local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireServer("LobbyVoting", "Ready")
        end
    end)
    pcall(function()
        local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
        local rgi = pg and pg:FindFirstChild("ReactGameIntermission")
        local readyBtn = rgi and rgi:FindFirstChild("Frame") and rgi.Frame:FindFirstChild("buttons") and rgi.Frame.buttons:FindFirstChild("ready")
        if readyBtn then
            if firesignal and readyBtn:FindFirstChild("Activated") then
                firesignal(readyBtn.Activated)
            end
            if getconnections then
                for _, conn in ipairs(getconnections(readyBtn.Activated)) do
                    if conn and conn.Function then pcall(conn.Function) end
                end
            end
        end
    end)
    pcall(function()
        local netMod = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Modules") and ReplicatedStorage.Shared.Modules:FindFirstChild("Network")
        if netMod then
            local net = require(netMod)
            if net and net.Channel then
                local chan = net.Channel("LobbyVoting")
                if chan and chan.Broadcast then
                    chan:Broadcast("Ready")
                end
            end
        end
    end)
    pcall(function()
        local gm = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("GameManager")
        local readyRemote = gm and (gm:FindFirstChild("Ready") or gm:FindFirstChild("RE:Ready"))
        if readyRemote then
            if readyRemote:IsA("RemoteEvent") then
                readyRemote:FireServer()
            elseif readyRemote:IsA("RemoteFunction") then
                readyRemote:InvokeServer()
            end
        end
    end)
end

function AutoGoldModule.SelectMapOverride(mapId, ...)
    local args = { ... }
    local remoteFunc = ReplicatedStorage:FindFirstChild("RemoteFunction")

    if args[#args] == "vip" and remoteFunc then
        remoteFunc:InvokeServer("LobbyVoting", "Override", mapId)
    end

    task.wait(2)
    AutoGoldModule.CastMapVote(mapId, Vector3.new(12.59, 10.64, 52.01))
    task.wait(0.5)
    AutoGoldModule.LobbyReadyUp()
end

function AutoGoldModule.GetAvailableMaps()
    local available = {}
    pcall(function()
        local now = os.time()
        if not AutoGoldModule.cachedMapDisplays or #AutoGoldModule.cachedMapDisplays == 0 or (now - AutoGoldModule.lastMapDisplayScanTime > 8) then
            AutoGoldModule.cachedMapDisplays = {}
            AutoGoldModule.lastMapDisplayScanTime = now
            local searchContainers = {}
            for _, folderName in ipairs({ "Elevators", "Intermission", "Voting", "Lobby", "MapDisplays" }) do
                local f = workspace:FindFirstChild(folderName)
                if f then table.insert(searchContainers, f) end
            end
            if #searchContainers == 0 then
                for _, child in ipairs(workspace:GetChildren()) do
                    if child:IsA("Model") or child:IsA("Folder") then
                        table.insert(searchContainers, child)
                    end
                end
            end
            for _, container in ipairs(searchContainers) do
                for _, inst in ipairs(container:GetDescendants()) do
                    if (inst.Name == "MapDisplay" or inst.Name:lower():find("mapdisplay") or inst.Name:lower():find("mapvote")) and (inst:IsA("SurfaceGui") or inst:IsA("BillboardGui")) then
                        table.insert(AutoGoldModule.cachedMapDisplays, inst)
                    end
                end
            end
            if #AutoGoldModule.cachedMapDisplays == 0 then
                for _, inst in ipairs(workspace:GetDescendants()) do
                    if (inst.Name == "MapDisplay" or inst.Name:lower():find("mapdisplay")) and (inst:IsA("SurfaceGui") or inst:IsA("BillboardGui")) then
                        table.insert(AutoGoldModule.cachedMapDisplays, inst)
                    end
                end
            end
        end

        if AutoGoldModule.cachedMapDisplays then
            for _, display in ipairs(AutoGoldModule.cachedMapDisplays) do
                if display and display.Parent then
                    local title = display:FindFirstChild("Title")
                    if title and title:IsA("TextLabel") and title.Text and title.Text ~= "" then
                        local t = title.Text:gsub("^%s*(.-)%s*$", "%1")
                        if #t > 1 then available[t] = true end
                    else
                        for _, d in ipairs(display:GetDescendants()) do
                            if (d:IsA("TextLabel") or d:IsA("TextBox")) and d.Visible and d.Text and d.Text ~= "" then
                                local t = d.Text:gsub("^%s*(.-)%s*$", "%1")
                                if #t > 2 and not t:find("Vote") and not t:find("Map") and not t:find("Player") then
                                    available[t] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    return available
end

function AutoGoldModule.IsMapAvailable(targetMap)
    local maps = AutoGoldModule.GetAvailableMaps()
    if maps[targetMap] then return true end
    for m, _ in pairs(maps) do
        if m:lower() == targetMap:lower() or m:lower():find(targetMap:lower(), 1, true) then
            return true
        end
    end
    return false
end

function AutoGoldModule.TriggerVeto()
    pcall(function()
        local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
        local remoteFunc = ReplicatedStorage:FindFirstChild("RemoteFunction")
        if remoteEvent then
            remoteEvent:FireServer("LobbyVoting", "Veto")
        elseif remoteFunc then
            remoteFunc:InvokeServer("LobbyVoting", "Veto")
        end
    end)
end

local function CastModifierVote(modsTable)
    if not modsTable or type(modsTable) ~= "table" or not next(modsTable) then
        return false
    end

    local bulkModifiers = nil
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Network")
        local modsFolder = net and net:FindFirstChild("Modifiers")
        bulkModifiers = modsFolder and modsFolder:FindFirstChild("RF:BulkVoteModifiers")
    end)
    if not bulkModifiers then
        pcall(function()
            bulkModifiers = ReplicatedStorage:FindFirstChild("RF:BulkVoteModifiers", true)
        end)
    end

    local modRep = nil
    pcall(function()
        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
        modRep = stateReps and stateReps:FindFirstChild("ModifierReplicator")
    end)
    if not modRep then
        pcall(function()
            modRep = ReplicatedStorage:FindFirstChild("ModifierReplicator", true)
        end)
    end

    local available = {}
    if modRep then
        local raw = modRep:GetAttribute("Available")
        if type(raw) == "string" then
            local clean = raw:match("{.+}")
            if clean then
                pcall(function()
                    available = HttpService:JSONDecode(clean)
                end)
            end
        end
    end

    local selectedMods = {}
    local votedNames = {}
    for k, v in pairs(modsTable) do
        local modName = (type(k) == "string" and k ~= "") and k or (type(v) == "string" and v)
        if modName and (v == true or type(v) == "string") then
            if not next(available) or available[modName] == true then
                selectedMods[modName] = true
                table.insert(votedNames, modName)
            else
                warn(string.format("[Modifier Voting] Modifier '%s' is not in available pool.", tostring(modName)))
            end
        end
    end

    if next(selectedMods) and bulkModifiers then
        warn(string.format("══════════════════════════════════════════════════════════════════════\n>>> [VOTING MODIFIERS] <<< Active Modifiers: %s\n══════════════════════════════════════════════════════════════════════", table.concat(votedNames, ", ")))
        if Logger and typeof(Logger.Info) == "function" then
            pcall(function() Logger:Info("Modifier Voting: Dispatched bulk modifier vote for: " .. table.concat(votedNames, ", ")) end)
        end
        local ok, res = pcall(function()
            return bulkModifiers:InvokeServer(selectedMods)
        end)
        if ok then
            if Logger and typeof(Logger.Success) == "function" then
                pcall(function() Logger:Success("Modifier Voting: Successfully voted modifiers!") end)
            end
            return true
        else
            warn("[Modifier Voting] Failed invoking RF:BulkVoteModifiers: " .. tostring(res))
        end
    elseif not bulkModifiers then
        warn("[Modifier Voting] RF:BulkVoteModifiers remote not located in ReplicatedStorage.")
    end
    return false
end

AutoGoldModule.CastModifierVote = CastModifierVote

function AutoGoldModule.WaitForIntermissionLoaded(timeout)
    timeout = timeout or 25
    local startTime = tick()
    local lp = Players.LocalPlayer or LocalPlayer
    local pg = lp and (lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5))

    -- Wait until the loading screen is dismissed
    while (tick() - startTime < timeout) do
        local isLoading = false
        if lp and lp:GetAttribute("Loading") == true then
            isLoading = true
        end
        if pg then
            local ls = pg:FindFirstChild("LoadingScreen")
            if ls and ls.Enabled then
                local content = ls:FindFirstChild("content")
                if content then
                    if content.Visible then isLoading = true end
                else
                    isLoading = true
                end
            end
            local rol = pg:FindFirstChild("ReactOverridesLoading")
            if rol and rol.Enabled then
                local tb = rol:FindFirstChild("TextButton")
                if tb and tb.Visible then isLoading = true end
            end
        end
        if not isLoading then
            break
        end
        task.wait(0.2)
    end

    task.wait(0.5) -- Brief settle time for map boards & remotes
    return true
end

function AutoGoldModule.CheckIsVipOrPrivateServer()
    if Globals then
        if Globals.PrivateCode and Globals.PrivateCode ~= "" then return true end
        if Globals.PrivateServerCode and Globals.PrivateServerCode ~= "" then return true end
        if Globals.IsVIP or Globals.VIP or Globals.PrivateServer then return true end
    end
    if State and State.Misc then
        if (State.Misc.PrivateCode and State.Misc.PrivateCode ~= "") or (State.Misc.PrivateServerCode and State.Misc.PrivateServerCode ~= "") then
            return true
        end
    end

    local isPriv = false
    pcall(function()
        if game.PrivateServerId and game.PrivateServerId ~= "" then isPriv = true end
        if game.PrivateServerOwnerId and game.PrivateServerOwnerId ~= 0 then isPriv = true end
    end)
    if isPriv then return true end

    local rs = game:GetService("ReplicatedStorage")
    local stateReps = rs:FindFirstChild("StateReplicators")
    local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
    if gsr then
        if gsr:GetAttribute("IsPrivateServer") == true then return true end
        local clientMods = gsr:GetAttribute("ClientModifiers")
        if type(clientMods) == "string" and clientMods:find("LegacyVIP") then return true end
    end

    if stateReps then
        local pr = stateReps:FindFirstChild("PlayerReplicator")
        if pr then
            if pr:GetAttribute("LegacyVIP") == true or pr:GetAttribute("VIPPlus") == true then
                return true
            end
        end
    end

    local lp = Players.LocalPlayer or LocalPlayer
    if lp and lp.UserId and lp.UserId > 0 then
        local ms = game:GetService("MarketplaceService")
        local vipPasses = { 10518590, 6745137, 6912306 }
        for _, passId in ipairs(vipPasses) do
            local ok, owned = pcall(function()
                return ms:UserOwnsGamePassAsync(lp.UserId, passId)
            end)
            if ok and owned then
                return true
            end
        end
    end

    return false
end

function AutoGoldModule.AttemptMapOverride(targetMap)
    if not targetMap or targetMap == "" or targetMap == "Unknown" then return false end
    local overridden = false
    local rs = game:GetService("ReplicatedStorage")
    local rf = rs:FindFirstChild("RemoteFunction")
    local re = rs:FindFirstChild("RemoteEvent")

    if rf then
        local ok, res = pcall(function()
            return rf:InvokeServer("LobbyVoting", "Override", targetMap)
        end)
        if ok and (res == true or res == nil) then
            overridden = true
        end
    end
    if re then
        pcall(function()
            re:FireServer("LobbyVoting", "Override", targetMap)
        end)
    end

    task.wait(1.5)
    pcall(AutoGoldModule.CastMapVote, targetMap, Vector3.new(12.59, 10.64, 52.01))
    task.wait(0.5)
    AutoGoldModule.LobbyReadyUp()
    return overridden
end

function AutoGoldModule.GameInfo(name, list)
    local targetMaps = (type(name) == "table" and name) or { name }
    local targetMap = targetMaps[1] or "Simplicity"

    -- 1. WAIT UNTIL USERS ARE FULLY LOADED IN INTERMISSION
    AutoGoldModule.WaitForIntermissionLoaded(30)

    local modifiers = (list and next(list)) and list or (Globals and Globals.Modifiers)
    if modifiers and type(modifiers) == "table" and next(modifiers) then
        task.spawn(function()
            CastModifierVote(modifiers)
            task.wait(1.5)
            CastModifierVote(modifiers)
        end)
    end

    local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
    local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
    local gameStateReplicator = stateReps and stateReps:FindFirstChild("GameStateReplicator")

    -- 2. CHECK VIP / PRIVATE SERVER
    local isVipOrPrivate = AutoGoldModule.CheckIsVipOrPrivateServer()

    if isVipOrPrivate then
        warn(string.format(">>> [AutoGoldModule.GameInfo] VIP / Private Server detected. Overriding map to '%s'...", tostring(targetMap)))
        if Logger and typeof(Logger.Info) == "function" then
            pcall(function() Logger:Info("VIP/Private Server: Overriding map to " .. tostring(targetMap)) end)
        end
        AutoGoldModule.AttemptMapOverride(targetMap)
        task.wait(0.5)
        AutoGoldModule.LobbyReadyUp()
        local hostWaitStart = tick()
        repeat
            task.wait(1)
            AutoGoldModule.LobbyReadyUp()
            local started = (gameStateReplicator and (gameStateReplicator:GetAttribute("GameStarted") == true or (gameStateReplicator:GetAttribute("Wave") or 0) > 0))
            local hotbar = pg and (pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
            if started or hotbar then break end
        until (tick() - hostWaitStart >= 35)
        return targetMap
    end

    -- 3. PUBLIC SERVER: Check if map is on boards. If not, Veto. If still not, smartLobby!
    warn(string.format(">>> [AutoGoldModule.GameInfo] Public Server: Checking boards for '%s'...", tostring(targetMap)))

    local foundValidMap = nil
    local scanStart = tick()
    while (tick() - scanStart < 8) do
        for _, mapName in ipairs(targetMaps) do
            if AutoGoldModule.IsMapAvailable(mapName) then
                foundValidMap = mapName
                break
            end
        end
        if foundValidMap then break end
        task.wait(0.5)
    end

    if foundValidMap then
        warn(string.format(">>> [AutoGoldModule.GameInfo] Public Server: Found '%s' on initial boards! Voting...", tostring(foundValidMap)))
        AutoGoldModule.SelectMapOverride(foundValidMap)
        task.wait(0.5)
        AutoGoldModule.LobbyReadyUp()
        local hostVoteWaitStart = tick()
        repeat
            task.wait(1)
            AutoGoldModule.LobbyReadyUp()
            local started = (gameStateReplicator and (gameStateReplicator:GetAttribute("GameStarted") == true or (gameStateReplicator:GetAttribute("Wave") or 0) > 0))
            local hotbar = pg and (pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
            if started or hotbar then break end
        until (tick() - hostVoteWaitStart >= 35)
        return foundValidMap
    end

    -- Not found -> Trigger Veto!
    warn(string.format(">>> [AutoGoldModule.GameInfo] Public Server: Map '%s' not found on boards. Triggering Veto...", tostring(targetMap)))
    if Logger and typeof(Logger.Info) == "function" then
        pcall(function() Logger:Info(string.format("Auto Currency: Target map (%s) not found on boards. Triggering Veto vote...", tostring(targetMap))) end)
    end
    AutoGoldModule.TriggerVeto()
    AutoGoldModule.cachedMapDisplays = nil
    AutoGoldModule.lastMapDisplayScanTime = 0

    local vetoRerollStart = tick()
    while (tick() - vetoRerollStart < 10) do
        task.wait(0.5)
        for _, mapName in ipairs(targetMaps) do
            if AutoGoldModule.IsMapAvailable(mapName) then
                foundValidMap = mapName
                break
            end
        end
        if foundValidMap then break end
    end

    if foundValidMap then
        warn(string.format(">>> [AutoGoldModule.GameInfo] Public Server: Found '%s' after Veto reroll! Voting...", tostring(foundValidMap)))
        AutoGoldModule.SelectMapOverride(foundValidMap)
        task.wait(0.5)
        AutoGoldModule.LobbyReadyUp()
        local hostVoteWaitStart = tick()
        repeat
            task.wait(1)
            AutoGoldModule.LobbyReadyUp()
            local started = (gameStateReplicator and (gameStateReplicator:GetAttribute("GameStarted") == true or (gameStateReplicator:GetAttribute("Wave") or 0) > 0))
            local hotbar = pg and (pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
            if started or hotbar then break end
        until (tick() - hostVoteWaitStart >= 35)
        return foundValidMap
    end

    -- STILL NOT FOUND AFTER VETO -> RETURN TO LOBBY VIA SMARTLOBBY!
    warn(string.format(">>> [AutoGoldModule.GameInfo] Public Server: Map '%s' STILL NOT FOUND after Veto! Returning to lobby via smartLobby...", tostring(targetMap)))
    if Logger and typeof(Logger.Warn) == "function" then
        pcall(function() Logger:Warn(string.format("Auto Currency: Target map (%s) still not found on boards after Veto. Returning to lobby via smartLobby...", tostring(targetMap))) end)
    end
    local tp = SmartTeleportToLobby or (Globals and Globals.SmartTeleportToLobby) or AutoGoldModule.SmartTeleportToLobby
    if tp then
        pcall(tp)
    else
        pcall(function()
            local rf = ReplicatedStorage:FindFirstChild("RemoteFunction")
            local re = ReplicatedStorage:FindFirstChild("RemoteEvent")
            if re then re:FireServer("Teleport", "backToLobby") end
            if rf then rf:InvokeServer("Teleport", "backToLobby") end
            TeleportService:Teleport(3260590327)
        end)
    end
    -- Halt execution permanently so we never ready up or start on the wrong map
    while true do
        task.wait(2)
        if tp then pcall(tp) else pcall(function() TeleportService:Teleport(3260590327) end) end
    end
    return nil
end

local function resolveDynamicCurrencyConfig(rawConfig, playerLevel)
    if type(rawConfig) ~= "table" then return nil end

    local candidates = {}
    for k, v in pairs(rawConfig) do
        if type(v) == "table" and (v.Level ~= nil or v.level ~= nil) and (v.Mode ~= nil or v.mode ~= nil) then
            local lvl = tonumber(v.Level or v.level) or 0
            table.insert(candidates, { key = k, level = lvl, config = v })
        end
    end

    if #candidates == 0 then
        return rawConfig
    end

    table.sort(candidates, function(a, b)
        return a.level < b.level
    end)

    -- Select the highest eligible bracket where level is met AND required towers are owned
    -- Falls back down to lower tier (e.g. Level 0 Casual) if higher tier towers aren't yet owned
    local chosen = candidates[1]
    for i = #candidates, 1, -1 do
        local item = candidates[i]
        if playerLevel >= item.level then
            local reqTowers = item.config.TowerRequirments or item.config.Towers or item.config.towers
            local hasAllReqTowers = true
            if type(reqTowers) == "table" and PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" then
                for _, t in ipairs(reqTowers) do
                    if t and t ~= "" and not PlayerDataHandler:IsTowerOwned(t) then
                        hasAllReqTowers = false
                        break
                    end
                end
            end
            if hasAllReqTowers then
                chosen = item
                break
            end
        end
    end

    return chosen.config
end

local function AutoCurrencyCheckerImpl(optFarmType, optStrat)
    local farmType = optFarmType or (Globals and Globals.AutoFarmType) or "Coins"
    if farmType == "Levels" then
        farmType = (State and State.AutoCurrency and State.AutoCurrency.Levels and State.AutoCurrency.Levels.Currency)
            or (Settings and Settings:Get("AutoLevelsCurrency", "Coins"))
            or "Coins"
    end
    local stratChoice = optStrat or (Globals and Globals.Strat) or "Lose"
    local playerLevel = PlayerDataHandler and typeof(PlayerDataHandler.GetLevel) == "function" and PlayerDataHandler:GetLevel() or 0

    local category = (AutoGoldModule and AutoGoldModule.CrateConfigs and AutoGoldModule.CrateConfigs[farmType])
        or (ProgressionConfig and ProgressionConfig.AutoCurrency and ProgressionConfig.AutoCurrency[farmType])
        or (Settings and Settings.AutoCurrency and Settings.AutoCurrency[farmType])
    local config = category and category[stratChoice]

    if not config and AutoGoldModule and AutoGoldModule.CrateConfigs then
        config = AutoGoldModule.CrateConfigs[stratChoice]
    end

    config = resolveDynamicCurrencyConfig(config, playerLevel)

    local result = {
        farmType = farmType,
        stratChoice = stratChoice,
        targetMode = config and (config.Mode or config.mode) or "Unknown",
        configFound = (config ~= nil),
        requiredLevel = config and (config.Level or config.level) or 0,
        playerLevel = playerLevel,
        levelPassed = true,
        missingTowers = {},
        missingGold = {},
        missingSkills = {},
        missingParts = {},
        isEligible = false,
        config = config,
    }

    if not config then
        table.insert(result.missingParts, "Config Missing")
        return result
    end

    -- 1. Level Check
    local reqLevel = config.Level or config.level or 0
    result.requiredLevel = reqLevel
    result.levelPassed = (playerLevel >= reqLevel)
    if not result.levelPassed then
        table.insert(result.missingParts, string.format("Level %d (You: %d)", reqLevel, playerLevel))
    end

    -- 2. Towers Check
    local towersConfig = config.TowerRequirments or config.Towers or config.towers
    if type(towersConfig) == "table" and PlayerDataHandler then
        for _, tower in ipairs(towersConfig) do
            if tower and tower ~= "" and not PlayerDataHandler:IsTowerOwned(tower) then
                table.insert(result.missingTowers, tower)
            end
        end
        if #result.missingTowers > 0 and game.PlaceId == LOBBY_PLACE_ID and Globals and Globals.AutoBuyMissingTowers == true and typeof(attemptBuyMissingTowersList) == "function" then
            local boughtAny = attemptBuyMissingTowersList(result.missingTowers)
            if boughtAny then
                local remaining = {}
                for _, tower in ipairs(towersConfig) do
                    if tower and tower ~= "" and not PlayerDataHandler:IsTowerOwned(tower) then
                        table.insert(remaining, tower)
                    end
                end
                result.missingTowers = remaining
            end
        end
    end
    if #result.missingTowers > 0 then
        table.insert(result.missingParts, "Towers: " .. table.concat(result.missingTowers, ", "))
    end

    -- 3. Golden Check
    local goldReqs = config.Golden or config.golden
    if type(goldReqs) == "table" and #goldReqs > 0 and PlayerDataHandler then
        for _, goldTower in ipairs(goldReqs) do
            if goldTower and goldTower ~= "" and not PlayerDataHandler:IsGoldenOwned(goldTower) then
                table.insert(result.missingGold, goldTower)
            end
        end
    end
    if #result.missingGold > 0 then
        table.insert(result.missingParts, "Golden: " .. table.concat(result.missingGold, ", "))
    end

    -- 4. Skill Tree Check
    local skillReqs = config.SkillTree or config["Skill Tree"] or config.skillTree
    if type(skillReqs) == "table" and next(skillReqs) then
        local userSkills = getSkillTreeDict()
        for skillName, reqNodeLevel in pairs(skillReqs) do
            local haveLevel = getSkillLevel(userSkills, skillName)
            if haveLevel < reqNodeLevel then
                table.insert(result.missingSkills, string.format("%s (Need %d, Have %d)", skillName, reqNodeLevel, haveLevel))
            end
        end
    end
    if #result.missingSkills > 0 then
        table.insert(result.missingParts, "Skill Tree: " .. table.concat(result.missingSkills, ", "))
    end

    result.isEligible = result.levelPassed and (#result.missingTowers == 0) and (#result.missingGold == 0) and (#result.missingSkills == 0)
    return result
end

local AutoCurrencyChecker = setmetatable({
    Check = function(optFarmType, optStrat)
        return AutoCurrencyCheckerImpl(optFarmType, optStrat)
    end
}, {
    __call = function(_, optFarmType, optStrat)
        return AutoCurrencyCheckerImpl(optFarmType, optStrat)
    end
})

local AutoEvoModule = {
    EvoData = (ProgressionConfig and ProgressionConfig.EvoData) or {
        ["Scout"] = { Evo = "EvolvedOperator", Coins = 15000, Gems = 4500, Order = 1 },
        ["Shotgunner"] = { Evo = "EvolvedEnforcer", Coins = 15000, Gems = 4750, Order = 2 },
        ["Crook Boss"] = { Evo = "EvolvedKingpin", Coins = 15000, Gems = 5500, Order = 3 },
        ["Minigunner"] = { Evo = "EvolvedJuggernaut", Coins = 15000, Gems = 6000, Order = 4 },
    },
    Configs = (ProgressionConfig and ProgressionConfig.AutoEvoConfigs) or {},
    buyingDebounce = false,
}

function AutoEvoModule.NormalizeTowerName(name: string?): string
    if not name then return "Scout" end
    local s = tostring(name):gsub("^%s+", ""):gsub("%s+$", "")
    if s:lower() == "kingpin" or s:lower() == "kingping" or s:lower() == "evolvedkingpin" then
        return "Crook Boss"
    end
    return s
end

function AutoEvoModule.GetTowerList(): { string }
    local list = {}
    local src = AutoEvoModule.EvoData
    if type(src) == "table" then
        for towerName in pairs(src) do
            table.insert(list, towerName)
        end
        table.sort(list, function(a, b)
            local oa = (type(src[a]) == "table" and src[a].Order) or 999
            local ob = (type(src[b]) == "table" and src[b].Order) or 999
            if oa ~= ob then return oa < ob end
            return a < b
        end)
    end
    if #list == 0 then
        list = { "Scout", "Shotgunner", "Crook Boss", "Minigunner" }
    end
    return list
end

function AutoEvoModule.IsTowerOrEvoOwned(towerName: string): boolean
    local eData = AutoEvoModule.EvoData[towerName]
    local evoName = eData and eData.Evo or towerName
    if PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" then
        local ownsBase = false
        local ownsEvo = false
        pcall(function() ownsBase = PlayerDataHandler:IsTowerOwned(towerName) end)
        pcall(function() ownsEvo = PlayerDataHandler:IsTowerOwned(evoName) end)
        return (ownsBase == true) or (ownsEvo == true)
    end
    return true
end

function AutoEvoModule.IsTowerEvoComplete(towerName: string): boolean
    local eData = AutoEvoModule.EvoData[towerName]
    local evoName = eData and eData.Evo or towerName

    local ownsEvo = false
    if PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" then
        pcall(function() ownsEvo = PlayerDataHandler:IsTowerOwned(evoName) end)
    end
    if not ownsEvo then return false end

    local evoExp = nil
    if PlayerDataHandler and typeof(PlayerDataHandler.GetTowerExp) == "function" then
        pcall(function() evoExp = PlayerDataHandler:GetTowerExp(evoName) end)
    end
    if evoExp and type(evoExp.Level) == "number" then
        return evoExp.Level >= 20
    end
    return true
end

function AutoEvoModule.AnalyzeRequirements(optTargetEvo: string?, optStrat: string?)
    local target = optTargetEvo or (State and State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Target) or (Globals and Globals.TargetEvo) or "All"
    target = AutoEvoModule.NormalizeTowerName(target)
    local stratChoice = optStrat or (State and State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Strategy) or (Globals and Globals.EvoStrat) or "Lose"

    local playerLevel = PlayerDataHandler and typeof(PlayerDataHandler.GetLevel) == "function" and PlayerDataHandler:GetLevel() or 0
    local coins = 0
    local gems = 0
    if PlayerDataHandler then
        if typeof(PlayerDataHandler.GetCoins) == "function" then
            pcall(function() coins = PlayerDataHandler:GetCoins() or 0 end)
        end
        if typeof(PlayerDataHandler.GetGems) == "function" then
            pcall(function() gems = PlayerDataHandler:GetGems() or 0 end)
        end
    end

    local toCheck = {}
    if target == "All" then
        for _, tName in ipairs(AutoEvoModule.GetTowerList()) do
            if not AutoEvoModule.IsTowerEvoComplete(tName) and AutoEvoModule.IsTowerOrEvoOwned(tName) then
                table.insert(toCheck, tName)
            end
        end
    elseif AutoEvoModule.EvoData[target] then
        toCheck = { target }
    end

    local result = {
        targetEvo = target,
        stratChoice = stratChoice,
        activeTower = nil,
        farmType = nil,
        targetMode = "Unknown",
        configFound = false,
        allFinished = (#toCheck == 0),
        readyToBuy = false,
        isEligible = false,
        missingBase = {},
        missingTowers = {},
        missingGold = {},
        missingSkills = {},
        requiredLevel = 0,
        playerLevel = playerLevel,
        levelPassed = true,
        missingParts = {},
        config = nil,
    }

    if #toCheck == 0 then
        if target == "All" then
            result.allFinished = true
            result.configFound = true
            result.isEligible = false
            return result
        else
            table.insert(result.missingParts, "No Target Selected")
            return result
        end
    end

    local activeTower = nil
    local activeFarmType = nil
    local activeReadyToBuy = false
    local missingBaseMap = {}

    for _, towerName in ipairs(toCheck) do
        local eData = AutoEvoModule.EvoData[towerName]
        local evoName = eData and eData.Evo or towerName

        local ownsEvo = false
        if PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" then
            pcall(function() ownsEvo = PlayerDataHandler:IsTowerOwned(evoName) end)
        end

        if ownsEvo then
            local evoExp = nil
            if PlayerDataHandler and typeof(PlayerDataHandler.GetTowerExp) == "function" then
                pcall(function() evoExp = PlayerDataHandler:GetTowerExp(evoName) end)
            end
            local evoLevel = evoExp and evoExp.Level or 20
            if evoLevel < 20 then
                result.allFinished = false
                if not activeTower then
                    activeTower = towerName
                    activeFarmType = "Gems"
                end
            end
        else
            result.allFinished = false
            local ownsBase = false
            if PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" then
                pcall(function() ownsBase = PlayerDataHandler:IsTowerOwned(towerName) end)
            end

            if not ownsBase then
                missingBaseMap[towerName] = true
                table.insert(result.missingBase, towerName)
                if not activeTower then
                    activeTower = towerName
                end
            else
                local expData = nil
                if PlayerDataHandler and typeof(PlayerDataHandler.GetTowerExp) == "function" then
                    pcall(function() expData = PlayerDataHandler:GetTowerExp(towerName) end)
                end
                local baseLevel = expData and expData.Level or 0
                local coinsNeed = eData and math.max(0, eData.Coins - coins) or 0
                local gemsNeed = eData and math.max(0, eData.Gems - gems) or 0

                if not activeTower then
                    activeTower = towerName
                    if coinsNeed == 0 and gemsNeed == 0 then
                        if baseLevel < 20 then
                            activeFarmType = "Gems"
                        else
                            activeReadyToBuy = true
                        end
                    elseif coinsNeed > 0 then
                        activeFarmType = "Coins"
                    else
                        activeFarmType = "Gems"
                    end
                end
            end
        end
    end

    result.activeTower = activeTower
    result.farmType = activeFarmType
    result.readyToBuy = activeReadyToBuy

    -- If all targets are completely evolved & level 20:
    if result.allFinished then
        result.isEligible = false
        result.configFound = true
        return result
    end

    -- If the active tower's base tower is not owned:
    if activeTower and missingBaseMap[activeTower] then
        table.insert(result.missingParts, "Base Tower: " .. activeTower)
        result.isEligible = false
        result.configFound = true
        return result
    end

    -- If ready to evolve/buy directly in lobby:
    if activeReadyToBuy then
        result.isEligible = true
        result.configFound = true
        return result
    end

    -- Needs to farm either Coins or Gems:
    local farmType = activeFarmType or "Coins"
    local actualStrat = stratChoice
    if farmType == "Gems" and actualStrat == "Win" then
        actualStrat = "Lose" -- Hardcore gems only has Lose strategy
    end
    result.farmType = farmType
    result.stratChoice = actualStrat

    local category = AutoEvoModule.Configs and AutoEvoModule.Configs[farmType]
    local config = category and category[actualStrat]

    if not config then
        table.insert(result.missingParts, "Config Missing (" .. farmType .. " " .. actualStrat .. ")")
        result.isEligible = false
        return result
    end

    result.configFound = true
    result.config = config
    result.targetMode = config.Mode or "Unknown"

    -- 1. Level Check
    local reqLevel = config.Level or 0
    result.requiredLevel = reqLevel
    result.levelPassed = (playerLevel >= reqLevel)
    if not result.levelPassed then
        table.insert(result.missingParts, string.format("Level %d (You: %d)", reqLevel, playerLevel))
    end

    -- 2. Towers Check (Strategy Loadout)
    local towersConfig = config.Towers
    local stratTowers = {}
    if type(towersConfig) == "table" then
        if activeTower and towersConfig[activeTower] then
            stratTowers = towersConfig[activeTower]
        elseif #towersConfig > 0 then
            stratTowers = towersConfig
        end
    end

    if type(stratTowers) == "table" and PlayerDataHandler then
        for _, tower in ipairs(stratTowers) do
            if tower and tower ~= "" and not PlayerDataHandler:IsTowerOwned(tower) then
                table.insert(result.missingTowers, tower)
            end
        end
    end
    if #result.missingTowers > 0 then
        table.insert(result.missingParts, "Towers: " .. table.concat(result.missingTowers, ", "))
    end

    -- 3. Golden Check
    local goldReqs = config.Golden or config.golden
    if type(goldReqs) == "table" and #goldReqs > 0 and PlayerDataHandler then
        for _, goldTower in ipairs(goldReqs) do
            if goldTower and goldTower ~= "" and not PlayerDataHandler:IsGoldenOwned(goldTower) then
                table.insert(result.missingGold, goldTower)
            end
        end
    end
    if #result.missingGold > 0 then
        table.insert(result.missingParts, "Golden: " .. table.concat(result.missingGold, ", "))
    end

    -- 4. Skill Tree Check
    local skillReqs = config.SkillTree or config["Skill Tree"] or config.skillTree
    if type(skillReqs) == "table" and next(skillReqs) then
        local userSkills = getSkillTreeDict()
        for skillName, reqNodeLevel in pairs(skillReqs) do
            local haveLevel = getSkillLevel(userSkills, skillName)
            if haveLevel < reqNodeLevel then
                table.insert(result.missingSkills, string.format("%s (Need %d, Have %d)", skillName, reqNodeLevel, haveLevel))
            end
        end
    end
    if #result.missingSkills > 0 then
        table.insert(result.missingParts, "Skill Tree: " .. table.concat(result.missingSkills, ", "))
    end

    result.isEligible = result.levelPassed and (#result.missingTowers == 0) and (#result.missingGold == 0) and (#result.missingSkills == 0) and (#result.missingBase == 0)
    return result
end

function AutoEvoModule.CheckMilestonesReached(): (boolean, string?)
    if not (State and State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Enabled) and not (Globals and Globals.AutoEvo) then
        return false, nil
    end

    local coins = 0
    local gems = 0
    if PlayerDataHandler then
        if typeof(PlayerDataHandler.GetCoins) == "function" then
            pcall(function() coins = PlayerDataHandler:GetCoins() or 0 end)
        end
        if typeof(PlayerDataHandler.GetGems) == "function" then
            pcall(function() gems = PlayerDataHandler:GetGems() or 0 end)
        end
    end

    local selected = tostring((State and State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Target) or (Globals and Globals.TargetEvo) or "All")
    selected = AutoEvoModule.NormalizeTowerName(selected)
    local activeTower = nil

    if selected == "All" then
        for _, tName in ipairs(AutoEvoModule.GetTowerList()) do
            if not AutoEvoModule.IsTowerEvoComplete(tName) and AutoEvoModule.IsTowerOrEvoOwned(tName) then
                activeTower = tName
                break
            end
        end
        if not activeTower then
            return true, "All Evolutions Complete (Level 20 Maxed)"
        end
    elseif AutoEvoModule.EvoData[selected] then
        activeTower = selected
        if AutoEvoModule.IsTowerEvoComplete(selected) then
            return true, string.format("%s Evolution Complete (Level 20 Maxed)", selected)
        end
    end

    if activeTower and AutoEvoModule.EvoData[activeTower] then
        local eData = AutoEvoModule.EvoData[activeTower]
        local evoName = eData.Evo or activeTower
        local ownsEvo = false
        if PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" then
            pcall(function() ownsEvo = PlayerDataHandler:IsTowerOwned(evoName) end)
        end

        if ownsEvo then
            local evoExp = nil
            if PlayerDataHandler and typeof(PlayerDataHandler.GetTowerExp) == "function" then
                pcall(function() evoExp = PlayerDataHandler:GetTowerExp(evoName) end)
            end
            if evoExp and evoExp.Level and evoExp.Level >= 20 then
                return true, string.format("%s Evolution Reached Level 20", evoName)
            end
        else
            local expData = nil
            if PlayerDataHandler and typeof(PlayerDataHandler.GetTowerExp) == "function" then
                pcall(function() expData = PlayerDataHandler:GetTowerExp(activeTower) end)
            end
            local baseLvl = expData and expData.Level or 0
            local coinsNeed = math.max(0, eData.Coins - coins)
            local gemsNeed = math.max(0, eData.Gems - gems)

            local currentMatchMode = workspace:GetAttribute("Mode")
            local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
            local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
            local gsrDiff = tostring((gsr and gsr:GetAttribute("Difficulty")) or workspace:GetAttribute("Difficulty") or "")
            local isHardcore = (gsrDiff:lower():find("hardcore") ~= nil) or (tostring(currentMatchMode):lower():find("hardcore") ~= nil)

            if coinsNeed == 0 and gemsNeed == 0 and baseLvl >= 20 then
                return true, string.format("%s Ready to Evolve (Requirements Met)", activeTower)
            elseif coinsNeed == 0 and not isHardcore and gemsNeed > 0 then
                return true, string.format("%s Coins Goal (%d/%d) Reached! Switching to Hardcore for Gems", activeTower, coins, eData.Coins)
            elseif gemsNeed == 0 and isHardcore and coinsNeed > 0 then
                return true, string.format("%s Gems Goal (%d/%d) Reached! Switching to Coins", activeTower, gems, eData.Gems)
            end
        end
    end

    return false, nil
end

function AutoEvoModule.AttemptPurchase(towerName: string, evoName: string)
    if AutoEvoModule.buyingDebounce then return end
    AutoEvoModule.buyingDebounce = true
    task.spawn(function()
        pcall(function()
            local rf = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction")
            if rf then
                Logger:Info(string.format("Auto Evo: Purchasing evolution for %s (%s)...", tostring(towerName), tostring(evoName)))
                rf:InvokeServer("Shop", "EvolveTower", towerName)
                Window:Notify({
                    Title = "EVOLVING TOWER",
                    Desc = string.format("Evolving %s into %s!", tostring(towerName), tostring(evoName)),
                    Duration = 6,
                })
            end
        end)
        task.wait(4)
        AutoEvoModule.buyingDebounce = false
    end)
end

local function parseTargetVal(v: any): number
    if not v then return 0 end
    if type(v) == "number" then return v end
    local str = tostring(v):gsub(",", ""):gsub("%s+", "")
    local num = tonumber(str:match("[%d%.]+"))
    if not num then return 0 end
    if str:lower():find("k") then num = num * 1000
    elseif str:lower():find("m") then num = num * 1000000 end
    return math.floor(num)
end

--==============================================================================
-- Key Verification & Tier Configuration
--==============================================================================
local CONFIG_FOLDER = "[SomethingNew]"
local VERIFIED_KEY_FILE = CONFIG_FOLDER .. "/verified_key"
local fileSystemSupported = (typeof(readfile) == "function" and typeof(writefile) == "function")

local function ensureFolder(folder: string)
    if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
        pcall(function()
            if not isfolder(folder) then
                makefolder(folder)
            end
        end)
    end
end

local function safeHttpGet(url: string, retries: number?): string?
    local maxRetries = retries or 3
    for attempt = 1, maxRetries do
        local ok, res = pcall(game.HttpGet, game, url)
        if ok and res and res ~= "" then
            return res
        end
        if attempt < maxRetries then
            task.wait(1)
        end
    end
    return nil
end

local function loadVerifiedKey()
    if getgenv and type(getgenv().SCRIPT_KEY) == "string" and #getgenv().SCRIPT_KEY > 0 then
        local sk = (getgenv().SCRIPT_KEY:gsub("^%s*(.-)%s*$", "%1"))
        if #sk > 0 then return sk end
    end
    if not fileSystemSupported then return nil end
    ensureFolder(CONFIG_FOLDER)
    local candidateFiles = {
        CONFIG_FOLDER .. "/verified_key.txt",
        CONFIG_FOLDER .. "/verified_key",
        "[SomethingNew]/verified_key.txt",
        "[SomethingNew]/verified_key",
        "[ATF]/verified_key.txt",
        "[ATF]/verified_key",
        "verified_key.txt",
        "verified_key"
    }
    for _, path in ipairs(candidateFiles) do
        local ok, content = pcall(function()
            if isfile and isfile(path) then
                return readfile(path)
            end
            return nil
        end)
        if ok and content and content ~= "" then
            local trimmed = (content:gsub("^%s*(.-)%s*$", "%1"))
            if #trimmed > 0 then
                return trimmed
            end
        end
    end
    return nil
end

local function saveVerifiedKey(key)
    if getgenv then
        getgenv().SCRIPT_KEY = key
    end
    if not fileSystemSupported then return false end
    ensureFolder(CONFIG_FOLDER)
    ensureFolder("[SomethingNew]")
    ensureFolder("[ATF]")
    pcall(function() writefile(CONFIG_FOLDER .. "/verified_key.txt", key) end)
    pcall(function() writefile(CONFIG_FOLDER .. "/verified_key", key) end)
    pcall(function() writefile("[SomethingNew]/verified_key.txt", key) end)
    pcall(function() writefile("[ATF]/verified_key.txt", key) end)
    return true
end

local function clearSavedKey()
    if getgenv then
        getgenv().SCRIPT_KEY = nil
    end
    if not fileSystemSupported then return false end
    local candidateFiles = {
        CONFIG_FOLDER .. "/verified_key.txt",
        CONFIG_FOLDER .. "/verified_key",
        "[SomethingNew]/verified_key.txt",
        "[SomethingNew]/verified_key",
        "[ATF]/verified_key.txt",
        "[ATF]/verified_key",
        "verified_key.txt",
        "verified_key"
    }
    for _, path in ipairs(candidateFiles) do
        pcall(function()
            if typeof(delfile) == "function" and isfile and isfile(path) then
                delfile(path)
            else
                writefile(path, "")
            end
        end)
    end
    return true
end

local PremiumLoaded = false
local INBUILT_PREMIUM_WHITELIST = {
    -- Optional whitelisted UserIds or usernames
}

local lastVerifiedKeySuccess = nil
local lastVerifiedKeyTime = 0

local cachedJunkieSDK: any = nil
local function getJunkieSDK(): any
    if cachedJunkieSDK then return cachedJunkieSDK end
    local sdkChunk = nil
    pcall(function()
        if isfile and isfile("JunkieSDK.lua") then
            sdkChunk = readfile("JunkieSDK.lua")
        end
    end)
    if not sdkChunk or #sdkChunk == 0 then
        pcall(function()
            sdkChunk = game:HttpGet("https://jnkie.com/sdk/library.lua")
        end)
    end
    if not sdkChunk then return nil end
    local success, junkie = pcall(function()
        return loadstring(sdkChunk)()
    end)
    if success and type(junkie) == "table" then
        junkie.service = "[SomethingHub]"
        junkie.identifier = "1083049"
        junkie.provider = "Access"
        cachedJunkieSDK = junkie
        return junkie
    end
    return nil
end

local function checkSavedLicense(): boolean
    -- 1. Check compiler macro / runtime variable JD_IS_PREMIUM
    if typeof(JD_IS_PREMIUM) == "boolean" then
        PremiumLoaded = (JD_IS_PREMIUM == true)
        return PremiumLoaded
    end

    -- 2. Check getgenv().SCRIPT_KEY or saved verified_key file
    local verified_key = loadVerifiedKey()
    if not verified_key and getgenv and type(getgenv().SCRIPT_KEY) == "string" and #getgenv().SCRIPT_KEY >= 4 then
        verified_key = getgenv().SCRIPT_KEY
    end

    if verified_key and verified_key ~= "" and #verified_key >= 4 then
        local Junkie = getJunkieSDK()
        if Junkie and typeof(Junkie.check_key) == "function" then
            local ok, result = pcall(function()
                return Junkie.check_key(verified_key)
            end)
            if ok and result and result.valid == true then
                lastVerifiedKeySuccess = verified_key
                lastVerifiedKeyTime = os.clock()
                PremiumLoaded = true
                if getgenv then getgenv().SCRIPT_KEY = verified_key end
                Logger:Success("Saved license key verified via Junkie! Premium VIP active.")
                return true
            else
                local reason = (result and (result.error or result.message)) or "KEY_INVALID"
                Logger:Warn(string.format("Saved license key '%s' is fake or invalid (%s). Purging saved key.", tostring(verified_key), tostring(reason)))
                clearSavedKey()
                if getgenv and getgenv().SCRIPT_KEY == verified_key then
                    getgenv().SCRIPT_KEY = nil
                end
                lastVerifiedKeySuccess = nil
                PremiumLoaded = false
                return false
            end
        else
            Logger:Warn("Could not reach Junkie authentication service to verify saved key.")
            PremiumLoaded = false
            return false
        end
    end

    PremiumLoaded = false
    return false
end

-- Check license silently on startup (NO popup at launch)
checkSavedLicense()

local function checkIsPremium(): boolean
    if PremiumLoaded == true then return true end
    if typeof(JD_IS_PREMIUM) == "boolean" and JD_IS_PREMIUM == true then return true end
    if LocalPlayer and (INBUILT_PREMIUM_WHITELIST[LocalPlayer.UserId] or INBUILT_PREMIUM_WHITELIST[LocalPlayer.Name]) then
        return true
    end
    return false
end

local function verifyOrPromptKeySystem(featureName: string?): boolean
    return true
end


local function GetTrialConfig(trialTitleOrName: string)
    if not trialTitleOrName or trialTitleOrName == "" then return nil end
    local trialsConfig = (Settings and (Settings.AutoTimescale or Settings.RevampAutoTrials))
        or (ProgressionConfig and (ProgressionConfig.AutoTimescale or ProgressionConfig.RevampAutoTrials))
    if not trialsConfig then
        pcall(function()
            local raw = fetchGithubScript("Settings.lua")
            if raw then
                local f = loadstring(raw)
                if f then
                    local res = f()
                    if res then trialsConfig = res.AutoTimescale or res.RevampAutoTrials end
                end
            end
        end)
    end
    if not trialsConfig then return nil end

    if trialsConfig[trialTitleOrName] then
        return trialsConfig[trialTitleOrName]
    end

    local cleanTarget = string.lower(trialTitleOrName):gsub("%s+", "")
    for k, v in pairs(trialsConfig) do
        if string.lower(tostring(k)):gsub("%s+", "") == cleanTarget then
            return v
        end
    end
    return nil
end

local function getTrialTowerSet(cfg: any, slot: number): table?
    if not cfg or type(cfg) ~= "table" then return nil end
    local towersObj = cfg.Towers or cfg.Tower
    if not towersObj or type(towersObj) ~= "table" then return nil end

    if slot == 2 then
        local t2 = towersObj["Tower 2"]
            or towersObj["Tower2"]
            or towersObj["2"]
            or towersObj[2]
            or towersObj.Tower2
        if type(t2) == "table" and (t2[1] ~= nil or #t2 > 0) then
            return t2
        end
        return nil
    elseif slot == 1 then
        local t1 = towersObj["Tower 1"]
            or towersObj["Tower1"]
            or towersObj["1"]
            or towersObj[1]
            or towersObj.Tower1
        if type(t1) == "table" and (t1[1] ~= nil or #t1 > 0) then
            return t1
        end
        if type(towersObj[1]) == "string" then
            return towersObj
        end
        return nil
    end
    return nil
end

local function getTrialScriptUrl(cfg: any, slot: number): string?
    if not cfg or type(cfg) ~= "table" then return nil end
    local scriptsObj = cfg.scripts or cfg.Scripts
    if not scriptsObj then return nil end
    if type(scriptsObj) == "string" then return scriptsObj end
    if type(scriptsObj) ~= "table" then return nil end

    if slot == 2 then
        return scriptsObj["Tower 2"]
            or scriptsObj["Tower2"]
            or scriptsObj["2"]
            or scriptsObj[2]
            or scriptsObj.Tower2
    elseif slot == 1 then
        local s1 = scriptsObj["Tower 1"]
            or scriptsObj["Tower1"]
            or scriptsObj["1"]
            or scriptsObj[1]
            or scriptsObj.Tower1
        if s1 and type(s1) == "string" then return s1 end
        if type(scriptsObj[1]) == "string" then return scriptsObj[1] end
        for _, u in pairs(scriptsObj) do
            if type(u) == "string" and u ~= "" then return u end
        end
    end
    return nil
end

local function checkTrialEligibility(trialTitle: string): (boolean, string, table?, string?)
    if not trialTitle or trialTitle == "" then
        return false, "No active trial detected", nil, nil
    end

    local config = GetTrialConfig(trialTitle)
    if not config then
        return false, "No config for " .. tostring(trialTitle), nil, nil
    end

    local playerLevel = PlayerDataHandler and typeof(PlayerDataHandler.GetLevel) == "function" and PlayerDataHandler:GetLevel() or 0
    local reqLevel = config.Level or 175
    if playerLevel < reqLevel then
        return false, string.format("Level %d required (You: %d)", reqLevel, playerLevel), nil, nil
    end

    -- Check Golden requirements
    local missingGold = {}
    if config.Golden and #config.Golden > 0 and PlayerDataHandler then
        for _, goldTower in ipairs(config.Golden) do
            if not PlayerDataHandler:IsGoldenOwned(goldTower) then
                table.insert(missingGold, "Golden " .. goldTower)
            end
        end
    end
    if #missingGold > 0 then
        return false, "Missing: " .. table.concat(missingGold, ", "), nil, nil
    end

    -- Check SkillTree requirements
    if config.SkillTree and next(config.SkillTree) then
        local userSkills = getSkillTreeDict()
        local missingSkills = {}
        for skillName, reqVal in pairs(config.SkillTree) do
            local current = getSkillLevel(userSkills, skillName)
            if current < reqVal then
                table.insert(missingSkills, string.format("%s (Lvl %d/%d)", skillName, current, reqVal))
            end
        end
        if #missingSkills > 0 then
            return false, "Missing Skills: " .. table.concat(missingSkills, ", "), nil, nil
        end
    end

    -- Check Towers requirements
    local isPrem = checkIsPremium()
    local towerSetsToCheck = {}
    local set2 = isPrem and getTrialTowerSet(config, 2)
    if set2 then
        table.insert(towerSetsToCheck, { key = "Tower 2", list = set2 })
    end
    local set1 = getTrialTowerSet(config, 1)
    if set1 then
        table.insert(towerSetsToCheck, { key = "Tower 1", list = set1 })
    end

    local firstMissing = nil
    local selectedLoadout = nil
    local selectedKey = nil

    for _, entry in ipairs(towerSetsToCheck) do
        local missingForSet = {}
        if PlayerDataHandler then
            for _, t in ipairs(entry.list) do
                if not PlayerDataHandler:IsTowerOwned(t) then
                    table.insert(missingForSet, t)
                end
            end
        end
        if #missingForSet == 0 then
            selectedLoadout = entry.list
            selectedKey = entry.key
            break
        elseif not firstMissing then
            firstMissing = missingForSet
        end
    end

    if selectedLoadout then
        return true, "Eligible (Ready to Farm)", selectedLoadout, selectedKey
    else
        local missingText = firstMissing and table.concat(firstMissing, ", ") or "None"
        return false, "Missing Towers: " .. missingText, nil, nil
    end
end

local ModeRequirements = {
    Coins = { "Scout", "Sniper", "Soldier", "Farm", "Minigunner", "Commander", "DJ Booth" },
    Gems = { "Ace Pilot", "Militant", "Ranger", "Commander", "DJ Booth", "Minigunner" },
    Levels = { "Shotgunner", "Minigunner", "Commander", "Farm" },
}

local function getMissingTowersText(mode: string, optCondition: string?): string
    if mode == "Coins" or mode == "Gems" or mode == "Levels" then
        local actualFarm = mode
        if mode == "Levels" then
            actualFarm = (State and State.AutoCurrency and State.AutoCurrency.Levels and State.AutoCurrency.Levels.Currency)
                or (Settings and Settings:Get("AutoLevelsCurrency", "Coins"))
                or "Coins"
        end

        local cond = optCondition
            or (State and State.AutoCurrency and State.AutoCurrency[mode] and State.AutoCurrency[mode].Condition)
            or (Settings and Settings:Get("Auto" .. mode .. "Condition", "Lose"))
            or "Lose"

        local stratChoice = (cond == "Win" or cond == "Win Only") and "Win" or "Lose"
        local res = AutoCurrencyChecker(actualFarm, stratChoice)
        if res.isEligible then
            return string.format("Eligible for %s (%s) ✓", res.stratChoice, res.targetMode)
        else
            local details = (#res.missingParts > 0) and table.concat(res.missingParts, " | ") or "Requirements not met"
            return string.format("%s: %s [X]", res.stratChoice, details)
        end
    end

    if mode == "Timescales" then
        if not PlayerDataHandler then return "DataHandler not connected" end
        local cur = nil
        pcall(function() cur = PlayerDataHandler:GetCurrentTrial() end)
        local title = cur and (cur.Title or cur.Name)
        if not title then return "Pending active trial..." end
        local eligible, reason = checkTrialEligibility(title)
        if eligible then
            return "Eligible for " .. title .. " ✓"
        else
            return "Ineligible: " .. reason .. " [X]"
        end
    end

    local reqs = ModeRequirements[mode] or {}
    if not DataHandler then
        return "DataHandler not connected"
    end
    local missing = {}
    for _, t in ipairs(reqs) do
        local ok, owned = pcall(function() return DataHandler:IsTowerOwned(t) end)
        if not (ok and owned) then
            table.insert(missing, t)
        end
    end
    if #missing == 0 then
        return "None (All Required Towers Owned ✓)"
    else
        return "Missing: " .. table.concat(missing, ", ") .. " [X]"
    end
end

--==============================================================================
-- 3. Settings Persistence System (Debounced to prevent disk thrashing)
--==============================================================================
local username = (LocalPlayer and LocalPlayer.Name) or "DefaultUser"
local SETTINGS_FILE = CONFIG_FOLDER .. "/" .. username .. ".json"

local function ensureParentFolder(filePath: string)
    local folder = filePath:match("^(.-)/[^/]+$") or filePath:match("^(.-)\\[^\\]+$")
    if folder and folder ~= "" then
        ensureFolder(folder)
    end
end

local DefaultSettings = {
    -- Auto Progress
    AutoProgressEnabled = false,

    -- Auto Currency
    AutoCurrencyEnabled = false,
    SelectedCurrencyTab = "Auto Coins",
    AutoCoinsEnabled = false,
    AutoCoinsCondition = "Lose",
    AutoCoinsTarget = "0",
    AutoGemsEnabled = false,
    AutoGemsCondition = "Lose",
    AutoGemsTarget = "0",
    AutoLevelsEnabled = false,
    AutoLevelsCondition = "Lose",
    AutoLevelsTarget = "0",
    AutoLevelsCurrency = "Coins",
    AutoTimescalesEnabled = false,
    AutoTimescalesTarget = "0",
    AutoTimescalesFallback = "Molten",
    AutoTimescalesIgnoredTrials = { "Glass", "Committed", "Limitation" },
    AutoEvoEnabled = false,
    TargetEvo = "All",
    EvoStrat = "Lose",
    AutoClicker = false,
    ClickCPS = 12,
    AutoCollectDrops = true,
    TargetCurrency = "All",
    AutoBuyUpgrades = false,
    UpgradeStrategy = "Highest ROI",
    AutoClaimFreeGifts = true,

    -- Utilities
    AutoSkip = false,
    AutoReady = false,
    AutoRejoin = false,
    RejoinPrivateServerCode = "",

    -- Private Server & Lobby
    PrivateServerCode = "",
    PrivateCode = "",
    MultiplayerPrivateServerLink = "",

    -- Advanced Functions
    AutoGatling = false,
    SelectedGatling = "Railgun",
    ConditionGatlingLoader = false,
    ConditionGatlingScript = "Railgun",

    -- Misc
    AntiAFK = true,
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    BlackScreen = false,
    Disable3DRendering = false,
    AntiLag = false,
    DisableShadows = false,
    WebhookUrl = "",
    WebhookAlerts = false,
    NodeName = "Node 1",
    TotalMatches = 0,
    SelectedTheme = "LightGray",

    -- Utilities
    Stacker = false,
    AutoSkip = false,
    EnableTimescale = false,
    TimescaleTargetSpeed = 2.0,
    AutoBuyMissingTowers = false,
    AutoPickups = false,
    PickupMethod = "Pathfinding",

    -- Advanc Func
    AutoGatling = false,
    AutoGatlingMaxTarget = 5,
    AutoGatlingPriority = "Last",
    AutoReloadGatling = false,
    GatlingReloadPercent = 100,
    SelectedGatling = "Railgun",

    -- Strategy Manager
    AutoExecuteStrat = false,
    SelectedAutoStrat = "",
    selectedStrat = "",
    SelectedStrat = "",
    Premium = false,
}

local selectedStrat = ""
if getgenv then getgenv().selectedStrat = getgenv().selectedStrat or "" end
_G.selectedStrat = _G.selectedStrat or ""

local Globals = {}
local saveDebounceTimer = nil

local function SaveSettings(immediate: boolean?)
    local function executeSave()
        ensureFolder(CONFIG_FOLDER)
        ensureParentFolder(SETTINGS_FILE)
        local dataToSave = {}
        for key in pairs(DefaultSettings) do
            dataToSave[key] = Globals[key]
        end
        dataToSave["SavedAt"] = os.time()
        dataToSave["Username"] = username

        if typeof(writefile) == "function" and HttpService then
            pcall(function()
                writefile(SETTINGS_FILE, HttpService:JSONEncode(dataToSave))
            end)
        end
    end

    if immediate then
        if saveDebounceTimer then
            task.cancel(saveDebounceTimer)
            saveDebounceTimer = nil
        end
        executeSave()
    else
        if saveDebounceTimer then
            task.cancel(saveDebounceTimer)
        end
        saveDebounceTimer = task.delay(0.5, function()
            saveDebounceTimer = nil
            executeSave()
        end)
    end
end

local function LoadSettings()
    ensureFolder(CONFIG_FOLDER)
    local data = {}
    local targetPath = (typeof(isfile) == "function" and isfile(SETTINGS_FILE) and SETTINGS_FILE) or nil

    if targetPath and typeof(readfile) == "function" then
        local success, content = pcall(readfile, targetPath)
        if success and content and content ~= "" then
            pcall(function()
                data = HttpService:JSONDecode(content)
            end)
        end
    end

    for key, defaultVal in pairs(DefaultSettings) do
        if data[key] ~= nil then
            Globals[key] = data[key]
        elseif Globals[key] == nil then
            Globals[key] = defaultVal
        end
    end

    SaveSettings(true)
end

LoadSettings()

--==============================================================================
-- 4. In-Main Auto Progress Handler
--==============================================================================
local progressListeners: { (key: string, value: any) -> () } = {}

local function fireProgressChanged(key: string, val: any)
    for _, fn in ipairs(progressListeners) do
        pcall(fn, key, val)
    end
end

local function SetSetting(key: string, value: any, immediate: boolean?)
    Globals[key] = value
    SaveSettings(immediate or false)
    fireProgressChanged(key, value)
end

local function GetSetting(key: string, fallback: any): any
    if Globals[key] ~= nil then
        return Globals[key]
    end
    return fallback
end

local Settings = {
    Tiers = ProgressionConfig.Tiers or {},
}

function Settings.OnChanged(callback: (key: string, value: any) -> ())
    table.insert(progressListeners, callback)
end

function Settings:Get(key: string, fallback: any): any
    if Globals[key] ~= nil then return Globals[key] end
    return fallback
end

function Settings:Set(key: string, value: any, immediate: boolean?)
    SetSetting(key, value, immediate)
end

function Settings:SetCurrentlyDoing(action: string)
    self:Set("CurrentlyDoing", action)
end

function Settings:SetTarget(target: string)
    self:Set("Target", target)
end

function Settings:SetTier(tier: string)
    if tier == "Premium" or tier == "Free" then
        self:Set("SelectedTier", tier)
        local isPrem = (tier == "Premium")
        self:Set("BetterProg", isPrem)
        self:Set("UnlockAllEvo", isPrem)
        self:Set("UnlockAllGoldenSkins", isPrem)
        self:Set("UnlockAllSkillTree", isPrem)
        self:Set("UnlockSpecialTowers", isPrem)
        SaveSettings(true)
    end
end

--==============================================================================
-- 4. State Store & Subscription Plan
--==============================================================================

if getgenv then
    if not getgenv().HubSessionStartTime then
        getgenv().HubSessionStartTime = tick()
    end
    if not getgenv().HubSessionMatches then
        getgenv().HubSessionMatches = 0
    end
    if not getgenv().HubSessionWins then
        getgenv().HubSessionWins = 0
    end
end
local SendAutoCurrencyWebhook = nil
local SendDiscordWebhook = nil

local State = {
    Master = true,
    StartTime = os.time(),
    ActionsCount = 0,
    CurrencyGained = 0,
    MilestoneProgress = 0.05,

    AutoProgress = {
        Enabled = GetSetting("AutoProgressEnabled", false),
    },
    
    AutoCurrency = {
        Enabled = GetSetting("AutoCurrencyEnabled", false),
        SelectedTab = GetSetting("SelectedCurrencyTab", "Auto Coins"),
        Coins = {
            Enabled = GetSetting("AutoCoinsEnabled", false),
            Condition = (checkIsPremium() and GetSetting("AutoCoinsCondition", "Lose")) or "Lose",
            Target = GetSetting("AutoCoinsTarget", "0"),
        },
        Gems = {
            Enabled = GetSetting("AutoGemsEnabled", false),
            Condition = (checkIsPremium() and GetSetting("AutoGemsCondition", "Lose")) or "Lose",
            Target = GetSetting("AutoGemsTarget", "0"),
        },
        Levels = {
            Enabled = GetSetting("AutoLevelsEnabled", false),
            Condition = (checkIsPremium() and GetSetting("AutoLevelsCondition", "Lose")) or "Lose",
            Target = GetSetting("AutoLevelsTarget", "0"),
            Currency = GetSetting("AutoLevelsCurrency", "Coins"),
        },
        Timescales = {
            Enabled = GetSetting("AutoTimescalesEnabled", false),
            Target = GetSetting("AutoTimescalesTarget", "0"),
            Fallback = GetSetting("AutoTimescalesFallback", "Molten"),
            IgnoredTrials = GetSetting("AutoTimescalesIgnoredTrials", { "Glass", "Committed", "Limitation" }),
        },
        Evo = {
            Enabled = GetSetting("AutoEvoEnabled", false),
            Target = GetSetting("TargetEvo", "All"),
            Strategy = GetSetting("EvoStrat", "Lose"),
        },
        AutoClicker = GetSetting("AutoClicker", false),
        ClickCPS = GetSetting("ClickCPS", 12),
        AutoCollectDrops = GetSetting("AutoCollectDrops", true),
        TargetCurrency = GetSetting("TargetCurrency", "All"),
        AutoBuyUpgrades = GetSetting("AutoBuyUpgrades", false),
        UpgradeStrategy = GetSetting("UpgradeStrategy", "Highest ROI"),
        AutoClaimFreeGifts = GetSetting("AutoClaimFreeGifts", true),
    },
    
    Product = {
        CurrentTier = checkIsPremium() and "Premium VIP" or "Keyless Mode",
        LicenseKey = (checkIsPremium() and (loadVerifiedKey() or "PREMIUM-ACTIVE")) or "",
        IsActivated = checkIsPremium(),
    },
    
    Utilities = {
        Stacker = checkIsPremium() and GetSetting("Stacker", false) or false,
        AutoSkip = GetSetting("AutoSkip", false),
        AutoReady = GetSetting("AutoReady", false),
        AutoRejoin = GetSetting("AutoRejoin", false),
        RejoinPrivateServerCode = GetSetting("PrivateServerCode", ""),
        EnableTimescale = GetSetting("EnableTimescale", false),
        TimescaleTargetSpeed = GetSetting("TimescaleTargetSpeed", 2.0),
        AutoBuyMissingTowers = GetSetting("AutoBuyMissingTowers", false),
        AutoPickups = GetSetting("AutoPickups", false),
        PickupMethod = GetSetting("PickupMethod", "Pathfinding"),
    },

    AdvancFunc = {
        AutoGatling = checkIsPremium() and GetSetting("AutoGatling", false) or false,
        SelectedGatling = GetSetting("SelectedGatling", "Railgun"),
        ConditionGatlingLoader = checkIsPremium() and GetSetting("ConditionGatlingLoader", false) or false,
        ConditionGatlingScript = GetSetting("ConditionGatlingScript", "Railgun"),
        MaxTarget = math.clamp(GetSetting("AutoGatlingMaxTarget", 5), 1, 5),
        TargetPriority = GetSetting("AutoGatlingPriority", "Last"),
        AutoReloadGatling = checkIsPremium() and GetSetting("AutoReloadGatling", false) or false,
        GatlingReloadPercent = GetSetting("GatlingReloadPercent", 100),
    },

    StrategyManager = {
        AutoExecuteStrat = GetSetting("AutoExecuteStrat", false),
        SelectedAutoStrat = GetSetting("SelectedAutoStrat", ""),
        selectedStrat = GetSetting("selectedStrat", GetSetting("SelectedAutoStrat", "")),
        SelectedStrat = GetSetting("SelectedStrat", GetSetting("SelectedAutoStrat", "")),
    },
    
    Misc = {
        PrivateServerCode = GetSetting("PrivateServerCode", ""),
        PrivateCode = GetSetting("PrivateCode", ""),
        MultiplayerPrivateServerLink = GetSetting("MultiplayerPrivateServerLink", ""),
        AntiAFK = GetSetting("AntiAFK", true),
        WalkSpeed = GetSetting("WalkSpeed", 16),
        JumpPower = GetSetting("JumpPower", 50),
        InfiniteJump = GetSetting("InfiniteJump", false),
        BlackScreen = GetSetting("BlackScreen", false),
        Disable3DRendering = GetSetting("Disable3DRendering", false),
        AntiLag = GetSetting("AntiLag", false),
        DisableShadows = GetSetting("DisableShadows", false),
        WebhookUrl = GetSetting("WebhookUrl", ""),
        WebhookAlerts = GetSetting("WebhookAlerts", false),
        NodeName = GetSetting("NodeName", "Node 1"),
        SelectedTheme = GetSetting("SelectedTheme", "LightGray"),
    }
}

-- Initial AutoRestart and AutoRejoin synchronization for API and in-game supervisor
local initialCond = (State.AutoCurrency.Coins.Enabled and State.AutoCurrency.Coins.Condition)
    or (State.AutoCurrency.Gems.Enabled and State.AutoCurrency.Gems.Condition)
    or State.AutoCurrency.Coins.Condition
    or "Lose"
if initialCond == "Lose" then
    if getgenv then
        getgenv().AutoRestart = false
        getgenv().AutoRejoin = false
    end
    Globals.AutoRestart = false
    Globals.AutoRejoin = false
else
    if getgenv then
        getgenv().AutoRestart = false
        getgenv().AutoRejoin = false
    end
    Globals.AutoRestart = false
    Globals.AutoRejoin = false
end

--==============================================================================
-- 3. Window & Theme Initialization
--==============================================================================
Window = Library:Window({
    Title = "SOMETHING NEW // HUB",
    Subtitle = "v1.0.0 // Ready",
    Theme = "LightGray",
    Icon = "Zap",
    Keybind = Enum.KeyCode.RightControl,
    DiscordLink = "https://discord.gg",
    Size = UDim2.fromOffset(800, 540),
})

-- Profile Widget
local isPremInitial = checkIsPremium()
Window:UserProfile({
    Username = (LocalPlayer and LocalPlayer.Name) or "Player",
    Badge = isPremInitial and "PREMIUM VIP" or "KEYLESS",
    TimeLeft = isPremInitial and "Permanent" or "None",
    AvatarId = (LocalPlayer and LocalPlayer.UserId) or 1,
})

-- Helper to safely format elapsed time
local function formatDuration(seconds: number): string
    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hrs, mins, secs)
end

--==============================================================================
-- 4. OVERVIEW TAB
--==============================================================================
local StatsGrid = nil
-- MilestoneBar removed
local refreshCurrencyBox = nil
local trialsSelectionBox = nil
local trialsMetricGrid = nil
-- Logger initialized at top-level
local lastLiveStats = nil
local refreshLiveOverview = nil

;(function()
local OverviewTab = Window:Tab({
    Title = "Overview",
    Subtitle = "System Status & Overview",
})

OverviewTab:Banner({
    Title = "Welcome to SomethingNew Hub",
    Desc = "Advanced neo-glassmorphism automation initialized. Configure your modules in the tabs below.",
    Type = "Info",
})

StatsGrid = OverviewTab:MetricGrid({
    Cols = 3,
    Items = {
        { Title = "STATUS", Value = "ONLINE", Sub = "Nominal", Color = Color3.fromRGB(34, 197, 94) },
        { Title = "SESSION TIME", Value = "00:00:00", Sub = "Runtime" },
        { Title = "ACTIONS RUN", Value = "0", Sub = "Completed cycles" },
        { Title = "MATCHES PLAYED", Value = "0", Sub = "Hub session" },
        { Title = "AUTO CURRENCY", Value = "OFF", Sub = "Standing by" },
        { Title = "CURRENCY GAINED", Value = "+0", Sub = "Session total", Color = Color3.fromRGB(245, 158, 11) },
    }
})

local UserOverviewSection = OverviewTab:Section({ Title = "Live Player Profile, Towers & Trials" })

local userOverviewBox = UserOverviewSection:SelectionBox({
    Selections = { "User Data", "User Owned Towers", "User Owned Trials" },
    Value = "User Data",
    Descriptions = {
        ["User Data"] = "Live Player Progression, Timescales & Wallet Stats",
        ["User Owned Towers"] = "TDS Tower Inventory Ownership & Verification",
        ["User Owned Trials"] = "TDS Completed Trials & Won Modifiers Progress",
    },
    Checklist = {
        ["User Data"] = getUserDataChecklist(),
        ["User Owned Towers"] = getOwnedTowersChecklist(),
        ["User Owned Trials"] = getOwnedTrialsChecklist(),
    },
    ButtonTexts = {
        ["User Data"] = "Refresh Live Player Stats",
        ["User Owned Towers"] = "Scan Owned Towers Inventory",
        ["User Owned Trials"] = "Scan Completed Trials",
    },
    Callbacks = {
        ["User Data"] = function()
            if refreshLiveOverview then
                refreshLiveOverview()
            end
            Window:Notify({
                Title = "Player Stats Refreshed",
                Desc = "Fetched latest coins, gems, timescales, level & EXP from DataHandler.",
                Duration = 2,
            })
        end,
        ["User Owned Towers"] = function()
            cachedOwnedTowersList = nil
            if refreshLiveOverview then
                refreshLiveOverview()
            end
            Window:Notify({
                Title = "Towers Inventory Scanned",
                Desc = "Verified current owned vs missing towers from DataHandler.",
                Duration = 2,
            })
        end,
        ["User Owned Trials"] = function()
            cachedOwnedTrialsList = nil
            cachedWonTrialsList = nil
            cachedNotWonTrialsList = nil
            if refreshLiveOverview then
                refreshLiveOverview()
            end
            Window:Notify({
                Title = "Trials Inventory Scanned",
                Desc = "Verified current completed vs uncompleted trials from DataHandler.",
                Duration = 2,
            })
        end,
    },
})

--==============================================================================
-- Live Player Stats & Inventory Reactive Engine
--==============================================================================
local isRefreshingLiveOverview = false
lastLiveStats = {
    Coins = -1,
    Gems = -1,
    Level = -1,
    Exp = -1,
    ExpDisplay = "",
}

refreshLiveOverview = function()
    if isRefreshingLiveOverview then return end
    isRefreshingLiveOverview = true
    task.defer(function()
        task.wait(0.05)
        isRefreshingLiveOverview = false
        if userOverviewBox then
            pcall(function()
                userOverviewBox:SetChecklist({
                    ["User Data"] = getUserDataChecklist(),
                    ["User Owned Towers"] = getOwnedTowersChecklist(),
                    ["User Owned Trials"] = getOwnedTrialsChecklist(),
                })
            end)
        end
        if trialsSelectionBox then
            pcall(function()
                local a, w, nw = getOwnedTrialsData()
                trialsSelectionBox:SetChecklist({
                    ["All Trials"] = a,
                    ["Won Trials"] = w,
                    ["Not Won Trials"] = nw,
                })
            end)
        end
        if trialsMetricGrid and typeof(trialsMetricGrid.UpdateItem) == "function" then
            pcall(function()
                local wonCount = 0
                local totalCount = 0
                local trials = nil
                if DataHandler and typeof(DataHandler.GetAllTrialsList) == "function" then
                    pcall(function() trials = DataHandler:GetAllTrialsList() end)
                end
                if trials and #trials > 0 then
                    totalCount = #trials
                    for _, t in ipairs(trials) do
                        if t.IsWon then wonCount = wonCount + 1 end
                    end
                end
                local timescaleTickets = 0
                if DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" then
                    pcall(function() timescaleTickets = DataHandler:GetTimescaleTickets() or 0 end)
                end
                local winRate = totalCount > 0 and math.floor((wonCount / totalCount) * 100) or 0
                trialsMetricGrid:UpdateItem(1, string.format("%d / %d", wonCount, totalCount), string.format("Win Rate: %d%%", winRate))
                trialsMetricGrid:UpdateItem(2, tostring(math.max(0, totalCount - wonCount)), "Modifiers to unlock")
                trialsMetricGrid:UpdateItem(3, formatCommas(timescaleTickets), "Boost items held")
            end)
        end
        if refreshCurrencyBox then
            pcall(refreshCurrencyBox)
        end
    end)
end

local function setupLiveStatListeners()
    local function connectCacheAtom(atomName: string)
        pcall(function()
            local cModule = game:GetService("ReplicatedStorage"):FindFirstChild("Client")
            cModule = cModule and cModule:FindFirstChild("Modules")
            cModule = cModule and cModule:FindFirstChild("Cache")
            if cModule then
                local Cache = require(cModule)
                local atom = Cache(atomName)
                if atom and atom.Updated and type(atom.Updated.Connect) == "function" then
                    atom.Updated:Connect(function()
                        if atomName == "Inventory.Troops" or atomName == "Inventory.Skins" then
                            cachedOwnedTowersList = nil
                        elseif atomName == "Inventory.Modifiers" or atomName == "Values.TimescaleTickets" then
                            cachedOwnedTrialsList = nil
                            cachedWonTrialsList = nil
                            cachedNotWonTrialsList = nil
                        end
                        refreshLiveOverview()
                    end)
                end
            end
        end)
    end

    local atomsToTrack = {
        "Values.Coins",
        "Values.Gems",
        "Values.Experience",
        "Values.Level",
        "Values.SkillCredits",
        "Values.TimescaleTickets",
        "Values.SpinTickets",
        "Values.ReviveTickets",
        "Values.Wins",
        "Values.Loses",
        "Values.Triumphs",
        "Inventory.Troops",
        "Inventory.Skins",
        "Inventory.Modifiers",
        "Equipped.Troops",
    }

    for _, atomName in ipairs(atomsToTrack) do
        connectCacheAtom(atomName)
    end

    -- Real-time Charm PlayerStatsStore Subscription (Instant in-game & lobby updates for EXP, Level, Coins, Gems)
    pcall(function()
        local Charm = require(game:GetService("ReplicatedStorage").Packages.Charm)
        local client = game:GetService("ReplicatedStorage"):FindFirstChild("Client")
        local ifaces = client and client:FindFirstChild("Interfaces")
        local stores = ifaces and ifaces:FindFirstChild("Stores")
        local shared = stores and stores:FindFirstChild("Shared")
        local pss = shared and shared:FindFirstChild("PlayerStatsStore")
        if pss then
            local pStore = require(pss)
            if Charm and type(Charm.subscribe) == "function" and pStore and type(pStore.getState) == "function" then
                Charm.subscribe(pStore.getState, function()
                    refreshLiveOverview()
                end)
            end
        end
    end)

    -- Real-time LocalPlayer ValueBase listeners (Experience, Level, Coins, Gems)
    if LocalPlayer then
        for _, valName in ipairs({ "Experience", "Level", "Coins", "Gems", "Gold", "Diamonds" }) do
            local vObj = LocalPlayer:FindFirstChild(valName)
            if vObj and vObj:IsA("ValueBase") then
                vObj.Changed:Connect(function()
                    refreshLiveOverview()
                end)
            end
        end
    end

    -- Real-time Workspace Skill Tree tile listeners for Lobby
    pcall(function()
        local ws = game:GetService("Workspace")
        for i = 1, 17 do
            local tile = ws:FindFirstChild(tostring(i))
            if tile then
                local sGui = tile:FindFirstChild("TileSurfaceGui")
                local frame = sGui and sGui:FindFirstChild("Frame")
                local lvlLabel = frame and frame:FindFirstChild("SkillLevel")
                if lvlLabel and lvlLabel:IsA("TextLabel") then
                    lvlLabel:GetPropertyChangedSignal("Text"):Connect(function()
                        refreshLiveOverview()
                    end)
                end
            end
        end
    end)
end

setupLiveStatListeners()

local OverviewQuick = OverviewTab:Section({ Title = "Quick Controls" })

OverviewQuick:Toggle({
    Title = "Master Automation Switch",
    Desc = "Globally enables or pauses all background automation routines",
    Value = State.Master,
    Callback = function(val: boolean)
        State.Master = val
        StatsGrid:UpdateItem(1, val and "ONLINE" or "PAUSED", val and "Nominal" or "Paused globally")
        Window:Notify({
            Title = "Master Switch",
            Desc = val and "All automation loops resumed." or "Automation suspended globally.",
            Duration = 2,
        })
    end,
})

local ActivityLogSection = OverviewTab:Section({ Title = "Activity Feed" })

Logger = ActivityLogSection:LogConsole({
    Title = "SYSTEM ACTIVITY LOG",
    Height = 140,
    MaxLines = 100,
})

Logger:Success("CoreRevamp Glassmorphism API mounted successfully.")
Logger:Info("SomethingNew Hub initialized on " .. ((LocalPlayer and LocalPlayer.Name) or "Player") .. ".")

--==============================================================================
-- 5. AUTO PROGRESS TAB
--==============================================================================
local formatNumber = nil
formatNumber = function(n: number | string): string
    local num = tonumber(n) or 0
    local formatted = tostring(math.floor(num))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function getChapter0StatusText(): string
    if not DataHandler then
        return "Unknown (DataHandler unavailable)"
    end

    local isBeaten = false
    pcall(function()
        if typeof(DataHandler.IsChapter0Beaten) == "function" then
            isBeaten = DataHandler:IsChapter0Beaten()
        end
    end)

    if isBeaten then
        return "Completed (4/4 Missions Beaten) ✓"
    end

    local status = nil
    pcall(function()
        if typeof(DataHandler.CheckOwnedStoryMode) == "function" then
            status = DataHandler:CheckOwnedStoryMode()
        end
    end)

    if status and type(status) == "table" then
        if status.AllBeaten then
            return "Completed (4/4 Missions Beaten) ✓"
        end
        local nextName = "Boot Camp"
        if status.Details and type(status.Details) == "table" then
            for _, m in ipairs(status.Details) do
                if not m.Beaten then
                    nextName = m.Name or nextName
                    break
                end
            end
        end
        return string.format("Incomplete (%d/4 Missions - Next: %s)", status.CompletedCount or 0, nextName)
    end

    local curLvl = 0
    pcall(function()
        if typeof(DataHandler.GetLevel) == "function" then
            curLvl = DataHandler:GetLevel() or 0
        end
    end)
    if curLvl >= 15 then
        return "Completed (Level 15+ Account) ✓"
    end

    return "Incomplete (Tutorial Required)"
end
end)()

--==============================================================================
-- 5. AUTO PROG TAB & PROGRESSION ENGINE
--==============================================================================
local getAutoProgressNodeInfo = nil
local refreshAutoProgUI = nil
local progToggleRef = nil

;(function()
    local function isTowerOwned(name: string): boolean
        if not name or name == "" then return true end
        if PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" then
            local ok, res = pcall(function() return PlayerDataHandler:IsTowerOwned(name) end)
            if ok and res ~= nil then return res end
        end
        if DataHandler and typeof(DataHandler.IsTowerOwned) == "function" then
            local ok, res = pcall(function() return DataHandler:IsTowerOwned(name) end)
            if ok and res ~= nil then return res end
        end
        return false
    end

    local function checkTowersListOwned(list: any): (boolean, { string }, { string })
        if type(list) ~= "table" then return true, {}, {} end
        local owned = {}
        local missing = {}
        for _, t in ipairs(list) do
            if isTowerOwned(t) then
                table.insert(owned, t)
            else
                table.insert(missing, t)
            end
        end
        return (#missing == 0), owned, missing
    end

    local function getTowerCost(towerName: string): (number, string)
        if not towerName or towerName == "" then return 0, "Coins" end
        local tList = (ProgressionConfig and ProgressionConfig.TowerList)
            or (Settings and Settings.TowerList)
        if tList then
            for _, curType in ipairs({ "Coins", "Levels", "Gems", "Evo", "Golden" }) do
                local arr = tList[curType]
                if type(arr) == "table" then
                    for _, item in ipairs(arr) do
                        if item.Name == towerName then
                            return tonumber(item.Cost or item.Coins or 0) or 0, curType
                        end
                    end
                end
            end
        end
        return 0, "Coins"
    end

    local storyMissionsMap = {
        [1] = "Boot Camp",
        [2] = "Live Fire",
        [3] = "Breach Protocol",
        [4] = "Brute Force",
    }
    local storyMissionsIndex = {
        ["Boot Camp"] = 1,
        ["Live Fire"] = 2,
        ["Breach Protocol"] = 3,
        ["Brute Force"] = 4,
    }

    getAutoProgressNodeInfo = function()
        local cfg = (ProgressionConfig and ProgressionConfig.AutoProgress)
            or (Settings and Settings.AutoProgress)
        if not cfg then
            return {
                nodeName = "Node 0",
                nodeNum = 0,
                progress = 0,
                title = "Node 0 Progression (0%)",
                status = "Fetching Progression Config...",
                objectives = "Waiting for configuration...",
                isComplete = false,
            }
        end

        local playerLevel = (PlayerDataHandler and typeof(PlayerDataHandler.GetLevel) == "function" and PlayerDataHandler:GetLevel())
            or (DataHandler and typeof(DataHandler.GetLevel) == "function" and DataHandler:GetLevel())
            or 0
        local playerCoins = 0
        if DataHandler and typeof(DataHandler.GetPlayerStats) == "function" then
            local s = DataHandler:GetPlayerStats()
            if s and s.Coins then playerCoins = tonumber(s.Coins) or 0 end
        end

        local function formatMissingTowers(missingList)
            local formatted = {}
            local totalCoins = 0
            for _, t in ipairs(missingList or {}) do
                local cost, cType = getTowerCost(t)
                if cType == "Coins" and cost > 0 then
                    totalCoins = totalCoins + cost
                    table.insert(formatted, string.format("%s (%s Coins)", t, tostring(cost)))
                else
                    table.insert(formatted, t)
                end
            end
            return formatted, totalCoins
        end

        -- 1. Check Node 0
        local n0 = cfg["Node 0"] or cfg["Node0"]
        local n0Step = n0 and n0[1]
        if n0 and n0Step then
            local ch0Beaten = false
            if DataHandler and typeof(DataHandler.IsChapter0Beaten) == "function" then
                pcall(function() ch0Beaten = DataHandler:IsChapter0Beaten() end)
            end

            local n0MissionDone = false
            local n0MissionsCount = 0
            local n0NextMissionName = "Boot Camp"
            local n0NextMissionNum = 1

            if ch0Beaten then
                n0MissionDone = true
                n0MissionsCount = 4
                n0NextMissionNum = 5
            else
                local storyStatus = nil
                if DataHandler and typeof(DataHandler.CheckOwnedStoryMode) == "function" then
                    pcall(function() storyStatus = DataHandler:CheckOwnedStoryMode() end)
                end
                if storyStatus and type(storyStatus) == "table" then
                    n0MissionDone = (storyStatus.AllBeaten == true)
                    n0MissionsCount = storyStatus.CompletedCount or 0
                    if storyStatus.Details and type(storyStatus.Details) == "table" then
                        for idx, m in ipairs(storyStatus.Details) do
                            if not m.Beaten then
                                n0NextMissionName = m.Name or storyMissionsMap[idx] or "Boot Camp"
                                n0NextMissionNum = storyMissionsIndex[n0NextMissionName] or idx
                                break
                            end
                        end
                    end
                end
            end

            local tToBuy = n0.TowerToBuy or (n0Step and n0Step.TowerToBuy)
            local tDone, tOwned, tMissing = checkTowersListOwned(tToBuy)
            local tFormatted, tTotalCoins = formatMissingTowers(tMissing)
            local coinsMet = (#tMissing == 0) or (tTotalCoins == 0) or (playerCoins >= tTotalCoins)

            -- Node 0 requires all 4 story missions to be completed.
            -- If story missions are incomplete, or if missions are complete and coins are ready to buy the tower, stay on Node 0.
            if not n0MissionDone or (not tDone and coinsMet) then
                local missionRatio = math.clamp(n0MissionsCount / 4, 0, 1)
                local towerRatio = tDone and 1 or 0
                local overallProg = (missionRatio * 0.7) + (towerRatio * 0.3)
                local objLines = {}
                table.insert(objLines, "📍 Current Node: Node 0 (Story Mode & Basics)")
                if not n0MissionDone then
                    table.insert(objLines, string.format("⚔️ Story Missions: %d/4 Beaten (Next: Mission %d - %s)", n0MissionsCount, n0NextMissionNum, n0NextMissionName))
                else
                    table.insert(objLines, "⚔️ Story Missions: 4/4 Completed (✓)")
                end
                if #tMissing > 0 then
                    table.insert(objLines, string.format("🛒 Towers to Buy: %s (Not Owned)", table.concat(tFormatted, ", ")))
                    if tTotalCoins > 0 then
                        table.insert(objLines, string.format("💰 Coins Goal: %d / %d Coins (%s)", playerCoins, tTotalCoins, coinsMet and "Ready to buy ✓" or string.format("%d needed", math.max(0, tTotalCoins - playerCoins))))
                    end
                else
                    table.insert(objLines, string.format("🛒 Towers to Buy: %s (Owned ✓)", table.concat(tOwned, ", ")))
                end
                table.insert(objLines, string.format("🛡️ Equip Loadout: %s", table.concat(n0Step.TowersToEquip or {"Scout", "Sniper"}, ", ")))

                return {
                    nodeName = "Node 0",
                    nodeNum = 0,
                    progress = overallProg,
                    title = string.format("Node 0 Progression (%d%%)", math.floor(overallProg * 100)),
                    status = string.format("Story: %d/4 | Next: %s", n0MissionsCount, (not n0MissionDone and ("M" .. n0NextMissionNum .. " " .. n0NextMissionName)) or (#tMissing > 0 and ("Buy " .. tMissing[1])) or "Complete"),
                    objectives = table.concat(objLines, "\n"),
                    config = n0,
                    stepConfig = n0Step,
                    isComplete = false,
                    nextMissionName = n0NextMissionName,
                    nextMissionNum = n0NextMissionNum,
                    towersToBuy = tMissing,
                    totalCoinsNeeded = tTotalCoins,
                    coinsMet = coinsMet,
                    playerCoins = playerCoins,
                    towersToEquip = n0Step.TowersToEquip or {"Scout", "Sniper"},
                    mode = "story",
                    chapter = 0,
                }
            end
        end

        -- 2. Check Node 1
        local n1 = cfg["Node 1"] or cfg["Node1"]
        local n1Step = n1 and n1[1]
        if n1 and n1Step then
            local lvlGoal = n1.LevelGoals or (n1Step and n1Step.LevelGoals) or 15
            local lvlPassed = (playerLevel >= lvlGoal)
            local tToBuyRaw = n1.TowerToBuy or (n1Step and n1Step.TowerToBuy) or {}
            local allNode1Towers = {}
            for _, t in ipairs(tToBuyRaw) do table.insert(allNode1Towers, t) end
            if not table.find(allNode1Towers, "Soldier") then table.insert(allNode1Towers, "Soldier") end
            if not table.find(allNode1Towers, "Assassin") then table.insert(allNode1Towers, "Assassin") end

            local tDone, tOwned, tMissing = checkTowersListOwned(allNode1Towers)
            local tFormatted, tTotalCoins = formatMissingTowers(tMissing)
            local coinsMet = (#tMissing == 0) or (tTotalCoins == 0) or (playerCoins >= tTotalCoins)
            local coinsDeficit = math.max(0, tTotalCoins - playerCoins)

            if not (lvlPassed and tDone) then
                local lvlRatio = math.clamp(playerLevel / lvlGoal, 0, 1)
                local coinRatio = (tTotalCoins > 0) and math.clamp(playerCoins / tTotalCoins, 0, 1) or (tDone and 1 or 0)
                local overallProg = (lvlRatio * 0.5) + (coinRatio * 0.5)
                local objLines = {}
                table.insert(objLines, string.format("📍 Current Node: Node 1 (Grind to Level %d & %s)", lvlGoal, table.concat(tToBuy or {"Assassin"}, ", ")))
                table.insert(objLines, string.format("📊 Level Goal: %d / %d (%d%%)", playerLevel, lvlGoal, math.floor(lvlRatio * 100)))
                if tTotalCoins > 0 then
                    if coinsMet then
                        table.insert(objLines, string.format("💰 Coins Goal: %d / %d Coins (100%% - Ready to buy ✓)", playerCoins, tTotalCoins))
                    else
                        table.insert(objLines, string.format("💰 Coins Goal: %d / %d Coins (%d%% - %d needed)", playerCoins, tTotalCoins, math.floor(coinRatio * 100), coinsDeficit))
                    end
                end
                if #tMissing > 0 then
                    table.insert(objLines, string.format("🛒 Towers to Buy: %s (Not Owned)", table.concat(tFormatted, ", ")))
                else
                    table.insert(objLines, string.format("🛒 Towers to Buy: %s (Owned ✓)", table.concat(tOwned, ", ")))
                end
                table.insert(objLines, string.format("🛡️ Equip Loadout: %s", table.concat(n1Step.TowersToEquip or {"Scout"}, ", ")))
                table.insert(objLines, string.format("⚔️ Mode: %s | Maps: %s", tostring(n1Step.Modes or "Easy"), table.concat(n1Step.Maps or {"Simplicity"}, ", ")))

                return {
                    nodeName = "Node 1",
                    nodeNum = 1,
                    progress = overallProg,
                    title = string.format("Node 1 Progression (Level %d/%d)", playerLevel, lvlGoal),
                    status = string.format("Level %d/%d | Coins: %d/%d (%s)", playerLevel, lvlGoal, playerCoins, tTotalCoins, (#tMissing > 0 and ("Buy: " .. table.concat(tMissing, ", "))) or "Ready"),
                    objectives = table.concat(objLines, "\n"),
                    config = n1,
                    stepConfig = n1Step,
                    isComplete = false,
                    levelGoal = lvlGoal,
                    currentLevel = playerLevel,
                    towersToBuy = tMissing,
                    totalCoinsNeeded = tTotalCoins,
                    coinsMet = coinsMet,
                    playerCoins = playerCoins,
                    towersToEquip = n1Step.TowersToEquip or {"Scout"},
                    mode = n1Step.Modes or "Easy",
                    maps = n1Step.Maps,
                    scripts = n1Step.scripts,
                }
            end
        end

        -- 3. Check Node 2
        local n2 = cfg["Node 2"] or cfg["Node2"]
        local n2Step = n2 and n2[1]
        if n2 and n2Step then
            local lvlGoal = n2.LevelGoals or (n2Step and n2Step.LevelGoals) or 50
            local lvlPassed = (playerLevel >= lvlGoal)
            local tToBuy = n2.TowerToBuy or (n2Step and n2Step.TowerToBuy)
            local tDone, tOwned, tMissing = checkTowersListOwned(tToBuy)
            local tFormatted, tTotalCoins = formatMissingTowers(tMissing)
            local coinsMet = (#tMissing == 0) or (tTotalCoins == 0) or (playerCoins >= tTotalCoins)
            local coinsDeficit = math.max(0, tTotalCoins - playerCoins)

            local tToClaim = n2.TowersToClaim or (n2Step and n2Step.TowersToClaim)
            local claimDone, claimOwned, claimMissing = checkTowersListOwned(tToClaim)

            if not (lvlPassed and tDone and claimDone) then
                local lvlRatio = math.clamp((playerLevel - 15) / (lvlGoal - 15), 0, 1)
                local coinRatio = (tTotalCoins > 0) and math.clamp(playerCoins / tTotalCoins, 0, 1) or (tDone and 1 or 0)
                local claimRatio = claimDone and 1 or 0
                local overallProg = (lvlRatio * 0.45) + (coinRatio * 0.4) + (claimRatio * 0.15)
                local objLines = {}
                table.insert(objLines, string.format("📍 Current Node: Node 2 (Molten & Level %d)", lvlGoal))
                table.insert(objLines, string.format("📊 Level Goal: %d / %d (%d%%)", playerLevel, lvlGoal, math.floor(math.clamp(playerLevel / lvlGoal, 0, 1) * 100)))
                if tTotalCoins > 0 then
                    if coinsMet then
                        table.insert(objLines, string.format("💰 Coins Goal: %d / %d Coins (100%% - Ready to buy ✓)", playerCoins, tTotalCoins))
                    else
                        table.insert(objLines, string.format("💰 Coins Goal: %d / %d Coins (%d%% - %d needed)", playerCoins, tTotalCoins, math.floor(coinRatio * 100), coinsDeficit))
                    end
                end
                if #tMissing > 0 then
                    table.insert(objLines, string.format("🛒 Towers to Buy: %s (Not Owned)", table.concat(tFormatted, ", ")))
                else
                    table.insert(objLines, string.format("🛒 Towers to Buy: %s (Owned ✓)", table.concat(tOwned, ", ")))
                end
                if #claimMissing > 0 then
                    table.insert(objLines, string.format("🎁 Towers to Claim: %s (Unlock at Lv30)", table.concat(claimMissing, ", ")))
                else
                    table.insert(objLines, string.format("🎁 Towers to Claim: %s (Claimed ✓)", table.concat(claimOwned, ", ")))
                end
                table.insert(objLines, string.format("🛡️ Equip Loadout: %s", table.concat(n2Step.TowersToEquip or {"Soldier"}, ", ")))
                table.insert(objLines, string.format("⚔️ Mode: %s | Maps: %s", tostring(n2Step.Modes or "Molten"), table.concat(n2Step.Maps or {"Lighthaos"}, ", ")))

                return {
                    nodeName = "Node 2",
                    nodeNum = 2,
                    progress = overallProg,
                    title = string.format("Node 2 Progression (Level %d/%d)", playerLevel, lvlGoal),
                    status = string.format("Level %d/%d | Coins: %d/%d | %s", playerLevel, lvlGoal, playerCoins, tTotalCoins, (#tMissing > 0 and ("Buy: " .. table.concat(tMissing, ", "))) or (#claimMissing > 0 and ("Claim: " .. table.concat(claimMissing, ", "))) or "Grinding"),
                    objectives = table.concat(objLines, "\n"),
                    config = n2,
                    stepConfig = n2Step,
                    isComplete = false,
                    levelGoal = lvlGoal,
                    currentLevel = playerLevel,
                    towersToBuy = tMissing,
                    totalCoinsNeeded = tTotalCoins,
                    coinsMet = coinsMet,
                    playerCoins = playerCoins,
                    towersToClaim = claimMissing,
                    towersToEquip = n2Step.TowersToEquip or {"Soldier"},
                    mode = n2Step.Modes or "Molten",
                    maps = n2Step.Maps,
                    scripts = n2Step.scripts,
                }
            end
        end

        -- 4. All Nodes Completed!
        return {
            nodeName = "Completed",
            nodeNum = 3,
            progress = 1.0,
            title = "All Progression Nodes Complete! 🎉",
            status = string.format("Level %d | All Node Objectives Satisfied", playerLevel),
            objectives = string.format("🎉 All progression nodes (Node 0, Node 1, Node 2) completed!\n📊 Level: %d\n✨ You have unlocked all progression milestones.", playerLevel),
            isComplete = true,
        }
    end

    local AutoProgTab = Window:Tab({
        Title = "Auto Prog",
        Subtitle = "Automated Game Progression",
    })

    local ControlSection = AutoProgTab:Section({ Title = "Progression Control" })

    progToggleRef = ControlSection:Toggle({
        Title = "Enable Auto Progress",
        Desc = "Automatically completes story missions, grinds node levels, equips loadouts, and buys towers per node.",
        Value = State.AutoProgress.Enabled,
        Callback = function(val: boolean)
            if val then
                local checkNode = getAutoProgressNodeInfo and getAutoProgressNodeInfo()
                if checkNode and checkNode.isComplete then
                    task.spawn(function()
                        task.wait(0.1)
                        if progToggleRef and typeof(progToggleRef.SetValue) == "function" then
                            pcall(function() progToggleRef:SetValue(false) end)
                        end
                    end)
                    State.AutoProgress.Enabled = false
                    Globals.AutoProgressEnabled = false
                    if Settings then Settings:Set("AutoProgressEnabled", false) end
                    SaveSettings(true)
                    Window:Notify({
                        Title = "All Nodes Reached!",
                        Desc = "You already reached all nodes! Auto Progress is complete.",
                        Duration = 6,
                    })
                    return
                end
            end
            State.AutoProgress.Enabled = val
            Globals.AutoProgressEnabled = val
            if Settings then Settings:Set("AutoProgressEnabled", val) end
            SaveSettings(true)
            Logger:Info("Auto Progress: " .. (val and "Enabled" or "Disabled"))
            if refreshAutoProgUI then refreshAutoProgUI() end
        end,
    })

    local initialInfo = getAutoProgressNodeInfo()
    local progBarRef = ControlSection:ProgressBar({
        Title = initialInfo.title,
        Desc = initialInfo.status,
        Progress = initialInfo.progress,
    })

    local StatusSection = AutoProgTab:Section({ Title = "Current Objectives & Status" })

    local progObjectivesLabel = StatusSection:Label({
        Title = "📍 " .. initialInfo.nodeName .. " Objectives",
        Desc = initialInfo.objectives,
    })

    local ActionSection = AutoProgTab:Section({ Title = "Actions" })
    ActionSection:Button({
        Title = "Refresh Progression Status",
        Desc = "Re-evaluates current account level, owned towers, and active node objectives.",
        Callback = function()
            if refreshAutoProgUI then
                refreshAutoProgUI()
                Window:Notify({
                    Title = "Progression Refreshed",
                    Desc = "Updated progression status from live player data.",
                    Duration = 3,
                })
            end
        end,
    })

    refreshAutoProgUI = function()
        pcall(function()
            local info = getAutoProgressNodeInfo()
            if progBarRef and typeof(progBarRef.SetProgress) == "function" then
                progBarRef:SetProgress(info.progress, info.status)
                if typeof(progBarRef.SetTitle) == "function" then
                    progBarRef:SetTitle(info.title)
                end
            end
            if progObjectivesLabel and typeof(progObjectivesLabel.SetDesc) == "function" then
                progObjectivesLabel:SetTitle("📍 " .. info.nodeName .. " Objectives")
                progObjectivesLabel:SetDesc(info.objectives)
            end
        end)
    end

    -- Real-time UI refresh loop
    task.spawn(function()
        while true do
            task.wait(2.5)
            if refreshAutoProgUI then
                refreshAutoProgUI()
            end
        end
    end)
end)()

--==============================================================================
-- 6. AUTO CURRENCY TAB
--==============================================================================
local CurrencyTab = Window:Tab({
    Title = "Auto Currency",
    Subtitle = "Farming & Resource Automation",
})

-- Segmented navigation at top of Auto Currency tab
local CurrencyModesSegmented = CurrencyTab:Segmented({
    Options = { "Auto Coins", "Auto Gems", "Auto Levels", "Auto Timescales", "Auto Evo" },
    Value = State.AutoCurrency.SelectedTab or "Auto Coins",
    Callback = function(choice: string)
        showCurrencySection(choice)
    end,
})

-- References to mode sections
local CoinsSection = nil
local GemsSection = nil
local LevelsSection = nil
local TimescalesSection = nil
local EvoSection = nil
local EvoTrackerSection = nil

local evoToggleRef = nil
local evoTargetDropdownRef = nil
local evoStratDropdownRef = nil
local evoStatusLabelRef = nil
local evoMissingLabelRef = nil
local evoCoinsGemsLabelRef = nil
local evoTowersLabelRef = nil

local missingCoinsLabel = nil
local missingGemsLabel = nil
local missingLevelsLabel = nil
local missingTimescalesLabel = nil

local coinsProgressLabel = nil
local gemsProgressLabel = nil
local levelsProgressLabel = nil

formatNumber = formatNumber or function(n: number | string): string
    local num = tonumber(n) or 0
    local formatted = tostring(math.floor(num))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function getCoinsProgressText(): string
    local currentCoins = 0
    if DataHandler and typeof(DataHandler.GetPlayerStats) == "function" then
        local ok, stats = pcall(function() return DataHandler:GetPlayerStats() end)
        if ok and stats and stats.Coins then
            currentCoins = stats.Coins
        end
    end
    local targetStr = (State and State.AutoCurrency and State.AutoCurrency.Coins and State.AutoCurrency.Coins.Target)
        or (Settings and Settings:Get("AutoCoinsTarget", "0"))
        or "0"
    local targetNum = tonumber(targetStr) or 0
    if targetNum > 0 then
        return string.format("Coins: %s / %s", formatNumber(currentCoins), formatNumber(targetNum))
    else
        return string.format("Coins: %s / 0", formatNumber(currentCoins))
    end
end

local function getGemsProgressText(): string
    local currentGems = 0
    if DataHandler and typeof(DataHandler.GetPlayerStats) == "function" then
        local ok, stats = pcall(function() return DataHandler:GetPlayerStats() end)
        if ok and stats and stats.Gems then
            currentGems = stats.Gems
        end
    end
    local targetStr = (State and State.AutoCurrency and State.AutoCurrency.Gems and State.AutoCurrency.Gems.Target)
        or (Settings and Settings:Get("AutoGemsTarget", "0"))
        or "0"
    local targetNum = tonumber(targetStr) or 0
    if targetNum > 0 then
        return string.format("Gems: %s / %s", formatNumber(currentGems), formatNumber(targetNum))
    else
        return string.format("Gems: %s / 0", formatNumber(currentGems))
    end
end

local function getLevelsProgressText(): string
    local currentLevel = 0
    local currentExp = 0
    if DataHandler then
        pcall(function()
            if typeof(DataHandler.GetPlayerStats) == "function" then
                local stats = DataHandler:GetPlayerStats()
                if stats then
                    currentLevel = stats.Level or 0
                    currentExp = stats.Exp or 0
                end
            elseif typeof(DataHandler.GetLevel) == "function" then
                currentLevel = DataHandler:GetLevel() or 0
            end
        end)
    end

    local targetStr = (State and State.AutoCurrency and State.AutoCurrency.Levels and State.AutoCurrency.Levels.Target)
        or (Settings and Settings:Get("AutoLevelsTarget", "0"))
        or "0"
    local targetNum = tonumber(targetStr) or 0

    if targetNum > 0 then
        local targetProg = nil
        if DataHandler and typeof(DataHandler.GetTargetLevelProgress) == "function" then
            local ok, prog = pcall(function()
                return DataHandler:GetTargetLevelProgress(targetNum, currentLevel, currentExp)
            end)
            if ok and prog then
                targetProg = prog
            end
        end

        local totalExp = (targetProg and targetProg.TotalEarnedExp) or currentExp
        local reqExp = (targetProg and targetProg.TotalTargetExp) or targetNum

        return string.format("Level: %s / %s | Requires: %s / %s",
            formatNumber(currentLevel),
            formatNumber(targetNum),
            formatNumber(totalExp),
            formatNumber(reqExp)
        )
    else
        return string.format("Level: %s / 0 | Requires: %s / 0",
            formatNumber(currentLevel),
            formatNumber(currentExp)
        )
    end
end

local function formatTrialCountdown(seconds: number): string
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%02d:%02d", mins, secs)
    end
end

local lastObservedTrialTitle = nil
local lastTrialRotationExpiry = 0

local function getCurrentTrialDisplayText(): string
    if not PlayerDataHandler then return "Detecting current trial..." end
    local now = os.time()
    local shouldForce = (lastTrialRotationExpiry > 0 and now >= lastTrialRotationExpiry)
    local cur = nil
    pcall(function() cur = PlayerDataHandler:GetCurrentTrial(shouldForce) end)
    if not cur or not (cur.Title or cur.Name) then
        return "None active / Fetching lobby data..."
    end

    local title = cur.Title or cur.Name
    local map = cur.Map or "Unknown Map"
    local expiresAt = cur.ExpiresAt

    if expiresAt then
        lastTrialRotationExpiry = expiresAt
        local remSecs = math.max(0, expiresAt - now)
        if remSecs == 0 then
            return string.format("%s (%s) [Rotating now...]", title, map)
        end
        return string.format("%s (%s) [%s left]", title, map, formatTrialCountdown(remSecs))
    else
        local timeLeft = cur.TimeRemaining or "Active"
        return string.format("%s (%s) [%s left]", title, map, timeLeft)
    end
end

local function getNextTrialDisplayText(): string
    if not PlayerDataHandler then return "Detecting next trial..." end
    local now = os.time()
    local shouldForce = (lastTrialRotationExpiry > 0 and now >= lastTrialRotationExpiry)
    local nxt = nil
    pcall(function() nxt = PlayerDataHandler:GetNextTrial(shouldForce) end)
    if not nxt or not (nxt.Title or nxt.Name) then
        return "Rotating soon..."
    end

    local title = nxt.Title or nxt.Name
    local map = nxt.Map or "Unknown Map"

    local cur = nil
    pcall(function() cur = PlayerDataHandler:GetCurrentTrial() end)
    local curExpiresAt = cur and cur.ExpiresAt

    if curExpiresAt and curExpiresAt > now then
        local startsIn = curExpiresAt - now
        return string.format("%s (%s) [Starts in %s]", title, map, formatTrialCountdown(startsIn))
    elseif curExpiresAt and curExpiresAt <= now then
        return string.format("%s (%s) [Starting now...]", title, map)
    else
        return string.format("%s (%s)", title, map)
    end
end

local function getTrialEligibilityDisplayText(): string
    if not PlayerDataHandler then return "Checking requirements..." end
    local cur = nil
    pcall(function() cur = PlayerDataHandler:GetCurrentTrial() end)
    local title = cur and (cur.Title or cur.Name)
    if not title then
        return "Pending trial data..."
    end

    local isPrem = checkIsPremium()

    -- Ignore list and Fallback are Premium features
    if isPrem then
        local ignored = (State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.IgnoredTrials)
            or (Settings and Settings:Get("AutoTimescalesIgnoredTrials", { "Glass", "Committed", "Limitation" }))
            or {}
        local isIgnored = false
        local normTitle = string.lower(tostring(title)):gsub("%s+", "")
        for _, ign in ipairs(ignored) do
            if string.lower(tostring(ign)):gsub("%s+", "") == normTitle or string.find(normTitle, string.lower(tostring(ign)):gsub("%s+", ""), 1, true) then
                isIgnored = true
                break
            end
        end
        if isIgnored then
            local fb = (State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Fallback) or "Molten"
            return string.format("Eligible: NO - Ignored by filter (%s) -> Fallback (%s)", title, fb)
        end
    end

    local eligible, details = checkTrialEligibility(title)
    if eligible then
        return "Eligible: YES (Ready to Farm)"
    else
        if isPrem then
            local fb = (State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Fallback) or "Molten"
            return string.format("Eligible: NO - %s -> Fallback (%s)", details, fb)
        else
            return string.format("Eligible: NO - %s (Waiting for rotation)", details)
        end
    end
end

local function getTimescalesProgressText(): string
    local currentTickets = 0
    if PlayerDataHandler and typeof(PlayerDataHandler.GetTimescaleTickets) == "function" then
        local ok, t = pcall(function() return PlayerDataHandler:GetTimescaleTickets() end)
        if ok and t then currentTickets = tonumber(t) or 0 end
    end
    local targetVal = tonumber(State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Target) or 0
    if targetVal == 0 then
        return string.format("User Timescales: %s / 0 (Infinite)", formatCommas(currentTickets))
    else
        return string.format("User Timescales: %s / %s", formatCommas(currentTickets), formatCommas(targetVal))
    end
end

showCurrencySection = function(mode: string)
    State.AutoCurrency.SelectedTab = mode
    if Settings then Settings:Set("SelectedCurrencyTab", mode) end
    if CoinsSection and CoinsSection.Root then CoinsSection.Root.Visible = (mode == "Auto Coins") end
    if GemsSection and GemsSection.Root then GemsSection.Root.Visible = (mode == "Auto Gems") end
    if LevelsSection and LevelsSection.Root then LevelsSection.Root.Visible = (mode == "Auto Levels") end
    if TimescalesSection and TimescalesSection.Root then TimescalesSection.Root.Visible = (mode == "Auto Timescales") end
    if EvoSection and EvoSection.Root then EvoSection.Root.Visible = (mode == "Auto Evo") end
    if EvoTrackerSection and EvoTrackerSection.Root then EvoTrackerSection.Root.Visible = (mode == "Auto Evo") end
end

refreshCurrencyBox = function()
    if missingCoinsLabel then
        pcall(function()
            local txt = getMissingTowersText("Coins")
            if missingCoinsLabel.SetDesc then missingCoinsLabel:SetDesc(txt) end
            if missingCoinsLabel.SetText then missingCoinsLabel:SetText(txt) end
        end)
    end
    if missingGemsLabel then
        pcall(function()
            local txt = getMissingTowersText("Gems")
            if missingGemsLabel.SetDesc then missingGemsLabel:SetDesc(txt) end
            if missingGemsLabel.SetText then missingGemsLabel:SetText(txt) end
        end)
    end
    if missingLevelsLabel then
        pcall(function()
            local txt = getMissingTowersText("Levels")
            if missingLevelsLabel.SetDesc then missingLevelsLabel:SetDesc(txt) end
            if missingLevelsLabel.SetText then missingLevelsLabel:SetText(txt) end
        end)
    end
    if missingTimescalesLabel then
        pcall(function()
            local txt = getMissingTowersText("Timescales")
            if missingTimescalesLabel.SetDesc then missingTimescalesLabel:SetDesc(txt) end
            if missingTimescalesLabel.SetText then missingTimescalesLabel:SetText(txt) end
        end)
    end
    if coinsProgressLabel then pcall(function() coinsProgressLabel:SetDesc(getCoinsProgressText()) end) end
    if gemsProgressLabel then pcall(function() gemsProgressLabel:SetDesc(getGemsProgressText()) end) end
    if levelsProgressLabel then pcall(function() levelsProgressLabel:SetDesc(getLevelsProgressText()) end) end
    if currentTrialLabelRef then pcall(function() currentTrialLabelRef:SetDesc(getCurrentTrialDisplayText()) end) end
    if nextTrialLabelRef then pcall(function() nextTrialLabelRef:SetDesc(getNextTrialDisplayText()) end) end
    if trialEligibilityLabelRef then pcall(function() trialEligibilityLabelRef:SetDesc(getTrialEligibilityDisplayText()) end) end
    if timescaleStatusLabelRef then pcall(function() timescaleStatusLabelRef:SetDesc(getTimescalesProgressText()) end) end

    if evoStatusLabelRef or evoMissingLabelRef then
        pcall(function()
            local evoAnalysis = AutoEvoModule.AnalyzeRequirements()
            local displayTarget = evoAnalysis.targetEvo
            if evoAnalysis.targetEvo == "All" and evoAnalysis.activeTower then
                displayTarget = "All [" .. evoAnalysis.activeTower .. "]"
            end
            local selectedModeStr = string.format("%s (%s)", displayTarget, evoAnalysis.stratChoice)

            if evoStatusLabelRef then
                evoStatusLabelRef:SetTitle("Status: " .. selectedModeStr)
                if evoAnalysis.allFinished then
                    evoStatusLabelRef:SetDesc("Finished (All Evolutions Complete)")
                elseif not evoAnalysis.configFound and not evoAnalysis.readyToBuy then
                    evoStatusLabelRef:SetDesc("Config Missing")
                elseif not evoAnalysis.isEligible then
                    evoStatusLabelRef:SetDesc("🔒 Locked (Missing Requirements)")
                elseif evoAnalysis.readyToBuy then
                    if State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Enabled then
                        evoStatusLabelRef:SetDesc("Buying Evolution: " .. tostring(evoAnalysis.activeTower) .. "...")
                    else
                        evoStatusLabelRef:SetDesc("Ready (Can Evolve " .. tostring(evoAnalysis.activeTower) .. ")")
                    end
                elseif game.PlaceId == LOBBY_PLACE_ID then
                    if State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Enabled then
                        evoStatusLabelRef:SetDesc(string.format("Queuing: %s - %s (%s)...", tostring(evoAnalysis.activeTower), tostring(evoAnalysis.targetMode), tostring(evoAnalysis.farmType)))
                    else
                        evoStatusLabelRef:SetDesc("Ready (Automation Off)")
                    end
                else
                    evoStatusLabelRef:SetDesc(string.format("In Match: %s - %s (%s)", tostring(evoAnalysis.activeTower), tostring(evoAnalysis.targetMode), tostring(evoAnalysis.farmType)))
                end
            end

            if evoMissingLabelRef then
                evoMissingLabelRef:SetTitle("Missing:")
                if evoAnalysis.allFinished then
                    evoMissingLabelRef:SetDesc("None (All targets complete)")
                elseif #evoAnalysis.missingParts > 0 then
                    evoMissingLabelRef:SetDesc(table.concat(evoAnalysis.missingParts, " | "))
                else
                    evoMissingLabelRef:SetDesc("None (All requirements met)")
                end
            end
        end)
    end

    if evoCoinsGemsLabelRef or evoTowersLabelRef then
        pcall(function()
            local coins = 0
            local gems = 0
            if PlayerDataHandler then
                if typeof(PlayerDataHandler.GetCoins) == "function" then
                    pcall(function() coins = PlayerDataHandler:GetCoins() or 0 end)
                end
                if typeof(PlayerDataHandler.GetGems) == "function" then
                    pcall(function() gems = PlayerDataHandler:GetGems() or 0 end)
                end
            end

            local selected = tostring((State and State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Target) or (Globals and Globals.TargetEvo) or "All")
            selected = AutoEvoModule.NormalizeTowerName(selected)
            local toCheck = {}
            local activeTowerFound = nil

            if selected == "All" then
                for _, tName in ipairs(AutoEvoModule.GetTowerList()) do
                    if not AutoEvoModule.IsTowerEvoComplete(tName) and AutoEvoModule.IsTowerOrEvoOwned(tName) then
                        if not activeTowerFound then activeTowerFound = tName end
                        table.insert(toCheck, tName)
                    end
                end
                if activeTowerFound then
                    toCheck = { activeTowerFound }
                else
                    toCheck = {}
                end
            elseif AutoEvoModule.EvoData[selected] then
                toCheck = { selected }
                activeTowerFound = selected
            end

            if evoCoinsGemsLabelRef then
                local coinsStr, gemsStr
                if #toCheck == 0 then
                    coinsStr = "Coins: Complete!"
                    gemsStr = "Gems: Complete!"
                elseif activeTowerFound and AutoEvoModule.EvoData[activeTowerFound] then
                    local evoInfo = AutoEvoModule.EvoData[activeTowerFound]
                    local ownsActiveEvo = PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" and PlayerDataHandler:IsTowerOwned(evoInfo.Evo)
                    if ownsActiveEvo then
                        coinsStr = "Coins: Complete! (" .. activeTowerFound .. ")"
                        gemsStr = "Gems: Complete! (Grinding Level)"
                    else
                        coinsStr = string.format("Coins: %s / %s", formatNumber(coins), formatNumber(evoInfo.Coins))
                        gemsStr = string.format("Gems: %s / %s", formatNumber(gems), formatNumber(evoInfo.Gems))
                    end
                else
                    coinsStr = "Coins: (No target)"
                    gemsStr = "Gems: (No target)"
                end
                evoCoinsGemsLabelRef:SetDesc(coinsStr .. "\n" .. gemsStr)
            end

            if evoTowersLabelRef then
                local towersText = ""
                local grindState = "Idle / Finished"
                local stateFound = false

                if #toCheck > 0 then
                    local lines = {}
                    for _, towerName in ipairs(toCheck) do
                        local eData = AutoEvoModule.EvoData[towerName]
                        local evoName = eData and eData.Evo or towerName

                        local ownsEvo = PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" and PlayerDataHandler:IsTowerOwned(evoName)
                        if ownsEvo then
                            table.insert(lines, towerName .. ": Complete!")
                            if PlayerDataHandler and typeof(PlayerDataHandler.GetTowerExp) == "function" then
                                local evoExp = PlayerDataHandler:GetTowerExp(evoName)
                                if evoExp then
                                    if evoExp.Level < 20 then
                                        local progStr = evoExp.ProgressDisplay or string.format("%d / %d EXP", evoExp.Exp or 0, evoExp.MaxExp or 0)
                                        table.insert(lines, string.format("%s: Level %d/20 (%s)", evoName, evoExp.Level, progStr))
                                        if not stateFound then grindState = "Grinding level..."; stateFound = true; Globals.CurrentEvoActiveTower = towerName end
                                    else
                                        table.insert(lines, evoName .. ": Complete!")
                                    end
                                else
                                    table.insert(lines, evoName .. ": (Waiting for data)")
                                end
                            end
                        else
                            if PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" and not PlayerDataHandler:IsTowerOwned(towerName) then
                                table.insert(lines, towerName .. ": Tower not owned")
                                table.insert(lines, evoName .. ": Locked")
                                if not stateFound then grindState = "Grinding coins..."; stateFound = true; Globals.CurrentEvoActiveTower = towerName end
                            else
                                if PlayerDataHandler and typeof(PlayerDataHandler.GetTowerExp) == "function" then
                                    local expData = PlayerDataHandler:GetTowerExp(towerName)
                                    if expData then
                                        local coinsNeed = math.max(0, eData.Coins - coins)
                                        local gemsNeed = math.max(0, eData.Gems - gems)

                                        if expData.Level < 20 then
                                            local progStr = expData.ProgressDisplay or string.format("%d / %d EXP", expData.Exp or 0, expData.MaxExp or 0)
                                            table.insert(lines, string.format("%s: Level %d/20 (%s)", towerName, expData.Level, progStr))
                                        end

                                        if coinsNeed == 0 and gemsNeed == 0 then
                                            if expData.Level < 20 then
                                                if not stateFound then grindState = "Grinding level..."; stateFound = true; Globals.CurrentEvoActiveTower = towerName end
                                            else
                                                table.insert(lines, towerName .. ": Complete!")
                                                if not stateFound then grindState = "Buying Selected Evo...."; stateFound = true; Globals.CurrentEvoActiveTower = towerName end

                                                if State and State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Enabled then
                                                    AutoEvoModule.AttemptPurchase(towerName, evoName)
                                                end
                                            end
                                        else
                                            local reqStr = {}
                                            if coinsNeed > 0 then table.insert(reqStr, formatNumber(coinsNeed) .. " Coins") end
                                            if gemsNeed > 0 then table.insert(reqStr, formatNumber(gemsNeed) .. " Gems") end
                                            table.insert(lines, string.format("%s: Needs %s", towerName, table.concat(reqStr, ", ")))

                                            if not stateFound then
                                                if coinsNeed > 0 then grindState = "Grinding coins..."
                                                else grindState = "Grinding gems..." end
                                                stateFound = true
                                                Globals.CurrentEvoActiveTower = towerName
                                            end
                                        end
                                    else
                                        table.insert(lines, towerName .. ": (Waiting for data)")
                                    end
                                    table.insert(lines, evoName .. ": Locked (Requires Base)")
                                else
                                    table.insert(lines, towerName .. ": (Update DataHandler)")
                                end
                            end
                        end
                    end
                    towersText = table.concat(lines, "\n")
                else
                    towersText = (selected == "All") and "All Evolutions Complete!" or "(No target selected)"
                    grindState = (selected == "All") and "Idle / Finished" or "No target selected"
                end

                evoTowersLabelRef:SetDesc(towersText)
                Globals.CurrentEvoGrindState = grindState
            end
        end)
    end
end

-- 1. Auto Coins Section
CoinsSection = CurrencyTab:Section({ Title = "Auto Coins Configuration" })

CoinsSection:Banner({
    Title = "Auto Coins Farming",
    Desc = "Automated molten/normal match queuing, automated wave progression, and target-based coin accumulation.",
    Type = "Info",
})

coinsToggleRef = nil
coinsDropdownRef = nil
coinsTextboxRef = nil

coinsToggleRef = CoinsSection:Toggle({
    Title = "Turn on Auto Coins",
    Desc = "Toggle automated coin farming routines",
    Value = State.AutoCurrency.Coins.Enabled,
    Callback = function(val: boolean)
        State.AutoCurrency.Coins.Enabled = val
        if Settings then Settings:Set("AutoCoinsEnabled", val) end
        refreshCurrencyBox()
        StatsGrid:UpdateItem(5, val and "ACTIVE" or "OFF", val and "Farming coins" or "Standing by")
        Logger:Info("Auto Coins: " .. (val and "ACTIVE" or "OFF"))
    end,
})

coinsDropdownRef = CoinsSection:Dropdown({
    Title = "Conditions",
    Desc = "Trigger match leave/retry on victory or defeat",
    List = { "Lose", "Win" },
    Value = State.AutoCurrency.Coins.Condition or "Lose",
    Callback = function(choice: string)
        if choice == "Win" and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Win condition requires an active Premium plan. Defaulting to Lose (Free Tier mode).",
                Duration = 4,
            })
            Logger:Warn("Auto Coins: 'Win' condition requires Premium. Defaulting to Lose (Free Tier mode).")
            State.AutoCurrency.Coins.Condition = "Lose"
            if Settings then Settings:Set("AutoCoinsCondition", "Lose") end
            task.spawn(function()
                if coinsDropdownRef and type(coinsDropdownRef.SetValue) == "function" then
                    coinsDropdownRef:SetValue("Lose")
                end
            end)
            if missingCoinsLabel then
                pcall(function()
                    local txt = getMissingTowersText("Coins", "Lose")
                    if missingCoinsLabel.SetDesc then missingCoinsLabel:SetDesc(txt) end
                    if missingCoinsLabel.SetText then missingCoinsLabel:SetText(txt) end
                end)
            end
            refreshCurrencyBox()
            return
        end
        State.AutoCurrency.Coins.Condition = choice
        if Settings then Settings:Set("AutoCoinsCondition", choice) end
        if getgenv then
            getgenv().AutoRestart = false
            getgenv().AutoRejoin = false
        end
        Globals.AutoRestart = false
        Globals.AutoRejoin = false
        if missingCoinsLabel then
            pcall(function()
                local txt = getMissingTowersText("Coins", choice)
                if missingCoinsLabel.SetDesc then missingCoinsLabel:SetDesc(txt) end
                if missingCoinsLabel.SetText then missingCoinsLabel:SetText(txt) end
            end)
        end
        refreshCurrencyBox()
    end,
})

coinsTextboxRef = CoinsSection:Textbox({
    Title = "Target Coins",
    Desc = "Amount of coins to farm (0 = infinite)",
    Placeholder = "0 = infinite",
    Value = State.AutoCurrency.Coins.Target,
    ClearTextOnFocus = false,
    Callback = function(txt: string)
        State.AutoCurrency.Coins.Target = txt
        if Settings then Settings:Set("AutoCoinsTarget", txt) end
        refreshCurrencyBox()
    end,
})

coinsProgressLabel = CoinsSection:Label({
    Title = "Coins Status",
    Desc = getCoinsProgressText(),
})

missingCoinsLabel = CoinsSection:Label({
    Title = "Coins: Towers Needed",
    Desc = getMissingTowersText("Coins"),
})

-- 2. Auto Gems Section
GemsSection = CurrencyTab:Section({ Title = "Auto Gems Configuration" })

GemsSection:Banner({
    Title = "Auto Gems Farming (Hardcore)",
    Desc = "Automated Hardcore lobby matchmaking, strategic wave advancement, and gem threshold monitoring.",
    Type = "Info",
})

gemsToggleRef = nil
gemsDropdownRef = nil
gemsTextboxRef = nil

gemsToggleRef = GemsSection:Toggle({
    Title = "Turn on Auto Gems",
    Desc = "Toggle automated gem farming routines",
    Value = State.AutoCurrency.Gems.Enabled,
    Callback = function(val: boolean)
        State.AutoCurrency.Gems.Enabled = val
        if Settings then Settings:Set("AutoGemsEnabled", val) end
        refreshCurrencyBox()
        StatsGrid:UpdateItem(5, val and "ACTIVE" or "OFF", val and "Farming gems" or "Standing by")
        Logger:Info("Auto Gems: " .. (val and "ACTIVE" or "OFF"))
    end,
})

gemsDropdownRef = GemsSection:Dropdown({
    Title = "Conditions",
    Desc = "Trigger match leave/retry on victory or defeat",
    List = { "Lose", "Win" },
    Value = State.AutoCurrency.Gems.Condition or "Lose",
    Callback = function(choice: string)
        if choice == "Win" and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Win condition requires an active Premium plan. Defaulting to Lose (Free Tier mode).",
                Duration = 4,
            })
            Logger:Warn("Auto Gems: 'Win' condition requires Premium. Defaulting to Lose (Free Tier mode).")
            State.AutoCurrency.Gems.Condition = "Lose"
            if Settings then Settings:Set("AutoGemsCondition", "Lose") end
            task.spawn(function()
                if gemsDropdownRef and type(gemsDropdownRef.SetValue) == "function" then
                    gemsDropdownRef:SetValue("Lose")
                end
            end)
            if missingGemsLabel then
                pcall(function()
                    local txt = getMissingTowersText("Gems", "Lose")
                    if missingGemsLabel.SetDesc then missingGemsLabel:SetDesc(txt) end
                    if missingGemsLabel.SetText then missingGemsLabel:SetText(txt) end
                end)
            end
            refreshCurrencyBox()
            return
        end
        State.AutoCurrency.Gems.Condition = choice
        if Settings then Settings:Set("AutoGemsCondition", choice) end
        if getgenv then
            getgenv().AutoRestart = false
            getgenv().AutoRejoin = false
        end
        Globals.AutoRestart = false
        Globals.AutoRejoin = false
        if missingGemsLabel then
            pcall(function()
                local txt = getMissingTowersText("Gems", choice)
                if missingGemsLabel.SetDesc then missingGemsLabel:SetDesc(txt) end
                if missingGemsLabel.SetText then missingGemsLabel:SetText(txt) end
            end)
        end
        refreshCurrencyBox()
    end,
})

gemsTextboxRef = GemsSection:Textbox({
    Title = "Target Gems",
    Desc = "Amount of gems to farm (0 = infinite)",
    Placeholder = "0 = infinite",
    Value = State.AutoCurrency.Gems.Target,
    ClearTextOnFocus = false,
    Callback = function(txt: string)
        State.AutoCurrency.Gems.Target = txt
        if Settings then Settings:Set("AutoGemsTarget", txt) end
        refreshCurrencyBox()
    end,
})

gemsProgressLabel = GemsSection:Label({
    Title = "Gems Status",
    Desc = getGemsProgressText(),
})

missingGemsLabel = GemsSection:Label({
    Title = "Gems: Towers Needed",
    Desc = getMissingTowersText("Gems"),
})

-- 3. Auto Levels Section
LevelsSection = CurrencyTab:Section({ Title = "Auto Levels Configuration" })

LevelsSection:Banner({
    Title = "Auto Levels Progression",
    Desc = "Rapid EXP match cycling to hit specific account level milestones automatically.",
    Type = "Info",
})

levelsToggleRef = nil
levelsDropdownRef = nil
levelsCurrencyDropdownRef = nil
levelsTextboxRef = nil

levelsToggleRef = LevelsSection:Toggle({
    Title = "Turn on Auto Levels",
    Desc = "Toggle automated EXP leveling routines",
    Value = State.AutoCurrency.Levels.Enabled,
    Callback = function(val: boolean)
        State.AutoCurrency.Levels.Enabled = val
        if Settings then Settings:Set("AutoLevelsEnabled", val) end
        refreshCurrencyBox()
        StatsGrid:UpdateItem(5, val and "ACTIVE" or "OFF", val and "Farming levels" or "Standing by")
        Logger:Info("Auto Levels: " .. (val and "ACTIVE" or "OFF"))
    end,
})

levelsDropdownRef = LevelsSection:Dropdown({
    Title = "Conditions",
    Desc = "Trigger match leave/retry on victory or defeat",
    List = { "Lose", "Win" },
    Value = State.AutoCurrency.Levels.Condition or "Lose",
    Callback = function(choice: string)
        if choice == "Win" and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Win condition requires an active Premium plan. Defaulting to Lose (Free Tier mode).",
                Duration = 4,
            })
            Logger:Warn("Auto Levels: 'Win' condition requires Premium. Defaulting to Lose (Free Tier mode).")
            State.AutoCurrency.Levels.Condition = "Lose"
            if Settings then Settings:Set("AutoLevelsCondition", "Lose") end
            task.spawn(function()
                if levelsDropdownRef and type(levelsDropdownRef.SetValue) == "function" then
                    levelsDropdownRef:SetValue("Lose")
                end
            end)
            if missingLevelsLabel then
                pcall(function()
                    local txt = getMissingTowersText("Levels", "Lose")
                    if missingLevelsLabel.SetDesc then missingLevelsLabel:SetDesc(txt) end
                    if missingLevelsLabel.SetText then missingLevelsLabel:SetText(txt) end
                end)
            end
            refreshCurrencyBox()
            return
        end
        State.AutoCurrency.Levels.Condition = choice
        if Settings then Settings:Set("AutoLevelsCondition", choice) end
        if missingLevelsLabel then
            pcall(function()
                local txt = getMissingTowersText("Levels", choice)
                if missingLevelsLabel.SetDesc then missingLevelsLabel:SetDesc(txt) end
                if missingLevelsLabel.SetText then missingLevelsLabel:SetText(txt) end
            end)
        end
        refreshCurrencyBox()
    end,
})

levelsCurrencyDropdownRef = LevelsSection:Dropdown({
    Title = "Selected Currency",
    Desc = "Choose currency farming route for Auto Levels",
    List = { "Coins", "Gems" },
    Value = State.AutoCurrency.Levels.Currency or "Coins",
    Callback = function(choice: string)
        State.AutoCurrency.Levels.Currency = choice
        if Settings then Settings:Set("AutoLevelsCurrency", choice) end
        if missingLevelsLabel then
            pcall(function()
                local txt = getMissingTowersText("Levels")
                if missingLevelsLabel.SetDesc then missingLevelsLabel:SetDesc(txt) end
                if missingLevelsLabel.SetText then missingLevelsLabel:SetText(txt) end
            end)
        end
        refreshCurrencyBox()
    end,
})

levelsTextboxRef = LevelsSection:Textbox({
    Title = "Target Level",
    Desc = "Target player level to reach (0 = infinite)",
    Placeholder = "0 = infinite",
    Value = State.AutoCurrency.Levels.Target,
    ClearTextOnFocus = false,
    Callback = function(txt: string)
        State.AutoCurrency.Levels.Target = txt
        if Settings then Settings:Set("AutoLevelsTarget", txt) end
        refreshCurrencyBox()
    end,
})

levelsProgressLabel = LevelsSection:Label({
    Title = "Level status",
    Desc = getLevelsProgressText(),
})

missingLevelsLabel = LevelsSection:Label({
    Title = "Levels: Towers Needed",
    Desc = getMissingTowersText("Levels"),
})

-- 4. Auto Timescales Section
TimescalesSection = CurrencyTab:Section({ Title = "Auto Timescales Configuration" })

TimescalesSection:Banner({
    Title = "Auto Timescales Farming",
    Desc = "Special mode farming for timescale tickets and accelerated reward boosts.",
    Type = "Info",
})

timescalesToggleRef = nil
timescalesFallbackDropdownRef = nil
timescalesTextboxRef = nil
currentTrialLabelRef = nil
nextTrialLabelRef = nil
trialEligibilityLabelRef = nil
timescaleStatusLabelRef = nil

timescalesToggleRef = TimescalesSection:Toggle({
    Title = "Turn on Auto Timescales",
    Desc = "Toggle automated Trials timescale ticket farming routines",
    Value = State.AutoCurrency.Timescales.Enabled,
    Callback = function(val: boolean)
        State.AutoCurrency.Timescales.Enabled = val
        if Settings then Settings:Set("AutoTimescalesEnabled", val) end
        refreshCurrencyBox()
        StatsGrid:UpdateItem(5, val and "ACTIVE" or "OFF", val and "Farming timescales" or "Standing by")
        Logger:Info("Auto Timescales: " .. (val and "ACTIVE" or "OFF"))
    end,
})

currentTrialLabelRef = TimescalesSection:Label({
    Title = "Current Trial",
    Desc = getCurrentTrialDisplayText(),
})

nextTrialLabelRef = TimescalesSection:Label({
    Title = "Next Trial",
    Desc = getNextTrialDisplayText(),
})

trialEligibilityLabelRef = TimescalesSection:Label({
    Title = "Trial Eligibility",
    Desc = getTrialEligibilityDisplayText(),
})

local timescalesIgnoredDropdownRef = nil

local allTrialList = {
    "Glass",
    "Committed",
    "Limitation",
    "Speedy Enemies",
    "Quarantine",
    "Fog",
    "Flying Enemies",
    "Jailed",
    "Exploding Enemies",
    "Inflation",
    "Hidden Enemies",
    "Broke",
    "Healthy Enemies"
}

timescalesIgnoredDropdownRef = TimescalesSection:Dropdown({
    Title = "Trials to Ignore",
    Desc = checkIsPremium() and "Ignore active trials matching these types and wait for next rotation (Premium)" or "Locked — Premium VIP Plan Required",
    List = allTrialList,
    Multi = true,
    Value = State.AutoCurrency.Timescales.IgnoredTrials or { "Glass", "Committed", "Limitation" },
    Callback = function(selectedList: { string })
        if not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Please activate Premium plan",
                Duration = 3.5,
            })
            Logger:Warn("Auto Timescales: 'Trials to Ignore' is locked. Premium plan required.")
            local defaultIgnored = { "Glass", "Committed", "Limitation" }
            State.AutoCurrency.Timescales.IgnoredTrials = defaultIgnored
            if Settings then Settings:Set("AutoTimescalesIgnoredTrials", defaultIgnored) end
            task.spawn(function()
                if timescalesIgnoredDropdownRef and type(timescalesIgnoredDropdownRef.SetValue) == "function" then
                    timescalesIgnoredDropdownRef:SetValue(defaultIgnored)
                end
            end)
            return
        end
        State.AutoCurrency.Timescales.IgnoredTrials = selectedList
        if Settings then Settings:Set("AutoTimescalesIgnoredTrials", selectedList) end
        refreshCurrencyBox()
        Logger:Info("Auto Timescales Ignored Trials updated: " .. table.concat(selectedList or {}, ", "))
    end,
})

timescalesFallbackDropdownRef = TimescalesSection:Dropdown({
    Title = "Fallbacks",
    Desc = checkIsPremium() and "Backup mode to run if ineligible for the active trial" or "Locked — Premium VIP Plan Required",
    List = { "Molten", "Fallen" },
    Value = State.AutoCurrency.Timescales.Fallback or "Molten",
    Callback = function(choice: string)
        if not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Please activate Premium plan",
                Duration = 3.5,
            })
            Logger:Warn("Auto Timescales: 'Fallbacks' is locked. Premium plan required.")
            task.spawn(function()
                if timescalesFallbackDropdownRef and type(timescalesFallbackDropdownRef.SetValue) == "function" then
                    timescalesFallbackDropdownRef:SetValue("Molten")
                end
            end)
            return
        end
        State.AutoCurrency.Timescales.Fallback = choice
        if Settings then Settings:Set("AutoTimescalesFallback", choice) end
        Logger:Info("Auto Timescales Fallback set to: " .. choice)
    end,
})

timescalesTextboxRef = TimescalesSection:Textbox({
    Title = "Target Timescales",
    Desc = checkIsPremium() and "Target timescale tickets to reach (0 = infinite)" or "Locked — Premium VIP Plan Required",
    Placeholder = "0 = infinite",
    Value = State.AutoCurrency.Timescales.Target or "0",
    ClearTextOnFocus = false,
    Callback = function(txt: string)
        if not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Please activate Premium plan",
                Duration = 3.5,
            })
            Logger:Warn("Auto Timescales: 'Target Timescales' is locked. Premium plan required.")
            State.AutoCurrency.Timescales.Target = "0"
            if Settings then Settings:Set("AutoTimescalesTarget", "0") end
            task.spawn(function()
                if timescalesTextboxRef and type(timescalesTextboxRef.SetValue) == "function" then
                    timescalesTextboxRef:SetValue("0")
                end
            end)
            refreshCurrencyBox()
            return
        end
        State.AutoCurrency.Timescales.Target = txt
        if Settings then Settings:Set("AutoTimescalesTarget", txt) end
        refreshCurrencyBox()
    end,
})

timescaleStatusLabelRef = TimescalesSection:Label({
    Title = "Timescales Status",
    Desc = getTimescalesProgressText(),
})

-- 5. Auto Evo Section
EvoSection = CurrencyTab:Section({ Title = "Auto Evolution Configuration" })

EvoSection:Banner({
    Title = "Auto Evolution Farming",
    Desc = "Automated evolution progression: farms Coins, Gems, and EXP, then evolves towers.",
    Type = "Info",
})

evoToggleRef = EvoSection:Toggle({
    Title = "Auto Evo",
    Desc = "Toggle automated evolution progression routines (Premium)",
    Value = State.AutoCurrency.Evo.Enabled,
    Callback = function(val: boolean)
        State.AutoCurrency.Evo.Enabled = val
        if Settings then Settings:Set("AutoEvoEnabled", val) end
        Globals.AutoEvo = val
        refreshCurrencyBox()
        StatsGrid:UpdateItem(5, val and "ACTIVE" or "OFF", val and "Farming evolution" or "Standing by")
        Logger:Info("Auto Evo: " .. (val and "ACTIVE" or "OFF"))
    end,
})

evoTargetDropdownRef = EvoSection:Dropdown({
    Title = "Target Evo",
    Desc = "Select the target evolution tower (Default: All)",
    List = { "All", "Scout", "Shotgunner", "Crook Boss", "Minigunner" },
    Value = State.AutoCurrency.Evo.Target or "All",
    Callback = function(choice: string)
        if not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Please activate key at product key",
                Duration = 3.5,
            })
            Logger:Warn("Auto Evo: 'Target Evo' requires Premium.")
            task.spawn(function()
                if evoTargetDropdownRef and type(evoTargetDropdownRef.SetValue) == "function" then
                    evoTargetDropdownRef:SetValue("All")
                end
            end)
            return
        end
        State.AutoCurrency.Evo.Target = choice
        if Settings then Settings:Set("TargetEvo", choice) end
        Globals.TargetEvo = choice
        refreshCurrencyBox()
        Logger:Info("Auto Evo: Target set to " .. choice)
    end,
})

evoStratDropdownRef = EvoSection:Dropdown({
    Title = "Win / Lose Strategy",
    Desc = "Select outcome preference for Auto Evo (Default: Lose)",
    List = { "Lose", "Win" },
    Value = State.AutoCurrency.Evo.Strategy or "Lose",
    Callback = function(choice: string)
        if not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Please activate key at product key",
                Duration = 3.5,
            })
            Logger:Warn("Auto Evo: 'Win / Lose Strategy' requires Premium.")
            task.spawn(function()
                if evoStratDropdownRef and type(evoStratDropdownRef.SetValue) == "function" then
                    evoStratDropdownRef:SetValue("Lose")
                end
            end)
            return
        end
        State.AutoCurrency.Evo.Strategy = choice
        if Settings then Settings:Set("EvoStrat", choice) end
        Globals.EvoStrat = choice
        refreshCurrencyBox()
        Logger:Info("Auto Evo: Strategy set to " .. choice)
    end,
})

evoStatusLabelRef = EvoSection:Label({
    Title = "Status",
    Desc = "Checking...",
})

evoMissingLabelRef = EvoSection:Label({
    Title = "Missing:",
    Desc = "Checking...",
})

-- Evolution Trackers Section
EvoTrackerSection = CurrencyTab:Section({ Title = "Evolution Trackers" })

evoCoinsGemsLabelRef = EvoTrackerSection:Label({
    Title = "Coins & Gems Tracker",
    Desc = "Waiting for data...",
})

evoTowersLabelRef = EvoTrackerSection:Label({
    Title = "Towers Level",
    Desc = "Waiting for data...",
})

-- Activate initial mode view
showCurrencySection(State.AutoCurrency.SelectedTab or "Auto Coins")

--==============================================================================
-- 6.5 AUTO PLAY (RECORDING) & STRATEGY LIBRARY TABS
--==============================================================================
local recordingFileName = "Strat"
local autoPlayRecordingActive = false
local recordingConsoleRef = nil
local recordingStatusLabel = nil
local spawnedRecorderTowers = {}
local recordedTowerCount = 0
local recorderLastWave = -1
local libraryDropdownRef = nil
local selectedLibraryFile = ""
local executed_actions = {}

local function resolve_tower_index(tower)
    if typeof(tower) ~= "Instance" then
        return nil
    end

    if spawnedRecorderTowers[tower] then
        return spawnedRecorderTowers[tower]
    end

    local current = tower.Parent
    while current do
        if spawnedRecorderTowers[current] then
            return spawnedRecorderTowers[current]
        end
        current = current.Parent
    end

    local activeTDS = TDS or cachedTDSAPI or shared.TDSTable or (getgenv and getgenv().TDS) or _G.TDS
    if activeTDS and type(activeTDS.PlacedTowers) == "table" then
        for idx, t in ipairs(activeTDS.PlacedTowers) do
            if t == tower or (typeof(tower) == "Instance" and (t == tower.Parent or tower:IsDescendantOf(t))) then
                spawnedRecorderTowers[tower] = idx
                return idx
            end
        end
    end

    return nil
end

local function serializeRecordArgument(argumentValue)
    local argumentType = type(argumentValue)
    if argumentType == "string" then
        return string.format("%q", argumentValue)
    elseif argumentType == "number" or argumentType == "boolean" then
        return tostring(argumentValue)
    elseif argumentType == "table" then
        local parts = {}
        for key, val in pairs(argumentValue) do
            local keyType = type(key)
            local formattedKey
            if keyType == "string" then
                formattedKey = string.format("[%q]", key)
            elseif keyType == "number" then
                formattedKey = string.format("[%d]", key)
            else
                formattedKey = string.format("[%s]", tostring(key))
            end
            local formattedValue = type(val) == "string" and string.format("%q", val) or tostring(val)
            table.insert(parts, formattedKey .. " = " .. formattedValue)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif typeof(argumentValue) == "Instance" then
        local idx = resolve_tower_index(argumentValue)
        if idx then return tostring(idx) end
        return "nil"
    else
        return "nil"
    end
end

local function ensureSavedRecordedFolder()
    if typeof(isfolder) == "function" then
        if not isfolder("[SavedRecorded]") then
            if typeof(makefolder) == "function" then
                pcall(makefolder, "[SavedRecorded]")
            end
        end
    elseif typeof(makefolder) == "function" then
        pcall(makefolder, "[SavedRecorded]")
    end
end

local function getSavedRecordedFilesList(): { string }
    ensureSavedRecordedFolder()
    local files = {}
    pcall(function()
        if typeof(listfiles) == "function" then
            local rawFiles = listfiles("[SavedRecorded]")
            if type(rawFiles) == "table" then
                for _, path in ipairs(rawFiles) do
                    local cleanName = tostring(path):match("([^/\\]+)$") or tostring(path)
                    if cleanName ~= "" then
                        table.insert(files, cleanName)
                    end
                end
            end
        end
    end)
    if #files == 0 then
        -- Check if Strat.txt or default files exist
        pcall(function()
            if typeof(isfile) == "function" and isfile("[SavedRecorded]/Strat.txt") then
                table.insert(files, "Strat.txt")
            end
        end)
    end
    if #files == 0 then
        table.insert(files, "Strat.txt")
    end
    table.sort(files)
    return files
end

local function getCleanRecordTargetFilePath(): (string, string)
    ensureSavedRecordedFolder()
    local name = tostring(recordingFileName or "Strat"):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        name = "Strat"
    end
    name = name:gsub('[/\\:*?"<>|]', "_")
    if not name:match("%.txt$") and not name:match("%.lua$") then
        name = name .. ".txt"
    end
    return "[SavedRecorded]/" .. name, name
end

local function appendRecordActionLine(commandStr: string, logDesc: string?)
    if not autoPlayRecordingActive then return end
    table.insert(executed_actions, commandStr)
    pcall(function()
        local savePath = getCleanRecordTargetFilePath()
        local wavePrefix = ""
        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
        local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
        local curWave = gsr and gsr:GetAttribute("Wave") or 0
        if curWave > recorderLastWave then
            recorderLastWave = curWave
            wavePrefix = string.format("\n-- [ Wave %d ] --\n", curWave)
        end
        if typeof(appendfile) == "function" then
            appendfile(savePath, wavePrefix .. commandStr .. "\n")
            appendfile("Strat.txt", wavePrefix .. commandStr .. "\n")
            appendfile("ADS_LastStrat.lua", wavePrefix .. commandStr .. "\n")
        end
    end)
    if logDesc and recordingConsoleRef then
        pcall(function()
            recordingConsoleRef:Log(logDesc)
        end)
    end
end

--==============================================================================
-- 4.5. Tab: User Owned Trials
--==============================================================================
;(function()
local UserOwnedTrialsTab = Window:Tab({
    Title = "User Owned Trials",
    Subtitle = "Completed Trials & Status",
})

UserOwnedTrialsTab:Banner({
    Title = "User Owned Trials & Modifiers",
    Desc = "Live tracking of all TDS Trials you have won, pending challenge maps to complete, and available Timescale tickets.",
    Type = "Info",
})

local function getTrialsMetricData()
    local allList, wonList, notWonList = getOwnedTrialsData()
    local wonCount = 0
    local totalCount = 0
    local trials = nil
    if DataHandler and typeof(DataHandler.GetAllTrialsList) == "function" then
        pcall(function() trials = DataHandler:GetAllTrialsList() end)
    end
    if trials and #trials > 0 then
        totalCount = #trials
        for _, t in ipairs(trials) do
            if t.IsWon then wonCount = wonCount + 1 end
        end
    end
    local timescaleTickets = 0
    if DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" then
        pcall(function() timescaleTickets = DataHandler:GetTimescaleTickets() or 0 end)
    end
    local winRate = totalCount > 0 and math.floor((wonCount / totalCount) * 100) or 0
    return {
        { Title = "TRIALS COMPLETED", Value = string.format("%d / %d", wonCount, totalCount), Sub = string.format("Win Rate: %d%%", winRate), Color = Color3.fromRGB(34, 197, 94) },
        { Title = "PENDING TRIALS", Value = tostring(math.max(0, totalCount - wonCount)), Sub = "Modifiers to unlock", Color = Color3.fromRGB(245, 158, 11) },
        { Title = "TIMESCALE TICKETS", Value = formatCommas(timescaleTickets), Sub = "Boost items held", Color = Color3.fromRGB(59, 130, 246) },
    }
end

trialsMetricGrid = UserOwnedTrialsTab:MetricGrid({
    Cols = 3,
    Items = getTrialsMetricData(),
})

local TrialsSection = UserOwnedTrialsTab:Section({ Title = "Trials Inventory & Breakdown" })

local allTrialsInit, wonTrialsInit, notWonTrialsInit = getOwnedTrialsData()

trialsSelectionBox = TrialsSection:SelectionBox({
    Selections = { "All Trials", "Won Trials", "Not Won Trials" },
    Value = "All Trials",
    Descriptions = {
        ["All Trials"] = "Comprehensive inventory of all 13 TDS Trials with win statuses",
        ["Won Trials"] = "Modifiers and Trials you have successfully completed and unlocked",
        ["Not Won Trials"] = "Trials remaining to conquer with their required challenge maps",
    },
    Checklist = {
        ["All Trials"] = allTrialsInit,
        ["Won Trials"] = wonTrialsInit,
        ["Not Won Trials"] = notWonTrialsInit,
    },
    ButtonTexts = {
        ["All Trials"] = "Scan Trials Inventory",
        ["Won Trials"] = "Refresh Won Modifiers",
        ["Not Won Trials"] = "Scan Pending Challenges",
    },
    Callbacks = {
        ["All Trials"] = function()
            local a, w, nw = getOwnedTrialsData(true)
            if trialsSelectionBox then
                trialsSelectionBox:SetChecklist({
                    ["All Trials"] = a,
                    ["Won Trials"] = w,
                    ["Not Won Trials"] = nw,
                })
            end
            if trialsMetricGrid and typeof(trialsMetricGrid.UpdateItem) == "function" then
                local wonCount = 0
                local totalCount = 0
                local trials = nil
                if DataHandler and typeof(DataHandler.GetAllTrialsList) == "function" then
                    pcall(function() trials = DataHandler:GetAllTrialsList() end)
                end
                if trials and #trials > 0 then
                    totalCount = #trials
                    for _, t in ipairs(trials) do
                        if t.IsWon then wonCount = wonCount + 1 end
                    end
                end
                local timescaleTickets = 0
                if DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" then
                    pcall(function() timescaleTickets = DataHandler:GetTimescaleTickets() or 0 end)
                end
                local winRate = totalCount > 0 and math.floor((wonCount / totalCount) * 100) or 0
                trialsMetricGrid:UpdateItem(1, string.format("%d / %d", wonCount, totalCount), string.format("Win Rate: %d%%", winRate))
                trialsMetricGrid:UpdateItem(2, tostring(math.max(0, totalCount - wonCount)), "Modifiers to unlock")
                trialsMetricGrid:UpdateItem(3, formatCommas(timescaleTickets), "Boost items held")
            end
            Window:Notify({
                Title = "Trials Inventory Refreshed",
                Desc = "Fetched latest trials and completion data from DataHandler.",
                Duration = 2,
            })
        end,
        ["Won Trials"] = function()
            local a, w, nw = getOwnedTrialsData(true)
            if trialsSelectionBox then
                trialsSelectionBox:SetChecklist({
                    ["All Trials"] = a,
                    ["Won Trials"] = w,
                    ["Not Won Trials"] = nw,
                })
            end
            Window:Notify({
                Title = "Won Modifiers Refreshed",
                Desc = "Updated list of completed trials.",
                Duration = 2,
            })
        end,
        ["Not Won Trials"] = function()
            local a, w, nw = getOwnedTrialsData(true)
            if trialsSelectionBox then
                trialsSelectionBox:SetChecklist({
                    ["All Trials"] = a,
                    ["Won Trials"] = w,
                    ["Not Won Trials"] = nw,
                })
            end
            Window:Notify({
                Title = "Pending Challenges Refreshed",
                Desc = "Updated list of trials remaining to be won.",
                Duration = 2,
            })
        end,
    },
})
end)()

-- Tab: Auto Play (Recording)
;(function()
local AutoPlayTab = Window:Tab({
    Title = "Auto Play",
    Subtitle = "Strategy Macro & Recorder",
})

AutoPlayTab:Banner({
    Title = "Strategy Action Recorder",
    Desc = "Record real-time tower placements, upgrades, sells, and abilities into an executable strategy script.",
    Type = "Info",
})

local RecorderConfigSection = AutoPlayTab:Section({ Title = "Recorder Controls" })

RecorderConfigSection:Textbox({
    Title = "Record File Name",
    Desc = "Target file name to save inside [SavedRecorded] (e.g. Strat, FallenLayBy)",
    Placeholder = "Strat",
    Value = recordingFileName,
    ClearTextOnFocus = false,
    Callback = function(txt: string)
        local val = txt:gsub("^%s+", ""):gsub("%s+$", "")
        if val ~= "" then
            recordingFileName = val
        else
            recordingFileName = "Strat"
        end
        Logger:Info("Recorder file name set to: " .. recordingFileName)
    end,
})

recordingStatusLabel = RecorderConfigSection:Label({
    Title = "Recorder Status",
    Desc = "IDLE - Standing by",
})

RecorderConfigSection:Button({
    Title = "START RECORDING",
    Desc = "Begins capturing in-game actions into [SavedRecorded]",
    Image = "Check",
    Callback = function()
        if autoPlayRecordingActive then
            Window:Notify({
                Title = "Already Recording",
                Desc = "Strategy recorder is already running!",
                Duration = 2,
            })
            return
        end

        local filePath, fileName = getCleanRecordTargetFilePath()
        autoPlayRecordingActive = true
        if getgenv then
            getgenv().record_strat = true
            getgenv().__active_record_path = filePath
        end
        if Globals then
            Globals.record_strat = true
            Globals.__active_record_path = filePath
            Globals.__last_recorded_wave = -1
        end
        table.clear(spawnedRecorderTowers)
        table.clear(executed_actions)
        recordedTowerCount = 0
        recorderLastWave = -1
        lastRecordedSkipWave = -1
        hasRecordedReadyThisMatch = false

        if recordingConsoleRef then
            recordingConsoleRef:Clear()
            recordingConsoleRef:Info("=== RECORDER INITIALIZED ===")
            recordingConsoleRef:Info("Target File: " .. filePath)
        end

        -- Determine map, mode, and equipped towers header
        local currentMap = "Unknown"
        local currentMode = "Unknown"
        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
        local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
        if gsr then
            currentMap = gsr:GetAttribute("Map") or "Unknown"
            currentMode = gsr:GetAttribute("Difficulty") or gsr:GetAttribute("Mode") or "Unknown"
        end

        local stateFolder = ReplicatedStorage:FindFirstChild("State")
        if stateFolder then
            pcall(function()
                if stateFolder:FindFirstChild("Map") and stateFolder.Map.Value ~= "" then
                    currentMap = stateFolder.Map.Value
                end
                if stateFolder:FindFirstChild("Difficulty") and stateFolder.Difficulty.Value ~= "" then
                    currentMode = stateFolder.Difficulty.Value
                end
            end)
        end

        local towerList = { "None", "None", "None", "None", "None" }
        if stateReps and LocalPlayer then
            for _, folder in ipairs(stateReps:GetChildren()) do
                if folder.Name == "PlayerReplicator" and folder:GetAttribute("UserId") == LocalPlayer.UserId then
                    local equipped = folder:GetAttribute("EquippedTowers")
                    if type(equipped) == "string" then
                        local cleanedJson = equipped:match("%[.*%]")
                        if cleanedJson and HttpService then
                            pcall(function()
                                local decoded = HttpService:JSONDecode(cleanedJson)
                                if type(decoded) == "table" then
                                    for i = 1, 5 do
                                        towerList[i] = decoded[i] or "None"
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end

        local headerComment = string.format([[-- Generated by Bogus Hub Auto Play Recorder
local TDS = shared.TDSTable or loadstring(game:HttpGet("https://raw.githubusercontent.com/DuxiiT/auto-strat/refs/heads/main/Library.lua"))()

TDS:Loadout("%s", "%s", "%s", "%s", "%s")
TDS:Mode("%s")
TDS:GameInfo("%s", {})

]], towerList[1], towerList[2], towerList[3], towerList[4], towerList[5], currentMode, currentMap)

        pcall(function()
            if typeof(writefile) == "function" then
                writefile(filePath, headerComment)
                writefile("Strat.txt", headerComment)
                writefile("ADS_LastStrat.lua", headerComment)
            end
        end)

        -- Sync existing towers
        local towersFolder = workspace:FindFirstChild("Towers")
        if towersFolder and LocalPlayer then
            for _, tower in ipairs(towersFolder:GetChildren()) do
                local replicator = tower:FindFirstChild("TowerReplicator")
                if replicator and replicator:GetAttribute("OwnerId") == LocalPlayer.UserId then
                    recordedTowerCount = recordedTowerCount + 1
                    spawnedRecorderTowers[tower] = recordedTowerCount
                end
            end
        end

        if typeof(strategyRecordingSetup) == "function" then
            strategyRecordingSetup()
        end

        recordingStatusLabel:SetTitle("Recorder Status")
        recordingStatusLabel:SetDesc("RECORDING ACTIVE -> " .. fileName)

        Window:Notify({
            Title = "Recording Started",
            Desc = "Capturing to [SavedRecorded]/" .. fileName,
            Duration = 3,
        })
        Logger:Success("Auto Play Recorder started -> [SavedRecorded]/" .. fileName)
    end,
})

RecorderConfigSection:Button({
    Title = "STOP RECORDING",
    Desc = "Stops active recording session and finalizes file",
    Image = "Button",
    Callback = function()
        if not autoPlayRecordingActive then
            Window:Notify({
                Title = "Recorder Idle",
                Desc = "No recording session is currently active.",
                Duration = 2,
            })
            return
        end

        autoPlayRecordingActive = false
        if getgenv then
            getgenv().record_strat = false
            getgenv().__active_record_path = nil
        end
        if Globals then
            Globals.record_strat = false
            Globals.__active_record_path = nil
        end

        local filePath, fileName = getCleanRecordTargetFilePath()
        if recordingConsoleRef then
            recordingConsoleRef:Success("Recording stopped successfully.")
            recordingConsoleRef:Info("Strategy file saved: " .. filePath)
        end

        recordingStatusLabel:SetTitle("Recorder Status")
        recordingStatusLabel:SetDesc("IDLE - Strategy saved: " .. fileName)

        if libraryDropdownRef and type(libraryDropdownRef.SetOptions) == "function" then
            pcall(function()
                libraryDropdownRef:SetOptions(getSavedRecordedFilesList())
            end)
        end

        Window:Notify({
            Title = "Recording Saved",
            Desc = "File successfully written to [SavedRecorded]/" .. fileName,
            Duration = 3.5,
        })
        Logger:Success("Auto Play Recorder stopped. Strategy written: " .. fileName)
    end,
})

local RecorderLogSection = AutoPlayTab:Section({ Title = "Live Recording Feed" })

recordingConsoleRef = RecorderLogSection:LogConsole({
    Title = "RECORDER ACTIVITY LOG",
    Height = 150,
    MaxLines = 100,
})

-- Workspace tower listeners for recorder
task.spawn(function()
    local towersFolder = workspace:WaitForChild("Towers", 10) or workspace:FindFirstChild("Towers")
    if towersFolder then
        towersFolder.ChildAdded:Connect(function(tower)
            if not autoPlayRecordingActive then return end
            task.wait(0.1)
            local replicator = tower:WaitForChild("TowerReplicator", 4)
            if not replicator then return end
            if LocalPlayer and replicator:GetAttribute("OwnerId") ~= LocalPlayer.UserId then return end
            if replicator:GetAttribute("Hologram") == true then return end

            recordedTowerCount = recordedTowerCount + 1
            local myIndex = recordedTowerCount
            spawnedRecorderTowers[tower] = myIndex

            local towerName = replicator:GetAttribute("Name") or tower.Name
            local rawPos = replicator:GetAttribute("Position")
            local posX, posY, posZ
            if typeof(rawPos) == "Vector3" then
                posX, posY, posZ = rawPos.X, rawPos.Y, rawPos.Z
            else
                local p = tower:GetPivot().Position
                posX, posY, posZ = p.X, p.Y, p.Z
            end

            local isStackerOn = (State and State.Utilities and State.Utilities.Stacker) or (Globals and (Globals.Stacker or Globals.StackEnabled)) or (getgenv and (getgenv().Stacker or getgenv().StackEnabled))
            local cmd
            if isStackerOn then
                cmd = string.format('TDS:Place("%s", %s, %s, %s, true)', towerName, tostring(posX), tostring(posY), tostring(posZ))
            else
                cmd = string.format('TDS:Place("%s", %s, %s, %s)', towerName, tostring(posX), tostring(posY), tostring(posZ))
            end
            appendRecordActionLine(cmd, string.format("Placed %s (Index: %d)", towerName, myIndex))
        end)

        towersFolder.ChildRemoved:Connect(function(tower)
            if not autoPlayRecordingActive then return end
            local myIndex = spawnedRecorderTowers[tower]
            if myIndex then
                local cmd = string.format("TDS:Sell(%d)", myIndex)
                appendRecordActionLine(cmd, string.format("Sold Tower (Index: %d)", myIndex))
                spawnedRecorderTowers[tower] = nil
            end
        end)
    end
end)

-- =============================================================================
-- Remote Interception & Method Hooking for Strategy Recording
-- Captures: Upgrades, Target changes, Abilities, Options (DJ track/traps), Medic, Skip
-- =============================================================================
local isTdsMethodCalling = false
local lastRecordedSkipWave = -1
local hasRecordedReadyThisMatch = false

local function handleRecordedRemoteCall(remote, method, args, results)
    if not autoPlayRecordingActive or isTdsMethodCalling then
        return
    end

    if method ~= "InvokeServer" and method ~= "FireServer" then
        return
    end

    local a1 = args[1]
    local a2 = args[2]
    local a3 = args[3]
    local a4 = args[4]
    local a5 = args[5]

    -- 1. Upgrades: InvokeServer("Troops", "Upgrade", "Set", { Troop = ..., Path = ... })
    if a1 == "Troops" and a2 == "Upgrade" and a3 == "Set" then
        if type(a4) == "table" then
            local tower = a4.Troop
            local my_index = resolve_tower_index(tower)
            local path = a4.Path or 1

            if my_index and (not results or results[1] == true or results[1] == nil) then
                local replicator = (typeof(tower) == "Instance" and tower:FindFirstChild("TowerReplicator"))
                local tower_name = (replicator and replicator:GetAttribute("Name")) or (typeof(tower) == "Instance" and tower.Name) or ("Tower " .. tostring(my_index))

                local cmd = (path > 1) and string.format("TDS:Upgrade(%d, %d)", my_index, path) or string.format("TDS:Upgrade(%d)", my_index)
                appendRecordActionLine(cmd, string.format("Upgraded %s (Index: %d)", tower_name, my_index))
                return
            end
        end
    end

    -- 2. Target: InvokeServer("Troops", "Target", "Set", { Troop = ..., Target = ... })
    if a1 == "Troops" and a2 == "Target" and a3 == "Set" then
        if type(a4) == "table" then
            local my_index = resolve_tower_index(a4.Troop)
            local target_type = a4.Target
            if my_index and type(target_type) == "string" then
                local cmd = string.format("TDS:SetTarget(%d, %q)", my_index, target_type)
                appendRecordActionLine(cmd, string.format("Target: Tower %d -> %s", my_index, target_type))
                return
            end
        end
    end

    -- 3. Options (DJ track, Trapper mode, etc.): InvokeServer("Troops", "Option", "Set", { Troop = ..., Name = ..., Value = ... })
    if a1 == "Troops" and a2 == "Option" and a3 == "Set" then
        if type(a4) == "table" then
            local idx = resolve_tower_index(a4.Troop)
            local opt_name = a4.Name or a4.Option or a4.Key or a4.Track
            local opt_val = a4.Value or a4.Val
            if idx and type(opt_name) == "string" then
                local valStr = serializeRecordArgument(opt_val)
                local cmd = string.format("TDS:SetOption(%d, %q, %s)", idx, opt_name, valStr)
                appendRecordActionLine(cmd, string.format("Option: Tower %d %s = %s", idx, opt_name, tostring(opt_val)))
                return
            end
        end
    end

    -- 4. Abilities: InvokeServer("Troops", "Abilities", "Activate", { Troop = ..., Name = ..., Data = ... })
    if a1 == "Troops" and a2 == "Abilities" and a3 == "Activate" then
        if type(a4) == "table" then
            local idx = resolve_tower_index(a4.Troop)
            local name = a4.Name
            if idx and type(name) == "string" then
                local data = a4.Data
                local cmd
                if data == nil or (type(data) == "table" and next(data) == nil) then
                    cmd = string.format("TDS:Ability(%d, %q)", idx, name)
                else
                    cmd = string.format("TDS:Ability(%d, %q, %s)", idx, name, serializeRecordArgument(data))
                end
                appendRecordActionLine(cmd, string.format("Ability: %s (Index: %d)", name, idx))
                return
            end
        end
    end

    -- 5. Medic: InvokeServer("Troops", "TowerServerEvent", "ToggleSelectedTower", tower1, tower2)
    if a1 == "Troops" and a2 == "TowerServerEvent" and a3 == "ToggleSelectedTower" then
        local idx = resolve_tower_index(args[4])
        local target_idx = resolve_tower_index(args[5])
        if idx and target_idx then
            local cmd = string.format("TDS:MedicSelect(%d, %d)", idx, target_idx)
            appendRecordActionLine(cmd, string.format("Medic: %d -> %d", idx, target_idx))
            return
        end
    end

    -- 6. Skip & Ready: InvokeServer("Voting", "Skip") - Debounced: exactly once per wave!
    if a1 == "Voting" and a2 == "Skip" then
        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
        local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
        local curWave = gsr and gsr:GetAttribute("Wave") or 0
        if curWave == 0 then
            if not hasRecordedReadyThisMatch then
                hasRecordedReadyThisMatch = true
                appendRecordActionLine("TDS:Ready()", "Readied up for match")
            end
        else
            if lastRecordedSkipWave ~= curWave then
                lastRecordedSkipWave = curWave
                appendRecordActionLine(string.format("TDS:VoteSkip(%d)", curWave), "Voted to skip wave " .. curWave)
            end
        end
        return
    end
end

-- Namecall metamethod hook
if type(hookmetamethod) == "function" and not (getgenv and getgenv().__tds_recorder_namecall_hooked) then
    if getgenv then getgenv().__tds_recorder_namecall_hooked = true end
    local originalNamecall
    originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or nil
        local args = {...}
        local results = table.pack(originalNamecall(self, ...))
        if autoPlayRecordingActive and (method == "InvokeServer" or method == "FireServer") then
            task.spawn(function()
                local set_id = setthreadidentity or setidentity or setthreadcontext
                if set_id then set_id(7) end
                pcall(handleRecordedRemoteCall, self, method, args, results)
            end)
        end
        return table.unpack(results, 1, results.n)
    end)
end

-- Fallback instance-level InvokeServer hook on RemoteFunction
task.spawn(function()
    pcall(function()
        if type(hookfunction) == "function" and not (getgenv and getgenv().__tds_recorder_rf_hooked) then
            local testRf = Instance.new("RemoteFunction")
            local rawInvoke = testRf.InvokeServer
            testRf:Destroy()
            if type(rawInvoke) == "function" then
                if getgenv then getgenv().__tds_recorder_rf_hooked = true end
                local origRfInvoke
                origRfInvoke = hookfunction(rawInvoke, function(self, ...)
                    local args = {...}
                    local results = table.pack(origRfInvoke(self, ...))
                    if autoPlayRecordingActive then
                        task.spawn(function()
                            pcall(handleRecordedRemoteCall, self, "InvokeServer", args, results)
                        end)
                    end
                    return table.unpack(results, 1, results.n)
                end)
            end
        end
    end)
end)

-- TDS Table Method Hook (Direct API calls: Mode, Place, Upgrade, SetTarget, etc.)
local hookedTDSMethods = {}
local function strategyRecordingSetup(targetTDS)
    local activeTDS = targetTDS or TDS or cachedTDSAPI or shared.TDSTable or (getgenv and getgenv().TDS) or _G.TDS
    if not activeTDS or type(activeTDS) ~= "table" then return end

    local recordableMethods = {
        "Mode", "Place", "Upgrade", "SetTarget", "Sell", "SellAll", "Ability", "SetOption", "MedicSelect", "MedicChain", "Ready", "VoteSkip", "WaitForWave", "UnlockTimeScale", "TimeScale"
    }

    for _, methodName in ipairs(recordableMethods) do
        if typeof(activeTDS[methodName]) == "function" and not hookedTDSMethods[methodName] then
            local origMethod = activeTDS[methodName]
            hookedTDSMethods[methodName] = origMethod

            activeTDS[methodName] = function(self, ...)
                if autoPlayRecordingActive and not (Globals and Globals.tdsReplaying) then
                    local args = {...}
                    local stringified = {}
                    for _, arg in ipairs(args) do
                        table.insert(stringified, serializeRecordArgument(arg))
                    end

                    if methodName == "Mode" then
                        table.clear(executed_actions)
                    elseif methodName == "VoteSkip" then
                        local targetWave = tonumber(args[1])
                        if not targetWave then
                            local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                            local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                            targetWave = gsr and gsr:GetAttribute("Wave") or 0
                        end
                        if lastRecordedSkipWave ~= targetWave then
                            lastRecordedSkipWave = targetWave
                            local actionString = string.format("TDS:VoteSkip(%d)", targetWave)
                            appendRecordActionLine(actionString, string.format("TDS:VoteSkip(%d)", targetWave))
                        end
                    elseif methodName == "Ready" then
                        if not hasRecordedReadyThisMatch then
                            hasRecordedReadyThisMatch = true
                            appendRecordActionLine("TDS:Ready()", "TDS:Ready()")
                        end
                    else
                        local actionString = string.format("TDS:%s(%s)", methodName, table.concat(stringified, ", "))
                        appendRecordActionLine(actionString, string.format("TDS:%s(%s)", methodName, table.concat(stringified, ", ")))
                    end
                end

                isTdsMethodCalling = true
                local res = table.pack(pcall(origMethod, self, ...))
                isTdsMethodCalling = false

                if res[1] == true then
                    return table.unpack(res, 2, res.n)
                else
                    error(res[2])
                end
            end
        end
    end
end

strategyRecordingSetup()
end)()

-- Tab: Library
;(function()
local LibraryTab = Window:Tab({
    Title = "Library",
    Subtitle = "Recorded Strategy Vault",
})

LibraryTab:Banner({
    Title = "Strategy Library Vault",
    Desc = "Manage, view, and export strategies recorded into your [SavedRecorded] directory.",
    Type = "Info",
})

local LibrarySection = LibraryTab:Section({ Title = "Recorded Strategies" })

local function getSavedRecordedStrategyItems()
    ensureSavedRecordedFolder()
    local items = {}
    local files = {}
    pcall(function()
        if typeof(listfiles) == "function" then
            local rawFiles = listfiles("[SavedRecorded]")
            if type(rawFiles) == "table" then
                for _, path in ipairs(rawFiles) do
                    local cleanName = tostring(path):match("([^/\\]+)$") or tostring(path)
                    if cleanName ~= "" and (cleanName:sub(-4) == ".txt" or cleanName:sub(-4) == ".lua") then
                        table.insert(files, { Name = cleanName, Path = path })
                    end
                end
            end
        end
    end)

    if #files == 0 then
        pcall(function()
            if typeof(isfile) == "function" and isfile("[SavedRecorded]/Strat.txt") then
                table.insert(files, { Name = "Strat.txt", Path = "[SavedRecorded]/Strat.txt" })
            elseif typeof(isfile) == "function" and isfile("Strat.txt") then
                table.insert(files, { Name = "Strat.txt", Path = "Strat.txt" })
            end
        end)
    end

    for _, f in ipairs(files) do
        local mode = "?"
        local map = "?"
        local isPremium = false
        pcall(function()
            if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(f.Path) then
                local content = readfile(f.Path)
                if content and #content > 0 then
                    local m = content:match('["\']?Mode["\']?%s*[:=]%s*["\']([^"\']+)["\']')
                        or content:match('TDS:Mode%(%s*["\']([^"\']+)["\']')
                        or content:match('["\']?Difficulty["\']?%s*[:=]%s*["\']([^"\']+)["\']')
                        or content:match('%-%-%s*[Mm]ode%s*:%s*([%w%s]+)')
                    if m and m ~= "" then
                        mode = m:gsub("^%s+", ""):gsub("%s+$", "")
                    end

                    local mp = content:match('TDS:GameInfo%(%s*["\']([^"\']+)["\']')
                        or content:match('TDS:Map%(%s*["\']([^"\']+)["\']')
                        or content:match('["\']?Map["\']?%s*[:=]%s*["\']([^"\']+)["\']')
                        or content:match('%-%-%s*[Mm]ap%s*:%s*([%w%s]+)')
                    if mp and mp ~= "" then
                        map = mp:gsub("^%s+", ""):gsub("%s+$", "")
                    end

                    if content:match('TDS:Mode%s*%(%s*["\'][^"\']+["\']%s*,%s*true')
                        or content:match('TDS:GameInfo%s*%(%s*["\'][^"\']+["\']%s*,%s*true')
                        or content:match('TDS:GameInfo%s*%(%s*["\'][^"\']+["\']%s*,%s*[^,%)]*,%s*true')
                        or content:match('TDS:Map%s*%(%s*["\'][^"\']+["\']%s*,%s*true')
                        or content:match('TDS:Loadout%s*%([^%)]*,%s*true')
                        or content:match('["\']?Mode["\']?%s*[:=]%s*["\'][^"\']+["\']%s*,%s*true')
                        or content:match('["\']?Premium["\']?%s*[:=]%s*true')
                        or content:match('[Pp]remium%s*=%s*true')
                        or content:match('%-%-%s*[Pp]remium') then
                        isPremium = true
                    end
                end
            end
        end)
        table.insert(items, {
            Name = f.Name,
            Mode = mode,
            Map = map,
            IsPremium = isPremium,
            Path = f.Path,
        })
    end

    if #items == 0 then
        table.insert(items, {
            Name = "example_strat.txt",
            Mode = "?",
            Path = "[SavedRecorded]/example_strat.txt",
        })
    end

    return items
end

local stratItemsInit = getSavedRecordedStrategyItems()
local savedAutoStrat = (State.StrategyManager and (State.StrategyManager.selectedStrat or State.StrategyManager.SelectedStrat or State.StrategyManager.SelectedAutoStrat))
if (not savedAutoStrat or savedAutoStrat == "") and Settings then
    savedAutoStrat = Settings:Get("selectedStrat", Settings:Get("SelectedStrat", Settings:Get("SelectedAutoStrat", "")))
end
if (not savedAutoStrat or savedAutoStrat == "") and getgenv and getgenv().selectedStrat and getgenv().selectedStrat ~= "" then
    savedAutoStrat = getgenv().selectedStrat
end
if not savedAutoStrat or savedAutoStrat == "" then
    savedAutoStrat = (stratItemsInit[1] and stratItemsInit[1].Name) or "Strat.txt"
end

selectedStrat = savedAutoStrat
selectedLibraryFile = savedAutoStrat
if getgenv then getgenv().selectedStrat = savedAutoStrat end
_G.selectedStrat = savedAutoStrat
if State.StrategyManager then
    State.StrategyManager.selectedStrat = savedAutoStrat
    State.StrategyManager.SelectedStrat = savedAutoStrat
    State.StrategyManager.SelectedAutoStrat = savedAutoStrat
end
Globals.selectedStrat = savedAutoStrat
Globals.SelectedStrat = savedAutoStrat
Globals.SelectedAutoStrat = savedAutoStrat

local currentRunningStratThread = nil
local currentRunningStratName = nil
local hasAutoExecutedThisMatch = false

local function executeStrategyFile(stratName, optPath, isAuto)
    if not stratName or stratName == "" then return false end

    local possiblePaths = {}
    if optPath and type(optPath) == "string" and optPath ~= "" then
        table.insert(possiblePaths, optPath)
    end

    -- Look up registered path from saved strategy list if available
    pcall(function()
        local recordedItems = getSavedRecordedStrategyItems()
        for _, it in ipairs(recordedItems) do
            if it.Name == stratName and it.Path then
                table.insert(possiblePaths, it.Path)
                break
            end
        end
    end)

    table.insert(possiblePaths, "[SavedRecorded]/" .. stratName)
    table.insert(possiblePaths, "[SavedRecorded]\\" .. stratName)
    table.insert(possiblePaths, stratName)
    table.insert(possiblePaths, "workspace/[SavedRecorded]/" .. stratName)
    table.insert(possiblePaths, "workspace/[SavedRecorded]\\" .. stratName)

    local content = nil
    for _, p in ipairs(possiblePaths) do
        if p and typeof(isfile) == "function" and isfile(p) and typeof(readfile) == "function" then
            local c = nil
            pcall(function() c = readfile(p) end)
            if c and #c > 0 then
                content = c
                break
            end
        end
    end

    if not content or content == "" then
        Window:Notify({
            Title = isAuto and "Auto-Execute Error" or "Execute Error",
            Desc = "Strategy file is empty or missing: " .. tostring(stratName),
            Duration = 3,
            Type = "error",
        })
        Logger:Error("Strategy file missing or empty: " .. tostring(stratName))
        return false
    end

    -- Premium Strategy Lockout Check
    local isStratPremium = false
    local recordedItems = getSavedRecordedStrategyItems()
    for _, it in ipairs(recordedItems) do
        if it.Name == stratName and it.IsPremium then
            isStratPremium = true
            break
        end
    end
    if not isStratPremium and content then
        if content:match('TDS:Mode%s*%(%s*["\'][^"\']+["\']%s*,%s*true')
            or content:match('TDS:GameInfo%s*%(%s*["\'][^"\']+["\']%s*,%s*true')
            or content:match('TDS:GameInfo%s*%(%s*["\'][^"\']+["\']%s*,%s*[^,%)]*,%s*true')
            or content:match('TDS:Map%s*%(%s*["\'][^"\']+["\']%s*,%s*true')
            or content:match('TDS:Loadout%s*%([^%)]*,%s*true')
            or content:match('["\']?Mode["\']?%s*[:=]%s*["\'][^"\']+["\']%s*,%s*true')
            or content:match('["\']?Premium["\']?%s*[:=]%s*true')
            or content:match('[Pp]remium%s*=%s*true')
            or content:match('%-%-%s*[Pp]remium') then
            isStratPremium = true
        end
    end

    if isStratPremium and not checkIsPremium() then
        Window:Notify({
            Title = "Premium Plan Required",
            Desc = "THis strat required premium! turn off the auto exec and never que them also",
            Duration = 5,
            Type = "error",
        })
        Logger:Warn("Execution blocked: Strategy requires Premium plan! Disabling Auto Execute.")
        if State.StrategyManager then
            State.StrategyManager.AutoExecuteStrat = false
        end
        Globals.AutoExecuteStrat = false
        if Settings then
            Settings:Set("AutoExecuteStrat", false)
        end
        if stratManagerRef and typeof(stratManagerRef.SetAutoExecute) == "function" then
            stratManagerRef:SetAutoExecute(false)
        end
        return false
    end

    -- Guard against duplicate launches of the SAME active running strategy
    if currentRunningStratThread and currentRunningStratName == stratName and coroutine.status(currentRunningStratThread) ~= "dead" then
        Logger:Info("[Auto-Exec] Strategy '" .. tostring(stratName) .. "' is already running. Skipping duplicate launch.")
        return true
    end

    if currentRunningStratThread then
        pcall(task.cancel, currentRunningStratThread)
        currentRunningStratThread = nil
        Logger:Info("Terminated previously running strategy (" .. tostring(currentRunningStratName) .. ") to switch execution.")
    end

    local activeTDS = TDS or cachedTDSAPI or shared.TDSTable or (getgenv and getgenv().TDS) or _G.TDS
    if not activeTDS and typeof(loadTDSAPI) == "function" then
        activeTDS = loadTDSAPI()
    end
    if activeTDS then
        if getgenv then getgenv().TDS = activeTDS end
        _G.TDS = activeTDS
        shared.TDSTable = activeTDS
        if AutoGoldModule then
            activeTDS.IsMapAvailable = AutoGoldModule.IsMapAvailable
            activeTDS.SelectMapOverride = AutoGoldModule.SelectMapOverride
            activeTDS.CastMapVote = AutoGoldModule.CastMapVote
            activeTDS.TriggerVeto = AutoGoldModule.TriggerVeto
        end
        if SmartTeleportToLobby then
            activeTDS.SmartTeleportToLobby = SmartTeleportToLobby
            if shared then shared.SmartTeleportToLobby = SmartTeleportToLobby end
            if Globals then Globals.SmartTeleportToLobby = SmartTeleportToLobby end
        end
        if typeof(activeTDS.RemoveIndex) == "function" then
            pcall(function() activeTDS:RemoveIndex() end)
        end
        if typeof(activeTDS.ResetAllStates) == "function" then
            pcall(function() activeTDS:ResetAllStates() end)
        end
    end

    currentRunningStratName = stratName
    hasAutoExecutedThisMatch = true

    Window:Notify({
        Title = isAuto and "Auto-Executing Strategy" or "Executing Strategy",
        Desc = (isAuto and "[Auto] " or "") .. "Running " .. tostring(stratName) .. "...",
        Duration = 3,
        Type = "info",
    })
    Logger:Info((isAuto and "[Auto-Exec]" or "[Manual-Exec]") .. " Launching strategy: " .. tostring(stratName))

    currentRunningStratThread = task.spawn(function()
        local func, pErr = loadstring(content, stratName)
        if func then
            local env = getfenv(func)
            if activeTDS then
                env.TDS = activeTDS
            end
            if not env.IsMapAvailable and AutoGoldModule and AutoGoldModule.IsMapAvailable then
                env.IsMapAvailable = AutoGoldModule.IsMapAvailable
            end
            if not env.SelectMapOverride and AutoGoldModule and AutoGoldModule.SelectMapOverride then
                env.SelectMapOverride = AutoGoldModule.SelectMapOverride
            end
            if not env.CastMapVote and AutoGoldModule and AutoGoldModule.CastMapVote then
                env.CastMapVote = AutoGoldModule.CastMapVote
            end
            if not env.LobbyReadyUp and AutoGoldModule and AutoGoldModule.LobbyReadyUp then
                env.LobbyReadyUp = AutoGoldModule.LobbyReadyUp
            end
            setfenv(func, env)

            local ok, rErr = pcall(func)
            currentRunningStratThread = nil -- Clean up thread reference to free memory

            if not ok then
                Logger:Error("Strategy execution error: " .. tostring(rErr))
                Window:Notify({
                    Title = "Strategy Error",
                    Desc = tostring(rErr),
                    Duration = 4,
                    Type = "error",
                })
            else
                Logger:Success("Strategy completed successfully: " .. tostring(stratName))
                Window:Notify({
                    Title = "Strategy Completed",
                    Desc = tostring(stratName) .. " executed successfully.",
                    Duration = 3,
                    Type = "success",
                })
            end
        else
            currentRunningStratThread = nil
            Logger:Error("Strategy parse error: " .. tostring(pErr))
            Window:Notify({
                Title = "Strategy Parse Error",
                Desc = tostring(pErr),
                Duration = 4,
                Type = "error",
            })
        end
    end)

    return true
end

local stratManagerRef = nil
stratManagerRef = LibrarySection:StrategyManager({
    Title = "Strategy Manager",
    Height = 180,
    Strats = stratItemsInit,
    Selected = selectedLibraryFile,
    AutoExecute = State.StrategyManager and State.StrategyManager.AutoExecuteStrat or false,
    AutoExecuteTitle = "Auto Execute on Run",
    ExecuteTitle = "▶ EXECUTE",
    OnSelect = function(item, index)
        selectedStrat = item.Name
        selectedLibraryFile = item.Name
        if getgenv then getgenv().selectedStrat = item.Name end
        _G.selectedStrat = item.Name

        if State.StrategyManager then
            State.StrategyManager.selectedStrat = item.Name
            State.StrategyManager.SelectedStrat = item.Name
            State.StrategyManager.SelectedAutoStrat = item.Name
        end
        Globals.selectedStrat = item.Name
        Globals.SelectedStrat = item.Name
        Globals.SelectedAutoStrat = item.Name

        if Settings then
            Settings:Set("selectedStrat", item.Name, true)
            Settings:Set("SelectedStrat", item.Name, true)
            Settings:Set("SelectedAutoStrat", item.Name, true)
            if typeof(Settings.Save) == "function" then
                Settings:Save()
            end
        end
        if typeof(SaveSettings) == "function" then
            SaveSettings(true)
        end
        Logger:Info("Selected strategy: " .. item.Name .. " [Mode: " .. tostring(item.Mode or "?") .. "]")

        if item.IsPremium and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "THis strat required premium! turn off the auto exec and never que them also",
                Duration = 5,
                Type = "error",
            })
            Logger:Warn("Selected strat (" .. item.Name .. ") requires Premium! Disabling Auto Execute.")
            if State.StrategyManager then
                State.StrategyManager.AutoExecuteStrat = false
            end
            Globals.AutoExecuteStrat = false
            if Settings then
                Settings:Set("AutoExecuteStrat", false)
            end
            if stratManagerRef and typeof(stratManagerRef.SetAutoExecute) == "function" then
                stratManagerRef:SetAutoExecute(false)
            end
            return
        end

        -- Always execute if auto-exec is turned on
        local isAuto = (State.StrategyManager and State.StrategyManager.AutoExecuteStrat == true)
            or (Globals and Globals.AutoExecuteStrat == true)
        if isAuto then
            Logger:Info("Auto Execute is ON: Running newly selected strategy -> " .. item.Name)
            executeStrategyFile(item.Name, item.Path, true)
        end
    end,
    OnDelete = function(item, index)
        local path = item.Path or ("[SavedRecorded]/" .. item.Name)
        pcall(function()
            if typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(path) then
                delfile(path)
            end
        end)
        if stratManagerRef then
            stratManagerRef:RemoveStrat(item.Name)
        end
        Window:Notify({
            Title = "Strategy Deleted",
            Desc = "Successfully removed " .. item.Name,
            Duration = 2.5,
            Type = "warning",
        })
        Logger:Warn("Deleted strategy file: " .. item.Name)
    end,
    OnExtract = function(item, index)
        local path = item.Path or ("[SavedRecorded]/" .. item.Name)
        local content = nil
        pcall(function()
            if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(path) then
                content = readfile(path)
            end
        end)
        if not content or content == "" then
            Window:Notify({
                Title = "Extract Failed",
                Desc = "File is empty or cannot be read: " .. item.Name,
                Duration = 2.5,
                Type = "error",
            })
            return
        end
        local copied = false
        pcall(function()
            if typeof(setclipboard) == "function" then
                setclipboard(content)
                copied = true
            elseif typeof(toclipboard) == "function" then
                toclipboard(content)
                copied = true
            end
        end)
        if copied then
            Window:Notify({
                Title = "Strategy Extracted!",
                Desc = "Copied " .. item.Name .. " (" .. #content .. " chars) to clipboard.",
                Duration = 3,
                Type = "success",
            })
            Logger:Success("Extracted strategy to clipboard: " .. item.Name)
        else
            Window:Notify({
                Title = "Clipboard Error",
                Desc = "Executor does not support setclipboard.",
                Duration = 2.5,
            })
        end
    end,
    OnExecute = function(item, index)
        executeStrategyFile(item.Name, item.Path, false)
    end,
    OnAutoExecute = function(val: boolean)
        local target = selectedStrat
        if not target or target == "" then target = selectedLibraryFile end
        if (not target or target == "") and State.StrategyManager then
            target = State.StrategyManager.selectedStrat or State.StrategyManager.SelectedAutoStrat
        end

        if val and not checkIsPremium() then
            local chkStrat = target or selectedStrat
            local recordedItems = getSavedRecordedStrategyItems()
            for _, it in ipairs(recordedItems) do
                if it.Name == chkStrat and it.IsPremium then
                    Window:Notify({
                        Title = "Premium Plan Required",
                        Desc = "THis strat required premium! turn off the auto exec and never que them also",
                        Duration = 5,
                        Type = "error",
                    })
                    Logger:Warn("Cannot enable Auto Execute: Selected strategy requires Premium!")
                    task.spawn(function()
                        if stratManagerRef and typeof(stratManagerRef.SetAutoExecute) == "function" then
                            stratManagerRef:SetAutoExecute(false)
                        end
                    end)
                    return
                end
            end
        end

        if State.StrategyManager then
            State.StrategyManager.AutoExecuteStrat = val
            if target and target ~= "" then
                State.StrategyManager.selectedStrat = target
                State.StrategyManager.SelectedStrat = target
                State.StrategyManager.SelectedAutoStrat = target
            end
        end
        Globals.AutoExecuteStrat = val
        if target and target ~= "" then
            selectedStrat = target
            Globals.selectedStrat = target
            Globals.SelectedStrat = target
            Globals.SelectedAutoStrat = target
            if getgenv then getgenv().selectedStrat = target end
            _G.selectedStrat = target
        end

        if Settings then
            Settings:Set("AutoExecuteStrat", val, true)
            if target and target ~= "" then
                Settings:Set("selectedStrat", target, true)
                Settings:Set("SelectedStrat", target, true)
                Settings:Set("SelectedAutoStrat", target, true)
            end
            if typeof(Settings.Save) == "function" then
                Settings:Save()
            end
        end
        if typeof(SaveSettings) == "function" then
            SaveSettings(true)
        end
        Logger:Info("Auto Execute Strat on Run: " .. (val and "ENABLED" or "DISABLED"))
        Window:Notify({
            Title = "Auto Execute Strat",
            Desc = val and ("Strategy will run automatically on match start (" .. (target or "selected") .. ")")
                or "Auto strategy execution disabled.",
            Duration = 2.5,
            Type = val and "success" or "info",
        })
        if val and target and target ~= "" then
            executeStrategyFile(target, nil, true)
        end
    end,
})

-- Auto-execute immediately upon running the script if AutoExecute is turned on!
task.spawn(function()
    task.wait(0.3)
    local isAuto = (State.StrategyManager and State.StrategyManager.AutoExecuteStrat == true)
        or (Globals and Globals.AutoExecuteStrat == true)
    local target = selectedStrat
    if not target or target == "" then target = selectedLibraryFile end
    if (not target or target == "") and State.StrategyManager then
        target = State.StrategyManager.selectedStrat or State.StrategyManager.SelectedStrat or State.StrategyManager.SelectedAutoStrat
    end
    if (not target or target == "") and getgenv then
        target = getgenv().selectedStrat
    end

    if isAuto and target and target ~= "" then
        Logger:Info("[Auto Execute on Run] Executing selected strategy immediately on script run: " .. tostring(target))
        executeStrategyFile(target, nil, true)
    end
end)

LibrarySection:Button({
    Title = "Refresh Strategy Library",
    Desc = "Rescans [SavedRecorded] directory and refreshes all strategy files & modes",
    Image = "Button",
    Callback = function()
        local updated = getSavedRecordedStrategyItems()
        if stratManagerRef then
            stratManagerRef:SetStrats(updated)
        end
        Window:Notify({
            Title = "Library Refreshed",
            Desc = string.format("Found %d recorded strategy file(s).", #updated),
            Duration = 2,
        })
        Logger:Info("Library scanned: " .. #updated .. " strategy files available.")
    end,
})
end)()

--==============================================================================
-- 7. UTILITIES TAB
--==============================================================================
local isStackerActive = nil
local applyStackerHooks = nil
local UtilitiesTab = nil
local StartAutoReady = nil
local StartAutoSkip = nil
local StartAutoRejoin = nil
local StartInMatchTimescale = nil
local StartAutoReloadGatling = nil
local StartAutoPickups = nil
local ApplyInMatchTimescaleOnce = nil
local extractPrivateServerCode = nil

UtilitiesTab = Window:Tab({
    Title = "Utilities",
    Subtitle = "Addons & Extended Utilities",
})

do
-- =============================================================================
-- Stacker & Collision Check Module (Tower Placement Stacker + Hacker Clone + Y+20)
-- =============================================================================
local stackerInitialized = false
local origCheckTowerCollisions = nil
local origTroopsInvokeServer = nil
local groundRaycastParams = nil

isStackerActive = function(): boolean
    if not checkIsPremium() then
        return false
    end
    return (State and State.Utilities and State.Utilities.Stacker == true)
        or (Globals and (Globals.Stacker == true or Globals.StackEnabled == true))
        or (getgenv and (getgenv().Stacker == true or getgenv().StackEnabled == true))
end

local function getGroundHit(pos: Vector3)
    if not groundRaycastParams then
        groundRaycastParams = RaycastParams.new()
        groundRaycastParams.FilterType = Enum.RaycastFilterType.Include
    end
    local instances = {}
    if workspace:FindFirstChild("Ground") then table.insert(instances, workspace.Ground) end
    if workspace:FindFirstChild("Cliff") then table.insert(instances, workspace.Cliff) end
    groundRaycastParams.FilterDescendantsInstances = instances

    local hit = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), groundRaycastParams)
    if not hit then
        local fallbackParams = RaycastParams.new()
        fallbackParams.FilterType = Enum.RaycastFilterType.Exclude
        local excludeList = {}
        if workspace:FindFirstChild("Towers") then table.insert(excludeList, workspace.Towers) end
        if LocalPlayer and LocalPlayer.Character then table.insert(excludeList, LocalPlayer.Character) end
        fallbackParams.FilterDescendantsInstances = excludeList
        hit = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), fallbackParams)
    end
    return hit
end

applyStackerHooks = function()
    if stackerInitialized then return end
    if game.PlaceId == LOBBY_PLACE_ID then return end

    task.spawn(function()
        local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
        local clientFolder = ReplicatedStorage:WaitForChild("Client", 10)
        if not sharedFolder or not clientFolder then return end

        local SharedGameFunctions = nil
        pcall(function()
            SharedGameFunctions = require(sharedFolder:WaitForChild("Modules", 5):WaitForChild("SharedGameFunctions", 5))
        end)

        local Network = nil
        pcall(function()
            Network = require(sharedFolder:WaitForChild("Modules", 5):WaitForChild("Network", 5))
        end)

        local NewPlacementController = nil
        pcall(function()
            NewPlacementController = require(clientFolder:WaitForChild("Controllers", 5):WaitForChild("Game", 5):WaitForChild("NewPlacementController", 5))
        end)

        local PathPlacementCursorController = nil
        pcall(function()
            PathPlacementCursorController = require(clientFolder:WaitForChild("Controllers", 5):WaitForChild("Game", 5):WaitForChild("PathPlacementCursorController", 5))
        end)

        -- 1. Hook CheckTowerCollisions (Tower Collision Bypass & Hacker Collision)
        if SharedGameFunctions and type(SharedGameFunctions.CheckTowerCollisions) == "function" and not origCheckTowerCollisions then
            origCheckTowerCollisions = SharedGameFunctions.CheckTowerCollisions
            SharedGameFunctions.CheckTowerCollisions = function(towerName, targetPos, team, p4, ignoredTower, ...)
                if not isStackerActive() or not targetPos then
                    return origCheckTowerCollisions(towerName, targetPos, team, p4, ignoredTower, ...)
                end

                local isPlacingActive = (NewPlacementController and NewPlacementController.Active)
                    or (PathPlacementCursorController and PathPlacementCursorController.active)

                if not isPlacingActive then
                    return origCheckTowerCollisions(towerName, targetPos, team, p4, ignoredTower, ...)
                end

                local ok, res = origCheckTowerCollisions(towerName, targetPos, team, p4, ignoredTower, ...)
                if ok then
                    return true, res
                end

                -- Stacker Collision Bypass (Allows hovering & placing on top of existing towers)
                local isTowerCollision = (type(res) == "table" and res.Position ~= nil)
                if isTowerCollision then
                    local gHit = getGroundHit(targetPos)
                    if gHit then
                        if PathPlacementCursorController and PathPlacementCursorController.active then
                            PathPlacementCursorController.CantPlace = false
                        end
                        return true, gHit
                    end
                end

                -- Hacker Clone cursor support
                if PathPlacementCursorController and PathPlacementCursorController.active then
                    PathPlacementCursorController.CantPlace = false
                end

                return origCheckTowerCollisions(towerName, targetPos, team, p4, ignoredTower, ...)
            end
        end

        -- 2. Hook Troops Channel InvokeServer (+20 Y Offset on Place & Hacker Clone)
        if Network and type(Network.Channel) == "function" then
            local troopsChannel = Network.Channel("Troops")
            if troopsChannel and type(troopsChannel.InvokeServer) == "function" and not origTroopsInvokeServer then
                origTroopsInvokeServer = troopsChannel.InvokeServer
                troopsChannel.InvokeServer = function(self, action, data, ...)
                    if isStackerActive() then
                        -- Normal Tower Placement: add +20 Y
                        if action == "Place" and type(data) == "table" and typeof(data.Position) == "Vector3" then
                            data.Position = data.Position + Vector3.new(0, 20, 0)
                        end

                        -- Hacker Clone Ability: add +20 Y
                        if action == "Abilities" and type(data) == "table" and type(data.Data) == "table" then
                            if typeof(data.Data.towerPosition) == "Vector3" then
                                data.Data.towerPosition = data.Data.towerPosition + Vector3.new(0, 20, 0)
                            end
                        end
                    end

                    return origTroopsInvokeServer(self, action, data, ...)
                end
            end
        end

        stackerInitialized = true
        Logger:Success("Stacker & Collision Check hooks applied successfully.")
    end)
end

if isStackerActive() then
    applyStackerHooks()
end
end -- Stacker block

;(function()
-- =============================================================================
-- Automation & Combat Utility Routines
-- =============================================================================
extractPrivateServerCode = function(linkOrCode: string?)
    if not linkOrCode or type(linkOrCode) ~= "string" then return "" end
    local trimmed = linkOrCode:gsub("^%s*(.-)%s*$", "%1")
    if trimmed == "" then return "" end

    local psCode = trimmed:match("privateServerLinkCode=([%w%-%_]+)")
    if psCode and #psCode > 0 then return psCode end

    local shareCode = trimmed:match("[?&]code=([%w%-%_]+)")
    if shareCode and #shareCode > 0 then return shareCode end

    return trimmed
end

local function RunVoteSkip()
    while true do
        local success = pcall(function()
            local rf = ReplicatedStorage:FindFirstChild("RemoteFunction")
            if rf and rf:IsA("RemoteFunction") then
                rf:InvokeServer("Voting", "Skip")
            end
        end)
        if success then break end
        task.wait(0.1)
    end
end

local AutoReadyRunning = false
StartAutoReady = function()
    local GameState = (game.PlaceId == LOBBY_PLACE_ID) and "LOBBY" or "GAME"
    local isEnabled = (Globals and Globals.AutoReady) or (State and State.Utilities and State.Utilities.AutoReady)
    if AutoReadyRunning or not isEnabled or GameState ~= "GAME" then return end
    AutoReadyRunning = true

    task.spawn(function()
        local stateReps = ReplicatedStorage:WaitForChild("StateReplicators", 10)
        local voteReplicator = stateReps and stateReps:WaitForChild("VoteReplicator", 10)
        if not voteReplicator then
            AutoReadyRunning = false
            return
        end
        
        repeat task.wait(0.1) until voteReplicator:GetAttribute("Enabled") == true and voteReplicator:GetAttribute("Title") == "Ready?"
        
        RunVoteSkip()
        
        repeat task.wait(0.1) until voteReplicator:GetAttribute("Enabled") == false
        
        AutoReadyRunning = false
    end)
end

local AutoSkipRunning = false
StartAutoSkip = function()
    local isEnabled = (Globals and Globals.AutoSkip) or (State and State.Utilities and State.Utilities.AutoSkip)
    if AutoSkipRunning or not isEnabled then return end
    AutoSkipRunning = true

    task.spawn(function()
        while (Globals and Globals.AutoSkip) or (State and State.Utilities and State.Utilities.AutoSkip) do
            local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
            local SkipVisible =
                pg
                and pg:FindFirstChild("ReactOverridesVote")
                and pg.ReactOverridesVote:FindFirstChild("Frame")
                and pg.ReactOverridesVote.Frame:FindFirstChild("votes")
                and pg.ReactOverridesVote.Frame.votes:FindFirstChild("vote")

            if SkipVisible and (SkipVisible.Position == UDim2.new(0.5, 0, 0.5, 0) or SkipVisible.Visible) then
                RunVoteSkip()
            end

            task.wait(0.1)
        end

        AutoSkipRunning = false
    end)
end

local AutoRejoinRunning = false
StartAutoRejoin = function()
    if AutoRejoinRunning then return end
    local isEnabled = (Globals and Globals.AutoRejoin) or (State and State.Utilities and State.Utilities.AutoRejoin)
    if not isEnabled then return end
    AutoRejoinRunning = true

    task.spawn(function()
        while (Globals and Globals.AutoRejoin) or (State and State.Utilities and State.Utilities.AutoRejoin) do
            if game.PlaceId ~= LOBBY_PLACE_ID then
                local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                local isOver = gsr and (gsr:GetAttribute("GameOver") == true)
                local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
                local hasRewards = pg and (pg:FindFirstChild("ReactGameNewRewards") ~= nil or pg:FindFirstChild("GameOver") ~= nil)

                if isOver or hasRewards then
                    Logger:Info("Auto Rejoin: Match conclusion detected (Win/Lose). Teleporting in 3 seconds...")
                    task.wait(3)
                    if (Globals and Globals.AutoRejoin) or (State and State.Utilities and State.Utilities.AutoRejoin) then
                        if SmartTeleportToLobby then
                            SmartTeleportToLobby()
                        elseif Globals and Globals.SmartTeleportToLobby then
                            Globals.SmartTeleportToLobby()
                        end
                        task.wait(10)
                    end
                end
            end
            task.wait(1)
        end
        AutoRejoinRunning = false
    end)
end

local TimeScaleValues = { 0.5, 1, 1.5, 2 }
local TimeScaleRunning = false
local TimeScaleNoTicketsWarned = false

local function NormalizeTimeScaleValue(val)
    local num = tonumber(val)
    if not num then return nil end
    for _, v in ipairs(TimeScaleValues) do
        if v == num then return v end
    end
    return nil
end

local function CoerceTimeScaleValue(val, fallback)
    return NormalizeTimeScaleValue(val) or fallback
end

local function GetTimescaleFrame()
    local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
    local hotbar = pg and pg:FindFirstChild("ReactUniversalHotbar")
    local frame = hotbar and hotbar:FindFirstChild("Frame")
    return frame and frame:FindFirstChild("timescale")
end

local function SetGameTimescale(targetVal)
    if game.PlaceId == LOBBY_PLACE_ID then return end

    local speedList = { 0, 0.5, 1, 1.5, 2 }
    local targetIdx = nil
    for i, v in ipairs(speedList) do
        if v == targetVal then
            targetIdx = i
            break
        end
    end
    if not targetIdx then return end

    local frame = GetTimescaleFrame()
    if not frame then return end

    local speedLabel = frame:FindFirstChild("Speed")
    if not (speedLabel and speedLabel:IsA("TextLabel")) then return end

    local currentVal = tonumber(speedLabel.Text:match("x([%d%.]+)"))
    if not currentVal then return end

    local currentIdx = nil
    for i, v in ipairs(speedList) do
        if v == currentVal then
            currentIdx = i
            break
        end
    end
    if not currentIdx or currentIdx == targetIdx then return end

    local diff = targetIdx - currentIdx
    if diff < 0 then
        diff = #speedList + diff
    end

    local rf = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if not rf then return end

    for _ = 1, diff do
        pcall(function()
            rf:InvokeServer("TicketsManager", "CycleTimeScale")
        end)
        task.wait(0.5)
    end
end

local function UnlockSpeedTickets()
    if game.PlaceId == LOBBY_PLACE_ID then return end

    local targetTickets = tonumber(Globals and Globals.TimescaleTarget)
        or tonumber(State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Target)
        or 0
    if targetTickets > 0 and (tonumber(Globals and Globals.TimescaleTicketsUsed) or 0) >= targetTickets then
        return
    end

    local tickets = (LocalPlayer and LocalPlayer:FindFirstChild("TimescaleTickets"))
    local ticketVal = tickets and tickets.Value
    if not ticketVal and DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" then
        pcall(function() ticketVal = DataHandler:GetTimescaleTickets() end)
    end

    if ticketVal and ticketVal >= 1 then
        local frame = GetTimescaleFrame()
        local lockIcon = frame and frame:FindFirstChild("Lock")

        if lockIcon and lockIcon.Visible then
            local rf = ReplicatedStorage:FindFirstChild("RemoteFunction")
            if rf then
                pcall(function()
                    rf:InvokeServer("TicketsManager", "UnlockTimeScale")
                    if Globals then
                        Globals.TimescaleTicketsUsed = (tonumber(Globals.TimescaleTicketsUsed) or 0) + 1
                        if Settings then Settings:Set("TimescaleTicketsUsed", Globals.TimescaleTicketsUsed) end
                    end
                end)
            end
        end
    end
end

ApplyInMatchTimescaleOnce = function()
    local isEnabled = (State and State.Utilities and State.Utilities.EnableTimescale)
        or (Globals and (Globals.EnableTimescale or Globals.TimeScaleEnabled))
        or (State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Enabled)
    if not isEnabled then return end

    local stateReplicators = ReplicatedStorage:FindFirstChild("StateReplicators")
    local gameStateReplicator = stateReplicators and stateReplicators:FindFirstChild("GameStateReplicator")
    if not gameStateReplicator or (gameStateReplicator:GetAttribute("GameStarted") ~= true and (gameStateReplicator:GetAttribute("Wave") or 0) == 0) then return end

    local frame = GetTimescaleFrame()
    if not frame or not frame.Visible then return end

    local targetSpeed = (State and State.Utilities and State.Utilities.TimescaleTargetSpeed)
        or (Globals and (Globals.TimescaleTargetSpeed or Globals.TimeScaleValue))
        or 2.0
    local desired = CoerceTimeScaleValue(targetSpeed, 2)
    local lock = frame:FindFirstChild("Lock")

    if lock and lock.Visible then
        local tickets = (LocalPlayer and LocalPlayer:FindFirstChild("TimescaleTickets"))
        local ticketVal = tickets and tickets.Value
        if not ticketVal and DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" then
            pcall(function() ticketVal = DataHandler:GetTimescaleTickets() end)
        end
        if ticketVal and ticketVal < 1 then
            if not TimeScaleNoTicketsWarned then
                TimeScaleNoTicketsWarned = true
                Logger:Warn("No timescale tickets left to unlock speed.")
            end
            return
        end
        UnlockSpeedTickets()
        task.wait(0.4)
    else
        TimeScaleNoTicketsWarned = false
    end

    SetGameTimescale(desired)
end

StartInMatchTimescale = function()
    local isEnabled = (State and State.Utilities and State.Utilities.EnableTimescale)
        or (Globals and (Globals.EnableTimescale or Globals.TimeScaleEnabled))
        or (State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Enabled)
    if TimeScaleRunning or not isEnabled then return end
    TimeScaleRunning = true

    task.spawn(function()
        while (State and State.Utilities and State.Utilities.EnableTimescale)
            or (Globals and (Globals.EnableTimescale or Globals.TimeScaleEnabled))
            or (State and State.AutoCurrency and State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Enabled) do
            ApplyInMatchTimescaleOnce()
            task.wait(3)
        end
        TimeScaleNoTicketsWarned = false
        TimeScaleRunning = false
    end)
end


local AutoReloadGatlingRunning = false
local function isGatlingAmmoLow(): boolean
    local towersFolder = workspace:FindFirstChild("Towers")
    local defaultFolder = towersFolder and towersFolder:FindFirstChild("Default")
    if not defaultFolder then return false end
    local myUserId = LocalPlayer and LocalPlayer.UserId

    for _, replicator in ipairs(defaultFolder:GetChildren()) do
        if replicator.Name == "TowerReplicator" then
            local owner = replicator:GetAttribute("OwnerId")
            local towerName = replicator:GetAttribute("Name")
            if tonumber(owner) == myUserId and towerName == "Gatling Gun" then
                local currentAmmo = tonumber(replicator:GetAttribute("Ammo"))
                local maxAmmo = tonumber(replicator:GetAttribute("MaxAmmo"))
                if currentAmmo and maxAmmo and maxAmmo > 0 then
                    local currentPercent = math.round((currentAmmo / maxAmmo) * 100)
                    local threshold = tonumber(State and State.AdvancFunc and State.AdvancFunc.GatlingReloadPercent)
                        or tonumber(State and State.Utilities and State.Utilities.GatlingReloadPercent)
                        or tonumber(Globals and Globals.GatlingReloadPercent)
                        or 100
                    return currentPercent <= threshold
                end
            end
        end
    end
    return false
end

StartAutoReloadGatling = function()
    if AutoReloadGatlingRunning then return end
    AutoReloadGatlingRunning = true
    task.spawn(function()
        local isReloading = false
        local cooldown = 0
        while (State and State.AdvancFunc and State.AdvancFunc.AutoReloadGatling)
            or (State and State.Utilities and State.Utilities.AutoReloadGatling)
            or (Globals and Globals.AutoReloadGatling) do
            task.wait(0.4)
            if game.PlaceId ~= LOBBY_PLACE_ID then
                if isReloading then
                    cooldown = cooldown - 0.4
                    if cooldown <= 0 then
                        isReloading = false
                    end
                else
                    if isGatlingAmmoLow() then
                        isReloading = true
                        cooldown = 3.0
                        pcall(function()
                            local event = ReplicatedStorage:FindFirstChild("Network")
                            if event then event = event:FindFirstChild("GatlingGun") end
                            if event then event = event:FindFirstChild("RE:Reload") end
                            if event and event:IsA("RemoteEvent") then
                                event:FireServer()
                            end
                        end)
                    end
                end
            end
        end
        AutoReloadGatlingRunning = false
    end)
end

-- =============================================================================
-- Auto Collect & Item Pickups (Event Currencies, Charms, Drops)
-- =============================================================================
local function GetRoot()
    local char = LocalPlayer and LocalPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function IsVoidCharm(obj)
    if not obj then return true end
    local pos = nil
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        local cf = obj:GetPivot()
        pos = cf.Position
    end
    if not pos then return true end
    return math.abs(pos.Y) > 999999 or pos.Y < -500
end

local function isCollectibleItem(item)
    if not item or not item.Parent then return false end
    if not (item:IsA("MeshPart") or item:IsA("BasePart") or item:IsA("Model")) then return false end
    if IsVoidCharm(item) then return false end

    local name = item.Name
    if name == "Fragment" or name:find("Fragment")
        or name == "Bunz" or name == "Lorebook" or name == "SnowCharm"
        or name == "CandyCorn" or name == "Candy" or name == "Pumpkin"
        or name == "Present" or name == "Gift"
        or name == "Egg" or name == "GoldenEgg" or name == "Golden Egg"
        or name:find("Charm") or name:find("Shard") or name:find("Solar")
        or name:find("Lunar") or name:find("Token") or name:find("Coin")
        or name:find("Drop") or name:find("Pickup") then
        return true
    end

    if item:IsA("MeshPart") or item:IsA("BasePart") or item:IsA("Model") then
        return true
    end

    return false
end

local function getItemCFrameAndPos(item)
    if item:IsA("BasePart") then
        return item.CFrame, item.Position
    elseif item:IsA("Model") then
        local cf = item:GetPivot()
        return cf, cf.Position
    end
    return nil, nil
end

local AutoPickupsRunning = false
StartAutoPickups = function()
    local isEnabled = (State and State.Utilities and State.Utilities.AutoPickups)
        or (Globals and Globals.AutoPickups)
    if AutoPickupsRunning or not isEnabled then return end
    AutoPickupsRunning = true

    task.spawn(function()
        while (State and State.Utilities and State.Utilities.AutoPickups) or (Globals and Globals.AutoPickups) do
            local folder = workspace:FindFirstChild("Pickups")
            local hrp = GetRoot()

            if folder and hrp and hrp.Parent then
                local char = hrp.Parent
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local function MoveToPos(TargetPos)
                    if not humanoid or not hrp or not hrp.Parent then
                        return false
                    end
                    local function MoveDirect(pos)
                        humanoid:MoveTo(pos)
                        local StartT = os.clock()
                        while os.clock() - StartT < 2 do
                            if not ((State and State.Utilities and State.Utilities.AutoPickups) or (Globals and Globals.AutoPickups)) then
                                return false
                            end
                            if not hrp or not hrp.Parent then
                                return false
                            end
                            if (hrp.Position - pos).Magnitude < 4 then
                                return true
                            end
                            task.wait(0.1)
                        end
                        return (hrp.Position - pos).Magnitude < 4
                    end
                    local path = PathfindingService:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 6,
                        AgentCanJump = true,
                        AgentJumpHeight = 7,
                        AgentMaxSlope = 45
                    })
                    local ok = pcall(function()
                        path:ComputeAsync(hrp.Position, TargetPos)
                    end)
                    if ok and path.Status == Enum.PathStatus.Success then
                        local waypoints = path:GetWaypoints()
                        local BlockedConn = nil
                        BlockedConn = path.Blocked:Connect(function()
                            if BlockedConn then
                                BlockedConn:Disconnect()
                                BlockedConn = nil
                            end
                            if (State and State.Utilities and State.Utilities.AutoPickups) or (Globals and Globals.AutoPickups) then
                                task.spawn(function()
                                    MoveToPos(TargetPos)
                                end)
                            end
                        end)
                        for _, wp in ipairs(waypoints) do
                            if not ((State and State.Utilities and State.Utilities.AutoPickups) or (Globals and Globals.AutoPickups)) then
                                if BlockedConn then
                                    BlockedConn:Disconnect()
                                    BlockedConn = nil
                                end
                                return false
                            end
                            if wp.Action == Enum.PathWaypointAction.Jump then
                                humanoid.Jump = true
                            end
                            if not MoveDirect(wp.Position) then
                                if BlockedConn then
                                    BlockedConn:Disconnect()
                                    BlockedConn = nil
                                end
                                return false
                            end
                        end
                        if BlockedConn then
                            BlockedConn:Disconnect()
                            BlockedConn = nil
                        end
                        return true
                    end
                    return MoveDirect(TargetPos)
                end

                local method = (State and State.Utilities and State.Utilities.PickupMethod)
                    or (Globals and Globals.PickupMethod)
                    or "Pathfinding"

                for _, item in ipairs(folder:GetChildren()) do
                    if not ((State and State.Utilities and State.Utilities.AutoPickups) or (Globals and Globals.AutoPickups)) then break end

                    if isCollectibleItem(item) then
                        local itemCFrame, itemPos = getItemCFrameAndPos(item)
                        if itemCFrame and itemPos then
                            if method == "Instant" then
                                hrp.CFrame = itemCFrame * CFrame.new(0, 3, 0)
                                task.wait(0.2)
                                task.wait(0.3)
                            else
                                local TargetPos = itemPos + Vector3.new(0, 3, 0)
                                MoveToPos(TargetPos)
                                task.wait(0.2)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end

            task.wait(1)
        end

        AutoPickupsRunning = false
    end)
end
end)() -- Automation routines block

do
-- Start background loops if active
if (State and State.Utilities and State.Utilities.AutoSkip) or (Globals and Globals.AutoSkip) then
    StartAutoSkip()
end
if (State and State.Utilities and State.Utilities.AutoReady) or (Globals and Globals.AutoReady) then
    StartAutoReady()
end
if (State and State.Utilities and State.Utilities.AutoRejoin) or (Globals and Globals.AutoRejoin) then
    StartAutoRejoin()
end
if ((State and State.Utilities and (State.Utilities.EnableTimescale or State.Utilities.InMatchTimescale))
    or (Globals and (Globals.EnableTimescale or Globals.TimeScaleEnabled or Globals.InMatchTimescale))) then
    StartInMatchTimescale()
end
if ((State and State.AdvancFunc and (State.AdvancFunc.AutoGatling or State.AdvancFunc.ConditionGatlingLoader))
    or (Globals and (Globals.AutoGatling or Globals.ConditionGatlingLoader))) and checkIsPremium() then
    AutoGoldModule.StartAutoGatling()
end
if ((State and State.AdvancFunc and State.AdvancFunc.AutoReloadGatling)
    or (State and State.Utilities and State.Utilities.AutoReloadGatling)
    or (Globals and Globals.AutoReloadGatling)) and checkIsPremium() then
    StartAutoReloadGatling()
end
if (State and State.Utilities and State.Utilities.AutoPickups) or (Globals and Globals.AutoPickups) then
    StartAutoPickups()
end
end

do
-- 1. Stacker at the top of the top (Premium)
local StackerSection = UtilitiesTab:Section({ Title = "Stacker Placement" })

local stackerToggleRef = nil
stackerToggleRef = StackerSection:Toggle({
    Title = "Stacker",
    Desc = checkIsPremium() and "Enable tower placement stacking, collision bypass, and +20 Y offset (Premium)" or "Locked — Premium VIP Plan Required",
    Value = checkIsPremium() and State.Utilities.Stacker or false,
    Callback = function(val: boolean)
        if val and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Stacker is a Premium VIP feature. Please activate key at Product tab.",
                Duration = 3.5,
            })
            Logger:Warn("Stacker: Premium feature. Please activate key at Product tab.")
            State.Utilities.Stacker = false
            if Globals then
                Globals.Stacker = false
                Globals.StackEnabled = false
            end
            if getgenv then
                getgenv().Stacker = false
                getgenv().StackEnabled = false
            end
            if Settings then Settings:Set("Stacker", false) end
            task.spawn(function()
                if stackerToggleRef and typeof(stackerToggleRef.SetValue) == "function" then
                    stackerToggleRef:SetValue(false)
                end
            end)
            return
        end
        State.Utilities.Stacker = val
        if Globals then
            Globals.Stacker = val
            Globals.StackEnabled = val
        end
        if getgenv then
            getgenv().Stacker = val
            getgenv().StackEnabled = val
        end
        if Settings then Settings:Set("Stacker", val) end
        Logger:Info("Stacker: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            applyStackerHooks()
        end
    end,
})
end

do
-- 2. General Utilities (Free)
local UtilitiesGeneralSection = UtilitiesTab:Section({ Title = "General Utilities" })

UtilitiesGeneralSection:Toggle({
    Title = "Auto Skip",
    Desc = "Automatically votes to skip wave intervals when prompt appears",
    Value = State.Utilities.AutoSkip,
    Callback = function(val: boolean)
        State.Utilities.AutoSkip = val
        Globals.AutoSkip = val
        if Settings then Settings:Set("AutoSkip", val) end
        Logger:Info("Auto Skip: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            StartAutoSkip()
        end
    end,
})

UtilitiesGeneralSection:Toggle({
    Title = "Auto Ready Up",
    Desc = "Automatically votes ready when the Ready prompt appears",
    Value = State.Utilities.AutoReady,
    Callback = function(val: boolean)
        State.Utilities.AutoReady = val
        Globals.AutoReady = val
        if Settings then Settings:Set("AutoReady", val) end
        Logger:Info("Auto Ready Up: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            StartAutoReady()
        end
    end,
})

UtilitiesGeneralSection:Toggle({
    Title = "Auto Rejoin",
    Desc = "Automatically rejoins match or private server upon Win or Lose",
    Value = State.Utilities.AutoRejoin,
    Callback = function(val: boolean)
        State.Utilities.AutoRejoin = val
        Globals.AutoRejoin = val
        if Settings then Settings:Set("AutoRejoin", val) end
        Logger:Info("Auto Rejoin: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            StartAutoRejoin()
        end
    end,
})

UtilitiesGeneralSection:Textbox({
    Title = "Private Server Code",
    Desc = "Private server link or code used for auto rejoin when match concludes",
    Placeholder = "Paste private server link or code here...",
    Value = State.Utilities.RejoinPrivateServerCode or (State.Misc and State.Misc.PrivateServerCode) or Globals.PrivateServerCode or "",
    ClearTextOnFocus = false,
    Callback = function(linkOrCode: string)
        local code = extractPrivateServerCode(linkOrCode)
        State.Utilities.RejoinPrivateServerCode = linkOrCode
        if State.Misc then
            State.Misc.PrivateServerCode = linkOrCode
            State.Misc.PrivateCode = code
            State.Misc.MultiplayerPrivateServerLink = linkOrCode
        end
        Globals.PrivateServerCode = linkOrCode
        Globals.PrivateCode = code
        Globals.MultiplayerPrivateServerLink = linkOrCode
        if Settings then
            Settings:Set("PrivateServerCode", linkOrCode)
            Settings:Set("PrivateCode", code)
            Settings:Set("MultiplayerPrivateServerLink", linkOrCode)
        end
        if code ~= "" then
            Logger:Info("Auto Rejoin: Private server code updated: " .. code)
        end
    end,
})

UtilitiesGeneralSection:Toggle({
    Title = "Enable Timescale",
    Desc = "Automatically unlock tickets and maintain timescale multiplier in match",
    Value = State.Utilities.EnableTimescale,
    Callback = function(val: boolean)
        State.Utilities.EnableTimescale = val
        Globals.EnableTimescale = val
        Globals.TimeScaleEnabled = val
        if Settings then Settings:Set("EnableTimescale", val) end
        Logger:Info("Enable Timescale: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            StartInMatchTimescale()
        end
    end,
})

UtilitiesGeneralSection:Slider({
    Title = "Timescale Speed",
    Desc = "Game speed multiplier to maintain in match (0.5x to 2.0x)",
    Min = 0.5,
    Max = 2.0,
    Step = 0.5,
    Suffix = "x",
    Value = State.Utilities.TimescaleTargetSpeed or 2.0,
    Callback = function(val: number)
        State.Utilities.TimescaleTargetSpeed = val
        Globals.TimescaleTargetSpeed = val
        Globals.TimeScaleValue = val
        if Settings then Settings:Set("TimescaleTargetSpeed", val) end
        if State.Utilities.EnableTimescale or Globals.TimeScaleEnabled then
            ApplyInMatchTimescaleOnce()
        end
    end,
})


UtilitiesGeneralSection:Button({
    Title = "Unlock Admin",
    Desc = "Requests sandbox admin privileges via Sandbox remote",
    Image = "Shield",
    Callback = function()
        pcall(function()
            local net = game:GetService("ReplicatedStorage"):FindFirstChild("Network")
            local sb = net and net:FindFirstChild("Sandbox")
            local setAdmin = sb and sb:FindFirstChild("RE:SetAdmin")
            if setAdmin then
                local myId = (LocalPlayer and LocalPlayer.UserId) or game:GetService("Players").LocalPlayer.UserId
                setAdmin:FireServer(myId, true)
                Window:Notify({
                    Title = "Unlock Admin",
                    Desc = "Admin privileges requested successfully!",
                    Duration = 3,
                })
                Logger:Success("Unlock Admin: Sent RE:SetAdmin successfully.")
            else
                Window:Notify({
                    Title = "Unlock Admin",
                    Desc = "Sandbox admin remote not found in current game mode.",
                    Duration = 3,
                    Type = "error",
                })
                Logger:Warn("Unlock Admin: Sandbox remote RE:SetAdmin not found.")
            end
        end)
    end,
})

-- Auto Collect & Item Pickups (Event Drops & Currencies)
UtilitiesGeneralSection:Toggle({
    Title = "Auto Collect",
    Desc = "Automatically collect dropped items, event currencies, and charms in match",
    Value = State.Utilities.AutoPickups,
    Callback = function(val: boolean)
        State.Utilities.AutoPickups = val
        Globals.AutoPickups = val
        if getgenv then getgenv().AutoPickups = val end
        if Settings then Settings:Set("AutoPickups", val) end
        Logger:Info("Auto Collect: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            StartAutoPickups()
        end
    end,
})

UtilitiesGeneralSection:Dropdown({
    Title = "Pickup Method",
    Desc = "Movement mode for item collection (Pathfinding or Instant)",
    List = { "Pathfinding", "Instant" },
    Value = State.Utilities.PickupMethod or Globals.PickupMethod or "Pathfinding",
    Callback = function(choice: string)
        State.Utilities.PickupMethod = choice
        Globals.PickupMethod = choice
        if getgenv then getgenv().PickupMethod = choice end
        if Settings then Settings:Set("PickupMethod", choice) end
        Logger:Info("Pickup Method: " .. tostring(choice))
    end,
})
end

--==============================================================================
-- 7.5 ADVANC FUNC TAB (Premium)
--==============================================================================
;(function()
local AdvancFuncTab = Window:Tab({
    Title = "Advanc Func",
    Subtitle = "Advanced Gatling & Combat",
})

AdvancFuncTab:Banner({
    Title = checkIsPremium() and "Advanced Functions (Premium VIP Active)" or "Advanced Functions (Premium VIP Required)",
    Desc = checkIsPremium() and "Specialized automated combat assistants, weapon reloads, and Gatling routines." or "Advanced Gatling & combat macros require an active Premium plan. Please activate key at Product tab.",
    Type = checkIsPremium() and "Info" or "Warning",
})

local autoGatlingSection = AdvancFuncTab:Section({ Title = "Auto Gatling" })

local autoGatlingToggleRef = nil
autoGatlingToggleRef = autoGatlingSection:Toggle({
    Title = "Turn on Auto Gatling",
    Desc = checkIsPremium() and "Automatically executes Gatling macro script during match" or "Locked — Premium VIP Plan Required",
    Value = checkIsPremium() and State.AdvancFunc.AutoGatling or false,
    Callback = function(val: boolean)
        if val and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Auto Gatling is a Premium VIP feature. Please activate key at Product tab.",
                Duration = 3.5,
            })
            Logger:Warn("Auto Gatling: Premium feature. Please activate key at Product tab.")
            State.AdvancFunc.AutoGatling = false
            Globals.AutoGatling = false
            if Settings then
                Settings:Set("AutoGatling", false)
            end
            task.spawn(function()
                if autoGatlingToggleRef and typeof(autoGatlingToggleRef.SetValue) == "function" then
                    autoGatlingToggleRef:SetValue(false)
                end
            end)
            return
        end
        State.AdvancFunc.AutoGatling = val
        Globals.AutoGatling = val
        if Settings then
            Settings:Set("AutoGatling", val)
        end
        Logger:Info("Auto Gatling: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            AutoGoldModule.GatlingExecuted = false
            if game.PlaceId ~= 3260590327 then
                AutoGoldModule.ExecuteGatlingLoader(State.AdvancFunc.SelectedGatling or "Railgun")
            else
                AutoGoldModule.StartAutoGatling()
            end
        end
    end,
})

autoGatlingSection:Dropdown({
    Title = "Gatling Script",
    Desc = "Choose script to load for Gatling Gun (Railgun or Gatlify)",
    List = { "Railgun", "Gatlify" },
    Value = State.AdvancFunc.SelectedGatling or "Railgun",
    Callback = function(choice: string)
        State.AdvancFunc.SelectedGatling = choice
        Globals.SelectedGatling = choice
        if Settings then Settings:Set("SelectedGatling", choice) end
        Logger:Info("Selected Gatling Script: " .. tostring(choice))
        if State.AdvancFunc.AutoGatling and game.PlaceId ~= 3260590327 then
            AutoGoldModule.ExecuteGatlingLoader(choice)
        end
    end,
})

autoGatlingSection:Slider({
    Title = "Max Target",
    Desc = "Maximum number of simultaneous targets to acquire",
    Min = 1,
    Max = 5,
    Step = 1,
    Value = math.clamp(State.AdvancFunc.MaxTarget or 5, 1, 5),
    Callback = function(val: number)
        State.AdvancFunc.MaxTarget = val
        Globals.AutoGatlingMaxTarget = val
        if Settings then Settings:Set("AutoGatlingMaxTarget", val) end
    end,
})

autoGatlingSection:Dropdown({
    Title = "Target Priority",
    Desc = "Targeting priority order for Gatling macros (Default: Last)",
    List = { "Last", "First", "Strongest" },
    Value = State.AdvancFunc.TargetPriority or "Last",
    Callback = function(choice: string)
        State.AdvancFunc.TargetPriority = choice
        Globals.AutoGatlingPriority = choice
        if Settings then Settings:Set("AutoGatlingPriority", choice) end
        Logger:Info("Gatling Target Priority: " .. choice)
    end,
})

local autoReloadToggleRef = nil
autoReloadToggleRef = autoGatlingSection:Toggle({
    Title = "Auto Reload Gatling",
    Desc = checkIsPremium() and "Automatically reloads Gatling Gun during safe combat windows (Premium)" or "Locked — Premium VIP Plan Required",
    Value = checkIsPremium() and State.AdvancFunc.AutoReloadGatling or false,
    Callback = function(val: boolean)
        if val and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Auto Reload Gatling is a Premium VIP feature. Please activate key at Product tab.",
                Duration = 3.5,
            })
            Logger:Warn("Auto Reload Gatling: Premium feature. Please activate key at Product tab.")
            State.AdvancFunc.AutoReloadGatling = false
            Globals.AutoReloadGatling = false
            if Settings then Settings:Set("AutoReloadGatling", false) end
            task.spawn(function()
                if autoReloadToggleRef and typeof(autoReloadToggleRef.SetValue) == "function" then
                    autoReloadToggleRef:SetValue(false)
                end
            end)
            return
        end
        State.AdvancFunc.AutoReloadGatling = val
        Globals.AutoReloadGatling = val
        if Settings then Settings:Set("AutoReloadGatling", val) end
        Logger:Info("Auto Reload Gatling: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            StartAutoReloadGatling()
        end
    end,
})

autoGatlingSection:Slider({
    Title = "Gatling Reload Threshold",
    Desc = "Reloads Gatling Gun when current ammo falls to or below this percentage",
    Min = 10,
    Max = 100,
    Step = 5,
    Suffix = "%",
    Value = State.AdvancFunc.GatlingReloadPercent or 100,
    Callback = function(val: number)
        State.AdvancFunc.GatlingReloadPercent = val
        Globals.GatlingReloadPercent = val
        if Settings then Settings:Set("GatlingReloadPercent", val) end
    end,
})

local conditionGatlingSection = AdvancFuncTab:Section({ Title = "Gatling Loader Condition Win | Trial" })

local conditionGatlingToggleRef = nil
conditionGatlingToggleRef = conditionGatlingSection:Toggle({
    Title = "Gatling Loader Condition Win | Trial",
    Desc = checkIsPremium() and "Loads Gatling script only during Win condition or Trials matches (Premium)" or "Locked — Premium VIP Plan Required",
    Value = checkIsPremium() and (State.AdvancFunc.ConditionGatlingLoader or false) or false,
    Callback = function(val: boolean)
        if val and not checkIsPremium() then
            Window:Notify({
                Title = "Premium Plan Required",
                Desc = "Gatling Loader Condition Win | Trial is a Premium VIP feature. Please activate key at Product tab.",
                Duration = 3.5,
            })
            Logger:Warn("Gatling Loader Condition Win | Trial: Premium feature. Please activate key at Product tab.")
            State.AdvancFunc.ConditionGatlingLoader = false
            Globals.ConditionGatlingLoader = false
            if Settings then Settings:Set("ConditionGatlingLoader", false) end
            task.spawn(function()
                if conditionGatlingToggleRef and typeof(conditionGatlingToggleRef.SetValue) == "function" then
                    conditionGatlingToggleRef:SetValue(false)
                end
            end)
            return
        end
        State.AdvancFunc.ConditionGatlingLoader = val
        Globals.ConditionGatlingLoader = val
        if Settings then Settings:Set("ConditionGatlingLoader", val) end
        Logger:Info("Gatling Loader Condition Win | Trial: " .. (val and "ENABLED" or "DISABLED"))
        if val then
            AutoGoldModule.GatlingExecuted = false
            if game.PlaceId == 3260590327 then
                AutoGoldModule.StartAutoGatling()
            end
        end
    end,
})

conditionGatlingSection:Dropdown({
    Title = "Gatling Script (Win | Trial)",
    Desc = "Choose script to load for Win | Trials matches (Railgun or Gatlify)",
    List = { "Railgun", "Gatlify" },
    Value = State.AdvancFunc.ConditionGatlingScript or "Railgun",
    Callback = function(choice: string)
        State.AdvancFunc.ConditionGatlingScript = choice
        Globals.ConditionGatlingScript = choice
        if Settings then Settings:Set("ConditionGatlingScript", choice) end
        Logger:Info("Selected Gatling Script (Win | Trial): " .. tostring(choice))
    end,
})
end)()

--==============================================================================
-- 8. PRODUCT TAB
--==============================================================================
;(function()
local ProductTab = Window:Tab({
    Title = "Product",
    Subtitle = "Tier Plans & Features",
})

ProductTab:Banner({
    Title = "Hub Licensing & Subscription Tiers",
    Desc = "Explore available tiers or activate a key below to unlock accelerated bypasses.",
    Type = "Info",
})

local isPremProduct = checkIsPremium()

ProductTab:SelectionBox({
    Selections = { "Free", "Premium" },
    Descriptions = {
        Free = "Community Edition",
        Premium = "VIP Access (Full)",
    },
    Checklist = {
        Free = {
            "Standard Molten & Fallen farming (Lose Mode)",
            "Hardcore Gem cycling (Lose Mode)",
            "Standard EXP Leveling routines",
            "Basic Auto Trials (Wait for rotation)",
            "Community Discord support access",
        },
        Premium = {
            "Full Auto Evolution farming (Auto Evo)",
            "Molten & Fallen Win Condition farming (Win Mode)",
            "Auto Timescales ticket farming with Fallbacks",
            "Trials to Ignore custom filter (Skip unwanted modifiers)",
            "Dedicated Dual-Tower Loadout auto-equipping",
            "Rich Discord Webhook alerts & match session logs",
            "Target milestone watchdog & in-place retry",
        },
    },
    ButtonTexts = {
        Free = isPremProduct and "Included" or "Current Tier Active",
        Premium = isPremProduct and "Current Tier Active" or "Activate Key Below",
    },
    Callbacks = {
        Free = function()
            Window:Notify({
                Title = "Free Tier",
                Desc = isPremProduct and "You currently have Premium active." or "You are currently running the Free Community Tier.",
                Duration = 2.5,
            })
        end,
        Premium = function()
            Window:Notify({
                Title = isPremProduct and "Premium Active" or "Premium Key Required",
                Desc = isPremProduct and "Premium VIP is active on this account." or "Please enter your license key in the activation box below to activate.",
                Duration = 3,
            })
        end,
    },
})

local ProductLicense = ProductTab:Section({ Title = "Key Activation & Verification" })

local currentTierBanner = ProductLicense:Banner({
    Title = isPremProduct and "Current License Status: Premium VIP (Active)" or "Current License Status: Standard Tier",
    Desc = isPremProduct and "All high-speed routines, bypasses, and uncap limits unlocked!" or "Basic features active. Enter a license key below to unlock VIP / Lifetime.",
    Type = isPremProduct and "Info" or "Warning",
})

ProductLicense:Textbox({
    Title = "License Key",
    Desc = "Paste your license or promotional key here",
    Placeholder = "SN-XXXX-XXXX-XXXX",
    ClearTextOnFocus = false,
    Callback = function(keyStr: string)
        State.Product.LicenseKey = keyStr
    end,
})

ProductLicense:Button({
    Title = "Redeem & Validate Key",
    Desc = "Validates the entered key and applies unlocked features",
    Image = "Check",
    Callback = function()
        local rawKey = State.Product.LicenseKey or ""
        local key = string.gsub(rawKey, "%s+", "")
        if #key < 4 then
            Window:Notify({
                Title = "Activation Failed",
                Desc = "Please enter a valid license key.",
                Duration = 2.5,
            })
            return
        end

        Window:Notify({
            Title = "Verifying Key",
            Desc = "Validating key with Junkie Key System...",
            Duration = 2,
        })

        local Junkie = getJunkieSDK()
        if not Junkie then
            Window:Notify({
                Title = "Connection Error",
                Desc = "Unable to connect to Junkie authentication service.",
                Duration = 3,
            })
            return
        end

        local ok, result = pcall(function()
            return Junkie.check_key(key)
        end)

        if ok and result and result.valid then
            saveVerifiedKey(key)
            if getgenv then getgenv().SCRIPT_KEY = key end
            lastVerifiedKeySuccess = key
            lastVerifiedKeyTime = os.clock()
            PremiumLoaded = true
            State.Product.IsActivated = true
            State.Product.CurrentTier = "Premium VIP"
            Window:UserProfile({
                Badge = "PREMIUM VIP",
                TimeLeft = "Permanent",
            })
            currentTierBanner.Title = "Current License Status: Premium VIP (Active)"
            currentTierBanner.Desc = "All high-speed routines, bypasses, and auto timescales unlocked!"
            Logger:Success("Junkie Key verified! Unlocked Premium VIP tier.")
            Window:Notify({
                Title = "License Activated!",
                Desc = "Welcome to Premium VIP! Key verified successfully.",
                Duration = 3,
            })
        else
            local failMsg = (result and result.message) or "Invalid key or verification failed."
            Window:Notify({
                Title = "Activation Failed",
                Desc = failMsg,
                Duration = 3,
            })
        end
    end,
})

ProductLicense:Button({
    Title = "Get Key",
    Desc = "Copies Junkie key link to clipboard",
    Image = "Link",
    Callback = function()
        local Junkie = getJunkieSDK()
        local link = (Junkie and typeof(Junkie.get_key_link) == "function" and Junkie.get_key_link())
            or "https://jnkie.com"
        if setclipboard then
            setclipboard(link)
            Window:Notify({
                Title = "Key Link Copied",
                Desc = "Junkie key link copied to clipboard!",
                Duration = 3,
            })
        elseif toclipboard then
            toclipboard(link)
            Window:Notify({
                Title = "Key Link Copied",
                Desc = "Junkie key link copied to clipboard!",
                Duration = 3,
            })
        else
            Window:Notify({
                Title = "Key Link",
                Desc = link,
                Duration = 5,
            })
        end
    end,
})
end)()

--==============================================================================
-- Private Server Link Code Parser & Smart Lobby Teleport
--==============================================================================
LOBBY_PLACE_ID = 3260590327
local isTeleporting = false
local loadoutApplied = false
local teleportRetryThread = nil
local isRunning = true

local function clearActiveMode()
    -- Teardown match/mode hook
end

local function extractPrivateServerCode(linkOrCode: string?)
    if not linkOrCode or type(linkOrCode) ~= "string" then return "" end
    local trimmed = linkOrCode:gsub("^%s*(.-)%s*$", "%1")
    if trimmed == "" then return "" end

    local psCode = trimmed:match("privateServerLinkCode=([%w%-%_]+)")
    if psCode and #psCode > 0 then
        return psCode
    end

    local shareCode = trimmed:match("[?&]code=([%w%-%_]+)")
    if shareCode and #shareCode > 0 then
        return shareCode
    end

    local linkCode = trimmed:match("[?&]linkCode=([%w%-%_]+)")
    if linkCode and #linkCode > 0 then
        return linkCode
    end

    if trimmed:find("roblox.com") or trimmed:find("http") then
        local pathCode = trimmed:match("/([%w%-%_]+)%s*$")
        if pathCode and #pathCode >= 15 and not pathCode:find("^[0-9]+$") then
            return pathCode
        end
    end

    return trimmed
end

SmartTeleportToLobby = function()
    if Globals then Globals.SmartTeleportToLobby = SmartTeleportToLobby end
    if shared then
        shared.SmartTeleportToLobby = SmartTeleportToLobby
        if shared.TDSTable then shared.TDSTable.SmartTeleportToLobby = SmartTeleportToLobby end
    end
    if AutoGoldModule then AutoGoldModule.SmartTeleportToLobby = SmartTeleportToLobby end
    if isTeleporting then return end
    isTeleporting = true
    loadoutApplied = false

    pcall(clearActiveMode)

    if teleportRetryThread then
        pcall(task.cancel, teleportRetryThread)
        teleportRetryThread = nil
    end

    local rawCode = (State and State.Misc and (State.Misc.PrivateCode or State.Misc.PrivateServerCode))
        or Globals.PrivateCode
        or Globals.PrivateServerCode
        or Globals.MultiplayerPrivateServerLink
        or (Settings and Settings:Get("PrivateCode", ""))
        or (Settings and Settings:Get("PrivateServerCode", ""))
        or ""
    local targetCode = extractPrivateServerCode(rawCode)

    local function attemptTeleport()
        local platform = UserInputService:GetPlatform()
        local isMobile = (platform == Enum.Platform.IOS or platform == Enum.Platform.Android)

        if not isMobile and targetCode ~= "" then
            Logger:Info("[Teleport] Launching private experience with linkCode: " .. targetCode)
            local launched = false
            pcall(function()
                local expService = game:GetService("ExperienceService")
                if expService then
                    expService:LaunchExperience({
                        placeId = LOBBY_PLACE_ID,
                        linkCode = targetCode
                    })
                    launched = true
                end
            end)
            if not launched then
                pcall(function()
                    TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
                end)
            end
        else
            if game.PlaceId ~= LOBBY_PLACE_ID then
                Logger:Info("[Teleport] Returning to lobby via game remotes...")
                pcall(function()
                    local shared = ReplicatedStorage:FindFirstChild("Shared")
                    local modules = shared and shared:FindFirstChild("Modules")
                    local newNet = modules and modules:FindFirstChild("NewNetwork")
                    if newNet then
                        local NewNetwork = require(newNet)
                        NewNetwork.Channel("Teleport"):fireServer("backToLobby")
                    end
                end)

                pcall(function()
                    local netFolder = ReplicatedStorage:FindFirstChild("Network")
                    local tpFolder = netFolder and netFolder:FindFirstChild("Teleport")
                    local reBack = tpFolder and tpFolder:FindFirstChild("RE:backToLobby")
                    if reBack and reBack:IsA("RemoteEvent") then
                        reBack:FireServer()
                    end
                end)

                pcall(function()
                    local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
                    local remoteFunc = ReplicatedStorage:FindFirstChild("RemoteFunction")
                    if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                        remoteEvent:FireServer("Teleport", "backToLobby")
                    elseif remoteFunc and remoteFunc:IsA("RemoteFunction") then
                        remoteFunc:InvokeServer("Teleport", "backToLobby")
                    end
                end)
            end
        end
    end

    attemptTeleport()

    if game.PlaceId ~= LOBBY_PLACE_ID then
        teleportRetryThread = task.spawn(function()
            while true do
                task.wait(10)
                if not isRunning then break end
                if game.PlaceId == LOBBY_PLACE_ID then break end
                attemptTeleport()
            end
        end)
    end

    task.delay(10, function()
        isTeleporting = false
    end)
end

--==============================================================================
-- 8. MISC TAB
--==============================================================================
local MiscTab = nil
local Apply3dRendering = nil
local StartAntiLag = nil
local ApplyDisableShadows = nil

do
MiscTab = Window:Tab({
    Title = "Misc",
    Subtitle = "Utilities & Client Settings",
})

local MiscPrivateServer = MiscTab:Section({ Title = "Private Server & Lobby" })

MiscPrivateServer:Textbox({
    Title = "Private Server Code / Link",
    Desc = "Enter private server join link or access code to persist for " .. username,
    Placeholder = "Paste private server link or code here...",
    Value = State.Misc.PrivateServerCode,
    ClearTextOnFocus = false,
    Callback = function(linkOrCode: string)
        local code = extractPrivateServerCode(linkOrCode)
        State.Misc.PrivateServerCode = linkOrCode
        State.Misc.PrivateCode = code
        State.Misc.MultiplayerPrivateServerLink = linkOrCode
        if Settings then
            Settings:Set("PrivateServerCode", linkOrCode)
            Settings:Set("PrivateCode", code)
            Settings:Set("MultiplayerPrivateServerLink", linkOrCode)
        end
        if code ~= "" then
            Logger:Info("Private server code saved: " .. code)
            Window:Notify({
                Title = "Private Server Saved",
                Desc = "Saved code for " .. username .. ": " .. code,
                Duration = 2.5,
            })
        else
            Logger:Info("Private server code cleared.")
        end
    end,
})

MiscPrivateServer:Button({
    Title = "Smart Teleport to Lobby",
    Desc = "Teleports to the lobby or private server using your saved code",
    Image = "Zap",
    Callback = function()
        Window:Notify({
            Title = "Smart Teleport",
            Desc = "Connecting to lobby / private server...",
            Duration = 2,
        })
        Logger:Info("Smart Teleport initiated.")
        SmartTeleportToLobby()
    end,
})


local MiscPlayer = MiscTab:Section({ Title = "Player Modifications" })

MiscPlayer:Toggle({
    Title = "Anti-AFK Protection",
    Desc = "Simulates user input upon idle detection to avoid the 20-minute kick",
    Value = State.Misc.AntiAFK,
    Callback = function(val: boolean)
        State.Misc.AntiAFK = val
        if Settings then Settings:Set("AntiAFK", val) end
        Logger:Info("Anti-AFK: " .. (val and "ACTIVE" or "DISABLED"))
    end,
})

-- Performance & Anti-Lag Functions
local AntiLagRunning = false

ApplyDisableShadows = function(enabled: boolean?)
    local shouldDisable = enabled
    if shouldDisable == nil then
        shouldDisable = (Globals and Globals.DisableShadows) or (State and State.Misc and State.Misc.DisableShadows) or false
    end
    pcall(function()
        Lighting.GlobalShadows = not shouldDisable
    end)
end

Apply3dRendering = function()
    local isDisable = (Globals and Globals.Disable3DRendering) or (State and State.Misc and State.Misc.Disable3DRendering) or false
    pcall(function()
        if isDisable then
            game:GetService("RunService"):Set3dRenderingEnabled(false)
        else
            game:GetService("RunService"):Set3dRenderingEnabled(true)
        end
    end)
    local PlayerGui = (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
        or (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 5))
    if not PlayerGui then return end
    local gui = PlayerGui:FindFirstChild("ADS_BlackScreen")
    if isDisable then
        if not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "ADS_BlackScreen"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.DisplayOrder = -1000
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = PlayerGui

            local frame = Instance.new("Frame")
            frame.Name = "Cover"
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Size = UDim2.fromScale(1, 1)
            frame.ZIndex = 0
            frame.Parent = gui

            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "BigTitle"
            textLabel.Text = "Something new hub"
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextSize = 44
            textLabel.TextColor3 = Color3.fromRGB(0, 245, 212)
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, 0, 0, 80)
            textLabel.Position = UDim2.new(0, 0, 0.5, -40)
            textLabel.TextXAlignment = Enum.TextXAlignment.Center
            textLabel.TextYAlignment = Enum.TextYAlignment.Center
            textLabel.ZIndex = 1
            textLabel.Parent = frame
        end
        if gui then
            gui.Enabled = true
        end
    else
        if gui then
            gui.Enabled = false
        end
    end
end

StartAntiLag = function()
    local isEnabled = (Globals and Globals.AntiLag) or (State and State.Misc and State.Misc.AntiLag) or false
    if AntiLagRunning or not isEnabled then return end
    AntiLagRunning = true

    pcall(function()
        local renderSettings = settings().Rendering
        renderSettings.QualityLevel = Enum.QualityLevel.Level01
    end)

    task.spawn(function()
        while (Globals and Globals.AntiLag) or (State and State.Misc and State.Misc.AntiLag) do
            pcall(function()
                local TowersFolder = workspace:FindFirstChild("Towers")
                local ClientUnits = workspace:FindFirstChild("ClientUnits")

                if TowersFolder then
                    for _, tower in ipairs(TowersFolder:GetChildren()) do
                        local anims = tower:FindFirstChild("Animations")
                        local weapon = tower:FindFirstChild("Weapon")
                        local projectiles = tower:FindFirstChild("Projectiles")

                        if anims then anims:Destroy() end
                        if projectiles then projectiles:Destroy() end
                        if weapon then weapon:Destroy() end
                    end
                end
                if ClientUnits then
                    for _, unit in ipairs(ClientUnits:GetChildren()) do
                        unit:Destroy()
                    end
                end
            end)
            
            task.wait(0.5)
        end
        AntiLagRunning = false
    end)
end

local MiscPerformance = MiscTab:Section({ Title = "Performance & Graphics" })

MiscPerformance:Toggle({
    Title = "Remove Towers Animations",
    Desc = "Destroys animations, weapons, projectiles & client units to prevent lag",
    Value = State.Misc.AntiLag,
    Callback = function(val: boolean)
        State.Misc.AntiLag = val
        Globals.AntiLag = val
        if Settings then Settings:Set("AntiLag", val) end
        if val then
            StartAntiLag()
        end
        Logger:Info("Remove Towers Animations: " .. (val and "ACTIVE" or "DISABLED"))
    end,
})

MiscPerformance:Toggle({
    Title = "Disable 3D Rendering",
    Desc = "Disables 3D viewport rendering and displays low-GPU black screen cover",
    Value = State.Misc.Disable3DRendering,
    Callback = function(val: boolean)
        State.Misc.Disable3DRendering = val
        Globals.Disable3DRendering = val
        if Settings then Settings:Set("Disable3DRendering", val) end
        Apply3dRendering()
        Logger:Info("Disable 3D Rendering: " .. (val and "ACTIVE" or "DISABLED"))
    end,
})

MiscPerformance:Toggle({
    Title = "Disable Dynamic Shadows",
    Desc = "Turns off scene global shadows to boost frame rate",
    Value = State.Misc.DisableShadows,
    Callback = function(val: boolean)
        State.Misc.DisableShadows = val
        Globals.DisableShadows = val
        if Settings then Settings:Set("DisableShadows", val) end
        ApplyDisableShadows(val)
        Logger:Info("Disable Dynamic Shadows: " .. (val and "ACTIVE" or "DISABLED"))
    end,
})
end

local function makeProgressBarASCII(pct: number, totalBlocks: number?): string
    local blocks = totalBlocks or 10
    local clampedPct = math.clamp(pct, 0, 100)
    local filled = math.floor((clampedPct / 100) * blocks)
    local empty = blocks - filled
    return string.rep("█", filled) .. string.rep("░", empty)
end

local function formatSessionDuration(seconds: number): (string, string)
    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local totalHoursStr = string.format("%.2f hrs", seconds / 3600)
    local clockStr = string.format("%dh %dm %ds", hrs, mins, secs)
    return clockStr, totalHoursStr
end

local function getActiveCurrencyInfo()
    local mode = "None (Idle)"
    local config = nil
    if State and State.AutoCurrency then
        if State.AutoCurrency.Coins and State.AutoCurrency.Coins.Enabled then
            mode = "Auto Coins"
            config = State.AutoCurrency.Coins
        elseif State.AutoCurrency.Gems and State.AutoCurrency.Gems.Enabled then
            mode = "Auto Gems"
            config = State.AutoCurrency.Gems
        elseif State.AutoCurrency.Levels and State.AutoCurrency.Levels.Enabled then
            mode = "Auto Levels"
            config = State.AutoCurrency.Levels
        elseif State.AutoCurrency.Timescales and State.AutoCurrency.Timescales.Enabled then
            mode = "Auto Timescales"
            config = State.AutoCurrency.Timescales
        elseif State.AutoCurrency.Evo and State.AutoCurrency.Evo.Enabled then
            mode = "Auto Evo"
            config = State.AutoCurrency.Evo
        end
    end
    return mode, config
end
--==============================================================================
-- Webhook Dispatcher
--==============================================================================
SendAutoCurrencyWebhook = function(eventTitle: string?, matchResult: string?, extraWave: any?, detailsText: string?)
    local webhookUrl = (State and State.Misc and State.Misc.WebhookUrl)
        or (Settings and Settings:Get("WebhookUrl", ""))
        or ""
    if webhookUrl == "" or not webhookUrl:find("^https?://") then
        return false, "No webhook URL configured"
    end

    local isLobby = (game.PlaceId == LOBBY_PLACE_ID)
    local activeMode, activeConfig = getActiveCurrencyInfo()
    local condition = (activeConfig and activeConfig.Condition) or "N/A"
    local isPrem = checkIsPremium()
    local planText = isPrem and "Premium" or "Free"

    local sessionStart = (getgenv and getgenv().HubSessionStartTime) or (State and State.StartTime) or tick()
    local currentSecs = math.max(0, tick() - sessionStart)
    local clockStr, totalHoursStr = formatSessionDuration(currentSecs)

    local stats = { Coins = 0, Gems = 0, Level = 0, Exp = 0 }
    if DataHandler and typeof(DataHandler.GetPlayerStats) == "function" then
        pcall(function()
            local s = DataHandler:GetPlayerStats()
            if s then
                stats.Coins = s.Coins or 0
                stats.Gems = s.Gems or 0
                stats.Level = s.Level or 0
                stats.Exp = s.Exp or 0
            end
        end)
    end

    local playerName = (LocalPlayer and LocalPlayer.Name) or "Player"
    local playerUserId = (LocalPlayer and LocalPlayer.UserId) or 0
    local nodeName = (State and State.Misc and State.Misc.NodeName)
        or (Settings and Settings:Get("NodeName", "Node 1"))
        or "Node 1"

    local sessionMatches = (getgenv and getgenv().HubSessionMatches) or 0
    local totalMatches = ((Settings and Settings:Get("TotalMatches", 0)) or 0) + sessionMatches
    local locationText = isLobby and "In Lobby" or "In Match"

    local fields = {
        {
            name = "👤 Username",
            value = string.format("`%s`", playerName),
            inline = true,
        },
        {
            name = "📌 Node:",
            value = string.format("`%s`", nodeName),
            inline = true,
        },
        {
            name = "🆔 ID",
            value = string.format("`%s`", tostring(playerUserId)),
            inline = true,
        },
        {
            name = "⭐ Plan",
            value = string.format("`%s`", planText),
            inline = true,
        },
        {
            name = "⚙️ Active Currency",
            value = string.format("`%s [%s]`", activeMode, condition),
            inline = true,
        },
        {
            name = "⏱️ Session Time",
            value = string.format("`%s (%s)`", clockStr, totalHoursStr),
            inline = true,
        },
    }

    -- Target & Progress Bar for Currency
    if activeMode == "Auto Coins" then
        local targetVal = tonumber(activeConfig and activeConfig.Target) or 0
        if targetVal > 0 then
            local pct = math.clamp(math.floor((stats.Coins / targetVal) * 100), 0, 100)
            local bar = makeProgressBarASCII(pct, 10)
            local rem = math.max(0, targetVal - stats.Coins)
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("[%s] %d%%\n*Coins: %s / %s • %s to target (Condition: %s)*",
                    bar, pct, formatNumber(stats.Coins), formatNumber(targetVal), formatNumber(rem), condition),
                inline = false,
            })
        else
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("*Coins: %s / 0 (Target: Infinite)*", formatNumber(stats.Coins)),
                inline = false,
            })
        end
    elseif activeMode == "Auto Gems" then
        local targetVal = tonumber(activeConfig and activeConfig.Target) or 0
        if targetVal > 0 then
            local pct = math.clamp(math.floor((stats.Gems / targetVal) * 100), 0, 100)
            local bar = makeProgressBarASCII(pct, 10)
            local rem = math.max(0, targetVal - stats.Gems)
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("[%s] %d%%\n*Gems: %s / %s • %s to target (Condition: %s)*",
                    bar, pct, formatNumber(stats.Gems), formatNumber(targetVal), formatNumber(rem), condition),
                inline = false,
            })
        else
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("*Gems: %s / 0 (Target: Infinite)*", formatNumber(stats.Gems)),
                inline = false,
            })
        end
    elseif activeMode == "Auto Levels" then
        local targetVal = tonumber(activeConfig and activeConfig.Target) or 0
        if targetVal > 0 then
            local pct = math.clamp(math.floor((stats.Level / targetVal) * 100), 0, 100)
            local bar = makeProgressBarASCII(pct, 10)
            local rem = math.max(0, targetVal - stats.Level)
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("[%s] %d%%\n*Level: %d / %d • %d levels to target*",
                    bar, pct, stats.Level, targetVal, rem),
                inline = false,
            })
        else
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("*Level: %d / 0 (Target: Infinite)*", stats.Level),
                inline = false,
            })
        end
    elseif activeMode == "Auto Timescales" then
        local tsCount = (DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" and DataHandler:GetTimescaleTickets()) or 0
        local targetVal = tonumber(activeConfig and activeConfig.Target) or 0
        local curTrial = (DataHandler and typeof(DataHandler.GetCurrentTrial) == "function" and DataHandler:GetCurrentTrial())
        local trialTitle = curTrial and (curTrial.Title or curTrial.Name) or "N/A"
        local fallbackChoice = (activeConfig and activeConfig.Fallback) or "Molten"
        if targetVal > 0 then
            local pct = math.clamp(math.floor((tsCount / targetVal) * 100), 0, 100)
            local bar = makeProgressBarASCII(pct, 10)
            local rem = math.max(0, targetVal - tsCount)
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("[%s] %d%%\n*Timescales: %s / %s • %s to target (Trial: %s | Fallback: %s)*",
                    bar, pct, formatNumber(tsCount), formatNumber(targetVal), formatNumber(rem), trialTitle, fallbackChoice),
                inline = false,
            })
        else
            table.insert(fields, {
                name = "📊 Target Progress",
                value = string.format("*Timescales: %s / 0 (Target: Infinite) • Current Trial: %s (Fallback: %s)*", formatNumber(tsCount), trialTitle, fallbackChoice),
                inline = false,
            })
        end
    else
        table.insert(fields, {
            name = "📊 Target Progress",
            value = "*Currently standing by (Idle)*",
            inline = false,
        })
    end

    table.insert(fields, {
        name = "🎮 Match Session Total:",
        value = string.format("`%d Matches`", sessionMatches),
        inline = true,
    })
    table.insert(fields, {
        name = "🏆 Total Matches:",
        value = string.format("`%d Matches`", totalMatches),
        inline = true,
    })
    table.insert(fields, {
        name = "📍 Current Location:",
        value = string.format("`%s`", locationText),
        inline = true,
    })
    local tsBalance = (DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" and DataHandler:GetTimescaleTickets()) or 0
    table.insert(fields, {
        name = "💰 Balances",
        value = string.format("🪙 `%s` Coins • 💎 `%s` Gems • ⌛ `%s` Timescales", formatNumber(stats.Coins), formatNumber(stats.Gems), formatNumber(tsBalance)),
        inline = false,
    })

    if matchResult then
        local resIcon = (matchResult == "WIN" or matchResult == "VICTORY") and "🏆 VICTORY" or "💀 DEFEAT"
        local waveVal = (extraWave ~= nil) and tostring(extraWave) or "N/A"
        table.insert(fields, {
            name = "🎮 Match Result",
            value = string.format("%s (Wave %s)", resIcon, waveVal),
            inline = true,
        })
    end

    table.insert(fields, {
        name = "📝 Details",
        value = string.format("`%s`", detailsText or "Currency farming loop operating normally."),
        inline = false,
    })

    local embedColor = 0x7C3AED
    if matchResult then
        if matchResult == "WIN" or matchResult == "VICTORY" then
            embedColor = 0x00FF88
        else
            embedColor = 0xFF4D4D
        end
    elseif eventTitle and eventTitle:find("Target Reached") then
        embedColor = 0xFFD700
    end

    local playerAvatarUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png", playerUserId)
    local payload = {
        embeds = {
            {
                author = {
                    name = string.format("Bogus Auto Hub [%s]", planText),
                    icon_url = playerAvatarUrl,
                },
                title = string.format("🔔 Bogus Auto Hub // %s", eventTitle or "Auto Currency Status"),
                color = embedColor,
                fields = fields,
                footer = {
                    text = string.format("Bogus Auto Hub %s • Currency Engine • %s", planText, os.date("%m/%d/%y, %I:%M %p")),
                    icon_url = playerAvatarUrl,
                },
                timestamp = DateTime.now():ToIsoDate(),
            }
        }
    }

    local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if req then
        task.spawn(function()
            pcall(function()
                req({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload),
                })
            end)
        end)
        return true
    end
    return false, "Executor does not support HTTP request API"
end

-- Backward compatibility alias
SendDiscordWebhook = function(eventTitle: string?, matchResult: string?, extraWave: any?)
    return SendAutoCurrencyWebhook(eventTitle, matchResult, extraWave)
end

--==============================================================================
-- Webhook UI Section in Misc Tab
--==============================================================================
do
local MiscWebhook = MiscTab:Section({ Title = "Discord Webhook Integration" })

MiscWebhook:Textbox({
    Title = "Webhook URL",
    Desc = "Destination Discord channel webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    ClearTextOnFocus = false,
    Value = State.Misc.WebhookUrl,
    Callback = function(url: string)
        State.Misc.WebhookUrl = url
        if Settings then Settings:Set("WebhookUrl", url) end
    end,
})

MiscWebhook:Textbox({
    Title = "Node Identifier",
    Desc = "Multi-account instance tag (e.g. Node 1, Alt 1)",
    Placeholder = "Node 1",
    ClearTextOnFocus = false,
    Value = State.Misc.NodeName or "Node 1",
    Callback = function(txt: string)
        local val = (txt ~= "" and txt) or "Node 1"
        State.Misc.NodeName = val
        if Settings then Settings:Set("NodeName", val) end
    end,
})

MiscWebhook:Toggle({
    Title = "Auto Currency Webhook Alerts",
    Desc = "Transmits session summaries, match results, and currency gain alerts",
    Value = State.Misc.WebhookAlerts,
    Callback = function(val: boolean)
        State.Misc.WebhookAlerts = val
        if Settings then Settings:Set("WebhookAlerts", val) end
    end,
})

MiscWebhook:Button({
    Title = "Send Auto Currency Webhook Test",
    Desc = "Dispatches the full Auto Currency farming preview embed to Discord",
    Image = "Discord",
    Callback = function()
        if State.Misc.WebhookUrl == "" then
            Window:Notify({ Title = "Webhook Error", Desc = "Please enter a valid webhook URL first.", Duration = 2 })
            return
        end
        local ok, err = SendAutoCurrencyWebhook("Webhook Test Connected", nil, nil, "Discord currency webhook successfully configured!")
        if ok then
            Window:Notify({ Title = "Webhook Sent", Desc = "Auto Currency embed delivered successfully!", Duration = 2.5 })
            Logger:Success("Auto Currency webhook test delivered to Discord.")
        else
            Window:Notify({ Title = "Webhook Failed", Desc = tostring(err or "Unable to send HTTP request."), Duration = 2.5 })
        end
    end,
})
end

-- Periodic Webhook Dispatcher Worker (every 5 minutes)
task.spawn(function()
    while true do
        task.wait(300)
        if State.Master and State.Misc.WebhookUrl ~= "" then
            if State.Misc.WebhookAlerts and SendAutoCurrencyWebhook then
                local activeMode = getActiveCurrencyInfo()
                if activeMode ~= "None (Idle)" then
                    pcall(function()
                        SendAutoCurrencyWebhook("Periodic Currency Update", nil, nil, "Actively farming " .. activeMode .. " queue.")
                    end)
                end
            end
        end
    end
end)

do
local MiscUI = MiscTab:Section({ Title = "Hub Customization" })

MiscUI:Dropdown({
    Title = "Glassmorphic Theme",
    Desc = "Instantly shift the accent color scheme and glass tint",
    List = { "LightGray", "SkyBlue", "DeepAzure", "MidnightEmerald", "CrimsonEclipse", "SolarAmber" },
    Value = State.Misc.SelectedTheme or "LightGray",
    Callback = function(themeName: string)
        Window:SetTheme(themeName)
        if Settings then Settings:Set("SelectedTheme", themeName) end
        Logger:Info("Theme shifted to: " .. themeName)
    end,
})

MiscUI:Keybind({
    Title = "Toggle Menu Keybind",
    Desc = "Press to hide or reveal the main interface",
    Value = Enum.KeyCode.RightControl,
    Callback = function(kc: Enum.KeyCode)
        Window.Keybind = kc
        Logger:Info("Keybind updated to: " .. kc.Name)
    end,
})

MiscUI:Button({
    Title = "Unload Hub Cleanly",
    Desc = "Stops all automation loops and removes the UI from screen",
    Image = "Close",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Unload",
            Content = "Are you sure you want to unload SomethingNew Hub?",
            ConfirmText = "Unload Now",
            Danger = true,
            OnConfirm = function()
                State.Master = false
                pcall(function()
                    RunService:Set3dRenderingEnabled(true)
                end)
                if Window.ScreenGui then
                    Window.ScreenGui:Destroy()
                end
            end,
        })
    end,
})
end

--==============================================================================
-- 9. Background Workers & Automation Loops
--==============================================================================

-- 9.1 Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if State.Misc.InfiniteJump then
        local char = LocalPlayer and LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- 9.2 Bulletproof Multi-Layer Anti-AFK System
local function setupAntiAFK()
    if not LocalPlayer then return end

    -- Layer 1: Reactive Idled Signal Interceptor
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            if State.Misc.AntiAFK then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
                Logger:Info("Anti-AFK: Kept connection alive via Idled trigger.")
            end
        end)
    end)

    -- Layer 2: Disable Roblox Internal Disconnect Hook (if executor supports getconnections)
    pcall(function()
        if type(getconnections) == "function" then
            for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
                if conn and typeof(conn) == "RBXScriptConnection" and conn ~= nil then
                    -- Keep our own script connection alive, disable native Roblox engine kicks
                elseif conn and conn.Disable then
                    conn:Disable()
                end
            end
        end
    end)

    -- Layer 3: Proactive 10-Minute Virtual Heartbeat (preempts 20-min AFK timer completely)
    task.spawn(function()
        while true do
            task.wait(600)
            if State and State.Misc and State.Misc.AntiAFK then
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    if vu then
                        vu:CaptureController()
                        vu:ClickButton2(Vector2.new(0, 0))
                    end
                end)
            end
        end
    end)
end

setupAntiAFK()

-- 9.3 Character Spawn Listener (re-apply speed/jump)
local function onCharacter(char: Model)
    local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
    if hum then
        if State.Misc.WalkSpeed ~= 16 then
            hum.WalkSpeed = State.Misc.WalkSpeed
        end
        if State.Misc.JumpPower ~= 50 then
            hum.JumpPower = State.Misc.JumpPower
        end
    end
end

if LocalPlayer then
    if LocalPlayer.Character then
        task.spawn(onCharacter, LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacter)
end

-- 9.4 Real-time Runtime & Stats Update Loop (1 Hz)
task.spawn(function()
    while true do
        task.wait(1)
        if Window.ScreenGui and Window.ScreenGui.Parent then
            local elapsed = os.time() - State.StartTime
            StatsGrid:UpdateItem(2, formatDuration(elapsed), "Runtime")
            
            -- Estimate rate
            local minutes = math.max(elapsed / 60, 0.1)
            local ratePerMin = math.floor(State.CurrencyGained / minutes)
            StatsGrid:UpdateItem(6, "+" .. tostring(State.CurrencyGained), string.format("+%d/min", ratePerMin))
            
            -- Live Trial Countdowns (1 Hz Real-time update)
            if currentTrialLabelRef and currentTrialLabelRef.SetDesc then
                pcall(function()
                    currentTrialLabelRef:SetDesc(getCurrentTrialDisplayText())
                end)
            end
            if nextTrialLabelRef and nextTrialLabelRef.SetDesc then
                pcall(function()
                    nextTrialLabelRef:SetDesc(getNextTrialDisplayText())
                end)
            end

            -- If trial rotation changes/expires, dynamically refresh eligibility text
            if PlayerDataHandler and typeof(PlayerDataHandler.GetCurrentTrial) == "function" then
                pcall(function()
                    local cur = PlayerDataHandler:GetCurrentTrial()
                    local curTitle = cur and (cur.Title or cur.Name)
                    if curTitle and curTitle ~= lastObservedTrialTitle then
                        lastObservedTrialTitle = curTitle
                        if trialEligibilityLabelRef and trialEligibilityLabelRef.SetDesc then
                            trialEligibilityLabelRef:SetDesc(getTrialEligibilityDisplayText())
                        end
                    end
                end)
            end
        else
            break
        end
    end
end)

-- 9.4b Active Watchdog for Live Player Data & Inventory Reactivity (Fallback Monitor)
task.spawn(function()
    while true do
        task.wait(1.5)
        if Window.ScreenGui and Window.ScreenGui.Parent then
            if DataHandler then
                local ok, stats = pcall(function() return DataHandler:GetPlayerStats() end)
                if ok and type(stats) == "table" and lastLiveStats then
                    if (stats.Coins ~= nil and stats.Coins ~= lastLiveStats.Coins)
                        or (stats.Gems ~= nil and stats.Gems ~= lastLiveStats.Gems)
                        or (stats.Level ~= nil and stats.Level ~= lastLiveStats.Level)
                        or (stats.Exp ~= nil and stats.Exp ~= lastLiveStats.Exp)
                        or (stats.ExpDisplay ~= nil and stats.ExpDisplay ~= lastLiveStats.ExpDisplay) then

                        lastLiveStats.Coins = stats.Coins
                        lastLiveStats.Gems = stats.Gems
                        lastLiveStats.Level = stats.Level
                        lastLiveStats.Exp = stats.Exp
                        lastLiveStats.ExpDisplay = stats.ExpDisplay

                        if refreshLiveOverview then
                            refreshLiveOverview()
                        end
                        if refreshCurrencyBox then
                            refreshCurrencyBox()
                        end
                    end
                end
            end
        else
            break
        end
    end
end)

-- 9.6 Auto Currency TDS Game Mechanics Worker
;(function()
    local isCurrencyMatchmaking = false
local lastCurrencyMatchmakingTime = 0
local activeInGameCurrencyLoop = false
local timescalesConsecutiveLosses = 0

local function GetMatchStatus(): string?
    local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
    local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
    if gsr and gsr:GetAttribute("GameOver") == true then
        local rawHealth = gsr:GetAttribute("Health")
        if rawHealth == nil then
            rawHealth = workspace:GetAttribute("Health")
        end
        local health = tonumber(rawHealth) or 0
        if health > 0 then
            return "WIN"
        else
            return "LOSS"
        end
    end
    return nil
end

local function triggerRematchVote(): boolean
    local fired = false
    -- 1. Direct GameManager RE:Rematch
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Network")
        local gm = net and net:FindFirstChild("GameManager")
        local reMatch = gm and gm:FindFirstChild("RE:Rematch")
        if reMatch then
            if reMatch:IsA("RemoteEvent") or reMatch:IsA("UnreliableRemoteEvent") then
                reMatch:FireServer()
                fired = true
            elseif reMatch:IsA("RemoteFunction") then
                reMatch:InvokeServer()
                fired = true
            end
        end
    end)

    -- 2. Scan ReplicatedStorage recursively for any Rematch remote
    pcall(function()
        local alt = ReplicatedStorage:FindFirstChild("RE:Rematch", true)
            or ReplicatedStorage:FindFirstChild("Rematch", true)
        if alt then
            if alt:IsA("RemoteEvent") or alt:IsA("UnreliableRemoteEvent") then
                alt:FireServer()
                fired = true
            elseif alt:IsA("RemoteFunction") then
                alt:InvokeServer()
                fired = true
            end
        end
    end)

    -- 3. Click GUI PlayAgain / Retry / Rematch buttons
    pcall(function()
        local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
        if not pg then return end
        local guis = {
            pg:FindFirstChild("ReactGameNewRewards"),
            pg:FindFirstChild("GameOver"),
            pg:FindFirstChild("GameOverScreen"),
            pg:FindFirstChild("ReactGameOver"),
        }
        for _, gui in ipairs(guis) do
            if gui then
                for _, name in ipairs({ "PlayAgain", "Retry", "Restart", "Rematch" }) do
                    local elem = gui:FindFirstChild(name, true)
                    if elem then
                        local btn = elem:FindFirstChild("button")
                            or elem:FindFirstChildOfClass("ImageButton")
                            or elem:FindFirstChildOfClass("TextButton")
                            or (elem:IsA("GuiButton") and elem)
                        if btn then
                            if getconnections then
                                for _, conn in ipairs(getconnections(btn.Activated)) do pcall(conn.Fire, conn); fired = true end
                                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do pcall(conn.Fire, conn); fired = true end
                            end
                            if firesignal then
                                pcall(firesignal, btn.Activated)
                                pcall(firesignal, btn.MouseButton1Click)
                                fired = true
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 4. Invoke RemoteFunction voting commands
    pcall(function()
        local rf = ReplicatedStorage:FindFirstChild("RemoteFunction")
        if rf and rf:IsA("RemoteFunction") then
            pcall(function() rf:InvokeServer("Voting", "Rematch") end)
            pcall(function() rf:InvokeServer("Voting", "Retry") end)
            pcall(function() rf:InvokeServer("Voting", "Restart") end)
            pcall(function() rf:InvokeServer("Voting", "Skip") end)
            fired = true
        end
    end)

    return fired
end

local function fireSkipVoteUntilTrue()
    local Event = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction")
    if not Event then return false end

    local success, result = pcall(function()
        local Result = table.pack(Event:InvokeServer(
            "Voting",
            "Skip"
        ))

        local ExpectedResult = table.unpack({
            true
        })

        return Result[1] == ExpectedResult
    end)

    return success and (result == true)
end

local function functionRestartLogic(): boolean
    local fired = false
    pcall(fireSkipVoteUntilTrue)
    pcall(function()
        local rf = ReplicatedStorage:FindFirstChild("RemoteFunction")
        if rf and rf:IsA("RemoteFunction") then
            pcall(function() rf:InvokeServer("Voting", "Restart") end)
            pcall(function() rf:InvokeServer("Voting", "Retry") end)
            pcall(function() rf:InvokeServer("Voting", "Skip") end)
            fired = true
        end
    end)
    pcall(function()
        local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
        if not pg then return end
        local guis = {
            pg:FindFirstChild("ReactGameNewRewards"),
            pg:FindFirstChild("GameOver"),
            pg:FindFirstChild("GameOverScreen"),
            pg:FindFirstChild("ReactGameOver"),
        }
        for _, gui in ipairs(guis) do
            if gui then
                for _, name in ipairs({ "Restart", "Retry", "PlayAgain", "Vote" }) do
                    local elem = gui:FindFirstChild(name, true)
                    if elem then
                        local btn = elem:FindFirstChild("button")
                            or elem:FindFirstChildOfClass("ImageButton")
                            or elem:FindFirstChildOfClass("TextButton")
                            or (elem:IsA("GuiButton") and elem)
                        if btn then
                            if getconnections then
                                for _, conn in ipairs(getconnections(btn.Activated)) do pcall(conn.Fire, conn); fired = true end
                                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do pcall(conn.Fire, conn); fired = true end
                            end
                            if firesignal then
                                pcall(firesignal, btn.Activated)
                                pcall(firesignal, btn.MouseButton1Click)
                                fired = true
                            end
                        end
                    end
                end
            end
        end
    end)
    return fired
end

local function functionWinLogic(mode: string, isTrials: boolean, isPrem: boolean): boolean
    warn("══════════════════════════════════════════════════════════════════════")
    warn(string.format(">>> [WIN LOGIC CONFIRMED: VICTORY] <<< Mode: %s | Trials: %s | Premium: %s", tostring(mode), tostring(isTrials), tostring(isPrem)))
    warn("══════════════════════════════════════════════════════════════════════")
    Logger:Info(string.format("Auto Currency: Executing custom WinLogic (Mode: %s, isTrials: %s, isPremium: %s)...", tostring(mode), tostring(isTrials), tostring(isPrem)))
    if isTrials and isPrem then
        -- Timescales Premium Win: Reset loss counter, dispatch Rematch
        timescalesConsecutiveLosses = 0
        isTeleporting = false
        local fired = triggerRematchVote()
        warn(string.format("[Auto Trials] Premium Consecutive Rematch Dispatched (RE:Rematch, fired=%s)", tostring(fired)))
        Logger:Info("Auto Timescales (Premium): Rematch vote dispatched (fired=" .. tostring(fired) .. ")")
        return true
    else
        -- Coins, Gems, Levels, or Timescales Fallback: Teleport to lobby via smartLobby
        warn(string.format("[Win Logic] Victory registered for %s! Returning to lobby via smartLobby...", tostring(mode)))
        Logger:Info(string.format("Auto Currency: Win confirmed for %s. Returning to lobby via smartLobby...", tostring(mode)))
        pcall(SmartTeleportToLobby)
        return false
    end
end

local function parseTargetVal(v: any): number
    if v == nil then return 0 end
    if typeof(v) == "number" then return v end
    local str = tostring(v):gsub(",", ""):gsub("%s+", ""):lower()
    if str == "" then return 0 end

    local mult = 1
    if str:sub(-1) == "k" then
        mult = 1000
        str = str:sub(1, -2)
    elseif str:sub(-1) == "m" then
        mult = 1000000
        str = str:sub(1, -2)
    elseif str:sub(-1) == "b" then
        mult = 1000000000
        str = str:sub(1, -2)
    end

    local num = tonumber(str)
    if num then
        return num * mult
    end
    return 0
end

local function isTargetReached(mode: string, targetVal: number, stats: any): boolean
    if not stats or targetVal <= 0 then return false end
    if mode == "Coins" then
        return (stats.Coins or 0) >= targetVal
    elseif mode == "Gems" then
        return (stats.Gems or 0) >= targetVal
    elseif mode == "Levels" then
        if targetVal <= 5000 then
            return (stats.Level or 0) >= targetVal
        else
            return (stats.Exp or 0) >= targetVal or (stats.Level or 0) >= targetVal
        end
    elseif mode == "Timescales" then
        local tickets = stats.TimescaleTickets
        if tickets == nil and DataHandler and typeof(DataHandler.GetTimescaleTickets) == "function" then
            tickets = DataHandler:GetTimescaleTickets()
        end
        return (tickets or 0) >= targetVal
    end
    return false
end

local function triggerCurrencyQueue(modeKey: string, optConfig: any)
    if game.PlaceId ~= LOBBY_PLACE_ID then return end

    -- Check if selected strategy requires Premium plan
    local currentStrat = selectedStrat or (State.StrategyManager and State.StrategyManager.selectedStrat) or Globals.selectedStrat
    if currentStrat and currentStrat ~= "" and not checkIsPremium() then
        local recordedItems = getSavedRecordedStrategyItems()
        for _, it in ipairs(recordedItems) do
            if it.Name == currentStrat and it.IsPremium then
                Logger:Warn("Auto Currency: Matchmaking queue blocked! Selected strategy '" .. currentStrat .. "' requires Premium.")
                Window:Notify({
                    Title = "Premium Plan Required",
                    Desc = "THis strat required premium! turn off the auto exec and never que them also",
                    Duration = 4,
                    Type = "error",
                })
                return
            end
        end
    end

    if os.time() - lastCurrencyMatchmakingTime < 4 then return end
    lastCurrencyMatchmakingTime = os.time()

    local remote = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if not (remote and remote:IsA("RemoteFunction")) then return end

    pcall(function()
        remote:InvokeServer("Multiplayer", "v2:stop")
    end)
    task.wait(0.2)

    local targetMode = optConfig and (optConfig.Mode or optConfig.mode)
    local lowMode = targetMode and targetMode:lower() or "molten"
    local payload = nil
    if modeKey == "Timescales" then
        if optConfig and optConfig.isEligible then
            payload = {
                count = 1,
                mode = "Trials"
            }
        else
            local fb = (optConfig and optConfig.Fallback) or "Molten"
            if fb ~= "Molten" and fb ~= "Fallen" then fb = "Molten" end
            payload = {
                count = 1,
                mode = "survival",
                difficulty = fb
            }
        end
    elseif modeKey == "Gems" or lowMode == "hardcore" then
        payload = {
            difficulty = "Easy",
            mode = "hardcore",
            count = 1
        }
    elseif lowMode == "casual" then
        payload = {
            difficulty = "Casual",
            mode = "survival",
            count = 1
        }
    elseif lowMode == "intermediate" then
        payload = {
            difficulty = "Intermediate",
            mode = "survival",
            count = 1
        }
    elseif lowMode == "fallen" then
        payload = {
            difficulty = "Fallen",
            mode = "survival",
            count = 1
        }
    else
        payload = {
            difficulty = "Molten",
            mode = "survival",
            count = 1
        }
    end

    pcall(function()
        remote:InvokeServer("Multiplayer", "v2:start", payload)
        Logger:Info(string.format("Auto Currency: Queued %s match (%s - %s).", modeKey, payload.mode, tostring(payload.difficulty or "Trials")))
    end)
end

local function enforceCurrencyTierRules()
    if not checkIsPremium() then
        -- 1. Coins: Auto switch Win to Lose
        if State.AutoCurrency and State.AutoCurrency.Coins and State.AutoCurrency.Coins.Condition == "Win" then
            State.AutoCurrency.Coins.Condition = "Lose"
            if Settings then Settings:Set("AutoCoinsCondition", "Lose") end
            task.spawn(function()
                if coinsDropdownRef and type(coinsDropdownRef.SetValue) == "function" then
                    coinsDropdownRef:SetValue("Lose")
                end
            end)
            Window:Notify({
                Title = "Premium Expired",
                Desc = "Auto Coins condition downgraded to Free Tier mode (Lose).",
                Duration = 5,
            })
            Logger:Warn("Auto Coins: Premium expired. Condition automatically switched to Free Tier mode (Lose).")
            if missingCoinsLabel then
                pcall(function()
                    local txt = getMissingTowersText("Coins", "Lose")
                    if missingCoinsLabel.SetDesc then missingCoinsLabel:SetDesc(txt) end
                    if missingCoinsLabel.SetText then missingCoinsLabel:SetText(txt) end
                end)
            end
        end

        -- 2. Gems: Auto switch Win to Lose
        if State.AutoCurrency and State.AutoCurrency.Gems and State.AutoCurrency.Gems.Condition == "Win" then
            State.AutoCurrency.Gems.Condition = "Lose"
            if Settings then Settings:Set("AutoGemsCondition", "Lose") end
            task.spawn(function()
                if gemsDropdownRef and type(gemsDropdownRef.SetValue) == "function" then
                    gemsDropdownRef:SetValue("Lose")
                end
            end)
            Window:Notify({
                Title = "Premium Expired",
                Desc = "Auto Gems condition downgraded to Free Tier mode (Lose).",
                Duration = 5,
            })
            Logger:Warn("Auto Gems: Premium expired. Condition automatically switched to Free Tier mode (Lose).")
            if missingGemsLabel then
                pcall(function()
                    local txt = getMissingTowersText("Gems", "Lose")
                    if missingGemsLabel.SetDesc then missingGemsLabel:SetDesc(txt) end
                    if missingGemsLabel.SetText then missingGemsLabel:SetText(txt) end
                end)
            end
        end

        -- 3. Levels: Auto switch Win to Lose
        if State.AutoCurrency and State.AutoCurrency.Levels and State.AutoCurrency.Levels.Condition == "Win" then
            State.AutoCurrency.Levels.Condition = "Lose"
            if Settings then Settings:Set("AutoLevelsCondition", "Lose") end
            task.spawn(function()
                if levelsDropdownRef and type(levelsDropdownRef.SetValue) == "function" then
                    levelsDropdownRef:SetValue("Lose")
                end
            end)
            Window:Notify({
                Title = "Premium Expired",
                Desc = "Auto Levels condition downgraded to Free Tier mode (Lose).",
                Duration = 5,
            })
            Logger:Warn("Auto Levels: Premium expired. Condition automatically switched to Free Tier mode (Lose).")
            if missingLevelsLabel then
                pcall(function()
                    local txt = getMissingTowersText("Levels", "Lose")
                    if missingLevelsLabel.SetDesc then missingLevelsLabel:SetDesc(txt) end
                    if missingLevelsLabel.SetText then missingLevelsLabel:SetText(txt) end
                end)
            end
        end

        -- 4. Timescales target: Reset to 0 for Free Tier (Premium feature)
        if State.AutoCurrency and State.AutoCurrency.Timescales then
            local tsTarget = parseTargetVal(State.AutoCurrency.Timescales.Target)
            if tsTarget > 0 then
                State.AutoCurrency.Timescales.Target = "0"
                if Settings then Settings:Set("AutoTimescalesTarget", "0") end
                task.spawn(function()
                    if timescalesTextboxRef and type(timescalesTextboxRef.SetValue) == "function" then
                        timescalesTextboxRef:SetValue("0")
                    end
                end)
            end
        end

        -- 5. Auto Evo: Disabled for Free Tier
        if State.AutoCurrency and State.AutoCurrency.Evo and State.AutoCurrency.Evo.Enabled then
            State.AutoCurrency.Evo.Enabled = false
            if Settings then Settings:Set("AutoEvoEnabled", false) end
            task.spawn(function()
                if evoToggleRef and type(evoToggleRef.SetValue) == "function" then
                    evoToggleRef:SetValue(false)
                end
            end)
            refreshCurrencyBox()
        end
    end
end

-- Supervisor loop for Lobby and In-Game Auto Currency routines
task.spawn(function()
    while true do
        task.wait(1.5)
        enforceCurrencyTierRules()
        if not State.Master then continue end

        local activeMode = nil
        local activeConfig = nil

        if State.AutoProgress and State.AutoProgress.Enabled then
            activeMode = "Progress"
            activeConfig = { Mode = "Progress", Condition = "Win" }
        elseif State.AutoCurrency.Coins.Enabled then
            activeMode = "Coins"
            activeConfig = State.AutoCurrency.Coins
        elseif State.AutoCurrency.Gems.Enabled then
            activeMode = "Gems"
            activeConfig = State.AutoCurrency.Gems
        elseif State.AutoCurrency.Levels.Enabled then
            activeMode = "Levels"
            activeConfig = State.AutoCurrency.Levels
        elseif State.AutoCurrency.Timescales.Enabled then
            activeMode = "Timescales"
            activeConfig = State.AutoCurrency.Timescales
        elseif State.AutoCurrency.Evo and State.AutoCurrency.Evo.Enabled then
            activeMode = "Evo"
            activeConfig = State.AutoCurrency.Evo
        end

        if not activeMode then
            activeInGameCurrencyLoop = false
            continue
        end

        local isLobby = (game.PlaceId == LOBBY_PLACE_ID)

        -- Check target limit threshold (Lobby only)
        if isLobby then
            local targetVal = parseTargetVal(activeConfig.Target)
            if targetVal > 0 and DataHandler then
                local stats = DataHandler:GetPlayerStats()
                -- Wait until player stats have actually loaded before evaluating
                if not stats or ((stats.Level or 0) <= 0 and (stats.Coins or 0) <= 0 and (stats.Gems or 0) <= 0) then
                    continue
                end

                if isTargetReached(activeMode, targetVal, stats) then
                    activeConfig.Enabled = false
                    if State.AutoCurrency and State.AutoCurrency[activeMode] then
                        State.AutoCurrency[activeMode].Enabled = false
                        State.AutoCurrency[activeMode].Target = "0"
                    end
                    activeConfig.Target = "0"
                    if Settings then
                        Settings:Set("Auto" .. activeMode .. "Enabled", false, true)
                        Settings:Set("Auto" .. activeMode .. "Target", "0", true)
                    end
                    SaveSettings(true)

                    if activeMode == "Coins" and coinsToggleRef then pcall(function() coinsToggleRef:SetValue(false) end)
                    elseif activeMode == "Gems" and gemsToggleRef then pcall(function() gemsToggleRef:SetValue(false) end)
                    elseif activeMode == "Levels" and levelsToggleRef then pcall(function() levelsToggleRef:SetValue(false) end)
                    elseif activeMode == "Timescales" and timescalesToggleRef then pcall(function() timescalesToggleRef:SetValue(false) end)
                    end

                    if activeMode == "Coins" and coinsTextboxRef then pcall(function() coinsTextboxRef:SetValue("0") end)
                    elseif activeMode == "Gems" and gemsTextboxRef then pcall(function() gemsTextboxRef:SetValue("0") end)
                    elseif activeMode == "Levels" and levelsTextboxRef then pcall(function() levelsTextboxRef:SetValue("0") end)
                    elseif activeMode == "Timescales" and timescalesTextboxRef then pcall(function() timescalesTextboxRef:SetValue("0") end)
                    end

                    refreshCurrencyBox()

                    if State.Misc.WebhookAlerts and State.Misc.WebhookUrl ~= "" and SendAutoCurrencyWebhook then
                        pcall(function()
                            SendAutoCurrencyWebhook(string.format("%s Target Reached!", activeMode), nil, nil, "Target goal reached in lobby! Toggle disabled.")
                        end)
                    end

                    Window:Notify({
                        Title = "Target Reached",
                        Desc = string.format("Auto %s target reached (%s). Target reset to 0.", activeMode, tostring(targetVal)),
                        Duration = 6
                    })
                    continue
                end
            end
        end
        if isLobby then
            activeInGameCurrencyLoop = false
            timescalesConsecutiveLosses = 0
            local attrLoading = LocalPlayer and LocalPlayer:GetAttribute("Loading") == true
            local attrTeleporting = LocalPlayer and LocalPlayer:GetAttribute("Teleporting") == true

            if not attrLoading and not attrTeleporting then
                if activeMode == "Progress" then
                    local nodeInfo = getAutoProgressNodeInfo and getAutoProgressNodeInfo()
                    if nodeInfo and nodeInfo.isComplete then
                        State.AutoProgress.Enabled = false
                        Globals.AutoProgressEnabled = false
                        if Settings then Settings:Set("AutoProgressEnabled", false) end
                        SaveSettings(true)
                        if progToggleRef and typeof(progToggleRef.SetValue) == "function" then
                            pcall(function() progToggleRef:SetValue(false) end)
                        end
                        if refreshAutoProgUI then refreshAutoProgUI() end
                        Window:Notify({
                            Title = "All Nodes Reached!",
                            Desc = "You already reached all nodes! Auto Progress has been turned off.",
                            Duration = 8,
                        })
                        continue
                    end

                    if nodeInfo and os.time() - lastCurrencyMatchmakingTime > 4 then
                        lastCurrencyMatchmakingTime = os.time()

                        -- Buy missing towers if any
                        if nodeInfo.towersToBuy and #nodeInfo.towersToBuy > 0 and typeof(attemptBuyMissingTowersList) == "function" then
                            attemptBuyMissingTowersList(nodeInfo.towersToBuy)
                        end

                        -- Equip required towers
                        if nodeInfo.towersToEquip and #nodeInfo.towersToEquip > 0 and TDS and typeof(TDS.Loadout) == "function" then
                            pcall(function() TDS:Loadout(unpack(nodeInfo.towersToEquip)) end)
                        end

                        local remote = ReplicatedStorage:FindFirstChild("RemoteFunction")
                        if remote and remote:IsA("RemoteFunction") then
                            pcall(function() remote:InvokeServer("Multiplayer", "v2:stop") end)
                            task.wait(0.2)

                            if nodeInfo.nodeNum == 0 then
                                -- Story Mode queue
                                remote:InvokeServer("Multiplayer", "v2:start", {
                                    mode = "story",
                                    count = 1,
                                    story = {
                                        chapter = 0,
                                        mission = nodeInfo.nextMissionNum or 1
                                    }
                                })
                                Logger:Info(string.format("Auto Progress: Queued Story Chapter 0 Mission %d (%s).", nodeInfo.nextMissionNum or 1, tostring(nodeInfo.nextMissionName or "Boot Camp")))
                            elseif nodeInfo.nodeNum == 1 then
                                -- Node 1: Casual (Easy) survival
                                remote:InvokeServer("Multiplayer", "v2:start", {
                                    mode = "survival",
                                    difficulty = "Casual",
                                    count = 1
                                })
                                Logger:Info("Auto Progress: Queued Node 1 Casual match.")
                            elseif nodeInfo.nodeNum == 2 then
                                -- Node 2: Molten survival
                                remote:InvokeServer("Multiplayer", "v2:start", {
                                    mode = "survival",
                                    difficulty = "Molten",
                                    count = 1
                                })
                                Logger:Info("Auto Progress: Queued Node 2 Molten match.")
                            end
                        end
                    end
                elseif activeMode == "Evo" then
                    local evoAnalysis = AutoEvoModule.AnalyzeRequirements()
                    if evoAnalysis.allFinished then
                        State.AutoCurrency.Evo.Enabled = false
                        if Settings then Settings:Set("AutoEvoEnabled", false) end
                        if evoToggleRef and typeof(evoToggleRef.SetValue) == "function" then
                            pcall(function() evoToggleRef:SetValue(false) end)
                        end
                        refreshCurrencyBox()
                        Window:Notify({
                            Title = "Auto Evo Complete",
                            Desc = "All target evolutions are fully leveled (Max Level 20)!",
                            Duration = 6,
                        })
                        Logger:Success("Auto Evo: All target evolutions are complete!")
                        task.wait(2)
                        continue
                    end

                    if evoAnalysis.readyToBuy then
                        if evoAnalysis.activeTower then
                            local evoInfo = AutoEvoModule.EvoData[evoAnalysis.activeTower]
                            local evoTargetName = evoInfo and evoInfo.Evo or evoAnalysis.activeTower
                            AutoEvoModule.AttemptPurchase(evoAnalysis.activeTower, evoTargetName)
                        end
                        task.wait(3)
                        refreshCurrencyBox()
                        continue
                    end

                    if not evoAnalysis.isEligible then
                        if os.time() - lastCurrencyMatchmakingTime > 15 then
                            lastCurrencyMatchmakingTime = os.time()
                            Logger:Warn("Auto Evo: Missing requirements: " .. table.concat(evoAnalysis.missingParts, " | "))
                        end
                    else
                        triggerCurrencyQueue("Evo", evoAnalysis.config)
                    end
                elseif activeMode == "Timescales" then
                    local curTrial = (DataHandler and typeof(DataHandler.GetCurrentTrial) == "function" and DataHandler:GetCurrentTrial())
                    local trialTitle = curTrial and (curTrial.Title or curTrial.Name)
                    local isEligible, reason, loadout, loadoutKey = false, "No active trial detected", nil, nil
                    if trialTitle then
                        isEligible, reason, loadout, loadoutKey = checkTrialEligibility(trialTitle)
                    end

                    -- Check ignored dropdown list
                    local ignoredTrials = activeConfig.IgnoredTrials or { "Glass", "Committed", "Limitation" }
                    if trialTitle then
                        local normTitle = string.lower(tostring(trialTitle)):gsub("%s+", "")
                        for _, ign in ipairs(ignoredTrials) do
                            if string.lower(tostring(ign)):gsub("%s+", "") == normTitle or string.find(normTitle, string.lower(tostring(ign)):gsub("%s+", ""), 1, true) then
                                isEligible = false
                                reason = "Ignored by filter (" .. tostring(trialTitle) .. ")"
                                break
                            end
                        end
                    end

                    if isEligible then
                        triggerCurrencyQueue("Timescales", { isEligible = true, Trial = trialTitle })
                    else
                        -- Fallback mode for ineligible or ignored trial
                        local fallbackDiff = activeConfig.Fallback or "Molten"
                        if fallbackDiff ~= "Molten" and fallbackDiff ~= "Fallen" then
                            fallbackDiff = "Molten"
                        end
                        if os.time() - lastCurrencyMatchmakingTime > 15 then
                            lastCurrencyMatchmakingTime = os.time()
                            Logger:Info(string.format("Auto Timescales (Premium): Active trial '%s' ineligible/ignored (%s). Queuing Fallback mode (%s)...", tostring(trialTitle or "None"), tostring(reason), fallbackDiff))
                        end
                        triggerCurrencyQueue("Timescales", { isEligible = false, Fallback = fallbackDiff })
                    end
                else
                    -- Check eligibility before queueing (only for selected Lose or Win condition)
                    local isPrem = checkIsPremium()
                    local condition = activeConfig.Condition or "Lose"
                    if not isPrem and (condition == "Win" or condition == "Win Only") then
                        condition = "Lose"
                        activeConfig.Condition = "Lose"
                    end
                    local stratChoice = (condition == "Win" or condition == "Win Only") and "Win" or "Lose"

                    -- In lobby: Attempt to purchase missing towers if configured for this currency mode
                    local checker = AutoCurrencyChecker(activeMode, stratChoice)
                    if checker and checker.config then
                        local toBuy = checker.config.TowersToBuy or checker.config.TowerToBuy
                        if toBuy and type(toBuy) == "table" and #toBuy > 0 then
                            local missingToBuy = {}
                            for _, t in ipairs(toBuy) do
                                if t and t ~= "" and PlayerDataHandler and typeof(PlayerDataHandler.IsTowerOwned) == "function" and not PlayerDataHandler:IsTowerOwned(t) then
                                    table.insert(missingToBuy, t)
                                end
                            end
                            if #missingToBuy > 0 and typeof(attemptBuyMissingTowersList) == "function" then
                                attemptBuyMissingTowersList(missingToBuy)
                                checker = AutoCurrencyChecker(activeMode, stratChoice)
                            end
                        end
                    end
                    if checker and checker.missingTowers and #checker.missingTowers > 0 and typeof(attemptBuyMissingTowersList) == "function" then
                        attemptBuyMissingTowersList(checker.missingTowers)
                        checker = AutoCurrencyChecker(activeMode, stratChoice)
                    end

                    if not checker.isEligible then
                        -- Not eligible, log once in a while and don't queue
                        if os.time() - lastCurrencyMatchmakingTime > 15 then
                            lastCurrencyMatchmakingTime = os.time()
                            Logger:Warn(string.format("Auto %s: Missing requirements: %s", activeMode, table.concat(checker.missingParts, " | ")))
                        end
                    else
                        -- Queue matchmaking if not already teleporting or loading
                        triggerCurrencyQueue(activeMode, checker.config)
                    end
                end
            end
        else
            -- In-Game Match Routine
            if not activeInGameCurrencyLoop then
                activeInGameCurrencyLoop = true
                task.spawn(function()
                    Logger:Info(string.format("Auto Currency: In-game match detected for %s. Initializing workflow...", activeMode))
                    if isStackerActive and isStackerActive() and applyStackerHooks then
                        applyStackerHooks()
                    end

                    local TDS = loadTDSAPI()
                    local isTrialsMatch = false
                    local gsrGlobalTrial = nil
                    if activeMode == "Timescales" then
                        -- Check if this is a Trials match or Fallback match
                        local reps = ReplicatedStorage:FindFirstChild("StateReplicators")
                        local ts = reps and reps:FindFirstChild("TrialsStateReplicator")
                        local wsMode = workspace:GetAttribute("Mode")
                        local gsr = reps and reps:FindFirstChild("GameStateReplicator")
                        local gsrMode = gsr and gsr:GetAttribute("Mode")
                        local gsrDifficulty = gsr and gsr:GetAttribute("Difficulty")
                        gsrGlobalTrial = gsr and gsr:GetAttribute("GlobalTrial")

                        if gsrDifficulty == "Fallen" or gsrDifficulty == "Molten" or wsMode == "survival" or gsrMode == "survival" then
                            isTrialsMatch = false
                        elseif ts ~= nil or wsMode == "Trials" or gsrMode == "Trials" or gsrDifficulty == "Trial" or (gsr and gsr:GetAttribute("ChallengeMap") == true) then
                            isTrialsMatch = true
                        else
                            isTrialsMatch = false
                        end
                    end

                    local isPrem = checkIsPremium()
                    local condition = activeConfig.Condition or "Lose"
                    if activeMode == "Timescales" then
                        if isTrialsMatch then
                            condition = "Win"
                        else
                            local fallbackChoice = activeConfig.Fallback or "Molten"
                            condition = (fallbackChoice == "Fallen") and "Win" or "Lose"
                        end
                    elseif activeMode == "Evo" then
                        local evoAnalysis = AutoEvoModule.AnalyzeRequirements()
                        condition = evoAnalysis.stratChoice or "Lose"
                    else
                        if not isPrem and (condition == "Win" or condition == "Win Only") then
                            condition = "Lose"
                            activeConfig.Condition = "Lose"
                        end
                    end
                    local stratChoice = (condition == "Win" or condition == "Win Only") and "Win" or "Lose"

                    if getgenv then
                        getgenv().AutoRestart = false
                        getgenv().AutoRejoin = false
                    end
                    Globals.AutoRestart = false
                    Globals.AutoRejoin = false

                    local loadoutTowers = nil
                    local activeMap = "Simplicity"
                    local mapModifiers = nil
                    local scriptUrl = nil
                    local currentMatchLvlReq = 0
                    local nodeInfo = nil
                    local isStoryMode = false

                    if activeMode == "Timescales" then
                        if isTrialsMatch then
                            -- Trials match
                            local curTrial = (DataHandler and typeof(DataHandler.GetCurrentTrial) == "function" and DataHandler:GetCurrentTrial())
                            local trialTitle = curTrial and (curTrial.Title or curTrial.Name)
                            if not trialTitle and gsrGlobalTrial and gsrGlobalTrial ~= "" then
                                for _, d in ipairs(DataHandler.StaticTrialDefinitions or {}) do
                                    if d.Name == gsrGlobalTrial then trialTitle = d.Title break end
                                end
                                if not trialTitle then trialTitle = gsrGlobalTrial end
                            end

                            local trialCfg = trialTitle and GetTrialConfig(trialTitle)
                            if not trialCfg and gsrGlobalTrial and gsrGlobalTrial ~= "" then
                                trialCfg = GetTrialConfig(gsrGlobalTrial)
                            end

                            if trialCfg then
                                local isPrem = checkIsPremium()
                                local t2 = isPrem and getTrialTowerSet(trialCfg, 2)
                                if t2 and PlayerDataHandler then
                                    local hasAll2 = true
                                    for _, t in ipairs(t2) do
                                        if not PlayerDataHandler:IsTowerOwned(t) then hasAll2 = false break end
                                    end
                                    if hasAll2 then
                                        loadoutTowers = t2
                                        scriptUrl = getTrialScriptUrl(trialCfg, 2)
                                    end
                                end

                                if not loadoutTowers then
                                    loadoutTowers = getTrialTowerSet(trialCfg, 1)
                                    scriptUrl = getTrialScriptUrl(trialCfg, 1)
                                end

                                local reps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                local gsr = reps and reps:FindFirstChild("GameStateReplicator")
                                activeMap = (curTrial and curTrial.Map) or (gsr and gsr:GetAttribute("MapName")) or workspace:GetAttribute("Map") or "Forgetten Docks"
                                Logger:Info(string.format("Auto Timescales: Detected active Trial match '%s' on '%s'.", tostring(trialTitle or gsrGlobalTrial), tostring(activeMap)))
                            else
                                Logger:Warn("Auto Timescales: Could not locate config for Trial: " .. tostring(trialTitle or gsrGlobalTrial))
                            end
                        else
                            -- Fallback Match (Survival: Molten or Fallen)
                            local fallbackChoice = activeConfig.Fallback or "Molten"
                            local fbStrat = (fallbackChoice == "Fallen") and "Win" or "Lose"
                            local fbChecker = AutoCurrencyChecker("Coins", fbStrat)
                            local dedicatedCfg = fbChecker and fbChecker.config

                            if dedicatedCfg then
                                loadoutTowers = dedicatedCfg.Towers
                                activeMap = (dedicatedCfg.Maps and dedicatedCfg.Maps[1]) or (fallbackChoice == "Fallen" and "Lay By" or "Simplicity")
                                mapModifiers = dedicatedCfg.Modifiers
                                scriptUrl = dedicatedCfg.Scripts and (dedicatedCfg.Scripts[activeMap] or dedicatedCfg.Scripts[dedicatedCfg.Maps and dedicatedCfg.Maps[1]])
                                if not scriptUrl and dedicatedCfg.Scripts then
                                    for _, u in pairs(dedicatedCfg.Scripts) do scriptUrl = u break end
                                end
                            end
                            Logger:Info(string.format("Auto Timescales: Running fallback %s match on %s (Strategy: %s).", tostring(fallbackChoice), tostring(activeMap or "Unknown"), tostring(scriptUrl and "Loaded" or "None")))
                        end
                    elseif activeMode == "Evo" then
                        local evoAnalysis = AutoEvoModule.AnalyzeRequirements()
                        local evoCfg = evoAnalysis.config
                        local activeTower = evoAnalysis.activeTower or "Scout"
                        local farmType = evoAnalysis.farmType or "Coins"

                        if evoCfg then
                            if type(evoCfg.Towers) == "table" and evoCfg.Towers[activeTower] then
                                loadoutTowers = evoCfg.Towers[activeTower]
                            elseif type(evoCfg.Towers) == "table" then
                                loadoutTowers = evoCfg.Towers
                            end

                            activeMap = (evoCfg.Maps and evoCfg.Maps[1]) or (farmType == "Gems" and "Wretched Front" or (stratChoice == "Win" and "Lay By" or "Simplicity"))
                            mapModifiers = evoCfg.Modifiers

                            if evoCfg.Scripts and evoCfg.Scripts[activeTower] then
                                local tScripts = evoCfg.Scripts[activeTower]
                                if type(tScripts) == "string" then
                                    scriptUrl = tScripts
                                elseif type(tScripts) == "table" then
                                    scriptUrl = tScripts[activeMap]
                                    if not scriptUrl then
                                        for _, u in pairs(tScripts) do scriptUrl = u break end
                                    end
                                end
                            end
                        end
                    elseif activeMode == "Progress" then
                        nodeInfo = getAutoProgressNodeInfo and getAutoProgressNodeInfo()
                        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                        local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                        local diffStr = tostring((gsr and gsr:GetAttribute("Difficulty")) or workspace:GetAttribute("Difficulty") or "")
                        local modeStr = tostring((gsr and gsr:GetAttribute("Mode")) or workspace:GetAttribute("Mode") or "")
                        local storyMissionAttr = gsr and gsr:GetAttribute("StoryMission")
                        if storyMissionAttr ~= nil or diffStr:find("Chapter") or diffStr:find("Mission") or modeStr:lower() == "story" or (nodeInfo and nodeInfo.nodeNum == 0) then
                            isStoryMode = true
                        end

                        if isStoryMode then
                            -- Node 0: Story Mode pre-made map
                            -- Fixed loadout provided by game; no intermission elevator or map voting!
                            local storyMissionsMap = {
                                [1] = "Boot Camp",
                                [2] = "Live Fire",
                                [3] = "Breach Protocol",
                                [4] = "Brute Force"
                            }
                            local mNum = tonumber(storyMissionAttr)
                                or tonumber(string.match(diffStr, "Mission(%d+)"))
                                or (nodeInfo and nodeInfo.nextMissionNum)
                                or 1
                            local missionName = storyMissionsMap[mNum] or "Boot Camp"
                            activeMap = missionName

                            local scriptsTable = (nodeInfo and nodeInfo.stepConfig and nodeInfo.stepConfig.scripts)
                                or (ProgressionConfig and ProgressionConfig.AutoProgress and ProgressionConfig.AutoProgress["Node 0"] and ProgressionConfig.AutoProgress["Node 0"][1] and ProgressionConfig.AutoProgress["Node 0"][1].scripts)
                            if scriptsTable then
                                scriptUrl = scriptsTable[missionName] or scriptsTable[activeMap]
                                if not scriptUrl then
                                    for _, u in pairs(scriptsTable) do scriptUrl = u break end
                                end
                            end

                            Logger:Info(string.format("Auto Progress (Node 0): Pre-made Story Mission %d (%s) detected. Executing script directly (skipping map voting)...", mNum, missionName))

                            -- Auto Ready Watcher for Story Mode: keep voting Ready until prompt is dismissed
                            task.spawn(function()
                                local reps = ReplicatedStorage:WaitForChild("StateReplicators", 10)
                                local vr = reps and reps:WaitForChild("VoteReplicator", 10)
                                local readyT0 = tick()
                                while activeInGameCurrencyLoop and State.Master and (tick() - readyT0 < 60) do
                                    if vr and vr:GetAttribute("Enabled") == true and vr:GetAttribute("Title") == "Ready?" then
                                        Logger:Info(string.format("Auto Progress (Node 0): Auto-voting Ready for Mission %d (%s)...", mNum, missionName))
                                        while vr and vr:GetAttribute("Enabled") == true and vr:GetAttribute("Title") == "Ready?" do
                                            RunVoteSkip()
                                            task.wait(0.25)
                                        end
                                        break
                                    end
                                    task.wait(0.2)
                                end
                            end)
                        else
                            if nodeInfo then
                                loadoutTowers = nodeInfo.towersToEquip
                                activeMap = (nodeInfo.maps and nodeInfo.maps[1]) or "Simplicity"
                                if nodeInfo.scripts then
                                    scriptUrl = nodeInfo.scripts[activeMap]
                                    if not scriptUrl then
                                        for _, u in pairs(nodeInfo.scripts) do scriptUrl = u break end
                                    end
                                end
                                Logger:Info(string.format("Auto Progress: In-game match configured for %s (Map: %s).", nodeInfo.nodeName, tostring(activeMap)))
                            end
                        end
                    else
                        local checker = AutoCurrencyChecker(activeMode, stratChoice)
                        local config = checker.config
                        if config then
                            currentMatchLvlReq = tonumber(config.Level or config.level) or 0
                            loadoutTowers = config.Towers
                            activeMap = (config.Maps and config.Maps[1]) or "Simplicity"
                            mapModifiers = config.Modifiers
                            scriptUrl = config.Scripts and (config.Scripts[activeMap] or config.Scripts[config.Maps[1]])
                            if not scriptUrl and config.Scripts then
                                for _, u in pairs(config.Scripts) do scriptUrl = u break end
                            end
                        end
                    end

                    -- Clean empty tower names from loadout if present
                    if loadoutTowers and type(loadoutTowers) == "table" then
                        local cleaned = {}
                        for _, t in ipairs(loadoutTowers) do
                            if t and t ~= "" and type(t) == "string" then
                                table.insert(cleaned, t)
                            end
                        end
                        loadoutTowers = cleaned
                    end

                    -- 1. Loadout Equipping
                    if loadoutTowers and type(loadoutTowers) == "table" and #loadoutTowers > 0 and TDS and typeof(TDS.Loadout) == "function" then
                        Logger:Info(string.format("Auto Currency: Equipping required loadout (%s)...", table.concat(loadoutTowers, ", ")))
                        pcall(function() TDS:Loadout(unpack(loadoutTowers)) end)
                    end

                    -- Intermission & Map Voting (Skipped for Trials and Story Mode)
                    local isStoryMode = (activeMode == "Progress") and (nodeInfo and nodeInfo.nodeNum == 0)
                    if not isTrialsMatch and not isStoryMode then
                        if mapModifiers and type(mapModifiers) == "table" and next(mapModifiers) then
                            Logger:Info("Auto Currency: Casting modifier votes from configuration...")
                            task.spawn(function()
                                CastModifierVote(mapModifiers)
                                task.wait(1.5)
                                CastModifierVote(mapModifiers)
                            end)
                        end

                        if activeMap and AutoGoldModule and typeof(AutoGoldModule.GameInfo) == "function" then
                            local voteTarget = (config and config.Maps) or activeMap
                            Logger:Info("Auto Currency: Intermission voting map: " .. tostring(activeMap))
                            pcall(function()
                                AutoGoldModule.GameInfo(voteTarget, mapModifiers)
                            end)
                        end
                    elseif isStoryMode then
                        Logger:Info("Auto Progress: Story Mode match detected - skipped elevator intermission and map voting.")
                    else
                        Logger:Info("Auto Timescales: Trials match detected - skipped elevator intermission and map voting.")
                    end

                    -- 2. Wait for player character & hotbar to be loaded in intermission
                    Logger:Info("Auto Currency: Waiting for character and hotbar...")
                    local waitStartT0 = tick()
                    repeat
                        task.wait(0.5)
                        local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
                        local hotbar = pg and (pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
                        local char = LocalPlayer and LocalPlayer.Character
                        if hotbar and char then break end
                    until (not State.Master) or (not activeInGameCurrencyLoop) or (tick() - waitStartT0 >= 30)

                    -- 3. State reset and clean index before strategy run
                    if TDS and typeof(TDS.RemoveIndex) == "function" then
                        pcall(function() TDS:RemoveIndex() end)
                    end
                    if TDS and typeof(TDS.ResetAllStates) == "function" then
                        pcall(function() TDS:ResetAllStates() end)
                    end

                    -- 4. Identify active map and load strategy script (skip for Story Mode to preserve mission-specific mapping)
                    if not isStoryMode and activeMode ~= "Timescales" then
                        pcall(function()
                            local wsMap = workspace:GetAttribute("Map")
                            if wsMap and wsMap ~= "" then
                                activeMap = wsMap
                            else
                                local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                local gsrMap = gsr and (gsr:GetAttribute("Map") or gsr:GetAttribute("MapName"))
                                if gsrMap and gsrMap ~= "" then activeMap = gsrMap end
                            end
                        end)

                        if config and config.Scripts and activeMap and config.Scripts[activeMap] then
                            scriptUrl = config.Scripts[activeMap]
                        end
                    end

                    local stratThread = nil
                    local function startStrat()
                        if not scriptUrl or scriptUrl == "" then
                            Logger:Warn("Auto Currency: Strategy script URL is missing!")
                            return
                        end
                        Logger:Info("Auto Currency: Running strategy script for map: " .. tostring(activeMap))
                        stratThread = task.spawn(function()
                            local ok, sErr = pcall(function()
                                local activeTDS = TDS or cachedTDSAPI or shared.TDSTable or (getgenv and getgenv().TDS) or _G.TDS
                                if not activeTDS then
                                    activeTDS = loadTDSAPI()
                                end
                                if activeTDS then
                                    if getgenv then getgenv().TDS = activeTDS end
                                    _G.TDS = activeTDS
                                    activeTDS.__matchRestarted = true
                                    activeTDS.GameInfo = function(self, ...)
                                        warn(">>> [startStrat] Bypassing elevator boards check (match in-game / restarted).")
                                        return true
                                    end
                                    activeTDS.Map = activeTDS.GameInfo
                                end

                                local stratFunc = loadstring(game:HttpGet(scriptUrl))
                                if stratFunc then
                                    if activeTDS then
                                        local env = getfenv(stratFunc)
                                        env.TDS = activeTDS
                                        setfenv(stratFunc, env)
                                    end
                                    stratFunc()
                                end
                            end)
                            if not ok then
                                Logger:Warn("Auto Currency: Strategy execution error: " .. tostring(sErr))
                            end
                        end)
                    end

                    startStrat()

                    -- Gatling Loader Routine (Railgun or Gatlify)
                    -- Loader 1: Auto Gatling (loads EVERY time if turned on)
                    -- Loader 2: Gatling Loader Condition Win | Trial (loads ONLY if Win condition or Trials)
                    local isWinOrTrials = (activeMode == "Timescales") or isTrialsMatch or (condition == "Win") or (condition == "Win Only")
                    local shouldLoadGatling = false
                    local chosenGatlingScript = "Railgun"

                    if State and State.AdvancFunc and State.AdvancFunc.AutoGatling then
                        shouldLoadGatling = true
                        chosenGatlingScript = State.AdvancFunc.SelectedGatling or "Railgun"
                    elseif State and State.AdvancFunc and State.AdvancFunc.ConditionGatlingLoader then
                        if isWinOrTrials then
                            shouldLoadGatling = true
                            chosenGatlingScript = State.AdvancFunc.ConditionGatlingScript or "Railgun"
                        else
                            Logger:Info("Auto Currency: Gatling Loader Condition Win | Trial skipped (condition is Lose, requires Win or Trials).")
                        end
                    end

                    if shouldLoadGatling then
                        task.spawn(function()
                            task.wait(2.5) -- Allow strategy script and initial placements to begin
                            AutoGoldModule.ExecuteGatlingLoader(chosenGatlingScript)
                        end)
                    end

                    local pendingTargetReached = false
                    local lastBoxRefresh = 0

                    local function doInPlaceRestart(tag: string?)
                        local prefix = tag or "Auto Currency"
                        Logger:Info(string.format("%s: Firing in-place Restart Match...", prefix))
                        isTeleporting = false

                        -- 1. Keep voting restart until server accepts it or begins round reset
                        local voteT0 = tick()
                        repeat
                            local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                            local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                            local vr = stateReps and stateReps:FindFirstChild("VoteReplicator")
                            local isOver = gsr and gsr:GetAttribute("GameOver")
                            local vTitle = vr and vr:GetAttribute("Title")
                            if isOver == false or vTitle == "Ready?" then
                                break
                            end

                            functionRestartLogic()
                            task.wait(0.5)
                        until (not State.Master) or (not activeInGameCurrencyLoop) or (tick() - voteT0 >= 25)

                        Logger:Info(string.format("%s: Waiting for match restart to complete...", prefix))
                        local restartSuccess = false
                        local restartWaitT0 = tick()
                        repeat
                            task.wait(0.5)
                            if game.PlaceId == LOBBY_PLACE_ID then break end
                            local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                            local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                            local vr = stateReps and stateReps:FindFirstChild("VoteReplicator")
                            local isOver = gsr and gsr:GetAttribute("GameOver")
                            local wave = gsr and (gsr:GetAttribute("Wave") or 0)
                            local vTitle = vr and vr:GetAttribute("Title")

                            if isOver == false or wave <= 1 or vTitle == "Ready?" then
                                restartSuccess = true
                                break
                            end
                        until (not State.Master) or (not activeInGameCurrencyLoop) or (tick() - restartWaitT0 >= 30)

                        if restartSuccess then
                            Logger:Info(string.format("%s: Match restarted! Cleaning state and executing strategy...", prefix))
                            if stratThread then
                                pcall(task.cancel, stratThread)
                                stratThread = nil
                            end
                            if TDS and typeof(TDS.RemoveIndex) == "function" then
                                pcall(function() TDS:RemoveIndex() end)
                            end
                            if TDS and typeof(TDS.ResetAllStates) == "function" then
                                pcall(function() TDS:ResetAllStates() end)
                            end
                            pcall(function()
                                local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
                                if pg then
                                    local r = pg:FindFirstChild("ReactGameNewRewards")
                                    if r then r:Destroy() end
                                    local g = pg:FindFirstChild("GameOver")
                                    if g then g:Destroy() end
                                end
                            end)

                            -- Wait until GameOver becomes false and placed towers in workspace are cleared
                            local cleanWaitT0 = tick()
                            repeat
                                task.wait(0.3)
                                local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                local isOver = gsr and gsr:GetAttribute("GameOver")
                                local towersFolder = workspace:FindFirstChild("Towers")
                                local towersClean = (not towersFolder or #towersFolder:GetChildren() == 0)
                                if isOver == false and towersClean then
                                    break
                                end
                            until (tick() - cleanWaitT0 >= 10)

                            task.wait(1)

                            -- For Story Mode (Node 0): keep voting ready when prompted
                            if isStoryMode then
                                task.spawn(function()
                                    local reps = ReplicatedStorage:WaitForChild("StateReplicators", 5)
                                    local vr = reps and reps:WaitForChild("VoteReplicator", 5)
                                    local readyT0 = tick()
                                    while activeInGameCurrencyLoop and State.Master and (tick() - readyT0 < 60) do
                                        if vr and vr:GetAttribute("Enabled") == true and vr:GetAttribute("Title") == "Ready?" then
                                            while vr and vr:GetAttribute("Enabled") == true and vr:GetAttribute("Title") == "Ready?" do
                                                RunVoteSkip()
                                                task.wait(0.25)
                                            end
                                            break
                                        end
                                        task.wait(0.2)
                                    end
                                end)
                            end

                            startStrat()
                            task.wait(3)
                            return true
                        else
                            Logger:Warn(string.format("%s: Match restart timed out or failed. Returning to lobby...", prefix))
                            SmartTeleportToLobby()
                            return false
                        end
                    end

                    -- 5. In-Match Game Over / Result Supervisor
                    while activeInGameCurrencyLoop and State.Master do
                        task.wait(1)

                        if tick() - lastBoxRefresh >= 5 then
                            lastBoxRefresh = tick()
                            if refreshCurrencyBox then
                                pcall(refreshCurrencyBox)
                            end
                        end

                        -- A. Target check (flag only so round completes and rewards are preserved):
                        local currentTargetVal = parseTargetVal(activeConfig.Target)
                        if currentTargetVal > 0 and DataHandler and not pendingTargetReached then
                            local stats = DataHandler:GetPlayerStats()
                            if isTargetReached(activeMode, currentTargetVal, stats) then
                                pendingTargetReached = true
                                Logger:Info(string.format("Auto %s: Target (%s) reached! Waiting for current match to conclude before returning to lobby so no rewards get lost...", activeMode, tostring(currentTargetVal)))
                            end
                        end

                        if activeMode == "Evo" and not pendingTargetReached then
                            local evoMilestone, evoReason = AutoEvoModule.CheckMilestonesReached()
                            if evoMilestone then
                                pendingTargetReached = true
                                Logger:Info(string.format("Auto Evo: Milestone reached (%s)! Waiting for match to conclude before returning to lobby...", tostring(evoReason)))
                                Window:Notify({
                                    Title = "AUTO EVO MILESTONE",
                                    Desc = tostring(evoReason) .. "! Returning to lobby after round concludes.",
                                    Duration = 6,
                                    Type = "info",
                                })
                            end
                        end

                        -- B. Match Status Check: Match is concluded when GameOver is true on server
                        local matchStatus = GetMatchStatus()
                        if not matchStatus then
                            continue
                        end

                        local reps = ReplicatedStorage:FindFirstChild("StateReplicators")
                        local gsr = reps and reps:FindFirstChild("GameStateReplicator")
                        local baseHealth = tonumber(gsr and (gsr:GetAttribute("Health") or workspace:GetAttribute("Health"))) or 0
                        local curWave = gsr and (gsr:GetAttribute("Wave") or 0)
                        local isTrials = (activeMode == "Timescales") and isTrialsMatch
                        local modeTag = isTrials and "AUTO TRIALS" or ("AUTO " .. string.upper(tostring(activeMode)))

                        if matchStatus == "WIN" or matchStatus == "VICTORY" then
                            warn("══════════════════════════════════════════════════════════════════════")
                            warn(string.format(">>> [%s STATUS: WON (VICTORY)] <<< Base Health: %s | Wave: %s", modeTag, tostring(baseHealth), tostring(curWave)))
                            warn("══════════════════════════════════════════════════════════════════════")
                            Logger:Success(string.format("%s: Match Concluded - Status: WON (Victory)! (Base Health: %s, Wave: %s)", modeTag, tostring(baseHealth), tostring(curWave)))
                            Window:Notify({
                                Title = "Status: WON (Victory)",
                                Desc = string.format("%s finished with Victory! Base HP: %s", modeTag, tostring(baseHealth)),
                                Duration = 5
                            })
                        else
                            warn("══════════════════════════════════════════════════════════════════════")
                            warn(string.format(">>> [%s STATUS: LOST (DEFEAT)] <<< Base Health: %s | Wave: %s", modeTag, tostring(baseHealth), tostring(curWave)))
                            warn("══════════════════════════════════════════════════════════════════════")
                            Logger:Warn(string.format("%s: Match Concluded - Status: LOST (Defeat)! (Base Health: %s, Wave: %s)", modeTag, tostring(baseHealth), tostring(curWave)))
                            Window:Notify({
                                Title = "Status: LOST (Defeat)",
                                Desc = string.format("%s finished with Defeat. Base HP: %s", modeTag, tostring(baseHealth)),
                                Duration = 5
                            })
                        end

                            -- Increment match session and total counters
                            if getgenv then
                                getgenv().HubSessionMatches = (getgenv().HubSessionMatches or 0) + 1
                                if matchStatus == "WIN" or matchStatus == "VICTORY" then
                                    getgenv().HubSessionWins = (getgenv().HubSessionWins or 0) + 1
                                end
                            end
                            if Settings then
                                local curTotal = Settings:Get("TotalMatches", 0) or 0
                                Settings:Set("TotalMatches", curTotal + 1)
                            end

                            if State.Misc.WebhookAlerts and State.Misc.WebhookUrl ~= "" and SendAutoCurrencyWebhook then
                                local matchWave = nil
                                pcall(function()
                                    local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                    local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                    if gsr then matchWave = gsr:GetAttribute("Wave") end
                                end)
                                pcall(function()
                                    SendAutoCurrencyWebhook("Match Concluded", matchStatus, matchWave, "Match concluded! Results recorded.")
                                end)
                            end
                            task.wait(2)

                            -- Check if target was reached during this match!
                            local currentTargetVal = parseTargetVal(activeConfig.Target)
                            local stats = DataHandler and DataHandler:GetPlayerStats()
                            if pendingTargetReached or (currentTargetVal > 0 and isTargetReached(activeMode, currentTargetVal, stats)) then
                                activeConfig.Enabled = false
                                if State.AutoCurrency and State.AutoCurrency[activeMode] then
                                    State.AutoCurrency[activeMode].Enabled = false
                                    State.AutoCurrency[activeMode].Target = "0"
                                end
                                activeConfig.Target = "0"
                                if Settings then
                                    Settings:Set("Auto" .. activeMode .. "Enabled", false, true)
                                    Settings:Set("Auto" .. activeMode .. "Target", "0", true)
                                end
                                SaveSettings(true)

                                if activeMode == "Coins" and coinsToggleRef then pcall(function() coinsToggleRef:SetValue(false) end) end
                                if activeMode == "Gems" and gemsToggleRef then pcall(function() gemsToggleRef:SetValue(false) end) end
                                if activeMode == "Levels" and levelsToggleRef then pcall(function() levelsToggleRef:SetValue(false) end) end
                                if activeMode == "Timescales" and timescalesToggleRef then pcall(function() timescalesToggleRef:SetValue(false) end) end
                                if activeMode == "Coins" and coinsTextboxRef then pcall(function() coinsTextboxRef:SetValue("0") end) end
                                if activeMode == "Gems" and gemsTextboxRef then pcall(function() gemsTextboxRef:SetValue("0") end) end
                                if activeMode == "Levels" and levelsTextboxRef then pcall(function() levelsTextboxRef:SetValue("0") end) end
                                if activeMode == "Timescales" and timescalesTextboxRef then pcall(function() timescalesTextboxRef:SetValue("0") end) end
                                refreshCurrencyBox()
                                if State.Misc.WebhookAlerts and State.Misc.WebhookUrl ~= "" and SendAutoCurrencyWebhook then
                                    pcall(function()
                                        SendAutoCurrencyWebhook(string.format("%s Target Reached!", activeMode), nil, nil, "Target goal completed! Returning to lobby.")
                                    end)
                                end
                                Window:Notify({
                                    Title = "Target Reached",
                                    Desc = string.format("Auto %s reached target (%s). Round completed! Returning to lobby...", activeMode, tostring(currentTargetVal)),
                                    Duration = 6
                                })
                                Logger:Info(string.format("Auto Currency: Target reached (%s). Match finished with full rewards, returning to lobby...", tostring(currentTargetVal)))
                                task.wait(0.5)
                                SmartTeleportToLobby()
                                break
                            end

                            if activeMode == "Evo" then
                                local evoMilestone, evoReason = AutoEvoModule.CheckMilestonesReached()
                                if pendingTargetReached or evoMilestone then
                                    Logger:Info(string.format("Auto Evo: Milestone achieved (%s). Returning to lobby...", tostring(evoReason or "Target Met")))
                                    Window:Notify({
                                        Title = "Auto Evo Milestone",
                                        Desc = string.format("Match complete! Returning to lobby (%s)...", tostring(evoReason or "Ready")),
                                        Duration = 5,
                                    })
                                    task.wait(0.5)
                                    SmartTeleportToLobby()
                                    break
                                end
                            end

                            local isPremUser = checkIsPremium()

                            if isTrialsMatch and isPremUser then
                                -- Premium mode for Farm Timescales
                                if matchStatus == "WIN" or matchStatus == "VICTORY" then
                                    functionWinLogic(activeMode, true, true)
                                    local rematchSuccess = false
                                    local rematchWaitT0 = tick()
                                    repeat
                                        triggerRematchVote()
                                        task.wait(0.5)
                                        if game.PlaceId == LOBBY_PLACE_ID then break end
                                        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                        local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                        local vr = stateReps and stateReps:FindFirstChild("VoteReplicator")
                                        local isOver = gsr and gsr:GetAttribute("GameOver")
                                        local wave = gsr and (gsr:GetAttribute("Wave") or 0)
                                        local vTitle = vr and vr:GetAttribute("Title")

                                        if isOver == false or wave <= 1 or vTitle == "Ready?" then
                                            rematchSuccess = true
                                            break
                                        end

                                        if rematchRemote and tick() - rematchWaitT0 >= 5 and tick() - rematchWaitT0 < 20 then
                                            pcall(function()
                                                if rematchRemote:IsA("RemoteEvent") or rematchRemote:IsA("UnreliableRemoteEvent") then
                                                    rematchRemote:FireServer()
                                                elseif rematchRemote:IsA("RemoteFunction") then
                                                    rematchRemote:InvokeServer()
                                                end
                                            end)
                                        end
                                    until (not State.Master) or (not activeInGameCurrencyLoop) or (tick() - rematchWaitT0 >= 30)

                                    if rematchSuccess then
                                        Logger:Info("Auto Timescales: Rematch successful! Resetting states and starting strategy...")
                                        if stratThread then
                                            pcall(task.cancel, stratThread)
                                            stratThread = nil
                                        end
                                        if TDS and typeof(TDS.RemoveIndex) == "function" then
                                            pcall(function() TDS:RemoveIndex() end)
                                        end
                                        if TDS and typeof(TDS.ResetAllStates) == "function" then
                                            pcall(function() TDS:ResetAllStates() end)
                                        end
                                        pcall(function()
                                            local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
                                            if pg then
                                                local r = pg:FindFirstChild("ReactGameNewRewards")
                                                if r then r:Destroy() end
                                                local g = pg:FindFirstChild("GameOver")
                                                if g then g:Destroy() end
                                            end
                                        end)

                                        local cleanWaitT0 = tick()
                                        repeat
                                            task.wait(0.3)
                                            local towersFolder = workspace:FindFirstChild("Towers")
                                        until (not towersFolder or #towersFolder:GetChildren() == 0) or (tick() - cleanWaitT0 >= 8)

                                        task.wait(1)
                                        startStrat()
                                    else
                                        Logger:Warn("Auto Timescales: Rematch timed out or failed. Returning to lobby via smartLobby...")
                                        SmartTeleportToLobby()
                                        break
                                    end
                                else
                                    -- Lose condition for Premium Timescales: Use RETRY logic, max 3 attempts before smartLobby
                                    timescalesConsecutiveLosses = timescalesConsecutiveLosses + 1
                                    warn(string.format(">>> [AUTO TRIALS DEFEAT RETRY] <<< Attempt %d / 3. Firing in-place match restart...", timescalesConsecutiveLosses))
                                    Logger:Warn(string.format("Auto Timescales (Premium): Defeat detected (Attempt %d / 3).", timescalesConsecutiveLosses))

                                    if timescalesConsecutiveLosses >= 3 then
                                        warn(">>> [AUTO TRIALS] 3 consecutive losses reached! Exiting to lobby via smartLobby...")
                                        Logger:Warn("Auto Timescales (Premium): Reached 3 consecutive losses! Returning to lobby via smartLobby...")
                                        timescalesConsecutiveLosses = 0
                                        SmartTeleportToLobby()
                                        break
                                    else
                                        Logger:Info("Auto Timescales (Premium): Firing in-place Restart Match retry...")
                                        isTeleporting = false

                                        local voteT0 = tick()
                                        repeat
                                            local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                            local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                            local vr = stateReps and stateReps:FindFirstChild("VoteReplicator")
                                            local isOver = gsr and gsr:GetAttribute("GameOver")
                                            local vTitle = vr and vr:GetAttribute("Title")
                                            if isOver == false or vTitle == "Ready?" then
                                                break
                                            end

                                            functionRestartLogic()
                                            task.wait(0.5)
                                        until (not State.Master) or (not activeInGameCurrencyLoop) or (tick() - voteT0 >= 25)

                                        Logger:Info("Auto Timescales: Waiting for match restart to complete...")
                                        local restartSuccess = false
                                        local restartWaitT0 = tick()
                                        repeat
                                            task.wait(0.5)
                                            if game.PlaceId == LOBBY_PLACE_ID then break end
                                            local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                            local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                            local vr = stateReps and stateReps:FindFirstChild("VoteReplicator")
                                            local isOver = gsr and gsr:GetAttribute("GameOver")
                                            local wave = gsr and (gsr:GetAttribute("Wave") or 0)
                                            local vTitle = vr and vr:GetAttribute("Title")

                                            if isOver == false or wave <= 1 or vTitle == "Ready?" then
                                                restartSuccess = true
                                                break
                                            end
                                        until (not State.Master) or (not activeInGameCurrencyLoop) or (tick() - restartWaitT0 >= 30)

                                        if restartSuccess then
                                            Logger:Info("Auto Timescales: Match restarted! Cleaning state and executing strategy...")
                                            if stratThread then
                                                pcall(task.cancel, stratThread)
                                                stratThread = nil
                                            end
                                            if TDS and typeof(TDS.RemoveIndex) == "function" then
                                                pcall(function() TDS:RemoveIndex() end)
                                            end
                                            if TDS and typeof(TDS.ResetAllStates) == "function" then
                                                pcall(function() TDS:ResetAllStates() end)
                                            end

                                            local cleanWaitT0 = tick()
                                            repeat
                                                task.wait(0.3)
                                                local towersFolder = workspace:FindFirstChild("Towers")
                                            until (not towersFolder or #towersFolder:GetChildren() == 0) or (tick() - cleanWaitT0 >= 8)

                                            task.wait(1)
                                            startStrat()
                                        else
                                            Logger:Warn("Auto Timescales: Match restart failed. Returning to lobby via smartLobby...")
                                            SmartTeleportToLobby()
                                            break
                                        end
                                    end
                                end
                            elseif activeMode == "Progress" then
                                local nodeInfo = getAutoProgressNodeInfo and getAutoProgressNodeInfo()
                                if nodeInfo and nodeInfo.nodeNum == 0 then
                                    if matchStatus == "WIN" or matchStatus == "VICTORY" then
                                        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
                                        local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                        local curMission = tonumber(gsr and gsr:GetAttribute("StoryMission"))
                                            or tonumber(string.match(tostring((gsr and gsr:GetAttribute("Difficulty")) or ""), "Mission(%d+)"))
                                            or (nodeInfo and nodeInfo.nextMissionNum)
                                            or 1
                                        local nextMissionNum = tonumber(gsr and gsr:GetAttribute("StoryNextMission")) or (curMission + 1)
                                        if nextMissionNum <= 4 then
                                            Logger:Info(string.format("Auto Progress (Node 0): Mission %d Victory! Directly queueing Mission %d in-game (Cobalt fast-transition)...", curMission, nextMissionNum))
                                            local remote = ReplicatedStorage:FindFirstChild("RemoteFunction")
                                            if remote and remote:IsA("RemoteFunction") then
                                                pcall(function() remote:InvokeServer("Multiplayer", "v2:stop") end)
                                                task.wait(0.2)
                                                remote:InvokeServer("Multiplayer", "v2:start", {
                                                    mode = "story",
                                                    count = 1,
                                                    story = {
                                                        chapter = 0,
                                                        mission = nextMissionNum
                                                    }
                                                })
                                            end
                                            task.wait(3)
                                            break
                                        else
                                            -- All 4 story missions cleared! Return to lobby to buy towers & advance to Node 1
                                            Logger:Info("Auto Progress (Node 0): All 4 story missions cleared! Returning to lobby to buy towers and enter Node 1...")
                                            SmartTeleportToLobby()
                                            break
                                        end
                                    else
                                        -- Lose on Node 0: Retry mission in-game
                                        doInPlaceRestart("Auto Progress (Node 0)")
                                    end
                                else
                                    -- Node 1 or Node 2
                                    local curLvl = (PlayerDataHandler and typeof(PlayerDataHandler.GetLevel) == "function" and PlayerDataHandler:GetLevel())
                                        or (DataHandler and typeof(DataHandler.GetLevel) == "function" and DataHandler:GetLevel())
                                        or 0
                                    local curCoins = 0
                                    if DataHandler and typeof(DataHandler.GetPlayerStats) == "function" then
                                        local st = DataHandler:GetPlayerStats()
                                        if st and st.Coins then curCoins = tonumber(st.Coins) or 0 end
                                    end

                                    local goal = (nodeInfo and nodeInfo.levelGoal) or 15
                                    local neededCoins = (nodeInfo and nodeInfo.totalCoinsNeeded) or 0
                                    local hasAllTowers = (nodeInfo and nodeInfo.towersToBuy and #nodeInfo.towersToBuy == 0)

                                    local lvlDone = (curLvl >= goal)
                                    local coinsDone = hasAllTowers or (neededCoins == 0) or (curCoins >= neededCoins)

                                    if lvlDone and coinsDone then
                                        Logger:Info(string.format("Auto Progress (%s): Objectives reached (Level: %d/%d, Coins: %d/%d)! Returning to lobby via smartLobby to buy towers and advance...", tostring(nodeInfo and nodeInfo.nodeName), curLvl, goal, curCoins, neededCoins))
                                        SmartTeleportToLobby()
                                        break
                                    else
                                        -- Lose strat fast grind: in-place Restart Match to farm coins and level without lobby delay!
                                        Logger:Info(string.format("Auto Progress (%s): Match ended. Grinding in-place (Level: %d/%d, Coins: %d/%d).", tostring(nodeInfo and nodeInfo.nodeName), curLvl, goal, curCoins, neededCoins))
                                        doInPlaceRestart(string.format("Auto Progress (%s)", tostring(nodeInfo and nodeInfo.nodeName)))
                                    end
                                end
                            elseif isTrialsMatch then
                                -- Standard Free Tier for Farm Timescales: Win or Lose -> always smartLobby
                                warn(string.format("══════════════════════════════════════════════════════════════════════"))
                                warn(string.format(">>> [AUTO TRIALS STANDARD FREE TIER RESULT: %s] <<< Returning to lobby via smartLobby...", tostring(matchStatus)))
                                warn(string.format("══════════════════════════════════════════════════════════════════════"))
                                Logger:Info(string.format("Auto Timescales (Standard Free Tier): Match concluded (%s). Returning to lobby via smartLobby...", matchStatus))
                                SmartTeleportToLobby()
                                break
                            elseif matchStatus == "WIN" or ((condition == "Win" or condition == "Win Only") and isPremUser) then
                                -- Auto Coins/Gems/Levels or Fallback Win condition: Custom WinLogic -> smartLobby
                                functionWinLogic(activeMode, false, isPremUser)
                                break
                            else
                                -- Check if player reached Level 15 in Casual match to return to lobby to purchase Soldier & Assassin
                                local effMode = activeMode
                                if effMode == "Levels" then
                                    effMode = (State and State.AutoCurrency and State.AutoCurrency.Levels and State.AutoCurrency.Levels.Currency)
                                        or (Settings and Settings:Get("AutoLevelsCurrency", "Coins"))
                                        or "Coins"
                                end
                                if effMode == "Coins" and condition == "Lose" then
                                    local currentLvl = (PlayerDataHandler and typeof(PlayerDataHandler.GetLevel) == "function" and PlayerDataHandler:GetLevel())
                                        or (DataHandler and typeof(DataHandler.GetLevel) == "function" and DataHandler:GetLevel())
                                        or 0
                                    if currentLvl >= 15 and currentMatchLvlReq < 15 then
                                        Logger:Info(string.format("Auto Coins: Level 15 reached in Casual match (Current Level: %d)! Returning to lobby via smartLobby to purchase Soldier & Assassin...", currentLvl))
                                        Window:Notify({
                                            Title = "Level 15 Reached!",
                                            Desc = "Reached Level 15! Returning to lobby to buy Soldier & Assassin.",
                                            Duration = 6,
                                        })
                                        SmartTeleportToLobby()
                                        break
                                    end
                                    local newChecker = AutoCurrencyChecker("Coins", "Lose")
                                    local newCfg = newChecker and newChecker.config
                                    local newLvlReq = newCfg and tonumber(newCfg.Level or newCfg.level) or 0
                                    if newLvlReq > currentMatchLvlReq then
                                        Logger:Info(string.format("Auto Coins: Level up detected! Current Level: %d (Unlocked tier Level %d: %s). Returning to lobby via smartLobby to queue higher difficulty...", currentLvl, newLvlReq, tostring(newCfg and newCfg.Mode)))
                                        Window:Notify({
                                            Title = "Tier Upgraded!",
                                            Desc = string.format("Level %d reached! Returning to lobby to queue %s...", currentLvl, tostring(newCfg and newCfg.Mode)),
                                            Duration = 5,
                                        })
                                        SmartTeleportToLobby()
                                        break
                                    end
                                end

                                -- Condition is "Lose": Fires Restart Match -> Clears state -> Replays strategy in-game
                                doInPlaceRestart("Auto Currency")
                            end
                        end
                    activeInGameCurrencyLoop = false
                end)
            end
        end
    end
end)
end)()




if (Globals and Globals.Disable3DRendering) or (State and State.Misc and State.Misc.Disable3DRendering) then
    task.spawn(Apply3dRendering)
end
if (Globals and Globals.AntiLag) or (State and State.Misc and State.Misc.AntiLag) then
    task.spawn(StartAntiLag)
end
if (Globals and Globals.DisableShadows) or (State and State.Misc and State.Misc.DisableShadows) then
    task.spawn(ApplyDisableShadows)
end

-- Continuous match listener: When in-game match starts or wave progression occurs, run auto-strat if enabled
task.spawn(function()
    while task.wait(2) do
        if ((State and State.Misc and State.Misc.Disable3DRendering) or (Globals and Globals.Disable3DRendering)) then
            Apply3dRendering()
        end
        if (((State and State.Misc and State.Misc.AntiLag) or (Globals and Globals.AntiLag)) and not AntiLagRunning) then
            task.spawn(StartAntiLag)
        end
        if ((State and State.Misc and State.Misc.DisableShadows) or (Globals and Globals.DisableShadows)) then
            ApplyDisableShadows()
        end

        if game.PlaceId ~= LOBBY_PLACE_ID then
            if ((State and State.Utilities and State.Utilities.AutoReady) or (Globals and Globals.AutoReady)) and not AutoReadyRunning then
                StartAutoReady()
            end
            if ((State and State.Utilities and State.Utilities.AutoSkip) or (Globals and Globals.AutoSkip)) and not AutoSkipRunning then
                StartAutoSkip()
            end
            if ((State and State.Utilities and State.Utilities.AutoRejoin) or (Globals and Globals.AutoRejoin)) and not AutoRejoinRunning then
                StartAutoRejoin()
            end
        end

        local isAuto = (State and State.StrategyManager and State.StrategyManager.AutoExecuteStrat == true)
            or (Globals and Globals.AutoExecuteStrat == true)
        if isAuto and game.PlaceId ~= LOBBY_PLACE_ID then
            local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
            local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
            local gameStarted = gsr and (gsr:GetAttribute("GameStarted") == true or (gsr:GetAttribute("Wave") or 0) > 0)
            local isOver = gsr and (gsr:GetAttribute("GameOver") == true)

            if isOver then
                hasAutoExecutedThisMatch = false
            elseif gameStarted and not hasAutoExecutedThisMatch then
                local currentTarget = selectedStrat
                if not currentTarget or currentTarget == "" then
                    currentTarget = (State and State.StrategyManager and (State.StrategyManager.selectedStrat or State.StrategyManager.SelectedStrat or State.StrategyManager.SelectedAutoStrat))
                        or (Globals and (Globals.selectedStrat or Globals.SelectedStrat or Globals.SelectedAutoStrat))
                        or selectedLibraryFile
                end
                if currentTarget and currentTarget ~= "" then
                    Logger:Info("[Auto-Exec Match] In-game match detected! Auto-executing: " .. tostring(currentTarget))
                    executeStrategyFile(currentTarget, nil, true)
                end
            end
        end
    end
end)

Window:SelectTab("Overview")

Window:Notify({
    Title = "SomethingNew Hub Ready",
    Desc = "Initialized 5 tabs with full glassmorphism suite.",
    Duration = 3,
})

return Window
