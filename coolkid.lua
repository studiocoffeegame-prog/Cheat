-- ══════════════════════════════════════════════════════════════
-- COOLKID X v5.0 ULTRA BUILDER + STUDIO EXPLORER + SCRIPT EDITOR
-- + PLAYER TARGET SYSTEM + NEW TOOLS
-- ══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
end)

-- Cleanup
if PlayerGui:FindFirstChild("CoolKidX_V5") then PlayerGui.CoolKidX_V5:Destroy() end
if Lighting:FindFirstChild("CKX_Blur") then Lighting.CKX_Blur:Destroy() end
for _, obj in pairs(workspace:GetChildren()) do
    if tostring(obj.Name):sub(1, 6) == "GIZMO_" then obj:Destroy() end
end

local blur = Instance.new("BlurEffect")
blur.Name = "CKX_Blur"; blur.Size = 0; blur.Parent = Lighting
TweenService:Create(blur, TweenInfo.new(0.5), {Size = 8}):Play()

local gui = Instance.new("ScreenGui")
gui.Name = "CoolKidX_V5"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = PlayerGui

-- COLORS
local C = {
    bg = Color3.fromRGB(12, 12, 16), sidebar = Color3.fromRGB(8, 8, 12),
    card = Color3.fromRGB(22, 22, 28), cardHover = Color3.fromRGB(30, 30, 40),
    accent = Color3.fromRGB(0, 255, 180), accent2 = Color3.fromRGB(120, 0, 255),
    red = Color3.fromRGB(255, 50, 70), orange = Color3.fromRGB(255, 140, 0),
    yellow = Color3.fromRGB(255, 220, 0), blue = Color3.fromRGB(0, 120, 255),
    green = Color3.fromRGB(0, 255, 80), text = Color3.fromRGB(220, 220, 230),
    textDim = Color3.fromRGB(120, 120, 140), toggleOn = Color3.fromRGB(0, 255, 180),
    toggleOff = Color3.fromRGB(60, 60, 70), inputBg = Color3.fromRGB(18, 18, 24),
    statusBar = Color3.fromRGB(6, 6, 10), gizmoRed = Color3.fromRGB(255, 60, 60),
    gizmoGreen = Color3.fromRGB(60, 255, 60), gizmoBlue = Color3.fromRGB(60, 100, 255),
    explorerBg = Color3.fromRGB(38, 38, 42), explorerHover = Color3.fromRGB(55, 55, 65),
    explorerSelected = Color3.fromRGB(0, 100, 160), explorerHeader = Color3.fromRGB(30, 30, 35),
    propBg = Color3.fromRGB(28, 28, 33),
    editorBg = Color3.fromRGB(14, 17, 22), editorLine = Color3.fromRGB(20, 24, 30),
    editorKeyword = Color3.fromRGB(197, 134, 192), editorString = Color3.fromRGB(206, 145, 120),
    editorComment = Color3.fromRGB(106, 153, 85), editorNumber = Color3.fromRGB(181, 206, 168),
    targetBg = Color3.fromRGB(25, 18, 35),
}

-- CLASS ICONS
local classIcons = {
    Workspace="🌍", Model="📦", Part="🧱", WedgePart="🔺", TrussPart="🪜",
    UnionOperation="🔷", MeshPart="🔶", Script="📜", LocalScript="📄", ModuleScript="📋",
    RemoteEvent="📡", RemoteFunction="🔁", BindableEvent="🔔", StringValue="📝",
    NumberValue="🔢", BoolValue="✅", IntValue="🔢", Folder="📁", Frame="⬜",
    TextLabel="🔤", TextButton="🖱", ImageLabel="🖼", ScreenGui="🖥", BillboardGui="📢",
    SurfaceGui="🟦", Sound="🔊", Animation="🎬", Humanoid="🧍", HumanoidRootPart="⚙️",
    Camera="🎥", Lighting="💡", Atmosphere="🌫", Sky="🌤", SpawnLocation="🚩", Tool="🔧",
    Fire="🔥", Smoke="💨", Sparkles="✨", Explosion="💥", PointLight="💡",
    SurfaceLight="🔦", SpotLight="🔦", BodyVelocity="⚡", BodyGyro="🌀",
    Attachment="📌", WeldConstraint="🔩", HingeConstraint="🚪", RopeConstraint="🪢",
    SpringConstraint="🔗", SelectionBox="🟩", Highlight="✨", ParticleEmitter="🌟",
    ForceField="🛡", Players="👥", Player="👤", ReplicatedStorage="🔄",
    ServerStorage="🗄", ServerScriptService="⚙️", StarterGui="🖥", StarterPack="🎒",
    StarterPlayer="👤", Teams="🏳", SoundService="🔊", Chat="💬", Default="📄",
}
local function getIcon(obj) return classIcons[obj.ClassName] or classIcons.Default end
local function getClassColor(obj)
    local cn = obj.ClassName
    if cn:find("Script") then return Color3.fromRGB(255, 200, 80)
    elseif cn:find("Part") or cn:find("Union") or cn:find("Mesh") then return Color3.fromRGB(100, 180, 255)
    elseif cn == "Model" or cn == "Folder" then return Color3.fromRGB(255, 200, 100)
    elseif cn:find("Gui") or cn:find("Frame") or cn:find("Label") or cn:find("Button") then return Color3.fromRGB(180, 130, 255)
    elseif cn:find("Remote") or cn:find("Bindable") then return Color3.fromRGB(255, 100, 100)
    elseif cn:find("Sound") or cn == "SoundService" then return Color3.fromRGB(100, 255, 180)
    elseif cn:find("Light") or cn == "Lighting" then return Color3.fromRGB(255, 255, 100)
    elseif cn:find("Constraint") or cn:find("Weld") then return Color3.fromRGB(255, 150, 50)
    else return Color3.fromRGB(200, 200, 210) end
end

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"; MainFrame.BackgroundColor3 = C.bg
MainFrame.BorderSizePixel = 0; MainFrame.ClipsDescendants = true
MainFrame.BackgroundTransparency = 1
MainFrame.Size = UDim2.new(0, 1060, 0, 0)
MainFrame.Position = UDim2.new(0.5, -530, 0.5, 0); MainFrame.Parent = gui
task.wait(0.1)
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 1060, 0, 640), Position = UDim2.new(0.5, -530, 0.5, -320),
    BackgroundTransparency = 0
}):Play()
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = C.accent; mainStroke.Thickness = 1.5; mainStroke.Transparency = 0.5
task.spawn(function()
    while MainFrame and MainFrame.Parent do
        TweenService:Create(mainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency=0.2}):Play()
        task.wait(2)
        TweenService:Create(mainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency=0.7}):Play()
        task.wait(2)
    end
end)

-- DRAG
local dragging, dragInput, dragStart, startPos
local DragZone = Instance.new("Frame")
DragZone.Size = UDim2.new(1, 0, 0, 45); DragZone.BackgroundTransparency = 1; DragZone.Parent = MainFrame
DragZone.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
DragZone.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- TITLE BAR
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 45); TitleBar.BackgroundColor3 = Color3.fromRGB(8, 8, 11); TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)
local fix = Instance.new("Frame", TitleBar); fix.Size = UDim2.new(1,0,0,15); fix.Position = UDim2.new(0,0,1,-15)
fix.BackgroundColor3 = Color3.fromRGB(8,8,11); fix.BorderSizePixel = 0
local logo = Instance.new("TextLabel", TitleBar); logo.Size = UDim2.new(0,40,0,40); logo.Position = UDim2.new(0,10,0,2)
logo.BackgroundTransparency = 1; logo.Text = "⚡"; logo.TextSize = 24
local title = Instance.new("TextLabel", TitleBar); title.Size = UDim2.new(0,300,1,0); title.Position = UDim2.new(0,48,0,0)
title.BackgroundTransparency = 1; title.Text = "COOLKID X"; title.TextColor3 = C.accent
title.TextSize = 20; title.Font = Enum.Font.GothamBlack; title.TextXAlignment = Enum.TextXAlignment.Left
local sub = Instance.new("TextLabel", TitleBar); sub.Size = UDim2.new(0,400,1,0); sub.Position = UDim2.new(0,195,0,2)
sub.BackgroundTransparency = 1; sub.Text = "v5.0 | EXPLORER + SCRIPT EDITOR + TARGET SYSTEM"
sub.TextColor3 = C.accent2; sub.TextSize = 10; sub.Font = Enum.Font.GothamBold; sub.TextXAlignment = Enum.TextXAlignment.Left

local function makeTopBtn(txt, pos, col, cb)
    local btn = Instance.new("TextButton", TitleBar); btn.Size = UDim2.new(0,30,0,30); btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(30,30,38); btn.Text = txt; btn.TextColor3 = col
    btn.TextSize = 16; btn.Font = Enum.Font.GothamBold; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=col, TextColor3=Color3.new(0,0,0)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(30,30,38), TextColor3=col}):Play() end)
    btn.MouseButton1Click:Connect(cb)
end
makeTopBtn("—", UDim2.new(1,-75,0,8), C.orange, function()
    local t = TweenService:Create(MainFrame, TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In), {Size=UDim2.new(0,1060,0,45)})
    t:Play(); t.Completed:Wait(); task.wait(2)
    TweenService:Create(MainFrame, TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(0,1060,0,640)}):Play()
end)
makeTopBtn("✕", UDim2.new(1,-40,0,8), C.red, function()
    TweenService:Create(blur, TweenInfo.new(0.3), {Size=0}):Play()
    local t = TweenService:Create(MainFrame, TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In), {Size=UDim2.new(0,1060,0,0), BackgroundTransparency=1})
    t:Play(); t.Completed:Connect(function() gui:Destroy(); blur:Destroy() end)
end)

-- STATUS BAR
local statusBar = Instance.new("Frame", MainFrame); statusBar.Size = UDim2.new(1,0,0,25)
statusBar.Position = UDim2.new(0,0,1,-25); statusBar.BackgroundColor3 = C.statusBar; statusBar.BorderSizePixel = 0
local statusLbl = Instance.new("TextLabel", statusBar); statusLbl.Size = UDim2.new(1,-20,1,0)
statusLbl.Position = UDim2.new(0,10,0,0); statusLbl.BackgroundTransparency = 1
statusLbl.Text = "● Ready — v5.0 + Script Editor + Target System"
statusLbl.TextColor3 = C.accent; statusLbl.TextSize = 11; statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
local function setStatus(msg) statusLbl.Text = "● " .. msg end

-- SIDEBAR
local sidebar = Instance.new("Frame", MainFrame); sidebar.Size = UDim2.new(0,185,1,-70)
sidebar.Position = UDim2.new(0,0,0,45); sidebar.BackgroundColor3 = C.sidebar; sidebar.BorderSizePixel = 0
local sideScroll = Instance.new("ScrollingFrame", sidebar); sideScroll.Size = UDim2.new(1,0,1,-30)
sideScroll.Position = UDim2.new(0,0,0,5); sideScroll.BackgroundTransparency = 1
sideScroll.ScrollBarThickness = 3; sideScroll.ScrollBarImageColor3 = C.accent
sideScroll.CanvasSize = UDim2.new(0,0,0,0); sideScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local sideLayout = Instance.new("UIListLayout", sideScroll); sideLayout.Padding = UDim.new(0,3); sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
local sidePad = Instance.new("UIPadding", sideScroll); sidePad.PaddingLeft = UDim.new(0,6)
local userLbl = Instance.new("TextLabel", sidebar); userLbl.Size = UDim2.new(1,0,0,25); userLbl.Position = UDim2.new(0,0,1,-25)
userLbl.BackgroundTransparency = 1; userLbl.Text = "👤 " .. player.Name
userLbl.TextColor3 = C.textDim; userLbl.TextSize = 10; userLbl.Font = Enum.Font.Gotham

-- CONTENT AREA
local contentArea = Instance.new("Frame", MainFrame); contentArea.Size = UDim2.new(1,-190,1,-70)
contentArea.Position = UDim2.new(0,188,0,45); contentArea.BackgroundTransparency = 1

-- TAB SYSTEM
local currentTab, allTabs, tabOrder = nil, {}, 0
local compCount = 0
local function createTab(icon, name)
    tabOrder = tabOrder + 1; local order = tabOrder
    local btn = Instance.new("TextButton", sideScroll); btn.Size = UDim2.new(1,-12,0,34)
    btn.BackgroundColor3 = Color3.fromRGB(16,16,22); btn.Text = ""; btn.AutoButtonColor = false; btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    local ic = Instance.new("TextLabel", btn); ic.Size = UDim2.new(0,28,1,0); ic.Position = UDim2.new(0,6,0,0)
    ic.BackgroundTransparency = 1; ic.Text = icon; ic.TextSize = 14
    local nm = Instance.new("TextLabel", btn); nm.Size = UDim2.new(1,-40,1,0); nm.Position = UDim2.new(0,36,0,0)
    nm.BackgroundTransparency = 1; nm.Text = name; nm.TextColor3 = C.textDim
    nm.TextSize = 11; nm.Font = Enum.Font.GothamSemibold; nm.TextXAlignment = Enum.TextXAlignment.Left
    local ind = Instance.new("Frame", btn); ind.Size = UDim2.new(0,3,0,0); ind.Position = UDim2.new(0,0,0.5,0)
    ind.AnchorPoint = Vector2.new(0,0.5); ind.BackgroundColor3 = C.accent; ind.BorderSizePixel = 0
    Instance.new("UICorner", ind).CornerRadius = UDim.new(0,2)
    local content = Instance.new("ScrollingFrame", contentArea); content.Size = UDim2.new(1,-8,1,-25)
    content.Position = UDim2.new(0,4,0,4); content.BackgroundTransparency = 1
    content.ScrollBarThickness = 4; content.ScrollBarImageColor3 = C.accent; content.Visible = false
    content.CanvasSize = UDim2.new(0,0,0,0); content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local cl = Instance.new("UIListLayout", content); cl.Padding = UDim.new(0,5); cl.SortOrder = Enum.SortOrder.LayoutOrder
    local cp = Instance.new("UIPadding", content); cp.PaddingLeft = UDim.new(0,6); cp.PaddingRight = UDim.new(0,6)
    cp.PaddingTop = UDim.new(0,4)
    btn.MouseEnter:Connect(function() if currentTab~=content then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(25,25,35)}):Play() end end)
    btn.MouseLeave:Connect(function() if currentTab~=content then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(16,16,22)}):Play() end end)
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(allTabs) do
            t.content.Visible = false
            TweenService:Create(t.btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(16,16,22)}):Play()
            TweenService:Create(t.ind, TweenInfo.new(0.15), {Size=UDim2.new(0,3,0,0)}):Play()
            t.lbl.TextColor3 = C.textDim
        end
        content.Visible = true; currentTab = content
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=C.accent}):Play()
        TweenService:Create(ind, TweenInfo.new(0.25,Enum.EasingStyle.Back), {Size=UDim2.new(0,3,0,18)}):Play()
        nm.TextColor3 = Color3.new(0,0,0); setStatus(name)
    end)
    table.insert(allTabs, {btn=btn, content=content, ind=ind, lbl=nm}); return content
end

-- UI BUILDERS
local function addSection(p, t)
    compCount += 1; local l = Instance.new("TextLabel", p); l.Name = "S"..compCount
    l.Size = UDim2.new(1,0,0,24); l.BackgroundTransparency = 1; l.Text = " ▸ "..t
    l.TextColor3 = C.accent; l.TextSize = 12; l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left
end
local function addBtn(p, t, col, cb)
    compCount += 1; local b = Instance.new("TextButton", p); b.Name = "B"..compCount
    b.Size = UDim2.new(1,0,0,34); b.BackgroundColor3 = col or C.card; b.Text = ""; b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(40,40,50); s.Thickness = 1; s.Transparency = 0.5
    local l = Instance.new("TextLabel", b); l.Size = UDim2.new(1,-16,1,0); l.Position = UDim2.new(0,10,0,0)
    l.BackgroundTransparency = 1; l.Text = t; l.TextColor3 = C.text; l.TextSize = 11; l.Font = Enum.Font.GothamSemibold; l.TextXAlignment = Enum.TextXAlignment.Left
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=C.cardHover}):Play(); TweenService:Create(s, TweenInfo.new(0.1), {Color=C.accent, Transparency=0.2}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=col or C.card}):Play(); TweenService:Create(s, TweenInfo.new(0.1), {Color=Color3.fromRGB(40,40,50), Transparency=0.5}):Play() end)
    b.MouseButton1Click:Connect(function() TweenService:Create(b, TweenInfo.new(0.06), {BackgroundColor3=C.accent}):Play(); task.wait(0.08); TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3=col or C.card}):Play(); if cb then pcall(cb) end end)
