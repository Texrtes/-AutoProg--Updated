--!strict
--==============================================================================
-- CoreRevampNewAPI.lua
-- Neo-Glassmorphism Adaptive UI Framework with Extended Component Suite
-- - Ultra-clean translucent frosted glass aesthetic (Glassmorphism & Acrylic)
-- - Specular border highlights with animated luminous gradient sweep
-- - Fully adaptive device scaling (Phone, Tablet, Desktop, Console)
-- - Dynamic auto-expanding text cards (zero clipping on multi-line text)
-- - Strictly deterministic LayoutOrder preventing mobile menu shuffling
-- - Responsive scrollable dropdowns with real-time Search filtering
-- - Precision step & custom suffix Slider controls
-- - Extended API: Keybind, Colorpicker, ProgressBar, Divider, Spacer,
--   Banner/Callout, MetricGrid/StatCard, LogConsole, and Dialog/Prompt modal
-- - 100% backward-compatible with NovaGlass / GlassHubUI / UICore API
--==============================================================================

local Library = {}
Library.__index = Library

Library.Assets = {
    Shadow          = "rbxassetid://1316045217",
    Minimize        = "rbxassetid://118026365011536",
    Minus           = "rbxassetid://118026365011536",
    Hide            = "rbxassetid://135928786788378",
    EyeOff          = "rbxassetid://135928786788378",
    ["eye-off"]     = "rbxassetid://135928786788378",
    Scale           = "rbxassetid://15082210525",
    Close           = "rbxassetid://110786993356448",
    X               = "rbxassetid://110786993356448",
    Resize          = "rbxassetid://15082210525",
    Chevron         = "rbxassetid://134243273101015",
    ChevronDown     = "rbxassetid://134243273101015",
    ["chevron-down"]= "rbxassetid://134243273101015",
    Arrow           = "rbxassetid://134243273101015",
    Button          = "rbxassetid://84269270119683",
    ButtonIcon      = "rbxassetid://84269270119683",
    Search          = "rbxassetid://121018724060431",
    Textbox         = "rbxassetid://13868675087",
    GlowDot         = "rbxassetid://105506802034513",
    ImageLogo       = "rbxassetid://130551565616516",
    Logo            = "rbxassetid://130551565616516",
    FloatingToggle  = "rbxassetid://130551565616516",
    FloatingBadge   = "rbxassetid://84269270119683",
    Discord         = "rbxassetid://119690296342461",
    Theme           = "rbxassetid://80758916183665",
    Home            = "rbxassetid://80559668453788",
    Overview        = "rbxassetid://80559668453788",
    User            = "rbxassetid://10747373176",
    Key             = "rbxassetid://10709790644",
    Clock           = "rbxassetid://121808839832144",
    Trials          = "rbxassetid://121808839832144",
    AutoTrials      = "rbxassetid://121808839832144",
    Check           = "rbxassetid://93898873302694",
    Globe           = "rbxassetid://10734887376",
    Chat            = "rbxassetid://10734887852",
    Gear            = "rbxassetid://80758916183665",
    Settings        = "rbxassetid://80758916183665",
    ["settings"]    = "rbxassetid://80758916183665",
    Sliders         = "rbxassetid://10734950020",
    Terminal        = "rbxassetid://10734951847",
    Console         = "rbxassetid://10734951847",
    AutoGold        = "rbxassetid://116510979641930",
    Gold            = "rbxassetid://116510979641930",
    Coins           = "rbxassetid://116510979641930",
    Package         = "rbxassetid://114765145536264",
    Zap             = "rbxassetid://130551565616516",
    AutoEvo         = "rbxassetid://130551565616516",
    Evo             = "rbxassetid://130551565616516",
    Shield          = "rbxassetid://110987169760162",
    Background      = "rbxassetid://82941526973068",
    AutoHubBg       = "rbxassetid://82941526973068",
    AutoHubIcon     = "autohub_icon.png",
}

-- Refined Glass Theme Palette
Library.Themes = {
    LightGray = {
        Background    = Color3.fromRGB(16, 17, 20),
        Sidebar       = Color3.fromRGB(12, 13, 16),
        Surface       = Color3.fromRGB(24, 26, 30),
        SurfaceHover  = Color3.fromRGB(34, 36, 42),
        Stroke        = Color3.fromRGB(190, 195, 205),
        StrokeSoft    = Color3.fromRGB(65, 70, 80),
        Text          = Color3.fromRGB(250, 250, 252),
        Muted         = Color3.fromRGB(150, 155, 165),
        Accent        = Color3.fromRGB(215, 220, 230),
        AccentHover   = Color3.fromRGB(245, 248, 255),
        AccentSoft    = Color3.fromRGB(40, 43, 50),
        Success       = Color3.fromRGB(34, 197, 94),
        Warning       = Color3.fromRGB(245, 158, 11),
        Danger        = Color3.fromRGB(239, 68, 68),
    },
    CyberNeon = {
        Background    = Color3.fromRGB(16, 17, 20),
        Sidebar       = Color3.fromRGB(12, 13, 16),
        Surface       = Color3.fromRGB(24, 26, 30),
        SurfaceHover  = Color3.fromRGB(34, 36, 42),
        Stroke        = Color3.fromRGB(190, 195, 205),
        StrokeSoft    = Color3.fromRGB(65, 70, 80),
        Text          = Color3.fromRGB(250, 250, 252),
        Muted         = Color3.fromRGB(150, 155, 165),
        Accent        = Color3.fromRGB(215, 220, 230),
        AccentHover   = Color3.fromRGB(245, 248, 255),
        AccentSoft    = Color3.fromRGB(40, 43, 50),
        Success       = Color3.fromRGB(34, 197, 94),
        Warning       = Color3.fromRGB(245, 158, 11),
        Danger        = Color3.fromRGB(239, 68, 68),
    },
    SkyBlue = {
        Background    = Color3.fromRGB(10, 18, 34),
        Sidebar       = Color3.fromRGB(8, 14, 26),
        Surface       = Color3.fromRGB(14, 28, 52),
        SurfaceHover  = Color3.fromRGB(20, 42, 78),
        Stroke        = Color3.fromRGB(14, 165, 233),
        StrokeSoft    = Color3.fromRGB(32, 64, 110),
        Text          = Color3.fromRGB(240, 249, 255),
        Muted         = Color3.fromRGB(145, 180, 220),
        Accent        = Color3.fromRGB(14, 165, 233),
        AccentHover   = Color3.fromRGB(56, 189, 248),
        AccentSoft    = Color3.fromRGB(14, 52, 95),
        Success       = Color3.fromRGB(16, 185, 129),
        Warning       = Color3.fromRGB(245, 158, 11),
        Danger        = Color3.fromRGB(244, 63, 94),
    },
    DeepAzure = {
        Background    = Color3.fromRGB(8, 11, 22),
        Sidebar       = Color3.fromRGB(6, 9, 17),
        Surface       = Color3.fromRGB(13, 18, 34),
        SurfaceHover  = Color3.fromRGB(19, 27, 48),
        Stroke        = Color3.fromRGB(59, 130, 246),
        StrokeSoft    = Color3.fromRGB(32, 46, 78),
        Text          = Color3.fromRGB(241, 245, 249),
        Muted         = Color3.fromRGB(138, 156, 188),
        Accent        = Color3.fromRGB(59, 130, 246),
        AccentHover   = Color3.fromRGB(96, 165, 250),
        AccentSoft    = Color3.fromRGB(20, 38, 78),
        Success       = Color3.fromRGB(34, 197, 94),
        Warning       = Color3.fromRGB(251, 191, 36),
        Danger        = Color3.fromRGB(239, 68, 68),
    },
    MidnightEmerald = {
        Background    = Color3.fromRGB(8, 18, 16),
        Sidebar       = Color3.fromRGB(6, 14, 12),
        Surface       = Color3.fromRGB(12, 28, 24),
        SurfaceHover  = Color3.fromRGB(18, 38, 32),
        Stroke        = Color3.fromRGB(16, 185, 129),
        StrokeSoft    = Color3.fromRGB(30, 62, 52),
        Text          = Color3.fromRGB(236, 253, 245),
        Muted         = Color3.fromRGB(134, 172, 158),
        Accent        = Color3.fromRGB(16, 185, 129),
        AccentHover   = Color3.fromRGB(52, 211, 153),
        AccentSoft    = Color3.fromRGB(14, 46, 38),
        Success       = Color3.fromRGB(16, 185, 129),
        Warning       = Color3.fromRGB(245, 158, 11),
        Danger        = Color3.fromRGB(239, 68, 68),
    },
    CrimsonEclipse = {
        Background    = Color3.fromRGB(18, 10, 14),
        Sidebar       = Color3.fromRGB(13, 7, 10),
        Surface       = Color3.fromRGB(26, 15, 20),
        SurfaceHover  = Color3.fromRGB(36, 20, 28),
        Stroke        = Color3.fromRGB(244, 63, 94),
        StrokeSoft    = Color3.fromRGB(58, 28, 38),
        Text          = Color3.fromRGB(255, 241, 242),
        Muted         = Color3.fromRGB(185, 142, 152),
        Accent        = Color3.fromRGB(244, 63, 94),
        AccentHover   = Color3.fromRGB(251, 113, 133),
        AccentSoft    = Color3.fromRGB(48, 16, 26),
        Success       = Color3.fromRGB(34, 197, 94),
        Warning       = Color3.fromRGB(245, 158, 11),
        Danger        = Color3.fromRGB(239, 68, 68),
    },
    SolarAmber = {
        Background    = Color3.fromRGB(18, 15, 10),
        Sidebar       = Color3.fromRGB(13, 11, 7),
        Surface       = Color3.fromRGB(27, 22, 14),
        SurfaceHover  = Color3.fromRGB(37, 30, 19),
        Stroke        = Color3.fromRGB(245, 158, 11),
        StrokeSoft    = Color3.fromRGB(60, 48, 26),
        Text          = Color3.fromRGB(254, 252, 232),
        Muted         = Color3.fromRGB(185, 165, 130),
        Accent        = Color3.fromRGB(245, 158, 11),
        AccentHover   = Color3.fromRGB(251, 191, 36),
        AccentSoft    = Color3.fromRGB(50, 34, 14),
        Success       = Color3.fromRGB(34, 197, 94),
        Warning       = Color3.fromRGB(245, 158, 11),
        Danger        = Color3.fromRGB(239, 68, 68),
    }
}

local THEME_ORDER = { "LightGray", "SkyBlue", "DeepAzure", "MidnightEmerald", "CrimsonEclipse", "SolarAmber" }

local function resolveTheme(themeInput: any): { [string]: Color3 }
    local base = Library.Themes.LightGray or Library.Themes.CyberNeon
    local resolved = {}
    for k, v in pairs(base) do
        resolved[k] = v
    end

    if type(themeInput) == "string" and Library.Themes[themeInput] then
        for k, v in pairs(Library.Themes[themeInput]) do
            resolved[k] = v
        end
    elseif type(themeInput) == "table" then
        for k, v in pairs(themeInput) do
            resolved[k] = v
        end
    end

    return resolved
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local function elevateThread()
    local setid = setthreadidentity or set_thread_identity or (syn and syn.set_thread_identity) or setidentity
    if setid then
        pcall(setid, 8)
    end
end

local function getTopInset(): number
    elevateThread()
    local topInset = 36
    pcall(function()
        topInset = GuiService:GetGuiInset().Y
    end)
    return math.max(topInset, 0)
end

-- Device Type Detection
local function detectDeviceType(): string
    if GuiService:IsTenFootInterface() then
        return "Console"
    end
    local camera = workspace.CurrentCamera
    local vp = (camera and camera.ViewportSize) or Vector2.new(1920, 1080)
    local minDim = math.min(vp.X, vp.Y)
    local maxDim = math.max(vp.X, vp.Y)
    local isTouch = UserInputService.TouchEnabled

    if isTouch and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
        if minDim >= 580 and maxDim >= 880 then
            return "Tablet"
        else
            return "Phone"
        end
    elseif isTouch then
        if minDim < 520 then
            return "Phone"
        elseif minDim < 720 then
            return "Tablet"
        else
            return "Desktop"
        end
    else
        return "Desktop"
    end
end

-- Device-Specific Scale Calculation
local function calculateDeviceScale(deviceType: string, vp: Vector2, topInset: number): number
    local availableHeight = math.max(vp.Y - topInset - 24, 200)
    local availableWidth = math.max(vp.X - 32, 300)
    
    local baseW = 800
    local baseH = 540

    if deviceType == "Phone" then
        local fitX = availableWidth / (baseW * 1.05)
        local fitY = availableHeight / (baseH * 1.05)
        return math.clamp(math.min(fitX, fitY), 0.50, 0.76)
    elseif deviceType == "Tablet" then
        local fitX = availableWidth / (baseW * 1.1)
        local fitY = availableHeight / (baseH * 1.1)
        return math.clamp(math.min(fitX, fitY), 0.72, 0.95)
    elseif deviceType == "Console" then
        return 1.20
    else
        if vp.Y >= 1440 then
            return math.clamp(vp.Y / 1200, 1.0, 1.30)
        elseif vp.Y <= 720 or vp.X <= 1280 then
            local fitX = availableWidth / (baseW * 1.08)
            local fitY = availableHeight / (baseH * 1.08)
            return math.clamp(math.min(fitX, fitY), 0.75, 1.0)
        else
            return 1.0
        end
    end
end

local function tween(object: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
    local info = TweenInfo.new(time, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local anim = TweenService:Create(object, info, goal)
    anim:Play()
    return anim
end

local function make(className: string, props: { [string]: any }?, children: { Instance }?): any
    local object = Instance.new(className)
    if props then
        for key, value in pairs(props) do
            (object :: any)[key] = value
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = object
        end
    end
    return object
end

local function corner(parent: Instance, radius: number)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    })
end

local function stroke(parent: Instance, color: Color3, thickness: number?, transparency: number?)
    return make("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0.65,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent: Instance, left: number, top: number, right: number, bottom: number)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left),
        PaddingTop = UDim.new(0, top),
        PaddingRight = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom),
        Parent = parent,
    })
end

local function list(parent: Instance, paddingSize: number, direction: Enum.FillDirection?)
    return make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, paddingSize),
        FillDirection = direction or Enum.FillDirection.Vertical,
        Parent = parent,
    })
end

local function normalizeAsset(image: any): string
    if type(image) == "number" then
        return "rbxassetid://" .. tostring(image)
    end
    if type(image) == "string" then
        if image == "" then return "" end
        if image:find("rbxassetid://") or image:find("rbxthumb://") or image:find("http") then
            return image
        end
        if Library.Assets[image] then
            return Library.Assets[image]
        end
        local lower = string.lower(image)
        for k, v in pairs(Library.Assets) do
            if string.lower(tostring(k)) == lower then
                return v
            end
        end
        local getCustom = (typeof(getcustomasset) == "function" and getcustomasset)
            or (typeof(getsynasset) == "function" and getsynasset)
        if getCustom then
            local isFileFn = (typeof(isfile) == "function" and isfile)
            if (isFileFn and isFileFn(image)) or image:find("%.png$") or image:find("%.jpg$") or image:find("%.jpeg$") then
                local ok, asset = pcall(getCustom, image)
                if ok and asset and asset ~= "" then return asset end
            end
        end
        if tonumber(image) then
            return "rbxassetid://" .. image
        end
        if image:find("%.png$") or image:find("%.jpg$") then
            return Library.Assets.Zap or Library.Assets.ImageLogo or "rbxassetid://130551565616516"
        end
        return image
    end
    return ""
end

local function createDefaultBorderSequence(theme: { [string]: Color3 }): ColorSequence
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, theme.Accent),
        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.45, theme.AccentHover),
        ColorSequenceKeypoint.new(0.70, theme.StrokeSoft),
        ColorSequenceKeypoint.new(1.00, theme.Accent),
    })
end

