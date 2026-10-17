--[[
	NOCTURNE UI LIBRARY  v1.0
	Тёмная библиотека интерфейсов для HUD-ов и панелей.

	Загрузка:
		local Library = loadstring(readfile("Nocturne.lua"))()
		-- или: loadstring(game:HttpGet("ССЫЛКА_НА_RAW"))()
		-- или как ModuleScript: local Library = require(script.Parent.Nocturne)

	Быстрый старт:
		local Window = Library:CreateWindow({ Title = "Nocturne", SubTitle = "v1.0" })
		local Tab = Window:CreateTab("Main", "🏠")
		Tab:CreateToggle({ Name = "Enabled", Callback = function(v) print(v) end })

	Полный пример - в файле Example.lua

	Новое в 1.1:
		Tab:CreateColorPicker({ Name, Default, Flag, Callback })   -- палитра из 16 цветов
		Window:CreateConfigTab()                                    -- готовая вкладка конфигов
		Library:SaveConfig(n) / LoadConfig(n) / DeleteConfig(n) / ListConfigs()
		Window:CreatePlayersTab({ Actions = {...} })                -- drag & drop функций на игроков
		Library:SetCursor(id)                                       -- курсор над окном
		Flag = "имя" у любого элемента - включает его в конфиг
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local Library = {
	Version = "1.1.0",
	Gui = nil,
	Flags = {},
	Cursor = "rbxassetid://76753338419764",
	ConfigFolder = "Nocturne/configs",
	_windows = {},
	Theme = {
		Background = Color3.fromRGB(11, 11, 15),
		Surface = Color3.fromRGB(17, 17, 23),
		Element = Color3.fromRGB(24, 24, 32),
		ElementHover = Color3.fromRGB(33, 33, 44),
		Stroke = Color3.fromRGB(44, 44, 58),
		Text = Color3.fromRGB(236, 236, 245),
		Muted = Color3.fromRGB(125, 125, 150),
		Accent = Color3.fromRGB(139, 92, 255),
		Success = Color3.fromRGB(80, 220, 140),
		Warning = Color3.fromRGB(255, 200, 87),
		Error = Color3.fromRGB(255, 90, 110),
	},
	_connections = {},
}

local GUI_NAME = "NocturneUI"

local F = {
	bold = Enum.Font.GothamBold,
	med = Enum.Font.GothamMedium,
	reg = Enum.Font.Gotham,
}

local CENTER = Enum.TextXAlignment.Center
local RIGHT = Enum.TextXAlignment.Right

---------------------------------------------------------------------
-- ВНУТРЕННИЕ ХЕЛПЕРЫ
---------------------------------------------------------------------
local function create(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function round(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function text(parent, str, size, font, color, props)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Text = str,
		TextSize = size,
		Font = font,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, size + 4),
	}, nil)
	if props then
		for k, v in pairs(props) do
			label[k] = v
		end
	end
	label.Parent = parent
	return label
end

local function tween(obj, time, props, style, dir)
	TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	):Play()
end

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Library._connections, c)
	return c
end

-- безопасный вызов пользовательских callback-ов
local function fire(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then
			warn("[Nocturne] callback error: " .. tostring(err))
		end
	end)
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local LocalPlayer = Players.LocalPlayer

-- находится ли точка (Vector2) внутри GuiObject
local function inside(obj, p)
	local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
	return p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
end

local function makeDraggable(handle, target, uiScale)
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local delta = (input.Position - dragStart) / uiScale.Scale
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- куда монтировать GUI: gethui -> CoreGui -> PlayerGui
local function mount(gui)
	local getters = {
		function() return gethui() end,
		function() return game:GetService("CoreGui") end,
		function() return Players.LocalPlayer:WaitForChild("PlayerGui") end,
	}
	for _, get in ipairs(getters) do
		local ok, parent = pcall(get)
		if ok and parent then
			pcall(function()
				local old = parent:FindFirstChild(GUI_NAME)
				if old then
					old:Destroy()
				end
			end)
			local set = pcall(function()
				gui.Parent = parent
			end)
			if set and gui.Parent == parent then
				return true
			end
		end
	end
	return false
end

local function getGui()
	if Library.Gui and Library.Gui.Parent then
		return Library.Gui
	end

	local gui = create("ScreenGui", {
		Name = GUI_NAME,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, nil)
	mount(gui)
	Library.Gui = gui

	-- контейнер уведомлений
	local holder = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32),
		BackgroundTransparency = 1,
	}, gui)
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, holder)

	return gui
end

---------------------------------------------------------------------
-- ТЕМА
---------------------------------------------------------------------
-- вызывай ДО CreateWindow: Library:SetTheme({ Accent = Color3.fromRGB(...) })
function Library:SetTheme(tbl)
	for k, v in pairs(tbl) do
		self.Theme[k] = v
	end
end

---------------------------------------------------------------------
-- ПАЛИТРА ДЛЯ COLORPICKER (16 цветов)
---------------------------------------------------------------------
Library.Palette = {
	Color3.fromRGB(255, 77, 77),   -- red
	Color3.fromRGB(255, 140, 66),  -- orange
	Color3.fromRGB(255, 200, 87),  -- amber
	Color3.fromRGB(250, 230, 90),  -- yellow
	Color3.fromRGB(170, 230, 80),  -- lime
	Color3.fromRGB(80, 220, 140),  -- green
	Color3.fromRGB(92, 255, 196),  -- mint
	Color3.fromRGB(40, 200, 190),  -- teal
	Color3.fromRGB(79, 216, 255),  -- cyan
	Color3.fromRGB(90, 160, 255),  -- sky
	Color3.fromRGB(66, 110, 255),  -- blue
	Color3.fromRGB(139, 92, 255),  -- violet
	Color3.fromRGB(190, 90, 255),  -- purple
	Color3.fromRGB(240, 80, 220),  -- magenta
	Color3.fromRGB(255, 95, 162),  -- pink
	Color3.fromRGB(245, 245, 250), -- white
}