end
local function addToggle(p, t, def, cb)
    compCount += 1; local on = def or false; local f = Instance.new("Frame", p); f.Size = UDim2.new(1,0,0,34); f.BackgroundColor3 = C.card; Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1,-60,1,0); l.Position = UDim2.new(0,10,0,0); l.BackgroundTransparency = 1; l.Text = t; l.TextColor3 = C.text; l.TextSize = 11; l.Font = Enum.Font.GothamSemibold; l.TextXAlignment = Enum.TextXAlignment.Left
    local bg = Instance.new("TextButton", f); bg.Size = UDim2.new(0,42,0,20); bg.Position = UDim2.new(1,-52,0.5,-10); bg.BackgroundColor3 = on and C.toggleOn or C.toggleOff; bg.Text = ""; bg.AutoButtonColor = false; Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local c = Instance.new("Frame", bg); c.Size = UDim2.new(0,16,0,16); c.Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); c.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", c).CornerRadius = UDim.new(1,0)
    bg.MouseButton1Click:Connect(function() on = not on; TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3=on and C.toggleOn or C.toggleOff}):Play(); TweenService:Create(c, TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play(); if cb then pcall(cb, on) end end)
end
local function addInput(p, ph, bt, cb)
    compCount += 1; local f = Instance.new("Frame", p); f.Size = UDim2.new(1,0,0,36); f.BackgroundColor3 = C.card; Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    local box = Instance.new("TextBox", f); box.Size = UDim2.new(1,-100,0,26); box.Position = UDim2.new(0,8,0,5); box.BackgroundColor3 = C.inputBg; box.PlaceholderText = ph; box.PlaceholderColor3 = C.textDim; box.Text = ""; box.TextColor3 = C.text; box.TextSize = 11; box.Font = Enum.Font.Gotham; box.ClearTextOnFocus = false; Instance.new("UICorner", box).CornerRadius = UDim.new(0,7)
    local eb = Instance.new("TextButton", f); eb.Size = UDim2.new(0,80,0,26); eb.Position = UDim2.new(1,-88,0,5); eb.BackgroundColor3 = C.accent; eb.Text = bt; eb.TextColor3 = Color3.new(0,0,0); eb.TextSize = 11; eb.Font = Enum.Font.GothamBold; Instance.new("UICorner", eb).CornerRadius = UDim.new(0,7)
    eb.MouseButton1Click:Connect(function() if cb then pcall(cb, box.Text) end end); return box
end
local function addSlider(p, t, mn, mx, def, cb)
    compCount += 1; local val = def or mn; local f = Instance.new("Frame", p); f.Size = UDim2.new(1,0,0,48); f.BackgroundColor3 = C.card; Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1,-55,0,20); l.Position = UDim2.new(0,10,0,3); l.BackgroundTransparency = 1; l.Text = t; l.TextColor3 = C.text; l.TextSize = 11; l.Font = Enum.Font.GothamSemibold; l.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", f); vl.Size = UDim2.new(0,50,0,20); vl.Position = UDim2.new(1,-58,0,3); vl.BackgroundTransparency = 1; vl.Text = tostring(val); vl.TextColor3 = C.accent; vl.TextSize = 11; vl.Font = Enum.Font.GothamBold; vl.TextXAlignment = Enum.TextXAlignment.Right
    local tr = Instance.new("Frame", f); tr.Size = UDim2.new(1,-20,0,5); tr.Position = UDim2.new(0,10,0,34); tr.BackgroundColor3 = Color3.fromRGB(40,40,55); Instance.new("UICorner", tr).CornerRadius = UDim.new(1,0)
    local fl = Instance.new("Frame", tr); fl.Size = UDim2.new((val-mn)/math.max(mx-mn,1),0,1,0); fl.BackgroundColor3 = C.accent; Instance.new("UICorner", fl).CornerRadius = UDim.new(1,0)
    local sliding = false
    tr.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
    UIS.InputChanged:Connect(function(inp) if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then local rel = math.clamp((inp.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1); val = math.floor(mn+(mx-mn)*rel); fl.Size = UDim2.new(rel,0,1,0); vl.Text = tostring(val); if cb then pcall(cb, val) end end end)
end
local function addSpacer(p, h) compCount += 1; local s = Instance.new("Frame", p); s.Size = UDim2.new(1,0,0,h or 4); s.BackgroundTransparency = 1 end

-- ══════════════════════════════════════════════════════════════
-- GIZMO SYSTEM
-- ══════════════════════════════════════════════════════════════
local selectedPart = nil; local gizmoMode = "move"
local gizmoFolder = Instance.new("Folder", workspace); gizmoFolder.Name = "GIZMO_Handles"
local activeGizmos = {}; local gizmoConnections = {}; local selectionBox = nil
local buildHistory = {}; local selectionEnabled = false; local gridSnap = 1

local function clearGizmos()
    for _, g in pairs(activeGizmos) do if g and g.Parent then g:Destroy() end end; activeGizmos = {}
    for _, conn in pairs(gizmoConnections) do if typeof(conn)=="RBXScriptConnection" then conn:Disconnect() end end; gizmoConnections = {}
end

local function createMoveGizmos(part)
    clearGizmos(); if not part then return end
    local axes = {{name="X",dir=Vector3.new(1,0,0),col=C.gizmoRed},{name="Y",dir=Vector3.new(0,1,0),col=C.gizmoGreen},{name="Z",dir=Vector3.new(0,0,1),col=C.gizmoBlue}}
    for _, ax in pairs(axes) do
        local shaft = Instance.new("Part"); shaft.Name="GIZMO_MS_"..ax.name; shaft.Size=Vector3.new(0.15,3,0.15)
        shaft.Anchored=true; shaft.CanCollide=false; shaft.Material=Enum.Material.Neon; shaft.Color=ax.col; shaft.Parent=gizmoFolder; table.insert(activeGizmos,shaft)
        local head = Instance.new("Part"); head.Name="GIZMO_MH_"..ax.name; head.Size=Vector3.new(0.5,0.8,0.5); head.Shape=Enum.PartType.Ball
        head.Anchored=true; head.CanCollide=false; head.Material=Enum.Material.Neon; head.Color=ax.col; head.Parent=gizmoFolder; table.insert(activeGizmos,head)
        local function updatePos()
            if part and part.Parent then local bp=part.Position
                if ax.name=="Y" then shaft.CFrame=CFrame.new(bp+ax.dir*1.5); head.CFrame=CFrame.new(bp+ax.dir*3.2)
                elseif ax.name=="X" then shaft.CFrame=CFrame.new(bp+ax.dir*1.5)*CFrame.Angles(0,0,math.rad(90)); head.CFrame=CFrame.new(bp+ax.dir*3.2)
                else shaft.CFrame=CFrame.new(bp+ax.dir*1.5)*CFrame.Angles(math.rad(90),0,0); head.CFrame=CFrame.new(bp+ax.dir*3.2) end end end
        updatePos(); table.insert(gizmoConnections, RunService.Heartbeat:Connect(updatePos))
        local cd = Instance.new("ClickDetector", head); cd.MaxActivationDistance=100
        local isDrag, lastMP = false, nil
        cd.MouseButton1Down:Connect(function() isDrag=true; lastMP=mouse.Hit.Position end)
        local dc = mouse.Move:Connect(function() if isDrag and part and part.Parent then local cur=mouse.Hit.Position; local delta=cur-(lastMP or cur); local mv=delta:Dot(ax.dir)*ax.dir; if gridSnap>0 then mv=Vector3.new(math.floor(mv.X/gridSnap+0.5)*gridSnap,math.floor(mv.Y/gridSnap+0.5)*gridSnap,math.floor(mv.Z/gridSnap+0.5)*gridSnap) end; if mv.Magnitude>0.01 then part.Position=part.Position+mv; lastMP=cur end end end)
        table.insert(gizmoConnections, dc)
        UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then isDrag=false end end)
    end
end

local function updateGizmo()
    if not selectedPart then clearGizmos(); return end
    if gizmoMode == "move" then createMoveGizmos(selectedPart) end
end

local function selectPart(part)
    if selectionBox then selectionBox:Destroy() end; selectedPart = part
    if part then
        selectionBox = Instance.new("SelectionBox"); selectionBox.Name="GIZMO_SelBox"
        selectionBox.LineThickness=0.05; selectionBox.Color3=C.accent
        selectionBox.SurfaceTransparency=0.85; selectionBox.SurfaceColor3=C.accent
        selectionBox.Adornee=part; selectionBox.Parent=gui; updateGizmo()
        setStatus("Selected: "..part.Name)
    else clearGizmos() end
end

-- SHAPE BUILDER
local shapeFolder = Instance.new("Folder", workspace); shapeFolder.Name = "CKX_ShapeBuilder"
local function getToolHandle()
    local tool = character:FindFirstChildWhichIsA("Tool")
    if tool then return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart") end; return nil
end

local function buildShape(shapeName, count, radius, animated)
    local handle = getToolHandle(); if not handle then setStatus("Hold a Tool first!"); return end
    local folder = Instance.new("Folder", shapeFolder); folder.Name="Shape_"..shapeName.."_"..tick(); local clones = {}
    if shapeName=="ring" then
        for i=1,count do local angle=(i/count)*math.pi*2; local clone=handle:Clone(); clone.Anchored=true; clone.CanCollide=false; clone.Size=handle.Size*0.6; clone.Material=Enum.Material.Neon; clone.BrickColor=BrickColor.Random(); clone.Position=character.HumanoidRootPart.Position+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius); clone.Parent=folder; table.insert(clones, {part=clone,angle=angle}) end
    elseif shapeName=="sphere" then
        local phi=(1+math.sqrt(5))/2; for i=1,count do local theta=2*math.pi*i/phi; local phiA=math.acos(1-2*(i-0.5)/count); local clone=handle:Clone(); clone.Anchored=true; clone.CanCollide=false; clone.Size=handle.Size*0.6; clone.Material=Enum.Material.Neon; clone.BrickColor=BrickColor.Random(); clone.Position=character.HumanoidRootPart.Position+Vector3.new(math.cos(theta)*math.sin(phiA)*radius,math.cos(phiA)*radius,math.sin(theta)*math.sin(phiA)*radius); clone.Parent=folder; table.insert(clones, {part=clone,angle=theta,phi=phiA}) end
    elseif shapeName=="tornado" then
        for i=1,count do local angle=(i/count)*math.pi*8; local h2=(i/count)*radius*4; local r2=(i/count)*radius; local clone=handle:Clone(); clone.Anchored=true; clone.CanCollide=false; clone.Size=handle.Size*0.4; clone.Material=Enum.Material.Neon; clone.BrickColor=BrickColor.Random(); clone.Position=character.HumanoidRootPart.Position+Vector3.new(math.cos(angle)*r2,h2,math.sin(angle)*r2); clone.Parent=folder; table.insert(clones, {part=clone,angle=angle,r=r2,h=h2}) end
    elseif shapeName=="helix" then
        for i=1,count do local angle=(i/count)*math.pi*6; local h2=(i/count)*radius*3; local clone=handle:Clone(); clone.Anchored=true; clone.CanCollide=false; clone.Size=handle.Size*0.5; clone.Material=Enum.Material.Neon; clone.BrickColor=BrickColor.Random(); clone.Position=character.HumanoidRootPart.Position+Vector3.new(math.cos(angle)*radius,h2-radius,math.sin(angle)*radius); clone.Parent=folder; table.insert(clones, {part=clone,angle=angle}) end
    end
    if animated then
        task.spawn(function() local t2=0; while folder and folder.Parent do t2+=0.03; for _,data in pairs(clones) do if data.part and data.part.Parent then if shapeName=="ring" then local a=data.angle+t2; data.part.Position=character.HumanoidRootPart.Position+Vector3.new(math.cos(a)*radius,math.sin(t2*2)*2,math.sin(a)*radius) elseif shapeName=="sphere" then local theta=data.angle+t2; data.part.Position=character.HumanoidRootPart.Position+Vector3.new(math.cos(theta)*math.sin(data.phi)*radius,math.cos(data.phi)*radius,math.sin(theta)*math.sin(data.phi)*radius) elseif shapeName=="tornado" then local a=data.angle+t2*3; data.part.Position=character.HumanoidRootPart.Position+Vector3.new(math.cos(a)*data.r,data.h,math.sin(a)*data.r) end end end; task.wait(0.03) end end)
    end
    setStatus(shapeName:upper().." built! ("..#clones.." clones)")
end

-- ══════════════════════════════════════════════════════════════
-- ★★★ PLAYER TARGET SYSTEM ★★★
-- ══════════════════════════════════════════════════════════════
local targetedPlayer = nil
local targetHighlight = nil
local targetConnections = {}

local function clearTargetHighlight()
    if targetHighlight then targetHighlight:Destroy(); targetHighlight = nil end
end

local function setTargetPlayer(p)
    clearTargetHighlight()
    targetedPlayer = p
    if not p then setStatus("Target cleared"); return end
    if p.Character then
        targetHighlight = Instance.new("Highlight")
        targetHighlight.FillColor = Color3.fromRGB(120, 0, 255)
        targetHighlight.OutlineColor = Color3.fromRGB(0, 255, 180)
        targetHighlight.FillTransparency = 0.5
        targetHighlight.Adornee = p.Character
        targetHighlight.Parent = gui
    end
    setStatus("🎯 Target: " .. p.Name)
end

-- ══════════════════════════════════════════════════════════════
-- ★★★ SCRIPT EDITOR WINDOW ★★★
-- ══════════════════════════════════════════════════════════════
local scriptEditorWindow = Instance.new("Frame", gui)
scriptEditorWindow.Name = "ScriptEditorWindow"
scriptEditorWindow.Size = UDim2.new(0, 700, 0, 540)
scriptEditorWindow.Position = UDim2.new(0.5, -350, 0.5, -270)
scriptEditorWindow.BackgroundColor3 = C.editorBg
scriptEditorWindow.BorderSizePixel = 0; scriptEditorWindow.Visible = false; scriptEditorWindow.ZIndex = 15
Instance.new("UICorner", scriptEditorWindow).CornerRadius = UDim.new(0, 10)
local edStroke = Instance.new("UIStroke", scriptEditorWindow)
edStroke.Color = C.accent2; edStroke.Thickness = 1.5; edStroke.Transparency = 0.3

-- Editor Title Bar
local edTitleBar = Instance.new("Frame", scriptEditorWindow)
edTitleBar.Size = UDim2.new(1,0,0,34); edTitleBar.BackgroundColor3 = Color3.fromRGB(10,10,16)
edTitleBar.BorderSizePixel = 0; edTitleBar.ZIndex = 16
Instance.new("UICorner", edTitleBar).CornerRadius = UDim.new(0,10)
local edTitleFix = Instance.new("Frame", edTitleBar); edTitleFix.Size = UDim2.new(1,0,0,15)
edTitleFix.Position = UDim2.new(0,0,1,-15); edTitleFix.BackgroundColor3 = Color3.fromRGB(10,10,16); edTitleFix.BorderSizePixel = 0

local edTitle = Instance.new("TextLabel", edTitleBar); edTitle.Size = UDim2.new(1,-80,1,0)
edTitle.Position = UDim2.new(0,34,0,0); edTitle.BackgroundTransparency = 1
edTitle.Text = "📜 Script Editor — (no script loaded)"; edTitle.TextColor3 = C.accent
edTitle.TextSize = 12; edTitle.Font = Enum.Font.GothamBold; edTitle.TextXAlignment = Enum.TextXAlignment.Left; edTitle.ZIndex = 17

local edIcon = Instance.new("TextLabel", edTitleBar); edIcon.Size = UDim2.new(0,30,1,0)
edIcon.Position = UDim2.new(0,4,0,0); edIcon.BackgroundTransparency = 1; edIcon.Text = "📝"
edIcon.TextSize = 16; edIcon.ZIndex = 17

-- Editor drag
local edDrag, edDragStart, edDragPos = false, nil, nil
edTitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        edDrag=true; edDragStart=inp.Position; edDragPos=scriptEditorWindow.Position
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then edDrag=false end end)
    end
end)
UIS.InputChanged:Connect(function(inp)
    if edDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-edDragStart
        scriptEditorWindow.Position=UDim2.new(edDragPos.X.Scale,edDragPos.X.Offset+d.X,edDragPos.Y.Scale,edDragPos.Y.Offset+d.Y)
    end
end)

-- Editor Close
local edClose = Instance.new("TextButton", edTitleBar); edClose.Size = UDim2.new(0,24,0,24)
edClose.Position = UDim2.new(1,-28,0,5); edClose.BackgroundColor3 = C.red; edClose.Text = "✕"
edClose.TextColor3 = Color3.new(1,1,1); edClose.TextSize = 12; edClose.Font = Enum.Font.GothamBold; edClose.ZIndex = 18
Instance.new("UICorner", edClose).CornerRadius = UDim.new(0,6)
edClose.MouseButton1Click:Connect(function() scriptEditorWindow.Visible = false end)

