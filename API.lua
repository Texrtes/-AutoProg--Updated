local Globals = getgenv()

-- Patched shared.TDSTable check

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    local t0 = tick()
    while not Players.LocalPlayer and (tick() - t0 < 10) do
        task.wait(0.1)
    end
    LocalPlayer = Players.LocalPlayer
end

local function extractPrivateServerCode(linkOrCode: any): string
    if type(linkOrCode) ~= "string" or linkOrCode == "" then return "" end
    local trimmed = linkOrCode:match("^%s*(.-)%s*$") or linkOrCode
    local psCode = trimmed:match("privateServerLinkCode=([%w%-%_]+)")
        or trimmed:match("linkCode=([%w%-%_]+)")
        or trimmed:match("code=([%w%-%_]+)")
    if psCode and psCode ~= "" then return psCode end
    local clean = trimmed:match("^([%w%-%_]+)$")
    if clean and not clean:find("^https?://") then return clean end
    return trimmed
end

local function SmartTeleportToLobby(...)
    local lobbyId = 3260590327
    pcall(function()
        local platform = UserInputService:GetPlatform()
        local IsMobile = (platform == Enum.Platform.IOS or platform == Enum.Platform.Android)

        local rawCode = (Globals and Globals.PrivateCode)
            or (typeof(getgenv) == "function" and getgenv().PrivateCode)
            or _G.PrivateCode
            or (Globals and Globals.PrivateServerCode)
            or (typeof(getgenv) == "function" and getgenv().PrivateServerCode)
            or _G.PrivateServerCode

        local targetCode = extractPrivateServerCode(rawCode)

        local launched = false
        if not IsMobile and targetCode and targetCode ~= "" then
            pcall(function()
                local expService = game:GetService("ExperienceService")
                if expService and typeof(expService.LaunchExperience) == "function" then
                    expService:LaunchExperience({
                        placeId = lobbyId, 
                        linkCode = targetCode
                    })
                    launched = true
                end
            end)
        end

        if not launched then
            TeleportService:Teleport(lobbyId)
        end
    end)

    task.spawn(function()
        task.wait(10)
        local win = Window or (Globals and Globals.Window) or (typeof(getgenv) == "function" and getgenv().Window) or (shared and shared.Window)
        if win and typeof(win.Notify) == "function" then
            pcall(function()
                win:Notify({
                    Title = "Teleport Failed",
                    Desc = "It looks like you're stuck! If you are using Delta, please ensure that 'Verify Teleports' is disabled in your settings.",
                    Time = 9999,
                    Type = "error"
                })
            end)
            task.wait(5)
            pcall(function()
                win:Notify({
                    Title = "Fixing Delta Teleport Issues",
                    Desc = "1. Disconnect from the game\n2. Completely empty your 'autoexecute' folder\n3. Reopen Roblox and join the game\n4. Go to Delta settings and disable 'Verify Teleports'\n5. Disconnect and rejoin to confirm 'Verify Teleports' remains OFF\n6. Once verified, restore your files to 'autoexecute' and rejoin",
                    Time = 9999,
                    Type = "normal"
                })
            end)
        end
    end)
end

local UniversalSmartLobby = SmartTeleportToLobby
local SmartTeleportLobby = SmartTeleportToLobby


local function getErrorCodeSafe()
    local ok, code = pcall(function()
        return GuiService:GetErrorCode()
    end)
    if ok and code then
        return code
    end
    return nil
end

local function Reconnect(msg: string?)
    local initialCode = getErrorCodeSafe()
    local hasError = false
    pcall(function()
        if initialCode and initialCode ~= Enum.ConnectionError.OK then
            hasError = true
        end
    end)
    if not hasError and type(msg) == "string" and #msg > 0 then
        hasError = true
    end

    if hasError then
        task.wait(5)
        local currentCode = getErrorCodeSafe()
        if (currentCode and currentCode == initialCode) or (type(msg) == "string" and #msg > 0) then
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            pcall(function()
                TeleportService:TeleportReconnect()
            end)
        end
    end
end

local function AntiStuck()
    task.spawn(function()
        local secondsStuck = 0

        while true do 
            task.wait(1)
            
            local attrLoading = LocalPlayer:GetAttribute("Loading") == true
            local attrTeleporting = LocalPlayer:GetAttribute("Teleporting") == true
            
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local loadScreen = pg and pg:FindFirstChild("LoadingScreen")
            local loadContent = loadScreen and loadScreen:FindFirstChild("content")
            local isLoadVisible = loadContent and loadContent.Visible == true
            
            local countScreen = pg and pg:FindFirstChild("PlayerCountdown")
            local countFrame = countScreen and countScreen:FindFirstChild("Frame")
            local isCountVisible = countFrame and countFrame.Visible == true

            if attrLoading or attrTeleporting or isLoadVisible or isCountVisible then
                secondsStuck = secondsStuck + 1
                if secondsStuck >= 60 then
                    pcall(SmartTeleportToLobby)
                    secondsStuck = 0 
                end
            else
                secondsStuck = 0 
            end
        end
    end)
end

AntiStuck()
task.spawn(Reconnect)
pcall(function() GuiService.ErrorMessageChanged:Connect(Reconnect) end)

if not game:IsLoaded() then game.Loaded:Wait() end

local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local mouse = LocalPlayer:GetMouse()
local RemoteFunc = ReplicatedStorage:WaitForChild("RemoteFunction")
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local FileName = "APIS.json"
local Logger = {
    Log = function(self, ...)
        pcall(print, "[API]", ...)
    end,
    Warn = function(self, ...)
        pcall(warn, "[API]", ...)
    end,
    Error = function(self, ...)
        pcall(warn, "[API ERROR]", ...)
    end,
    Clear = function(self)
    end,
}
local StartBackToLobby
local platform = UserInputService:GetPlatform()
local IsMobile = (platform == Enum.Platform.IOS or platform == Enum.Platform.Android)

task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

task.spawn(function()
    pcall(function()
        RemoteFunc:InvokeServer("Settings", "Update", "Show Nametags", false)
    end)
end)

local function launchOrTeleportPrivateServer(...)
    SmartTeleportToLobby()
    return true
end

local function IdentifyGameState()
    if game.PlaceId == 3260590327 then
        return "LOBBY"
    else
        return "GAME"
    end
end

local GameState = IdentifyGameState()

local function StartAntiAfk()
    task.spawn(function()
        local LobbyTimer = 0
        while GameState == "LOBBY" do 
            task.wait(1)
            LobbyTimer = LobbyTimer + 1
            if LobbyTimer >= 600 then
                SmartTeleportToLobby()
                break 
            end
        end
    end)
end

StartAntiAfk()

local SendRequest = request or http_request or httprequest
    or GetDevice and GetDevice().request

if not SendRequest then 
    warn("failure: no http function") 
    return 
end

local BackToLobbyRunning = false
local AutoSkipRunning = false
local AntiLagRunning = false
local AutoChainRunning = false
local AutoDjRunning = false
local AutoNecroRunning = false
local AutoMercenaryBaseRunning = false
local AutoMilitaryBaseRunning = false
local AutoGatlingRunning = false
local GatlingExecuted = false
local IsCurrentlyLoading = false
local LastLoadTime = 0
local IsEquippingLoadout = false

local MaxPathDistance = 300
local MilMarker = nil
local MercMarker = nil

local CurrentEquippedTowers = {"None"}

local AutoMedicRunning = false

local AllModifiers = {
    "HiddenEnemies", "Glass", "ExplodingEnemies", "Limitation", 
    "Committed", "HealthyEnemies", "Fog", "FlyingEnemies", 
    "Broke", "SpeedyEnemies", "Quarantine", "JailedTowers", "Inflation"
}

local DefaultSettings = {
    AutoSkip = false,
    AutoReady = false,
    AutoChain = false,
    AutoGatling = false,
    SupportCaravan = false,
    AutoDJ = false,
    AutoNecro = false,
    AutoRejoin = false,
    AutoRestart = false,
    AutoMercenary = false,
    AutoMilitary = false,
    AntiLag = false,
    Disable3DRendering = false,
    NoRecoil = false,
    AutoMedic = false,
	AutoReset = false,
	AutoBack = false,
	PrivateCode = "",
}

local ItemNames = {
    ["17438486690"] = "Range Flag(s)",
    ["17438486138"] = "Damage Flag(s)",
    ["17438487774"] = "Cooldown Flag(s)",
    ["17429537022"] = "Blizzard(s)",
    ["17448596749"] = "Napalm Strike(s)",
    ["18493073533"] = "Spin Ticket(s)",
    ["17429548305"] = "Supply Drop(s)",
    ["18443277308"] = "Low Grade Consumable Crate(s)",
    ["136180382135048"] = "Santa Radio(s)",
    ["18443277106"] = "Mid Grade Consumable Crate(s)",
    ["18443277591"] = "High Grade Consumable Crate(s)",
    ["132155797622156"] = "Christmas Tree(s)",
    ["124065875200929"] = "Fruit Cake(s)",
    ["17429541513"] = "Barricade(s)",
    ["110415073436604"] = "Holy Hand Grenade(s)",
    ["17429533728"] = "Frag Grenade(s)",
    ["17437703262"] = "Molotov(s)",
    ["139414922355803"] = "Present Clusters(s)"
}

local executed_actions = {}

TDS = {
    PlacedTowers = {},
    ActiveStrat = true,
    IsEquippingLoadout = false,
    LoadoutPending = false,
    MatchmakingMap = {
        ["PizzaParty"] = "halloween",
        ["Badlands"] = "badlands",
        ["PollutedWasteland"] = "polluted",
        ["DuckyEasy"] = "ducky2025",
        ["DuckyHard"] = "ducky2025"
    }
}
TDS["placed_towers"] = TDS.PlacedTowers
TDS["active_strat"] = TDS.ActiveStrat
TDS["matchmaking_map"] = TDS.MatchmakingMap

local UpgradeHistory = {}

shared.TDSTable = TDS
shared["TDS_Table"] = TDS

function TDS:ResetAllStates()
    self.__matchRestarted = true
    if self.PlacedTowers and type(self.PlacedTowers) == "table" then pcall(table.clear, self.PlacedTowers) end
    self.PlacedTowers = {}
    self["placed_towers"] = self.PlacedTowers
    if self.PlacedTraps and type(self.PlacedTraps) == "table" then pcall(table.clear, self.PlacedTraps) end
    self.PlacedTraps = {}
    if self.MapInteractions and type(self.MapInteractions) == "table" then pcall(table.clear, self.MapInteractions) end
    self.MapInteractions = {}
    if UpgradeHistory and type(UpgradeHistory) == "table" then pcall(table.clear, UpgradeHistory) end
    if self.UpgradeHistory and type(self.UpgradeHistory) == "table" then pcall(table.clear, self.UpgradeHistory) end
    if executed_actions and type(executed_actions) == "table" then pcall(table.clear, executed_actions) end
    if Logger and Logger.Clear then
        pcall(function()
            Logger:Clear()
        end)
    end
    warn("[TDS:ResetAllStates] All states, indices, and action histories reset.")
    return true
end

function TDS:RunStrategy()
    local currentMatchId = (game.JobId ~= "" and game.JobId) or tostring(game.PlaceInstanceId or "MatchInstance")
    if getgenv and getgenv().__WIN_STRAT_EXECUTED_JOB_ID == currentMatchId then
        warn("[TDS:RunStrategy] BLOCKED: Win condition single-execution locked for match " .. tostring(currentMatchId))
        return
    end

    if Globals.activeStrategyThread then
        pcall(task.cancel, Globals.activeStrategyThread)
        Globals.activeStrategyThread = nil
    end

    Globals.activeStrategyThread = task.spawn(function()
        Globals.tdsReplaying = true
        pcall(function()
            loadstring(readfile("ADS_LastStrat.lua"))()
        end)
        Globals.tdsReplaying = false
        Globals.activeStrategyThread = nil
    end)
end

local function SaveSettings()
    local DataToSave = {}
    for key, _ in pairs(DefaultSettings) do
        DataToSave[key] = Globals[key]
    end
    writefile(FileName, HttpService:JSONEncode(DataToSave))
end

local function LoadSettings()
    local data = {}
    if isfile(FileName) then
        pcall(function()
            data = HttpService:JSONDecode(readfile(FileName))
        end)
    end

    for key, DefaultVal in pairs(DefaultSettings) do
        if Globals[key] == nil then
            if data[key] ~= nil then
                Globals[key] = data[key]
            else
                Globals[key] = DefaultVal
            end
        end
    end
    
    SaveSettings()
end

local function SetSetting(name, value)
    if DefaultSettings[name] ~= nil then
        Globals[name] = value
        SaveSettings()
    end
end

local function Apply3dRendering()
    if Globals.Disable3DRendering then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    else
        RunService:Set3dRenderingEnabled(true)
    end
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local gui = PlayerGui and PlayerGui:FindFirstChild("ADS_BlackScreen")
    if Globals.Disable3DRendering then
        if PlayerGui and not gui then
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
        end
        gui.Enabled = true
    else
        if gui then
            gui.Enabled = false
        end
    end
end

LoadSettings()
Apply3dRendering()

local function FindPath()
    local MapFolder = workspace:FindFirstChild("Map")
    if not MapFolder then return nil end
    local PathsFolder = MapFolder:FindFirstChild("Paths")
    if not PathsFolder then return nil end
    local PathFolder = PathsFolder:GetChildren()[1]
    if not PathFolder then return nil end

    local PathNodes = {}
    for _, node in ipairs(PathFolder:GetChildren()) do
        if node:IsA("BasePart") then
            table.insert(PathNodes, node)
        end
    end

    table.sort(PathNodes, function(a, b)
        local NumA = tonumber(a.Name:match("%d+"))
        local NumB = tonumber(b.Name:match("%d+"))
        if NumA and NumB then return NumA < NumB end
        return a.Name < b.Name
    end)

    return PathNodes
end

local function TotalLength(PathNodes)
    local TotalLength = 0
    for i = 1, #PathNodes - 1 do
        TotalLength = TotalLength + (PathNodes[i + 1].Position - PathNodes[i].Position).Magnitude
    end
    return TotalLength
end

local MercenarySlider
local MilitarySlider
local MaxLenght

local function CalcLength()
    local map = workspace:FindFirstChild("Map")

    if GameState == "GAME" and map then
        local PathNodes = FindPath()

        if PathNodes and #PathNodes > 0 then
            MaxPathDistance = TotalLength(PathNodes)

            if MercenarySlider then
                MercenarySlider:SetMax(MaxPathDistance) 
            end

            if MilitarySlider then
                MilitarySlider:SetMax(MaxPathDistance)
            end

            if MaxLenght then
                MaxLenght = MaxPathDistance
            end
            return true
        end
    end
    return false
end

local function GetPointAtDistance(PathNodes, distance)
    if not PathNodes or #PathNodes < 2 then return nil end

    local CurrentDist = 0
    for i = 1, #PathNodes - 1 do
        local StartPos = PathNodes[i].Position
        local EndPos = PathNodes[i+1].Position
        local SegmentLen = (EndPos - StartPos).Magnitude

        if CurrentDist + SegmentLen >= distance then
            local remaining = distance - CurrentDist
            local direction = (EndPos - StartPos).Unit
            return StartPos + (direction * remaining)
        end
        CurrentDist = CurrentDist + SegmentLen
    end
    return PathNodes[#PathNodes].Position
end

local function UpdatePathVisuals()
    if not Globals.PathVisuals then
        if MilMarker then 
            MilMarker:Destroy() 
            MilMarker = nil 
        end
        if MercMarker then 
            MercMarker:Destroy() 
            MercMarker = nil 
        end
        return
    end

    local PathNodes = FindPath()
    if not PathNodes then return end

    if not MilMarker then
        MilMarker = Instance.new("Part")
        MilMarker.Name = "MilVisual"
        MilMarker.Shape = Enum.PartType.Cylinder
        MilMarker.Size = Vector3.new(0.3, 3, 3)
        MilMarker.Color = Color3.fromRGB(0, 255, 0)
        MilMarker.Material = Enum.Material.Plastic
        MilMarker.Anchored = true
        MilMarker.CanCollide = false
        MilMarker.Orientation = Vector3.new(0, 0, 90)
        MilMarker.Parent = workspace
    end

    if not MercMarker then
        MercMarker = MilMarker:Clone()
        MercMarker.Name = "MercVisual"
        MercMarker.Color = Color3.fromRGB(255, 0, 0)
        MercMarker.Parent = workspace
    end

    local MilPos = GetPointAtDistance(PathNodes, Globals.MilitaryPath or 0)
    local MercPos = GetPointAtDistance(PathNodes, Globals.MercenaryPath or 0)

    if MilPos then
        MilMarker.Position = MilPos + Vector3.new(0, 0.2, 0)
        MilMarker.Transparency = 0.7
    end
    if MercPos then
        MercMarker.Position = MercPos + Vector3.new(0, 0.2, 0)
        MercMarker.Transparency = 0.7
    end
end

local function MissionsUIFix()
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local MissionsScrollingFrame = game:GetService("Players").LocalPlayer.PlayerGui.ReactLobbyQuests.quests.missions.scrollingFrame
                local MissionsListLayout = MissionsScrollingFrame.listLayout
                local MissionFrame = MissionsScrollingFrame["1"]
                if MissionFrame.AbsoluteSize.Y > 0 then
                    local UIScaleRatio = MissionFrame.AbsoluteSize.Y / MissionFrame.Size.Y.Offset
                    local CurrentCanvasSize = MissionsScrollingFrame.CanvasSize
                    local CanvasHeight = (MissionsListLayout.AbsoluteContentSize.Y / UIScaleRatio) + 25
                    MissionsScrollingFrame.CanvasSize = UDim2.new(CurrentCanvasSize.X.Scale, CurrentCanvasSize.X.Offset, CurrentCanvasSize.Y.Scale, CanvasHeight)
                end
            end)
        end
    end)