---------------------------------------------------------------------
-- КУРСОР: меняется, пока мышь над окном библиотеки
---------------------------------------------------------------------
local cursorState = { active = false, previous = "" }

local function restoreCursor()
	if cursorState.active then
		cursorState.active = false
		pcall(function()
			UserInputService.MouseIcon = cursorState.previous or ""
		end)
	end
end

local function startCursor()
	if Library._cursorStarted then
		return
	end
	Library._cursorStarted = true

	connect(RunService.RenderStepped, function()
		local want = false
		if Library.Cursor then
			local m = UserInputService:GetMouseLocation()
			for _, w in ipairs(Library._windows) do
				local r = w.Root
				if r.Parent and r.Visible and inside(r, m) then
					want = true
					break
				end
			end
		end

		if want then
			if not cursorState.active then
				cursorState.active = true
				cursorState.previous = UserInputService.MouseIcon
			end
			if UserInputService.MouseIcon ~= Library.Cursor then
				UserInputService.MouseIcon = Library.Cursor
			end
		else
			restoreCursor()
		end
	end)
end

-- Library:SetCursor(76753338419764) / Library:SetCursor("rbxassetid://...") / Library:SetCursor(nil) - выключить
function Library:SetCursor(id)
	if type(id) == "number" then
		id = "rbxassetid://" .. id
	end
	self.Cursor = id
end

---------------------------------------------------------------------
-- КОНФИГИ
-- Любой элемент с параметром Flag = "имя" попадает в конфиг.
-- Файлы: <workspace>/Nocturne/configs/<имя>.json (если есть writefile/readfile),
-- иначе конфиги живут в памяти до выхода из игры.
---------------------------------------------------------------------
local memoryConfigs = {}

local function hasFs()
	return type(writefile) == "function" and type(readfile) == "function"
end

local function ensureFolder()
	if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		return
	end
	pcall(function()
		local path = ""
		for part in string.gmatch(Library.ConfigFolder, "[^/]+") do
			path = (path == "") and part or (path .. "/" .. part)
			if not isfolder(path) then
				makefolder(path)
			end
		end
	end)
end

local function cleanName(name)
	local s = tostring(name or "")
	s = s:gsub("[^%w%-_ ]", "")
	s = s:gsub("^%s+", "")
	s = s:gsub("%s+$", "")
	return s
end

local function serialize(v)
	local t = typeof(v)
	if t == "Color3" then
		return {
			__t = "Color3",
			r = math.floor(v.R * 255 + 0.5),
			g = math.floor(v.G * 255 + 0.5),
			b = math.floor(v.B * 255 + 0.5),
		}
	elseif t == "EnumItem" then
		return { __t = "Enum", name = tostring(v) }
	elseif t == "nil" then
		return { __t = "nil" }
	end
	return v
end

local function deserialize(v)
	if type(v) == "table" then
		if v.__t == "Color3" then
			return Color3.fromRGB(v.r, v.g, v.b)
		elseif v.__t == "Enum" then
			local parts = string.split(v.name, ".")
			local ok, item = pcall(function()
				return Enum[parts[2]][parts[3]]
			end)
			return ok and item or nil
		end
		return nil
	end
	return v
end

local function configPath(name)
	return Library.ConfigFolder .. "/" .. name .. ".json"
end

function Library:GetConfigData()
	local data = {}
	for flag, api in pairs(self.Flags) do
		local ok, value = pcall(function()
			return api:Get()
		end)
		if ok then
			data[flag] = serialize(value)
		end
	end
	return data
end

function Library:ApplyConfigData(data)
	for flag, raw in pairs(data) do
		local api = self.Flags[flag]
		if api then
			pcall(function()
				api:Set(deserialize(raw))
			end)
		end
	end
end

-- возвращает: ok (bool), имя или текст ошибки
function Library:SaveConfig(name)
	name = cleanName(name)
	if name == "" then
		return false, "Enter a config name"
	end
	local ok, json = pcall(function()
		return HttpService:JSONEncode(self:GetConfigData())
	end)
	if not ok then
		return false, "Could not encode config"
	end
	if hasFs() then
		ensureFolder()
		local wrote, err = pcall(writefile, configPath(name), json)
		if not wrote then
			return false, tostring(err)
		end
	else
		memoryConfigs[name] = json
	end
	return true, name
end

function Library:LoadConfig(name)
	name = cleanName(name)
	if name == "" then
		return false, "Enter a config name"
	end
	local json
	if hasFs() then
		local ok, res = pcall(readfile, configPath(name))
		if not ok then
			return false, "Config not found"
		end
		json = res
	else
		json = memoryConfigs[name]
		if not json then
			return false, "Config not found"
		end
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(data) ~= "table" then
		return false, "Config file is damaged"
	end
	self:ApplyConfigData(data)
	return true, name
end

function Library:DeleteConfig(name)
	name = cleanName(name)
	if name == "" then
		return false, "Enter a config name"
	end
	if hasFs() then
		if type(delfile) ~= "function" then
			return false, "delfile is not available"
		end
		local ok = pcall(delfile, configPath(name))
		if ok then
			return true, name
		end
		return false, "Config not found"
	end
	if memoryConfigs[name] then
		memoryConfigs[name] = nil
		return true, name
	end
	return false, "Config not found"
end

function Library:ListConfigs()
	local names = {}
	if hasFs() and type(listfiles) == "function" then
		ensureFolder()
		local ok, files = pcall(listfiles, self.ConfigFolder)
		if ok and type(files) == "table" then
			for _, path in ipairs(files) do
				local n = tostring(path):match("([^/\\]+)%.json$")
				if n then
					table.insert(names, n)
				end
			end
		end
	else
		for n in pairs(memoryConfigs) do
			table.insert(names, n)
		end
	end
	table.sort(names)
	return names
end

---------------------------------------------------------------------
-- УВЕДОМЛЕНИЯ
---------------------------------------------------------------------
local notifyCount = 0