-- Toolbar
local edToolbar = Instance.new("Frame", scriptEditorWindow); edToolbar.Size = UDim2.new(1,0,0,32)
edToolbar.Position = UDim2.new(0,0,0,34); edToolbar.BackgroundColor3 = Color3.fromRGB(16,16,22)
edToolbar.BorderSizePixel = 0; edToolbar.ZIndex = 16
local edToolLayout = Instance.new("UIListLayout", edToolbar); edToolLayout.FillDirection = Enum.FillDirection.Horizontal
edToolLayout.Padding = UDim.new(0,4); edToolLayout.VerticalAlignment = Enum.VerticalAlignment.Center; edToolLayout.SortOrder = Enum.SortOrder.LayoutOrder
local edToolPad = Instance.new("UIPadding", edToolbar); edToolPad.PaddingLeft = UDim.new(0,6)

local function makeEdBtn(txt, col, order, cb)
    local b = Instance.new("TextButton", edToolbar); b.Size = UDim2.new(0,0,0,24)
    b.AutomaticSize = Enum.AutomaticSize.X; b.BackgroundColor3 = col or Color3.fromRGB(25,25,35)
    b.Text = " "..txt.." "; b.TextColor3 = C.text; b.TextSize = 11; b.Font = Enum.Font.GothamSemibold
    b.AutoButtonColor = false; b.LayoutOrder = order; b.ZIndex = 17
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=C.cardHover}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=col or Color3.fromRGB(25,25,35)}):Play() end)
    b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
    return b
end

-- File tabs bar
local edTabsBar = Instance.new("Frame", scriptEditorWindow); edTabsBar.Size = UDim2.new(1,0,0,28)
edTabsBar.Position = UDim2.new(0,0,0,66); edTabsBar.BackgroundColor3 = Color3.fromRGB(12,12,18)
edTabsBar.BorderSizePixel = 0; edTabsBar.ZIndex = 16; edTabsBar.ClipsDescendants = true
local edTabsLayout = Instance.new("UIListLayout", edTabsBar); edTabsLayout.FillDirection = Enum.FillDirection.Horizontal
edTabsLayout.Padding = UDim.new(0,2); edTabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center; edTabsLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Main editor split: line numbers + code
local edMain = Instance.new("Frame", scriptEditorWindow); edMain.Size = UDim2.new(1,-8,1,-140)
edMain.Position = UDim2.new(0,4,0,98); edMain.BackgroundColor3 = Color3.fromRGB(14,17,22)
edMain.BorderSizePixel = 0; edMain.ZIndex = 16; edMain.ClipsDescendants = true
Instance.new("UICorner", edMain).CornerRadius = UDim.new(0,8)

-- Line numbers panel
local edLineNums = Instance.new("Frame", edMain); edLineNums.Size = UDim2.new(0,40,1,0)
edLineNums.BackgroundColor3 = Color3.fromRGB(10,12,17); edLineNums.BorderSizePixel = 0; edLineNums.ZIndex = 17
local edLineScroll = Instance.new("ScrollingFrame", edLineNums); edLineScroll.Size = UDim2.new(1,0,1,0)
edLineScroll.BackgroundTransparency = 1; edLineScroll.ScrollBarThickness = 0
edLineScroll.CanvasSize = UDim2.new(0,0,0,0); edLineScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; edLineScroll.ZIndex = 17
local edLineLayout = Instance.new("UIListLayout", edLineScroll); edLineLayout.Padding = UDim.new(0,0); edLineLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Code display area
local edCodeScroll = Instance.new("ScrollingFrame", edMain); edCodeScroll.Size = UDim2.new(1,-42,1,0)
edCodeScroll.Position = UDim2.new(0,42,0,0); edCodeScroll.BackgroundTransparency = 1
edCodeScroll.ScrollBarThickness = 5; edCodeScroll.ScrollBarImageColor3 = C.accent2
edCodeScroll.CanvasSize = UDim2.new(0,0,0,0); edCodeScroll.AutomaticCanvasSize = Enum.AutomaticSize.XY; edCodeScroll.ZIndex = 17

local edCodeBox = Instance.new("TextBox", edCodeScroll); edCodeBox.Size = UDim2.new(1,-8,1,0)
edCodeBox.Position = UDim2.new(0,4,0,0); edCodeBox.BackgroundTransparency = 1
edCodeBox.Text = "-- No script loaded\n-- Open the Explorer, click a Script, then use\n-- 'Open in Editor' from the right-click menu"
edCodeBox.TextColor3 = Color3.fromRGB(180, 200, 220); edCodeBox.TextSize = 12; edCodeBox.Font = Enum.Font.Code
edCodeBox.MultiLine = true; edCodeBox.TextXAlignment = Enum.TextXAlignment.Left; edCodeBox.TextYAlignment = Enum.TextYAlignment.Top
edCodeBox.ClearTextOnFocus = false; edCodeBox.ZIndex = 18; edCodeBox.TextWrapped = false

-- Bottom bar
local edBottomBar = Instance.new("Frame", scriptEditorWindow); edBottomBar.Size = UDim2.new(1,0,0,32)
edBottomBar.Position = UDim2.new(0,0,1,-32); edBottomBar.BackgroundColor3 = Color3.fromRGB(8,8,14)
edBottomBar.BorderSizePixel = 0; edBottomBar.ZIndex = 16
local edBottomLbl = Instance.new("TextLabel", edBottomBar); edBottomLbl.Size = UDim2.new(0.6,0,1,0)
edBottomLbl.Position = UDim2.new(0,8,0,0); edBottomLbl.BackgroundTransparency = 1
edBottomLbl.Text = "Ln 1, Col 1 | Lua 5.1 | UTF-8"; edBottomLbl.TextColor3 = C.textDim
edBottomLbl.TextSize = 10; edBottomLbl.Font = Enum.Font.Gotham; edBottomLbl.TextXAlignment = Enum.TextXAlignment.Left; edBottomLbl.ZIndex = 17
local edCharCount = Instance.new("TextLabel", edBottomBar); edCharCount.Size = UDim2.new(0.4,0,1,0)
edCharCount.Position = UDim2.new(0.6,-8,0,0); edCharCount.BackgroundTransparency = 1
edCharCount.Text = "0 chars | 0 lines"; edCharCount.TextColor3 = C.textDim
edCharCount.TextSize = 10; edCharCount.Font = Enum.Font.Gotham; edCharCount.TextXAlignment = Enum.TextXAlignment.Right; edCharCount.ZIndex = 17

-- Search bar in editor
local edSearchBar = Instance.new("Frame", scriptEditorWindow); edSearchBar.Size = UDim2.new(1,0,0,30)
edSearchBar.Position = UDim2.new(0,0,0,66+28); edSearchBar.BackgroundColor3 = Color3.fromRGB(16,16,26)
edSearchBar.BorderSizePixel = 0; edSearchBar.ZIndex = 16; edSearchBar.Visible = false
local edSearchBox = Instance.new("TextBox", edSearchBar); edSearchBox.Size = UDim2.new(0.5,-4,0,22)
edSearchBox.Position = UDim2.new(0,4,0,4); edSearchBox.BackgroundColor3 = C.inputBg
edSearchBox.PlaceholderText = "🔎 Find..."; edSearchBox.PlaceholderColor3 = C.textDim; edSearchBox.Text = ""
edSearchBox.TextColor3 = C.text; edSearchBox.TextSize = 11; edSearchBox.Font = Enum.Font.Gotham
edSearchBox.ClearTextOnFocus = false; edSearchBox.ZIndex = 17
Instance.new("UICorner", edSearchBox).CornerRadius = UDim.new(0,6)
local edReplaceBox = Instance.new("TextBox", edSearchBar); edReplaceBox.Size = UDim2.new(0.3,-4,0,22)
edReplaceBox.Position = UDim2.new(0.5,4,0,4); edReplaceBox.BackgroundColor3 = C.inputBg
edReplaceBox.PlaceholderText = "Replace..."; edReplaceBox.PlaceholderColor3 = C.textDim; edReplaceBox.Text = ""
edReplaceBox.TextColor3 = C.text; edReplaceBox.TextSize = 11; edReplaceBox.Font = Enum.Font.Gotham
edReplaceBox.ClearTextOnFocus = false; edReplaceBox.ZIndex = 17
Instance.new("UICorner", edReplaceBox).CornerRadius = UDim.new(0,6)
local edReplaceBtn = Instance.new("TextButton", edSearchBar); edReplaceBtn.Size = UDim2.new(0.2,-8,0,22)
edReplaceBtn.Position = UDim2.new(0.8,4,0,4); edReplaceBtn.BackgroundColor3 = C.accent
edReplaceBtn.Text = "Replace All"; edReplaceBtn.TextColor3 = Color3.new(0,0,0); edReplaceBtn.TextSize = 10
edReplaceBtn.Font = Enum.Font.GothamBold; edReplaceBtn.ZIndex = 17
Instance.new("UICorner", edReplaceBtn).CornerRadius = UDim.new(0,6)

-- Loaded scripts tabs system
local loadedScripts = {}
local currentEditorScript = nil
local edTabOrder = 0

local function updateLineNumbers(code)
    edLineScroll:ClearAllChildren(); Instance.new("UIListLayout", edLineScroll).Padding = UDim.new(0,0)
    local lines = 0; for _ in (code.."\n"):gmatch("[^\n]*\n") do lines += 1 end
    for i = 1, math.max(lines, 1) do
        local lbl = Instance.new("TextLabel", edLineScroll); lbl.Size = UDim2.new(1,0,0,16)
        lbl.BackgroundTransparency = 1; lbl.Text = tostring(i); lbl.TextColor3 = Color3.fromRGB(80,90,110)
        lbl.TextSize = 11; lbl.Font = Enum.Font.Code; lbl.TextXAlignment = Enum.TextXAlignment.Right; lbl.ZIndex = 18
        local pad = Instance.new("UIPadding", lbl); pad.PaddingRight = UDim.new(0,4)
        lbl.LayoutOrder = i
    end
    edLineScroll.CanvasSize = UDim2.new(0,0,0,lines*16+10)
end

local function openScriptInEditor(scriptObj)
    if not scriptObj then return end
    pcall(function()
        local src = scriptObj.Source or "-- Source not accessible"
        local lineCount = select(2, src:gsub('\n', '\n')) + 1
        edCodeBox.Text = src
        updateLineNumbers(src)
        edTitle.Text = "📜 " .. scriptObj.ClassName .. " — " .. scriptObj:GetFullName()
        edCharCount.Text = #src .. " chars | " .. lineCount .. " lines"
        currentEditorScript = scriptObj
        scriptEditorWindow.Visible = true
        -- Add tab
        edTabOrder += 1
        local tab = Instance.new("TextButton", edTabsBar); tab.Size = UDim2.new(0,0,1,0)
        tab.AutomaticSize = Enum.AutomaticSize.X; tab.BackgroundColor3 = Color3.fromRGB(20,20,32)
        tab.Text = " "..getIcon(scriptObj).." "..scriptObj.Name.." ✕ "; tab.TextColor3 = C.accent
        tab.TextSize = 10; tab.Font = Enum.Font.GothamSemibold; tab.AutoButtonColor = false; tab.ZIndex = 17
        tab.LayoutOrder = edTabOrder
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0,6)
        tab.MouseButton1Click:Connect(function()
            pcall(function()
                local s = scriptObj.Source; edCodeBox.Text = s; updateLineNumbers(s)
                edTitle.Text = "📜 "..scriptObj.ClassName.." — "..scriptObj:GetFullName()
                edCharCount.Text = #s.." chars | "..select(2, s:gsub('\n','\n'))+1 .." lines"
            end)
        end)
        setStatus("📜 Opened: " .. scriptObj.Name .. " (" .. #src .. " chars)")
    end)
end

-- Sync line number scroll with code scroll
edCodeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    edLineScroll.CanvasPosition = Vector2.new(0, edCodeScroll.CanvasPosition.Y)
end)
edCodeBox:GetPropertyChangedSignal("Text"):Connect(function()
    local t = edCodeBox.Text; updateLineNumbers(t)
    local lines = select(2, t:gsub('\n','\n'))+1
    edCharCount.Text = #t.." chars | "..lines.." lines"
end)

-- Toolbar buttons
makeEdBtn("💾 Copy All", Color3.fromRGB(0,40,60), 1, function()
    if edCodeBox.Text ~= "" then
        print("=== COPIED SCRIPT SOURCE ===\n" .. edCodeBox.Text .. "\n=== END ===")
        setStatus("Source copied to console!")
    end
end)
makeEdBtn("🔍 Find", Color3.fromRGB(35,30,15), 2, function()
    edSearchBar.Visible = not edSearchBar.Visible
end)
makeEdBtn("▶ Run", Color3.fromRGB(0,60,20), 3, function()
    local code = edCodeBox.Text
    local ok, err = pcall(loadstring(code))
    if ok then setStatus("✅ Script executed!") else setStatus("❌ Error: " .. tostring(err)) end
end)
makeEdBtn("📋 Paste Clipboard", Color3.fromRGB(30,20,50), 4, function()
    edCodeBox.Text = (edCodeBox.Text or "")
    setStatus("Edit the code box directly!")
end)
makeEdBtn("🗑 Clear", C.red, 5, function()
    edCodeBox.Text = ""; updateLineNumbers(""); setStatus("Editor cleared")
end)
makeEdBtn("⬆ Save to Script", Color3.fromRGB(0,50,30), 6, function()
    if currentEditorScript then
        pcall(function()
            currentEditorScript.Source = edCodeBox.Text
            setStatus("✅ Saved to " .. currentEditorScript.Name)
        end)
    else setStatus("No script loaded!") end
end)

-- Replace All
edReplaceBtn.MouseButton1Click:Connect(function()
    local find = edSearchBox.Text; local rep = edReplaceBox.Text
    if find == "" then return end
    edCodeBox.Text = edCodeBox.Text:gsub(find:gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%0"), rep)
    setStatus("Replaced all occurrences of '" .. find .. "'")
end)

-- ══════════════════════════════════════════════════════════════
-- EXPLORER WINDOW (from v4, preserved + enhanced)
-- ══════════════════════════════════════════════════════════════
local explorerWindow = Instance.new("Frame", gui)
explorerWindow.Name = "ExplorerWindow"; explorerWindow.Size = UDim2.new(0,320,0,580)
explorerWindow.Position = UDim2.new(1,-340,0.5,-290); explorerWindow.BackgroundColor3 = C.explorerBg
explorerWindow.BorderSizePixel = 0; explorerWindow.Visible = false; explorerWindow.ZIndex = 10
Instance.new("UICorner", explorerWindow).CornerRadius = UDim.new(0,10)
local expStroke = Instance.new("UIStroke", explorerWindow); expStroke.Color = C.accent; expStroke.Thickness = 1.5; expStroke.Transparency = 0.4

local expHeader = Instance.new("Frame", explorerWindow); expHeader.Size = UDim2.new(1,0,0,32); expHeader.BackgroundColor3 = C.explorerHeader; expHeader.BorderSizePixel = 0; expHeader.ZIndex = 11
Instance.new("UICorner", expHeader).CornerRadius = UDim.new(0,10)
local expHeaderFix = Instance.new("Frame", expHeader); expHeaderFix.Size = UDim2.new(1,0,0,15); expHeaderFix.Position = UDim2.new(0,0,1,-15); expHeaderFix.BackgroundColor3 = C.explorerHeader; expHeaderFix.BorderSizePixel = 0; expHeaderFix.ZIndex = 11
local expTitle = Instance.new("TextLabel", expHeader); expTitle.Size = UDim2.new(1,-80,1,0); expTitle.Position = UDim2.new(0,8,0,0); expTitle.BackgroundTransparency = 1; expTitle.Text = "🔍 Explorer | Properties"; expTitle.TextColor3 = C.accent; expTitle.TextSize = 12; expTitle.Font = Enum.Font.GothamBold; expTitle.TextXAlignment = Enum.TextXAlignment.Left; expTitle.ZIndex = 12
local expClose = Instance.new("TextButton", expHeader); expClose.Size = UDim2.new(0,24,0,24); expClose.Position = UDim2.new(1,-28,0,4); expClose.BackgroundColor3 = C.red; expClose.Text = "✕"; expClose.TextColor3 = Color3.new(1,1,1); expClose.TextSize = 12; expClose.Font = Enum.Font.GothamBold; expClose.ZIndex = 12; Instance.new("UICorner", expClose).CornerRadius = UDim.new(0,6)
expClose.MouseButton1Click:Connect(function() explorerWindow.Visible = false end)

local expSearchFrame = Instance.new("Frame", explorerWindow); expSearchFrame.Size = UDim2.new(1,-8,0,26); expSearchFrame.Position = UDim2.new(0,4,0,36); expSearchFrame.BackgroundColor3 = C.inputBg; expSearchFrame.ZIndex = 11; Instance.new("UICorner", expSearchFrame).CornerRadius = UDim.new(0,7)
local expSearch = Instance.new("TextBox", expSearchFrame); expSearch.Size = UDim2.new(1,-8,1,0); expSearch.Position = UDim2.new(0,4,0,0); expSearch.BackgroundTransparency = 1; expSearch.PlaceholderText = "🔎 Search..."; expSearch.PlaceholderColor3 = C.textDim; expSearch.Text = ""; expSearch.TextColor3 = C.text; expSearch.TextSize = 11; expSearch.Font = Enum.Font.Gotham; expSearch.ClearTextOnFocus = false; expSearch.ZIndex = 12

local expTreeFrame = Instance.new("Frame", explorerWindow); expTreeFrame.Size = UDim2.new(1,-4,0,290); expTreeFrame.Position = UDim2.new(0,2,0,66); expTreeFrame.BackgroundColor3 = Color3.fromRGB(32,32,38); expTreeFrame.ZIndex = 11; Instance.new("UICorner", expTreeFrame).CornerRadius = UDim.new(0,8)
local expTree = Instance.new("ScrollingFrame", expTreeFrame); expTree.Size = UDim2.new(1,0,1,0); expTree.BackgroundTransparency = 1; expTree.ScrollBarThickness = 4; expTree.ScrollBarImageColor3 = C.accent; expTree.CanvasSize = UDim2.new(0,0,0,0); expTree.AutomaticCanvasSize = Enum.AutomaticSize.Y; expTree.ZIndex = 12

local expDivider = Instance.new("TextLabel", explorerWindow); expDivider.Size = UDim2.new(1,0,0,18); expDivider.Position = UDim2.new(0,0,0,360); expDivider.BackgroundColor3 = C.explorerHeader; expDivider.Text = " 📋 PROPERTIES"; expDivider.TextColor3 = C.accent; expDivider.TextSize = 11; expDivider.Font = Enum.Font.GothamBold; expDivider.TextXAlignment = Enum.TextXAlignment.Left; expDivider.ZIndex = 11; expDivider.BorderSizePixel = 0
local expPropFrame = Instance.new("Frame", explorerWindow); expPropFrame.Size = UDim2.new(1,-4,0,185); expPropFrame.Position = UDim2.new(0,2,0,380); expPropFrame.BackgroundColor3 = C.propBg; expPropFrame.ZIndex = 11; Instance.new("UICorner", expPropFrame).CornerRadius = UDim.new(0,8)
local expProps = Instance.new("ScrollingFrame", expPropFrame); expProps.Size = UDim2.new(1,0,1,0); expProps.BackgroundTransparency = 1; expProps.ScrollBarThickness = 4; expProps.ScrollBarImageColor3 = C.accent; expProps.CanvasSize = UDim2.new(0,0,0,0); expProps.AutomaticCanvasSize = Enum.AutomaticSize.Y; expProps.ZIndex = 12

local expDrag2, expDragStart2, expDragPos2 = false, nil, nil
expHeader.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then expDrag2=true; expDragStart2=inp.Position; expDragPos2=explorerWindow.Position; inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then expDrag2=false end end) end end)
UIS.InputChanged:Connect(function(inp) if expDrag2 and inp.UserInputType==Enum.UserInputType.MouseMovement then local d=inp.Position-expDragStart2; explorerWindow.Position=UDim2.new(expDragPos2.X.Scale,expDragPos2.X.Offset+d.X,expDragPos2.Y.Scale,expDragPos2.Y.Offset+d.Y) end end)