end

local function GetEquippedTowers()
    local towers = {}
    local StateReplicators = ReplicatedStorage:FindFirstChild("StateReplicators")

    if StateReplicators then
        for _, folder in ipairs(StateReplicators:GetChildren()) do
            if folder.Name == "PlayerReplicator" and folder:GetAttribute("UserId") == LocalPlayer.UserId then
                local equipped = folder:GetAttribute("EquippedTowers")
                if type(equipped) == "string" then
                    local CleanedJson = equipped:match("%[.*%]") 
                    local success, TowerTable = pcall(function()
                        return HttpService:JSONDecode(CleanedJson)
                    end)

                    if success and type(TowerTable) == "table" then
                        for i = 1, 5 do
                            if TowerTable[i] then
                                table.insert(towers, TowerTable[i])
                            end
                        end
                    end
                end
            end
        end
    end
    return #towers > 0 and towers or {"None"}
end

CurrentEquippedTowers = GetEquippedTowers()

local function RunVoteSkip()
    while true do
        local success = pcall(function()
            RemoteFunc:InvokeServer("Voting", "Skip")
        end)
        if success then break end
        task.wait(0.1)
    end
end

AutoReadyRunning = false

local function StartAutoReady()
    if AutoReadyRunning or not Globals.AutoReady or GameState ~= "GAME" then return end
    AutoReadyRunning = true

    task.spawn(function()
        local voteReplicator = ReplicatedStorage:WaitForChild("StateReplicators"):WaitForChild("VoteReplicator")
        
        repeat 
            task.wait(0.1) 
            if not Globals.AutoReady then 
                AutoReadyRunning = false
                return 
            end
        until voteReplicator:GetAttribute("Enabled") == true and voteReplicator:GetAttribute("Title") == "Ready?"
        
        if not Globals.AutoReady then
            AutoReadyRunning = false
            return
        end

        RunVoteSkip()
        
        repeat 
            task.wait(0.1) 
        until voteReplicator:GetAttribute("Enabled") == false or not Globals.AutoReady
        
        AutoReadyRunning = false
    end)
end

local function CheckResOk(data)
    if data == true then return true end
    if type(data) == "table" and data.Success == true then return true end

    local success, IsModel = pcall(function()
        return data and data:IsA("Model")
    end)

    if success and IsModel then return true end
    if type(data) == "userdata" then return true end

    return false
end

local function RejoinMatch()
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction")
    local success = false
    local res

    if Globals.PrivateCode and Globals.PrivateCode ~= "" and not IsMobile then
        SmartTeleportToLobby()
        task.wait(9e9)
        return
    end

    repeat
        local StateFolder = ReplicatedStorage:FindFirstChild("State")
        local CurrentMode = StateFolder and StateFolder.Difficulty.Value
        if not CurrentMode or CurrentMode == "" then
            CurrentMode = TDS.SavedDifficulty
        end

        if CurrentMode and CurrentMode ~= "" then
            local ok, result = pcall(function()
                local payload
                local EventMode = StateFolder:FindFirstChild("Mode") and StateFolder.Mode.Value

                if CurrentMode == "PizzaParty" then
                    payload = {
                        mode = "halloween",
                        count = 1
                    }
                elseif tostring(EventMode or ""):lower() == "hardcore" then
                    payload = {
                        difficulty = CurrentMode,
                        mode = "hardcore",
                        count = 1
                    }
                elseif CurrentMode == "PollutedWasteland" then
                    payload = {
                        mode = "polluted",
                        count = 1
                    }
                elseif CurrentMode == "Badlands" then
                    payload = {
                        mode = "badlands",
                        count = 1
                    }
                elseif EventMode == "DuckEvent" then
                    payload = {
                        difficulty = CurrentMode,
                        mode = "ducky2025",
                        count = 1
                    }
                elseif CurrentMode == "Trial" then
                    SmartTeleportToLobby()
                    return true
                else
                    payload = {
                        difficulty = CurrentMode,
                        mode = "survival",
                        count = 1
                    }
                end

                return remote:InvokeServer("Multiplayer", "v2:start", payload)
            end)

            if ok and CheckResOk(result) then
                success = true
                res = result
            else
                task.wait(0.5) 
            end
        else
            task.wait(1)
        end
    until success

    return res
end

local function MatchReadyUp()
    local stateReplicators = ReplicatedStorage:WaitForChild("StateReplicators")
    local voteReplicator = stateReplicators:WaitForChild("VoteReplicator")
    local gameStateReplicator = stateReplicators:WaitForChild("GameStateReplicator")

    if gameStateReplicator:GetAttribute("GameStarted") == true then
        return
    end
    
    local voteTitle = voteReplicator:GetAttribute("Title")
    if voteTitle == "Ready?" and voteReplicator:GetAttribute("Enabled") == true then
        RunVoteSkip()
        return
    end

    local yieldSignal = Instance.new("BindableEvent")
    local voteConnection
    local gameStartedConnection

    voteConnection = voteReplicator.AttributeChanged:Connect(function(attributeName)
        if attributeName == "Enabled" and voteReplicator:GetAttribute("Enabled") == true then
            if voteReplicator:GetAttribute("Title") == "Ready?" then
                RunVoteSkip()
                yieldSignal:Fire()
            end
        elseif attributeName == "Title" and voteReplicator:GetAttribute("Title") ~= "Ready?" then
            yieldSignal:Fire()
        elseif attributeName == "VoteCount" or attributeName == "MaxVotes" then
            local currentVotes = voteReplicator:GetAttribute("VoteCount")
            local maxVotesRequired = voteReplicator:GetAttribute("MaxVotes")
            if currentVotes and maxVotesRequired and maxVotesRequired > 0 and currentVotes >= maxVotesRequired then
                yieldSignal:Fire()
            end
        end
    end)

    gameStartedConnection = gameStateReplicator:GetAttributeChangedSignal("GameStarted"):Connect(function()
        if gameStateReplicator:GetAttribute("GameStarted") == true then
            yieldSignal:Fire()
        end
    end)

    yieldSignal.Event:Wait()

    if voteConnection then
        voteConnection:Disconnect()
    end
    if gameStartedConnection then
        gameStartedConnection:Disconnect()
    end
    yieldSignal:Destroy()
end

local function TriggerRestart()
    if typeof(WaitForRewardScreen) == "function" then
        WaitForRewardScreen(35)
    else
        local UiRoot = PlayerGui:WaitForChild("ReactGameNewRewards", 30)
        local FoundSection = false
        local t0 = tick()
        repeat
            task.wait(0.3)
            local f = UiRoot and UiRoot:FindFirstChild("Frame")
            local g = f and f:FindFirstChild("gameOver")
            local s = g and g:FindFirstChild("RewardsScreen")
            if s and s:FindFirstChild("RewardsSection") then
                FoundSection = true
            end
        until FoundSection or (tick() - t0 >= 30)
    end

    task.wait(2)
    RunVoteSkip()
