-- Denos Teleporter Custom UI (Part 1/4)
print("Denos teleport saver loaded.") 

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Shared Script State Trackers
local panelToggleKey = Enum.KeyCode.K 
local instantTPKey = Enum.KeyCode.E  
local targetPlayerName = ""          

local listeningForUIBind = false
local listeningForTPBind = false
local bindingInstanceIndex = nil

local savedInstances = {}
local maxInstances = 25 -- EXPANDED: Now supports up to 25 custom slots
local selectedInstanceIndex = nil

-- Top-Level UI Main Panel Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Denos_TP_Panel"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) 
MainFrame.BorderColor3 = Color3.fromRGB(0, 70, 255) 
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 420, 0, 210) 
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Font = Enum.Font.Code
Title.Text = " DENOS TELEPORTER" 
Title.TextColor3 = Color3.fromRGB(0, 100, 255) 
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.BorderSizePixel = 0
Sidebar.Position = UDim2.new(0, 0, 0, 25)
Sidebar.Size = UDim2.new(0, 130, 1, -25)

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Parent = Sidebar
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 2)
-- Denos Teleporter Custom UI (Part 2/4)

local NavTeleporterBtn = Instance.new("TextButton")
NavTeleporterBtn.Parent = Sidebar
NavTeleporterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NavTeleporterBtn.BorderSizePixel = 0
NavTeleporterBtn.Size = UDim2.new(1, 0, 0, 30)
NavTeleporterBtn.Font = Enum.Font.Code
NavTeleporterBtn.Text = "Teleporter"
NavTeleporterBtn.TextColor3 = Color3.fromRGB(0, 100, 255)
NavTeleporterBtn.TextSize = 12

local NavSaverBtn = Instance.new("TextButton")
NavSaverBtn.Parent = Sidebar
NavSaverBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
NavSaverBtn.BorderSizePixel = 0
NavSaverBtn.Size = UDim2.new(1, 0, 0, 30)
NavSaverBtn.Font = Enum.Font.Code
NavSaverBtn.Text = "Teleport Instance Saver"
NavSaverBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
NavSaverBtn.TextSize = 10
NavSaverBtn.TextWrapped = true

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 130, 0, 25)
ContentFrame.Size = UDim2.new(1, -130, 1, -25)

-- ================= PAGE 1: TELEPORTER =================
local TeleporterPage = Instance.new("Frame")
TeleporterPage.Name = "TeleporterPage"
TeleporterPage.Parent = ContentFrame
TeleporterPage.BackgroundTransparency = 1
TeleporterPage.Size = UDim2.new(1, 0, 1, 0)
TeleporterPage.Visible = true 

local KeybindContainer = Instance.new("Frame")
KeybindContainer.Parent = TeleporterPage
KeybindContainer.BackgroundTransparency = 1
KeybindContainer.Position = UDim2.new(0, 10, 0, 5)
KeybindContainer.Size = UDim2.new(1, -20, 0, 15)

local UIBindBtn = Instance.new("TextButton")
UIBindBtn.Parent = KeybindContainer
UIBindBtn.BackgroundTransparency = 1
UIBindBtn.Size = UDim2.new(0.5, 0, 1, 0)
UIBindBtn.Font = Enum.Font.Code
UIBindBtn.Text = "UI: [ " .. panelToggleKey.Name .. " ]"
UIBindBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
UIBindBtn.TextSize = 10
UIBindBtn.TextXAlignment = Enum.TextXAlignment.Left

local TPBindBtn = Instance.new("TextButton")
TPBindBtn.Parent = KeybindContainer
TPBindBtn.BackgroundTransparency = 1
TPBindBtn.Position = UDim2.new(0.5, 0, 0, 0)
TPBindBtn.Size = UDim2.new(0.5, 0, 1, 0)
TPBindBtn.Font = Enum.Font.Code
TPBindBtn.Text = "Fast TP: [ " .. instantTPKey.Name .. " ]"
TPBindBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
TPBindBtn.TextSize = 10
TPBindBtn.TextXAlignment = Enum.TextXAlignment.Right
-- Denos Teleporter Custom UI (Part 3/4)