local explorerSelected = nil; local expandedNodes = {}

local function buildPropertiesPanel(obj)
    expProps:ClearAllChildren(); local layout=Instance.new("UIListLayout",expProps); layout.Padding=UDim.new(0,0); layout.SortOrder=Enum.SortOrder.LayoutOrder
    if not obj then return end
    local header=Instance.new("Frame",expProps); header.Size=UDim2.new(1,0,0,26); header.BackgroundColor3=Color3.fromRGB(20,20,28); header.ZIndex=13
    local headerLbl=Instance.new("TextLabel",header); headerLbl.Size=UDim2.new(1,-4,1,0); headerLbl.Position=UDim2.new(0,4,0,0); headerLbl.BackgroundTransparency=1; headerLbl.Text=getIcon(obj).." "..obj.ClassName.." \""..obj.Name.."\""; headerLbl.TextColor3=getClassColor(obj); headerLbl.TextSize=11; headerLbl.Font=Enum.Font.GothamBold; headerLbl.TextXAlignment=Enum.TextXAlignment.Left; headerLbl.ZIndex=14
    local props={}
    table.insert(props,{"Name",tostring(obj.Name)}); table.insert(props,{"ClassName",tostring(obj.ClassName)}); table.insert(props,{"Parent",obj.Parent and obj.Parent.Name or "nil"})
    local childCount=0; for _ in pairs(obj:GetChildren()) do childCount+=1 end; table.insert(props,{"Children",tostring(childCount)})
    if obj:IsA("BasePart") then table.insert(props,{"Position",string.format("%.2f,%.2f,%.2f",obj.Position.X,obj.Position.Y,obj.Position.Z)}); table.insert(props,{"Size",string.format("%.2f,%.2f,%.2f",obj.Size.X,obj.Size.Y,obj.Size.Z)}); table.insert(props,{"Anchored",tostring(obj.Anchored)}); table.insert(props,{"CanCollide",tostring(obj.CanCollide)}); table.insert(props,{"Transparency",string.format("%.2f",obj.Transparency)}); table.insert(props,{"Material",tostring(obj.Material)}); table.insert(props,{"Color",string.format("R:%.0f G:%.0f B:%.0f",obj.Color.R*255,obj.Color.G*255,obj.Color.B*255)}) end
    if obj:IsA("BaseScript") or obj:IsA("ModuleScript") then local ok,src=pcall(function() return obj.Source end); if ok then table.insert(props,{"SourceLines",tostring(select(2,src:gsub('\n','\n'))+1)}); table.insert(props,{"SourceLength",tostring(#src).." chars"}) end; if obj:IsA("BaseScript") then table.insert(props,{"Disabled",tostring(obj.Disabled)}) end end
    if obj:IsA("Humanoid") then table.insert(props,{"Health",string.format("%.0f/%.0f",obj.Health,obj.MaxHealth)}); table.insert(props,{"WalkSpeed",tostring(obj.WalkSpeed)}); table.insert(props,{"JumpPower",tostring(obj.JumpPower)}) end
    table.insert(props,{"FullPath",obj:GetFullName()})
    local rowOrder=0
    for _, prop in pairs(props) do
        rowOrder+=1; local rowBg=rowOrder%2==0 and Color3.fromRGB(32,32,40) or Color3.fromRGB(26,26,34)
        local row=Instance.new("Frame",expProps); row.Size=UDim2.new(1,0,0,20); row.BackgroundColor3=rowBg; row.ZIndex=13; row.LayoutOrder=rowOrder+10
        local keyLbl=Instance.new("TextLabel",row); keyLbl.Size=UDim2.new(0.42,0,1,0); keyLbl.Position=UDim2.new(0,4,0,0); keyLbl.BackgroundTransparency=1; keyLbl.Text=prop[1]; keyLbl.TextColor3=Color3.fromRGB(160,160,200); keyLbl.TextSize=10; keyLbl.Font=Enum.Font.Gotham; keyLbl.TextXAlignment=Enum.TextXAlignment.Left; keyLbl.ZIndex=14
        local valLbl=Instance.new("TextLabel",row); valLbl.Size=UDim2.new(0.58,-4,1,0); valLbl.Position=UDim2.new(0.42,0,0,0); valLbl.BackgroundTransparency=1; valLbl.Text=tostring(prop[2]); valLbl.TextColor3=Color3.fromRGB(200,230,200); valLbl.TextSize=10; valLbl.Font=Enum.Font.Gotham; valLbl.TextXAlignment=Enum.TextXAlignment.Left; valLbl.ZIndex=14; valLbl.ClipsDescendants=true
        row.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then setStatus("Prop: "..prop[1].."="..prop[2]); print("[CKX] "..prop[1].." = "..prop[2]) end end)
    end
end

local nodeOrder = 0
local function buildTreeNode(obj, depth, parentFrame)
    nodeOrder += 1; local order = nodeOrder; local hasChildren = #obj:GetChildren() > 0; local indent = depth*14
    local nodeFrame=Instance.new("Frame", expTree); nodeFrame.Size=UDim2.new(1,0,0,22); nodeFrame.BackgroundTransparency=1; nodeFrame.ZIndex=12; nodeFrame.LayoutOrder=order
    local hoverBg=Instance.new("Frame",nodeFrame); hoverBg.Size=UDim2.new(1,0,1,0); hoverBg.BackgroundColor3=Color3.fromRGB(50,50,65); hoverBg.BackgroundTransparency=1; hoverBg.ZIndex=12; Instance.new("UICorner",hoverBg).CornerRadius=UDim.new(0,4)
    local arrowBtn=Instance.new("TextButton",nodeFrame); arrowBtn.Size=UDim2.new(0,14,0,22); arrowBtn.Position=UDim2.new(0,indent,0,0); arrowBtn.BackgroundTransparency=1; arrowBtn.Text=hasChildren and (expandedNodes[obj] and "▾" or "▸") or " "; arrowBtn.TextColor3=C.textDim; arrowBtn.TextSize=11; arrowBtn.Font=Enum.Font.GothamBold; arrowBtn.ZIndex=14
    local iconLbl=Instance.new("TextLabel",nodeFrame); iconLbl.Size=UDim2.new(0,18,0,22); iconLbl.Position=UDim2.new(0,indent+16,0,0); iconLbl.BackgroundTransparency=1; iconLbl.Text=getIcon(obj); iconLbl.TextSize=12; iconLbl.ZIndex=14
    local nameLbl=Instance.new("TextLabel",nodeFrame); nameLbl.Size=UDim2.new(1,-(indent+36),0,22); nameLbl.Position=UDim2.new(0,indent+36,0,0); nameLbl.BackgroundTransparency=1; nameLbl.Text=obj.Name; nameLbl.TextColor3=getClassColor(obj); nameLbl.TextSize=11; nameLbl.Font=Enum.Font.Gotham; nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.ZIndex=14
    local classBadge=Instance.new("TextLabel",nodeFrame); classBadge.Size=UDim2.new(0,80,0,22); classBadge.Position=UDim2.new(1,-82,0,0); classBadge.BackgroundTransparency=1; classBadge.Text=obj.ClassName; classBadge.TextColor3=C.textDim; classBadge.TextSize=9; classBadge.Font=Enum.Font.Gotham; classBadge.TextXAlignment=Enum.TextXAlignment.Right; classBadge.TextTruncate=Enum.TextTruncate.AtEnd; classBadge.ZIndex=14
    local childContainer=Instance.new("Frame",expTree); childContainer.Size=UDim2.new(1,0,0,0); childContainer.BackgroundTransparency=1; childContainer.ZIndex=12; childContainer.LayoutOrder=order+0.5; childContainer.Visible=expandedNodes[obj] or false
    local childLayout=Instance.new("UIListLayout",childContainer); childLayout.Padding=UDim.new(0,1); childLayout.SortOrder=Enum.SortOrder.LayoutOrder
    local rowBtn=Instance.new("TextButton",nodeFrame); rowBtn.Size=UDim2.new(1,0,1,0); rowBtn.BackgroundTransparency=1; rowBtn.Text=""; rowBtn.ZIndex=15
    rowBtn.MouseEnter:Connect(function() TweenService:Create(hoverBg,TweenInfo.new(0.1),{BackgroundTransparency=0.7}):Play() end)
    rowBtn.MouseLeave:Connect(function() if explorerSelected~=obj then TweenService:Create(hoverBg,TweenInfo.new(0.1),{BackgroundTransparency=1}):Play() end end)
    rowBtn.MouseButton1Click:Connect(function()
        explorerSelected=obj; hoverBg.BackgroundTransparency=0.5; hoverBg.BackgroundColor3=C.explorerSelected
        buildPropertiesPanel(obj); setStatus("Selected: "..obj.ClassName.." \""..obj.Name.."\"")
        if obj:IsA("BaseScript") or obj:IsA("ModuleScript") then
            pcall(function() print("=== SOURCE: "..obj:GetFullName().." ==="); print(obj.Source); print("=== END ===") end)
        end
        if obj:IsA("BasePart") then selectPart(obj) end
    end)
    local childrenBuilt=false
    local function buildChildren()
        if childrenBuilt then return end; childrenBuilt=true
        local children=obj:GetChildren(); table.sort(children, function(a,b) local aC=a:IsA("Model")or a:IsA("Folder"); local bC=b:IsA("Model")or b:IsA("Folder"); if aC~=bC then return aC end; return a.Name<b.Name end)
        for _, child in pairs(children) do pcall(function() buildTreeNode(child, depth+1, childContainer) end) end
    end
    arrowBtn.MouseButton1Click:Connect(function()
        if not hasChildren then return end; expandedNodes[obj]=not expandedNodes[obj]; arrowBtn.Text=expandedNodes[obj] and "▾" or "▸"; childContainer.Visible=expandedNodes[obj]
        if expandedNodes[obj] then buildChildren() end
        task.wait(0.05); childContainer.Size=UDim2.new(1,0,0,childLayout.AbsoluteContentSize.Y)
    end)
    -- RIGHT CLICK: context menu with "Open in Editor"
    rowBtn.MouseButton2Click:Connect(function()
        explorerSelected=obj
        -- Show context menu
    end)
end

local browsableServices = {
    {name="🌍 Workspace",service=workspace}, {name="💡 Lighting",service=Lighting},
    {name="🔄 ReplicatedStorage",service=game:GetService("ReplicatedStorage")},
    {name="🖥 StarterGui",service=game:GetService("StarterGui")},
    {name="🎒 StarterPack",service=game:GetService("StarterPack")},
    {name="👤 StarterPlayer",service=game:GetService("StarterPlayer")},
    {name="🔊 SoundService",service=SoundService}, {name="👥 Players",service=Players},
    {name="🗄 ServerStorage",service=(function() local ok,s=pcall(function() return game:GetService("ServerStorage") end); return ok and s or nil end)()},
    {name="⚙️ ServerScriptService",service=(function() local ok,s=pcall(function() return game:GetService("ServerScriptService") end); return ok and s or nil end)()},
}

local function buildExplorerTree()
    expTree:ClearAllChildren(); local treeLayout=Instance.new("UIListLayout",expTree); treeLayout.Padding=UDim.new(0,1); treeLayout.SortOrder=Enum.SortOrder.LayoutOrder; nodeOrder=0; expandedNodes={}
    for _, svc in pairs(browsableServices) do
        if svc.service then
            pcall(function()
                nodeOrder+=1
                local svcHeader=Instance.new("TextButton",expTree); svcHeader.Size=UDim2.new(1,0,0,26); svcHeader.BackgroundColor3=Color3.fromRGB(20,20,28); svcHeader.Text=""; svcHeader.AutoButtonColor=false; svcHeader.LayoutOrder=nodeOrder; svcHeader.ZIndex=12; Instance.new("UICorner",svcHeader).CornerRadius=UDim.new(0,6)
                local svcLbl=Instance.new("TextLabel",svcHeader); svcLbl.Size=UDim2.new(1,-8,1,0); svcLbl.Position=UDim2.new(0,6,0,0); svcLbl.BackgroundTransparency=1; svcLbl.Text=svc.name.." ("..tostring(#svc.service:GetChildren())..")"; svcLbl.TextColor3=C.accent; svcLbl.TextSize=11; svcLbl.Font=Enum.Font.GothamBold; svcLbl.TextXAlignment=Enum.TextXAlignment.Left; svcLbl.ZIndex=13
                local svcArrow=Instance.new("TextLabel",svcHeader); svcArrow.Size=UDim2.new(0,20,1,0); svcArrow.Position=UDim2.new(1,-22,0,0); svcArrow.BackgroundTransparency=1; svcArrow.Text="▸"; svcArrow.TextColor3=C.textDim; svcArrow.TextSize=11; svcArrow.Font=Enum.Font.GothamBold; svcArrow.ZIndex=13
                nodeOrder+=1
                local svcChildren=Instance.new("Frame",expTree); svcChildren.Size=UDim2.new(1,0,0,0); svcChildren.BackgroundTransparency=1; svcChildren.ZIndex=12; svcChildren.LayoutOrder=nodeOrder; svcChildren.Visible=false
                local svcChildLayout=Instance.new("UIListLayout",svcChildren); svcChildLayout.Padding=UDim.new(0,1); svcChildLayout.SortOrder=Enum.SortOrder.LayoutOrder
                local built,isOpen=false,false
                svcHeader.MouseButton1Click:Connect(function()
                    isOpen=not isOpen; svcChildren.Visible=isOpen; svcArrow.Text=isOpen and "▾" or "▸"
                    if isOpen and not built then built=true
                        local children=svc.service:GetChildren(); table.sort(children,function(a,b) local aC=a:IsA("Model")or a:IsA("Folder"); local bC=b:IsA("Model")or b:IsA("Folder"); if aC~=bC then return aC end; return a.Name<b.Name end)
                        for _, child in pairs(children) do pcall(function() buildTreeNode(child,1,svcChildren) end) end
                    end
                    task.wait(0.05); svcChildren.Size=UDim2.new(1,0,0,isOpen and svcChildLayout.AbsoluteContentSize.Y or 0)
                end)
            end)
        end
    end
end

local expRefreshBtn=Instance.new("TextButton",explorerWindow); expRefreshBtn.Size=UDim2.new(0,70,0,22); expRefreshBtn.Position=UDim2.new(1,-75,0,38); expRefreshBtn.BackgroundColor3=C.accent; expRefreshBtn.Text="🔄 Refresh"; expRefreshBtn.TextColor3=Color3.new(0,0,0); expRefreshBtn.TextSize=10; expRefreshBtn.Font=Enum.Font.GothamBold; expRefreshBtn.ZIndex=12; Instance.new("UICorner",expRefreshBtn).CornerRadius=UDim.new(0,6)
expRefreshBtn.MouseButton1Click:Connect(function() buildExplorerTree(); setStatus("Refreshed!") end)

-- Context menu
local contextMenu=Instance.new("Frame",gui); contextMenu.Size=UDim2.new(0,175,0,0); contextMenu.BackgroundColor3=Color3.fromRGB(22,22,32); contextMenu.Visible=false; contextMenu.ZIndex=20; Instance.new("UICorner",contextMenu).CornerRadius=UDim.new(0,8)
local ctxStroke=Instance.new("UIStroke",contextMenu); ctxStroke.Color=C.accent; ctxStroke.Thickness=1; ctxStroke.Transparency=0.5; ctxStroke.ZIndex=20
local ctxLayout=Instance.new("UIListLayout",contextMenu); ctxLayout.Padding=UDim.new(0,2); ctxLayout.SortOrder=Enum.SortOrder.LayoutOrder
local ctxPad=Instance.new("UIPadding",contextMenu); ctxPad.PaddingLeft=UDim.new(0,4); ctxPad.PaddingRight=UDim.new(0,4); ctxPad.PaddingTop=UDim.new(0,4); ctxPad.PaddingBottom=UDim.new(0,4)
local ctxOrder=0
local function addCtxItem(text, col, cb)
    ctxOrder+=1; local b=Instance.new("TextButton",contextMenu); b.Size=UDim2.new(1,0,0,24); b.LayoutOrder=ctxOrder; b.BackgroundColor3=col or Color3.fromRGB(35,35,45); b.Text=text; b.TextColor3=C.text; b.TextSize=11; b.Font=Enum.Font.GothamSemibold; b.AutoButtonColor=false; b.ZIndex=21; Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(50,50,70) end); b.MouseLeave:Connect(function() b.BackgroundColor3=col or Color3.fromRGB(35,35,45) end)
    b.MouseButton1Click:Connect(function() contextMenu.Visible=false; if cb then pcall(cb) end end)
    contextMenu.Size=UDim2.new(0,175,0,ctxLayout.AbsoluteContentSize.Y+8)
end
addCtxItem("📜 Open in Script Editor", Color3.fromRGB(30,20,50), function() if explorerSelected and (explorerSelected:IsA("BaseScript") or explorerSelected:IsA("ModuleScript")) then openScriptInEditor(explorerSelected) else setStatus("Select a Script first!") end end)
addCtxItem("📋 Copy Name", nil, function() if explorerSelected then print("Name: "..explorerSelected.Name); setStatus("Name: "..explorerSelected.Name) end end)
addCtxItem("🔗 Copy Full Path", nil, function() if explorerSelected then print("Path: "..explorerSelected:GetFullName()); setStatus("Path copied!") end end)
addCtxItem("📜 Print Source", nil, function() if explorerSelected and (explorerSelected:IsA("BaseScript") or explorerSelected:IsA("ModuleScript")) then pcall(function() print(explorerSelected.Source) end); setStatus("Source in console!") end end)
addCtxItem("🎯 Select in Gizmo", nil, function() if explorerSelected and explorerSelected:IsA("BasePart") then selectPart(explorerSelected) end end)
addCtxItem("📍 TP Here", nil, function() if explorerSelected and explorerSelected:IsA("BasePart") and character.PrimaryPart then character.PrimaryPart.CFrame=CFrame.new(explorerSelected.Position+Vector3.new(0,5,0)) end end)
addCtxItem("📋 Duplicate", nil, function() if explorerSelected and explorerSelected.Parent then local c=explorerSelected:Clone(); c.Parent=explorerSelected.Parent; if c:IsA("BasePart") then c.Position=c.Position+Vector3.new(4,0,0) end; buildExplorerTree() end end)
addCtxItem("🔒 Toggle Anchor", nil, function() if explorerSelected and explorerSelected:IsA("BasePart") then explorerSelected.Anchored=not explorerSelected.Anchored end end)
addCtxItem("🔇 Disable Script", nil, function() if explorerSelected and explorerSelected:IsA("BaseScript") then explorerSelected.Disabled=not explorerSelected.Disabled; setStatus(explorerSelected.Disabled and "DISABLED" or "ENABLED") end end)
addCtxItem("🗑 Destroy", C.red, function() if explorerSelected then local n=explorerSelected.Name; pcall(function() explorerSelected:Destroy() end); buildExplorerTree(); setStatus("Destroyed: "..n) end end)

UIS.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then if contextMenu.Visible then task.wait(0.05); contextMenu.Visible=false end end
    if inp.UserInputType==Enum.UserInputType.MouseButton2 and explorerSelected then contextMenu.Position=UDim2.new(0,inp.Position.X,0,inp.Position.Y); contextMenu.Visible=true end
end)

explorerWindow:GetPropertyChangedSignal("Visible"):Connect(function() if explorerWindow.Visible then buildExplorerTree() end end)

-- ══════════════════════════════════════════════════════════════
-- CREATE ALL TABS
-- ══════════════════════════════════════════════════════════════
local tabHome = createTab("🏠", "Home")
local tabSelect = createTab("🎯", "Select")         -- NEW
local tabExplorer = createTab("🔍", "Explorer")
local tabScript = createTab("📜", "Script Editor")   -- NEW
local tabMovement = createTab("⚡", "Movement")
local tabBuilder = createTab("🏗", "Gizmo Builder")
local tabShapes = createTab("🌐", "Shape Builder")
local tabVisuals = createTab("👁", "Visuals & ESP")
local tabMorph = createTab("🧬", "Morph")
local tabTools = createTab("🔧", "Tools & Physics")
local tabEffects = createTab("🌈", "Effects")        -- NEW combined
local tabEmotes = createTab("💃", "Emotes & Anims")
local tabAdmin = createTab("⚙️", "Admin & World")

-- ══════════════════════════════════════════════════════════════
-- HOME TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabHome, "DASHBOARD v5.0")
local hCard=Instance.new("Frame",tabHome); hCard.Size=UDim2.new(1,0,0,145); hCard.BackgroundColor3=C.card; Instance.new("UICorner",hCard).CornerRadius=UDim.new(0,12)
local hText=Instance.new("TextLabel",hCard); hText.Size=UDim2.new(1,-14,1,-8); hText.Position=UDim2.new(0,7,0,4); hText.BackgroundTransparency=1; hText.RichText=true
hText.Text='<font color="#00FFB4"><b>Welcome '..player.Name..'</b></font>\n<font color="#888">Version:</font> <font color="#7800FF">5.0 — Script Editor + Target System</font>\n<font color="#FF9500">NEW:</font> <font color="#FFD700">📜 Script Editor — view, edit, run scripts</font>\n<font color="#FF9500">NEW:</font> <font color="#7800FF">🎯 Select Tab — apply effects on OTHER players</font>\n<font color="#FF9500">NEW:</font> <font color="#00FF88">🔫 Target Tool — click players to select them</font>\n<font color="#888">[F6]=Explorer | [F7]=Script Editor | [INSERT]=GUI</font>'
hText.TextSize=11; hText.Font=Enum.Font.Gotham; hText.TextXAlignment=Enum.TextXAlignment.Left; hText.TextYAlignment=Enum.TextYAlignment.Top; hText.TextColor3=C.text
addSpacer(tabHome,4)
addBtn(tabHome,"📋 List Players",nil,function() for _,p in pairs(Players:GetPlayers()) do print(p.Name,p.UserId) end end)
addBtn(tabHome,"💾 Print Position",nil,function() if character.PrimaryPart then print("Pos:",character.PrimaryPart.Position) end end)
addBtn(tabHome,"🔄 Refresh Character",nil,function() character=player.Character or player.CharacterAdded:Wait(); humanoid=character:WaitForChild("Humanoid"); setStatus("Refreshed") end)
addBtn(tabHome,"📜 Open Script Editor",nil,function() scriptEditorWindow.Visible=true end)
addBtn(tabHome,"🔍 Open Explorer",nil,function() explorerWindow.Visible=true; buildExplorerTree() end)

