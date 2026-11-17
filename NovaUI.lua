--[[
    NOVA UI
    Purple / dark editorial interface library
    Version: 1.0.0
    Place this ModuleScript in ReplicatedStorage as "NovaUI".

    Original Roblox Studio UI library inspired by the supplied visual reference:
    vivid violet header, near-black surfaces, thin outlines, bold typography,
    compact controls, and soft neon accents.
]]

local NovaUI = {}
NovaUI.__index = NovaUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULTS = {
    Name = "NOVA",
    Subtitle = "INTERFACE SYSTEM",
    Width = 760,
    Height = 500,
    ToggleKey = Enum.KeyCode.RightControl,
    Theme = {
        Accent = Color3.fromRGB(177, 83, 242),
        AccentDark = Color3.fromRGB(126, 48, 190),
        Background = Color3.fromRGB(17, 17, 20),
        Surface = Color3.fromRGB(27, 27, 31),
        Surface2 = Color3.fromRGB(36, 35, 41),
        Text = Color3.fromRGB(247, 243, 250),
        Muted = Color3.fromRGB(163, 156, 171),
        Border = Color3.fromRGB(7, 7, 9),
        Success = Color3.fromRGB(112, 220, 158),
        Danger = Color3.fromRGB(244, 105, 125),
    }
}

local function create(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local function label(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 20)
    }, parent)
end

local function buttonBase(parent, text, height, theme)
    local button = create("TextButton", {
        AutoButtonColor = false,
        Text = text or "",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        BackgroundColor3 = theme.Surface2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 38)
    }, parent)
    corner(button, 7)
    stroke(button, theme.Border, 1, 0.1)
    button.MouseEnter:Connect(function()
        tween(button, 0.13, {BackgroundColor3 = theme.AccentDark})
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.13, {BackgroundColor3 = theme.Surface2})
    end)
    return button
end