local function getParentGui()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, parent = pcall(function() return CoreGui end)
    if ok and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function addRipple(button: GuiButton, color: Color3)
    button.ClipsDescendants = true
    button.MouseButton1Down:Connect(function(x, y)
        local ripple = make("Frame", {
            Name = "Ripple",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x - button.AbsolutePosition.X, y - button.AbsolutePosition.Y),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.65,
            BorderSizePixel = 0,
            ZIndex = button.ZIndex + 2,
            Parent = button,
        })
        corner(ripple, 100)
        local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
        tween(ripple, 0.45, {
            Size = UDim2.fromOffset(size, size),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        task.delay(0.48, function()
            if ripple then ripple:Destroy() end
        end)
    end)
end

-- Strict Clamping prevents window from going off-screen or under the top notch
local function clampWindowPosition(target: GuiObject, uiScale: UIScale?, customHeight: number?, customWidth: number?)
    elevateThread()
    local camera = workspace.CurrentCamera
    local vp = (camera and camera.ViewportSize) or Vector2.new(1920, 1080)
    local scale = 1
    pcall(function()
        if uiScale then
            scale = uiScale.Scale
        end
    end)
    local topInset = getTopInset()

    local effectiveH = customHeight or (target and target.AbsoluteSize and target.AbsoluteSize.Y) or 500
    local effectiveW = customWidth or (target and target.AbsoluteSize and target.AbsoluteSize.X) or 600

    local halfH = (effectiveH * scale) / 2
    local halfW = (effectiveW * scale) / 2

    local minOffsetY = (topInset + halfH + 8 - (vp.Y * 0.5)) / scale
    local maxOffsetY = ((vp.Y * 0.5) - halfH - 8) / scale
    if minOffsetY > maxOffsetY then
        maxOffsetY = minOffsetY
    end

    local minOffsetX = (halfW + 8 - (vp.X * 0.5)) / scale
    local maxOffsetX = ((vp.X * 0.5) - halfW - 8) / scale
    if minOffsetX > maxOffsetX then
        minOffsetX = 0
        maxOffsetX = 0
    end

    local currentOffsetY = (target and target.Position and target.Position.Y.Offset) or 0
    local currentOffsetX = (target and target.Position and target.Position.X.Offset) or 0

    local clampedY = math.clamp(currentOffsetY, minOffsetY, maxOffsetY)
    local clampedX = math.clamp(currentOffsetX, minOffsetX, maxOffsetX)

    if target then
        target.Position = UDim2.new(0.5, clampedX, 0.5, clampedY)
        return target.Position
    end
    return UDim2.new(0.5, 0, 0.5, 0)
end

local function bindDrag(handle: GuiObject, target: GuiObject, uiScale: UIScale?)
    local dragging = false
    local dragInput: InputObject? = nil
    local dragStart: Vector3? = nil
    local startPosition: UDim2? = nil

    handle.InputBegan:Connect(function(input)
        elevateThread()
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
            input.Changed:Connect(function()
                elevateThread()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        elevateThread()
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        elevateThread()
        if dragging and input == dragInput and dragStart and startPosition then
            pcall(function()
                local delta = input.Position - dragStart
                local scale = 1
                pcall(function()
                    if uiScale then
                        scale = uiScale.Scale
                    end
                end)
                local camera = workspace.CurrentCamera
                local vp = (camera and camera.ViewportSize) or Vector2.new(1920, 1080)
                local topInset = getTopInset()

                local rawOffsetX = startPosition.X.Offset + (delta.X / scale)
                local rawOffsetY = startPosition.Y.Offset + (delta.Y / scale)

                local currentH = target.AbsoluteSize.Y
                -- If minimized (height <= 80), clamp against full height so it never gets dragged too high to unminimize!
                local fullH = (currentH <= 80 and 540 or currentH)
                local halfH = (currentH * scale) / 2
                local halfTopH = (fullH * scale) / 2
                local halfW = (target.AbsoluteSize.X * scale) / 2

                local minOffsetY = (topInset + halfTopH + 8 - (vp.Y * 0.5)) / scale
                local maxOffsetY = ((vp.Y * 0.5) - halfH - 8) / scale
                if minOffsetY > maxOffsetY then
                    maxOffsetY = minOffsetY
                end

                local minOffsetX = (halfW + 8 - (vp.X * 0.5)) / scale
                local maxOffsetX = ((vp.X * 0.5) - halfW - 8) / scale
                if minOffsetX > maxOffsetX then
                    minOffsetX = 0
                    maxOffsetX = 0
                end

                local clampedY = math.clamp(rawOffsetY, minOffsetY, maxOffsetY)
                local clampedX = math.clamp(rawOffsetX, minOffsetX, maxOffsetX)

                target.Position = UDim2.new(
                    0.5,
                    clampedX,
                    0.5,
                    clampedY
                )
            end)
        end
    end)
end

local function bindResize(handle: GuiObject, target: GuiObject, minSize: Vector2, uiScale: UIScale?)
    local resizing = false
    local resizeInput: InputObject? = nil
    local startPos: Vector2? = nil
    local startSize: UDim2? = nil

    handle.InputBegan:Connect(function(input)
        elevateThread()
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startPos = Vector2.new(input.Position.X, input.Position.Y)
            startSize = target.Size
            input.Changed:Connect(function()
                elevateThread()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        elevateThread()
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            resizeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        elevateThread()
        if resizing and input == resizeInput and startPos and startSize then
            pcall(function()
                local scale = 1
                pcall(function()
                    if uiScale then
                        scale = uiScale.Scale
                    end
                end)
                local currentPos = Vector2.new(input.Position.X, input.Position.Y)
                local delta = (currentPos - startPos) / scale
                local newX = math.max(minSize.X, startSize.X.Offset + delta.X)
                local newY = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
                target.Size = UDim2.fromOffset(newX, newY)
                clampWindowPosition(target, uiScale)
            end)
        end
    end)
end

local function createIcon(parent: Instance, image: any, size: number, color: Color3, transparency: number?)
    local asset = normalizeAsset(image)
    return make("ImageLabel", {
        Name = "Icon",
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Image = asset,
        ImageColor3 = color,
        ImageTransparency = transparency or 0,
        ScaleType = Enum.ScaleType.Fit,
        Visible = asset ~= "",
        Parent = parent,
    })
end

local function createText(parent: Instance, name: string, text: string, size: number, color: Color3, bold: boolean?, order: number?)
    return make("TextLabel", {
        Name = name,
        Text = text,
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextSize = size,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order or 1,
        Parent = parent,
    })
end

-- Translucent Acrylic Card Row with Auto-Expanding Multi-Line Text
local function createCoreRow(self: any, parent: Instance, title: string, desc: string?, image: any?, height: number?, rightReservedWidth: number?, layoutOrder: number?, autoHeight: boolean?)
    local iconAsset = normalizeAsset(image or "")
    local hasIcon = iconAsset ~= ""
    local leftInset = hasIcon and 48 or 14
    local reservedRight = rightReservedWidth or 130
    local hasDesc = (desc and desc ~= "") or (autoHeight == true)
    local minHeight = height or (hasDesc and 64 or 52)

    local row = make("TextButton", {
        Name = "CoreRow",
        Text = "",
        AutoButtonColor = false,
        Size = autoHeight and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, minHeight),
        AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.52, -- Translucent glass effect
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 10,
        Parent = parent,
    })
    row.ClipsDescendants = not autoHeight
    corner(row, 10)
    local rowStroke = stroke(row, self.Theme.StrokeSoft, 1, 0.72)

    if autoHeight then
        make("UISizeConstraint", {
            MinSize = Vector2.new(0, minHeight),
            Parent = row,
        })
        padding(row, 0, 10, 0, 10)
    end

    -- Glowing left indicator
    local leftIndicator = make("Frame", {
        Name = "LeftIndicator",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 0.45, 0),
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(leftIndicator, 2)

    -- Specular glass rim highlight
    local topHighlight = make("Frame", {
        Name = "TopSpecular",
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Parent = row,
    })

    local iconWrap = make("Frame", {
        Name = "IconWrap",
        AnchorPoint = autoHeight and Vector2.new(0, 0) or Vector2.new(0, 0.5),
        Position = autoHeight and UDim2.new(0, 10, 0, 2) or UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = self.Theme.Sidebar,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Visible = hasIcon,
        Parent = row,
    })
    corner(iconWrap, 7)
    local iconWrapStroke = stroke(iconWrap, self.Theme.StrokeSoft, 1, 0.8)

    local icon = createIcon(iconWrap, iconAsset, 16, self.Theme.Accent, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)

    local textWrap = make("Frame", {
        Name = "TextWrap",
        AnchorPoint = autoHeight and Vector2.new(0, 0) or Vector2.new(0, 0.5),
        Position = autoHeight and UDim2.new(0, leftInset, 0, 0) or UDim2.new(0, leftInset, 0.5, 0),
        Size = autoHeight and UDim2.new(1, -leftInset - reservedRight, 0, 0) or UDim2.new(1, -leftInset - reservedRight, 1, -8),
        AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        ClipsDescendants = not autoHeight,
        Parent = row,
    })
    local tLayout = list(textWrap, 3)
    if not autoHeight then
        tLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    end

    make("TextLabel", {
        Name = "Title",
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = autoHeight and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        TextTruncate = autoHeight and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
        TextWrapped = autoHeight,
        BackgroundTransparency = 1,
        Size = autoHeight and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, 18),
        AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        LayoutOrder = 1,
        Parent = textWrap,
    })

    if hasDesc then
        make("TextLabel", {
            Name = "Desc",
            Text = tostring(desc or ""),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = self.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate = autoHeight and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Size = autoHeight and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, 26),
            AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            Visible = (desc and desc ~= "") or (autoHeight == true),
            LayoutOrder = 2,
            Parent = textWrap,
        })
    end

    row.MouseEnter:Connect(function()
        tween(row, 0.2, { BackgroundColor3 = self.Theme.SurfaceHover, BackgroundTransparency = 0.35 })
        tween(rowStroke, 0.2, { Color = self.Theme.Accent, Transparency = 0.35 })
        tween(leftIndicator, 0.2, { BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0.65, 0) })
        tween(topHighlight, 0.2, { BackgroundTransparency = 0.65 })
        if hasIcon then
            tween(iconWrapStroke, 0.2, { Color = self.Theme.Accent, Transparency = 0.4 })
        end
    end)
    row.MouseLeave:Connect(function()
        tween(row, 0.2, { BackgroundColor3 = self.Theme.Surface, BackgroundTransparency = 0.52 })
        tween(rowStroke, 0.2, { Color = self.Theme.StrokeSoft, Transparency = 0.72 })
        tween(leftIndicator, 0.2, { BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0.45, 0) })
        tween(topHighlight, 0.2, { BackgroundTransparency = 0.88 })
        if hasIcon then
            tween(iconWrapStroke, 0.2, { Color = self.Theme.StrokeSoft, Transparency = 0.8 })
        end
    end)

    return row
end