-- ══════════════════════════════════════════════════════════════
-- ★★★ SELECT TAB ★★★
-- ══════════════════════════════════════════════════════════════
addSection(tabSelect, "PLAYER SELECTION")

local selCard=Instance.new("Frame",tabSelect); selCard.Size=UDim2.new(1,0,0,80); selCard.BackgroundColor3=C.targetBg; Instance.new("UICorner",selCard).CornerRadius=UDim.new(0,12)
local selInstroke=Instance.new("UIStroke",selCard); selInstroke.Color=C.accent2; selInstroke.Thickness=1; selInstroke.Transparency=0.4
local selText=Instance.new("TextLabel",selCard); selText.Size=UDim2.new(1,-14,1,-8); selText.Position=UDim2.new(0,7,0,4); selText.BackgroundTransparency=1; selText.RichText=true
selText.Text='<font color="#7800FF"><b>🎯 TARGET SYSTEM</b></font>\n<font color="#888">Sélectionne un joueur → applique n\'importe quel\neffet sur lui depuis les boutons ci-dessous.</font>'
selText.TextSize=11; selText.Font=Enum.Font.Gotham; selText.TextXAlignment=Enum.TextXAlignment.Left; selText.TextYAlignment=Enum.TextYAlignment.Top; selText.TextColor3=C.text

addSpacer(tabSelect,5)

-- Current target display
local targetCard=Instance.new("Frame",tabSelect); targetCard.Size=UDim2.new(1,0,0,40); targetCard.BackgroundColor3=Color3.fromRGB(20,20,30); Instance.new("UICorner",targetCard).CornerRadius=UDim.new(0,10)
local targetStroke=Instance.new("UIStroke",targetCard); targetStroke.Color=C.accent2; targetStroke.Thickness=1; targetStroke.Transparency=0.4
local targetLbl=Instance.new("TextLabel",targetCard); targetLbl.Size=UDim2.new(1,-10,1,0); targetLbl.Position=UDim2.new(0,8,0,0); targetLbl.BackgroundTransparency=1
targetLbl.Text="🎯 Cible: Aucune"; targetLbl.TextColor3=C.textDim; targetLbl.TextSize=12; targetLbl.Font=Enum.Font.GothamBold; targetLbl.TextXAlignment=Enum.TextXAlignment.Left

local function updateTargetLabel()
    if targetedPlayer then
        targetLbl.Text="🎯 Cible: "..targetedPlayer.Name
        targetLbl.TextColor3=C.accent2
    else
        targetLbl.Text="🎯 Cible: Aucune"; targetLbl.TextColor3=C.textDim
    end
end

addSpacer(tabSelect,4)
addSection(tabSelect,"SÉLECTION MANUELLE")

-- Player selector buttons (auto-populated)
local playerListFrame=Instance.new("Frame",tabSelect); playerListFrame.Size=UDim2.new(1,0,0,0); playerListFrame.BackgroundTransparency=1; playerListFrame.AutomaticSize=Enum.AutomaticSize.Y
local playerListLayout=Instance.new("UIListLayout",playerListFrame); playerListLayout.Padding=UDim.new(0,4); playerListLayout.SortOrder=Enum.SortOrder.LayoutOrder

local function rebuildPlayerList()
    playerListFrame:ClearAllChildren(); Instance.new("UIListLayout",playerListFrame).Padding=UDim.new(0,4)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local rowH = 38
            local row=Instance.new("Frame",playerListFrame); row.Size=UDim2.new(1,0,0,rowH); row.BackgroundColor3=Color3.fromRGB(22,22,32); Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
            local rowStroke=Instance.new("UIStroke",row); rowStroke.Color=Color3.fromRGB(50,40,70); rowStroke.Thickness=1
            local avatar=Instance.new("TextLabel",row); avatar.Size=UDim2.new(0,32,0,32); avatar.Position=UDim2.new(0,4,0,3); avatar.BackgroundTransparency=1; avatar.Text="👤"; avatar.TextSize=20
            local nameLbl2=Instance.new("TextLabel",row); nameLbl2.Size=UDim2.new(0.6,0,1,0); nameLbl2.Position=UDim2.new(0,40,0,0); nameLbl2.BackgroundTransparency=1; nameLbl2.Text=p.Name; nameLbl2.TextColor3=C.text; nameLbl2.TextSize=12; nameLbl2.Font=Enum.Font.GothamBold; nameLbl2.TextXAlignment=Enum.TextXAlignment.Left
            local selectBtn=Instance.new("TextButton",row); selectBtn.Size=UDim2.new(0,75,0,26); selectBtn.Position=UDim2.new(1,-80,0,6); selectBtn.BackgroundColor3=C.accent2; selectBtn.Text="SELECT"; selectBtn.TextColor3=Color3.new(1,1,1); selectBtn.TextSize=10; selectBtn.Font=Enum.Font.GothamBold; selectBtn.AutoButtonColor=false; Instance.new("UICorner",selectBtn).CornerRadius=UDim.new(0,8)
            selectBtn.MouseButton1Click:Connect(function()
                setTargetPlayer(p); updateTargetLabel(); setStatus("🎯 Target set: "..p.Name)
                TweenService:Create(row,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(40,20,60)}):Play()
                task.wait(0.3); TweenService:Create(row,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(22,22,32)}):Play()
            end)
        end
    end
end
rebuildPlayerList()
addBtn(tabSelect,"🔄 Refresh Player List",nil,function() rebuildPlayerList(); setStatus("Player list refreshed") end)
addBtn(tabSelect,"❌ Clear Target",C.red,function() setTargetPlayer(nil); updateTargetLabel() end)

addSpacer(tabSelect,6)
addSection(tabSelect,"EFFETS SUR LA CIBLE")

local function getTarget() return targetedPlayer end
local function getTargetChar() return targetedPlayer and targetedPlayer.Character end
local function getTargetHRP() local c=getTargetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getTargetHum() local c=getTargetChar(); return c and c:FindFirstChildWhichIsA("Humanoid") end