end

local function GetCurrentWave()
    local label

    repeat
        task.wait(0.5)
        label = PlayerGui:FindFirstChild("ReactGameTopGameDisplay", true) 
            and PlayerGui.ReactGameTopGameDisplay.Frame.wave.container:FindFirstChild("value")
    until label ~= nil

    local text = label.Text
    local WaveNum = text:match("(%d+)")

    return tonumber(WaveNum) or 0
end

local function DoPlaceTower(TName, TPos)
    local retries = 0
    while true do
        local ok, res = pcall(function()
            return RemoteFunc:InvokeServer("Troops", "Place", {
                Rotation = CFrame.new(),
                Position = TPos
            }, TName)
        end)
 
        if ok and CheckResOk(res) then return true end
        retries = retries + 1
        task.wait(0.25)
    end
end

local function DoUpgradeTower(TObj, PathId)
    if not TObj then
        return false
    end
    local retries = 0
    while true do
        local ok, res = pcall(function()
            return RemoteFunc:InvokeServer("Troops", "Upgrade", "Set", {
                Troop = TObj,
                Path = PathId
            })
        end)
        if ok and CheckResOk(res) then return true end
        retries = retries + 1
        task.wait(0.25)
    end
end

local function DoSellTower(TObj)
    while true do
        local ok, res = pcall(function()
            return RemoteFunc:InvokeServer("Troops", "Sell", { Troop = TObj })
        end)
        if ok and CheckResOk(res) then return true end
        task.wait(0.25)
    end
end

local function DoSetOption(TObj, OptName, OptVal, ReqWave)
    if ReqWave then
        repeat task.wait(0.3) until GetCurrentWave() >= ReqWave
    end

    while true do
        local ok, res = pcall(function()
            return RemoteFunc:InvokeServer("Troops", "Option", "Set", {
                Troop = TObj,
                Name = OptName,
                Value = OptVal
            })
        end)
        if ok and CheckResOk(res) then return true end
        task.wait(0.25)
    end
end

local function DoActivateAbility(TObj, AbName, AbData, IsLooping, IsStack)
    if type(AbData) == "boolean" then
        IsStack = IsLooping
        IsLooping = AbData
        AbData = nil
    end

    AbData = type(AbData) == "table" and AbData or nil

    local positions
    if AbData and type(AbData.towerPosition) == "table" then
        positions = AbData.towerPosition
    end

    local CloneIdx = AbData and AbData.towerToClone
    local TargetIdx = AbData and AbData.towerTarget

    local function attempt()
        while true do
            local ok, res = pcall(function()
                local data

                if AbData then
                    data = table.clone(AbData)

                    if positions and #positions > 0 then
                        data.towerPosition = positions[math.random(#positions)]
                    end

                    if (IsStack == true or IsStack == "stack") and typeof(data.towerPosition) == "Vector3" then
                        data.towerPosition = data.towerPosition + Vector3.new(0, 20, 0)
                    end

                    if type(CloneIdx) == "number" then
                        data.towerToClone = TDS.PlacedTowers[CloneIdx]
                    end

                    if type(TargetIdx) == "number" then
                        data.towerTarget = TDS.PlacedTowers[TargetIdx]
                    end
                end

                return RemoteFunc:InvokeServer(
                    "Troops",
                    "Abilities",
                    "Activate",
                    {
                        Troop = TObj,
                        Name = AbName,
                        Data = data
                    }
                )
            end)

            if ok and CheckResOk(res) then
                return true
            end

            task.wait(0.25)
        end
    end

    if IsLooping then
        local active = true
        task.spawn(function()
            while active do
                attempt()
                task.wait(1)
            end
        end)
        return function() active = false end
    end

    return attempt()
end

function TDS:Mode(difficulty, code)
    self.SavedDifficulty = difficulty
    -- Only use private code if explicitly provided in TDS:Mode call!
    local targetCode = (code and tostring(code) ~= "") and tostring(code) or ""
    self.PrivateCode = targetCode

    if GameState ~= "LOBBY" then 
        return false 
    end

    -- If an explicit private server link or code was passed, teleport there first if not already in VIP
    if targetCode ~= "" then
        local ownsVipPass = false
        pcall(function()
            ownsVipPass = MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, 10518590)
        end)
        if not ownsVipPass then
            local ServerType = (game.PrivateServerId ~= "" and "VIPServer" or "Public")
            pcall(function()
                local rrs = game:GetService("RobloxReplicatedStorage")
                if rrs and rrs:FindFirstChild("GetServerType") then
                    ServerType = rrs.GetServerType:InvokeServer()
                end
            end)
            
            if ServerType ~= "VIPServer" then
                local launched = launchOrTeleportPrivateServer(game.PlaceId, targetCode, LocalPlayer)
                return true
            end
        end
    end

    local diffLower = tostring(difficulty or "Molten"):lower()

    -- Trial mode handling:
    if diffLower == "trial" or diffLower == "trials" then
        local remote = ReplicatedStorage:FindFirstChild("RemoteFunction") or game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction", 5)
        if remote then
            pcall(function() remote:InvokeServer("Multiplayer", "v2:stop") end)
            task.wait(0.2)
            pcall(function() remote:InvokeServer("Multiplayer", "v2:start", { count = 1, mode = "Trials" }) end)
            return true
        end

        local Elevators = workspace:FindFirstChild("TrialElevators")
        local Network = ReplicatedStorage:FindFirstChild("Network")
        if Elevators and Network then
            local targetElevator = nil
            for _, v in pairs(Elevators:GetChildren()) do
                if v.Name:match("Elevator") then
                    targetElevator = v
                    break
                end
            end
            if targetElevator then
                task.spawn(function()
                    local ElevatorsNet = Network:FindFirstChild("Elevators")
                    if ElevatorsNet then
                        local EnterRemote = ElevatorsNet:FindFirstChild("RF:Enter")
                        local SetSizeRemote = ElevatorsNet:FindFirstChild("RF:SetSize")
                        local SetReadyRemote = ElevatorsNet:FindFirstChild("RF:SetReady")
                        if EnterRemote then pcall(function() EnterRemote:InvokeServer(targetElevator) end) end
                        if SetSizeRemote then pcall(function() SetSizeRemote:InvokeServer(1) end) end
                        if SetReadyRemote then pcall(function() SetReadyRemote:InvokeServer(true) end) end
                    end
                end)
                return true
            end
        end
    end

    -- Matchmaking Queue
    local remote = ReplicatedStorage:FindFirstChild("RemoteFunction") or game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction", 5)
    if not (remote and remote:IsA("RemoteFunction")) then
        warn("[TDS_API] RemoteFunction not found in ReplicatedStorage!")
        return false
    end

    -- Reset any stale queue / party state
    pcall(function()
        remote:InvokeServer("Multiplayer", "v2:stop")
    end)
    task.wait(0.2)

    local mode = TDS.MatchmakingMap and TDS.MatchmakingMap[difficulty]
    local payload

    if diffLower == "hardcore" then
        payload = {
            mode = "hardcore",
            difficulty = "Easy",
            count = 1
        }
    elseif diffLower == "voidcore" then
        payload = {
            mode = "hardcore",
            difficulty = "Hard",
            count = 1
        }
    elseif mode then
        payload = {
            mode = mode,
            count = 1
        }
        if difficulty:match("Ducky") then
            payload.difficulty = difficulty:gsub("Ducky", "")
        end
    else
        -- Standard survival modes (Molten, Fallen, Intermediate, Casual, Easy, etc.)
        local formattedDiff = "Molten"
        if diffLower == "molten" then formattedDiff = "Molten"
        elseif diffLower == "fallen" then formattedDiff = "Fallen"
        elseif diffLower == "intermediate" then formattedDiff = "Intermediate"
        elseif diffLower == "casual" then formattedDiff = "Casual"
        elseif diffLower == "easy" then formattedDiff = "Easy"
        else
            formattedDiff = difficulty
        end

        payload = {
            difficulty = formattedDiff,
            mode = "survival",
            count = 1
        }
    end

    local queued = false
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return remote:InvokeServer("Multiplayer", "v2:start", payload)
        end)
        if ok then
            queued = true
            pcall(function()
                Logger:Info(string.format("[TDS_API] Successfully queued match (%s - %s).", tostring(payload.mode), tostring(payload.difficulty or "N/A")))
            end)
            break
        else
            task.wait(0.5)
        end
    end

    return queued
end

