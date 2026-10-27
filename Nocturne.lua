local BloodUI = {}
BloodUI.__index = BloodUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local function Create(class, properties)
    local instance = Instance.new(class)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Tween(object, properties, duration)
    TweenService:Create(object, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties):Play()
end

function BloodUI:CreateWindow(config)
    local Window = {}
    
    local ScreenGui = Create("ScreenGui", {
        Name = "BloodUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    local MainFrame = Create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 560, 0, 420),
        BackgroundColor3 = Color3.fromRGB(8, 4, 6),
        BorderSizePixel = 0
    })
    
    Create("UICorner", {
        Parent = MainFrame,
        CornerRadius = UDim.new(0, 12)
    })
    
    local TopBar = Create("Frame", {
        Name = "TopBar",
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Color3.fromRGB(12, 6, 8),
        BorderSizePixel = 0
    })
    
    Create("UICorner", {
        Parent = TopBar,
        CornerRadius = UDim.new(0, 12)
    })
    
    local Title = Create("TextLabel", {
        Name = "Title",
        Parent = TopBar,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = config.Name or "BloodUI",
        TextColor3 = Color3.fromRGB(220, 38, 48),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local CloseButton = Create("TextButton", {
        Name = "Close",
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 32, 0, 32),
        BackgroundColor3 = Color3.fromRGB(18, 9, 11),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(180, 32, 42),
        TextSize = 20
    })
    
    Create("UICorner", {
        Parent = CloseButton,
        CornerRadius = UDim.new(1, 0)
    })
    
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4)
        wait(0.4)
        ScreenGui:Destroy()
    end)
    
    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = MainFrame,
        Position = UDim2.new(0, 12, 0, 60),
        Size = UDim2.new(0, 140, 1, -72),
        BackgroundColor3 = Color3.fromRGB(12, 6, 8),
        BorderSizePixel = 0
    })
    
    Create("UICorner", {
        Parent = TabContainer,
        CornerRadius = UDim.new(0, 10)
    })
    
    Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })
    
    Create("UIPadding", {
        Parent = TabContainer,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    })
    
    local ContentContainer = Create("Frame", {
        Name = "Content",
        Parent = MainFrame,
        Position = UDim2.new(0, 164, 0, 60),
        Size = UDim2.new(1, -176, 1, -72),
        BackgroundColor3 = Color3.fromRGB(12, 6, 8),
        BorderSizePixel = 0
    })
    
    Create("UICorner", {
        Parent = ContentContainer,
        CornerRadius = UDim.new(0, 10)
    })
    
    local CurrentTab = nil
    
    function Window:CreateTab(name)
        local Tab = {}
        
        local TabButton = Create("TextButton", {
            Name = name,
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Color3.fromRGB(18, 9, 11),
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = Color3.fromRGB(140, 28, 36),
            TextSize = 14,
            AutoButtonColor = false
        })
        
        Create("UICorner", {
            Parent = TabButton,
            CornerRadius = UDim.new(0, 8)
        })
        
        local TabContent = Create("ScrollingFrame", {
            Name = name,
            Parent = ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Color3.fromRGB(180, 32, 42),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false
        })
        
        Create("UIListLayout", {
            Parent = TabContent,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        
        Create("UIPadding", {
            Parent = TabContent,
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        })
        
        TabButton.MouseButton1Click:Connect(function()
            if CurrentTab then
                CurrentTab.Visible = false
                for _, btn in pairs(TabContainer:GetChildren()) do
                    if btn:IsA("TextButton") then
                        Tween(btn, {BackgroundColor3 = Color3.fromRGB(18, 9, 11), TextColor3 = Color3.fromRGB(140, 28, 36)})
                    end
                end
            end
            TabContent.Visible = true
            CurrentTab = TabContent
            Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(180, 32, 42), TextColor3 = Color3.fromRGB(255, 255, 255)})
        end)
        
        if not CurrentTab then
            TabButton.BackgroundColor3 = Color3.fromRGB(180, 32, 42)
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabContent.Visible = true
            CurrentTab = TabContent
        end
        
        TabContent:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContent.UIListLayout.AbsoluteContentSize.Y + 24)
        end)
        
        function Tab:CreateButton(text, callback)
            local Button = Create("TextButton", {
                Name = text,
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Color3.fromRGB(18, 9, 11),
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                AutoButtonColor = false
            })
            
            Create("UICorner", {
                Parent = Button,
                CornerRadius = UDim.new(1, 0)
            })
            
            Button.MouseEnter:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(140, 28, 36)})
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(18, 9, 11)})
            end)
            
            Button.MouseButton1Click:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(180, 32, 42)})
                wait(0.1)
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(18, 9, 11)})
                pcall(callback)
            end)
        end
        
        function Tab:CreateToggle(text, default, callback)
            local toggled = default or false
            
            local ToggleFrame = Create("Frame", {
                Name = text,
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Color3.fromRGB(18, 9, 11),
                BorderSizePixel = 0
            })
            
            Create("UICorner", {
                Parent = ToggleFrame,
                CornerRadius = UDim.new(1, 0)
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = ToggleFrame,
                Position = UDim2.new(0, 16, 0, 0),
                Size = UDim2.new(1, -70, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ToggleButton = Create("TextButton", {
                Name = "Toggle",
                Parent = ToggleFrame,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, 46, 0, 24),
                BackgroundColor3 = toggled and Color3.fromRGB(180, 32, 42) or Color3.fromRGB(30, 15, 18),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false
            })
            
            Create("UICorner", {
                Parent = ToggleButton,
                CornerRadius = UDim.new(1, 0)
            })
            
            local Circle = Create("Frame", {
                Name = "Circle",
                Parent = ToggleButton,
                Position = toggled and UDim2.new(1, -20, 0.5, -10) or UDim2.new(0, 4, 0.5, -10),
                Size = UDim2.new(0, 20, 0, 20),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0
            })
            
            Create("UICorner", {
                Parent = Circle,
                CornerRadius = UDim.new(1, 0)
            })
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                Tween(ToggleButton, {BackgroundColor3 = toggled and Color3.fromRGB(180, 32, 42) or Color3.fromRGB(30, 15, 18)})
                Tween(Circle, {Position = toggled and UDim2.new(1, -20, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)})
                pcall(callback, toggled)
            end)
        end
        
        function Tab:CreateSlider(text, min, max, default, callback)
            local value = default or min
            
            local SliderFrame = Create("Frame", {
                Name = text,
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = Color3.fromRGB(18, 9, 11),
                BorderSizePixel = 0
            })
            
            Create("UICorner", {
                Parent = SliderFrame,
                CornerRadius = UDim.new(0, 10)
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = SliderFrame,
                Position = UDim2.new(0, 16, 0, 8),
                Size = UDim2.new(1, -80, 0, 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ValueLabel = Create("TextLabel", {
                Name = "Value",
                Parent = SliderFrame,
                Position = UDim2.new(1, -60, 0, 8),
                Size = UDim2.new(0, 50, 0, 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = tostring(value),
                TextColor3 = Color3.fromRGB(180, 32, 42),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right
            })
            
            local SliderBar = Create("Frame", {
                Name = "Bar",
                Parent = SliderFrame,
                Position = UDim2.new(0, 16, 1, -18),
                Size = UDim2.new(1, -32, 0, 6),
                BackgroundColor3 = Color3.fromRGB(30, 15, 18),
                BorderSizePixel = 0
            })
            
            Create("UICorner", {
                Parent = SliderBar,
                CornerRadius = UDim.new(1, 0)
            })
            
            local SliderFill = Create("Frame", {
                Name = "Fill",
                Parent = SliderBar,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(180, 32, 42),
                BorderSizePixel = 0
            })
            
            Create("UICorner", {
                Parent = SliderFill,
                CornerRadius = UDim.new(1, 0)
            })
            
            local dragging = false
            
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * pos)
                ValueLabel.Text = tostring(value)
                Tween(SliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
                pcall(callback, value)
            end
            
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(input)
                end
            end)
            
            SliderBar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input)
                end
            end)
        end
        
        function Tab:CreateInput(text, placeholder, callback)
            local InputFrame = Create("Frame", {
                Name = text,
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = Color3.fromRGB(18, 9, 11),
                BorderSizePixel = 0
            })
            
            Create("UICorner", {
                Parent = InputFrame,
                CornerRadius = UDim.new(0, 10)
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = InputFrame,
                Position = UDim2.new(0, 16, 0, 8),
                Size = UDim2.new(1, -32, 0, 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local Input = Create("TextBox", {
                Name = "Input",
                Parent = InputFrame,
                Position = UDim2.new(0, 16, 0, 32),
                Size = UDim2.new(1, -32, 0, 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                PlaceholderText = placeholder or "",
                PlaceholderColor3 = Color3.fromRGB(80, 40, 46),
                Text = "",
                TextColor3 = Color3.fromRGB(180, 32, 42),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false
            })
            
            Input.FocusLost:Connect(function()
                pcall(callback, Input.Text)
            end)
        end
        
        function Tab:CreateLabel(text)
            local Label = Create("TextLabel", {
                Name = text,
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(140, 140, 140),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            Create("UIPadding", {
                Parent = Label,
                PaddingLeft = UDim.new(0, 8)
            })
        end
        
        return Tab
    end
    
    local dragging, dragInput, dragStart, startPos
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(MainFrame, {Size = UDim2.new(0, 560, 0, 420)}, 0.5)
    
    return Window
end

return BloodUI