local InputBox = Instance.new("TextBox")
InputBox.Parent = TeleporterPage
InputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
InputBox.BorderColor3 = Color3.fromRGB(40, 40, 40)
InputBox.Position = UDim2.new(0, 10, 0, 25)
InputBox.Size = UDim2.new(1, -20, 0, 30)
InputBox.Font = Enum.Font.SourceSans
InputBox.PlaceholderText = "Enter player name..."
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.TextSize = 14

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Parent = TeleporterPage
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
PlayerListFrame.BorderColor3 = Color3.fromRGB(0, 70, 255) 
PlayerListFrame.Position = UDim2.new(0, 10, 0, 57)
PlayerListFrame.Size = UDim2.new(1, -20, 0, 110)
PlayerListFrame.Visible = false
PlayerListFrame.ZIndex = 5
PlayerListFrame.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = PlayerListFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local TPButton = Instance.new("TextButton")
TPButton.Parent = TeleporterPage
TPButton.BackgroundColor3 = Color3.fromRGB(0, 70, 255) 
TPButton.BorderSizePixel = 0
TPButton.Position = UDim2.new(0, 10, 0, 70)
TPButton.Size = UDim2.new(1, -20, 0, 35)
TPButton.Font = Enum.Font.Code
TPButton.Text = "TELEPORT"
TPButton.TextColor3 = Color3.fromRGB(255, 255, 255) 
TPButton.TextSize = 16

-- ================= PAGE 2: INSTANCE SAVER =================
local SaverPage = Instance.new("Frame")
SaverPage.Name = "SaverPage"
SaverPage.Parent = ContentFrame
SaverPage.BackgroundTransparency = 1
SaverPage.Size = UDim2.new(1, 0, 1, 0)
SaverPage.Visible = false 

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Parent = SaverPage
CounterLabel.BackgroundTransparency = 1
CounterLabel.Position = UDim2.new(0, 10, 0, 5)
CounterLabel.Size = UDim2.new(1, -20, 0, 15)
CounterLabel.Font = Enum.Font.Code
CounterLabel.Text = "Slots: 0 / 25" -- VISUAL UPDATE: Shows 25 slots max
CounterLabel.TextColor3 = Color3.fromRGB(0, 100, 255)
CounterLabel.TextSize = 10
CounterLabel.TextXAlignment = Enum.TextXAlignment.Right

local AddCubeBtn = Instance.new("TextButton")
AddCubeBtn.Parent = SaverPage
AddCubeBtn.BackgroundColor3 = Color3.fromRGB(0, 70, 255)
AddCubeBtn.BorderSizePixel = 0
AddCubeBtn.Position = UDim2.new(0, 10, 0, 25)
AddCubeBtn.Size = UDim2.new(1, -20, 0, 25)
AddCubeBtn.Font = Enum.Font.Code
AddCubeBtn.Text = "+ DROP CUBE PART"
AddCubeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddCubeBtn.TextSize = 12

local CoordLabel = Instance.new("TextLabel")
CoordLabel.Parent = SaverPage
CoordLabel.BackgroundTransparency = 1
CoordLabel.Position = UDim2.new(0, 10, 0, 55)
CoordLabel.Size = UDim2.new(0, 80, 0, 20)
CoordLabel.Font = Enum.Font.Code
CoordLabel.Text = "Edit Position:"
CoordLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
CoordLabel.TextSize = 10
CoordLabel.TextXAlignment = Enum.TextXAlignment.Left

local InputX = Instance.new("TextBox")
InputX.Parent = SaverPage
InputX.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
InputX.BorderColor3 = Color3.fromRGB(40, 40, 40)
InputX.Position = UDim2.new(0, 95, 0, 55)
InputX.Size = UDim2.new(0, 55, 0, 20)
InputX.Font = Enum.Font.SourceSans
InputX.PlaceholderText = "X"
InputX.TextColor3 = Color3.fromRGB(255, 255, 255)
InputX.TextSize = 12