function TDS:Loadout(...)
    while IsCurrentlyLoading do
        task.wait(0.2)
    end

    IsCurrentlyLoading = true
    IsEquippingLoadout = true
    self.IsEquippingLoadout = true

    local function extractTowerName(t: any): string?
        if type(t) == "string" then
            return t
        elseif type(t) == "table" then
            if type(t.Name) == "string" then return t.Name end
            if type(t.name) == "string" then return t.name end
            if type(t[1]) == "string" then return t[1] end
        end
        return nil
    end

    local function isIgnoredPlaceholder(t: any): boolean
        local s = extractTowerName(t)
        if not s then return true end
        s = s:gsub("^%s+", ""):gsub("%s+$", ""):lower()
        return s == "" or s == "none" or s == "empty" or s == "nil" or s == "false" or s == "placeholder"
    end

    local rawArgs = {...}
    local towers = {}
    local function addTower(item)
        if not isIgnoredPlaceholder(item) then
            local tName = extractTowerName(item)
            if tName then
                table.insert(towers, tName)
            end
        end
    end

    if #rawArgs == 1 and type(rawArgs[1]) == "table" and (rawArgs[1].Name == nil and rawArgs[1].name == nil) then
        for _, t in ipairs(rawArgs[1]) do
            addTower(t)
        end
    else
        for _, t in ipairs(rawArgs) do
            addTower(t)
        end
    end

    local remote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")
    local remoteFunc = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction")

    local function normalizeKey(name: any): string
        local raw = extractTowerName(name)
        if not raw or isIgnoredPlaceholder(raw) then return "" end
        local trimmed = raw:gsub("^%s*(.-)%s*$", "%1"):lower()
        local isGolden = false
        if trimmed:sub(1, 7) == "golden " then
            isGolden = true
            trimmed = trimmed:sub(8)
        end
        local cleanKey = trimmed:gsub("%s+", "")
        return (isGolden and "golden_" or "") .. cleanKey
    end

    local function readEquipped(): {string}
        local eq = {}
        local stateReps = ReplicatedStorage:FindFirstChild("StateReplicators")
        if stateReps then
            local myRep = nil
            for _, folder in ipairs(stateReps:GetChildren()) do
                local uId = folder:GetAttribute("UserId")
                local pName = folder:GetAttribute("Name")
                if folder.Name == "PlayerReplicator" or folder.Name:find("PlayerReplicator") then
                    if uId == LocalPlayer.UserId or tostring(uId) == tostring(LocalPlayer.UserId) or pName == LocalPlayer.Name or pName == LocalPlayer.DisplayName then
                        myRep = folder
                        break
                    end
                end
            end
            if not myRep then
                for _, folder in ipairs(stateReps:GetChildren()) do
                    local uId = folder:GetAttribute("UserId")
                    if uId == LocalPlayer.UserId or tostring(uId) == tostring(LocalPlayer.UserId) then
                        myRep = folder
                        break
                    end
                end
            end
            if not myRep then
                myRep = stateReps:FindFirstChild("PlayerReplicator")
            end

            if myRep then
                local equippedAttr = myRep:GetAttribute("EquippedTowers")
                if type(equippedAttr) == "string" then
                    local cleanedJson = equippedAttr:match("%[.*%]")
                    if cleanedJson then
                        local ok, decoded = pcall(function()
                            return HttpService:JSONDecode(cleanedJson)
                        end)
                        if ok and type(decoded) == "table" then
                            for _, name in ipairs(decoded) do
                                if type(name) == "string" and name ~= "None" and name ~= "" then
                                    table.insert(eq, name)
                                end
                            end
                        end
                    end
                elseif type(equippedAttr) == "table" then
                    for _, name in ipairs(equippedAttr) do
                        if type(name) == "string" and name ~= "None" and name ~= "" then
                            table.insert(eq, name)
                        end
                    end
                end
            end
        end

        -- Fallback 1: DataHandler
        if #eq == 0 and DataHandler and typeof(DataHandler.GetEquippedTowers) == "function" then
            pcall(function()
                local eqList = DataHandler:GetEquippedTowers()
                if type(eqList) == "table" then
                    for _, name in ipairs(eqList) do
                        if type(name) == "string" and name ~= "None" and name ~= "" then
                            table.insert(eq, name)
                        end
                    end
                end
            end)
        end

        -- Fallback 2: Legacy InventoryController (Lobby)
        if #eq == 0 then
            pcall(function()
                local client = ReplicatedStorage:FindFirstChild("Client")
                local interfaces = client and client:FindFirstChild("Interfaces")
                local legacy = interfaces and interfaces:FindFirstChild("LegacyInterface")
                local controllers = legacy and legacy:FindFirstChild("Controllers")
                local invCtrlMod = controllers and controllers:FindFirstChild("InventoryController")
                if invCtrlMod then
                    local InvCtrl = require(invCtrlMod)
                    if InvCtrl and type(InvCtrl.getItems) == "function" then
                        local items = InvCtrl:getItems()
                        if items then
                            for _, item in pairs(items) do
                                if type(item) == "table" and item.type == "tower" and item.equipped == true and item.name then
                                    table.insert(eq, item.name)
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- Fallback 3: Cache Troops
        if #eq == 0 then
            pcall(function()
                local client = ReplicatedStorage:FindFirstChild("Client")
                local modules = client and client:FindFirstChild("Modules")
                local cacheMod = modules and modules:FindFirstChild("Cache")
                if cacheMod then
                    local Cache = require(cacheMod)
                    local eqAtom = Cache and Cache("Equipped.Troops")
                    local eqData = eqAtom and type(eqAtom.GetValue) == "function" and eqAtom:GetValue()
                    if type(eqData) == "table" then
                        for _, tName in ipairs(eqData) do
                            if type(tName) == "string" and tName ~= "" and tName ~= "None" then
                                table.insert(eq, tName)
                            end
                        end
                    end
                    if #eq == 0 then
                        local atom = Cache and Cache("Inventory.Troops")
                        local troops = atom and type(atom.GetValue) == "function" and atom:GetValue()
                        if type(troops) == "table" then
                            for tName, tData in pairs(troops) do
                                if type(tData) == "table" and tData.Equipped == true then
                                    table.insert(eq, tName)
                                end
                            end
                        end
                    end
                end
            end)
        end

        return eq
    end

    local success = pcall(function()
        local CurrentlyEquipped = readEquipped()
        if #CurrentlyEquipped == 0 then
            for _ = 1, 10 do
                task.wait(0.2)
                CurrentlyEquipped = readEquipped()
                if #CurrentlyEquipped > 0 then break end
            end
        end

        local function getExactTowerName(tName)
            local raw = extractTowerName(tName)
            if not raw or isIgnoredPlaceholder(raw) then return tostring(tName or "") end
            local trimmed = tostring(raw):gsub("^%s*(.-)%s*$", "%1")
            local cleanKey = trimmed:lower():gsub("^golden%s+", ""):gsub("%s+", "")
            local lowerT = string.lower(trimmed)
            local resolved = trimmed

            pcall(function()
                local client = ReplicatedStorage:FindFirstChild("Client")
                local modules = client and client:FindFirstChild("Modules")
                local cacheMod = modules and modules:FindFirstChild("Cache")
                if cacheMod then
                    local Cache = require(cacheMod)
                    local atom = Cache and Cache("Inventory.Troops")
                    local troops = atom and atom:GetValue()
                    if type(troops) == "table" then
                        for realName, _ in pairs(troops) do
                            local realClean = string.lower(tostring(realName)):gsub("%s+", "")
                            if realClean == cleanKey or string.lower(tostring(realName)) == lowerT then
                                resolved = realName
                                return
                            end
                        end
                    end
                end
            end)

            if resolved == trimmed then
                pcall(function()
                    local client = ReplicatedStorage:FindFirstChild("Client")
                    local interfaces = client and client:FindFirstChild("Interfaces")
                    local legacy = interfaces and interfaces:FindFirstChild("LegacyInterface")
                    local controllers = legacy and legacy:FindFirstChild("Controllers")
                    local invCtrlMod = controllers and controllers:FindFirstChild("InventoryController")
                    if invCtrlMod then
                        local InvCtrl = require(invCtrlMod)
                        if InvCtrl and type(InvCtrl.getItems) == "function" then
                            local items = InvCtrl:getItems()
                            if items then
                                for _, item in pairs(items) do
                                    if type(item) == "table" and item.type == "tower" and item.name then
                                        local rName = tostring(item.name)
                                        local realClean = string.lower(rName):gsub("%s+", "")
                                        if realClean == cleanKey or string.lower(rName) == lowerT then
                                            resolved = rName
                                            return
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            if resolved == trimmed and DataHandler and type(DataHandler.ownedTowers) == "table" then
                for realName, _ in pairs(DataHandler.ownedTowers) do
                    local realClean = string.lower(tostring(realName)):gsub("%s+", "")
                    if realClean == cleanKey or string.lower(tostring(realName)) == lowerT then
                        resolved = realName
                        break
                    end
                end
            end

            return resolved
        end

        local matchedCurrentIndices = {}
        local matchedTargetIndices = {}

        -- Match target towers against currently equipped towers
        for tIdx, targetName in ipairs(towers) do
            local tKey = normalizeKey(targetName)
            if tKey ~= "" then
                for cIdx, currentName in ipairs(CurrentlyEquipped) do
                    if not matchedCurrentIndices[cIdx] and not matchedTargetIndices[tIdx] then
                        local cKey = normalizeKey(currentName)
                        if cKey == tKey then
                            matchedCurrentIndices[cIdx] = true
                            matchedTargetIndices[tIdx] = true
                            break
                        end
                    end
                end
            end
        end

        -- Towers currently equipped that are NOT in target loadout (need to be unequipped/replaced)
        local toUnequip = {}
        for cIdx, currentName in ipairs(CurrentlyEquipped) do
            if not matchedCurrentIndices[cIdx] then
                table.insert(toUnequip, currentName)
            end
        end

        -- Target towers that are missing from current loadout (need to be equipped)
        local toEquip = {}
        for tIdx, targetName in ipairs(towers) do
            if not matchedTargetIndices[tIdx] then
                table.insert(toEquip, targetName)
            end
        end

        -- If all target towers are already equipped and no unwanted towers are equipped, nothing to do!
        if #toUnequip == 0 and #toEquip == 0 then
            warn("[TDS:Loadout] Target towers already equipped, no changes needed.")
            if Logger and Logger.Info then
                Logger:Info("[TDS:Loadout] All requested towers already equipped; skipping swap.")
            end
            return true
        end

        warn(string.format("[TDS:Loadout] Smart swap: %d to unequip, %d to equip.", #toUnequip, #toEquip))

        -- 1. Unequip only towers that differ
        for _, currentTower in ipairs(toUnequip) do
            local unequipDone = false
            local attempts = 0
            repeat
                attempts = attempts + 1
                local ok = pcall(function()
                    if remoteFunc then
                        remoteFunc:InvokeServer("Inventory", "Unequip", "Tower", currentTower)
                    end
                    if remote then
                        remote:FireServer("Inventory", "Unequip", "Tower", currentTower)
                    end
                    task.wait(0.25)
                end)
                if ok then unequipDone = true else task.wait(0.2) end
            until unequipDone or attempts >= 4
        end

        if #toUnequip > 0 then
            task.wait(0.3)
        end

        -- 2. Equip missing towers into the freed slots
        for _, rawTowerName in ipairs(toEquip) do
            local towerName = getExactTowerName(rawTowerName)
            local equipSuccess = false
            local attempts = 0
            repeat
                attempts = attempts + 1
                local ok = pcall(function()
                    if remoteFunc then
                        remoteFunc:InvokeServer("Inventory", "Equip", "Tower", towerName)
                    end
                    if remote then
                        remote:FireServer("Inventory", "Equip", "Tower", towerName)
                    end
                    if Logger and Logger.Log then
                        Logger:Log("Equipped tower: " .. tostring(towerName))
                    end
                    task.wait(0.25)
                end)
                if ok then equipSuccess = true else task.wait(0.2) end
            until equipSuccess or attempts >= 4
        end

        if #toEquip > 0 then
            task.wait(0.3)
        end

        return true
    end)

    IsCurrentlyLoading = false
    IsEquippingLoadout = false
    self.IsEquippingLoadout = false
    self.LoadoutPending = false
    LastLoadTime = os.clock()

    return success
end

TDS.Loudout = TDS.Loadout

function TDS:VoteSkip(StartWave, EndWave)
    task.spawn(function()
        if not Globals.AutoSkip then
            return
        end
        local CurrentWave = GetCurrentWave()
        
        self.LastVoteSkipTarget = self.LastVoteSkipTarget or 0
        
        if not StartWave then
            if self.LastVoteSkipTarget < CurrentWave then
                self.LastVoteSkipTarget = CurrentWave
            else
                self.LastVoteSkipTarget = self.LastVoteSkipTarget + 1
            end
            StartWave = self.LastVoteSkipTarget
            EndWave = StartWave
        else
            EndWave = EndWave or StartWave
            self.LastVoteSkipTarget = EndWave
        end

        for wave = StartWave, EndWave do
            if not Globals.AutoSkip then break end
            while GetCurrentWave() < wave do
                if not Globals.AutoSkip then break end
                task.wait(1)
            end

            local TargetNextWave = wave + 1
            
            while GetCurrentWave() < TargetNextWave do
                if not Globals.AutoSkip then break end
                local VoteUi = PlayerGui:FindFirstChild("ReactOverridesVote")
                local VoteButton = VoteUi 
                    and VoteUi:FindFirstChild("Frame") 
                    and VoteUi.Frame:FindFirstChild("votes") 
                    and VoteUi.Frame.votes:FindFirstChild("vote", true)

                if VoteButton and VoteButton.Position == UDim2.new(0.5, 0, 0.5, 0) then
                    pcall(function()
                        RemoteFunc:InvokeServer("Voting", "Skip")
                    end)
                end
                
                task.wait(0.5)
            end
        end
    end)
end

local function LobbyReadyUp()
    pcall(function()
        local remoteFunc = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction")
        if remoteFunc and remoteFunc:IsA("RemoteFunction") then
            remoteFunc:InvokeServer("LobbyVoting", "Ready")
        end
    end)
    pcall(function()
        local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireServer("LobbyVoting", "Ready")
        end
    end)
    pcall(function()
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
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
        local netMod = game:GetService("ReplicatedStorage"):FindFirstChild("Shared") and game:GetService("ReplicatedStorage").Shared:FindFirstChild("Modules") and game:GetService("ReplicatedStorage").Shared.Modules:FindFirstChild("Network")
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
    for k, v in pairs(modsTable) do
        local modName = (type(k) == "string" and k ~= "") and k or (type(v) == "string" and v)
        if modName and (v == true or type(v) == "string") then
            selectedMods[modName] = true
        end
    end

    if next(selectedMods) and bulkModifiers then
        local ok, err = pcall(function()
            bulkModifiers:InvokeServer(selectedMods)
        end)
        if ok then
            warn(string.format(">>> [TDS:GameInfo] BulkVoteModifiers invoked successfully with %d modifiers.", (function() local c=0 for _ in pairs(selectedMods) do c=c+1 end return c end)()))
        else
            warn(string.format(">>> [TDS:GameInfo] BulkVoteModifiers error: %s", tostring(err)))
        end
        return ok
    end
    return false
end

TDS.CastModifierVote = CastModifierVote

local function MapNamesMatch(str1, str2)
    if not str1 or not str2 then return false end
    local s1 = tostring(str1):lower():gsub("[%s%p]+", "")
    local s2 = tostring(str2):lower():gsub("[%s%p]+", "")
    return s1 == s2 or s1:find(s2, 1, true) ~= nil or s2:find(s1, 1, true) ~= nil
end

local cachedApiBoardEntries = nil
local lastApiBoardScan = 0

local function FindBoardForMap(targetMap)
    if not targetMap or targetMap == "" or targetMap == "Unknown" then return false, nil end
    local now = tick()

    -- 1. Check workspace attributes Map1..Map4 first (instant 0ms)
    for i = 1, 4 do
        local attr = workspace:GetAttribute("Map" .. i)
        if attr and MapNamesMatch(attr, targetMap) then
            return true, Vector3.new(12.59, 10.64, 52.01)
        end
    end
    local wsMap = workspace:GetAttribute("Map")
    if wsMap and MapNamesMatch(wsMap, targetMap) then
        return true, Vector3.new(12.59, 10.64, 52.01)
    end

    -- 2. Fast cached board scan (0.001ms)
    if cachedApiBoardEntries and (now - lastApiBoardScan < 15) then
        local valid = true
        for _, entry in ipairs(cachedApiBoardEntries) do
            if not entry.label or not entry.label.Parent then valid = false; break end
            if entry.label.Text and MapNamesMatch(entry.label.Text, targetMap) then
                return true, entry.position
            end
        end
        if valid then return false, nil end
    end

    -- 3. Targeted container lookup (bypasses full 60k workspace traversal)
    local boardModels = {}
    pcall(function()
        local folders = {
            workspace:FindFirstChild("IntermissionLobby") and workspace.IntermissionLobby:FindFirstChild("Boards"),
            workspace:FindFirstChild("IntermissionLobby") and workspace.IntermissionLobby:FindFirstChild("MapDisplays"),
            workspace:FindFirstChild("Intermission") and workspace.Intermission:FindFirstChild("Boards"),
            workspace:FindFirstChild("Boards"),
            workspace:FindFirstChild("MapDisplays"),
            workspace:FindFirstChild("VotingBoards"),
            workspace:FindFirstChild("Voting"),
            workspace:FindFirstChild("Elevators"),
        }
        for _, f in ipairs(folders) do
            if f then
                for _, b in ipairs(f:GetChildren()) do
                    if b:IsA("Model") or b:IsA("BasePart") or b:FindFirstChild("MapDisplay", true) then
                        table.insert(boardModels, b)
                    end
                end
                if #boardModels > 0 then break end
            end
        end

        if #boardModels == 0 then
            for _, child in ipairs(workspace:GetChildren()) do
                local cName = child.Name:lower()
                if cName:find("board") or cName:find("intermission") or cName:find("voting") or cName:find("elevator") then
                    for _, b in ipairs(child:GetChildren()) do
                        table.insert(boardModels, b)
                    end
                    if #boardModels > 0 then break end
                end
            end
        end
    end)

    local newCache = {}
    local foundMatch, foundPos = false, nil
    for _, b in ipairs(boardModels) do
        local display = b:FindFirstChild("MapDisplay", true) or (b:IsA("SurfaceGui") and b)
        local title = display and (display:FindFirstChild("Title", true) or display:FindFirstChildWhichIsA("TextLabel", true))
        if title and title:IsA("TextLabel") then
            local hitboxes = b:FindFirstChild("Hitboxes") or (b.Parent and b.Parent:FindFirstChild("Hitboxes"))
            local bottom = hitboxes and (hitboxes:FindFirstChild("Bottom") or hitboxes:FindFirstChild("VotePlatform"))
            local pos = (bottom and bottom.Position) or (b:IsA("BasePart") and b.Position) or Vector3.new(12.59, 10.64, 52.01)
            table.insert(newCache, { label = title, position = pos })
            if not foundMatch and title.Text and MapNamesMatch(title.Text, targetMap) then
                foundMatch = true
                foundPos = pos
            end
        end
    end

    if #newCache > 0 then
        cachedApiBoardEntries = newCache
        lastApiBoardScan = now
    end

    if foundMatch then
        return true, foundPos
    end

    return false, nil
end


local function CheckBoardHasMap(targetMap)
    local found = FindBoardForMap(targetMap)
    return found
end

local function TriggerLobbyVeto()
    pcall(function()
        if RemoteEvent then
            RemoteEvent:FireServer("LobbyVoting", "Veto")
        elseif RemoteFunc then
            RemoteFunc:InvokeServer("LobbyVoting", "Veto")
        end
    end)
    pcall(function()
        local rf = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction")
        local re = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
        if re then re:FireServer("LobbyVoting", "Veto") end
        if rf then rf:InvokeServer("LobbyVoting", "Veto") end
    end)
    pcall(function()
        local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
        local rgi = pg and pg:FindFirstChild("ReactGameIntermission")
        local vetoBtn = rgi and rgi:FindFirstChild("Frame") and rgi.Frame:FindFirstChild("buttons") and rgi.Frame.buttons:FindFirstChild("veto")
        if vetoBtn then
            if firesignal and vetoBtn:FindFirstChild("Activated") then
                firesignal(vetoBtn.Activated)
            end
            if getconnections then
                for _, conn in ipairs(getconnections(vetoBtn.Activated)) do
                    if conn and conn.Function then pcall(conn.Function) end
                end
            end
        end
    end)
end

local function CastMapVote(mapId, posVec)
    local targetMap = mapId or "Simplicity"
    local targetPos = posVec or Vector3.new(12.59, 10.64, 52.01)
    warn(string.format(">>> [TDS:GameInfo] Casting Map Vote for '%s'...", tostring(targetMap)))
    pcall(function()
        local re = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent") or RemoteEvent
        if re then
            re:FireServer("LobbyVoting", "Vote", targetMap, targetPos)
        end
    end)
    pcall(function()
        local rf = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction") or RemoteFunc
        if rf then
            rf:InvokeServer("LobbyVoting", "Vote", targetMap, targetPos)
        end
    end)
end

local function WaitForIntermissionLoaded(timeout)
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

    if pg then
        pcall(function()
            pg:WaitForChild("ReactGameIntermission", 5)
        end)
    end

    task.wait(0.5) -- Brief settle time for map boards & remotes
    return true
end

local function CheckIsVipOrPrivateServer()
    -- 1. Explicit VIP flags
    if Globals then
        if Globals.IsVIP == true or Globals.VIP == true then return true end
    end
    if State and State.Misc then
        if State.Misc.IsVIP == true or State.Misc.VIP == true then return true end
    end

    -- 2. Game PrivateServerOwnerId (only actual VIP private servers have owner > 0)
    local isPriv = false
    pcall(function()
        if game.PrivateServerOwnerId and game.PrivateServerOwnerId > 0 then isPriv = true end
    end)
    if isPriv then return true end

    -- 3. GameStateReplicator IsPrivateServer / ClientModifiers
    local rs = game:GetService("ReplicatedStorage")
    local stateReps = rs:FindFirstChild("StateReplicators")
    local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
    if gsr then
        if gsr:GetAttribute("IsPrivateServer") == true then return true end
        local clientMods = gsr:GetAttribute("ClientModifiers")
        if type(clientMods) == "string" and clientMods:find("LegacyVIP") then return true end
    end

    -- 4. PlayerReplicator VIP attributes
    local lp = Players.LocalPlayer or LocalPlayer
    if stateReps and lp then
        for _, pr in ipairs(stateReps:GetChildren()) do
            if pr.Name == "PlayerReplicator" and pr:GetAttribute("UserId") == lp.UserId then
                if pr:GetAttribute("LegacyVIP") == true or pr:GetAttribute("VIPPlus") == true then
                    return true
                end
            end
        end
        local pr = stateReps:FindFirstChild("PlayerReplicator")
        if pr then
            if pr:GetAttribute("LegacyVIP") == true or pr:GetAttribute("VIPPlus") == true then
                return true
            end
        end
    end

    -- 5. MarketplaceService Gamepass Ownership (VIP 10518590, VIP+ 6745137, Legacy VIP 6912306)
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

local function AttemptMapOverride(targetMap)
    if not targetMap or targetMap == "" or targetMap == "Unknown" then return false end
    local overridden = false
    local rs = game:GetService("ReplicatedStorage")
    local rf = rs:FindFirstChild("RemoteFunction") or RemoteFunc
    local re = rs:FindFirstChild("RemoteEvent") or RemoteEvent

    warn(string.format(">>> [TDS:GameInfo] Attempting VIP Override for map '%s'...", tostring(targetMap)))

    if rf then
        local ok, res = pcall(function()
            return rf:InvokeServer("LobbyVoting", "Override", targetMap)
        end)
        if ok and res ~= false then
            overridden = true
            warn(string.format(">>> [TDS:GameInfo] VIP Override remote invoked: %s", tostring(res)))
        end
    end
    if re then
        pcall(function()
            re:FireServer("LobbyVoting", "Override", targetMap)
        end)
    end

    task.wait(2.5)
    pcall(CastMapVote, targetMap, Vector3.new(12.59, 10.64, 52.01))
    task.wait(0.5)
    LobbyReadyUp()
    return overridden
end

local function SelectMapOverride(MapId, ...)
    AttemptMapOverride(MapId)
end

TDS.CastMapVote = CastMapVote
TDS.SelectMapOverride = SelectMapOverride
TDS.CheckIsVipOrPrivateServer = CheckIsVipOrPrivateServer
TDS.AttemptMapOverride = AttemptMapOverride
TDS.SmartTeleportToLobby = SmartTeleportToLobby
TDS.SmartTeleportLobby = SmartTeleportToLobby
TDS.UniversalSmartLobby = SmartTeleportToLobby
function TDS:SmartTeleportToLobby(...) return SmartTeleportToLobby(...) end
function TDS:SmartTeleportLobby(...) return SmartTeleportToLobby(...) end
function TDS:UniversalSmartLobby(...) return SmartTeleportToLobby(...) end

if Globals then
    Globals.SmartTeleportToLobby = SmartTeleportToLobby
    Globals.SmartTeleportLobby = SmartTeleportToLobby
    Globals.UniversalSmartLobby = SmartTeleportToLobby
end
if typeof(getgenv) == "function" then
    getgenv().SmartTeleportToLobby = SmartTeleportToLobby
    getgenv().SmartTeleportLobby = SmartTeleportToLobby
    getgenv().UniversalSmartLobby = SmartTeleportToLobby
end
_G.SmartTeleportToLobby = SmartTeleportToLobby
_G.SmartTeleportLobby = SmartTeleportToLobby
_G.UniversalSmartLobby = SmartTeleportToLobby
if shared then
    shared.SmartTeleportToLobby = SmartTeleportToLobby
    shared.SmartTeleportLobby = SmartTeleportToLobby
    shared.UniversalSmartLobby = SmartTeleportToLobby
    if shared.TDSTable then
        shared.TDSTable.SmartTeleportToLobby = SmartTeleportToLobby
        shared.TDSTable.SmartTeleportLobby = SmartTeleportToLobby
        shared.TDSTable.UniversalSmartLobby = SmartTeleportToLobby
    end
end

function TDS:GameInfo(name, list)
    if game.PlaceId == 3260590327 then return false end

    local targetMap = (type(name) == "table" and name[1]) or name
    if not targetMap or targetMap == "" or targetMap == "Unknown" then
        targetMap = "Simplicity"
    end

    -- If match is already in-game, match has restarted mid-game, or Story Mode:
    local stateReps = game:GetService("ReplicatedStorage"):FindFirstChild("StateReplicators")
    local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
    local gsrOver = gsr and gsr:GetAttribute("GameOver")
    local gsrWave = gsr and (gsr:GetAttribute("Wave") or 0)
    local towersFolder = workspace:FindFirstChild("Towers")
    local hasPlacedTowers = towersFolder and (#towersFolder:GetChildren() > 0)
    local isStory = (gsr and gsr:GetAttribute("StoryMission") ~= nil) or (tostring(gsr and gsr:GetAttribute("Difficulty") or ""):find("Chapter") ~= nil)
    local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
    local hotbarPresent = (pg and pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
    local intermissionGui = (pg and pg:FindFirstChild("ReactGameIntermission"))
    local isIntermission = (intermissionGui and intermissionGui.Enabled ~= false)

    -- Only bypass if the game is genuinely in-progress (wave > 0, towers placed, or hotbar active without intermission)
    local isAlreadyPlaying = (gsrWave > 0) or (hasPlacedTowers == true) or (hotbarPresent and not isIntermission and gsr and gsr:GetAttribute("GameStarted") == true)

    if isStory or isAlreadyPlaying then
        warn(string.format(">>> [TDS:GameInfo] Match already in-game / in-progress on '%s'. Bypassing elevator boards check.", tostring(targetMap)))
        return true
    end

    -- 1. WAIT UNTIL USERS ARE FULLY LOADED IN THE INTERMISSION
    WaitForIntermissionLoaded(30)

    -- 2. Cast modifiers if specified
    local modifiers = (list and next(list)) and list or (Globals and Globals.Modifiers)
    if modifiers and next(modifiers) then
        pcall(CastModifierVote, modifiers)
    end

    -- 3. CHECK VIP / PRIVATE SERVER
    local isVipOrPrivate = CheckIsVipOrPrivateServer()

    if isVipOrPrivate then
        -- VIP / PRIVATE SERVER: OVERRIDE MAP!
        warn(string.format(">>> [TDS:GameInfo] VIP / Private Server detected. Overriding map to '%s'...", tostring(targetMap)))
        AttemptMapOverride(targetMap)
        task.wait(0.5)
        LobbyReadyUp()
        local hostWait = tick()
        repeat
            task.wait(1)
            LobbyReadyUp()
            local started = (gsr and (gsr:GetAttribute("GameStarted") == true or (gsr:GetAttribute("Wave") or 0) > 0))
            local hotbar = pg and (pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
            if started or hotbar then break end
        until (tick() - hostWait >= 35)
        return true
    end

    -- 4. PUBLIC SERVER: Check if map is on boards. If not, Veto. If still not, smartLobby!
    warn(string.format(">>> [TDS:GameInfo] Public Server: Checking voting boards for '%s'...", tostring(targetMap)))

    local mapFound, boardPos = false, nil
    local scanStart = tick()
    while (tick() - scanStart < 8) do
        local found, pos = FindBoardForMap(targetMap)
        if found then
            mapFound = true
            boardPos = pos
            break
        end
        task.wait(0.1)
    end

    if mapFound then
        warn(string.format(">>> [TDS:GameInfo] Public Server: Target map '%s' found on initial boards! Voting...", tostring(targetMap)))
        CastMapVote(targetMap, boardPos or Vector3.new(12.59, 10.64, 52.01))
        task.wait(0.5)
        LobbyReadyUp()
        local hostWait = tick()
        repeat
            task.wait(1)
            LobbyReadyUp()
            local started = (gsr and (gsr:GetAttribute("GameStarted") == true or (gsr:GetAttribute("Wave") or 0) > 0))
            local hotbar = pg and (pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
            if started or hotbar then break end
        until (tick() - hostWait >= 35)
        return true
    end

    -- Map NOT found on boards -> Trigger VETO vote!
    warn(string.format(">>> [TDS:GameInfo] Public Server: Target map '%s' not found on boards. Triggering Veto vote...", tostring(targetMap)))
    TriggerLobbyVeto()

    -- Wait for boards to reroll and re-scan
    local vetoRerollStart = tick()
    while (tick() - vetoRerollStart < 12) do
        task.wait(0.1)
        local found, pos = FindBoardForMap(targetMap)
        if found then
            mapFound = true
            boardPos = pos
            break
        end
    end

    if mapFound then
        warn(string.format(">>> [TDS:GameInfo] Public Server: Target map '%s' found after Veto! Voting...", tostring(targetMap)))
        CastMapVote(targetMap, boardPos or Vector3.new(12.59, 10.64, 52.01))
        task.wait(0.5)
        LobbyReadyUp()
        local hostWait = tick()
        repeat
            task.wait(1)
            LobbyReadyUp()
            local started = (gsr and (gsr:GetAttribute("GameStarted") == true or (gsr:GetAttribute("Wave") or 0) > 0))
            local hotbar = pg and (pg:FindFirstChild("ReactUniversalHotbar") ~= nil)
            if started or hotbar then break end
        until (tick() - hostWait >= 35)
        return true
    end

    -- Map STILL NOT FOUND after Veto -> Return to lobby via smartLobby!
    warn(string.format(">>> [TDS:GameInfo] Public Server: Target map '%s' STILL NOT FOUND after Veto! Returning to lobby via smartLobby...", tostring(targetMap)))
    SmartTeleportToLobby()
    -- Halt execution permanently so the strat never readies up or plays the wrong map
    while true do
        task.wait(2)
        SmartTeleportToLobby()
    end
    return false
end

TDS.Map = TDS.GameInfo
function TDS:Map(...)
    return self:GameInfo(...)
end

function TDS:StartGame()
    LobbyReadyUp()
end

function TDS:Ready()
    if game.PlaceId == 3260590327 then
        return false 
    end
    MatchReadyUp()
    return true
end

function TDS:GetWave()
    return GetCurrentWave()
end

function TDS:WaitForWave(targetWave)
    if game.PlaceId == 3260590327 then return false end
    while self:GetWave() < targetWave do
        task.wait(0.5)
    end
    return true
end

function TDS:RestartGame()
    TriggerRestart()
end

function TDS:Place(TName, px, py, pz, ...)
    local args = {...}
    local stack = false
 
    if args[#args] == "stack" or args[#args] == true then
        py = py+25
    end
    if game.PlaceId == 3260590327 then
        return false 
    end
 
    local towersFolder = workspace:FindFirstChild("Towers") or workspace:WaitForChild("Towers", 5)
    local existing = {}
    if towersFolder then
        for _, child in ipairs(towersFolder:GetChildren()) do
            for _, SubChild in ipairs(child:GetChildren()) do
                if SubChild.Name == "Owner" and SubChild.Value == LocalPlayer.UserId then
                    existing[child] = true
                    break
                end
            end
        end
    end
 
    DoPlaceTower(TName, Vector3.new(px, py, pz))
 
    local NewT
    local waitStart = os.time()
    repeat
        local curTowers = workspace:FindFirstChild("Towers")
        if curTowers then
            for _, child in ipairs(curTowers:GetChildren()) do
                if not existing[child] then
                    for _, SubChild in ipairs(child:GetChildren()) do
                        if SubChild.Name == "Owner" and SubChild.Value == LocalPlayer.UserId then
                            NewT = child
                            break
                        end
                    end
                end
                if NewT then break end
            end
        end
        if not NewT then task.wait(0.05) end
    until NewT or (os.time() - waitStart > 10)
 
    if NewT then
        table.insert(self.PlacedTowers, NewT)
    end
    return #self.PlacedTowers
end

function TDS:Upgrade(idx, PId)
    local t = self.PlacedTowers[idx]
    if t then
        DoUpgradeTower(t, PId or 1)
        UpgradeHistory[idx] = (UpgradeHistory[idx] or 0) + 1
    end
end

function TDS:SetTarget(idx, TargetType, ReqWave)
    if ReqWave then
        repeat task.wait(0.5) until GetCurrentWave() >= ReqWave
    end

    local t = self.PlacedTowers[idx]
    if not t then return end

    pcall(function()
        RemoteFunc:InvokeServer("Troops", "Target", "Set", {
            Troop = t,
            Target = TargetType
        })
    end)
end

function TDS:Sell(idx, ReqWave)
    if ReqWave then
        repeat task.wait(0.5) until GetCurrentWave() >= ReqWave
    end
    local t = self.PlacedTowers[idx]
    if t and DoSellTower(t) then
        return true
    end
    return false
end

function TDS:SellAll(ReqWave)
    task.spawn(function()
        if ReqWave then
            repeat task.wait(0.5) until GetCurrentWave() >= ReqWave
        end

        local TowersCopy = {unpack(self.PlacedTowers)}
        for idx, t in ipairs(TowersCopy) do
            if DoSellTower(t) then
                for i, OrigT in ipairs(self.PlacedTowers) do
                    if OrigT == t then
                        table.remove(self.PlacedTowers, i)
                        break
                    end
                end
            end
        end

        return true
    end)
end

function TDS:Ability(idx, name, data, loop, stack)
    local t = self.PlacedTowers[idx]
    if not t then return false end
    return DoActivateAbility(t, name, data, loop, stack)
end

function TDS:AutoChain(...)
    local TowerIndices = {...}
    if #TowerIndices == 0 then return end

    local running = true

    task.spawn(function()
        local i = 1
        while running do
            local idx = TowerIndices[i]
            local tower = TDS.PlacedTowers[idx]

            if tower then
                DoActivateAbility(tower, "Call Of Arms")
            end

            local hotbar = PlayerGui:FindFirstChild("ReactUniversalHotbar") and PlayerGui.ReactUniversalHotbar:FindFirstChild("Frame")
            local timescale = hotbar and hotbar:FindFirstChild("timescale")

            if timescale then
                if timescale:FindFirstChild("Lock") then
                    task.wait(10.5)
                else
                    task.wait(5.5)
                end
            else
                task.wait(10.5)
            end

            i += 1
            if i > #TowerIndices then
                i = 1
            end
        end
    end)

    return function()
        running = false
    end
end

function TDS:SetOption(idx, name, val, ReqWave)
    local t = self.PlacedTowers[idx]
    if t then
        pcall(function()
            if Logger and type(Logger.Log) == "function" then
                Logger:Log("Setting option '" .. tostring(name) .. "' for tower index: " .. tostring(idx))
            end
        end)
        return DoSetOption(t, name, val, ReqWave)
    end
    return false
end

if GameState == "LOBBY" and Globals.AutoRejoin and isfile("ADS_LastStrat.lua") then
    pcall(delfile, "ADS_LastStrat.lua")
end

if GameState == "GAME" and Globals.AutoRejoin and isfile("ADS_LastStrat.lua") then
    local currentMatchId = (game.JobId ~= "" and game.JobId) or tostring(game.PlaceInstanceId or "MatchInstance")
    if not (getgenv and getgenv().__WIN_STRAT_EXECUTED_JOB_ID == currentMatchId) then
        local stratContent = pcall(readfile, "ADS_LastStrat.lua") and readfile("ADS_LastStrat.lua") or ""
        if stratContent:find(":Loadout%(") then
            TDS.LoadoutPending = true
        end
        task.spawn(function()
            task.wait(2)
            TDS:RunStrategy()
        end)
    end
end

local function IsVoidCharm(obj)
    return math.abs(obj.Position.Y) > 999999
end

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function StartAutoGatling()
    if AutoGatlingRunning or not Globals.AutoGatling then return end
    AutoGatlingRunning = true
    task.spawn(function()
        while Globals.AutoGatling do
            if GameState == "GAME" then
                if not GatlingExecuted then
                    GatlingExecuted = true 
                    task.spawn(function()
                        task.wait(2)
                        local selected = Globals.SelectedGatling or "Railgun"
                        local url = (selected == "Gatlify")
                            and "https://raw.githubusercontent.com/avtryxz/Gatlify/refs/heads/main/Gatlify.lua"
                            or "https://raw.githubusercontent.com/avtryxz/autogutlin/refs/heads/main/autogutlin.lua"
                        pcall(function()
                            loadstring(game:HttpGet(url))()
                        end)
                    end)
                end
            else
                GatlingExecuted = false 
            end
            task.wait(1)
        end
        AutoGatlingRunning = false
    end)
end

local function StartAutoSkip()
    if AutoSkipRunning or not Globals.AutoSkip then return end
    AutoSkipRunning = true

    task.spawn(function()
        while Globals.AutoSkip do
            local SkipVisible =
                PlayerGui:FindFirstChild("ReactOverridesVote")
                and PlayerGui.ReactOverridesVote:FindFirstChild("Frame")
                and PlayerGui.ReactOverridesVote.Frame:FindFirstChild("votes")
                and PlayerGui.ReactOverridesVote.Frame.votes:FindFirstChild("vote")

            if SkipVisible and SkipVisible.Position == UDim2.new(0.5, 0, 0.5, 0) then
                RunVoteSkip()
            end

            task.wait(0.1)
        end

        AutoSkipRunning = false
    end)
end

local function IsRewardScreenVisible()
    local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
    if not pg then return false, nil end

    local uiRoot = pg:FindFirstChild("ReactGameNewRewards")
    if not uiRoot or not uiRoot:IsA("ScreenGui") then return false, nil end
    if uiRoot.Enabled == false then return false, nil end

    local mainFrame = uiRoot:FindFirstChild("Frame")
    if not mainFrame or not mainFrame:IsA("GuiObject") or mainFrame.Visible == false then return false, nil end

    local gameOver = mainFrame:FindFirstChild("gameOver")
    if not gameOver or not gameOver:IsA("GuiObject") or gameOver.Visible == false then return false, nil end

    local rewardsScreen = gameOver:FindFirstChild("RewardsScreen")
    if not rewardsScreen or not rewardsScreen:IsA("GuiObject") or rewardsScreen.Visible == false then
        rewardsScreen = uiRoot:FindFirstChild("RewardsScreen", true)
        if not rewardsScreen or not rewardsScreen:IsA("GuiObject") or rewardsScreen.Visible == false then
            return false, nil
        end
    end

    local topBanner = rewardsScreen:FindFirstChild("RewardBanner")
    local bannerLabel = topBanner and (topBanner:FindFirstChild("textLabel") or topBanner:FindFirstChildWhichIsA("TextLabel", true))
    local bannerText = bannerLabel and bannerLabel.Text and bannerLabel.Text:upper() or ""
    local hasBanner = (bannerText ~= "" and bannerText ~= "UNKNOWN")

    local gameStats = rewardsScreen:FindFirstChild("gameStats")
    local statsList = gameStats and gameStats:FindFirstChild("stats")
    local hasStats = (statsList and #statsList:GetChildren() > 0)

    local sectionRewards = rewardsScreen:FindFirstChild("RewardsSection")
    local hasSection = (sectionRewards and #sectionRewards:GetChildren() > 0)

    local hasSize = (rewardsScreen.AbsoluteSize.X > 50 and rewardsScreen.AbsoluteSize.Y > 50)

    if (hasBanner or hasStats or hasSection) and hasSize then
        return true, rewardsScreen
    end

    return false, nil
end

local function WaitForRewardScreen(timeout)
    local maxWait = timeout or 35
    local t0 = tick()
    warn(string.format(">>> [TDS:API] Waiting for Reward Screen to visibly display on screen (max %ds)...", maxWait))

    while (tick() - t0) < maxWait do
        local visible, screen = IsRewardScreenVisible()
        if visible then
            warn(">>> [TDS:API] Reward Screen is now VISIBLE on screen!")
            task.wait(2)
            return true, screen
        end
        task.wait(0.5)
    end

    warn(">>> [TDS:API] Reward Screen did NOT display within timeout.")
    return false, nil
end

if Globals then
    Globals.IsRewardScreenVisible = IsRewardScreenVisible
    Globals.WaitForRewardScreen = WaitForRewardScreen
end
if typeof(getgenv) == "function" then
    getgenv().IsRewardScreenVisible = IsRewardScreenVisible
    getgenv().WaitForRewardScreen = WaitForRewardScreen
end

local function HandlePostMatch(forceRestart)
    if forceRestart == true or Globals.AutoRestart then
        TriggerRestart()
    else
        -- ONLY teleport if the Reward Screen is actually confirmed visible on screen!
        local shown = false
        if typeof(WaitForRewardScreen) == "function" then
            shown = WaitForRewardScreen(40)
        elseif Globals and typeof(Globals.WaitForRewardScreen) == "function" then
            shown = Globals.WaitForRewardScreen(40)
        elseif typeof(IsRewardScreenVisible) == "function" then
            shown = IsRewardScreenVisible()
        elseif Globals and typeof(Globals.IsRewardScreenVisible) == "function" then
            shown = Globals.IsRewardScreenVisible()
        end

        if shown then
            warn(">>> [TDS:API] Reward screen confirmed visible! Teleporting to lobby in 3 seconds...")
            task.wait(3)
            SmartTeleportToLobby()
        else
            warn(">>> [TDS:API] Reward screen was NOT visible or did not display. Teleport aborted to prevent premature rejoin.")
        end
    end
end

function StartBackToLobby()
    if game.PlaceId == 3260590327 then return end
    if BackToLobbyRunning then return end
    BackToLobbyRunning = true

    task.spawn(function()
        local stateReps = ReplicatedStorage:WaitForChild("StateReplicators", 30)
        local gameStateReplicator = stateReps and stateReps:WaitForChild("GameStateReplicator", 30)
        
        -- If GameStateReplicator is missing, do NOT blindly teleport!
        if not gameStateReplicator then
            BackToLobbyRunning = false
            return
        end

        while Globals.AutoRejoin or Globals.AutoRestart do
            local isGameOver = gameStateReplicator:GetAttribute("GameOver") == true
            if isGameOver then
                local health = gameStateReplicator:GetAttribute("Health") or 0
                if health > 0 then
                    if Globals.AutoRejoin then
                        if isfile("ADS_LastStrat.lua") then
                            pcall(delfile, "ADS_LastStrat.lua")
                        end
                        pcall(HandlePostMatch)
                        break
                    end
                else
                    if Globals.AutoRestart then
                        if typeof(WaitForRewardScreen) == "function" then
                            WaitForRewardScreen(35)
                        end
                        task.spawn(pcall, HandlePostMatch, true)
                        local lastVoteTime = 0
                        local voteReplicator = stateReps and stateReps:FindFirstChild("VoteReplicator")
                        while Globals.AutoRestart do
                            local title = voteReplicator and voteReplicator:GetAttribute("Title")
                            local enabled = voteReplicator and voteReplicator:GetAttribute("Enabled")
                            
                            if enabled == true and title == "Restart?" then
                                if os.clock() - lastVoteTime > 3 then
                                    pcall(function()
                                        RemoteFunc:InvokeServer("Voting", "Skip")
                                    end)
                                    lastVoteTime = os.clock()
                                end
                            end
                            
                            if title == "Ready?" or gameStateReplicator:GetAttribute("GameOver") == false then
                                break
                            end
                            task.wait(0.1)
                        end
                        
                        if not Globals.AutoRestart then break end
                        
                        if isfile("ADS_LastStrat.lua") then
                            task.spawn(function()
                                repeat
                                    task.wait(0.1)
                                    local towersFolder = workspace:FindFirstChild("Towers")
                                until (towersFolder and #towersFolder:GetChildren() == 0) or not Globals.AutoRestart
                                
                                if not Globals.AutoRestart then return end
                                TDS:ResetAllStates()
                                TDS:RunStrategy()
                            end)
                        end
                        
                        repeat task.wait(1) until gameStateReplicator:GetAttribute("GameOver") == false or not Globals.AutoRestart
                    elseif Globals.AutoRejoin then
                        if isfile("ADS_LastStrat.lua") then
                            pcall(delfile, "ADS_LastStrat.lua")
                        end
                        pcall(HandlePostMatch)
                        break
                    end
                end
            end
            task.wait(1)
        end
        BackToLobbyRunning = false
    end)
end

local function StartAntiLag()
    if AntiLagRunning or not Globals.AntiLag then return end
    AntiLagRunning = true

    local settings = settings().Rendering
    settings.QualityLevel = Enum.QualityLevel.Level01

    task.spawn(function()
        while Globals.AntiLag do
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
            
            task.wait(0.5)
        end
        AntiLagRunning = false
    end)
end

local function StartAutoChain()
    if AutoChainRunning or not Globals.AutoChain then return end
    AutoChainRunning = true

    task.spawn(function()
        local idx = 1

        while Globals.AutoChain do
            local commander = {}
            local TowersFolder = workspace:FindFirstChild("Towers")

            if TowersFolder then
                for _, towers in ipairs(TowersFolder:GetDescendants()) do
                    if not Globals.AutoChain then break end
                    if towers:IsA("Folder") and towers.Name == "TowerReplicator"
                    and towers:GetAttribute("Name") == "Commander"
                    and towers:GetAttribute("OwnerId") == game.Players.LocalPlayer.UserId
                    and (towers:GetAttribute("Upgrade") or 0) >= 2 then
                        commander[#commander + 1] = towers.Parent
                    end
                end
            end

            if not Globals.AutoChain then break end

            if #commander >= 3 then
                if idx > #commander then idx = 1 end

                local CurrentCommander = commander[idx]
                local replicator = CurrentCommander and CurrentCommander:FindFirstChild("TowerReplicator")
                local UpgradeLevel = replicator and replicator:GetAttribute("Upgrade") or 0

                if UpgradeLevel >= 4 and Globals.SupportCaravan then
                    RemoteFunc:InvokeServer(
                        "Troops",
                        "Abilities",
                        "Activate",
                        { Troop = CurrentCommander, Name = "Support Caravan", Data = {} }
                    )
                    task.wait(0.1) 
                end

                if not Globals.AutoChain then break end

                local response = RemoteFunc:InvokeServer(
                    "Troops",
                    "Abilities",
                    "Activate",
                    { Troop = CurrentCommander, Name = "Call Of Arms", Data = {} }
                )

                if response then
                    idx += 1

                    local hotbar = PlayerGui:FindFirstChild("ReactUniversalHotbar")
                    local TimescaleFrame = hotbar and hotbar.Frame:FindFirstChild("timescale")

                    if TimescaleFrame and TimescaleFrame.Visible then
                        if TimescaleFrame:FindFirstChild("Lock") then
                            task.wait(10.3)
                        else
                            task.wait(5.25)
                        end
                    else
                        task.wait(10.3)
                    end
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end

        AutoChainRunning = false
    end)
end

local function StartAutoDjBooth()
    if AutoDjRunning or not Globals.AutoDJ then return end
    AutoDjRunning = true

    task.spawn(function()
        while Globals.AutoDJ do
            local DJ = nil
            local TowersFolder = workspace:FindFirstChild("Towers")

            if TowersFolder then
                for _, towers in ipairs(TowersFolder:GetDescendants()) do
                    if not Globals.AutoDJ then break end
                    if towers:IsA("Folder") and towers.Name == "TowerReplicator"
                    and towers:GetAttribute("Name") == "DJ Booth"
                    and towers:GetAttribute("OwnerId") == game.Players.LocalPlayer.UserId
                    and (towers:GetAttribute("Upgrade") or 0) >= 3 then
                        DJ = towers.Parent
                    end
                end
            end

            if not Globals.AutoDJ then break end

            if DJ then
                RemoteFunc:InvokeServer(
                    "Troops",
                    "Abilities",
                    "Activate",
                    { Troop = DJ, Name = "Drop The Beat", Data = {} }
                )
            end

            task.wait(1)
        end

        AutoDjRunning = false
    end)
end

local function StartAutoNecro()
    if AutoNecroRunning or not Globals.AutoNecro then return end
    AutoNecroRunning = true

    local lastActivation = 0
    local ownerId = game.Players.LocalPlayer.UserId

    local function getNecros(towersFolder)
        local list = {}
        if not towersFolder then
            return list
        end
        for _, rep in ipairs(towersFolder:GetDescendants()) do
            if not Globals.AutoNecro then break end
            if rep:IsA("Folder") and rep.Name == "TowerReplicator"
            and rep:GetAttribute("Name") == "Necromancer"
            and rep:GetAttribute("OwnerId") == ownerId then
                list[#list + 1] = rep.Parent
            end
        end
        return list
    end

    local function pickMaxGraves(rep, graveStore, up)
        local maxGraves = rep and rep:GetAttribute("Max_Graves")
        if graveStore then
            local gMax = graveStore:GetAttribute("Max_Graves")
            if type(gMax) == "number" and gMax > 0 then
                maxGraves = gMax
            end
        end
        if not maxGraves or maxGraves < 2 then
            if up >= 4 then
                maxGraves = 9
            elseif up >= 2 then
                maxGraves = 6
            else
                maxGraves = 3
            end
        end
        return maxGraves
    end

    local function countGraves(graveStore)
        if not graveStore then
            return 0
        end
        local cnt = 0
        for k, v in pairs(graveStore:GetAttributes()) do
            if type(k) == "string" and #k > 20 then
                local isDestroy = false
                if type(v) == "table" then
                    for _, elem in pairs(v) do
                        if tostring(elem) == "Destroy" then
                            isDestroy = true
                            break
                        end
                    end
                elseif tostring(v):find("Destroy") then
                    isDestroy = true
                end
                if isDestroy then
                    graveStore:SetAttribute(k, nil)
                else
                    cnt += 1
                end
            end
        end
        return cnt
    end

    local function cleanAllGraves(list)
        for _, necro in ipairs(list) do
            if not Globals.AutoNecro then break end
            local rep = necro and necro:FindFirstChild("TowerReplicator")
            local store = rep and rep:FindFirstChild("GraveStone")
            if store then
                countGraves(store)
            end
        end
    end

    task.spawn(function()
        local idx = 1

        while Globals.AutoNecro do
            local TowersFolder = workspace:FindFirstChild("Towers")
            local necromancer = getNecros(TowersFolder)
            cleanAllGraves(necromancer)

            if not Globals.AutoNecro then break end

            if #necromancer >= 1 then
                if idx > #necromancer then idx = 1 end
                local CurrentNecromancer = necromancer[idx]
                local replicator = CurrentNecromancer and CurrentNecromancer:FindFirstChild("TowerReplicator")

                local up = replicator and (replicator:GetAttribute("Upgrade") or 0) or 0
                local graveStore = replicator and replicator:FindFirstChild("GraveStone")
                local maxGraves = pickMaxGraves(replicator, graveStore, up)
                local graveCount = countGraves(graveStore)
                local debounce = (replicator and replicator:GetAttribute("AbilityDebounce")) or 5
                local now = os.clock()

                if maxGraves and graveCount >= maxGraves and (now - lastActivation >= debounce) then
                    if not Globals.AutoNecro then break end
                    local response = RemoteFunc:InvokeServer(
                        "Troops",
                        "Abilities",
                        "Activate",
                        { Troop = CurrentNecromancer, Name = "Raise The Dead", Data = {} }
                    )

                    if response then 
                        lastActivation = now
                        idx += 1
                        task.wait(1)
                    else
                        task.wait(0.5)
                    end
                else
                    task.wait(0.1)
                end
            else
                task.wait(1)
            end
        end

        AutoNecroRunning = false
    end)
end

local function StartAutoMercenary()
    if not Globals.AutoMercenary and not Globals.AutoMilitary then return end

    if AutoMercenaryBaseRunning then return end
    AutoMercenaryBaseRunning = true

    task.spawn(function()
        while Globals.AutoMercenary do
            local TowersFolder = workspace:FindFirstChild("Towers")

            if TowersFolder then
                for _, towers in ipairs(TowersFolder:GetDescendants()) do
                    if not Globals.AutoMercenary then break end
                    if towers:IsA("Folder") and towers.Name == "TowerReplicator"
                    and towers:GetAttribute("Name") == "Mercenary Base"
                    and towers:GetAttribute("OwnerId") == game.Players.LocalPlayer.UserId
                    and (towers:GetAttribute("Upgrade") or 0) >= 5 then

                        RemoteFunc:InvokeServer(
                            "Troops",
                            "Abilities",
                            "Activate",
                            { 
                                Troop = towers.Parent, 
                                Name = "Air-Drop", 
                                Data = {
                                    pathName = 1, 
                                    directionCFrame = CFrame.new(), 
                                    dist = Globals.MercenaryPath or 300
                                } 
                            }
                        )

                        task.wait(0.5)

                        if not Globals.AutoMercenary then break end
                    end
                end
            end

            task.wait(0.5)
        end

        AutoMercenaryBaseRunning = false
    end)
end

local function StartAutoMilitary()
    if not Globals.AutoMilitary then return end

    if AutoMilitaryBaseRunning then return end
    AutoMilitaryBaseRunning = true

    task.spawn(function()
        while Globals.AutoMilitary do
            local TowersFolder = workspace:FindFirstChild("Towers")
            if TowersFolder then
                for _, towers in ipairs(TowersFolder:GetDescendants()) do
                    if not Globals.AutoMilitary then break end
                    if towers:IsA("Folder") and towers.Name == "TowerReplicator"
                    and towers:GetAttribute("Name") == "Military Base"
                    and towers:GetAttribute("OwnerId") == game.Players.LocalPlayer.UserId
                    and (towers:GetAttribute("Upgrade") or 0) >= 4 then

                        RemoteFunc:InvokeServer(
                            "Troops",
                            "Abilities",
                            "Activate",
                            { 
                                Troop = towers.Parent, 
                                Name = "Airstrike", 
                                Data = {
                                    pathName = 1, 
                                    pointToEnd = CFrame.new(), 
                                    dist = Globals.MilitaryPath or 195
                                } 
                            }
                        )

                        task.wait(0.5)

                        if not Globals.AutoMilitary then break end
                    end
                end
            end

            task.wait(0.5)
        end

        AutoMilitaryBaseRunning = false
    end)
end

local AutoMedicModule = nil

local function StartMedicChain()
    if Globals.AutoMedic then
        if AutoMedicModule and AutoMedicModule.State and AutoMedicModule.State.Running then 
            return 
        end

        local myMedics = {}
        repeat
            if not Globals.AutoMedic then return end
            myMedics = {}
            local towersFolder = game:GetService("Workspace"):FindFirstChild("Towers")
            
            if towersFolder then
                for _, tower in ipairs(towersFolder:GetChildren()) do
                    if not Globals.AutoMedic then return end
                    local replicator = tower:FindFirstChild("TowerReplicator")
                    if replicator then
                        local ownerId = replicator:GetAttribute("OwnerId")
                        local ownerName = replicator:GetAttribute("OwnerName")
                        local towerName = replicator:GetAttribute("Name")

                        local localPlayer = game:GetService("Players").LocalPlayer
                        local isOwner = (ownerId and ownerId == localPlayer.UserId) or (ownerName and ownerName == localPlayer.Name)

                        if isOwner and towerName and string.lower(towerName) == "medic" then
                            table.insert(myMedics, tower)
                        end
                    end
                end
            end

            if #myMedics < 4 then
                task.wait(1)
            end
        until #myMedics >= 4 or not Globals.AutoMedic

        if not Globals.AutoMedic then return end

        if not AutoMedicModule then
            local success, loadedLib = pcall(function()
                local url = "https://raw.githubusercontent.com/AmonguszzZ/ModdedAether/refs/heads/main/AutoAbilities/AutoMedicNew.lua"
                return loadstring(game:HttpGet(url))()
            end)
            if success and loadedLib then
                AutoMedicModule = loadedLib
            end
        end
        if AutoMedicModule and Globals.AutoMedic then
            AutoMedicModule.Chaining()
        end
    else
        if AutoMedicModule and AutoMedicModule.State then
            AutoMedicModule.State.Running = false
        end
    end
end

function TDS:Rejoin()
    SmartTeleportToLobby()
end

function TDS:RemoveIndex()
    if self.PlacedTowers and type(self.PlacedTowers) == "table" then
        pcall(table.clear, self.PlacedTowers)
    end
    self.PlacedTowers = {}
    self["placed_towers"] = self.PlacedTowers

    if self.PlacedTraps and type(self.PlacedTraps) == "table" then
        pcall(table.clear, self.PlacedTraps)
    end
    self.PlacedTraps = {}

    if self.MapInteractions and type(self.MapInteractions) == "table" then
        pcall(table.clear, self.MapInteractions)
    end
    self.MapInteractions = {}

    if self.UpgradeHistory and type(self.UpgradeHistory) == "table" then
        pcall(table.clear, self.UpgradeHistory)
    end
    if UpgradeHistory and type(UpgradeHistory) == "table" then
        pcall(table.clear, UpgradeHistory)
    end
    if executed_actions and type(executed_actions) == "table" then
        pcall(table.clear, executed_actions)
    end
    self.__matchRestarted = true
    warn("[TDS:RemoveIndex] Tower indices, traps, and interaction history cleared.")
    return true
end

TDS.RemoveIndex = TDS.RemoveIndex
TDS["remove_index"] = TDS.RemoveIndex
TDS.removeIndex = TDS.RemoveIndex
if getgenv then
    getgenv().RemoveIndex = function(...)
        if TDS and typeof(TDS.RemoveIndex) == "function" then
            return TDS:RemoveIndex(...)
        end
    end
end

task.spawn(function()
    task.wait(2)
    while true do

        if Globals.AutoSkip and not AutoSkipRunning then
            StartAutoSkip()
        end

        if Globals.AutoChain and not AutoChainRunning then
            StartAutoChain()
        end

        if Globals.AutoDJ and not AutoDjRunning then
            StartAutoDjBooth()
        end

        if Globals.AutoNecro and not AutoNecroRunning then
            StartAutoNecro()
        end

        if Globals.AutoMercenary and not AutoMercenaryBaseRunning then
            StartAutoMercenary()
        end

        if Globals.AutoMilitary and not AutoMilitaryBaseRunning then
            StartAutoMilitary()
        end

        if Globals.AntiLag and not AntiLagRunning then
            StartAntiLag()
        end

        if (Globals.AutoRejoin or Globals.AutoRestart) and not BackToLobbyRunning then
            StartBackToLobby()
        end

        if Globals.AutoGatling and not AutoGatlingRunning then
            StartAutoGatling()
        end

        if Globals.AutoReady and not AutoReadyRunning then
            StartAutoReady()
        end

        if Globals.AutoMedic and not AutoMedicRunning then
            StartMedicChain()
        end
		
		if Globals.AutoBack and not AutoBackRunning then
            StartAutoBack()
        end

        task.wait(1)
    end
end)

local function strategyRecordingSetup()
    local originalMethods = {}
    local recordableMethods = {
        "Mode", "Place", "Upgrade", "SetTarget", "Sell", "SellAll", "Ability", "SetOption", "MedicSelect", "MedicChain", "Ready", "VoteSkip", "WaitForWave", "UnlockTimeScale", "TimeScale"
    }

    local function stringifyArgument(argumentValue)
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
        else
            return "nil"
        end
    end

    for _, methodName in ipairs(recordableMethods) do
        if typeof(TDS[methodName]) == "function" then
            originalMethods[methodName] = TDS[methodName]
            TDS[methodName] = function(self, ...)
                if not (Globals and Globals.tdsReplaying) and GameState == "GAME" and (Globals and Globals.record_strat) then
                    local argumentsList = {...}
                    local stringifiedArguments = {}
                    for _, argumentValue in ipairs(argumentsList) do
                        table.insert(stringifiedArguments, stringifyArgument(argumentValue))
                    end

                    if methodName == "Mode" then
                        -- Mode marker
                    else
                        local shouldRecord = true
                        local actionString = string.format("TDS:%s(%s)", methodName, table.concat(stringifiedArguments, ", "))

                        if methodName == "VoteSkip" then
                            local targetWave = tonumber(argumentsList[1])
                            if not targetWave then
                                pcall(function()
                                    local stateReps = game:GetService("ReplicatedStorage"):FindFirstChild("StateReplicators")
                                    local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                    targetWave = gsr and gsr:GetAttribute("Wave") or 0
                                end)
                            end
                            targetWave = targetWave or 0
                            if Globals.__last_recorded_skip_wave == targetWave then
                                shouldRecord = false
                            else
                                Globals.__last_recorded_skip_wave = targetWave
                                actionString = string.format("TDS:VoteSkip(%d)", targetWave)
                            end
                        elseif methodName == "Ready" then
                            if Globals.__has_recorded_ready_this_match then
                                shouldRecord = false
                            else
                                Globals.__has_recorded_ready_this_match = true
                            end
                        end

                        if shouldRecord then
                            local curWave = 0
                            pcall(function()
                                local stateReps = game:GetService("ReplicatedStorage"):FindFirstChild("StateReplicators")
                                local gsr = stateReps and stateReps:FindFirstChild("GameStateReplicator")
                                curWave = gsr and gsr:GetAttribute("Wave") or 0
                            end)
                            local wavePrefix = ""
                            if not Globals.__last_recorded_wave or curWave > Globals.__last_recorded_wave then
                                Globals.__last_recorded_wave = curWave
                                wavePrefix = string.format("\n-- [ Wave %d ] --\n", curWave)
                            end
                            if typeof(appendfile) == "function" then
                                pcall(appendfile, "ADS_LastStrat.lua", wavePrefix .. actionString .. "\n")
                                pcall(appendfile, "Strat.txt", wavePrefix .. actionString .. "\n")
                                if Globals.__active_record_path then
                                    pcall(appendfile, Globals.__active_record_path, wavePrefix .. actionString .. "\n")
                                end
                            end
                        end
                    end
                end

                return originalMethods[methodName](self, ...)
            end
        end
    end
end

pcall(strategyRecordingSetup)

return TDS