-- Page Component API Builder
local function createPageApi(window: any, scroll: ScrollingFrame)
    local api = {}
    local itemCounter = 0
    local function nextOrder(explicit: any): number
        itemCounter = itemCounter + 1
        return tonumber(explicit) or itemCounter
    end

    local function checkPremium(props: { [string]: any }?): boolean
        if props and props.IsPrem == false then
            window:Notify({
                Title = "Premium Required",
                Desc = "Please activate VIP / Premium",
                Duration = 3,
            })
            return false
        end
        return true
    end

    function api:Section(props: { [string]: any })
        props = props or {}
        local section = make("Frame", {
            Name = "Section",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        list(section, 10)

        local headerWrap = make("Frame", {
            Name = "SectionHeaderWrap",
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Parent = section,
        })
        local hLayout = list(headerWrap, 8, Enum.FillDirection.Horizontal)
        hLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local accentBar = make("Frame", {
            Name = "AccentBar",
            Size = UDim2.fromOffset(3, 16),
            BackgroundColor3 = window.Theme.Accent,
            BorderSizePixel = 0,
            Parent = headerWrap,
        })
        corner(accentBar, 2)

        make("TextLabel", {
            Name = "SectionTitle",
            Text = string.upper(tostring(props.Title or "Section")),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, 0),
            Parent = headerWrap,
        })

        local dividerLine = make("Frame", {
            Name = "SectionDivider",
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            LayoutOrder = 2,
            Parent = section,
        })
        make("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, window.Theme.Accent),
                ColorSequenceKeypoint.new(0.35, window.Theme.StrokeSoft),
                ColorSequenceKeypoint.new(1.00, window.Theme.Background),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0.00, 0.25),
                NumberSequenceKeypoint.new(0.65, 0.75),
                NumberSequenceKeypoint.new(1.00, 1.0),
            }),
            Parent = dividerLine,
        })

        local sectionApi = createPageApi(window, section :: any)
        sectionApi.Root = section
        function sectionApi:SetVisible(v: boolean)
            section.Visible = v
        end
        return sectionApi
    end

    function api:Label(props: { [string]: any })
        props = props or {}
        local autoHeight = props.AutoHeight ~= false
        local row = createCoreRow(window, scroll, tostring(props.Title or "Label"), props.Desc or "", props.Image or "", props.Height or 56, 20, nextOrder(props.Order), autoHeight)
        local item = {}
        function item:SetTitle(value: string)
            local titleLabel = row:FindFirstChild("Title", true)
            if titleLabel and titleLabel:IsA("TextLabel") then titleLabel.Text = value end
        end
        function item:SetDesc(value: string)
            local descLabel = row:FindFirstChild("Desc", true)
            if descLabel and descLabel:IsA("TextLabel") then
                descLabel.Text = tostring(value or "")
                descLabel.Visible = (tostring(value or "") ~= "")
            end
        end
        item.SetText = item.SetDesc
        function item:SetVisible(value: boolean) row.Visible = value end
        return item
    end

    function api:Button(props: { [string]: any })
        props = props or {}
        local callback = props.Callback or function() end
        local row = createCoreRow(window, scroll, tostring(props.Title or "Button"), props.Desc or "", props.Image or "Button", props.Height or 58, 50, nextOrder(props.Order))
        addRipple(row, window.Theme.Accent)

        local actionPill = make("Frame", {
            Name = "ActionPill",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(32, 32),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(actionPill, 8)
        stroke(actionPill, window.Theme.StrokeSoft, 1, 0.75)

        local glyph = createIcon(actionPill, props.RightIcon or "Button", 16, window.Theme.Muted, 0)
        glyph.AnchorPoint = Vector2.new(0.5, 0.5)
        glyph.Position = UDim2.fromScale(0.5, 0.5)

        row.MouseEnter:Connect(function()
            tween(glyph, 0.15, { ImageColor3 = window.Theme.Accent })
            tween(actionPill, 0.15, { BackgroundColor3 = window.Theme.AccentSoft, BackgroundTransparency = 0.1 })
        end)
        row.MouseLeave:Connect(function()
            tween(glyph, 0.15, { ImageColor3 = window.Theme.Muted })
            tween(actionPill, 0.15, { BackgroundColor3 = window.Theme.Sidebar, BackgroundTransparency = 0.35 })
        end)

        row.MouseButton1Click:Connect(function()
            if not checkPremium(props) then return end
            tween(row, 0.08, { Size = UDim2.new(1, 0, 0, (props.Height or 58) - 3) })
            task.delay(0.08, function()
                tween(row, 0.12, { Size = UDim2.new(1, 0, 0, props.Height or 58) })
            end)
            task.spawn(callback)
        end)

        local item = {}
        function item:SetTitle(value: string)
            local titleLabel = row:FindFirstChild("Title", true)
            if titleLabel and titleLabel:IsA("TextLabel") then titleLabel.Text = value end
        end
        function item:SetVisible(value: boolean) row.Visible = value end
        return item
    end

    function api:Toggle(props: { [string]: any })
        props = props or {}
        local value = (props.Value == true) or (props.Default == true)
        local callback = props.Callback or function() end
        local row = createCoreRow(window, scroll, tostring(props.Title or "Toggle"), props.Desc or "", props.Image or "", props.Height or 58, 68, nextOrder(props.Order))
        addRipple(row, window.Theme.Accent)

        local switch = make("Frame", {
            Name = "Switch",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.fromOffset(48, 26),
            BackgroundColor3 = value and window.Theme.Success or window.Theme.Sidebar,
            BackgroundTransparency = value and 0.15 or 0.35,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(switch, 13)
        local switchStroke = stroke(switch, value and window.Theme.Success or window.Theme.StrokeSoft, 1, value and 0.3 or 0.6)

        local knob = make("Frame", {
            Name = "Knob",
            Size = UDim2.fromOffset(20, 20),
            Position = value and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = switch,
        })
        corner(knob, 10)
        stroke(knob, Color3.fromRGB(200, 210, 230), 1, 0.7)

        local function setValue(nextValue: boolean, fire: boolean?)
            value = nextValue == true
            tween(switch, 0.22, {
                BackgroundColor3 = value and window.Theme.Success or window.Theme.Sidebar,
                BackgroundTransparency = value and 0.15 or 0.35,
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            tween(switchStroke, 0.22, {
                Color = value and window.Theme.Success or window.Theme.StrokeSoft,
                Transparency = value and 0.3 or 0.6,
            })
            tween(knob, 0.22, {
                Position = value and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
            }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            if fire then
                task.spawn(function() callback(value) end)
            end
        end

        row.MouseButton1Click:Connect(function()
            if not checkPremium(props) then return end
            setValue(not value, true)
        end)

        local item = {}
        function item:SetValue(nextVal: boolean) setValue(nextVal, false) end
        function item:GetValue() return value end
        function item:SetVisible(nextVal: boolean) row.Visible = nextVal end
        function item:SetTitle(newTitle: string)
            local titleLbl = row:FindFirstChild("TextWrap") and row.TextWrap:FindFirstChild("Title")
            if titleLbl and titleLbl:IsA("TextLabel") then
                titleLbl.Text = tostring(newTitle)
            end
        end
        function item:SetDesc(newDesc: string)
            local descLbl = row:FindFirstChild("TextWrap") and row.TextWrap:FindFirstChild("Desc")
            if descLbl and descLbl:IsA("TextLabel") then
                descLbl.Text = tostring(newDesc)
            end
        end
        return item
    end

    function api:Dropdown(props: { [string]: any })
        props = props or {}
        local options = props.List or props.Options or {}
        local multi = props.Multi == true
        local title = tostring(props.Title or "Dropdown")
        local desc = tostring(props.Desc or "")
        local callback = props.Callback or function() end
        local selected = props.Value
        if selected == nil and not multi then
            selected = options[1]
        elseif selected == nil and multi then
            selected = {}
        end
        local searchable = props.Searchable == true or (props.Searchable == nil and #options > 8)

        local container = make("Frame", {
            Name = "DropdownContainer",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        list(container, 6)

        local pillWidth = props.ValueWidth or 160
        local row = createCoreRow(window, container, title, desc, props.Image or "", props.Height or 58, pillWidth + 24, 1)
        addRipple(row, window.Theme.Accent)

        local pillWrap = make("Frame", {
            Name = "ValuePill",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(pillWidth, 34),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(pillWrap, 8)
        local pillStroke = stroke(pillWrap, window.Theme.StrokeSoft, 1, 0.75)
        padding(pillWrap, 12, 0, 12, 0)

        local valueLabel = make("TextLabel", {
            Name = "Value",
            Text = multi and table.concat(selected, ", ") or tostring(selected or "Select"),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 1, 0),
            Parent = pillWrap,
        })

        local chevron = createIcon(pillWrap, "Chevron", 16, window.Theme.Muted, 0)
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Position = UDim2.new(1, 0, 0.5, 0)

        -- Scrollable Glass Dropdown List
        local listFrame = make("ScrollingFrame", {
            Name = "DropdownList",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.20,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = false,
            LayoutOrder = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = window.Theme.Accent,
            ScrollBarImageTransparency = 0.25,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ElasticBehavior = Enum.ElasticBehavior.Always,
            Active = true,
            Parent = container,
        })
        corner(listFrame, 10)
        stroke(listFrame, window.Theme.StrokeSoft, 1, 0.6)
        padding(listFrame, 6, 6, 6, 8)
        local optionLayout = list(listFrame, 4)

        local open = false
        local buttons = {}
        local searchBox = nil

        local function getDropdownHeight()
            local contentHeight = optionLayout.AbsoluteContentSize.Y + 14
            if contentHeight <= 14 then
                local count = 0
                for _, entry in pairs(buttons) do
                    if type(entry) == "table" and entry.Button and entry.Button.Visible then
                        count = count + 1
                    end
                end
                contentHeight = (count * 40) + (searchable and 44 or 12)
            end
            local maxHeight = (window.DeviceType == "Phone" and 150) or (window.DeviceType == "Tablet" and 180) or 220
            return math.min(contentHeight, maxHeight)
        end

        local function filterOptions(query: string)
            local q = string.lower(tostring(query or ""))
            for opt, entry in pairs(buttons) do
                if type(entry) == "table" and entry.Button then
                    if q == "" or string.find(string.lower(tostring(opt)), q, 1, true) then
                        entry.Button.Visible = true
                    else
                        entry.Button.Visible = false
                    end
                end
            end
            task.defer(function()
                if open and listFrame.Parent then
                    tween(listFrame, 0.12, { Size = UDim2.new(1, 0, 0, getDropdownHeight()) })
                end
            end)
        end

        if searchable then
            local searchWrap = make("Frame", {
                Name = "DropdownSearchWrap",
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = window.Theme.Surface,
                BackgroundTransparency = 0.50,
                BorderSizePixel = 0,
                LayoutOrder = 0,
                Parent = listFrame,
            })
            corner(searchWrap, 6)
            stroke(searchWrap, window.Theme.StrokeSoft, 1, 0.75)
            padding(searchWrap, 8, 0, 8, 0)

            local sIcon = createIcon(searchWrap, "Search", 14, window.Theme.Muted, 0)
            sIcon.AnchorPoint = Vector2.new(0, 0.5)
            sIcon.Position = UDim2.new(0, 0, 0.5, 0)

            searchBox = make("TextBox", {
                Name = "SearchInput",
                Position = UDim2.new(0, 22, 0, 0),
                Size = UDim2.new(1, -22, 1, 0),
                Text = "",
                PlaceholderText = "Search...",
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = window.Theme.Text,
                PlaceholderColor3 = window.Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Parent = searchWrap,
            })

            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                filterOptions(searchBox.Text)
            end)
        end

        local function closeDropdown()
            open = false
            tween(listFrame, 0.18, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            tween(chevron, 0.18, { Rotation = 0 })
            task.delay(0.2, function()
                if not open and listFrame.Parent then
                    listFrame.Visible = false
                    if searchBox then
                        searchBox.Text = ""
                        for _, entry in pairs(buttons) do
                            if type(entry) == "table" and entry.Button then
                                entry.Button.Visible = true
                            end
                        end
                    end
                end
            end)
        end

        local function openDropdown()
            open = true
            listFrame.Visible = true
            listFrame.CanvasPosition = Vector2.new(0, 0)
            if searchBox then
                searchBox.Text = ""
                for _, entry in pairs(buttons) do
                    if type(entry) == "table" and entry.Button then
                        entry.Button.Visible = true
                    end
                end
            end
            local targetH = getDropdownHeight()
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            tween(listFrame, 0.22, { Size = UDim2.new(1, 0, 0, targetH) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            tween(chevron, 0.22, { Rotation = 180 })
        end

        local function selectedContains(val: any)
            if not multi or type(selected) ~= "table" then return selected == val end
            return table.find(selected, val) ~= nil
        end

        local function refreshValue()
            valueLabel.Text = multi and table.concat(selected, ", ") or tostring(selected or "Select")
            if valueLabel.Text == "" then valueLabel.Text = "Select" end
            for opt, entry in pairs(buttons) do
                local active = selectedContains(opt)
                if type(entry) == "table" and entry.Label then
                    entry.Label.TextColor3 = active and window.Theme.Accent or window.Theme.Text
                    entry.Button.BackgroundColor3 = active and window.Theme.AccentSoft or window.Theme.Surface
                    entry.Button.BackgroundTransparency = active and 0.20 or 0.75
                    entry.Dot.BackgroundTransparency = active and 0 or 1
                end
            end
        end

        local function addOption(opt: any, index: number?)
            local active = selectedContains(opt)
            local btn = make("TextButton", {
                Name = "Option_" .. tostring(opt),
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = active and window.Theme.AccentSoft or window.Theme.Surface,
                BackgroundTransparency = active and 0.20 or 0.75,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 36),
                LayoutOrder = (index or 1) + 1,
                Parent = listFrame,
            })
            corner(btn, 6)
            addRipple(btn, window.Theme.Accent)

            local optDot = make("Frame", {
                Name = "IndicatorDot",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = window.Theme.Accent,
                BackgroundTransparency = active and 0 or 1,
                BorderSizePixel = 0,
                Parent = btn,
            })
            corner(optDot, 3)

            local optLabel = make("TextLabel", {
                Name = "OptionText",
                Text = tostring(opt),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = active and window.Theme.Accent or window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 24, 0, 0),
                Size = UDim2.new(1, -28, 1, 0),
                Parent = btn,
            })

            btn.MouseEnter:Connect(function()
                if not selectedContains(opt) then
                    tween(btn, 0.15, { BackgroundTransparency = 0.40, BackgroundColor3 = window.Theme.SurfaceHover })
                    tween(optLabel, 0.15, { TextColor3 = Color3.fromRGB(255, 255, 255) })
                end
            end)
            btn.MouseLeave:Connect(function()
                if not selectedContains(opt) then
                    tween(btn, 0.15, { BackgroundTransparency = 0.75, BackgroundColor3 = window.Theme.Surface })
                    tween(optLabel, 0.15, { TextColor3 = window.Theme.Text })
                end
            end)

            buttons[opt] = { Button = btn, Dot = optDot, Label = optLabel }

            btn.MouseButton1Click:Connect(function()
                if multi then
                    local pos = table.find(selected, opt)
                    if pos then table.remove(selected, pos) else table.insert(selected, opt) end
                else
                    selected = opt
                    closeDropdown()
                end
                refreshValue()
                callback(selected)
            end)
        end

        for i, opt in ipairs(options) do
            addOption(opt, i)
        end

        row.MouseButton1Click:Connect(function()
            if not checkPremium(props) then return end
            if open then closeDropdown() else openDropdown() end
        end)

        local item = {}
        function item:SetValue(v: any) selected = v; refreshValue() end
        function item:GetValue() return selected end
        function item:SetVisible(v: boolean) container.Visible = v end
        function item:SetOptions(newOptions: { any })
            options = newOptions or {}
            for _, entry in pairs(buttons) do
                if type(entry) == "table" and entry.Button then
                    entry.Button:Destroy()
                elseif typeof(entry) == "Instance" then
                    entry:Destroy()
                end
            end
            table.clear(buttons)
            for i, opt in ipairs(options) do
                addOption(opt, i)
            end
            refreshValue()
            if searchBox then searchBox.Text = "" end
            if open then
                listFrame.Size = UDim2.new(1, 0, 0, getDropdownHeight())
            end
        end
        item.Refresh = item.SetOptions
        item.SetValues = item.SetOptions
        return item
    end

    function api:Segmented(props: { [string]: any })
        props = props or {}
        local options = props.Options or props.List or { "Option 1", "Option 2" }
        local selected = props.Value or options[1]
        local callback = props.Callback or function() end

        local row = make("Frame", {
            Name = "SegmentedContainer",
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.40,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        corner(row, 10)
        stroke(row, window.Theme.StrokeSoft, 1, 0.75)
        padding(row, 5, 5, 5, 5)
        local segLayout = list(row, 6, Enum.FillDirection.Horizontal)
        segLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        segLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local buttons = {}
        local numOpts = #options
        local totalGaps = (numOpts - 1) * 6 + 10

        local function refreshSegmented()
            for opt, btn in pairs(buttons) do
                local active = opt == selected
                tween(btn, 0.2, {
                    BackgroundColor3 = active and window.Theme.Accent or window.Theme.Sidebar,
                    BackgroundTransparency = active and 0.15 or 0.6,
                }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or window.Theme.Muted
            end
        end

        for _, opt in ipairs(options) do
            local btn = make("TextButton", {
                Name = "Segment_" .. tostring(opt),
                Text = tostring(opt),
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = opt == selected and Color3.fromRGB(255, 255, 255) or window.Theme.Muted,
                AutoButtonColor = false,
                BackgroundColor3 = opt == selected and window.Theme.Accent or window.Theme.Sidebar,
                BackgroundTransparency = opt == selected and 0.15 or 0.6,
                BorderSizePixel = 0,
                Size = UDim2.new(1 / numOpts, -math.ceil(totalGaps / numOpts), 1, 0),
                Parent = row,
            })
            corner(btn, 8)
            addRipple(btn, Color3.fromRGB(255, 255, 255))
            buttons[opt] = btn

            btn.MouseButton1Click:Connect(function()
                if not checkPremium(props) then return end
                selected = opt
                refreshSegmented()
                task.spawn(function() callback(selected) end)
            end)
        end

        local item = {}
        function item:SetValue(v: any) selected = v; refreshSegmented() end
        function item:GetValue() return selected end
        function item:SetVisible(v: boolean) row.Visible = v end
        return item
    end

    function api:SelectionBox(props: { [string]: any })
        props = props or {}
        local selections = props.Selections or { "Free", "Premium" }
        local descriptions = props.Descriptions or {}
        local checklist = props.Checklist or {}
        local buttonTexts = props.ButtonTexts or {}
        local callbacks = props.Callbacks or {}
        
        local selected = props.Value or selections[1]

        local container = make("Frame", {
            Name = "SelectionBoxContainer",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        list(container, 10)

        local segRow = make("Frame", {
            Name = "SegmentedContainer",
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.40,
            BorderSizePixel = 0,
            Parent = container,
        })
        corner(segRow, 10)
        stroke(segRow, window.Theme.StrokeSoft, 1, 0.75)
        padding(segRow, 6, 6, 6, 6)
        local segLayout = list(segRow, 6, Enum.FillDirection.Horizontal)
        segLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        segLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local segButtons = {}
        local numSelections = #selections
        local totalSegGaps = (numSelections - 1) * 6 + 12

        local card = make("Frame", {
            Name = "SelectionCardBody",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = container,
        })
        corner(card, 12)
        stroke(card, window.Theme.StrokeSoft, 1, 0.65)
        padding(card, 18, 16, 18, 16)
        list(card, 14)

        local headerRow = make("Frame", {
            Name = "HeaderRow",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Parent = card,
        })
        local cardTitleLabel = createText(headerRow, "CardTitle", "", 16, window.Theme.Text, true)

        local badgePill = make("Frame", {
            Name = "BadgePill",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = window.Theme.AccentSoft,
            BorderSizePixel = 0,
            Parent = headerRow,
        })
        corner(badgePill, 6)
        padding(badgePill, 10, 0, 10, 0)
        stroke(badgePill, window.Theme.Accent, 1, 0.5)

        local badgeText = make("TextLabel", {
            Name = "BadgeText",
            Text = "",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = window.Theme.Accent,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = badgePill,
        })

        local checklistContainer = make("Frame", {
            Name = "ChecklistContainer",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = card,
        })
        list(checklistContainer, 10)

        local actionBtn = make("TextButton", {
            Name = "ActionButton",
            Text = "",
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            AutoButtonColor = false,
            BackgroundColor3 = window.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 46),
            Parent = card,
        })
        corner(actionBtn, 8)
        addRipple(actionBtn, Color3.fromRGB(255, 255, 255))

        actionBtn.MouseEnter:Connect(function()
            tween(actionBtn, 0.16, { BackgroundColor3 = window.Theme.AccentHover })
        end)
        actionBtn.MouseLeave:Connect(function()
            tween(actionBtn, 0.16, { BackgroundColor3 = window.Theme.Accent })
        end)

        local actionBtnConn = nil

        local function updateSelectionView(targetOption: any)
            selected = targetOption

            for opt, btn in pairs(segButtons) do
                local active = opt == targetOption
                tween(btn, 0.2, {
                    BackgroundColor3 = active and window.Theme.Accent or window.Theme.Sidebar,
                    BackgroundTransparency = active and 0.15 or 0.6,
                }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or window.Theme.Muted
            end

            cardTitleLabel.Text = tostring(targetOption)
            local descVal = descriptions[targetOption] or descriptions[tostring(targetOption)] or ""
            badgeText.Text = string.upper(tostring(descVal))
            badgePill.Visible = (descVal ~= "")

            local matchedKey = targetOption
            if not checklist[matchedKey] then
                for k, v in pairs(checklist) do
                    if tostring(k):lower() == tostring(targetOption):lower() then
                        matchedKey = k
                        break
                    end
                end
            end

            local items = checklist[matchedKey] or {}

            local existingRows = {}
            for _, child in ipairs(checklistContainer:GetChildren()) do
                if child:IsA("Frame") and child.Name == "ItemRow" then
                    table.insert(existingRows, child)
                end
            end

            if #existingRows == #items and #items > 0 then
                for idx, it in ipairs(items) do
                    local itemRow = existingRows[idx]
                    local textLabel = itemRow:FindFirstChild("ItemText")
                    local checkDot = itemRow:FindFirstChild("CheckDot")
                    local checkmark = checkDot and checkDot:FindFirstChild("Checkmark")

                    local isCross = tostring(it):find("^✗") ~= nil or tostring(it):find("%[X%]") ~= nil or tostring(it):find("%[x%]") ~= nil or tostring(it):find("Not Owned") ~= nil
                    local iconColor = isCross and window.Theme.Danger or window.Theme.Success
                    local iconChar = isCross and "✗" or "✓"

                    if textLabel and textLabel:IsA("TextLabel") and textLabel.Text ~= tostring(it) then
                        textLabel.Text = tostring(it)
                    end
                    if checkmark and checkmark:IsA("TextLabel") and checkmark.Text ~= iconChar then
                        checkmark.Text = iconChar
                        checkmark.TextColor3 = iconColor
                    end
                    if checkDot and checkDot:IsA("Frame") then
                        checkDot.BackgroundColor3 = iconColor
                    end
                end
            else
                for _, child in ipairs(checklistContainer:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end

                for _, it in ipairs(items) do
                    local itemRow = make("Frame", {
                        Name = "ItemRow",
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundTransparency = 1,
                        Parent = checklistContainer,
                    })
                    local hLayout = list(itemRow, 10, Enum.FillDirection.Horizontal)
                    hLayout.VerticalAlignment = Enum.VerticalAlignment.Center

                    local isCross = tostring(it):find("^✗") ~= nil or tostring(it):find("%[X%]") ~= nil or tostring(it):find("%[x%]") ~= nil or tostring(it):find("Not Owned") ~= nil
                    local iconColor = isCross and window.Theme.Danger or window.Theme.Success
                    local iconChar = isCross and "✗" or "✓"

                    local checkDot = make("Frame", {
                        Name = "CheckDot",
                        Size = UDim2.fromOffset(20, 20),
                        BackgroundColor3 = iconColor,
                        BackgroundTransparency = 0.85,
                        BorderSizePixel = 0,
                        Parent = itemRow,
                    })
                    corner(checkDot, 10)
                    stroke(checkDot, iconColor, 1, 0.5)

                    make("TextLabel", {
                        Name = "Checkmark",
                        Text = iconChar,
                        Font = Enum.Font.GothamBold,
                        TextSize = 12,
                        TextColor3 = iconColor,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Parent = checkDot,
                    })

                    make("TextLabel", {
                        Name = "ItemText",
                        Text = tostring(it),
                        Font = Enum.Font.GothamMedium,
                        TextSize = 13,
                        TextColor3 = window.Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -34, 1, 0),
                        Parent = itemRow,
                    })
                end
            end

            local matchedBtnKey = targetOption
            if not buttonTexts[matchedBtnKey] then
                for k, v in pairs(buttonTexts) do
                    if tostring(k):lower() == tostring(targetOption):lower() then
                        matchedBtnKey = k
                        break
                    end
                end
            end
            actionBtn.Text = tostring(buttonTexts[matchedBtnKey] or ("Select " .. tostring(targetOption)))

            if actionBtnConn then
                actionBtnConn:Disconnect()
                actionBtnConn = nil
            end
            actionBtnConn = actionBtn.MouseButton1Click:Connect(function()
                if not checkPremium(props) then return end
                local matchedCbKey = targetOption
                if not callbacks[matchedCbKey] then
                    for k, v in pairs(callbacks) do
                        if tostring(k):lower() == tostring(targetOption):lower() then
                            matchedCbKey = k
                            break
                        end
                    end
                end
                local cb = callbacks[matchedCbKey]
                if type(cb) == "function" then
                    task.spawn(cb)
                end
            end)
        end

        for _, opt in ipairs(selections) do
            local btn = make("TextButton", {
                Name = "Segment_" .. tostring(opt),
                Text = tostring(opt),
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = opt == selected and Color3.fromRGB(255, 255, 255) or window.Theme.Muted,
                AutoButtonColor = false,
                BackgroundColor3 = opt == selected and window.Theme.Accent or window.Theme.Sidebar,
                BackgroundTransparency = opt == selected and 0.15 or 0.6,
                BorderSizePixel = 0,
                Size = UDim2.new(1 / numSelections, -math.ceil(totalSegGaps / numSelections), 1, 0),
                Parent = segRow,
            })
            corner(btn, 8)
            addRipple(btn, Color3.fromRGB(255, 255, 255))
            segButtons[opt] = btn

            btn.MouseButton1Click:Connect(function()
                updateSelectionView(opt)
            end)
        end

        updateSelectionView(selected)

        local apiItem = {}
        function apiItem:SetValue(v: any) updateSelectionView(v) end
        function apiItem:GetValue() return selected end
        function apiItem:SetVisible(v: boolean) container.Visible = v end
        function apiItem:SetChecklist(newList: any)
            checklist = newList or {}
            updateSelectionView(selected)
        end
        function apiItem:SetDescriptions(newDescs: any)
            descriptions = newDescs or {}
            updateSelectionView(selected)
        end
        function apiItem:Refresh()
            updateSelectionView(selected)
        end
        return apiItem
    end

    function api:FeatureCard(props: { [string]: any })
        props = props or {}
        local title = tostring(props.Title or "Feature Card")
        local badge = tostring(props.Badge or "")
        local items = props.Items or {}
        local buttonText = tostring(props.ButtonText or "Action")
        local callback = props.Callback or function() end

        local card = make("Frame", {
            Name = "FeatureCard",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        corner(card, 12)
        stroke(card, window.Theme.StrokeSoft, 1, 0.65)
        padding(card, 18, 16, 18, 16)
        list(card, 14)

        local headerRow = make("Frame", {
            Name = "HeaderRow",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Parent = card,
        })
        createText(headerRow, "CardTitle", title, 16, window.Theme.Text, true)

        if badge ~= "" then
            local badgePill = make("Frame", {
                Name = "BadgePill",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(0, 26),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = window.Theme.AccentSoft,
                BorderSizePixel = 0,
                Parent = headerRow,
            })
            corner(badgePill, 6)
            padding(badgePill, 10, 0, 10, 0)
            stroke(badgePill, window.Theme.Accent, 1, 0.5)

            make("TextLabel", {
                Name = "BadgeText",
                Text = badge,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = window.Theme.Accent,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                AutomaticSize = Enum.AutomaticSize.X,
                Parent = badgePill,
            })
        end

        for _, it in ipairs(items) do
            local itemRow = make("Frame", {
                Name = "ItemRow",
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Parent = card,
            })
            local hLayout = list(itemRow, 10, Enum.FillDirection.Horizontal)
            hLayout.VerticalAlignment = Enum.VerticalAlignment.Center

            local checkDot = make("Frame", {
                Name = "CheckDot",
                Size = UDim2.fromOffset(20, 20),
                BackgroundColor3 = window.Theme.Success,
                BackgroundTransparency = 0.85,
                BorderSizePixel = 0,
                Parent = itemRow,
            })
            corner(checkDot, 10)
            stroke(checkDot, window.Theme.Success, 1, 0.5)

            make("TextLabel", {
                Name = "Checkmark",
                Text = "✓",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = window.Theme.Success,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Parent = checkDot,
            })

            make("TextLabel", {
                Name = "ItemText",
                Text = tostring(it),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -34, 1, 0),
                Parent = itemRow,
            })
        end

        if buttonText ~= "" then
            local actionBtn = make("TextButton", {
                Name = "ActionButton",
                Text = buttonText,
                Font = Enum.Font.GothamBold,
                TextSize = 15,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                AutoButtonColor = false,
                BackgroundColor3 = window.Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 46),
                Parent = card,
            })
            corner(actionBtn, 8)
            addRipple(actionBtn, Color3.fromRGB(255, 255, 255))

            actionBtn.MouseEnter:Connect(function()
                tween(actionBtn, 0.16, { BackgroundColor3 = window.Theme.AccentHover })
            end)
            actionBtn.MouseLeave:Connect(function()
                tween(actionBtn, 0.16, { BackgroundColor3 = window.Theme.Accent })
            end)
            actionBtn.MouseButton1Click:Connect(function()
                if not checkPremium(props) then return end
                task.spawn(callback)
            end)
        end

        local item = {}
        function item:SetVisible(v: boolean) card.Visible = v end
        return item
    end

    function api:Search(props: { [string]: any })
        props = props or {}
        local placeholder = tostring(props.Placeholder or "Search components...")
        local callback = props.Callback or function() end

        local container = make("Frame", {
            Name = "SearchContainer",
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.40,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        corner(container, 10)
        local searchStroke = stroke(container, window.Theme.StrokeSoft, 1, 0.7)

        local searchIcon = createIcon(container, "Search", 18, window.Theme.Muted, 0)
        searchIcon.AnchorPoint = Vector2.new(0, 0.5)
        searchIcon.Position = UDim2.new(0, 14, 0.5, 0)

        local textBox = make("TextBox", {
            Name = "SearchInput",
            Text = "",
            PlaceholderText = placeholder,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = window.Theme.Text,
            PlaceholderColor3 = window.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(42, 0),
            Size = UDim2.new(1, -56, 1, 0),
            Parent = container,
        })

        textBox.Focused:Connect(function()
            if not checkPremium(props) then
                textBox:ReleaseFocus()
                return
            end
            tween(searchStroke, 0.15, { Color = window.Theme.Accent, Transparency = 0.3 })
            tween(searchIcon, 0.15, { ImageColor3 = window.Theme.Accent })
        end)

        textBox.FocusLost:Connect(function()
            tween(searchStroke, 0.15, { Color = window.Theme.StrokeSoft, Transparency = 0.7 })
            tween(searchIcon, 0.15, { ImageColor3 = window.Theme.Muted })
        end)

        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            if props.IsPrem == false then return end
            local query = textBox.Text:lower()
            task.spawn(function() callback(query) end)
        end)

        local item = {}
        function item:SetVisible(v: boolean) container.Visible = v end
        return item
    end

    function api:Slider(props: { [string]: any })
        props = props or {}
        local min = tonumber(props.Min) or 0
        local max = tonumber(props.Max) or 100
        local step = tonumber(props.Step) or 1
        local suffix = tostring(props.Suffix or "")
        local precision = tonumber(props.Precision)
        if not precision then
            local sStr = tostring(step)
            local dot = string.find(sStr, "%.")
            if dot then
                precision = #sStr - dot
            else
                precision = 0
            end
        end

        local value = tonumber(props.Value) or tonumber(props.Default) or min
        local callback = props.Callback or function() end
        local sliderWidth = props.Width or (suffix ~= "" and 150 or 135)

        local row = createCoreRow(window, scroll, tostring(props.Title or "Slider"), props.Desc or "", props.Image or "", props.Height or (props.Desc and 64 or 52), sliderWidth + 18, nextOrder(props.Order))

        local sliderWrap = make("Frame", {
            Name = "SliderWrap",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(sliderWidth, 38),
            BackgroundTransparency = 1,
            Parent = row,
        })

        local function formatVal(v: number): string
            if precision > 0 then
                return string.format("%." .. tostring(precision) .. "f", v) .. suffix
            else
                return tostring(math.floor(v + 0.5)) .. suffix
            end
        end

        local maxFormatted = formatVal(max)
        local pillWidth = math.max(48, #maxFormatted * 8 + 14)

        local numberPill = make("Frame", {
            Name = "NumberPill",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(pillWidth, 20),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = sliderWrap,
        })
        corner(numberPill, 6)
        stroke(numberPill, window.Theme.StrokeSoft, 1, 0.8)

        local numberLabel = make("TextLabel", {
            Name = "Number",
            Text = formatVal(value),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Center,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = numberPill,
        })

        local bar = make("Frame", {
            Name = "Bar",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(1, 0, 0, 6),
            BackgroundColor3 = window.Theme.Sidebar,
            BorderSizePixel = 0,
            Parent = sliderWrap,
        })
        corner(bar, 3)

        local fill = make("Frame", {
            Name = "Fill",
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = window.Theme.Accent,
            BorderSizePixel = 0,
            Parent = bar,
        })
        corner(fill, 3)

        local knob = make("Frame", {
            Name = "Knob",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(15, 15),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = fill,
        })
        corner(knob, 8)
        stroke(knob, window.Theme.Accent, 1.5, 0.2)

        local dragging = false
        local function setValueFromAlpha(alpha: number, fire: boolean?)
            alpha = math.clamp(alpha, 0, 1)
            local raw = min + ((max - min) * alpha)
            if step > 0 then
                value = math.floor(((raw - min) / step) + 0.5) * step + min
            else
                value = raw
            end
            value = math.clamp(value, min, max)
            local fillRatio = (value - min) / math.max(max - min, 0.0001)
            fill.Size = UDim2.fromScale(math.clamp(fillRatio, 0, 1), 1)
            numberLabel.Text = formatVal(value)
            if fire then callback(value) end
        end

        local function fromX(x: number)
            setValueFromAlpha((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), true)
        end

        bar.InputBegan:Connect(function(input)
            elevateThread()
            if not checkPremium(props) then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                pcall(function() fromX(input.Position.X) end)
            end
        end)
        bar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            elevateThread()
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                pcall(function() fromX(input.Position.X) end)
            end
        end)

        setValueFromAlpha((value - min) / math.max(max - min, 0.0001), false)

        local item = {}
        function item:SetValue(v: number)
            if step > 0 then
                value = math.floor(((v - min) / step) + 0.5) * step + min
            else
                value = v
            end
            value = math.clamp(value, min, max)
            setValueFromAlpha((value - min) / math.max(max - min, 0.0001), false)
        end
        function item:GetValue() return value end
        function item:SetVisible(v: boolean) row.Visible = v end
        return item
    end

    function api:Textbox(props: { [string]: any })
        props = props or {}
        local callback = props.Callback or function() end
        local boxWidth = props.Width or (window.DeviceType == "Phone" and 140 or 160)
        local row = createCoreRow(window, scroll, tostring(props.Title or "Textbox"), props.Desc or "", props.Image or "Textbox", props.Height or 64, boxWidth + 18, nextOrder(props.Order), true)

        local boxWrap = make("Frame", {
            Name = "InputWrap",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(boxWidth, 32),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.50,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = row,
        })
        corner(boxWrap, 8)
        local boxStroke = stroke(boxWrap, window.Theme.StrokeSoft, 1, 0.75)
        padding(boxWrap, 10, 0, 10, 0)

        local box = make("TextBox", {
            Name = "Input",
            Text = tostring(props.Value or props.Default or ""),
            PlaceholderText = tostring(props.Placeholder or "Enter text"),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = window.Theme.Text,
            PlaceholderColor3 = window.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = props.ClearTextOnFocus == true or props.ClearText == true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = boxWrap,
        })

        box.Focused:Connect(function()
            if not checkPremium(props) then
                box:ReleaseFocus()
                return
            end
            tween(boxStroke, 0.16, { Color = window.Theme.Accent, Transparency = 0.3 })
            tween(boxWrap, 0.16, { BackgroundTransparency = 0.35 })
        end)
        box.FocusLost:Connect(function(enterPressed)
            tween(boxStroke, 0.16, { Color = window.Theme.StrokeSoft, Transparency = 0.75 })
            tween(boxWrap, 0.16, { BackgroundTransparency = 0.50 })
            if props.IsPrem ~= false then
                callback(box.Text, enterPressed)
            end
        end)

        local item = {}
        function item:SetValue(v: string) box.Text = v end
        function item:GetValue() return box.Text end
        function item:SetPlaceholderText(v: string) box.PlaceholderText = v end
        function item:SetVisible(v: boolean) row.Visible = v end
        return item
    end

    function api:Keybind(props: { [string]: any })
        props = props or {}
        local title = tostring(props.Title or "Keybind")
        local desc = tostring(props.Desc or "")
        local callback = props.Callback or function() end
        local currentKey = props.Value or props.Default or Enum.KeyCode.Unknown
        if typeof(currentKey) == "string" then
            local resolvedKey = Enum.KeyCode[currentKey]
            if resolvedKey then currentKey = resolvedKey end
        end
        local pillWidth = props.Width or (window.DeviceType == "Phone" and 90 or 100)
        local row = createCoreRow(window, scroll, title, desc, props.Image or "Key", props.Height or (desc ~= "" and 62 or 52), pillWidth + 24, nextOrder(props.Order))
        addRipple(row, window.Theme.Accent)

        local pillWrap = make("Frame", {
            Name = "KeybindPill",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(pillWidth, 30),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(pillWrap, 8)
        local pillStroke = stroke(pillWrap, window.Theme.StrokeSoft, 1, 0.75)
        padding(pillWrap, 8, 0, 8, 0)

        local function getKeyName(kc: any): string
            if typeof(kc) == "EnumItem" then
                return kc.Name
            elseif type(kc) == "string" then
                return kc
            end
            return "None"
        end

        local keyLabel = make("TextLabel", {
            Name = "KeyName",
            Text = "[ " .. getKeyName(currentKey) .. " ]",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Center,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = pillWrap,
        })

        local listening = false
        local connection = nil

        local function stopListening()
            listening = false
            if connection then
                connection:Disconnect()
                connection = nil
            end
            keyLabel.Text = "[ " .. getKeyName(currentKey) .. " ]"
            tween(pillStroke, 0.18, { Color = window.Theme.StrokeSoft, Transparency = 0.75 })
            tween(pillWrap, 0.18, { BackgroundColor3 = window.Theme.Sidebar })
        end

        local function startListening()
            if not checkPremium(props) then return end
            listening = true
            keyLabel.Text = "[ ... ]"
            tween(pillStroke, 0.18, { Color = window.Theme.Accent, Transparency = 0.1 })
            tween(pillWrap, 0.18, { BackgroundColor3 = window.Theme.AccentSoft })

            if connection then connection:Disconnect() end
            connection = UserInputService.InputBegan:Connect(function(input)
                elevateThread()
                if not listening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local chosenKey = input.KeyCode
                    if chosenKey == Enum.KeyCode.Escape then
                        currentKey = Enum.KeyCode.Unknown
                    else
                        currentKey = chosenKey
                    end
                    stopListening()
                    callback(currentKey, getKeyName(currentKey))
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    stopListening()
                end
            end)
        end

        row.MouseButton1Click:Connect(function()
            if listening then
                stopListening()
            else
                startListening()
            end
        end)

        local item = {}
        function item:SetValue(kc: any)
            if typeof(kc) == "string" and Enum.KeyCode[kc] then
                currentKey = Enum.KeyCode[kc]
            else
                currentKey = kc
            end
            keyLabel.Text = "[ " .. getKeyName(currentKey) .. " ]"
        end
        function item:GetValue() return currentKey end
        function item:SetVisible(v: boolean) row.Visible = v end
        return item
    end

    function api:Colorpicker(props: { [string]: any })
        props = props or {}
        local title = tostring(props.Title or "Color Picker")
        local desc = tostring(props.Desc or "")
        local currentColor = props.Value or props.Default or Color3.fromRGB(255, 255, 255)
        local callback = props.Callback or function() end

        local container = make("Frame", {
            Name = "ColorpickerContainer",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        list(container, 6)

        local row = createCoreRow(window, container, title, desc, props.Image or "Theme", props.Height or (desc ~= "" and 62 or 52), 92, 1)
        addRipple(row, window.Theme.Accent)

        local swatchWrap = make("Frame", {
            Name = "SwatchWrap",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(78, 28),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(swatchWrap, 6)
        stroke(swatchWrap, window.Theme.StrokeSoft, 1, 0.75)

        local swatch = make("Frame", {
            Name = "ColorSwatch",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 6, 0.5, 0),
            Size = UDim2.fromOffset(22, 16),
            BackgroundColor3 = currentColor,
            BorderSizePixel = 0,
            Parent = swatchWrap,
        })
        corner(swatch, 4)
        stroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.5)

        local hexLabel = make("TextLabel", {
            Name = "HexLabel",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -4, 0.5, 0),
            Size = UDim2.new(1, -34, 1, 0),
            Text = "#" .. currentColor:ToHex():upper():sub(1, 6),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = window.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Center,
            BackgroundTransparency = 1,
            Parent = swatchWrap,
        })

        local tray = make("Frame", {
            Name = "ColorTray",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = false,
            LayoutOrder = 2,
            Parent = container,
        })
        corner(tray, 10)
        stroke(tray, window.Theme.StrokeSoft, 1, 0.6)
        padding(tray, 12, 10, 12, 10)
        list(tray, 8)

        local presetRow = make("Frame", {
            Name = "Presets",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Parent = tray,
        })
        list(presetRow, 8, Enum.FillDirection.Horizontal)

        local presets = {
            Color3.fromRGB(239, 68, 68),
            Color3.fromRGB(245, 158, 11),
            Color3.fromRGB(34, 197, 94),
            Color3.fromRGB(14, 165, 233),
            Color3.fromRGB(59, 130, 246),
            Color3.fromRGB(168, 85, 247),
            Color3.fromRGB(244, 63, 94),
            Color3.fromRGB(255, 255, 255),
        }

        local rVal = math.floor(currentColor.R * 255 + 0.5)
        local gVal = math.floor(currentColor.G * 255 + 0.5)
        local bVal = math.floor(currentColor.B * 255 + 0.5)
        local updateColor

        for _, pc in ipairs(presets) do
            local pBtn = make("TextButton", {
                Name = "Preset",
                Text = "",
                Size = UDim2.fromOffset(24, 24),
                BackgroundColor3 = pc,
                BorderSizePixel = 0,
                Parent = presetRow,
            })
            corner(pBtn, 6)
            stroke(pBtn, Color3.fromRGB(255, 255, 255), 1, 0.6)
            pBtn.MouseButton1Click:Connect(function()
                updateColor(pc)
            end)
        end

        local function makeChannelSlider(label: string, initial: number, channelColor: Color3, onChanChange: (number) -> ())
            local chanWrap = make("Frame", {
                Name = label .. "Channel",
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Parent = tray,
            })

            local chanLabel = make("TextLabel", {
                Name = "ChanTag",
                Size = UDim2.fromOffset(20, 22),
                Text = label,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = channelColor,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = chanWrap,
            })

            local chanBar = make("Frame", {
                Name = "Bar",
                Position = UDim2.new(0, 24, 0.5, -3),
                Size = UDim2.new(1, -70, 0, 6),
                BackgroundColor3 = window.Theme.Surface,
                BorderSizePixel = 0,
                Parent = chanWrap,
            })
            corner(chanBar, 3)

            local chanFill = make("Frame", {
                Name = "Fill",
                Size = UDim2.fromScale(initial / 255, 1),
                BackgroundColor3 = channelColor,
                BorderSizePixel = 0,
                Parent = chanBar,
            })
            corner(chanFill, 3)

            local valText = make("TextLabel", {
                Name = "ValText",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(40, 20),
                Text = tostring(initial),
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1,
                Parent = chanWrap,
            })

            local dragging = false
            local function updateFromX(x: number)
                local alpha = math.clamp((x - chanBar.AbsolutePosition.X) / math.max(chanBar.AbsoluteSize.X, 1), 0, 1)
                local v = math.floor(alpha * 255 + 0.5)
                chanFill.Size = UDim2.fromScale(alpha, 1)
                valText.Text = tostring(v)
                onChanChange(v)
            end

            chanBar.InputBegan:Connect(function(input)
                elevateThread()
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    pcall(function() updateFromX(input.Position.X) end)
                end
            end)
            chanBar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                elevateThread()
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    pcall(function() updateFromX(input.Position.X) end)
                end
            end)

            return {
                Set = function(v: number)
                    v = math.clamp(v, 0, 255)
                    chanFill.Size = UDim2.fromScale(v / 255, 1)
                    valText.Text = tostring(v)
                end
            }
        end

        local rSlider, gSlider, bSlider
        updateColor = function(c: Color3)
            currentColor = c
            rVal = math.floor(c.R * 255 + 0.5)
            gVal = math.floor(c.G * 255 + 0.5)
            bVal = math.floor(c.B * 255 + 0.5)
            swatch.BackgroundColor3 = c
            hexLabel.Text = "#" .. c:ToHex():upper():sub(1, 6)
            if rSlider then rSlider.Set(rVal) end
            if gSlider then gSlider.Set(gVal) end
            if bSlider then bSlider.Set(bVal) end
            callback(c)
        end

        rSlider = makeChannelSlider("R", rVal, Color3.fromRGB(244, 63, 94), function(v)
            rVal = v
            local c = Color3.fromRGB(rVal, gVal, bVal)
            currentColor = c
            swatch.BackgroundColor3 = c
            hexLabel.Text = "#" .. c:ToHex():upper():sub(1, 6)
            callback(c)
        end)
        gSlider = makeChannelSlider("G", gVal, Color3.fromRGB(34, 197, 94), function(v)
            gVal = v
            local c = Color3.fromRGB(rVal, gVal, bVal)
            currentColor = c
            swatch.BackgroundColor3 = c
            hexLabel.Text = "#" .. c:ToHex():upper():sub(1, 6)
            callback(c)
        end)
        bSlider = makeChannelSlider("B", bVal, Color3.fromRGB(59, 130, 246), function(v)
            bVal = v
            local c = Color3.fromRGB(rVal, gVal, bVal)
            currentColor = c
            swatch.BackgroundColor3 = c
            hexLabel.Text = "#" .. c:ToHex():upper():sub(1, 6)
            callback(c)
        end)

        local open = false
        local function toggleTray()
            if not checkPremium(props) then return end
            open = not open
            if open then
                tray.Visible = true
                tray.Size = UDim2.new(1, 0, 0, 0)
                tween(tray, 0.20, { Size = UDim2.new(1, 0, 0, 132) })
            else
                tween(tray, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
                task.delay(0.2, function()
                    if not open and tray.Parent then tray.Visible = false end
                end)
            end
        end

        row.MouseButton1Click:Connect(toggleTray)

        local item = {}
        function item:SetValue(c: Color3) updateColor(c) end
        function item:GetValue() return currentColor end
        function item:SetVisible(v: boolean) container.Visible = v end
        return item
    end

    function api:ProgressBar(props: { [string]: any })
        props = props or {}
        local title = tostring(props.Title or "Progress")
        local status = tostring(props.Status or props.Desc or "")
        local rawProgress = tonumber(props.Progress) or tonumber(props.Value) or 0
        if rawProgress > 1 then rawProgress = rawProgress / 100 end
        local progress = math.clamp(rawProgress, 0, 1)
        local barColor = props.Color or window.Theme.Accent

        local row = make("Frame", {
            Name = "ProgressBarRow",
            Size = UDim2.new(1, 0, 0, 68),
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.52,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        corner(row, 12)
        stroke(row, window.Theme.StrokeSoft, 1, 0.75)
        padding(row, 14, 10, 14, 10)

        local topWrap = make("Frame", {
            Name = "TopWrap",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Parent = row,
        })

        local titleLabel = make("TextLabel", {
            Name = "Title",
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = window.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 1, 0),
            Parent = topWrap,
        })

        local percentLabel = make("TextLabel", {
            Name = "Percent",
            Text = tostring(math.floor(progress * 100 + 0.5)) .. "%",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = barColor,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(50, 20),
            Parent = topWrap,
        })

        local statusLabel = make("TextLabel", {
            Name = "Status",
            Text = status,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = window.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, 0, 0, 16),
            Parent = row,
        })

        local track = make("Frame", {
            Name = "Track",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 8),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(track, 4)

        local fill = make("Frame", {
            Name = "Fill",
            Size = UDim2.fromScale(progress, 1),
            BackgroundColor3 = barColor,
            BorderSizePixel = 0,
            Parent = track,
        })
        corner(fill, 4)

        local item = {}
        function item:SetProgress(val: number, newStatus: string?)
            if val > 1 then val = val / 100 end
            progress = math.clamp(val, 0, 1)
            tween(fill, 0.25, { Size = UDim2.fromScale(progress, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            percentLabel.Text = tostring(math.floor(progress * 100 + 0.5)) .. "%"
            if newStatus then
                statusLabel.Text = tostring(newStatus)
            end
        end
        function item:SetStatus(newStatus: string)
            statusLabel.Text = tostring(newStatus)
        end
        function item:SetTitle(newTitle: string)
            titleLabel.Text = tostring(newTitle)
        end
        function item:GetProgress() return progress end
        function item:SetVisible(v: boolean) row.Visible = v end
        return item
    end

    function api:Divider(props: { [string]: any })
        props = props or {}
        local divWrap = make("Frame", {
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, tonumber(props.Height) or 12),
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        local line = make("Frame", {
            Name = "Line",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -8, 0, 1),
            BackgroundColor3 = props.Color or Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = divWrap,
        })
        make("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, window.Theme.StrokeSoft),
                ColorSequenceKeypoint.new(0.50, window.Theme.Accent),
                ColorSequenceKeypoint.new(1.00, window.Theme.StrokeSoft),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0.00, 0.8),
                NumberSequenceKeypoint.new(0.50, 0.3),
                NumberSequenceKeypoint.new(1.00, 0.8),
            }),
            Parent = line,
        })
        local item = {}
        function item:SetVisible(v: boolean) divWrap.Visible = v end
        return item
    end

    function api:Spacer(props: { [string]: any })
        props = props or {}
        local space = make("Frame", {
            Name = "Spacer",
            Size = UDim2.new(1, 0, 0, tonumber(props.Size or props.Height) or 10),
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        local item = {}
        function item:SetSize(h: number) space.Size = UDim2.new(1, 0, 0, h) end
        function item:SetVisible(v: boolean) space.Visible = v end
        return item
    end

    function api:Banner(props: { [string]: any })
        props = props or {}
        local bType = tostring(props.Type or "Info")
        local title = tostring(props.Title or "Notice")
        local desc = tostring(props.Desc or props.Text or "")

        local typeColors = {
            Info = window.Theme.Accent,
            Success = window.Theme.Success,
            Warning = window.Theme.Warning,
            Danger = window.Theme.Danger,
        }
        local accentColor = typeColors[bType] or window.Theme.Accent

        local card = make("Frame", {
            Name = "BannerCard",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        corner(card, 10)
        stroke(card, accentColor, 1, 0.70)
        padding(card, 16, 12, 14, 12)

        local stripe = make("Frame", {
            Name = "Stripe",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -16, 0.5, 0),
            Size = UDim2.new(0, 4, 1, -12),
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0,
            Parent = card,
        })
        corner(stripe, 2)

        local contentWrap = make("Frame", {
            Name = "ContentWrap",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = card,
        })
        list(contentWrap, 4)

        local titleLabel = make("TextLabel", {
            Name = "Title",
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = accentColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Parent = contentWrap,
        })

        local descLabel = make("TextLabel", {
            Name = "Desc",
            Text = desc,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = window.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = contentWrap,
        })

        local item = {}
        function item:SetTitle(t: string) titleLabel.Text = tostring(t) end
        function item:SetText(d: string) descLabel.Text = tostring(d) end
        function item:SetType(newType: string)
            local col = typeColors[newType] or window.Theme.Accent
            titleLabel.TextColor3 = col
            stripe.BackgroundColor3 = col
        end
        function item:SetVisible(v: boolean) card.Visible = v end
        return item
    end
    api.Callout = api.Banner

    function api:MetricGrid(props: { [string]: any })
        props = props or {}
        local cols = math.clamp(tonumber(props.Cols) or 3, 1, 4)
        local items = props.Items or {}

        local gridWrap = make("Frame", {
            Name = "MetricGrid",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        local gapOffset = math.ceil((8 * (cols - 1)) / cols) + 1
        make("UIGridLayout", {
            CellPadding = UDim2.fromOffset(8, 8),
            CellSize = UDim2.new(1 / cols, -gapOffset, 0, 68),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = gridWrap,
        })

        local statCards = {}

        local function addStatCard(data: { [string]: any }, index: number)
            local card = make("Frame", {
                Name = "StatCard_" .. tostring(index),
                BackgroundColor3 = window.Theme.Surface,
                BackgroundTransparency = 0.52,
                BorderSizePixel = 0,
                LayoutOrder = index,
                Parent = gridWrap,
            })
            corner(card, 10)
            stroke(card, window.Theme.StrokeSoft, 1, 0.75)
            padding(card, 10, 8, 10, 8)

            local cardTitle = make("TextLabel", {
                Name = "StatTitle",
                Text = string.upper(tostring(data.Title or "STAT")),
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = window.Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Parent = card,
            })

            local cardValue = make("TextLabel", {
                Name = "StatValue",
                Text = tostring(data.Value or "0"),
                Font = Enum.Font.GothamBold,
                TextSize = 17,
                TextColor3 = data.Color or window.Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 16),
                Size = UDim2.new(1, 0, 0, 22),
                Parent = card,
            })

            local cardSub = make("TextLabel", {
                Name = "StatSub",
                Text = tostring(data.Sub or data.Trend or ""),
                Font = Enum.Font.GothamMedium,
                TextSize = 10,
                TextColor3 = data.Trend and window.Theme.Success or window.Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 38),
                Size = UDim2.new(1, 0, 0, 14),
                Parent = card,
            })

            statCards[index] = { Card = card, Title = cardTitle, Value = cardValue, Sub = cardSub }
        end

        for i, it in ipairs(items) do
            addStatCard(it, i)
        end

        local item = {}
        function item:UpdateItem(index: number, val: any, sub: string?)
            local entry = statCards[index]
            if entry then
                entry.Value.Text = tostring(val)
                if sub ~= nil then entry.Sub.Text = tostring(sub) end
            end
        end
        function item:SetVisible(v: boolean) gridWrap.Visible = v end
        return item
    end
    api.StatCard = api.MetricGrid

    function api:LogConsole(props: { [string]: any })
        props = props or {}
        local title = tostring(props.Title or "Console Log")
        local consoleH = tonumber(props.Height) or 160
        local maxLines = tonumber(props.MaxLines) or 120
        local autoScroll = props.AutoScroll ~= false

        local consoleWrap = make("Frame", {
            Name = "LogConsole",
            Size = UDim2.new(1, 0, 0, consoleH + 34),
            BackgroundColor3 = window.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(props.Order),
            Parent = scroll,
        })
        corner(consoleWrap, 10)
        stroke(consoleWrap, window.Theme.StrokeSoft, 1, 0.6)

        local header = make("Frame", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.50,
            BorderSizePixel = 0,
            Parent = consoleWrap,
        })
        corner(header, 10)
        padding(header, 10, 0, 8, 0)
        local hLayout = list(header, 8, Enum.FillDirection.Horizontal)
        hLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local dot1 = make("Frame", { Size = UDim2.fromOffset(8, 8), BackgroundColor3 = window.Theme.Danger, Parent = header })
        corner(dot1, 4)
        local dot2 = make("Frame", { Size = UDim2.fromOffset(8, 8), BackgroundColor3 = window.Theme.Warning, Parent = header })
        corner(dot2, 4)
        local dot3 = make("Frame", { Size = UDim2.fromOffset(8, 8), BackgroundColor3 = window.Theme.Success, Parent = header })
        corner(dot3, 4)

        make("TextLabel", {
            Name = "Title",
            Text = string.upper(title),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.6, 0, 1, 0),
            Parent = header,
        })

        local clearBtn = make("TextButton", {
            Name = "ClearBtn",
            Text = "CLEAR",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = window.Theme.Muted,
            BackgroundColor3 = window.Theme.SurfaceHover,
            BackgroundTransparency = 0.5,
            Size = UDim2.fromOffset(50, 20),
            AnchorPoint = Vector2.new(1, 0.5),
            Parent = header,
        })
        corner(clearBtn, 4)

        local logScroll = make("ScrollingFrame", {
            Name = "LogScroll",
            Position = UDim2.new(0, 0, 0, 32),
            Size = UDim2.new(1, 0, 1, -34),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = window.Theme.Accent,
            ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = consoleWrap,
        })
        padding(logScroll, 8, 6, 8, 6)
        list(logScroll, 3)

        local lines = {}

        local function addLogLine(msg: string, col: Color3)
            local timeStr = os.date("%X")
            local lineText = string.format("[%s] %s", timeStr, tostring(msg))

            local lineLabel = make("TextLabel", {
                Name = "LogLine",
                Text = lineText,
                Font = Enum.Font.Code,
                TextSize = 11,
                TextColor3 = col or window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = logScroll,
            })
            table.insert(lines, lineLabel)

            if #lines > maxLines then
                local old = table.remove(lines, 1)
                if old then old:Destroy() end
            end

            if autoScroll then
                task.defer(function()
                    if logScroll and logScroll.Parent then
                        logScroll.CanvasPosition = Vector2.new(0, 999999)
                    end
                end)
            end
        end

        clearBtn.MouseButton1Click:Connect(function()
            for _, l in ipairs(lines) do
                if l and l.Parent then l:Destroy() end
            end
            table.clear(lines)
        end)

        local item = {}
        function item:Log(msg: any) addLogLine(tostring(msg), window.Theme.Text) end
        function item:Info(msg: any) addLogLine(tostring(msg), window.Theme.Accent) end
        function item:Warn(msg: any) addLogLine(tostring(msg), window.Theme.Warning) end
        function item:Error(msg: any) addLogLine(tostring(msg), window.Theme.Danger) end
        function item:Success(msg: any) addLogLine(tostring(msg), window.Theme.Success) end
        function item:Clear()
            for _, l in ipairs(lines) do
                if l and l.Parent then l:Destroy() end
            end
            table.clear(lines)
        end
        function item:SetVisible(v: boolean) consoleWrap.Visible = v end
        return item
    end

    api.Root = scroll
    return api
end

-- Main Window Constructor
function Library:Window(props: { [string]: any })
    props = props or {}
    local self = setmetatable({}, Library)
    self.ThemeName = (type(props.Theme) == "string" and props.Theme) or "LightGray"
    self.Theme = resolveTheme(props.Theme or "LightGray")
    self.Tabs = {}
    self.SelectedTab = nil
    self.Keybind = (props.Config and props.Config.Keybind) or props.Keybind or Enum.KeyCode.RightControl
    self.ManualScale = nil
    self.DeviceType = detectDeviceType()
    self.TabCount = 0

    local appTitle = tostring(props.Title or "AUTOPROG // v2.0")
    local guiName = props.Name or "AutoProg_Window"
    local existing = getParentGui():FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local screenGui = make("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = props.DisplayOrder or 999,
        IgnoreGuiInset = true, -- Never displace or jerk on mobile menu toggle
        Parent = getParentGui(),
    })
    if typeof(protectgui) == "function" then
        pcall(protectgui, screenGui)
    elseif typeof(syn) == "table" and typeof((syn :: any).protect_gui) == "function" then
        pcall((syn :: any).protect_gui, screenGui)
    end
    self.ScreenGui = screenGui

    local isAlive = true
    local stopAnimation = function() end

    pcall(function()
        screenGui.Destroying:Connect(function()
            isAlive = false
            stopAnimation()
        end)
    end)
    pcall(function()
        screenGui.AncestryChanged:Connect(function(_, parent)
            if not parent then
                isAlive = false
                stopAnimation()
            end
        end)
    end)

    local shadow = make("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = props.Position or UDim2.fromScale(0.5, 0.5),
        Size = (props.Config and props.Config.Size) or props.Size or UDim2.fromOffset(800, 540),
        BackgroundTransparency = 1,
        Image = Library.Assets.Shadow,
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.35,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Parent = screenGui,
    })
    self.Shadow = shadow

    local uiScale = make("UIScale", {
        Scale = 1,
        Parent = shadow,
    })
    self.UIScale = uiScale

    local function updateDeviceScale()
        pcall(function()
            local setidentity = setthreadidentity or set_thread_identity or (syn and syn.set_thread_identity)
            if setidentity then pcall(setidentity, 8) end
            local camera = workspace.CurrentCamera
            if not camera then return end
            local vp = camera.ViewportSize
            local topInset = getTopInset()
            self.DeviceType = detectDeviceType()

            local finalScale = self.ManualScale or calculateDeviceScale(self.DeviceType, vp, topInset)
            uiScale.Scale = finalScale
            clampWindowPosition(shadow, uiScale)
        end)
    end

    local camera = workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateDeviceScale)
        task.spawn(updateDeviceScale)
    end

    function self:SetScale(newScale: number?)
        self.ManualScale = newScale
        updateDeviceScale()
    end

    function self:GetDeviceType(): string
        return self.DeviceType
    end

    -- Frosted Glass Window Body
    local root = make("Frame", {
        Name = "WindowRoot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -16, 1, -16),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.50, -- Translucent modern glass
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = shadow,
    })
    corner(root, 14)

    -- Animated Dynamic Glowing Border Stroke
    local rootStroke = stroke(root, Color3.fromRGB(255, 255, 255), 1.2, 0.12)
    rootStroke.Name = "AnimatedBorderStroke"
    local borderGradient = make("UIGradient", {
        Name = "BorderGradient",
        Color = props.BorderGradient or createDefaultBorderSequence(self.Theme),
        Rotation = 0,
        Parent = rootStroke,
    })
    self.BorderGradient = borderGradient
    self.BorderStroke = rootStroke
    self.CustomBorderGradient = props.BorderGradient ~= nil

    -- Frosted Glass Layer with Ambient Glow
    local bgLayer = make("Frame", {
        Name = "BackgroundLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 1,
        ClipsDescendants = true,
        Parent = root,
    })
    corner(bgLayer, 14)

    local bgImage = make("ImageLabel", {
        Name = "BackgroundImage",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Crop,
        Image = normalizeAsset(props.BackgroundImage or props.Image or "82941526973068"),
        ImageTransparency = props.BackgroundImageTransparency or props.ImageTransparency or 0.82,
        ImageColor3 = props.BackgroundImageColor or Color3.fromRGB(255, 255, 255),
        ZIndex = 1,
        Parent = bgLayer,
    })
    self.BackgroundImage = bgImage

    local ambientGlow = make("ImageLabel", {
        Name = "AmbientGlow",
        AnchorPoint = Vector2.new(0.5, 0.2),
        Position = UDim2.fromScale(0.5, 0.2),
        Size = UDim2.fromScale(1.4, 0.8),
        BackgroundTransparency = 1,
        Image = Library.Assets.Shadow,
        ImageColor3 = self.Theme.Accent,
        ImageTransparency = 0.86,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 1,
        Parent = bgLayer,
    })
    self.AmbientGlow = ambientGlow

    -- Border Animation Engine (Background animation removed: static light ray transparent)
    local borderAnimationActive = (props.BorderAnimation ~= false)
    local backgroundAnimationActive = false
    local borderSpeed = props.BorderSpeed or 60
    local bgTime = 0

    local animConn: RBXScriptConnection? = nil

    stopAnimation = function()
        if animConn then
            pcall(function() animConn:Disconnect() end)
            animConn = nil
        end
    end

    local function startAnimation()
        if animConn or not isAlive then return end
        if not borderAnimationActive and not backgroundAnimationActive then return end

        animConn = RunService.RenderStepped:Connect(function(dt)
            if not isAlive then
                stopAnimation()
                return
            end

            local setidentity = setthreadidentity or set_thread_identity or (syn and syn.set_thread_identity)
            if setidentity then
                pcall(setidentity, 8)
            end

            local parentCheckOk, hasParent = pcall(function()
                return screenGui and screenGui.Parent ~= nil
            end)
            if parentCheckOk and not hasParent then
                isAlive = false
                stopAnimation()
                return
            end

            if not borderAnimationActive and not backgroundAnimationActive then
                return
            end

            pcall(function()
                if borderAnimationActive and borderGradient and borderGradient.Parent then
                    borderGradient.Rotation = (borderGradient.Rotation + dt * borderSpeed) % 360
                end

                if backgroundAnimationActive then
                    bgTime = bgTime + dt
                    if imgGradient and imgGradient.Parent then
                        local waveOffset = -1 + ((bgTime * 0.35) % 2)
                        imgGradient.Offset = Vector2.new(waveOffset, math.sin(bgTime * 0.6) * 0.12)
                        imgGradient.Rotation = 35 + math.sin(bgTime * 0.4) * 12
                    end

                    if bgGradient and bgGradient.Parent then
                        bgGradient.Rotation = (bgGradient.Rotation + dt * 16) % 360
                        bgGradient.Offset = Vector2.new(math.sin(bgTime * 0.5) * 0.16, math.cos(bgTime * 0.4) * 0.16)
                    end
                    if ambientGlow and ambientGlow.Parent then
                        ambientGlow.ImageTransparency = 0.84 + (math.sin(bgTime * 1.3) * 0.05)
                    end
                end
            end)
        end)
        self.AnimConnection = animConn
    end

    if borderAnimationActive or backgroundAnimationActive then
        startAnimation()
    end

    function self:SetBorderAnimation(enabled: boolean, speed: number?)
        borderAnimationActive = enabled
        if speed then borderSpeed = speed end
        if borderAnimationActive or backgroundAnimationActive then
            startAnimation()
        else
            stopAnimation()
        end
    end

    function self:SetBorderGradient(seq: ColorSequence?)
        if seq then
            self.CustomBorderGradient = true
            borderGradient.Color = seq
        else
            self.CustomBorderGradient = false
            borderGradient.Color = createDefaultBorderSequence(self.Theme)
        end
    end

    function self:SetBackgroundImage(asset: string, transparency: number?)
        bgImage.Image = normalizeAsset(asset)
        if transparency then
            bgImage.ImageTransparency = transparency
        end
        bgImage.Visible = (asset ~= "")
    end

    function self:SetBackgroundAnimation(enabled: boolean)
        backgroundAnimationActive = enabled
        if borderAnimationActive or backgroundAnimationActive then
            startAnimation()
        else
            stopAnimation()
        end
    end

    self.Root = root

    -- Subtle Top Edge Glass Reflection
    local topGlow = make("Frame", {
        Name = "TopGlow",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = root,
    })
    make("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 1.0),
            NumberSequenceKeypoint.new(0.30, 0.4),
            NumberSequenceKeypoint.new(0.50, 0.2),
            NumberSequenceKeypoint.new(0.70, 0.4),
            NumberSequenceKeypoint.new(1.00, 1.0),
        }),
        Parent = topGlow,
    })

    -- Floating Glass Orb Restore Button
    local floatingOpenBtn = make("ImageButton", {
        Name = "FloatingOpenButton",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 24, 0.5, 0),
        Size = UDim2.fromOffset(54, 54),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Image = normalizeAsset(props.FloatingIcon or Library.Assets.FloatingToggle or "84269270119683"),
        ImageColor3 = (tostring(props.Icon or "autohub_icon.png"):find("%.png") or tostring(props.Icon or "autohub_icon.png"):find("%.jpg")) and Color3.fromRGB(255, 255, 255) or self.Theme.Accent,
        Visible = false,
        ZIndex = 200,
        Parent = screenGui,
    })
    corner(floatingOpenBtn, 27)
    stroke(floatingOpenBtn, self.Theme.Accent, 1, 0.4)
    addRipple(floatingOpenBtn, self.Theme.Accent)
    bindDrag(floatingOpenBtn, floatingOpenBtn, nil)

    -- Confirmation Modal for Exit
    local confirmOverlay = make("Frame", {
        Name = "ConfirmOverlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.60,
        Visible = false,
        ZIndex = 300,
        Parent = root,
    })

    local confirmModal = make("Frame", {
        Name = "ConfirmModal",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(320, 160),
        BackgroundColor3 = self.Theme.Sidebar,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 301,
        Parent = confirmOverlay,
    })
    corner(confirmModal, 12)
    stroke(confirmModal, self.Theme.StrokeSoft, 1, 0.5)
    padding(confirmModal, 20, 20, 20, 20)
    list(confirmModal, 12)

    createText(confirmModal, "ModalTitle", "Confirm Exit", 17, self.Theme.Text, true, 1)
    createText(confirmModal, "ModalDesc", "Are you sure you want to close this UI?", 14, self.Theme.Muted, false, 2)

    local modalBtnRow = make("Frame", {
        Name = "ModalBtnRow",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = confirmModal,
    })
    list(modalBtnRow, 12, Enum.FillDirection.Horizontal)

    local cancelBtn = make("TextButton", {
        Name = "CancelBtn",
        Text = "Cancel",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = self.Theme.Text,
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, -6, 1, 0),
        Parent = modalBtnRow,
    })
    corner(cancelBtn, 8)
    stroke(cancelBtn, self.Theme.StrokeSoft, 1, 0.7)
    addRipple(cancelBtn, self.Theme.Muted)

    local confirmBtn = make("TextButton", {
        Name = "ConfirmBtn",
        Text = "Exit",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Danger,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, -6, 1, 0),
        Parent = modalBtnRow,
    })
    corner(confirmBtn, 8)
    addRipple(confirmBtn, Color3.fromRGB(255, 255, 255))

    cancelBtn.MouseButton1Click:Connect(function()
        tween(confirmOverlay, 0.15, { BackgroundTransparency = 1 })
        local t = tween(confirmModal, 0.15, { Size = UDim2.fromOffset(250, 125) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            confirmOverlay.Visible = false
        end)
    end)

    confirmBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    local isWindowVisible = true
    local isTransitioning = false

    local function getBaseScale(): number
        local camera = workspace.CurrentCamera
        local vp = (camera and camera.ViewportSize) or Vector2.new(1920, 1080)
        return self.ManualScale or calculateDeviceScale(self.DeviceType, vp, getTopInset())
    end

    local function animateOpen()
        if isTransitioning then return end
        if shadow.Visible and isWindowVisible then return end
        isTransitioning = true
        isWindowVisible = true

        if floatingOpenBtn.Visible then
            local hideBtnTween = tween(floatingOpenBtn, 0.16, { Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            hideBtnTween.Completed:Connect(function()
                floatingOpenBtn.Visible = false
            end)
        end

        local targetScale = getBaseScale()
        clampWindowPosition(shadow, uiScale)

        shadow.Visible = true
        uiScale.Scale = targetScale * 0.88
        local basePos = shadow.Position
        shadow.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset + 16)

        local scaleAnim = tween(uiScale, 0.28, { Scale = targetScale }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local posAnim = tween(shadow, 0.28, { Position = basePos }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        scaleAnim.Completed:Connect(function()
            uiScale.Scale = targetScale
            shadow.Position = basePos
            clampWindowPosition(shadow, uiScale)
            isTransitioning = false
        end)
    end

    local function animateClose(showFloating: boolean?)
        if isTransitioning then return end
        if not shadow.Visible and not isWindowVisible then return end
        isTransitioning = true
        isWindowVisible = false

        local targetScale = getBaseScale()
        local basePos = shadow.Position
        local targetPos = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset + 16)

        local scaleAnim = tween(uiScale, 0.20, { Scale = targetScale * 0.85 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local posAnim = tween(shadow, 0.20, { Position = targetPos }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

        scaleAnim.Completed:Connect(function()
            shadow.Visible = false
            shadow.Position = basePos
            uiScale.Scale = targetScale
            isTransitioning = false

            if showFloating ~= false then
                floatingOpenBtn.Visible = true
                floatingOpenBtn.Size = UDim2.fromOffset(0, 0)
                tween(floatingOpenBtn, 0.25, { Size = UDim2.fromOffset(54, 54) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end
        end)
    end

    local function toggleVisibility()
        if isWindowVisible then
            animateClose(true)
        else
            animateOpen()
        end
    end

    local resizeHandle = make("ImageButton", {
        Name = "ResizeHandle",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -6, 1, -6),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        Image = Library.Assets.Resize,
        ImageColor3 = self.Theme.Muted,
        ImageTransparency = 0.5,
        ZIndex = 100,
        Parent = shadow,
    })
    bindResize(resizeHandle, shadow, Vector2.new(620, 420), uiScale)

    resizeHandle.MouseEnter:Connect(function()
        tween(resizeHandle, 0.15, { ImageTransparency = 0.1, ImageColor3 = self.Theme.Accent })
    end)
    resizeHandle.MouseLeave:Connect(function()
        tween(resizeHandle, 0.15, { ImageTransparency = 0.5, ImageColor3 = self.Theme.Muted })
    end)

    -- Frosted Glass Sidebar
    local sidebarWidth = 195
    local sidebar = make("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = self.Theme.Sidebar,
        BackgroundTransparency = 0.55, -- Translucent glass
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 5,
        Parent = root,
    })
    self.Sidebar = sidebar

    local sideDivider = make("Frame", {
        Name = "SideDivider",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    local sideHeader = make("Frame", {
        Name = "SideHeader",
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = sidebar,
    })
    bindDrag(sideHeader, shadow, uiScale)

    local sideLogoWrap = make("Frame", {
        Name = "SideLogoWrap",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 12, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = sideHeader,
    })
    corner(sideLogoWrap, 8)
    stroke(sideLogoWrap, self.Theme.Accent, 1, 0.5)

    local iconTarget = props.Icon or "autohub_icon.png"
    local resolvedIcon = normalizeAsset(iconTarget)
    if resolvedIcon == "" or resolvedIcon == "autohub_icon.png" then
        resolvedIcon = Library.Assets.Zap or Library.Assets.ImageLogo or "rbxassetid://130551565616516"
    end
    local isCustomIcon = (tostring(iconTarget):find("%.png") or tostring(iconTarget):find("%.jpg")) and (resolvedIcon:find("http") ~= nil)
    local iconColor = isCustomIcon and Color3.fromRGB(255, 255, 255) or self.Theme.Accent
    local sideLogo = createIcon(sideLogoWrap, resolvedIcon, 18, iconColor, 0)
    sideLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    sideLogo.Position = UDim2.fromScale(0.5, 0.5)

    local sideAppTitle = make("TextLabel", {
        Name = "AppTitle",
        Text = appTitle,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextWrapped = true,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(52, 0),
        Size = UDim2.new(1, -58, 1, 0),
        Parent = sideHeader,
    })

    -- Smooth Scrollable Tab Container (fits all tabs on mobile seamlessly)
    local tabContainer = make("ScrollingFrame", {
        Name = "TabContainer",
        Position = UDim2.fromOffset(0, 68),
        Size = UDim2.new(1, 0, 1, -158),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        ScrollBarImageTransparency = 0.25,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Always,
        ScrollingEnabled = true,
        Active = true,
        Parent = sidebar,
    })
    padding(tabContainer, 10, 6, 10, 26)
    list(tabContainer, 6)

    -- Translucent Glass Profile Widget
    local profileCard = make("Frame", {
        Name = "ProfileCard",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 10, 1, -10),
        Size = UDim2.new(1, -20, 0, 74),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    corner(profileCard, 10)
    stroke(profileCard, self.Theme.StrokeSoft, 1, 0.7)
    padding(profileCard, 10, 8, 10, 8)
    list(profileCard, 4)

    local pTopRow = make("Frame", {
        Name = "ProfileTop",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = profileCard,
    })

    local pAvatarWrap = make("Frame", {
        Name = "AvatarWrap",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = pTopRow,
    })
    corner(pAvatarWrap, 17)
    local pAvatarStroke = stroke(pAvatarWrap, self.Theme.Accent, 1, 0.4)

    local pAvatarImage = make("ImageLabel", {
        Name = "Avatar",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer and LocalPlayer.UserId or 1) .. "&w=100&h=100",
        Parent = pAvatarWrap,
    })

    local pInfoWrap = make("Frame", {
        Name = "InfoWrap",
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -42, 1, 0),
        BackgroundTransparency = 1,
        Parent = pTopRow,
    })
    local pInfoLayout = list(pInfoWrap, 2)
    pInfoLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local pUsernameLabel = make("TextLabel", {
        Name = "Username",
        Text = LocalPlayer and LocalPlayer.Name or "User",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Parent = pInfoWrap,
    })

    local pBadgePill = make("Frame", {
        Name = "BadgePill",
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = self.Theme.AccentSoft,
        BackgroundTransparency = 0.20,
        BorderSizePixel = 0,
        Parent = pInfoWrap,
    })
    corner(pBadgePill, 4)
    padding(pBadgePill, 6, 0, 6, 0)

    local pBadgeText = make("TextLabel", {
        Name = "BadgeText",
        Text = "VIP ACCESS",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = self.Theme.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = pBadgePill,
    })

    local pTimeLabel = make("TextLabel", {
        Name = "TimeLeft",
        Text = "Time left: Permanent",
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = self.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Parent = profileCard,
    })

    function self:UserProfile(userProps: { [string]: any })
        userProps = userProps or {}
        if userProps.Username then pUsernameLabel.Text = tostring(userProps.Username) end
        if userProps.Badge then pBadgeText.Text = string.upper(tostring(userProps.Badge)) end
        if userProps.TimeLeft then pTimeLabel.Text = "Time left: " .. tostring(userProps.TimeLeft) end
        if userProps.AvatarId then
            pAvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userProps.AvatarId) .. "&w=100&h=100"
        end
        return {
            SetUsername = function(_, name: string) pUsernameLabel.Text = name end,
            SetBadge    = function(_, badge: string) pBadgeText.Text = string.upper(badge) end,
            SetTimeLeft = function(_, timeStr: string) pTimeLabel.Text = "Time left: " .. timeStr end,
            SetAvatar   = function(_, id: number) pAvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(id) .. "&w=100&h=100" end,
        }
    end

    local contentArea = make("Frame", {
        Name = "ContentArea",
        Position = UDim2.new(0, sidebarWidth, 0, 68),
        Size = UDim2.new(1, -sidebarWidth, 1, -68),
        BackgroundTransparency = 1,
        Parent = root,
    })

    local topBar = make("Frame", {
        Name = "TopBar",
        Position = UDim2.new(0, sidebarWidth, 0, 0),
        Size = UDim2.new(1, -sidebarWidth, 0, 68),
        BackgroundTransparency = 1,
        Parent = root,
    })
    bindDrag(topBar, shadow, uiScale)

    local topDivider = make("Frame", {
        Name = "TopDivider",
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = topBar,
    })
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, self.Theme.StrokeSoft),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1.00, self.Theme.StrokeSoft),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0.70),
            NumberSequenceKeypoint.new(0.80, 0.85),
            NumberSequenceKeypoint.new(1.00, 1.00),
        }),
        Parent = topDivider,
    })

    local breadcrumbWrap = make("Frame", {
        Name = "BreadcrumbWrap",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 18, 0.5, 0),
        Size = UDim2.new(1, -135, 0, 44),
        BackgroundTransparency = 1,
        Parent = topBar,
    })
    local bLayout = list(breadcrumbWrap, 3)
    bLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local headerTopRow = make("Frame", {
        Name = "HeaderTopRow",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = breadcrumbWrap,
    })
    local htLayout = list(headerTopRow, 8, Enum.FillDirection.Horizontal)
    htLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local breadcrumbLabel = make("TextLabel", {
        Name = "Breadcrumb",
        Text = "OVERVIEW",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = headerTopRow,
    })

    local activeBadge = make("Frame", {
        Name = "ActiveBadge",
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = self.Theme.AccentSoft,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Parent = headerTopRow,
    })
    corner(activeBadge, 4)
    padding(activeBadge, 6, 0, 6, 0)

    local activeBadgeText = make("TextLabel", {
        Name = "BadgeText",
        Text = "ACTIVE",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = self.Theme.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = activeBadge,
    })

    local subRow = make("Frame", {
        Name = "SubRow",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Parent = breadcrumbWrap,
    })
    local subLayout = list(subRow, 6, Enum.FillDirection.Horizontal)
    subLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local pingWrap = make("Frame", {
        Name = "PingWrap",
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        Parent = subRow,
    })

    local pingDot = make("Frame", {
        Name = "PingDot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = self.Theme.Success,
        BorderSizePixel = 0,
        Parent = pingWrap,
    })
    corner(pingDot, 3)

    local pingHalo = make("Frame", {
        Name = "PingHalo",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = self.Theme.Success,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = pingWrap,
    })
    corner(pingHalo, 6)

    task.spawn(function()
        local setidentity = setthreadidentity or set_thread_identity or (syn and syn.set_thread_identity)
        while isAlive do
            if setidentity then pcall(setidentity, 8) end
            local hasParent = false
            local ok = pcall(function()
                hasParent = (screenGui and screenGui.Parent ~= nil)
            end)
            if not ok or not hasParent then break end

            local pingOk = pcall(function()
                if not (pingHalo and pingHalo.Parent) then return end
                pingHalo.Size = UDim2.fromOffset(6, 6)
                pingHalo.BackgroundTransparency = 0.4
                local t = tween(pingHalo, 1.4, {
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundTransparency = 1,
                }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                t.Completed:Wait()
            end)
            if not pingOk then break end
            task.wait(0.25)
        end
    end)

    local descLabelRef = make("TextLabel", {
        Name = "Subtitle",
        Text = tostring(props.Desc or props.Subtitle or "LOBBY : System Ready"),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = self.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Parent = subRow,
    })

    local controls = make("Frame", {
        Name = "Controls",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(102, 32),
        BackgroundTransparency = 1,
        Parent = topBar,
    })
    list(controls, 6, Enum.FillDirection.Horizontal)

    local function makeTopBtn(name: string, icon: string, callback: () -> ())
        local btn = make("ImageButton", {
            Name = name,
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(28, 28),
            AutoButtonColor = false,
            Parent = controls,
        })
        corner(btn, 7)
        local btnStroke = stroke(btn, self.Theme.StrokeSoft, 1, 0.8)

        local img = make("ImageLabel", {
            Name = "Icon",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(15, 15),
            BackgroundTransparency = 1,
            Image = normalizeAsset(icon),
            ImageColor3 = self.Theme.Muted,
            ScaleType = Enum.ScaleType.Fit,
            Parent = btn,
        })

        btn.MouseEnter:Connect(function()
            tween(btn, 0.15, { BackgroundTransparency = 0.15 })
            tween(img, 0.15, { ImageColor3 = self.Theme.Text })
            tween(btnStroke, 0.15, { Color = self.Theme.Accent, Transparency = 0.4 })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, 0.15, { BackgroundTransparency = 0.45 })
            tween(img, 0.15, { ImageColor3 = self.Theme.Muted })
            tween(btnStroke, 0.15, { Color = self.Theme.StrokeSoft, Transparency = 0.8 })
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Button 1: Hide the entire hub and reveal the flying ball
    makeTopBtn("HideBtn", "Hide", function()
        animateClose(true)
        self:Notify({ Title = "Hub Minimized", Desc = "Click floating ball or press RightControl to restore.", Duration = 2 })
    end)

    -- Button 2: Minimize / Collapse to header bar (clean minus icon)
    local isMinimized = false
    local defaultSize = (props.Config and props.Config.Size) or props.Size or UDim2.fromOffset(800, 540)
    local originalSize = defaultSize
    makeTopBtn("MinimizeBtn", "Minimize", function()
        isMinimized = not isMinimized
        if isMinimized then
            originalSize = (shadow.Size.Y.Offset > 68 and shadow.Size) or defaultSize
            resizeHandle.Visible = false
            tween(shadow, 0.22, { Size = UDim2.fromOffset(originalSize.X.Offset, 68) })
            contentArea.Visible = false
            sidebar.Visible = false
        else
            contentArea.Visible = true
            sidebar.Visible = true
            local targetSize = (originalSize.Y.Offset > 68 and originalSize) or defaultSize
            local clampedPos = clampWindowPosition(shadow, uiScale, targetSize.Y.Offset, targetSize.X.Offset)
            tween(shadow, 0.22, { Size = targetSize, Position = clampedPos })
            task.delay(0.22, function()
                resizeHandle.Visible = true
            end)
        end
    end)

    -- Button 3: Close modal prompt
    makeTopBtn("CloseBtn", "Close", function()
        confirmOverlay.BackgroundTransparency = 1
        confirmOverlay.Visible = true
        confirmModal.Size = UDim2.fromOffset(250, 125)
        tween(confirmOverlay, 0.20, { BackgroundTransparency = 0.60 })
        tween(confirmModal, 0.25, { Size = UDim2.fromOffset(320, 160) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    floatingOpenBtn.MouseButton1Click:Connect(function()
        animateOpen()
    end)

    local pages = make("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(16, 12),
        Size = UDim2.new(1, -32, 1, -24),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = contentArea,
    })

    function self:SetTitle(newTitle: string)
        appTitle = newTitle
        sideAppTitle.Text = newTitle
        if self.SelectedTab then
            breadcrumbLabel.Text = string.upper(self.SelectedTab)
        end
    end

    function self:SetSubtitle(newSub: string)
        descLabelRef.Text = newSub
    end
    self.SetSub = self.SetSubtitle

    function self:SetTheme(themeNameOrTable: any)
        self.Theme = resolveTheme(themeNameOrTable)
        if type(themeNameOrTable) == "string" then
            self.ThemeName = themeNameOrTable
        end

        root.BackgroundColor3 = self.Theme.Background
        if borderGradient and not self.CustomBorderGradient then
            borderGradient.Color = createDefaultBorderSequence(self.Theme)
        end
        if bgGradient then
            bgGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, self.Theme.Background),
                ColorSequenceKeypoint.new(0.40, self.Theme.Sidebar),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(16, 20, 34)),
                ColorSequenceKeypoint.new(1.00, self.Theme.Background),
            })
        end
        if ambientGlow then
            ambientGlow.ImageColor3 = self.Theme.Accent
        end
        sidebar.BackgroundColor3 = self.Theme.Sidebar
        sideLogo.ImageColor3 = self.Theme.Accent
        sideLogoWrap.UIStroke.Color = self.Theme.Accent
        pAvatarStroke.Color = self.Theme.Accent
        pBadgePill.BackgroundColor3 = self.Theme.AccentSoft
        pBadgeText.TextColor3 = self.Theme.Accent
        floatingOpenBtn.ImageColor3 = self.Theme.Accent
        floatingOpenBtn.UIStroke.Color = self.Theme.Accent

        for _, btn in ipairs(controls:GetChildren()) do
            if btn:IsA("ImageButton") then
                btn.BackgroundColor3 = self.Theme.Surface
                local s = btn:FindFirstChildOfClass("UIStroke")
                if s then s.Color = self.Theme.StrokeSoft end
                local ic = btn:FindFirstChild("Icon")
                if ic and ic:IsA("ImageLabel") then ic.ImageColor3 = self.Theme.Muted end
            end
        end

        if self.SelectedTab then
            self:SelectTab(self.SelectedTab)
        end
    end

    function self:SelectTab(name: string)
        for tabName, tab in pairs(self.Tabs) do
            local selected = tabName == name
            
            if selected then
                tab.Page.Visible = true
                tab.Page.Position = UDim2.new(0, 10, 0, 0)
                tab.Page.BackgroundTransparency = 1
                tween(tab.Page, 0.22, { Position = UDim2.fromScale(0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                tab.Page.Visible = false
            end

            tween(tab.Button, 0.18, {
                BackgroundColor3 = selected and self.Theme.AccentSoft or self.Theme.Sidebar,
                BackgroundTransparency = selected and 0.35 or 1,
            })
            if tab.Indicator then
                tween(tab.Indicator, 0.18, {
                    BackgroundTransparency = selected and 0 or 1,
                    Size = selected and UDim2.new(0, 3, 0.60, 0) or UDim2.new(0, 3, 0, 0),
                    BackgroundColor3 = self.Theme.Accent,
                })
            end
            if tab.TitleLabel then
                tab.TitleLabel.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or self.Theme.Muted
            end
            if tab.DescLabel then
                tab.DescLabel.TextColor3 = selected and self.Theme.Accent or Color3.fromRGB(110, 125, 150)
            end
            if tab.Icon then
                tab.Icon.ImageColor3 = selected and self.Theme.Accent or self.Theme.Muted
            end
        end
        self.SelectedTab = name
        breadcrumbLabel.Text = string.upper(name)
    end

    function self:Tab(tabProps: { [string]: any })
        tabProps = tabProps or {}
        self.TabCount = (self.TabCount or 0) + 1
        local currentTabOrder = self.TabCount

        local name = tostring(tabProps.Title or ("Tab " .. tostring(currentTabOrder)))
        local subDesc = tostring(tabProps.Subtitle or tabProps.Desc or "Active Module")
        local tabIconAsset = (tabProps.Icon and tabProps.Icon ~= "" and normalizeAsset(tabProps.Icon)) or ""
        local hasTabIcon = tabIconAsset ~= ""

        local tabHeight = (self.DeviceType == "Phone" and 46) or 50

        local tabButton = make("TextButton", {
            Name = "Tab_" .. name,
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, tabHeight),
            BackgroundColor3 = self.Theme.Sidebar,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = currentTabOrder,
            Parent = tabContainer,
        })
        corner(tabButton, 8)
        addRipple(tabButton, self.Theme.Accent)

        local tabIndicator = make("Frame", {
            Name = "ActiveIndicator",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 3, 0.55, 0),
            BackgroundColor3 = self.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = tabButton,
        })
        corner(tabIndicator, 2)

        local tabIcon = nil
        if hasTabIcon then
            tabIcon = createIcon(tabButton, tabIconAsset, 20, self.Theme.Muted, 0)
            tabIcon.AnchorPoint = Vector2.new(0, 0.5)
            tabIcon.Position = UDim2.new(0, 14, 0.5, 0)
        end

        local textWrap = make("Frame", {
            Name = "TextWrap",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, hasTabIcon and 44 or 14, 0.5, 0),
            Size = UDim2.new(1, -(hasTabIcon and 50 or 18), 1, -8),
            BackgroundTransparency = 1,
            Parent = tabButton,
        })
        local tLayout = list(textWrap, 2)
        tLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local titleLabel = make("TextLabel", {
            Name = "Title",
            Text = name,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = self.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Parent = textWrap,
        })

        local descLabel = make("TextLabel", {
            Name = "Desc",
            Text = subDesc,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(110, 125, 150),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 15),
            Parent = textWrap,
        })

        local page = make("ScrollingFrame", {
            Name = "Page_" .. name,
            Size = UDim2.new(1, -4, 1, -6),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = self.Theme.Accent,
            ScrollBarImageTransparency = 0.25,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ElasticBehavior = Enum.ElasticBehavior.Always,
            Visible = false,
            Active = true,
            Parent = pages,
        })
        padding(page, 6, 4, 12, 24)
        list(page, 10)

        local pageApi = createPageApi(self, page)
        pageApi.Name = name

        self.Tabs[name] = {
            Button      = tabButton,
            Indicator   = tabIndicator,
            TitleLabel  = titleLabel,
            DescLabel   = descLabel,
            Icon        = tabIcon,
            Page        = page,
            Api         = pageApi,
        }

        tabButton.MouseEnter:Connect(function()
            if self.SelectedTab ~= name then
                tween(tabButton, 0.16, {
                    BackgroundColor3 = self.Theme.SurfaceHover,
                    BackgroundTransparency = 0.55,
                })
                if tabIcon then
                    tween(tabIcon, 0.16, { ImageColor3 = self.Theme.Text })
                end
                tween(titleLabel, 0.16, { TextColor3 = self.Theme.Text })
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if self.SelectedTab ~= name then
                tween(tabButton, 0.16, {
                    BackgroundColor3 = self.Theme.Sidebar,
                    BackgroundTransparency = 1,
                })
                if tabIcon then
                    tween(tabIcon, 0.16, { ImageColor3 = self.Theme.Muted })
                end
                tween(titleLabel, 0.16, { TextColor3 = self.Theme.Muted })
            end
        end)

        tabButton.MouseButton1Click:Connect(function()
            self:SelectTab(name)
        end)

        if not self.SelectedTab then
            self:SelectTab(name)
        end

        return pageApi
    end

    -- Frosted Glass Notification Toast
    function self:Notify(toastProps: { [string]: any })
        toastProps = toastProps or {}
        local duration = tonumber(toastProps.Duration) or 3
        local toast = make("Frame", {
            Name = "Toast",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16),
            Size = UDim2.fromOffset(300, 72),
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 50,
            Parent = root,
        })
        corner(toast, 10)
        stroke(toast, self.Theme.StrokeSoft, 1, 0.6)
        padding(toast, 14, 10, 14, 10)

        local accentLine = make("Frame", {
            Name = "AccentLine",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -10, 0.5, 0),
            Size = UDim2.new(0, 3, 0.65, 0),
            BackgroundColor3 = toastProps.Color or self.Theme.Accent,
            BorderSizePixel = 0,
            Parent = toast,
        })
        corner(accentLine, 2)

        local toastContent = make("Frame", {
            Name = "ToastContent",
            Size = UDim2.new(1, 0, 1, -6),
            BackgroundTransparency = 1,
            Parent = toast,
        })
        list(toastContent, 3)

        createText(toastContent, "ToastTitle", tostring(toastProps.Title or "Notification"), 15, toastProps.Color or self.Theme.Text, true, 1)
        createText(toastContent, "ToastDesc", tostring(toastProps.Desc or toastProps.Message or ""), 13, self.Theme.Muted, false, 2)

        local progBar = make("Frame", {
            Name = "ProgressBar",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, -14, 1, 10),
            Size = UDim2.new(1, 28, 0, 2),
            BackgroundColor3 = toastProps.Color or self.Theme.Accent,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Parent = toast,
        })
        tween(progBar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

        toast.BackgroundTransparency = 1
        toast.Position = UDim2.new(1, 340, 1, -16)
        tween(toast, 0.25, {
            BackgroundTransparency = 0.18,
            Position = UDim2.new(1, -16, 1, -16),
        }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        task.delay(duration, function()
            if toast.Parent then
                tween(toast, 0.2, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, 340, 1, -16),
                }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                task.wait(0.22)
                if toast then toast:Destroy() end
            end
        end)
        return toast
    end

    -- Modern Frosted Glass Modal Dialog / Confirmation Prompt
    function self:Dialog(props: { [string]: any })
        props = props or {}
        local title = tostring(props.Title or "Confirm Action")
        local content = tostring(props.Content or props.Desc or props.Text or "Are you sure you want to proceed?")
        local confirmText = tostring(props.ConfirmText or props.Confirm or "Confirm")
        local cancelText = tostring(props.CancelText or props.Cancel or "Cancel")
        local onConfirm = props.OnConfirm or function() end
        local onCancel = props.OnCancel or function() end
        local isDanger = props.Danger == true

        local overlay = make("TextButton", {
            Name = "DialogOverlay",
            Text = "",
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 400,
            Active = true,
            Parent = root,
        })

        local cardWidth = math.min(380, math.max(root.AbsoluteSize.X - 32, 280))
        local card = make("Frame", {
            Name = "DialogCard",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(cardWidth, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            ZIndex = 401,
            ClipsDescendants = true,
            Parent = overlay,
        })
        corner(card, 14)
        stroke(card, isDanger and self.Theme.Danger or self.Theme.Stroke, 1.5, 0.4)
        padding(card, 20, 18, 20, 18)
        list(card, 14)

        local headerWrap = make("Frame", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            ZIndex = 402,
            Parent = card,
        })
        local hList = list(headerWrap, 8, Enum.FillDirection.Horizontal)
        hList.VerticalAlignment = Enum.VerticalAlignment.Center

        local accentBar = make("Frame", {
            Name = "Bar",
            Size = UDim2.fromOffset(4, 18),
            BackgroundColor3 = isDanger and self.Theme.Danger or self.Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 402,
            Parent = headerWrap,
        })
        corner(accentBar, 2)

        make("TextLabel", {
            Name = "Title",
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = isDanger and self.Theme.Danger or self.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, 0),
            ZIndex = 402,
            Parent = headerWrap,
        })

        make("TextLabel", {
            Name = "Content",
            Text = content,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = self.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 402,
            Parent = card,
        })

        local actionsRow = make("Frame", {
            Name = "ActionsRow",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            ZIndex = 402,
            Parent = card,
        })
        local aList = list(actionsRow, 10, Enum.FillDirection.Horizontal)
        aList.HorizontalAlignment = Enum.HorizontalAlignment.Right

        local cancelBtn = make("TextButton", {
            Name = "CancelBtn",
            Text = cancelText,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = self.Theme.Muted,
            AutoButtonColor = false,
            BackgroundColor3 = self.Theme.Sidebar,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(100, 34),
            ZIndex = 403,
            Parent = actionsRow,
        })
        corner(cancelBtn, 8)
        stroke(cancelBtn, self.Theme.StrokeSoft, 1, 0.75)
        addRipple(cancelBtn, self.Theme.Text)

        local confirmBtn = make("TextButton", {
            Name = "ConfirmBtn",
            Text = confirmText,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            AutoButtonColor = false,
            BackgroundColor3 = isDanger and self.Theme.Danger or self.Theme.Accent,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(110, 34),
            ZIndex = 403,
            Parent = actionsRow,
        })
        corner(confirmBtn, 8)
        addRipple(confirmBtn, Color3.fromRGB(255, 255, 255))

        local closed = false
        local function dismiss(confirmed: boolean)
            if closed then return end
            closed = true
            tween(card, 0.18, { Position = UDim2.fromScale(0.5, 0.52), BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tween(overlay, 0.18, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.2, function()
                if overlay and overlay.Parent then overlay:Destroy() end
            end)
            if confirmed then
                task.spawn(onConfirm)
            else
                task.spawn(onCancel)
            end
        end

        confirmBtn.MouseButton1Click:Connect(function() dismiss(true) end)
        cancelBtn.MouseButton1Click:Connect(function() dismiss(false) end)

        card.Position = UDim2.fromScale(0.5, 0.48)
        tween(overlay, 0.22, { BackgroundTransparency = 0.55 }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(card, 0.22, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        local item = {}
        function item:Close() dismiss(false) end
        return item
    end
    self.Prompt = self.Dialog

    function self:SetVisible(val: boolean)
        if val then
            animateOpen()
        else
            animateClose(false)
        end
    end

    function self:Destroy()
        isAlive = false
        stopAnimation()
        pcall(function()
            screenGui:Destroy()
        end)
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        elevateThread()
        if processed then return end
        if input.KeyCode == self.Keybind then
            toggleVisibility()
        end
    end)

    clampWindowPosition(shadow, uiScale)

    -- Smooth entrance animation on startup
    task.spawn(function()
        animateOpen()
        task.wait(0.05)
        if tabContainer and tabContainer.Parent then
            tabContainer.CanvasPosition = Vector2.new(0, 0)
        end
    end)

    return self
end

return Library