local function makeList(parent, gap)
    return create("UIListLayout", {
        Padding = UDim.new(0, gap or 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, parent)
end

local function normalizeTheme(source)
    local result = {}
    for key, value in pairs(DEFAULTS.Theme) do
        result[key] = value
    end
    if source then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

--============================================================
-- Window
--============================================================

function NovaUI:CreateWindow(options)
    options = options or {}
    local config = {}
    for key, value in pairs(DEFAULTS) do
        config[key] = value
    end
    for key, value in pairs(options) do
        config[key] = value
    end
    config.Theme = normalizeTheme(options.Theme)

    local self = setmetatable({}, NovaUI)
    self.Config = config
    self.Theme = config.Theme
    self.Tabs = {}
    self.ActiveTab = nil
    self.Visible = true
    self.Destroyed = false
    self._connections = {}

    local screen = create("ScreenGui", {
        Name = "NovaUI_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 50
    }, PlayerGui)
    self.Screen = screen

    local scale = create("UIScale", {Scale = 1}, screen)
    self.Scale = scale

    local root = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(config.Width, config.Height),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, screen)
    corner(root, 13)
    stroke(root, self.Theme.Border, 2, 0)
    self.Root = root

    -- Thin violet edge accent.
    local topLine = create("Frame", {
        BorderSizePixel = 0,
        BackgroundColor3 = self.Theme.Accent,
        Size = UDim2.new(1, 0, 0, 3),
        ZIndex = 5
    }, root)

    -- Header.
    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 64)
    }, root)
    self.Header = header

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 8),
        Size = UDim2.new(1, -150, 0, 27),
        Text = tostring(config.Name),
        TextColor3 = Color3.new(0.08, 0.04, 0.1),
        Font = Enum.Font.GothamBlack,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left
    }, header)
    self.TitleLabel = title

    local subtitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(21, 35),
        Size = UDim2.new(1, -150, 0, 17),
        Text = tostring(config.Subtitle),
        TextColor3 = Color3.fromRGB(48, 20, 59),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    }, header)

    local close = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = Color3.fromRGB(28, 18, 33),
        Text = "×",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        AutoButtonColor = false
    }, header)
    corner(close, 7)
    close.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    local minimize = create("TextButton", {
        Name = "Minimize",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -58, 0.5, 0),
        Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = Color3.fromRGB(28, 18, 33),
        Text = "—",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        AutoButtonColor = false
    }, header)
    corner(minimize, 7)
    minimize.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)

    -- Main body and navigation.
    local body = create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 64),
        Size = UDim2.new(1, 0, 1, -64)
    }, root)

    local nav = create("Frame", {
        Name = "Navigation",
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(0, 160, 1, -24)
    }, body)
    corner(nav, 9)
    self.Navigation = nav

    local navTitle = label(nav, "  MENU", 10, self.Theme.Muted, Enum.Font.GothamBold)
    navTitle.Size = UDim2.new(1, 0, 0, 28)
    navTitle.Position = UDim2.fromOffset(0, 3)

    local navList = create("ScrollingFrame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 34),
        Size = UDim2.new(1, -16, 1, -42),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent
    }, nav)
    makeList(navList, 6)
    padding(navList, 0, 2, 0, 4)
    self.TabList = navList

    local content = create("ScrollingFrame", {
        Name = "Content",
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(184, 12),
        Size = UDim2.new(1, -196, 1, -24),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent
    }, body)
    corner(content, 9)
    padding(content, 15, 15, 14, 16)
    makeList(content, 10)
    self.Content = content

    -- Dragging.
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    -- Keyboard toggle.
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == config.ToggleKey then
            self:SetVisible(not self.Visible)
        end
    end))

    -- Fit to screen.
    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local factor = math.min(1, (viewport.X - 24) / config.Width, (viewport.Y - 24) / config.Height)
        scale.Scale = math.max(0.55, factor)
    end
    updateScale()
    table.insert(self._connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale))
    if workspace.CurrentCamera then
        table.insert(self._connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end

    self.Body = body
    self:Notify({
        Title = config.Name,
        Content = "Interface initialized",
        Duration = 3
    })

    return self
end

function NovaUI:SetVisible(value)
    self.Visible = value
    if self.Root then
        self.Root.Visible = value
    end
end

function NovaUI:Toggle()
    self:SetVisible(not self.Visible)
end

function NovaUI:SetTitle(text)
    self.TitleLabel.Text = tostring(text)
end

function NovaUI:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        self.Theme[key] = value
    end
    if self.Root then
        self.Root.BackgroundColor3 = self.Theme.Background
        self.Header.BackgroundColor3 = self.Theme.Accent
        self.Navigation.BackgroundColor3 = self.Theme.Surface
        self.Content.BackgroundColor3 = self.Theme.Surface
        self.Content.ScrollBarImageColor3 = self.Theme.Accent
        self.TabList.ScrollBarImageColor3 = self.Theme.Accent
    end
end

function NovaUI:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, connection in ipairs(self._connections) do
        pcall(function() connection:Disconnect() end)
    end
    if self.Screen then
        self.Screen:Destroy()
    end
end

--============================================================
-- Notifications
--============================================================

function NovaUI:Notify(options)
    options = options or {}
    if not self.Screen then return end

    local holder = self.Screen:FindFirstChild("Notifications")
    if not holder then
        holder = create("Frame", {
            Name = "Notifications",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -18, 0, 18),
            Size = UDim2.fromOffset(300, 400)
        }, self.Screen)
        makeList(holder, 9)
    end

    local card = create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 76),
        ClipsDescendants = true
    }, holder)
    corner(card, 9)
    stroke(card, self.Theme.Accent, 1, 0.25)

    create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0)
    }, card)

    local heading = label(card, tostring(options.Title or "Notification"), 14, self.Theme.Text, Enum.Font.GothamBold)
    heading.Position = UDim2.fromOffset(15, 8)
    heading.Size = UDim2.new(1, -25, 0, 22)

    local message = label(card, tostring(options.Content or ""), 12, self.Theme.Muted)
    message.Position = UDim2.fromOffset(15, 32)
    message.Size = UDim2.new(1, -25, 0, 34)

    card.Position = UDim2.new(1, 20, 0, 0)
    tween(card, 0.25, {Position = UDim2.new(0, 0, 0, 0)})

    task.delay(tonumber(options.Duration) or 4, function()
        if card and card.Parent then
            tween(card, 0.2, {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 20, 0, 0)
            })
            task.wait(0.22)
            if card then card:Destroy() end
        end
    end)
end

--============================================================
-- Tabs and Sections
--============================================================