--[[
	Library:Notify({
		Title = "Заголовок",
		Content = "Текст",
		Duration = 4,
		Type = "info" | "success" | "warning" | "error",
	})
]]
function Library:Notify(o)
	o = o or {}
	local T = self.Theme
	local gui = getGui()
	local holder = gui:FindFirstChild("Notifications")

	local colors = { success = T.Success, warning = T.Warning, error = T.Error }
	local color = colors[string.lower(o.Type or "")] or T.Accent
	local duration = o.Duration or 4

	notifyCount = notifyCount + 1
	local wrap = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = notifyCount,
	}, holder)

	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 40, 0, 0),
		BackgroundColor3 = T.Surface,
	}, wrap)
	round(card, 10)
	stroke(card, T.Stroke, 1)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 18),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, card)
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, card)

	text(card, string.format('<font color="#%s">●</font>  %s', color:ToHex(), o.Title or "Notification"), 14, F.bold, T.Text, {
		RichText = true,
		LayoutOrder = 1,
	})
	if o.Content then
		text(card, o.Content, 13, F.reg, T.Muted, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			LayoutOrder = 2,
		})
	end

	-- полоса времени
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -8),
		Size = UDim2.new(1, -28, 0, 3),
		BackgroundColor3 = color,
	}, card)
	round(bar, 2)

	tween(card, 0.4, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
	tween(bar, duration, { Size = UDim2.new(0, 0, 0, 3) }, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if card.Parent then
			tween(card, 0.3, { Position = UDim2.new(1, 40, 0, 0) })
			task.wait(0.3)
			wrap:Destroy()
		end
	end)
end

---------------------------------------------------------------------
-- WATERMARK (HUD-плашка с FPS и пингом)
---------------------------------------------------------------------
--[[
	local wm = Library:CreateWatermark({ Text = "Nocturne", Position = UDim2.fromOffset(16, 16) })
	wm:SetText("Новое имя")
	wm:SetVisible(false)
	wm:Destroy()
]]
function Library:CreateWatermark(o)
	o = o or {}
	local T = self.Theme
	local gui = getGui()
	local name = o.Text or "Nocturne"

	local frame = create("Frame", {
		Name = "Watermark",
		Position = o.Position or UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Surface,
	}, gui)
	round(frame, 8)
	stroke(frame, T.Stroke, 1)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, frame)

	local label = text(frame, "", 13, F.med, T.Text, {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		RichText = true,
	})

	local acc, frames = 0, 0
	local function render(fps, ping)
		label.Text = string.format(
			'<font color="#%s">●</font>  %s   <font color="#%s">|</font>   %d fps   <font color="#%s">|</font>   %d ms',
			T.Accent:ToHex(), name, T.Stroke:ToHex(), fps, T.Stroke:ToHex(), ping
		)
	end
	render(60, 0)

	local conn = connect(RunService.Heartbeat, function(dt)
		acc = acc + dt
		frames = frames + 1
		if acc >= 0.5 then
			local fps = math.floor(frames / acc + 0.5)
			local ping = 0
			pcall(function()
				ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
			end)
			render(fps, ping)
			acc, frames = 0, 0
		end
	end)

	local api = {}
	function api:SetText(str)
		name = str
	end
	function api:SetVisible(v)
		frame.Visible = v
	end
	function api:Destroy()
		conn:Disconnect()
		frame:Destroy()
	end
	return api
end