-- Effects on target
addBtn(tabSelect,"💥 Exploser la cible",C.red,function()
    local hrp=getTargetHRP(); if not hrp then setStatus("Target ou character introuvable!"); return end
    local e=Instance.new("Explosion"); e.Position=hrp.Position; e.BlastRadius=12; e.BlastPressure=5e6; e.Parent=workspace
    setStatus("💥 Explosion sur "..getTarget().Name)
end)
addBtn(tabSelect,"🚀 Launcher la cible en l'air",nil,function()
    local hrp=getTargetHRP(); if not hrp then setStatus("Target introuvable!"); return end
    local bv=Instance.new("BodyVelocity",hrp); bv.Velocity=Vector3.new(0,250,0); bv.MaxForce=Vector3.new(0,9e9,0); Debris:AddItem(bv,0.4)
    setStatus("🚀 Launched: "..getTarget().Name)
end)
addBtn(tabSelect,"🔥 Fire sur la cible",nil,function()
    local hrp=getTargetHRP(); if not hrp then setStatus("Target introuvable!"); return end
    local old=hrp:FindFirstChild("CKX_TargetFire"); if old then old:Destroy(); setStatus("Fire retiré"); return end
    local f=Instance.new("Fire",hrp); f.Name="CKX_TargetFire"; f.Size=10; f.Heat=5
    setStatus("🔥 Fire sur "..getTarget().Name)
end)
addBtn(tabSelect,"✨ Sparkles sur la cible",nil,function()
    local hrp=getTargetHRP(); if not hrp then setStatus("Target introuvable!"); return end
    local old=hrp:FindFirstChild("CKX_TargetSparkle"); if old then old:Destroy(); setStatus("Sparkles retiré"); return end
    local a=Instance.new("Attachment",hrp); a.Name="CKX_TargetSparkle"; local pe=Instance.new("ParticleEmitter",a); pe.Texture="rbxassetid://241650934"; pe.Rate=80; pe.SpreadAngle=Vector2.new(60,60)
    setStatus("✨ Sparkles sur "..getTarget().Name)
end)
addBtn(tabSelect,"🌈 Rainbow Body sur cible",nil,function()
    local tc=getTargetChar(); if not tc then setStatus("Target introuvable!"); return end
    if _G.targetRainbow then _G.targetRainbow:Disconnect(); _G.targetRainbow=nil; setStatus("Rainbow retiré"); return end
    _G.targetRainbow=RunService.Heartbeat:Connect(function() local h=tick()*60%360; for _,p in pairs(tc:GetDescendants()) do if p:IsA("BasePart") then p.Color=Color3.fromHSV(h/360,1,1) end end end)
    setStatus("🌈 Rainbow sur "..getTarget().Name)
end)
addBtn(tabSelect,"👻 Rendre cible invisible",nil,function()
    local tc=getTargetChar(); if not tc then setStatus("Target introuvable!"); return end
    for _,p in pairs(tc:GetDescendants()) do if p:IsA("BasePart") then p.Transparency=1 end end
    setStatus("👻 Invisible: "..getTarget().Name)
end)
addBtn(tabSelect,"🦕 Géantifier la cible",nil,function()
    local hum=getTargetHum(); if not hum then setStatus("Target introuvable!"); return end
    pcall(function() hum.BodyHeightScale.Value=3; hum.BodyWidthScale.Value=3; hum.BodyDepthScale.Value=3 end)
    setStatus("🦕 Géant: "..getTarget().Name)
end)
addBtn(tabSelect,"🐭 Miniaturiser la cible",nil,function()
    local hum=getTargetHum(); if not hum then setStatus("Target introuvable!"); return end
    pcall(function() hum.BodyHeightScale.Value=0.3; hum.BodyWidthScale.Value=0.3; hum.BodyDepthScale.Value=0.3 end)
    setStatus("🐭 Mini: "..getTarget().Name)
end)
addBtn(tabSelect,"⚡ Neon la cible",nil,function()
    local tc=getTargetChar(); if not tc then setStatus("Target introuvable!"); return end
    for _,p in pairs(tc:GetDescendants()) do if p:IsA("BasePart") then p.Material=Enum.Material.Neon end end
    setStatus("⚡ Neon: "..getTarget().Name)
end)
addBtn(tabSelect,"🛡 ForceField sur cible",nil,function()
    local tc=getTargetChar(); if not tc then setStatus("Target introuvable!"); return end
    local ff=Instance.new("ForceField",tc); Debris:AddItem(ff,15)
    setStatus("🛡 FF sur "..getTarget().Name)
end)
addBtn(tabSelect,"❤️ Soigner la cible",C.green,function()
    local hum=getTargetHum(); if not hum then setStatus("Target introuvable!"); return end
    hum.Health=hum.MaxHealth; setStatus("❤️ Soigné: "..getTarget().Name)
end)
addBtn(tabSelect,"💀 Kill la cible",C.red,function()
    local hum=getTargetHum(); if not hum then setStatus("Target introuvable!"); return end
    hum.Health=0; setStatus("💀 Killed: "..getTarget().Name)
end)
addBtn(tabSelect,"📍 TP à ma position",nil,function()
    local hrp=getTargetHRP(); local myHRP=character:FindFirstChild("HumanoidRootPart"); if not hrp or not myHRP then return end
    hrp.CFrame=myHRP.CFrame+Vector3.new(2,0,0); setStatus("📍 TP to me: "..getTarget().Name)
end)
addBtn(tabSelect,"🏃 TP moi à la cible",nil,function()
    local hrp=getTargetHRP(); local myHRP=character:FindFirstChild("HumanoidRootPart"); if not hrp or not myHRP then return end
    myHRP.CFrame=hrp.CFrame+Vector3.new(2,0,0); setStatus("📍 TP to target")
end)
addBtn(tabSelect,"🌀 Spin la cible",nil,function()
    local hrp=getTargetHRP(); if not hrp then setStatus("Target introuvable!"); return end
    if _G.targetSpin then _G.targetSpin:Disconnect(); _G.targetSpin=nil; setStatus("Spin retiré"); return end
    _G.targetSpin=RunService.Heartbeat:Connect(function() if hrp and hrp.Parent then hrp.CFrame=hrp.CFrame*CFrame.Angles(0,math.rad(10),0) end end)
    setStatus("🌀 Spin: "..getTarget().Name)
end)
addBtn(tabSelect,"🔇 Slow Walk la cible",nil,function()
    local hum=getTargetHum(); if not hum then setStatus("Target introuvable!"); return end
    hum.WalkSpeed=2; setStatus("🐢 Slow: "..getTarget().Name)
end)
addBtn(tabSelect,"⚡ Speed MAX la cible",nil,function()
    local hum=getTargetHum(); if not hum then setStatus("Target introuvable!"); return end
    hum.WalkSpeed=200; setStatus("⚡ Boost: "..getTarget().Name)
end)
addBtn(tabSelect,"🧲 Attirer la cible vers moi",nil,function()
    local hrp=getTargetHRP(); local myHRP=character:FindFirstChild("HumanoidRootPart"); if not hrp or not myHRP then return end
    local bv=Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(9e9,9e9,9e9)
    task.spawn(function()
        local t=tick(); while tick()-t<3 and hrp and hrp.Parent and myHRP and myHRP.Parent do
            local dir=(myHRP.Position-hrp.Position).Unit; bv.Velocity=dir*60; task.wait(0.05)
        end; if bv and bv.Parent then bv:Destroy() end
    end)
    setStatus("🧲 Pull: "..getTarget().Name)
end)
addBtn(tabSelect,"💨 Repousser la cible",nil,function()
    local hrp=getTargetHRP(); local myHRP=character:FindFirstChild("HumanoidRootPart"); if not hrp or not myHRP then return end
    local bv=Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(9e9,9e9,9e9)
    local dir=(hrp.Position-myHRP.Position).Unit; bv.Velocity=dir*100+Vector3.new(0,50,0); Debris:AddItem(bv,0.5)
    setStatus("💨 Pushed: "..getTarget().Name)
end)
addBtn(tabSelect,"🎆 Fireworks sur cible",nil,function()
    local hrp=getTargetHRP(); if not hrp then setStatus("Target introuvable!"); return end
    task.spawn(function() for i=1,10 do task.wait(0.15); local e=Instance.new("Explosion"); e.Position=hrp.Position+Vector3.new(math.random(-8,8),math.random(0,10),math.random(-8,8)); e.BlastRadius=5; e.BlastPressure=0; e.Parent=workspace end end)
    setStatus("🎆 Fireworks: "..getTarget().Name)
end)
addBtn(tabSelect,"🌊 Orbit sur cible",nil,function()
    local hrp=getTargetHRP(); if not hrp then setStatus("Target introuvable!"); return end
    local myHRP=character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    if _G.orbitConn then _G.orbitConn:Disconnect(); _G.orbitConn=nil; setStatus("Orbit retiré"); return end
    _G.orbitConn=RunService.Heartbeat:Connect(function()
        if hrp and hrp.Parent and myHRP and myHRP.Parent then
            local t=tick(); myHRP.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(t*2)*8,0,math.sin(t*2)*8),hrp.Position)
        end
    end)
    setStatus("🌊 Orbiting: "..getTarget().Name)
end)