local InputY = Instance.new("TextBox")
InputY.Parent = SaverPage
InputY.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
InputY.BorderColor3 = Color3.fromRGB(40, 40, 40)
InputY.Position = UDim2.new(0, 155, 0, 55)
InputY.Size = UDim2.new(0, 55, 0, 20)
InputY.Font = Enum.Font.SourceSans
InputY.PlaceholderText = "Y"
InputY.TextColor3 = Color3.fromRGB(255, 255, 255)
InputY.TextSize = 12

local InputZ = Instance.new("TextBox")
InputZ.Parent = SaverPage
InputZ.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
InputZ.BorderColor3 = Color3.fromRGB(40, 40, 40)
InputZ.Position = UDim2.new(0, 215, 0, 55)
InputZ.Size = UDim2.new(0, 55, 0, 20)
InputZ.Font = Enum.Font.SourceSans
InputZ.PlaceholderText = "Z"
InputZ.TextColor3 = Color3.fromRGB(255, 255, 255)
InputZ.TextSize = 12

local InstanceListFrame = Instance.new("ScrollingFrame")
InstanceListFrame.Parent = SaverPage
InstanceListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InstanceListFrame.BorderColor3 = Color3.fromRGB(30, 30, 30)
InstanceListFrame.Position = UDim2.new(0, 10, 0, 80)
InstanceListFrame.Size = UDim2.new(1, -20, 0, 100)
InstanceListFrame.ScrollBarThickness = 4

local InstanceListLayout = Instance.new("UIListLayout")
InstanceListLayout.Parent = InstanceListFrame
InstanceListLayout.SortOrder = Enum.SortOrder.LayoutOrder
InstanceListLayout.Padding = UDim.new(0, 2)

local MoveHandles = Instance.new("Handles")
MoveHandles.Style = Enum.HandlesStyle.Resize 
MoveHandles.Color3 = Color3.fromRGB(0, 255, 150)
MoveHandles.Parent = ScreenGui
-- Denos Teleporter Custom UI (Part 4/4)

NavTeleporterBtn.MouseButton1Click:Connect(function()
    TeleporterPage.Visible, SaverPage.Visible = true, false
    NavTeleporterBtn.BackgroundColor3, NavTeleporterBtn.TextColor3 = Color3.fromRGB(30, 30, 30), Color3.fromRGB(0, 100, 255)
    NavSaverBtn.BackgroundColor3, NavSaverBtn.TextColor3 = Color3.fromRGB(25, 25, 25), Color3.fromRGB(150, 150, 150)
end)

NavSaverBtn.MouseButton1Click:Connect(function()
    TeleporterPage.Visible, SaverPage.Visible = false, true
    NavSaverBtn.BackgroundColor3, NavSaverBtn.TextColor3 = Color3.fromRGB(30, 30, 30), Color3.fromRGB(0, 100, 255)
    NavTeleporterBtn.BackgroundColor3, NavTeleporterBtn.TextColor3 = Color3.fromRGB(25, 25, 25), Color3.fromRGB(150, 150, 150)
end)

UIBindBtn.MouseButton1Click:Connect(function()
    listeningForUIBind, listeningForTPBind, bindingInstanceIndex = true, false, nil
    UIBindBtn.Text, UIBindBtn.TextColor3 = "UI: [ ... ]", Color3.fromRGB(0, 100, 255)
end)

TPBindBtn.MouseButton1Click:Connect(function()
    listeningForTPBind, listeningForUIBind, bindingInstanceIndex = false, true, nil
    TPBindBtn.Text, TPBindBtn.TextColor3 = "Fast TP: [ ... ]", Color3.fromRGB(0, 100, 255)
end)

local dragStartPos = nil
MoveHandles.MouseButton1Down:Connect(function() if MoveHandles.Adornee then dragStartPos = MoveHandles.Adornee.Position end end)
MoveHandles.MouseDrag:Connect(function(face, distance)
    if not MoveHandles.Adornee or not dragStartPos then return end
    MoveHandles.Adornee.Position = dragStartPos + (Vector3.FromNormalId(face) * distance)
    if selectedInstanceIndex and savedInstances[selectedInstanceIndex] and savedInstances[selectedInstanceIndex].Part == MoveHandles.Adornee then
        local p = MoveHandles.Adornee.Position
        InputX.Text, InputY.Text, InputZ.Text = string.format("%.1f", p.X), string.format("%.1f", p.Y), string.format("%.1f", p.Z)
    end
end)