function NovaUI:CreateTab(options)
    options = options or {}
    local tab = {
        Name = tostring(options.Name or "Tab"),
        Icon = tostring(options.Icon or "•"),
        Window = self,
        Elements = {}
    }

    local tabButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Surface2,
        Text = tab.Icon .. "   " .. tab.Name,
        TextColor3 = self.Theme.Muted,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 38)
    }, self.TabList)
    corner(tabButton, 7)
    padding(tabButton, 10, 5, 0, 0)

    local page = create("Frame", {
        Name = tab.Name .. "Page",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false
    }, self.Content)
    makeList(page, 10)
    tab.Page = page
    tab.Button = tabButton

    function tab:Show()
        for _, other in ipairs(self.Window.Tabs) do
            other.Page.Visible = false
            tween(other.Button, 0.12, {
                BackgroundColor3 = self.Window.Theme.Surface2,
                TextColor3 = self.Window.Theme.Muted
            })
        end
        page.Visible = true
        tween(tabButton, 0.12, {
            BackgroundColor3 = self.Window.Theme.Accent,
            TextColor3 = Color3.new(1, 1, 1)
        })
        self.Window.ActiveTab = self
        self.Window.Content.CanvasPosition = Vector2.new(0, 0)
    end

    tabButton.MouseButton1Click:Connect(function()
        tab:Show()
    end)

    function tab:CreateSection(name)
        local section = {
            Tab = self,
            Name = tostring(name or "Section")
        }

        local wrap = create("Frame", {
            BackgroundColor3 = self.Window.Theme.Background,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        }, page)
        corner(wrap, 8)
        stroke(wrap, self.Window.Theme.Border, 1, 0.15)
        padding(wrap, 12, 12, 10, 12)
        makeList(wrap, 8)

        local heading = label(wrap, section.Name:upper(), 11, self.Window.Theme.Accent, Enum.Font.GothamBlack)
        heading.Size = UDim2.new(1, 0, 0, 22)

        local function makeRow(height)
            local row = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, height or 38)
            }, wrap)
            return row
        end

        function section:CreateLabel(text)
            local row = makeRow(25)
            local textLabel = label(row, tostring(text), 12, self.Tab.Window.Theme.Muted)
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            return {Instance = textLabel, Set = function(_, value) textLabel.Text = tostring(value) end}
        end

        function section:CreateParagraph(options)
            options = options or {}
            local row = makeRow(0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            local stack = create("Frame", {
                BackgroundColor3 = self.Tab.Window.Theme.Surface,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            }, row)
            corner(stack, 6)
            padding(stack, 10, 10, 8, 8)
            makeList(stack, 3)
            local titleLabel = label(stack, tostring(options.Title or "Information"), 13, self.Tab.Window.Theme.Text, Enum.Font.GothamBold)
            local bodyLabel = label(stack, tostring(options.Content or ""), 11, self.Tab.Window.Theme.Muted)
            bodyLabel.Size = UDim2.new(1, 0, 0, 0)
            return {
                Instance = stack,
                Set = function(_, text) bodyLabel.Text = tostring(text) end
            }
        end

        function section:CreateButton(options)
            options = options or {}
            local btn = buttonBase(wrap, tostring(options.Name or "Button"), 38, self.Tab.Window.Theme)
            btn.MouseButton1Click:Connect(function()
                if options.Callback then
                    task.spawn(options.Callback)
                end
            end)
            return {Instance = btn, SetText = function(_, text) btn.Text = tostring(text) end}
        end

        function section:CreateToggle(options)
            options = options or {}
            local value = options.CurrentValue == true
            local row = makeRow(40)
            local textLabel = label(row, tostring(options.Name or "Toggle"), 12, self.Tab.Window.Theme.Text, Enum.Font.GothamMedium)
            textLabel.Size = UDim2.new(1, -75, 1, 0)

            local track = create("TextButton", {
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(48, 25),
                BackgroundColor3 = value and self.Tab.Window.Theme.Accent or self.Tab.Window.Theme.Surface2,
                Text = ""
            }, row)
            corner(track, 13)

            local knob = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(19, 19),
                BackgroundColor3 = Color3.new(1, 1, 1)
            }, track)
            corner(knob, 10)

            local function set(newValue, call)
                value = newValue == true
                tween(track, 0.15, {
                    BackgroundColor3 = value and self.Tab.Window.Theme.Accent or self.Tab.Window.Theme.Surface2
                })
                tween(knob, 0.15, {
                    Position = value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                })
                if call and options.Callback then
                    task.spawn(options.Callback, value)
                end
            end
            track.MouseButton1Click:Connect(function() set(not value, true) end)
            return {
                Instance = row,
                Set = function(_, newValue) set(newValue, true) end,
                Get = function() return value end
            }
        end

        function section:CreateSlider(options)
            options = options or {}
            local min = tonumber(options.Range and options.Range[1]) or 0
            local max = tonumber(options.Range and options.Range[2]) or 100
            local increment = tonumber(options.Increment) or 1
            local value = math.clamp(tonumber(options.CurrentValue) or min, min, max)

            local row = makeRow(56)
            local titleLabel = label(row, tostring(options.Name or "Slider"), 12, self.Tab.Window.Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Size = UDim2.new(1, -65, 0, 22)

            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.fromOffset(60, 22),
                Text = tostring(value),
                TextColor3 = self.Tab.Window.Theme.Accent,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right
            }, row)

            local bar = create("Frame", {
                Position = UDim2.fromOffset(0, 32),
                Size = UDim2.new(1, 0, 0, 7),
                BackgroundColor3 = self.Tab.Window.Theme.Surface2,
                BorderSizePixel = 0
            }, row)
            corner(bar, 5)

            local fill = create("Frame", {
                Size = UDim2.new((value - min) / math.max(1, max - min), 0, 1, 0),
                BackgroundColor3 = self.Tab.Window.Theme.Accent,
                BorderSizePixel = 0
            }, bar)
            corner(fill, 5)

            local hitbox = create("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Position = UDim2.fromOffset(0, 22),
                Size = UDim2.new(1, 0, 0, 27)
            }, row)

            local function setFromX(x, call)
                local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local raw = min + (max - min) * alpha
                value = math.clamp(math.floor(raw / increment + 0.5) * increment, min, max)
                local percent = (value - min) / math.max(1, max - min)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                valueLabel.Text = tostring(value)
                if call and options.Callback then task.spawn(options.Callback, value) end
            end

            local active = false
            hitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    active = true
                    setFromX(input.Position.X, true)
                end
            end)
            hitbox.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    active = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X, true)
                end
            end)

            return {
                Instance = row,
                Get = function() return value end,
                Set = function(_, newValue)
                    value = math.clamp(tonumber(newValue) or min, min, max)
                    local p = (value - min) / math.max(1, max - min)
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    valueLabel.Text = tostring(value)
                    if options.Callback then task.spawn(options.Callback, value) end
                end
            }
        end

        function section:CreateDropdown(options)
            options = options or {}
            local values = options.Options or {}
            local selected = options.CurrentOption or values[1] or "None"
            local row = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 42)
            }, wrap)

            local titleLabel = label(row, tostring(options.Name or "Dropdown"), 12, self.Tab.Window.Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Size = UDim2.new(0.42, 0, 1, 0)

            local selector = create("TextButton", {
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.55, 0, 0, 34),
                BackgroundColor3 = self.Tab.Window.Theme.Surface2,
                Text = tostring(selected) .. "  ▾",
                TextColor3 = self.Tab.Window.Theme.Text,
                TextSize = 11,
                Font = Enum.Font.GothamSemibold
            }, row)
            corner(selector, 6)

            local open = false
            local popup
            local function closePopup()
                open = false
                if popup then popup:Destroy(); popup = nil end
            end
            selector.MouseButton1Click:Connect(function()
                if open then closePopup(); return end
                open = true
                popup = create("Frame", {
                    BackgroundColor3 = self.Tab.Window.Theme.Surface,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, 4),
                    Size = UDim2.new(1, 0, 0, math.min(#values * 30 + 8, 150)),
                    ZIndex = 20
                }, row)
                corner(popup, 6)
                stroke(popup, self.Tab.Window.Theme.Accent, 1, 0.3)
                local list = create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(4, 4),
                    Size = UDim2.new(1, -8, 1, -8),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 3,
                    ZIndex = 21
                }, popup)
                makeList(list, 2)
                for _, option in ipairs(values) do
                    local choice = create("TextButton", {
                        BackgroundColor3 = self.Tab.Window.Theme.Surface2,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 28),
                        Text = tostring(option),
                        TextColor3 = self.Tab.Window.Theme.Text,
                        TextSize = 11,
                        Font = Enum.Font.Gotham,
                        ZIndex = 22
                    }, list)
                    corner(choice, 4)
                    choice.MouseButton1Click:Connect(function()
                        selected = option
                        selector.Text = tostring(selected) .. "  ▾"
                        closePopup()
                        if options.Callback then task.spawn(options.Callback, selected) end
                    end)
                end
            end)

            return {
                Instance = row,
                Get = function() return selected end,
                Set = function(_, value)
                    selected = value
                    selector.Text = tostring(value) .. "  ▾"
                    if options.Callback then task.spawn(options.Callback, value) end
                end,
                Refresh = function(_, newOptions)
                    values = newOptions or {}
                    if not table.find(values, selected) then
                        selected = values[1] or "None"
                        selector.Text = tostring(selected) .. "  ▾"
                    end
                    closePopup()
                end
            }
        end

        function section:CreateInput(options)
            options = options or {}
            local row = makeRow(62)
            local titleLabel = label(row, tostring(options.Name or "Input"), 12, self.Tab.Window.Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Size = UDim2.new(1, 0, 0, 21)

            local box = create("TextBox", {
                ClearTextOnFocus = false,
                Position = UDim2.fromOffset(0, 25),
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = self.Tab.Window.Theme.Surface2,
                BorderSizePixel = 0,
                Text = tostring(options.Default or ""),
                PlaceholderText = tostring(options.Placeholder or "Enter text..."),
                PlaceholderColor3 = self.Tab.Window.Theme.Muted,
                TextColor3 = self.Tab.Window.Theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            }, row)
            corner(box, 6)
            padding(box, 9, 9, 0, 0)
            box.FocusLost:Connect(function(enterPressed)
                if options.Callback then task.spawn(options.Callback, box.Text, enterPressed) end
            end)
            return {
                Instance = box,
                Get = function() return box.Text end,
                Set = function(_, value) box.Text = tostring(value) end
            }
        end

        function section:CreateKeybind(options)
            options = options or {}
            local key = options.CurrentKeybind or Enum.KeyCode.Unknown
            local row = makeRow(38)
            local titleLabel = label(row, tostring(options.Name or "Keybind"), 12, self.Tab.Window.Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Size = UDim2.new(1, -110, 1, 0)

            local bindButton = buttonBase(row, key.Name, 38, self.Tab.Window.Theme)
            bindButton.AnchorPoint = Vector2.new(1, 0)
            bindButton.Position = UDim2.new(1, 0, 0, 0)
            bindButton.Size = UDim2.fromOffset(100, 34)

            local listening = false
            bindButton.MouseButton1Click:Connect(function()
                listening = true
                bindButton.Text = "Press key..."
            end)

            local connection = UserInputService.InputBegan:Connect(function(input, processed)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    listening = false
                    bindButton.Text = key.Name
                    if options.Callback then task.spawn(options.Callback, key) end
                elseif not processed and input.KeyCode == key and options.OnPressed then
                    task.spawn(options.OnPressed)
                end
            end)

            return {
                Instance = row,
                Get = function() return key end,
                Set = function(_, newKey) key = newKey; bindButton.Text = key.Name end,
                Destroy = function() connection:Disconnect() end
            }
        end

        function section:CreateColorPicker(options)
            options = options or {}
            local colors = options.Colors or {
                Color3.fromRGB(177, 83, 242),
                Color3.fromRGB(80, 160, 255),
                Color3.fromRGB(90, 210, 160),
                Color3.fromRGB(255, 110, 130),
                Color3.fromRGB(255, 190, 80),
                Color3.fromRGB(245, 245, 245)
            }
            local selected = options.Color or colors[1]
            local row = makeRow(42)
            local titleLabel = label(row, tostring(options.Name or "Accent color"), 12, self.Tab.Window.Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Size = UDim2.new(1, -180, 1, 0)

            local palette = create("Frame", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(math.min(#colors * 27, 162), 28)
            }, row)
            local layout = create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 4)
            }, palette)

            for _, color in ipairs(colors) do
                local swatch = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = color,
                    Text = "",
                    Size = UDim2.fromOffset(23, 23)
                }, palette)
                corner(swatch, 6)
                stroke(swatch, Color3.new(1, 1, 1), 1, 0.65)
                swatch.MouseButton1Click:Connect(function()
                    selected = color
                    if options.Callback then task.spawn(options.Callback, color) end
                end)
            end
            return {
                Instance = row,
                Get = function() return selected end,
                Set = function(_, color)
                    selected = color
                    if options.Callback then task.spawn(options.Callback, color) end
                end
            }
        end

        return section
    end

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        tab:Show()
    end
    return tab
end

return NovaUI
