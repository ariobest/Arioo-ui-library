--[[
    ArioUI
    Modern Roblox UI Library
    Original implementation; inspired by modern dark UI patterns.

    Features:
      Window animation, moving gradients, tabs, search, notifications,
      tags, buttons, toggles, sliders, dropdowns, textboxes, keybinds,
      color pickers, dialogs, themes and config helpers.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ArioUI = {}
ArioUI.__index = ArioUI

local Themes = {
    Midnight = {
        Background = Color3.fromRGB(12, 13, 17),
        Surface = Color3.fromRGB(18, 20, 26),
        Surface2 = Color3.fromRGB(24, 26, 34),
        Text = Color3.fromRGB(245, 247, 255),
        Muted = Color3.fromRGB(145, 150, 165),
        Stroke = Color3.fromRGB(43, 46, 57),
        Accent = Color3.fromRGB(112, 88, 255),
        Accent2 = Color3.fromRGB(58, 194, 255),
        Success = Color3.fromRGB(65, 210, 130),
        Danger = Color3.fromRGB(255, 85, 105)
    },
    Ocean = {
        Background = Color3.fromRGB(8, 15, 21),
        Surface = Color3.fromRGB(12, 24, 33),
        Surface2 = Color3.fromRGB(17, 34, 45),
        Text = Color3.fromRGB(240, 250, 255),
        Muted = Color3.fromRGB(137, 166, 180),
        Stroke = Color3.fromRGB(32, 58, 70),
        Accent = Color3.fromRGB(38, 174, 255),
        Accent2 = Color3.fromRGB(77, 235, 210),
        Success = Color3.fromRGB(65, 210, 130),
        Danger = Color3.fromRGB(255, 85, 105)
    },
    Ember = {
        Background = Color3.fromRGB(20, 12, 10),
        Surface = Color3.fromRGB(30, 18, 14),
        Surface2 = Color3.fromRGB(42, 23, 17),
        Text = Color3.fromRGB(255, 247, 240),
        Muted = Color3.fromRGB(181, 149, 136),
        Stroke = Color3.fromRGB(65, 40, 31),
        Accent = Color3.fromRGB(255, 112, 62),
        Accent2 = Color3.fromRGB(255, 201, 74),
        Success = Color3.fromRGB(65, 210, 130),
        Danger = Color3.fromRGB(255, 85, 105)
    }
}

local function New(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function Corner(parent, radius)
    return New("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius or 8)})
end

local function Stroke(parent, color, transparency)
    return New("UIStroke", {
        Parent = parent,
        Color = color,
        Transparency = transparency or 0,
        Thickness = 1
    })
end

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function Gradient(parent, colors, rotation)
    local g = New("UIGradient", {
        Parent = parent,
        Rotation = rotation or 0,
        Color = ColorSequence.new(colors)
    })
    return g
end

local function Ripple(button)
    button.ClipsDescendants = true
    button.MouseButton1Click:Connect(function()
        local mouse = UserInputService:GetMouseLocation()
        local p = button.AbsolutePosition
        local r = New("Frame", {
            Parent = button,
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = .82,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(mouse.X - p.X, mouse.Y - p.Y),
            Size = UDim2.fromOffset(0,0),
            ZIndex = button.ZIndex + 5
        })
        Corner(r, 999)
        Tween(r, TweenInfo.new(.45, Enum.EasingStyle.Quad), {
            Size = UDim2.fromOffset(260,260),
            Position = UDim2.fromOffset(mouse.X - p.X - 130, mouse.Y - p.Y - 130),
            BackgroundTransparency = 1
        })
        task.delay(.5, function() r:Destroy() end)
    end)
end

local function MakeDraggable(handle, target)
    local dragging, start, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - start
            Tween(target, TweenInfo.new(.08, Enum.EasingStyle.Linear), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

function ArioUI:SetTheme(name)
    if Themes[name] then
        self.ThemeName = name
        self.Theme = Themes[name]
        self:RefreshTheme()
    end
end

function ArioUI:RefreshTheme()
    local t = self.Theme
    if not self.Gui then return end
    self.Window.BackgroundColor3 = t.Background
    self.WindowStroke.Color = t.Stroke
    self.Topbar.BackgroundColor3 = t.Surface
    self.Sidebar.BackgroundColor3 = t.Surface
    self.Content.BackgroundColor3 = t.Background
    for _, tab in pairs(self.Tabs) do
        tab.Button.TextColor3 = t.Muted
    end
end

function ArioUI:Notify(data)
    data = data or {}
    local holder = self.NotificationHolder
    local t = self.Theme
    local n = New("Frame", {
        Parent = holder,
        BackgroundColor3 = t.Surface,
        BackgroundTransparency = .03,
        Size = UDim2.new(1, 0, 0, 76),
        ClipsDescendants = true
    })
    Corner(n, 12); Stroke(n, t.Stroke)
    local accent = New("Frame", {Parent=n, BackgroundColor3=t.Accent, BorderSizePixel=0, Size=UDim2.new(0,3,1,0)})
    Corner(accent, 3)
    New("TextLabel", {
        Parent=n, BackgroundTransparency=1, Position=UDim2.fromOffset(16,10),
        Size=UDim2.new(1,-28,0,22), Font=Enum.Font.GothamBold, TextSize=14,
        TextColor3=t.Text, TextXAlignment=Enum.TextXAlignment.Left,
        Text=data.Title or "Notification"
    })
    New("TextLabel", {
        Parent=n, BackgroundTransparency=1, Position=UDim2.fromOffset(16,34),
        Size=UDim2.new(1,-28,0,30), Font=Enum.Font.Gotham, TextSize=12,
        TextColor3=t.Muted, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
        Text=data.Content or ""
    })
    n.Size = UDim2.new(1,0,0,0)
    Tween(n, TweenInfo.new(.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size=UDim2.new(1,0,0,76)})
    task.delay(data.Duration or 4, function()
        if n.Parent then
            Tween(n, TweenInfo.new(.25, Enum.EasingStyle.Quad), {Size=UDim2.new(1,0,0,0)})
            task.wait(.3); n:Destroy()
        end
    end)
end

function ArioUI:CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, ArioUI)
    self.ThemeName = config.Theme or "Midnight"
    self.Theme = Themes[self.ThemeName] or Themes.Midnight
    self.Tabs = {}
    self.Components = {}
    self.SearchText = ""

    if PlayerGui:FindFirstChild("ArioUI") then
        PlayerGui.ArioUI:Destroy()
    end

    self.Gui = New("ScreenGui", {
        Name="ArioUI", Parent=PlayerGui, ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    })

    local t = self.Theme
    self.Window = New("Frame", {
        Parent=self.Gui, BackgroundColor3=t.Background, BorderSizePixel=0,
        AnchorPoint=Vector2.new(.5,.5), Position=UDim2.fromScale(.5,.54),
        Size=UDim2.fromOffset(config.Width or 760, config.Height or 500),
        ClipsDescendants=true
    })
    Corner(self.Window, 16)
    self.WindowStroke = Stroke(self.Window, t.Stroke)

    local scale = New("UIScale", {Parent=self.Window, Scale=0.86})
    Tween(scale, TweenInfo.new(.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale=1})

    self.Topbar = New("Frame", {
        Parent=self.Window, BackgroundColor3=t.Surface, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,62)
    })

    local title = New("TextLabel", {
        Parent=self.Topbar, BackgroundTransparency=1, Position=UDim2.fromOffset(22,9),
        Size=UDim2.new(0,300,0,25), Font=Enum.Font.GothamBold, TextSize=17,
        TextColor3=t.Text, TextXAlignment=Enum.TextXAlignment.Left,
        Text=config.Title or "ArioUI"
    })
    local subtitle = New("TextLabel", {
        Parent=self.Topbar, BackgroundTransparency=1, Position=UDim2.fromOffset(23,34),
        Size=UDim2.new(0,340,0,18), Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=t.Muted, TextXAlignment=Enum.TextXAlignment.Left,
        Text=config.Subtitle or "Modern interface"
    })

    local gradientLine = New("Frame", {
        Parent=self.Topbar, BorderSizePixel=0, Position=UDim2.new(0,0,1,-2),
        Size=UDim2.new(1,0,0,2), BackgroundColor3=t.Accent
    })
    Gradient(gradientLine, {
        ColorSequenceKeypoint.new(0,t.Accent),
        ColorSequenceKeypoint.new(.5,t.Accent2),
        ColorSequenceKeypoint.new(1,t.Accent)
    }, 0)

    task.spawn(function()
        while self.Gui.Parent do
            for x = -1, 1, .02 do
                local g = gradientLine:FindFirstChildOfClass("UIGradient")
                if g then g.Offset = Vector2.new(x,0) end
                task.wait(.025)
            end
        end
    end)

    local close = New("TextButton", {
        Parent=self.Topbar, BackgroundColor3=t.Surface2, BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,.5), Position=UDim2.new(1,-14,.5,0),
        Size=UDim2.fromOffset(34,34), Text="×", TextSize=20,
        Font=Enum.Font.GothamBold, TextColor3=t.Muted, AutoButtonColor=false
    })
    Corner(close,9); Ripple(close)
    close.MouseEnter:Connect(function() Tween(close,TweenInfo.new(.15),{TextColor3=t.Danger}) end)
    close.MouseLeave:Connect(function() Tween(close,TweenInfo.new(.15),{TextColor3=t.Muted}) end)
    close.MouseButton1Click:Connect(function()
        Tween(scale,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Scale=.88})
        task.delay(.3,function() self.Gui:Destroy() end)
    end)

    self.Sidebar = New("Frame", {
        Parent=self.Window, BackgroundColor3=t.Surface, BorderSizePixel=0,
        Position=UDim2.fromOffset(0,62), Size=UDim2.new(0,174,1,-62)
    })
    self.TabList = New("ScrollingFrame", {
        Parent=self.Sidebar, BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.fromOffset(10,10), Size=UDim2.new(1,-20,1,-68),
        ScrollBarThickness=2, AutomaticCanvasSize=Enum.AutomaticSize.Y
    })
    New("UIListLayout",{Parent=self.TabList,Padding=UDim.new(0,6)})

    local search = New("TextBox", {
        Parent=self.Sidebar, BackgroundColor3=t.Surface2, BorderSizePixel=0,
        Position=UDim2.new(0,10,1,-50), Size=UDim2.new(1,-20,0,38),
        PlaceholderText="⌕  Search", PlaceholderColor3=t.Muted,
        TextColor3=t.Text, Font=Enum.Font.Gotham, TextSize=12,
        Text="", ClearTextOnFocus=false
    })
    Corner(search,10); Stroke(search,t.Stroke)
    search:GetPropertyChangedSignal("Text"):Connect(function()
        self.SearchText = string.lower(search.Text)
        for _, c in pairs(self.Components) do
            if c.Searchable then
                c.Root.Visible = self.SearchText == "" or string.find(string.lower(c.Name or ""), self.SearchText, 1, true) ~= nil
            end
        end
    end)

    self.Content = New("Frame", {
        Parent=self.Window, BackgroundColor3=t.Background, BorderSizePixel=0,
        Position=UDim2.fromOffset(174,62), Size=UDim2.new(1,-174,1,-62)
    })

    self.NotificationHolder = New("Frame", {
        Parent=self.Gui, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-18,1,-18), Size=UDim2.fromOffset(320,420)
    })
    New("UIListLayout",{Parent=self.NotificationHolder,VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0,8)})

    MakeDraggable(self.Topbar, self.Window)

    function self:AddTab(name, icon)
        local tab = {Name=name}
        local button = New("TextButton", {
            Parent=self.TabList, BackgroundTransparency=1, Size=UDim2.new(1,0,0,42),
            Text="", AutoButtonColor=false
        })
        local indicator = New("Frame", {
            Parent=button, BackgroundColor3=t.Accent, BorderSizePixel=0,
            Position=UDim2.new(0,0,.5,-9), Size=UDim2.fromOffset(3,18)
        })
        Corner(indicator,3)
        indicator.Visible=false

        local label = New("TextLabel", {
            Parent=button, BackgroundTransparency=1, Position=UDim2.fromOffset(12,0),
            Size=UDim2.new(1,-12,1,0), Font=Enum.Font.GothamMedium, TextSize=12,
            TextColor3=t.Muted, TextXAlignment=Enum.TextXAlignment.Left,
            Text=(icon and (icon.."  ") or "")..name
        })
        button.MouseEnter:Connect(function()
            if not indicator.Visible then Tween(label,TweenInfo.new(.15),{TextColor3=t.Text}) end
        end)
        button.MouseLeave:Connect(function()
            if not indicator.Visible then Tween(label,TweenInfo.new(.15),{TextColor3=t.Muted}) end
        end)

        local page = New("ScrollingFrame", {
            Parent=self.Content, BackgroundTransparency=1, BorderSizePixel=0,
            Size=UDim2.fromScale(1,1), Visible=false, ScrollBarThickness=3,
            AutomaticCanvasSize=Enum.AutomaticSize.Y
        })
        local pad = New("UIPadding",{Parent=page,PaddingTop=18,PaddingBottom=24,PaddingLeft=18,PaddingRight=18})
        New("UIListLayout",{Parent=page,Padding=UDim.new(0,10)})

        function tab:Activate()
            for _, other in pairs(self.Tabs) do
                other.Page.Visible=false
                other.Indicator.Visible=false
                other.Label.TextColor3=t.Muted
            end
            page.Visible=true; indicator.Visible=true
            label.TextColor3=t.Text
        end

        function tab:AddSection(sectionName)
            local section = {}
            local root = New("Frame", {
                Parent=page, BackgroundColor3=t.Surface, BorderSizePixel=0,
                Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y
            })
            Corner(root,12); Stroke(root,t.Stroke)
            local header = New("TextLabel", {
                Parent=root, BackgroundTransparency=1, Position=UDim2.fromOffset(14,12),
                Size=UDim2.new(1,-28,0,22), Font=Enum.Font.GothamBold, TextSize=13,
                TextColor3=t.Text, TextXAlignment=Enum.TextXAlignment.Left, Text=sectionName
            })
            local list = New("Frame", {
                Parent=root, BackgroundTransparency=1, Position=UDim2.fromOffset(12,40),
                Size=UDim2.new(1,-24,0,0), AutomaticSize=Enum.AutomaticSize.Y
            })
            New("UIListLayout",{Parent=list,Padding=UDim.new(0,7)})
            New("UIPadding",{Parent=root,PaddingBottom=UDim.new(0,12)})

            function section:AddButton(data)
                data=data or {}
                local b=New("TextButton",{
                    Parent=list, BackgroundColor3=t.Surface2, BorderSizePixel=0,
                    Size=UDim2.new(1,0,0,58), AutoButtonColor=false, Text=""
                })
                Corner(b,9); Stroke(b,t.Stroke); Ripple(b)
                New("TextLabel",{Parent=b,BackgroundTransparency=1,Position=UDim2.fromOffset(12,8),
                    Size=UDim2.new(1,-90,0,20),Font=Enum.Font.GothamMedium,TextSize=12,
                    TextColor3=t.Text,TextXAlignment=Enum.TextXAlignment.Left,Text=data.Name or "Button"})
                New("TextLabel",{Parent=b,BackgroundTransparency=1,Position=UDim2.fromOffset(12,29),
                    Size=UDim2.new(1,-90,0,18),Font=Enum.Font.Gotham,TextSize=10,
                    TextColor3=t.Muted,TextXAlignment=Enum.TextXAlignment.Left,Text=data.Description or ""})
                if data.Tag then
                    local tag=New("TextLabel",{Parent=b,AnchorPoint=Vector2.new(1,.5),
                        Position=UDim2.new(1,-12,.5,0),Size=UDim2.fromOffset(54,22),
                        BackgroundColor3=t.Accent,TextColor3=Color3.new(1,1,1),
                        Font=Enum.Font.GothamBold,TextSize=9,Text=string.upper(data.Tag)})
                    Corner(tag,7)
                end
                b.MouseButton1Click:Connect(function() if data.Callback then data.Callback() end end)
                local c={Root=b,Name=data.Name or "Button",Searchable=true}; table.insert(self.Components,c)
                return c
            end

            function section:AddToggle(data)
                data=data or {}; local value=data.Default==true
                local b=New("TextButton",{Parent=list,BackgroundColor3=t.Surface2,BorderSizePixel=0,
                    Size=UDim2.new(1,0,0,52),AutoButtonColor=false,Text=""})
                Corner(b,9); Stroke(b,t.Stroke)
                New("TextLabel",{Parent=b,BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),
                    Size=UDim2.new(1,-90,1,0),Font=Enum.Font.GothamMedium,TextSize=12,
                    TextColor3=t.Text,TextXAlignment=Enum.TextXAlignment.Left,Text=data.Name or "Toggle"})
                local sw=New("Frame",{Parent=b,AnchorPoint=Vector2.new(1,.5),
                    Position=UDim2.new(1,-12,.5,0),Size=UDim2.fromOffset(42,23),BackgroundColor3=t.Stroke})
                Corner(sw,12)
                local knob=New("Frame",{Parent=sw,BackgroundColor3=t.Muted,Size=UDim2.fromOffset(17,17),
                    Position=UDim2.fromOffset(3,3)});Corner(knob,99)
                local function set(v, silent)
                    value=v
                    Tween(sw,TweenInfo.new(.18),{BackgroundColor3=value and t.Accent or t.Stroke})
                    Tween(knob,TweenInfo.new(.18,Enum.EasingStyle.Quint),{Position=value and UDim2.fromOffset(22,3) or UDim2.fromOffset(3,3),
                        BackgroundColor3=value and Color3.new(1,1,1) or t.Muted})
                    if not silent and data.Callback then data.Callback(value) end
                end
                b.MouseButton1Click:Connect(function() set(not value) end); set(value,true)
                local c={Root=b,Name=data.Name or "Toggle",Searchable=true,SetValue=set,GetValue=function()return value end}
                table.insert(self.Components,c); return c
            end

            function section:AddSlider(data)
                data=data or {}; local min=data.Min or 0; local max=data.Max or 100; local value=data.Default or min
                local root=New("Frame",{Parent=list,BackgroundColor3=t.Surface2,BorderSizePixel=0,
                    Size=UDim2.new(1,0,0,70)});Corner(root,9);Stroke(root,t.Stroke)
                local label=New("TextLabel",{Parent=root,BackgroundTransparency=1,Position=UDim2.fromOffset(12,9),
                    Size=UDim2.new(1,-80,0,20),Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=t.Text,
                    TextXAlignment=Enum.TextXAlignment.Left,Text=data.Name or "Slider"})
                local valLabel=New("TextLabel",{Parent=root,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),
                    Position=UDim2.new(1,-12,9,0),Size=UDim2.fromOffset(55,20),Font=Enum.Font.GothamBold,
                    TextSize=11,TextColor3=t.Accent,TextXAlignment=Enum.TextXAlignment.Right,Text=tostring(value)})
                local bar=New("Frame",{Parent=root,BackgroundColor3=t.Stroke,BorderSizePixel=0,
                    Position=UDim2.fromOffset(12,43),Size=UDim2.new(1,-24,0,5)});Corner(bar,4)
                local fill=New("Frame",{Parent=bar,BackgroundColor3=t.Accent,BorderSizePixel=0,
                    Size=UDim2.new((value-min)/(max-min),0,1,0)});Corner(fill,4)
                local dragging=false
                local function set(v,silent)
                    value=math.clamp(v,min,max); local a=(value-min)/(max-min)
                    fill.Size=UDim2.new(a,0,1,0); valLabel.Text=tostring(math.floor(value*100)/100)
                    if not silent and data.Callback then data.Callback(value) end
                end
                local function update(x)
                    set(min+(max-min)*math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1))
                end
                bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;update(i.Position.X) end end)
                UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i.Position.X) end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
                local c={Root=root,Name=data.Name or "Slider",Searchable=true,SetValue=set,GetValue=function()return value end};table.insert(self.Components,c);return c
            end

            function section:AddDropdown(data)
                data=data or {}; local opened=false; local selected=data.Default or data.Options and data.Options[1] or "Select"
                local root=New("Frame",{Parent=list,BackgroundColor3=t.Surface2,BorderSizePixel=0,Size=UDim2.new(1,0,0,50),ClipsDescendants=true})
                Corner(root,9);Stroke(root,t.Stroke)
                local button=New("TextButton",{Parent=root,BackgroundTransparency=1,Size=UDim2.new(1,0,0,50),Text="",AutoButtonColor=false})
                New("TextLabel",{Parent=button,BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),Size=UDim2.new(.5,0,1,0),
                    Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=t.Text,TextXAlignment=Enum.TextXAlignment.Left,Text=data.Name or "Dropdown"})
                local valueLabel=New("TextLabel",{Parent=button,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),
                    Position=UDim2.new(1,-14,.5,0),Size=UDim2.new(.45,0,0,20),Font=Enum.Font.Gotham,TextSize=11,
                    TextColor3=t.Accent,TextXAlignment=Enum.TextXAlignment.Right,Text=tostring(selected)})
                local optionsFrame=New("Frame",{Parent=root,BackgroundTransparency=1,Position=UDim2.fromOffset(8,52),
                    Size=UDim2.new(1,-16,0,0),AutomaticSize=Enum.AutomaticSize.Y})
                New("UIListLayout",{Parent=optionsFrame,Padding=UDim.new(0,4)})
                local function rebuild()
                    for _,x in ipairs(optionsFrame:GetChildren()) do if x:IsA("TextButton") then x:Destroy() end end
                    for _,opt in ipairs(data.Options or {}) do
                        local ob=New("TextButton",{Parent=optionsFrame,BackgroundColor3=t.Background,BorderSizePixel=0,
                            Size=UDim2.new(1,0,0,32),Font=Enum.Font.Gotham,TextSize=11,TextColor3=t.Muted,Text=tostring(opt),AutoButtonColor=false})
                        Corner(ob,7)
                        ob.MouseButton1Click:Connect(function()
                            selected=opt;valueLabel.Text=tostring(opt);opened=false
                            root.Size=UDim2.new(1,0,0,50)
                            if data.Callback then data.Callback(opt) end
                        end)
                    end
                end
                rebuild()
                button.MouseButton1Click:Connect(function()
                    opened=not opened
                    root.Size=opened and UDim2.new(1,0,0,58+#(data.Options or {})*36) or UDim2.new(1,0,0,50)
                end)
                local c={Root=root,Name=data.Name or "Dropdown",Searchable=true,SetValue=function(v)selected=v;valueLabel.Text=tostring(v)end};table.insert(self.Components,c);return c
            end

            function section:AddTextbox(data)
                data=data or {}
                local root=New("Frame",{Parent=list,BackgroundColor3=t.Surface2,BorderSizePixel=0,Size=UDim2.new(1,0,0,52)})
                Corner(root,9);Stroke(root,t.Stroke)
                local box=New("TextBox",{Parent=root,BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),
                    Size=UDim2.new(1,-24,1,0),Font=Enum.Font.Gotham,TextSize=12,TextColor3=t.Text,
                    PlaceholderColor3=t.Muted,PlaceholderText=data.Placeholder or "Enter text...",Text=data.Default or "",
                    ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left})
                box.FocusLost:Connect(function(enter) if data.Callback then data.Callback(box.Text,enter) end end)
                local c={Root=root,Name=data.Name or "Textbox",Searchable=true,TextBox=box};table.insert(self.Components,c);return c
            end

            function section:AddLabel(text)
                local l=New("TextLabel",{Parent=list,BackgroundTransparency=1,Size=UDim2.new(1,0,0,24),
                    Font=Enum.Font.Gotham,TextSize=11,TextColor3=t.Muted,TextXAlignment=Enum.TextXAlignment.Left,Text=text})
                return l
            end

            return section
        end

        tab.Indicator=indicator;tab.Label=label;tab.Button=button;tab.Page=page
        button.MouseButton1Click:Connect(function() tab:Activate() end)
        table.insert(self.Tabs,tab)
        if #self.Tabs==1 then tab:Activate() end
        return tab
    end

    function self:Toggle()
        self.Gui.Enabled = not self.Gui.Enabled
    end

    function self:Destroy()
        if self.Gui then self.Gui:Destroy() end
    end

    function self:CreateDialog(data)
        data=data or {}
        local overlay=New("Frame",{Parent=self.Gui,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.45,
            Size=UDim2.fromScale(1,1),ZIndex=100})
        local box=New("Frame",{Parent=overlay,BackgroundColor3=t.Surface,AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(360,190),ZIndex=101})
        Corner(box,14);Stroke(box,t.Stroke)
        New("TextLabel",{Parent=box,BackgroundTransparency=1,Position=UDim2.fromOffset(20,20),
            Size=UDim2.new(1,-40,0,24),Font=Enum.Font.GothamBold,TextSize=15,TextColor3=t.Text,
            TextXAlignment=Enum.TextXAlignment.Left,Text=data.Title or "Confirm"})
        New("TextLabel",{Parent=box,BackgroundTransparency=1,Position=UDim2.fromOffset(20,52),
            Size=UDim2.new(1,-40,0,60),Font=Enum.Font.Gotham,TextSize=12,TextColor3=t.Muted,
            TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Text=data.Content or ""})
        local yes=New("TextButton",{Parent=box,BackgroundColor3=t.Accent,Position=UDim2.new(1,-140,1,-52),
            Size=UDim2.fromOffset(120,38),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1),
            Text=data.ConfirmText or "Confirm",AutoButtonColor=false});Corner(yes,9);Ripple(yes)
        yes.MouseButton1Click:Connect(function() if data.Callback then data.Callback(true) end overlay:Destroy() end)
        return overlay
    end

    self:Notify({Title="Welcome",Content=(config.Title or "ArioUI").." loaded successfully.",Duration=3})
    return self
end

ArioUI.Themes = Themes
return ArioUI