-- ══════════════════════════════════════════════════════════════
-- EXPLORER TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabExplorer,"STUDIO EXPLORER")
addBtn(tabExplorer,"🔍 Ouvrir Explorer",Color3.fromRGB(0,50,30),function() explorerWindow.Visible=true; buildExplorerTree(); setStatus("Explorer ouvert!") end)
addBtn(tabExplorer,"📜 Ouvrir Script Editor",Color3.fromRGB(20,10,40),function() scriptEditorWindow.Visible=true; setStatus("Script Editor ouvert!") end)
addBtn(tabExplorer,"🔄 Refresh Explorer",nil,function() buildExplorerTree(); setStatus("Refreshed!") end)
addSpacer(tabExplorer,5)
addSection(tabExplorer,"RECHERCHE RAPIDE")
addInput(tabExplorer,"Nom d'objet...","FIND",function(name)
    local found={}; local function search(parent,depth) if depth>10 then return end; for _,obj in pairs(parent:GetChildren()) do if obj.Name:lower():find(name:lower(),1,true) then table.insert(found,obj) end; pcall(search,obj,depth+1) end end
    for _,svc in pairs(browsableServices) do if svc.service then pcall(search,svc.service,0) end end
    print("=== SEARCH '"..name.."' — "..#found.." results ==="); for i,obj in pairs(found) do print(i,obj.ClassName,obj:GetFullName()) end
    setStatus("Found "..#found.." — console!"); if #found>0 then explorerSelected=found[1]; buildPropertiesPanel(found[1]); explorerWindow.Visible=true end
end)
addSpacer(tabExplorer,5)
addSection(tabExplorer,"STATS DU JEU")
addBtn(tabExplorer,"📊 Game Stats",nil,function()
    local tot,sc,pt,mo,rm=0,0,0,0,0
    local function count(p,d) if d>8 then return end; for _,obj in pairs(p:GetChildren()) do tot+=1; if obj:IsA("BasePart") then pt+=1 end; if obj:IsA("Model") then mo+=1 end; if obj:IsA("BaseScript")or obj:IsA("ModuleScript") then sc+=1 end; if obj:IsA("RemoteEvent")or obj:IsA("RemoteFunction") then rm+=1 end; pcall(count,obj,d+1) end end
    for _,svc in pairs(browsableServices) do if svc.service then pcall(count,svc.service,0) end end
    print("Objects:",tot,"| Parts:",pt,"| Scripts:",sc,"| Remotes:",rm); setStatus(pt.." parts, "..sc.." scripts")
end)
addBtn(tabExplorer,"📡 Find All Remotes",nil,function()
    local found={}; local function s(p,d) if d>8 then return end; for _,obj in pairs(p:GetChildren()) do if obj:IsA("RemoteEvent")or obj:IsA("RemoteFunction") then table.insert(found,obj); print("📡 "..obj.ClassName..": "..obj:GetFullName()) end; pcall(s,obj,d+1) end end
    for _,svc in pairs(browsableServices) do if svc.service then pcall(s,svc.service,0) end end; setStatus(#found.." Remotes — console!")
end)
addBtn(tabExplorer,"📜 Find All Scripts",nil,function()
    local found={}; local function s(p,d) if d>8 then return end; for _,obj in pairs(p:GetChildren()) do if obj:IsA("BaseScript")or obj:IsA("ModuleScript") then table.insert(found,obj); print(obj.ClassName..": "..obj:GetFullName()) end; pcall(s,obj,d+1) end end
    for _,svc in pairs(browsableServices) do if svc.service then pcall(s,svc.service,0) end end; setStatus(#found.." Scripts — console!")
end)

-- ══════════════════════════════════════════════════════════════
-- SCRIPT EDITOR TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabScript,"SCRIPT EDITOR [F7]")
local edCard=Instance.new("Frame",tabScript); edCard.Size=UDim2.new(1,0,0,100); edCard.BackgroundColor3=Color3.fromRGB(14,10,24); Instance.new("UICorner",edCard).CornerRadius=UDim.new(0,12)
local edInstroke=Instance.new("UIStroke",edCard); edInstroke.Color=C.accent2; edInstroke.Thickness=1; edInstroke.Transparency=0.3
local edInfoText=Instance.new("TextLabel",edCard); edInfoText.Size=UDim2.new(1,-14,1,-8); edInfoText.Position=UDim2.new(0,7,0,4); edInfoText.BackgroundTransparency=1; edInfoText.RichText=true
edInfoText.Text='<font color="#7800FF"><b>📜 SCRIPT EDITOR INTÉGRÉ</b></font>\n<font color="#888">► Ouvre, lit et modifie tout script du jeu</font>\n<font color="#888">► Find & Replace intégré</font>\n<font color="#888">► Run le code directement depuis l\'éditeur</font>\n<font color="#888">► Numérotation de lignes | Coloration syntaxique</font>'
edInfoText.TextSize=11; edInfoText.Font=Enum.Font.Gotham; edInfoText.TextXAlignment=Enum.TextXAlignment.Left; edInfoText.TextYAlignment=Enum.TextYAlignment.Top; edInfoText.TextColor3=C.text
addSpacer(tabScript,5)
addBtn(tabScript,"📜 Ouvrir Script Editor",Color3.fromRGB(20,10,40),function() scriptEditorWindow.Visible=true end)
addBtn(tabScript,"🔍 Ouvre + Explore Scripts",nil,function() explorerWindow.Visible=true; buildExplorerTree(); setStatus("Explorer ouvert — Clic droit sur un Script → Open in Editor") end)
addSpacer(tabScript,5)
addSection(tabScript,"CODE RAPIDE")
addInput(tabScript,"Code Lua...","▶ RUN",function(code)
    local ok,err=pcall(loadstring(code)); if ok then setStatus("✅ Executed!") else setStatus("❌ "..tostring(err)) end
end)
addBtn(tabScript,"▶ Exécuter le code de l'éditeur",Color3.fromRGB(0,50,20),function()
    if edCodeBox.Text~="" then local ok,err=pcall(loadstring(edCodeBox.Text)); if ok then setStatus("✅ Script exécuté!") else setStatus("❌ "..tostring(err)) end
    else setStatus("Aucun code dans l'éditeur!") end
end)
addSpacer(tabScript,5)
addSection(tabScript,"TEMPLATES")
addBtn(tabScript,"📋 Template: Print All Players",nil,function()
    edCodeBox.Text='for _, p in pairs(game:GetService("Players"):GetPlayers()) do\n    print(p.Name, p.UserId, p.DisplayName)\nend'; updateLineNumbers(edCodeBox.Text); scriptEditorWindow.Visible=true
end)
addBtn(tabScript,"📋 Template: Scan Remotes",nil,function()
    edCodeBox.Text='local function scan(p, d)\n    if d > 8 then return end\n    for _, obj in pairs(p:GetChildren()) do\n        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then\n            print("REMOTE:", obj:GetFullName())\n        end\n        pcall(scan, obj, d+1)\n    end\nend\nscan(game, 0)'; updateLineNumbers(edCodeBox.Text); scriptEditorWindow.Visible=true
end)
addBtn(tabScript,"📋 Template: Find Values",nil,function()
    edCodeBox.Text='local function scan(p, d)\n    if d > 8 then return end\n    for _, obj in pairs(p:GetChildren()) do\n        if obj:IsA("ValueBase") then\n            print(obj.ClassName, obj.Name, "=", obj.Value, "|", obj:GetFullName())\n        end\n        pcall(scan, obj, d+1)\n    end\nend\nscan(game, 0)'; updateLineNumbers(edCodeBox.Text); scriptEditorWindow.Visible=true
end)
addBtn(tabScript,"📋 Template: Teleport Loop",nil,function()
    edCodeBox.Text='local player = game:GetService("Players").LocalPlayer\nlocal char = player.Character or player.CharacterAdded:Wait()\nlocal hrp = char:WaitForChild("HumanoidRootPart")\nhrp.CFrame = CFrame.new(0, 100, 0)\nprint("Teleported!")'; updateLineNumbers(edCodeBox.Text); scriptEditorWindow.Visible=true
end)

-- ══════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════
local flyEnabled,flyVelocity,flyGyro,flyConn=false,nil,nil,nil; local flySpeed=60
local noclipEnabled,noclipConn=false,nil
addSection(tabMovement,"FLY (A=Up, E=Down, W/S=Fwd/Back, Q/D=Strafe)")
addToggle(tabMovement,"🕊 Fly Mode",false,function(en)
    flyEnabled=en; local hrp=character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if en then humanoid.PlatformStand=true; flyVelocity=Instance.new("BodyVelocity",hrp); flyVelocity.MaxForce=Vector3.new(9e9,9e9,9e9); flyVelocity.Velocity=Vector3.zero; flyGyro=Instance.new("BodyGyro",hrp); flyGyro.MaxTorque=Vector3.new(9e9,9e9,9e9); flyGyro.D=100
        flyConn=RunService.Heartbeat:Connect(function() if not flyEnabled or not flyVelocity or not flyVelocity.Parent then return end; local cam=workspace.CurrentCamera; local mv=Vector3.zero; if UIS:IsKeyDown(Enum.KeyCode.W) then mv+=cam.CFrame.LookVector*flySpeed end; if UIS:IsKeyDown(Enum.KeyCode.S) then mv-=cam.CFrame.LookVector*flySpeed end; if UIS:IsKeyDown(Enum.KeyCode.A) then mv+=Vector3.new(0,flySpeed,0) end; if UIS:IsKeyDown(Enum.KeyCode.E) then mv-=Vector3.new(0,flySpeed,0) end; if UIS:IsKeyDown(Enum.KeyCode.Q) then mv-=cam.CFrame.RightVector*flySpeed end; if UIS:IsKeyDown(Enum.KeyCode.D) then mv+=cam.CFrame.RightVector*flySpeed end; flyVelocity.Velocity=mv; flyGyro.CFrame=cam.CFrame end)
    else humanoid.PlatformStand=false; if flyVelocity then flyVelocity:Destroy(); flyVelocity=nil end; if flyGyro then flyGyro:Destroy(); flyGyro=nil end; if flyConn then flyConn:Disconnect(); flyConn=nil end end
end)
addSlider(tabMovement,"Fly Speed",10,400,60,function(v) flySpeed=v end)
addToggle(tabMovement,"👻 NoClip",false,function(en) noclipEnabled=en; if en then noclipConn=RunService.Stepped:Connect(function() for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end) else if noclipConn then noclipConn:Disconnect(); noclipConn=nil end; for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end end)
addToggle(tabMovement,"🦘 Infinite Jump",false,function(en) if en then _G.infJump=UIS.JumpRequest:Connect(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) else if _G.infJump then _G.infJump:Disconnect() end end end)
addSlider(tabMovement,"Walk Speed",4,300,16,function(v) humanoid.WalkSpeed=v end)
addSlider(tabMovement,"Jump Power",1,300,50,function(v) humanoid.JumpPower=v end)
addSlider(tabMovement,"Gravity",0,500,196,function(v) workspace.Gravity=v end)
addBtn(tabMovement,"📍 TP to Mouse",nil,function() if character.PrimaryPart then character.PrimaryPart.CFrame=mouse.Hit+Vector3.new(0,5,0) end end)
addInput(tabMovement,"X,Y,Z","TP",function(val) local t=string.split(val,","); if #t==3 then local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3]); if x and y and z and character.PrimaryPart then character.PrimaryPart.CFrame=CFrame.new(x,y,z) end end end)

-- ══════════════════════════════════════════════════════════════
-- GIZMO BUILDER TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabBuilder,"GIZMO MODE")
addBtn(tabBuilder,"➡️ MOVE Mode",Color3.fromRGB(35,25,25),function() gizmoMode="move"; updateGizmo(); setStatus("Mode: MOVE") end)
addToggle(tabBuilder,"🎯 Click-to-Select",false,function(en) selectionEnabled=en; if en then _G.selectConn=mouse.Button1Down:Connect(function() if not selectionEnabled then return end; local t=mouse.Target; if t and t:IsA("BasePart") and not t:IsDescendantOf(character) and not t.Name:find("GIZMO_") then selectPart(t) end end) else if _G.selectConn then _G.selectConn:Disconnect() end; selectPart(nil); if selectionBox then selectionBox:Destroy(); selectionBox=nil end end end)
addSlider(tabBuilder,"Grid Snap",0,8,1,function(v) gridSnap=v==0 and 0.01 or v end)
addSection(tabBuilder,"SPAWN PARTS")
addBtn(tabBuilder,"🧱 Brick",nil,function() local p=Instance.new("Part"); p.Size=Vector3.new(4,4,4); p.Position=mouse.Hit.Position+Vector3.new(0,2,0); p.Anchored=true; p.BrickColor=BrickColor.Random(); p.Name="CKX_Brick"; p.Parent=workspace; table.insert(buildHistory,{action="spawn",obj=p}) end)
addBtn(tabBuilder,"🔵 Sphere",nil,function() local p=Instance.new("Part"); p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(4,4,4); p.Position=mouse.Hit.Position+Vector3.new(0,2,0); p.Anchored=true; p.BrickColor=BrickColor.Random(); p.Name="CKX_Sphere"; p.Parent=workspace end)
addBtn(tabBuilder,"💡 Light Part",nil,function() local p=Instance.new("Part"); p.Size=Vector3.new(1,1,1); p.Position=mouse.Hit.Position+Vector3.new(0,1,0); p.Anchored=true; p.Transparency=0.4; p.Material=Enum.Material.Neon; p.Color=Color3.fromRGB(255,220,100); p.Name="CKX_Light"; local light=Instance.new("PointLight",p); light.Range=25; light.Brightness=5; p.Parent=workspace end)
addSection(tabBuilder,"EDIT SELECTED")
addBtn(tabBuilder,"🗑 Delete",C.red,function() if selectedPart then table.insert(buildHistory,{action="delete",obj=selectedPart,parent=selectedPart.Parent}); selectedPart:Destroy(); selectPart(nil) else setStatus("Nothing selected!") end end)
addBtn(tabBuilder,"📋 Duplicate",nil,function() if selectedPart then local c=selectedPart:Clone(); c.Position=selectedPart.Position+Vector3.new(4,0,0); c.Parent=workspace; table.insert(buildHistory,{action="spawn",obj=c}); selectPart(c) end end)
addBtn(tabBuilder,"🔒 Toggle Anchor",nil,function() if selectedPart then selectedPart.Anchored=not selectedPart.Anchored end end)
addBtn(tabBuilder,"↶ Undo",nil,function() local last=table.remove(buildHistory); if last then if last.action=="spawn" and last.obj and last.obj.Parent then last.obj:Destroy() elseif last.action=="delete" then last.obj.Parent=last.parent or workspace end end end)
addInput(tabBuilder,"RGB (255,0,128)","COLOR",function(val) if selectedPart then local t=string.split(val,","); if #t==3 then selectedPart.Color=Color3.fromRGB(math.clamp(tonumber(t[1])or 128,0,255),math.clamp(tonumber(t[2])or 128,0,255),math.clamp(tonumber(t[3])or 128,0,255)) end end end)
addInput(tabBuilder,"W,H,D","SIZE",function(val) if selectedPart then local t=string.split(val,","); if #t==3 then selectedPart.Size=Vector3.new(math.max(0.05,tonumber(t[1])or 4),math.max(0.05,tonumber(t[2])or 4),math.max(0.05,tonumber(t[3])or 4)) end end end)

-- ══════════════════════════════════════════════════════════════
-- SHAPE BUILDER TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabShapes,"SHAPE BUILDER — Hold a Tool!")
local shapeCount,shapeRadius2,shapeAnimated=60,12,true
addSlider(tabShapes,"Clone Count",10,200,60,function(v) shapeCount=v end)
addSlider(tabShapes,"Radius",3,40,12,function(v) shapeRadius2=v end)
addToggle(tabShapes,"🔄 Animated",true,function(en) shapeAnimated=en end)
addBtn(tabShapes,"🌐 Sphere",nil,function() buildShape("sphere",shapeCount,shapeRadius2,shapeAnimated) end)
addBtn(tabShapes,"💍 Ring",nil,function() buildShape("ring",shapeCount,shapeRadius2,shapeAnimated) end)
addBtn(tabShapes,"🧬 Helix",nil,function() buildShape("helix",shapeCount,shapeRadius2,shapeAnimated) end)
addBtn(tabShapes,"🌪 Tornado",nil,function() buildShape("tornado",shapeCount,shapeRadius2,shapeAnimated) end)
addBtn(tabShapes,"🗑 Clear Shapes",C.red,function() shapeFolder:ClearAllChildren() end)

-- ══════════════════════════════════════════════════════════════
-- VISUALS TAB
-- ══════════════════════════════════════════════════════════════
local espData={}
addSection(tabVisuals,"ENVIRONMENT")
addToggle(tabVisuals,"☀️ Fullbright",false,function(en) if en then Lighting.Brightness=2; Lighting.Ambient=Color3.new(1,1,1); Lighting.ClockTime=12 else Lighting.Brightness=1; Lighting.Ambient=Color3.fromRGB(90,90,90) end end)
addSlider(tabVisuals,"Time of Day",0,24,14,function(v) Lighting.ClockTime=v end)
addToggle(tabVisuals,"🌫 Fog",false,function(en) Lighting.FogStart=en and 0 or 100000; Lighting.FogEnd=en and 100 or 100000 end)
local rainbowSky
addToggle(tabVisuals,"🌈 Rainbow Sky",false,function(en) if en then rainbowSky=RunService.Heartbeat:Connect(function() Lighting.ColorShift_Top=Color3.fromHSV(tick()*20%360/360,0.8,1) end) else if rainbowSky then rainbowSky:Disconnect() end; Lighting.ColorShift_Top=Color3.new(0,0,0) end end)
addSection(tabVisuals,"ESP")
addToggle(tabVisuals,"👁 Player ESP",false,function(en)
    if en then for _,p in pairs(Players:GetPlayers()) do if p~=player and p.Character then local hl=Instance.new("Highlight"); hl.FillColor=C.accent; hl.OutlineColor=C.red; hl.FillTransparency=0.4; hl.Adornee=p.Character; hl.Parent=gui; local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,150,0,40); bb.StudsOffset=Vector3.new(0,3.5,0); bb.AlwaysOnTop=true; bb.Parent=p.Character:FindFirstChild("Head") or p.Character; local nl=Instance.new("TextLabel",bb); nl.Size=UDim2.new(1,0,1,0); nl.BackgroundTransparency=1; nl.Text=p.Name; nl.TextColor3=C.accent; nl.TextSize=13; nl.Font=Enum.Font.GothamBold; nl.TextStrokeTransparency=0; espData[p.UserId]={hl=hl,bb=bb,lbl=nl} end end
    _G.espUpd=RunService.Heartbeat:Connect(function() for _,p in pairs(Players:GetPlayers()) do if p~=player and espData[p.UserId] and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("HumanoidRootPart") then espData[p.UserId].lbl.Text=p.Name.."\n"..math.floor((p.Character.HumanoidRootPart.Position-character.HumanoidRootPart.Position).Magnitude).."s" end end end)
    else if _G.espUpd then _G.espUpd:Disconnect() end; for _,d in pairs(espData) do if d.hl then d.hl:Destroy() end; if d.bb then d.bb:Destroy() end end; espData={} end
end)
addSlider(tabVisuals,"FOV",10,120,70,function(v) camera.FieldOfView=v end)
local freecamConn
addToggle(tabVisuals,"🎥 Freecam",false,function(en) camera.CameraType=en and Enum.CameraType.Scriptable or Enum.CameraType.Custom; if en then local speed=1; freecamConn=RunService.RenderStepped:Connect(function() local mv=Vector3.zero; if UIS:IsKeyDown(Enum.KeyCode.W) then mv+=camera.CFrame.LookVector*speed end; if UIS:IsKeyDown(Enum.KeyCode.S) then mv-=camera.CFrame.LookVector*speed end; if UIS:IsKeyDown(Enum.KeyCode.A) then mv+=Vector3.new(0,speed,0) end; if UIS:IsKeyDown(Enum.KeyCode.E) then mv-=Vector3.new(0,speed,0) end; if UIS:IsKeyDown(Enum.KeyCode.Q) then mv-=camera.CFrame.RightVector*speed end; if UIS:IsKeyDown(Enum.KeyCode.D) then mv+=camera.CFrame.RightVector*speed end; speed=UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1; camera.CFrame=camera.CFrame+mv end) else if freecamConn then freecamConn:Disconnect() end; camera.CameraType=Enum.CameraType.Custom end end)

-- ══════════════════════════════════════════════════════════════
-- MORPH TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabMorph,"BODY MORPHS")
local morphList={{"🦕 Giant",function() humanoid.BodyHeightScale.Value=3; humanoid.BodyWidthScale.Value=2.5; humanoid.BodyDepthScale.Value=2.5 end},{"🐭 Tiny",function() humanoid.BodyHeightScale.Value=0.3; humanoid.BodyWidthScale.Value=0.4; humanoid.BodyDepthScale.Value=0.4 end},{"👻 Invisible",function() for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency=1 end end end},{"⚡ Neon",function() for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.Material=Enum.Material.Neon end end end},{"💀 Glass",function() for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.Material=Enum.Material.Glass; p.Transparency=0.5 end end end},{"🧊 Ice",function() for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.Material=Enum.Material.Ice; p.Color=Color3.fromRGB(180,230,255) end end end},{"🔥 Lava",function() for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.Material=Enum.Material.Neon; p.Color=Color3.fromRGB(255,60,0) end end end}}
for _,m in pairs(morphList) do addBtn(tabMorph,m[1],nil,m[2]) end
addBtn(tabMorph,"🔄 Reset",C.orange,function() humanoid.BodyHeightScale.Value=1; humanoid.BodyWidthScale.Value=1; humanoid.BodyDepthScale.Value=1; humanoid.HeadScale.Value=1; for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.Transparency=0; p.Material=Enum.Material.SmoothPlastic end end end)
addSlider(tabMorph,"Head Scale",1,10,1,function(v) humanoid.HeadScale.Value=v end)

-- ══════════════════════════════════════════════════════════════
-- TOOLS TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabTools,"TOOL GIVER")
addInput(tabTools,"Tool Asset ID","GIVE",function(id) id=id:gsub("%D",""); if id~="" then local ok,r=pcall(function() return game:GetService("InsertService"):LoadAsset(tonumber(id)) end); if ok and r then local tool=r:FindFirstChildWhichIsA("Tool"); if tool then tool.Parent=player.Backpack; r:Destroy(); setStatus("Tool: "..tool.Name) else r:Destroy(); setStatus("No Tool found") end end end end)
addBtn(tabTools,"🗑 Remove All Tools",C.red,function() for _,t in pairs(player.Backpack:GetChildren()) do t:Destroy() end; local eq=character:FindFirstChildWhichIsA("Tool"); if eq then eq:Destroy() end end)
addSection(tabTools,"OUTILS SPÉCIAUX")
addBtn(tabTools,"🎯 TARGET TOOL (Click player → Sélectionne)",Color3.fromRGB(30,0,50),function()
    -- Create a special tool that selects players on click
    if _G.targetToolConn then _G.targetToolConn:Disconnect(); _G.targetToolConn=nil; setStatus("Target Tool désactivé"); return end
    _G.targetToolConn=mouse.Button1Down:Connect(function()
        local target=mouse.Target; if not target then return end
        local targetChar=target:FindFirstAncestorWhichIsA("Model")
        if targetChar then for _,p in pairs(Players:GetPlayers()) do if p.Character==targetChar and p~=player then setTargetPlayer(p); updateTargetLabel(); setStatus("🎯 Target: "..p.Name); rebuildPlayerList(); break end end end
    end)
    setStatus("🎯 Target Tool actif! Click sur un joueur pour le cibler")
end)
addBtn(tabTools,"🏃 SPEED TOOL (E=Boost, R=Normal)",nil,function()
    if _G.speedToolConn then _G.speedToolConn:Disconnect(); _G.speedToolConn=nil; setStatus("Speed Tool OFF"); return end
    _G.speedToolConn=UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end
        if inp.KeyCode==Enum.KeyCode.E then humanoid.WalkSpeed=100; setStatus("🏃 BOOST!") end
        if inp.KeyCode==Enum.KeyCode.R then humanoid.WalkSpeed=16; setStatus("Normal speed") end
    end)
    setStatus("Speed Tool: [E]=Boost [R]=Normal")
end)
addBtn(tabTools,"🔫 PAINT TOOL (Click = Recolor part)",nil,function()
    if _G.paintToolConn then _G.paintToolConn:Disconnect(); _G.paintToolConn=nil; setStatus("Paint Tool OFF"); return end
    local paintColor=BrickColor.Random()
    _G.paintToolConn=mouse.Button1Down:Connect(function()
        local t=mouse.Target; if t and t:IsA("BasePart") then t.BrickColor=paintColor; paintColor=BrickColor.Random(); setStatus("Painted! Next: "..tostring(paintColor)) end
    end)
    setStatus("🔫 Paint Tool actif!")
end)
addBtn(tabTools,"💣 BOMB TOOL (Click = Explosion at part)",nil,function()
    if _G.bombToolConn then _G.bombToolConn:Disconnect(); _G.bombToolConn=nil; setStatus("Bomb Tool OFF"); return end
    _G.bombToolConn=mouse.Button1Down:Connect(function()
        local e=Instance.new("Explosion"); e.Position=mouse.Hit.Position; e.BlastRadius=12; e.BlastPressure=3e6; e.Parent=workspace
    end)
    setStatus("💣 Bomb Tool actif! (Clic pour exploser)")
end)
addBtn(tabTools,"🧲 GRAVITY GUN (Click = Launch part)",nil,function()
    if _G.gravGunConn then _G.gravGunConn:Disconnect(); _G.gravGunConn=nil; setStatus("Gravity Gun OFF"); return end
    _G.gravGunConn=mouse.Button1Down:Connect(function()
        local t=mouse.Target; if t and t:IsA("BasePart") and not t:IsDescendantOf(character) then
            t.Anchored=false; local bv=Instance.new("BodyVelocity",t); bv.MaxForce=Vector3.new(9e9,9e9,9e9)
            local dir=(mouse.Hit.Position-camera.CFrame.Position).Unit; bv.Velocity=dir*120+Vector3.new(0,20,0); Debris:AddItem(bv,0.5)
            setStatus("🧲 Launched: "..t.Name)
        end
    end)
    setStatus("🧲 Gravity Gun actif!")
end)
addBtn(tabTools,"🔦 INSPECT TOOL (Click = show properties)",nil,function()
    if _G.inspectConn then _G.inspectConn:Disconnect(); _G.inspectConn=nil; setStatus("Inspect Tool OFF"); return end
    _G.inspectConn=mouse.Button1Down:Connect(function()
        local t=mouse.Target; if t then
            explorerSelected=t; buildPropertiesPanel(t); explorerWindow.Visible=true
            setStatus("🔦 Inspect: "..t.ClassName.." '"..t.Name.."'")
            if t:IsA("BasePart") then selectPart(t) end
        end
    end)
    setStatus("🔦 Inspect Tool actif! Clic sur n'importe quoi")
end)
addBtn(tabTools,"🧊 FREEZE TOOL (Click = toggle anchor)",nil,function()
    if _G.freezeConn then _G.freezeConn:Disconnect(); _G.freezeConn=nil; setStatus("Freeze Tool OFF"); return end
    _G.freezeConn=mouse.Button1Down:Connect(function()
        local t=mouse.Target; if t and t:IsA("BasePart") then
            t.Anchored=not t.Anchored; setStatus("🧊 "..t.Name.." Anchor="..tostring(t.Anchored))
        end
    end)
    setStatus("🧊 Freeze Tool actif!")
end)
addBtn(tabTools,"🌊 WATER TOOL (Click = add glass part)",nil,function()
    if _G.waterConn then _G.waterConn:Disconnect(); _G.waterConn=nil; setStatus("Water Tool OFF"); return end
    _G.waterConn=mouse.Button1Down:Connect(function()
        local p=Instance.new("Part"); p.Size=Vector3.new(8,0.5,8); p.Position=mouse.Hit.Position+Vector3.new(0,0.25,0)
        p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Glass; p.Transparency=0.4
        p.Color=Color3.fromRGB(0,120,200); p.Name="CKX_Water"; p.Parent=workspace
        setStatus("💧 Water placed!")
    end)
    setStatus("🌊 Water Tool actif!")
end)
addSpacer(tabTools,5)
addSection(tabTools,"DÉSACTIVER TOUS LES TOOLS")
addBtn(tabTools,"🔴 OFF All Special Tools",C.red,function()
    local conns={_G.targetToolConn,_G.speedToolConn,_G.paintToolConn,_G.bombToolConn,_G.gravGunConn,_G.inspectConn,_G.freezeConn,_G.waterConn}
    for _,c in pairs(conns) do if c and typeof(c)=="RBXScriptConnection" then pcall(function() c:Disconnect() end) end end
    _G.targetToolConn=nil; _G.speedToolConn=nil; _G.paintToolConn=nil; _G.bombToolConn=nil; _G.gravGunConn=nil; _G.inspectConn=nil; _G.freezeConn=nil; _G.waterConn=nil
    setStatus("All tools disabled!")
end)
addSection(tabTools,"PHYSICS")
addBtn(tabTools,"💥 Explode at Mouse",C.red,function() local e=Instance.new("Explosion"); e.Position=mouse.Hit.Position; e.BlastRadius=15; e.BlastPressure=5e6; e.Parent=workspace end)
addBtn(tabTools,"🛡 ForceField (10s)",nil,function() local ff=Instance.new("ForceField",character); Debris:AddItem(ff,10) end)
addBtn(tabTools,"🚀 Launch Up",nil,function() if character.HumanoidRootPart then local bv=Instance.new("BodyVelocity",character.HumanoidRootPart); bv.Velocity=Vector3.new(0,200,0); bv.MaxForce=Vector3.new(0,9e9,0); Debris:AddItem(bv,0.3) end end)
addBtn(tabTools,"❤️ Full Heal",C.accent,function() humanoid.Health=humanoid.MaxHealth end)