---------------------------------------------------------------------
-- ОКНО
---------------------------------------------------------------------
--[[
	Library:CreateWindow({
		Title = "Nocturne",
		SubTitle = "v1.0",
		Accent = Color3.fromRGB(139, 92, 255),   -- необязательно
		Size = Vector2.new(620, 420),             -- необязательно
		ToggleKey = Enum.KeyCode.RightShift,      -- скрыть/показать
	})
]]
function Library:CreateWindow(o)
	o = o or {}
	if o.Accent then
		self.Theme.Accent = o.Accent
	end
	local T = self.Theme
	local gui = getGui()
	local size = o.Size or Vector2.new(620, 420)

	local Window = {}

	local root = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
	}, gui)

	table.insert(self._windows, { Root = root })
	startCursor()

	local uiScale = create("UIScale", {}, root)
	local function fit()
		local v = workspace.CurrentCamera.ViewportSize
		return math.clamp(math.min(v.X / (size.X + 80), v.Y / (size.Y + 80)), 0.5, 1)
	end
	uiScale.Scale = fit() * 0.9
	tween(uiScale, 0.5, { Scale = fit() }, Enum.EasingStyle.Back)
	connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
		uiScale.Scale = fit()
	end)

	-- тень
	create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 90, 1, 90),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.3,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
	}, root)

	local window = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Background,
		ClipsDescendants = true,
	}, root)
	round(window, 12)
	stroke(window, T.Stroke, 1)

	-- верхняя панель
	local topbar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	}, window)

	local dot = create("Frame", {
		Position = UDim2.fromOffset(16, 15),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = T.Accent,
	}, topbar)
	round(dot, 4)

	local titleRow = create("Frame", {
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -140, 1, 0),
		BackgroundTransparency = 1,
	}, topbar)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, titleRow)
	text(titleRow, o.Title or "Nocturne", 15, F.bold, T.Text, {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
	})
	if o.SubTitle then
		text(titleRow, o.SubTitle, 12, F.med, T.Muted, {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			TextTruncate = Enum.TextTruncate.None,
		})
	end

	local function topButton(symbol, xOffset)
		local b = create("TextButton", {
			Position = UDim2.new(1, xOffset, 0.5, -14),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = T.Element,
			BackgroundTransparency = 1,
			Text = symbol,
			TextColor3 = T.Muted,
			Font = F.bold,
			TextSize = 14,
			AutoButtonColor = false,
		}, topbar)
		round(b, 8)
		b.MouseEnter:Connect(function()
			tween(b, 0.15, { BackgroundTransparency = 0, TextColor3 = T.Text })
		end)
		b.MouseLeave:Connect(function()
			tween(b, 0.15, { BackgroundTransparency = 1, TextColor3 = T.Muted })
		end)
		return b
	end
	local minBtn = topButton("–", -72)
	local closeBtn = topButton("✕", -40)

	-- разделитель с акцентным затуханием
	create("Frame", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.Stroke,
		BorderSizePixel = 0,
	}, window)
	local accentLine = create("Frame", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.fromOffset(240, 1),
		BackgroundColor3 = T.Accent,
		BorderSizePixel = 0,
	}, window)
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, accentLine)

	makeDraggable(topbar, root, uiScale)

	-- сайдбар
	local sidebar = create("Frame", {
		Position = UDim2.fromOffset(0, 45),
		Size = UDim2.new(0, 150, 1, -45),
		BackgroundTransparency = 1,
	}, window)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, sidebar)
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	create("Frame", {
		Position = UDim2.fromOffset(150, 45),
		Size = UDim2.new(0, 1, 1, -45),
		BackgroundColor3 = T.Stroke,
		BorderSizePixel = 0,
	}, window)

	local pages = create("Frame", {
		Position = UDim2.fromOffset(151, 45),
		Size = UDim2.new(1, -151, 1, -45),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, window)

	-- поведение окна
	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		tween(root, 0.35, { Size = UDim2.fromOffset(size.X, minimized and 44 or size.Y) })
	end)
	closeBtn.MouseButton1Click:Connect(function()
		root.Visible = false
	end)

	local toggleKey = o.ToggleKey or Enum.KeyCode.RightShift
	connect(UserInputService.InputBegan, function(input, processed)
		if not processed and input.KeyCode == toggleKey then
			root.Visible = not root.Visible
		end
	end)

	function Window:SetVisible(v)
		root.Visible = v
	end
	function Window:Toggle()
		root.Visible = not root.Visible
	end
	function Window:Notify(opts)
		Library:Notify(opts)
	end
	function Window:Destroy()
		root:Destroy()
	end

	---------------------------------------------------------------
	-- ВКЛАДКИ
	---------------------------------------------------------------
	local tabs = {}
	local activeTab

	local function selectTab(tab)
		activeTab = tab
		for _, t in ipairs(tabs) do
			local on = (t == tab)
			t.Page.Visible = on
			t._bar.Visible = on
			tween(t._btn, 0.2, { BackgroundTransparency = on and 0 or 1 })
			tween(t._label, 0.2, { TextColor3 = on and T.Text or T.Muted })
		end
	end

	function Window:CreateTab(name, icon)
		local Tab = {}

		local btn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = T.Element,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = #tabs + 1,
		}, sidebar)
		round(btn, 8)

		local bar = create("Frame", {
			Position = UDim2.new(0, 0, 0.5, -8),
			Size = UDim2.fromOffset(3, 16),
			BackgroundColor3 = T.Accent,
			Visible = false,
		}, btn)
		round(bar, 2)

		local textX = 14
		if icon then
			text(btn, icon, 16, F.bold, T.Text, {
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.fromOffset(22, 36),
				TextXAlignment = CENTER,
			})
			textX = 40
		end
		local label = text(btn, name, 14, F.med, T.Muted, {
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(1, -(textX + 6), 1, 0),
		})

		local page = create("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = T.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, pages)
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 14),
		}, page)
		create("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)

		Tab.Page = page
		Tab._btn = btn
		Tab._bar = bar
		Tab._label = label
		table.insert(tabs, Tab)

		btn.MouseEnter:Connect(function()
			if activeTab ~= Tab then
				tween(btn, 0.15, { BackgroundTransparency = 0.6 })
			end
		end)
		btn.MouseLeave:Connect(function()
			if activeTab ~= Tab then
				tween(btn, 0.15, { BackgroundTransparency = 1 })
			end
		end)
		btn.MouseButton1Click:Connect(function()
			selectTab(Tab)
		end)

		if not activeTab then
			selectTab(Tab)
		end

		-----------------------------------------------------------
		-- Общие хелперы вкладки
		-----------------------------------------------------------
		local order = 0
		local function nextOrder()
			order = order + 1
			return order
		end

		-- базовая карточка элемента
		local function card(height, clickable)
			local c = create(clickable and "TextButton" or "Frame", {
				Size = UDim2.new(1, 0, 0, height),
				BackgroundColor3 = T.Element,
				LayoutOrder = nextOrder(),
			}, page)
			if clickable then
				c.Text = ""
				c.AutoButtonColor = false
			end
			round(c, 8)
			stroke(c, T.Stroke, 1)
			return c
		end

		local function hoverable(obj)
			obj.MouseEnter:Connect(function()
				tween(obj, 0.15, { BackgroundColor3 = T.ElementHover })
			end)
			obj.MouseLeave:Connect(function()
				tween(obj, 0.15, { BackgroundColor3 = T.Element })
			end)
		end

		local function nameLabel(parent, str, widthScale)
			return text(parent, str, 14, F.med, T.Text, {
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(widthScale or 0.6, -14, 0, 38),
			})
		end

		-- элемент с Flag = "имя" попадает в конфиги
		local function reg(opts, api)
			if opts and opts.Flag then
				Library.Flags[opts.Flag] = api
			end
			return api
		end

		-----------------------------------------------------------
		-- Section
		-----------------------------------------------------------
		function Tab:CreateSection(str)
			local holder = create("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = nextOrder(),
			}, page)
			text(holder, str, 12, F.bold, T.Accent, {
				Position = UDim2.fromOffset(2, 4),
				Size = UDim2.new(1, -2, 0, 16),
			})
		end

		-----------------------------------------------------------
		-- Label
		-----------------------------------------------------------
		function Tab:CreateLabel(str)
			local l = text(page, str, 13, F.reg, T.Muted, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.None,
				LayoutOrder = nextOrder(),
			})
			local api = {}
			function api:SetText(s)
				l.Text = s
			end
			return api
		end

		-----------------------------------------------------------
		-- Button
		-----------------------------------------------------------
		--[[ Tab:CreateButton({ Name = "...", Callback = function() end }) ]]
		function Tab:CreateButton(opts)
			opts = opts or {}
			local b = card(38, true)
			hoverable(b)
			local lbl = nameLabel(b, opts.Name or "Button", 1)
			lbl.Size = UDim2.new(1, -50, 0, 38)
			text(b, "›", 22, F.bold, T.Muted, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, -2),
				Size = UDim2.fromOffset(20, 26),
				TextXAlignment = RIGHT,
			})
			b.MouseButton1Click:Connect(function()
				b.BackgroundColor3 = T.Accent
				tween(b, 0.4, { BackgroundColor3 = T.Element })
				fire(opts.Callback)
			end)

			local api = {}
			function api:SetText(s)
				lbl.Text = s
			end
			return api
		end

		-----------------------------------------------------------
		-- Toggle
		-----------------------------------------------------------
		--[[ Tab:CreateToggle({ Name, Default = false, Callback = function(state) end }) -> :Set(bool) :Get() ]]
		function Tab:CreateToggle(opts)
			opts = opts or {}
			local state = opts.Default == true
			local c = card(38, true)
			hoverable(c)
			nameLabel(c, opts.Name or "Toggle", 1).Size = UDim2.new(1, -70, 0, 38)

			local track = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(40, 22),
				BackgroundColor3 = state and T.Accent or T.Stroke,
			}, c)
			round(track, 11)
			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = T.Text,
			}, track)
			round(knob, 8)

			local api = {}
			function api:Set(v, silent)
				state = v and true or false
				tween(track, 0.2, { BackgroundColor3 = state and T.Accent or T.Stroke })
				tween(knob, 0.2, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
				if not silent then
					fire(opts.Callback, state)
				end
			end
			function api:Get()
				return state
			end
			c.MouseButton1Click:Connect(function()
				api:Set(not state)
			end)
			return reg(opts, api)
		end

		-----------------------------------------------------------
		-- Slider
		-----------------------------------------------------------
		--[[ Tab:CreateSlider({ Name, Min, Max, Default, Increment = 1, Suffix = "", Callback = function(value) end }) ]]
		function Tab:CreateSlider(opts)
			opts = opts or {}
			local min, max = opts.Min or 0, opts.Max or 100
			local inc = opts.Increment or 1
			local suffix = opts.Suffix or ""
			local decimals = #(tostring(inc):match("%.(%d+)") or "")

			local function snap(v)
				v = math.floor((v - min) / inc + 0.5) * inc + min
				v = math.clamp(v, min, max)
				return tonumber(string.format("%." .. decimals .. "f", v))
			end

			local value = snap(opts.Default or min)
			local c = card(54, false)
			text(c, opts.Name or "Slider", 14, F.med, T.Text, {
				Position = UDim2.fromOffset(14, 8),
				Size = UDim2.new(0.6, -14, 0, 18),
			})
			local valLabel = text(c, "", 13, F.bold, T.Accent, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 8),
				Size = UDim2.fromOffset(100, 18),
				TextXAlignment = RIGHT,
			})

			local track = create("Frame", {
				Position = UDim2.new(0, 14, 0, 37),
				Size = UDim2.new(1, -28, 0, 6),
				BackgroundColor3 = T.Stroke,
			}, c)
			round(track, 3)
			local fill = create("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = T.Accent,
			}, track)
			round(fill, 3)
			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = T.Text,
			}, fill)
			round(knob, 7)

			local function render()
				local ratio = (max > min) and (value - min) / (max - min) or 0
				fill.Size = UDim2.new(ratio, 0, 1, 0)
				valLabel.Text = tostring(value) .. suffix
			end
			render()

			local api = {}
			function api:Set(v, silent)
				local new = snap(v)
				if new ~= value then
					value = new
					render()
					if not silent then
						fire(opts.Callback, value)
					end
				end
			end
			function api:Get()
				return value
			end

			-- большая зона нажатия
			local hit = create("TextButton", {
				Position = UDim2.fromOffset(0, 26),
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Text = "",
			}, c)

			local dragging = false
			local function update(x)
				local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				api:Set(min + (max - min) * rel)
			end
			hit.InputBegan:Connect(function(input)
				if isPress(input) then
					dragging = true
					update(input.Position.X)
				end
			end)
			connect(UserInputService.InputChanged, function(input)
				if dragging and isMove(input) then
					update(input.Position.X)
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if isPress(input) then
					dragging = false
				end
			end)

			return reg(opts, api)
		end

		-----------------------------------------------------------
		-- Dropdown
		-----------------------------------------------------------
		--[[ Tab:CreateDropdown({ Name, Options = {"A","B"}, Default = "A", Callback = function(option) end })
		     -> :Set(opt) :Get() :Refresh(newOptions) ]]
		function Tab:CreateDropdown(opts)
			opts = opts or {}
			local options = opts.Options or {}
			local selected = opts.Default
			local open = false

			local c = card(38, false)
			c.ClipsDescendants = true

			local header = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
			}, c)
			nameLabel(header, opts.Name or "Dropdown", 0.5)
			local valueLabel = text(header, "", 13, F.med, T.Muted, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -36, 0, 0),
				Size = UDim2.new(0.5, -20, 0, 38),
				TextXAlignment = RIGHT,
			})
			local arrow = text(header, "▾", 14, F.bold, T.Muted, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				TextXAlignment = CENTER,
			})

			local list = create("Frame", {
				Position = UDim2.fromOffset(8, 42),
				Size = UDim2.new(1, -16, 0, 0),
				BackgroundTransparency = 1,
			}, c)
			create("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, list)

			local buttons = {}
			local function listHeight()
				local n = #options
				return n * 28 + math.max(n - 1, 0) * 4
			end
			local function openHeight()
				return 42 + listHeight() + 10
			end

			local api = {}

			local function colorize()
				valueLabel.Text = selected ~= nil and tostring(selected) or "Select..."
				valueLabel.TextColor3 = selected ~= nil and T.Text or T.Muted
				for i, b in ipairs(buttons) do
					b.TextColor3 = (options[i] == selected) and T.Accent or T.Muted
				end
			end

			local function setOpen(state)
				open = state
				tween(c, 0.25, { Size = UDim2.new(1, 0, 0, open and openHeight() or 38) })
				tween(arrow, 0.25, { Rotation = open and 180 or 0 })
			end

			local function build()
				for _, b in ipairs(buttons) do
					b:Destroy()
				end
				buttons = {}
				for i, opt in ipairs(options) do
					local b = create("TextButton", {
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = T.Background,
						Text = tostring(opt),
						TextColor3 = T.Muted,
						Font = F.med,
						TextSize = 13,
						AutoButtonColor = false,
						LayoutOrder = i,
					}, list)
					round(b, 6)
					b.MouseEnter:Connect(function()
						tween(b, 0.12, { BackgroundColor3 = T.Surface })
					end)
					b.MouseLeave:Connect(function()
						tween(b, 0.12, { BackgroundColor3 = T.Background })
					end)
					b.MouseButton1Click:Connect(function()
						api:Set(opt)
						setOpen(false)
					end)
					buttons[i] = b
				end
				list.Size = UDim2.new(1, -16, 0, listHeight())
				colorize()
				if open then
					tween(c, 0.2, { Size = UDim2.new(1, 0, 0, openHeight()) })
				end
			end

			function api:Set(opt, silent)
				selected = opt
				colorize()
				if not silent then
					fire(opts.Callback, selected)
				end
			end
			function api:Get()
				return selected
			end
			function api:Refresh(newOptions)
				options = newOptions or {}
				local found = false
				for _, v in ipairs(options) do
					if v == selected then
						found = true
					end
				end
				if not found then
					selected = nil
				end
				build()
			end

			header.MouseEnter:Connect(function()
				tween(c, 0.15, { BackgroundColor3 = T.ElementHover })
			end)
			header.MouseLeave:Connect(function()
				tween(c, 0.15, { BackgroundColor3 = T.Element })
			end)
			header.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			build()
			return reg(opts, api)
		end

		-----------------------------------------------------------
		-- Textbox
		-----------------------------------------------------------
		--[[ Tab:CreateTextbox({ Name, Placeholder, Default, Callback = function(text, enterPressed) end }) ]]
		function Tab:CreateTextbox(opts)
			opts = opts or {}
			local c = card(38, false)
			nameLabel(c, opts.Name or "Textbox", 0.5)

			local field = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(160, 26),
				BackgroundColor3 = T.Background,
			}, c)
			round(field, 6)
			local fieldStroke = stroke(field, T.Stroke, 1)

			local box = create("TextBox", {
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1,
				Text = opts.Default or "",
				PlaceholderText = opts.Placeholder or "Type here...",
				PlaceholderColor3 = T.Muted,
				TextColor3 = T.Text,
				Font = F.med,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
			}, field)

			box.Focused:Connect(function()
				tween(fieldStroke, 0.15, { Color = T.Accent })
			end)
			box.FocusLost:Connect(function(enter)
				tween(fieldStroke, 0.15, { Color = T.Stroke })
				fire(opts.Callback, box.Text, enter)
			end)

			local api = {}
			function api:Set(s)
				box.Text = tostring(s or "")
			end
			function api:Get()
				return box.Text
			end
			return reg(opts, api)
		end

		-----------------------------------------------------------
		-- Keybind
		-----------------------------------------------------------
		--[[ Tab:CreateKeybind({ Name, Default = Enum.KeyCode.F, Callback = function(key) end, Changed = function(key) end })
		     Escape при выборе клавиши - очистить бинд. ]]
		function Tab:CreateKeybind(opts)
			opts = opts or {}
			local key = opts.Default
			local listening = false

			local c = card(38, false)
			nameLabel(c, opts.Name or "Keybind", 0.5)

			local btn = create("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(84, 26),
				BackgroundColor3 = T.Background,
				Text = "",
				AutoButtonColor = false,
			}, c)
			round(btn, 6)
			stroke(btn, T.Stroke, 1)
			local keyLabel = text(btn, "", 12, F.med, T.Muted, {
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = CENTER,
			})

			local function render()
				if listening then
					keyLabel.Text = "..."
					keyLabel.TextColor3 = T.Accent
				else
					keyLabel.Text = key and key.Name or "None"
					keyLabel.TextColor3 = key and T.Text or T.Muted
				end
			end
			render()

			btn.MouseButton1Click:Connect(function()
				listening = true
				render()
			end)

			connect(UserInputService.InputBegan, function(input, processed)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						key = (input.KeyCode ~= Enum.KeyCode.Escape) and input.KeyCode or nil
						render()
						fire(opts.Changed, key)
					end
					return
				end
				if not processed and key and input.KeyCode == key then
					fire(opts.Callback, key)
				end
			end)

			local api = {}
			function api:Set(k)
				key = k
				render()
			end
			function api:Get()
				return key
			end
			return reg(opts, api)
		end

		-----------------------------------------------------------
		-- ColorPicker (палитра из 16 цветов)
		-----------------------------------------------------------
		--[[ Tab:CreateColorPicker({ Name, Default = Color3, Flag, Callback = function(color) end })
		     -> :Set(Color3) :Get() ]]
		function Tab:CreateColorPicker(opts)
			opts = opts or {}
			local palette = Library.Palette
			local color = opts.Default or palette[12]
			local open = false

			local c = card(38, false)
			c.ClipsDescendants = true

			local header = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
			}, c)
			nameLabel(header, opts.Name or "Color", 0.6)

			local preview = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(34, 20),
				BackgroundColor3 = color,
			}, header)
			round(preview, 6)
			stroke(preview, T.Stroke, 1)

			-- сетка 8 x 2
			local grid = create("Frame", {
				Position = UDim2.fromOffset(14, 46),
				Size = UDim2.new(1, -28, 0, 60),
				BackgroundTransparency = 1,
			}, c)
			create("UIGridLayout", {
				CellSize = UDim2.fromOffset(24, 24),
				CellPadding = UDim2.fromOffset(8, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, grid)

			local swatches = {}
			local api = {}

			local function sameColor(a, b)
				return math.abs(a.R - b.R) < 0.005 and math.abs(a.G - b.G) < 0.005 and math.abs(a.B - b.B) < 0.005
			end

			local function mark()
				preview.BackgroundColor3 = color
				for _, s in ipairs(swatches) do
					local on = sameColor(s.color, color)
					tween(s.stroke, 0.15, { Transparency = on and 0 or 1 })
				end
			end

			for i, col in ipairs(palette) do
				local s = create("TextButton", {
					Text = "",
					AutoButtonColor = false,
					BackgroundColor3 = col,
					LayoutOrder = i,
				}, grid)
				round(s, 6)
				local st = stroke(s, T.Text, 2, 1)
				swatches[i] = { color = col, stroke = st }
				s.MouseButton1Click:Connect(function()
					api:Set(col)
				end)
			end

			local function setOpen(state)
				open = state
				tween(c, 0.25, { Size = UDim2.new(1, 0, 0, open and 118 or 38) })
			end

			function api:Set(col, silent)
				if typeof(col) ~= "Color3" then
					return
				end
				color = col
				mark()
				if not silent then
					fire(opts.Callback, color)
				end
			end
			function api:Get()
				return color
			end

			header.MouseEnter:Connect(function()
				tween(c, 0.15, { BackgroundColor3 = T.ElementHover })
			end)
			header.MouseLeave:Connect(function()
				tween(c, 0.15, { BackgroundColor3 = T.Element })
			end)
			header.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			mark()
			return reg(opts, api)
		end

		return Tab
	end

	---------------------------------------------------------------
	-- ВКЛАДКА КОНФИГОВ
	---------------------------------------------------------------
	--[[ Window:CreateConfigTab("Configs", "💾")
	     Готовая вкладка: имя, список сохранённых, Save / Load / Delete / Refresh.
	     В конфиг попадают элементы, у которых задан Flag = "имя". ]]
	function Window:CreateConfigTab(name, icon)
		local Tab = Window:CreateTab(name or "Configs", icon or "💾")

		Tab:CreateSection("Config")

		local nameBox = Tab:CreateTextbox({ Name = "Config name", Placeholder = "my config" })
		local list
		list = Tab:CreateDropdown({
			Name = "Saved configs",
			Options = Library:ListConfigs(),
			Callback = function(opt)
				nameBox:Set(opt)
			end,
		})

		local function refresh()
			list:Refresh(Library:ListConfigs())
		end
		local function target()
			local n = nameBox:Get()
			if n == "" then
				n = list:Get() or ""
			end
			return n
		end
		local function report(ok, res, okTitle)
			Library:Notify({
				Title = ok and okTitle or "Config error",
				Content = tostring(res),
				Type = ok and "success" or "error",
			})
		end

		Tab:CreateButton({
			Name = "Save",
			Callback = function()
				local ok, res = Library:SaveConfig(target())
				report(ok, res, "Config saved")
				if ok then
					refresh()
					list:Set(res, true)
				end
			end,
		})
		Tab:CreateButton({
			Name = "Load",
			Callback = function()
				local ok, res = Library:LoadConfig(target())
				report(ok, res, "Config loaded")
			end,
		})
		Tab:CreateButton({
			Name = "Delete",
			Callback = function()
				local ok, res = Library:DeleteConfig(target())
				report(ok, res, "Config deleted")
				if ok then
					refresh()
					nameBox:Set("")
				end
			end,
		})
		Tab:CreateButton({
			Name = "Refresh list",
			Callback = refresh,
		})

		Tab:CreateLabel(
			hasFs() and ("Файлы лежат в папке workspace/" .. Library.ConfigFolder)
				or "Файловая система недоступна: конфиги живут в памяти до выхода из игры."
		)

		return Tab
	end

	---------------------------------------------------------------
	-- ВКЛАДКА ИГРОКОВ (drag & drop функций)
	---------------------------------------------------------------
	--[[ local P = Window:CreatePlayersTab({
	         Name = "Players", Icon = "👥",
	         IncludeLocal = true,   -- показывать себя в списке
	         Actions = {
	             { Name = "Kill", Icon = "💀", Callback = function(player, actionName) ... end },
	         },
	     })
	     P:AddAction({ Name, Icon, Callback })
	     Тяни плашку функции на игрока или на арену внизу (арена = на всех). ]]
	function Window:CreatePlayersTab(o)
		o = o or {}
		local GuiService = game:GetService("GuiService")
		local includeLocal = o.IncludeLocal ~= false

		local Tab = Window:CreateTab(o.Name or "Players", o.Icon or "👥")
		local page = Tab.Page

		-- эта вкладка рисует свой layout и не скроллится целиком
		for _, cls in ipairs({ "UIListLayout", "UIPadding" }) do
			local x = page:FindFirstChildOfClass(cls)
			if x then
				x:Destroy()
			end
		end
		page.AutomaticCanvasSize = Enum.AutomaticSize.None
		page.CanvasSize = UDim2.new()
		page.ScrollingEnabled = false
		page.ScrollBarThickness = 0

		local LIST_Y = 106
		local ARENA_H = 56

		-- верх: функции
		text(page, "FUNCTIONS  ·  drag onto a player", 12, F.bold, T.Accent, {
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 16),
		})
		local chips = create("Frame", {
			Position = UDim2.fromOffset(12, 32),
			Size = UDim2.new(1, -24, 0, 66),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, page)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, chips)

		-- середина: игроки
		local list = create("ScrollingFrame", {
			Position = UDim2.fromOffset(12, LIST_Y),
			Size = UDim2.new(1, -24, 1, -(LIST_Y + ARENA_H + 20)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = T.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, page)
		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, list)

		-- низ: арена
		local arena = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -12),
			Size = UDim2.new(1, -24, 0, ARENA_H),
			BackgroundColor3 = T.Surface,
		}, page)
		round(arena, 10)
		local arenaStroke = stroke(arena, T.Stroke, 1.5)
		text(arena, "⚔  ARENA", 14, F.bold, T.Text, {
			Position = UDim2.fromOffset(0, 9),
			Size = UDim2.new(1, 0, 0, 18),
			TextXAlignment = CENTER,
		})
		text(arena, "Drop a function here to apply it to everyone", 12, F.med, T.Muted, {
			Position = UDim2.fromOffset(0, 29),
			Size = UDim2.new(1, 0, 0, 16),
			TextXAlignment = CENTER,
		})

		local rows = {}
		local actions = {}
		local rowOrder = 0
		local drag = nil

		local function wanted(plr)
			return includeLocal or plr ~= LocalPlayer
		end

		local function addRow(plr)
			if rows[plr] or not wanted(plr) then
				return
			end
			rowOrder = rowOrder + 1
			local f = create("Frame", {
				Size = UDim2.new(1, -6, 0, 46),
				BackgroundColor3 = T.Element,
				LayoutOrder = rowOrder,
			}, list)
			round(f, 8)
			local st = stroke(f, T.Stroke, 1)

			local av = create("ImageLabel", {
				Position = UDim2.fromOffset(8, 6),
				Size = UDim2.fromOffset(34, 34),
				BackgroundColor3 = T.Background,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150",
			}, f)
			round(av, 17)

			text(f, plr.DisplayName .. (plr == LocalPlayer and "  (you)" or ""), 14, F.bold, T.Text, {
				Position = UDim2.fromOffset(52, 6),
				Size = UDim2.new(1, -64, 0, 18),
			})
			text(f, "@" .. plr.Name, 12, F.med, T.Muted, {
				Position = UDim2.fromOffset(52, 25),
				Size = UDim2.new(1, -64, 0, 16),
			})

			rows[plr] = { frame = f, stroke = st }
		end

		local function removeRow(plr)
			local r = rows[plr]
			if r then
				r.frame:Destroy()
				rows[plr] = nil
			end
		end

		for _, plr in ipairs(Players:GetPlayers()) do
			addRow(plr)
		end
		connect(Players.PlayerAdded, addRow)
		connect(Players.PlayerRemoving, removeRow)

		-- координаты указателя в тех же пикселях, что и AbsolutePosition
		local function pointer(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
			end
			return UserInputService:GetMouseLocation()
		end

		local function targetAt(p)
			if inside(arena, p) then
				return "arena"
			end
			if inside(list, p) then
				for plr, r in pairs(rows) do
					if inside(r.frame, p) then
						return plr
					end
				end
			end
			return nil
		end

		local function highlight(t)
			for plr, r in pairs(rows) do
				local on = (plr == t)
				tween(r.stroke, 0.12, { Color = on and T.Accent or T.Stroke })
				tween(r.frame, 0.12, { BackgroundColor3 = on and T.ElementHover or T.Element })
			end
			local on = (t == "arena")
			tween(arenaStroke, 0.12, { Color = on and T.Accent or T.Stroke })
			tween(arena, 0.12, { BackgroundColor3 = on and T.ElementHover or T.Surface })
		end

		local function label(a)
			return (a.Icon and (a.Icon .. "  ") or "") .. a.Name
		end

		local function makeGhost(a)
			local g = create("TextLabel", {
				Size = UDim2.fromOffset(0, 28),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = T.Accent,
				BackgroundTransparency = 0.1,
				Text = label(a),
				TextColor3 = Color3.new(1, 1, 1),
				Font = F.bold,
				TextSize = 13,
				ZIndex = 1000,
			}, Library.Gui)
			round(g, 8)
			create("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}, g)
			return g
		end

		local function drop(a, t)
			if t == "arena" then
				local n = 0
				for _, plr in ipairs(Players:GetPlayers()) do
					if wanted(plr) then
						n = n + 1
						fire(a.Callback, plr, a.Name)
					end
				end
				Library:Notify({
					Title = a.Name,
					Content = "Applied to everyone (" .. n .. ")",
					Type = "success",
					Duration = 2.5,
				})
			elseif t then
				fire(a.Callback, t, a.Name)
				Library:Notify({
					Title = a.Name,
					Content = "Applied to " .. t.DisplayName,
					Type = "success",
					Duration = 2.5,
				})
			end
		end

		connect(UserInputService.InputChanged, function(input)
			if not drag or not isMove(input) then
				return
			end
			local p = pointer(input)
			if not drag.active and (p - drag.start).Magnitude > 6 then
				drag.active = true
				drag.ghost = makeGhost(drag.action)
			end
			if drag.active then
				drag.ghost.Position = UDim2.fromOffset(p.X + 14, p.Y + 10)
				highlight(targetAt(p))
			end
		end)

		connect(UserInputService.InputEnded, function(input)
			if drag and isPress(input) then
				local d = drag
				drag = nil
				if d.ghost then
					d.ghost:Destroy()
				end
				highlight(nil)
				if d.active then
					drop(d.action, targetAt(pointer(input)))
				end
			end
		end)

		local api = { Tab = Tab }

		function api:AddAction(a)
			if type(a) ~= "table" or not a.Name then
				return
			end
			table.insert(actions, a)

			local chip = create("TextButton", {
				Size = UDim2.fromOffset(0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = T.Element,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #actions,
			}, chips)
			round(chip, 8)
			stroke(chip, T.Stroke, 1)
			create("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}, chip)
			text(chip, label(a), 13, F.med, T.Text, {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				TextTruncate = Enum.TextTruncate.None,
			})

			chip.MouseEnter:Connect(function()
				tween(chip, 0.12, { BackgroundColor3 = T.ElementHover })
			end)
			chip.MouseLeave:Connect(function()
				tween(chip, 0.12, { BackgroundColor3 = T.Element })
			end)
			chip.InputBegan:Connect(function(input)
				if isPress(input) and not drag then
					drag = { action = a, start = pointer(input), active = false, ghost = nil }
				end
			end)
		end

		for _, a in ipairs(o.Actions or {}) do
			api:AddAction(a)
		end

		return api
	end

	return Window
end

---------------------------------------------------------------------
-- ВЫГРУЗКА
---------------------------------------------------------------------
function Library:Unload()
	for _, c in ipairs(self._connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	self._connections = {}
	restoreCursor()
	self._cursorStarted = false
	self._windows = {}
	self.Flags = {}
	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end
end

return Library
