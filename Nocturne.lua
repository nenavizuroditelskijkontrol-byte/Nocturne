-- LocalScript для StarterPlayer > StarterPlayerScripts.
-- Самостоятельный интерфейс для своей игры; не предназначен для инжекторов
-- и не использует executor API или loadstring.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
	Background = Color3.fromRGB(20, 22, 29),
	Panel = Color3.fromRGB(29, 32, 41),
	Hover = Color3.fromRGB(40, 44, 56),
	Accent = Color3.fromRGB(116, 92, 255),
	Text = Color3.fromRGB(240, 241, 247),
	Muted = Color3.fromRGB(155, 160, 175),
	Track = Color3.fromRGB(52, 56, 69),
}

local function create(className, properties, parent)
	local instance = Instance.new(className)

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	instance.Parent = parent
	return instance
end

local function round(instance, radius)
	create("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
	}, instance)
end

local screenGui = create("ScreenGui", {
	Name = "NovaInterface",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local window = create("Frame", {
	Name = "Window",
	Size = UDim2.fromOffset(570, 400),
	Position = UDim2.new(0.5, -285, 0.5, -200),
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
}, screenGui)
round(window, 12)

create("UIStroke", {
	Color = Color3.fromRGB(67, 71, 88),
	Transparency = 0.35,
	Thickness = 1,
}, window)

local topbar = create("Frame", {
	Name = "Topbar",
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
}, window)
round(topbar, 12)

create("Frame", {
	Position = UDim2.new(0, 0, 1, -12),
	Size = UDim2.new(1, 0, 0, 12),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
}, topbar)

create("TextLabel", {
	Position = UDim2.fromOffset(18, 0),
	Size = UDim2.new(1, -70, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Nova UI",
	TextColor3 = Theme.Text,
	TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Left,
}, topbar)

local closeButton = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = Theme.Hover,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamMedium,
	Text = "×",
	TextColor3 = Theme.Text,
	TextSize = 22,
	AutoButtonColor = false,
}, topbar)
round(closeButton, 8)

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

local tabContainer = create("Frame", {
	Position = UDim2.fromOffset(14, 70),
	Size = UDim2.new(0, 145, 1, -84),
	BackgroundTransparency = 1,
}, window)

create("UIListLayout", {
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabContainer)

local pageContainer = create("Frame", {
	Position = UDim2.fromOffset(172, 70),
	Size = UDim2.new(1, -186, 1, -84),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, window)

local currentPage
local tabButtons = {}

local function createTab(name)
	local tabButton = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = name,
		TextColor3 = Theme.Muted,
		TextSize = 13,
	}, tabContainer)
	round(tabButton, 8)

	local page = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		Visible = false,
	}, pageContainer)

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 8),
	}, page)

	local layout = create("UIListLayout", {
		Padding = UDim.new(0, 9),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
	end)

	local function selectTab()
		if currentPage then
			currentPage.Visible = false
		end

		currentPage = page
		page.Visible = true

		for _, button in ipairs(tabButtons) do
			local selected = button == tabButton
			button.BackgroundColor3 = selected and Theme.Accent or Theme.Panel
			button.TextColor3 = selected and Theme.Text or Theme.Muted
		end
	end

	tabButton.MouseButton1Click:Connect(selectTab)
	table.insert(tabButtons, tabButton)

	local tab = {}

	local function makeRow(height)
		local row = create("Frame", {
			Size = UDim2.new(1, -4, 0, height),
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
		}, page)
		round(row, 8)
		return row
	end

	function tab:Label(text)
		local row = makeRow(40)

		create("TextLabel", {
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
	end

	function tab:Button(text, callback)
		local row = makeRow(44)
		local button = create("TextButton", {
			Position = UDim2.fromOffset(6, 5),
			Size = UDim2.new(1, -12, 1, -10),
			BackgroundColor3 = Theme.Hover,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 13,
		}, row)
		round(button, 6)

		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = Theme.Accent,
			}):Play()
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = Theme.Hover,
			}):Play()
		end)

		button.MouseButton1Click:Connect(function()
			if callback then
				callback()
			end
		end)
	end

	function tab:Toggle(text, defaultValue, callback)
		local enabled = defaultValue == true
		local row = makeRow(44)

		create("TextLabel", {
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)

		local toggle = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(40, 22),
			BackgroundColor3 = enabled and Theme.Accent or Theme.Track,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, row)
		round(toggle, 11)

		local knob = create("Frame", {
			Position = enabled and UDim2.new(1, -19, 0.5, -7) or UDim2.new(0, 5, 0.5, -7),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, toggle)
		round(knob, 7)

		local function setValue(value)
			enabled = value
			toggle.BackgroundColor3 = enabled and Theme.Accent or Theme.Track
			knob.Position = enabled and UDim2.new(1, -19, 0.5, -7) or UDim2.new(0, 5, 0.5, -7)

			if callback then
				callback(enabled)
			end
		end

		toggle.MouseButton1Click:Connect(function()
			setValue(not enabled)
		end)

		return {
			Get = function()
				return enabled
			end,
			Set = setValue,
		}
	end

	function tab:Slider(text, minimum, maximum, defaultValue, callback)
		minimum = minimum or 0
		maximum = maximum or 100
		defaultValue = math.clamp(defaultValue or minimum, minimum, maximum)

		local value = defaultValue
		local row = makeRow(64)

		create("TextLabel", {
			Position = UDim2.fromOffset(12, 5),
			Size = UDim2.new(1, -70, 0, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)

		local valueLabel = create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 5),
			Size = UDim2.fromOffset(55, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = tostring(value),
			TextColor3 = Theme.Muted,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, row)

		local track = create("TextButton", {
			Position = UDim2.new(0, 12, 0, 38),
			Size = UDim2.new(1, -24, 0, 6),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, row)
		round(track, 3)

		local initialAlpha = (value - minimum) / math.max(maximum - minimum, 1)
		local fill = create("Frame", {
			Size = UDim2.new(initialAlpha, 0, 1, 0),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
		}, track)
		round(fill, 3)

		local dragging = false

		local function update(inputX)
			local alpha = math.clamp(
				(inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X,
				0,
				1
			)

			value = math.floor(minimum + (maximum - minimum) * alpha + 0.5)
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			valueLabel.Text = tostring(value)

			if callback then
				callback(value)
			end
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input.Position.X)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			) then
				update(input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		return {
			Get = function()
				return value
			end,
			Set = function(newValue)
				newValue = math.clamp(newValue, minimum, maximum)
				local alpha = (newValue - minimum) / math.max(maximum - minimum, 1)

				value = newValue
				fill.Size = UDim2.new(alpha, 0, 1, 0)
				valueLabel.Text = tostring(value)

				if callback then
					callback(value)
				end
			end,
		}
	end

	if not currentPage then
		tabButton.BackgroundColor3 = Theme.Accent
		tabButton.TextColor3 = Theme.Text
		currentPage = page
		page.Visible = true
	end

	return tab
end

local dragging = false
local dragStart
local startPosition

topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = window.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	) then
		local delta = input.Position - dragStart

		window.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local mainTab = createTab("Главная")
mainTab:Label("Добро пожаловать в Nova UI")
mainTab:Button("Нажми меня", function()
	print("Кнопка нажата")
end)
mainTab:Toggle("Включить эффект", false, function(enabled)
	print("Эффект включён:", enabled)
end)
mainTab:Slider("Громкость", 0, 100, 50, function(value)
	print("Громкость:", value)
end)

local infoTab = createTab("Информация")
infoTab:Label("Интерфейс создан одним LocalScript.")
infoTab:Button("Закрыть интерфейс", function()
	screenGui:Destroy()
end)