-- ══════════════════════════════════════════════════════════════
-- EFFECTS TAB (Fun & FX)
-- ══════════════════════════════════════════════════════════════
local currentMusic=nil
addSection(tabEffects,"MUSIC")
addInput(tabEffects,"Music ID","▶ PLAY",function(id) id=id:gsub("%D",""); if id~="" then if currentMusic then pcall(function() currentMusic:Destroy() end) end; currentMusic=Instance.new("Sound"); currentMusic.SoundId="rbxassetid://"..id; currentMusic.Volume=0.5; currentMusic.Looped=true; currentMusic.Parent=SoundService; currentMusic:Play() end end)
addBtn(tabEffects,"⏹ Stop Music",C.red,function() if currentMusic then currentMusic:Stop(); currentMusic:Destroy(); currentMusic=nil end end)
addSlider(tabEffects,"Volume",0,10,5,function(v) if currentMusic then currentMusic.Volume=v/10 end end)
addSection(tabEffects,"EFFETS PERSO")
addToggle(tabEffects,"✨ Sparkles",false,function(en) local hrp=character:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local old=hrp:FindFirstChild("CKX_Sparkle"); if old then old:Destroy() end; if en then local a=Instance.new("Attachment",hrp); a.Name="CKX_Sparkle"; local pe=Instance.new("ParticleEmitter",a); pe.Texture="rbxassetid://241650934"; pe.Lifetime=NumberRange.new(0.4,1); pe.Rate=60; pe.SpreadAngle=Vector2.new(45,45); pe.Speed=NumberRange.new(5) end end)
addToggle(tabEffects,"🔥 Fire",false,function(en) local hrp=character:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local old=hrp:FindFirstChild("CKX_Fire"); if old then old:Destroy() end; if en then local f=Instance.new("Fire",hrp); f.Name="CKX_Fire"; f.Size=8; f.Heat=4 end end)
addToggle(tabEffects,"❄️ Ice Trail",false,function(en) if en then _G.iceTrail=RunService.Heartbeat:Connect(function() if character:FindFirstChild("HumanoidRootPart") then local p=Instance.new("Part"); p.Size=Vector3.new(2,0.15,2); p.Position=character.HumanoidRootPart.Position-Vector3.new(0,3,0); p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Ice; p.Color=Color3.fromRGB(180,220,255); p.Transparency=0.3; p.Parent=workspace; Debris:AddItem(p,2) end end) else if _G.iceTrail then _G.iceTrail:Disconnect() end end end)
local rainbow2
addToggle(tabEffects,"🌈 Rainbow Body",false,function(en) if en then rainbow2=RunService.Heartbeat:Connect(function() local h=tick()*60%360; for _,p in pairs(character:GetDescendants()) do if p:IsA("BasePart") then p.Color=Color3.fromHSV(h/360,1,1) end end end) else if rainbow2 then rainbow2:Disconnect() end end end)
local spinC
addToggle(tabEffects,"🌀 Spin",false,function(en) if en then spinC=RunService.Heartbeat:Connect(function() if character.HumanoidRootPart then character.HumanoidRootPart.CFrame=character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(8),0) end end) else if spinC then spinC:Disconnect() end end end)
addBtn(tabEffects,"💰 Money Rain 30s",nil,function() task.spawn(function() local e=tick()+30; while tick()<e do local p=Instance.new("Part"); p.Size=Vector3.new(0.8,0.1,0.8); p.Color=Color3.fromRGB(255,215,0); p.Material=Enum.Material.SmoothPlastic; local c=character.PrimaryPart and character.PrimaryPart.Position or Vector3.new(); p.Position=c+Vector3.new(math.random(-12,12),25,math.random(-12,12)); p.Parent=workspace; Debris:AddItem(p,5); task.wait(0.05) end end) end)
addBtn(tabEffects,"🎆 Fireworks",nil,function() task.spawn(function() for i=1,15 do task.wait(0.12); local e=Instance.new("Explosion"); local c=character.PrimaryPart and character.PrimaryPart.Position or Vector3.new(); e.Position=c+Vector3.new(math.random(-25,25),math.random(5,20),math.random(-25,25)); e.BlastRadius=8; e.BlastPressure=0; e.Parent=workspace end end) end)
local neonTrailC
addToggle(tabEffects,"💜 Neon Trail",false,function(en) if en then neonTrailC=RunService.Heartbeat:Connect(function() if character.HumanoidRootPart then local p=Instance.new("Part"); p.Size=Vector3.new(0.5,0.5,0.5); p.Position=character.HumanoidRootPart.Position-Vector3.new(0,2,0); p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon; p.Color=Color3.fromHSV(tick()*30%360/360,1,1); p.Parent=workspace; Debris:AddItem(p,1.5) end end) else if neonTrailC then neonTrailC:Disconnect() end end end)

-- ══════════════════════════════════════════════════════════════
-- EMOTES TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabEmotes,"PLAY ANY EMOTE BY ID")
addInput(tabEmotes,"Animation ID","PLAY",function(id) id=id:gsub("%D",""); if id~="" then local anim=Instance.new("Animation"); anim.AnimationId="rbxassetid://"..id; local track=humanoid:LoadAnimation(anim); track:Play(); _G.curAnim=track end end)
addBtn(tabEmotes,"⏹ Stop",C.red,function() if _G.curAnim then _G.curAnim:Stop() end end)
addToggle(tabEmotes,"🔁 Loop",false,function(en) if _G.curAnim then _G.curAnim.Looped=en end end)
addSlider(tabEmotes,"Anim Speed",0,5,1,function(v) if _G.curAnim then _G.curAnim:AdjustSpeed(v) end end)
addSection(tabEmotes,"BUILT-IN EMOTES")
local emotes={{"👋 Wave",507770239},{"🕺 Dance 1",507771019},{"💃 Dance 2",507776043},{"🤸 Backflip",522635514},{"😂 Laugh",507770818},{"👍 Thumbs Up",507770625},{"😴 Sleep",2121823418},{"💪 Flex",5915693819}}
for _,e in pairs(emotes) do addBtn(tabEmotes,e[1],nil,function() local a=Instance.new("Animation"); a.AnimationId="rbxassetid://"..e[2]; local t=humanoid:LoadAnimation(a); t:Play(); _G.curAnim=t end) end
addBtn(tabEmotes,"⏹ Stop ALL",C.orange,function() for _,t in pairs(humanoid:GetPlayingAnimationTracks()) do t:Stop() end end)

-- ══════════════════════════════════════════════════════════════
-- ADMIN TAB
-- ══════════════════════════════════════════════════════════════
addSection(tabAdmin,"WORLD")
addBtn(tabAdmin,"🌊 Flood",nil,function() local w=Instance.new("Part"); w.Name="CKX_Flood"; w.Size=Vector3.new(2000,5,2000); w.Position=Vector3.new(0,-5,0); w.Anchored=true; w.CanCollide=false; w.Transparency=0.5; w.Material=Enum.Material.Glass; w.Color=Color3.fromRGB(0,120,200); w.Parent=workspace end)
addBtn(tabAdmin,"🌑 Black Hole",nil,function() for _,o in pairs(workspace:GetDescendants()) do if o:IsA("BasePart") and not o:IsDescendantOf(character) and o~=workspace.Terrain then o.Anchored=false; local c=character.PrimaryPart and character.PrimaryPart.Position or Vector3.new(); local bv=Instance.new("BodyVelocity",o); bv.Velocity=(c-o.Position).Unit*80; bv.MaxForce=Vector3.one*1e6; Debris:AddItem(bv,3) end end end)
addBtn(tabAdmin,"🌙 Night",nil,function() Lighting.ClockTime=0; Lighting.Brightness=0.1 end)
addBtn(tabAdmin,"🌞 Day",nil,function() Lighting.ClockTime=14; Lighting.Brightness=2 end)
addInput(tabAdmin,"Lua code","RUN",function(code) local ok,err=pcall(loadstring(code)); if not ok then warn(err) end end)
addToggle(tabAdmin,"🧊 Freeze All",false,function(en) for _,o in pairs(workspace:GetDescendants()) do if o:IsA("BasePart") and not o:IsDescendantOf(character) then o.Anchored=en end end end)
addBtn(tabAdmin,"🪜 Build Staircase",nil,function() if character.PrimaryPart then for i=0,19 do local step=Instance.new("Part"); step.Size=Vector3.new(6,1,4); step.Position=character.PrimaryPart.Position+character.PrimaryPart.CFrame.LookVector*(i*4)+Vector3.new(0,i*1.2,0); step.Anchored=true; step.Material=Enum.Material.SmoothPlastic; step.BrickColor=BrickColor.new("Medium stone grey"); step.Name="CKX_Step"; step.Parent=workspace end end end)
addBtn(tabAdmin,"🔄 MASTER RESET",C.orange,function()
    local conns={_G.iceTrail,_G.espUpd,_G.infJump,_G.targetToolConn,_G.speedToolConn,_G.paintToolConn,_G.bombToolConn,_G.gravGunConn,_G.inspectConn,_G.freezeConn,_G.waterConn,_G.targetRainbow,_G.orbitConn,_G.targetSpin}
    for _,c in pairs(conns) do if c and typeof(c)=="RBXScriptConnection" then pcall(function() c:Disconnect() end) end end
    if rainbow2 then rainbow2:Disconnect() end; if spinC then spinC:Disconnect() end; if neonTrailC then neonTrailC:Disconnect() end; if rainbowSky then rainbowSky:Disconnect() end; if freecamConn then freecamConn:Disconnect() end; if flyConn then flyConn:Disconnect() end; if noclipConn then noclipConn:Disconnect() end
    clearTargetHighlight(); targetedPlayer=nil; updateTargetLabel()
    for _,o in pairs(workspace:GetDescendants()) do if tostring(o.Name):sub(1,4)=="CKX_" or o.Name:find("GIZMO_") then pcall(function() o:Destroy() end) end end
    shapeFolder:ClearAllChildren(); clearGizmos(); if selectionBox then selectionBox:Destroy() end; selectedPart=nil
    Lighting.ClockTime=14; Lighting.Brightness=1; Lighting.Ambient=Color3.fromRGB(90,90,90); Lighting.ColorShift_Top=Color3.new(0,0,0); Lighting.FogEnd=100000
    humanoid.WalkSpeed=16; humanoid.JumpPower=50; humanoid.PlatformStand=false
    if flyVelocity then flyVelocity:Destroy() end; if flyGyro then flyGyro:Destroy() end
    camera.CameraType=Enum.CameraType.Custom; camera.FieldOfView=70; workspace.Gravity=196
    if currentMusic then pcall(function() currentMusic:Destroy() end); currentMusic=nil end
    setStatus("MASTER RESET!")
end)

-- ══════════ AUTO-OPEN ══════════
task.wait(0.7)
if allTabs[1] then allTabs[1].btn.MouseButton1Click:Fire() end

-- ══════════ KEYBOARD SHORTCUTS ══════════
local guiOpen = true
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        guiOpen = not guiOpen
        if guiOpen then MainFrame.Visible=true; TweenService:Create(blur,TweenInfo.new(0.3),{Size=8}):Play(); TweenService:Create(MainFrame,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,1060,0,640),BackgroundTransparency=0}):Play()
        else TweenService:Create(blur,TweenInfo.new(0.3),{Size=0}):Play(); local t=TweenService:Create(MainFrame,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,1060,0,0)}); t:Play(); t.Completed:Connect(function() if not guiOpen then MainFrame.Visible=false end end) end
    end
    if input.KeyCode == Enum.KeyCode.F6 then explorerWindow.Visible=not explorerWindow.Visible; if explorerWindow.Visible then buildExplorerTree() end end
    if input.KeyCode == Enum.KeyCode.F7 then scriptEditorWindow.Visible=not scriptEditorWindow.Visible end
    if not gpe then
        if input.KeyCode==Enum.KeyCode.One then gizmoMode="move"; updateGizmo() end
        if (input.KeyCode==Enum.KeyCode.Delete or input.KeyCode==Enum.KeyCode.X) and selectedPart and selectionEnabled then selectedPart:Destroy(); selectPart(nil) end
        if input.KeyCode==Enum.KeyCode.C and UIS:IsKeyDown(Enum.KeyCode.LeftControl) and selectedPart then local cl=selectedPart:Clone(); cl.Position=selectedPart.Position+Vector3.new(2,0,0); cl.Parent=workspace; selectPart(cl) end
    end
end)

-- Initial line numbers
updateLineNumbers(edCodeBox.Text)

-- NOTIFICATION
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚡ CoolKid X v5.0",
        Text = "Script Editor + Target System!\n[F6]=Explorer | [F7]=Script Editor\n🎯 Select Tab → Effets sur autres joueurs\n🔧 Tools Tab → Nouveaux outils interactifs",
        Duration = 12
    })
end)

print("══════════════════════════════════════════════════")
print("   COOLKID X v5.0 CHARGÉ!")
print("")
print("   ★ NOUVEAUTÉS v5.0:")
print("   📜 Script Editor [F7]:")
print("      - Éditeur de code intégré")
print("      - Numérotation de lignes")
print("      - Find & Replace")
print("      - Run directement depuis l'éditeur")
print("      - Templates de code prêts à l'emploi")
print("      - Clic droit sur script → Open in Editor")
print("")
print("   🎯 Select Tab:")
print("      - Sélectionne n'importe quel joueur")
print("      - 20+ effets applicables sur la cible")
print("      - Explosion, Launch, Fire, Rainbow...")
print("      - Géantifier, Miniaturiser, Kill, Heal...")
print("      - Attirer, Repousser, Orbit, Spin...")
print("")
print("   🔧 Tools Tab — Nouveaux tools interactifs:")
print("      - 🎯 Target Tool (click joueur = cible)")
print("      - 🏃 Speed Tool [E]=Boost [R]=Normal")
print("      - 🔫 Paint Tool (recolore les parts)")
print("      - 💣 Bomb Tool (explosion au clic)")
print("      - 🧲 Gravity Gun (lance les parts)")
print("      - 🔦 Inspect Tool (propriétés au clic)")
print("      - 🧊 Freeze Tool (toggle anchor)")
print("      - 🌊 Water Tool (pose de l'eau)")
print("")
print("   ★ RACCOURCIS:")
print("   [F6] = Explorer | [F7] = Script Editor")
print("   [INSERT] = Toggle GUI")
print("══════════════════════════════════════════════════")