local updateInstanceList
updateInstanceList = function()
    for _, child in pairs(InstanceListFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    CounterLabel.Text = "Slots: " .. #savedInstances .. " / " .. maxInstances
    for i, inst in ipairs(savedInstances) do
        local Row = Instance.new("Frame") Row.Parent = InstanceListFrame Row.Size = UDim2.new(1, -5, 0, 24)
        Row.BackgroundColor3 = (selectedInstanceIndex == i) and Color3.fromRGB(0, 40, 120) or Color3.fromRGB(25, 25, 25) Row.BorderSizePixel = 0
        local Sel = Instance.new("TextButton") Sel.Parent = Row Sel.Size = UDim2.new(0.6, 0, 1, 0) Sel.BackgroundTransparency = 1
        local pos = inst.Part.Position Sel.Text = " [" .. i .. "] X:" .. string.format("%.0f", pos.X) .. " Y:" .. string.format("%.0f", pos.Y) .. " Z:" .. string.format("%.0f", pos.Z)
        Sel.Font, Sel.TextSize, Sel.TextColor3, Sel.TextXAlignment = Enum.Font.Code, 10, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left
        Sel.MouseButton1Click:Connect(function()
            selectedInstanceIndex = i InputX.Text, InputY.Text, InputZ.Text = string.format("%.1f", pos.X), string.format("%.1f", pos.Y), string.format("%.1f", pos.Z)
            MoveHandles.Adornee = inst.Part updateInstanceList()
        end)
        local KeyBtn = Instance.new("TextButton") KeyBtn.Parent = Row KeyBtn.Position = UDim2.new(0.6, 2, 0, 2) KeyBtn.Size = UDim2.new(0.25, -4, 1, -4)
        KeyBtn.BackgroundColor3, KeyBtn.Font, KeyBtn.Text, KeyBtn.TextColor3, KeyBtn.TextSize = Color3.fromRGB(40, 40, 40), Enum.Font.Code, inst.Key.Name, Color3.fromRGB(0, 255, 150), 9
        KeyBtn.MouseButton1Click:Connect(function() bindingInstanceIndex, listeningForUIBind, listeningForTPBind = i, false, false KeyBtn.Text = "..." end)
        local Del = Instance.new("TextButton") Del.Parent = Row Del.Position = UDim2.new(0.85, 2, 0, 2) Del.Size = UDim2.new(0.15, -4, 1, -4)
        Del.BackgroundColor3, Del.Font, Del.Text, Del.TextColor3, Del.TextSize = Color3.fromRGB(150, 0, 0), Enum.Font.SourceSansBold, "X", Color3.fromRGB(255, 255, 255), 11
        Del.MouseButton1Click:Connect(function() inst.Part:Destroy() if MoveHandles.Adornee == inst.Part then MoveHandles.Adornee = nil end table.remove(savedInstances, i) if selectedInstanceIndex == i then selectedInstanceIndex = #savedInstances > 0 and 1 or nil end updateInstanceList() end)
    end
end

AddCubeBtn.MouseButton1Click:Connect(function()
    if #savedInstances >= maxInstances or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local P = Instance.new("Part") P.Size = Vector3.new(3, 3, 3) P.Position = LocalPlayer.Character.HumanoidRootPart.Position P.Anchored, P.CanCollide = true, false
    P.Material, P.Color, P.Transparency, P.Parent = Enum.Material.Neon, Color3.fromRGB(0, 70, 255), 0.4, workspace
    
    -- Default keybind sequence mapping for the first 5 entries; entries 6-25 initialize as Unknown waiting for your input assignment
    local defaultKeys = {Enum.KeyCode.J, Enum.KeyCode.L, Enum.KeyCode.U, Enum.KeyCode.O, Enum.KeyCode.P}
    table.insert(savedInstances, {Part = P, Key = defaultKeys[#savedInstances + 1] or Enum.KeyCode.Unknown})
    selectedInstanceIndex = #savedInstances MoveHandles.Adornee = P updateInstanceList()
end)

local function modifyActiveCoordinates()
    if not selectedInstanceIndex or not savedInstances[selectedInstanceIndex] then return end
    local t = savedInstances[selectedInstanceIndex].Part
    t.Position = Vector3.new(tonumber(InputX.Text) or t.Position.X, tonumber(InputY.Text) or t.Position.Y, tonumber(InputZ.Text) or t.Position.Z) updateInstanceList()
end
InputX.FocusLost:Connect(modifyActiveCoordinates) InputY.FocusLost:Connect(modifyActiveCoordinates) InputZ.FocusLost:Connect(modifyActiveCoordinates)

local function openPlayerList()
    for _, child in pairs(PlayerListFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local c = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            c = c + 1 local B = Instance.new("TextButton") B.Parent = PlayerListFrame B.BackgroundColor3 = Color3.fromRGB(30, 30, 30) B.Size = UDim2.new(1, 0, 0, 25)
            B.Font, B.Text, B.TextColor3, B.TextSize = Enum.Font.SourceSans, p.DisplayName .. " (@" .. p.Name .. ")", Color3.fromRGB(255, 255, 255), 12 B.ZIndex = 6
            B.MouseButton1Click:Connect(function() InputBox.Text, targetPlayerName, PlayerListFrame.Visible, TPButton.Visible = p.Name, p.Name, false, true end)
        end
    end
    PlayerListFrame.CanvasSize, PlayerListFrame.Visible, TPButton.Visible = UDim2.new(0, 0, 0, c * 25), true, false
end
InputBox.Focused:Connect(openPlayerList) InputBox.FocusLost:Connect(function() task.wait(0.2) PlayerListFrame.Visible, TPButton.Visible, targetPlayerName = false, true, InputBox.Text end)

local function teleportToPlayer()
    if targetPlayerName == "" then return end local t = Players:FindFirstChild(targetPlayerName)
    if not t then for _, p in pairs(Players:GetPlayers()) do if p.DisplayName:lower() == targetPlayerName:lower() or p.Name:lower() == targetPlayerName:lower() then t = p break end end end
    if t and t.Character and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local r = t.Character:FindFirstChild("HumanoidRootPart") if r then LocalPlayer.Character.HumanoidRootPart.CFrame = r.CFrame * CFrame.new(0, 3, 0) end
    end
end
TPButton.MouseButton1Click:Connect(teleportToPlayer)

UserInputService.InputBegan:Connect(function(i, gp)
    if listeningForUIBind or listeningForTPBind or bindingInstanceIndex then
        if i.UserInputType == Enum.UserInputType.Keyboard then
            if listeningForUIBind then panelToggleKey = i.KeyCode UIBindBtn.Text, UIBindBtn.TextColor3 = "UI: [ " .. panelToggleKey.Name .. " ]", Color3.fromRGB(120, 120, 120) listeningForUIBind = false
            elseif listeningForTPBind then instantTPKey = i.KeyCode TPBindBtn.Text, TPBindBtn.TextColor3 = "Fast TP: [ " .. instantTPKey.Name .. " ]", Color3.fromRGB(120, 120, 120) listeningForTPBind = false
            elseif bindingInstanceIndex and savedInstances[bindingInstanceIndex] then savedInstances[bindingInstanceIndex].Key = i.KeyCode bindingInstanceIndex = nil updateInstanceList() end
        end return
    end
    if gp then return end
    if panelToggleKey and i.KeyCode == panelToggleKey then MainFrame.Visible = not MainFrame.Visible end
    if instantTPKey and i.KeyCode == instantTPKey then teleportToPlayer() end
    for _, inst in ipairs(savedInstances) do
        if inst.Key and i.KeyCode == inst.Key then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(inst.Part.Position + Vector3.new(0, 3, 0)) end break
        end
    end
end)
