-- DENOS WARE

if _G.DenosWareSession then
    local oldSession = _G.DenosWareSession

    if oldSession.Cleanup then
        pcall(oldSession.Cleanup)
    end
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("DENOS_WARE_Panel")
if oldGui then
    oldGui:Destroy()
end

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local DEFAULT_GRAVITY = 196.2

local Session = {
    Active = true,
    Fly = false,
    Noclip = false,
    Connections = {},
    Cleanup = nil
}

_G.DenosWareSession = Session

local function connect(signal, callback)
    if not Session.Active then
        return nil
    end

    local connection = signal:Connect(callback)
    table.insert(Session.Connections, connection)

    return connection
end

local function disconnectAll()
    for _, connection in ipairs(Session.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Session.Connections)
end

local panelToggleKey = Enum.KeyCode.K
local instantTPKey = Enum.KeyCode.E
local targetPlayerName = ""

local listeningForUIBind = false
local listeningForTPBind = false
local bindingInstanceIndex = nil

local savedInstances = {}
local maxInstances = 25
local selectedInstanceIndex = nil

local flyVelocity = nil
local flyGyro = nil

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DENOS_WARE_Panel"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderColor3 = Color3.fromRGB(0, 70, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 420, 0, 260)
MainFrame.Active = true
MainFrame.Draggable = false

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Font = Enum.Font.Code
Title.Text = " DENOS WARE"
Title.TextColor3 = Color3.fromRGB(0, 100, 255)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -24, 0, 3)
CloseButton.Size = UDim2.new(0, 20, 0, 19)
CloseButton.Font = Enum.Font.Code
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 11
CloseButton.ZIndex = 100

local dragging = false
local dragStart = nil
local startPosition = nil
local dragInput = nil

connect(Title.InputBegan, function(input)
    if not Session.Active then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = MainFrame.Position

        local changedConnection

        changedConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false

                if changedConnection then
                    changedConnection:Disconnect()
                end
            end
        end)
    end
end)

connect(Title.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        dragInput = input
    end
end)

connect(UserInputService.InputChanged, function(input)
    if not Session.Active then
        return
    end

    if input == dragInput and dragging then
        local delta = input.Position - dragStart

        MainFrame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

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

local function makeNavButton(text, size)
    local button = Instance.new("TextButton")
    button.Parent = Sidebar
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, size)
    button.Font = Enum.Font.Code
    button.Text = text
    button.TextColor3 = Color3.fromRGB(150, 150, 150)
    button.TextSize = 10
    button.TextWrapped = true

    return button
end

local NavTeleporterBtn = makeNavButton("Teleporter", 30)
local NavSaverBtn = makeNavButton("Teleport Instance Saver", 36)
local NavPlayerSettingsBtn = makeNavButton("Player Settings", 30)

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 130, 0, 25)
ContentFrame.Size = UDim2.new(1, -130, 1, -25)

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
CounterLabel.Text = "Slots: 0 / 25"
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

local function makeCoordBox(position, placeholder)
    local box = Instance.new("TextBox")
    box.Parent = SaverPage
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    box.BorderColor3 = Color3.fromRGB(40, 40, 40)
    box.Position = position
    box.Size = UDim2.new(0, 55, 0, 20)
    box.Font = Enum.Font.SourceSans
    box.PlaceholderText = placeholder
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 12

    return box
end

local InputX = makeCoordBox(UDim2.new(0, 95, 0, 55), "X")
local InputY = makeCoordBox(UDim2.new(0, 155, 0, 55), "Y")
local InputZ = makeCoordBox(UDim2.new(0, 215, 0, 55), "Z")

local InstanceListFrame = Instance.new("ScrollingFrame")
InstanceListFrame.Parent = SaverPage
InstanceListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InstanceListFrame.BorderColor3 = Color3.fromRGB(30, 30, 30)
InstanceListFrame.Position = UDim2.new(0, 10, 0, 80)
InstanceListFrame.Size = UDim2.new(1, -20, 0, 100)
InstanceListFrame.ScrollBarThickness = 4

local InstanceListLayout = Instance.new("UIListLayout")
InstanceListLayout.Parent = InstanceListFrame
InstanceListLayout.Padding = UDim.new(0, 2)

local MoveHandles = Instance.new("Handles")
MoveHandles.Name = "DENOS_WARE_MoveHandles"
MoveHandles.Style = Enum.HandlesStyle.Resize
MoveHandles.Color3 = Color3.fromRGB(0, 255, 150)
MoveHandles.Parent = ScreenGui

local PlayerSettingsPage = Instance.new("ScrollingFrame")
PlayerSettingsPage.Name = "PlayerSettingsPage"
PlayerSettingsPage.Parent = ContentFrame
PlayerSettingsPage.BackgroundTransparency = 1
PlayerSettingsPage.BorderSizePixel = 0
PlayerSettingsPage.Size = UDim2.new(1, 0, 1, 0)
PlayerSettingsPage.Visible = false
PlayerSettingsPage.ScrollingDirection = Enum.ScrollingDirection.Y
PlayerSettingsPage.ScrollBarThickness = 6
PlayerSettingsPage.ScrollBarImageColor3 = Color3.fromRGB(0, 100, 255)
PlayerSettingsPage.CanvasSize = UDim2.new(0, 0, 0, 330)

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Parent = PlayerSettingsPage
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Position = UDim2.new(0, 10, 0, 5)
SettingsTitle.Size = UDim2.new(1, -25, 0, 20)
SettingsTitle.Font = Enum.Font.Code
SettingsTitle.Text = "PLAYER SETTINGS"
SettingsTitle.TextColor3 = Color3.fromRGB(0, 100, 255)
SettingsTitle.TextSize = 13
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left

local function makeSettingRow(y, label, default)
    local row = Instance.new("Frame")
    row.Parent = PlayerSettingsPage
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0, 10, 0, y)
    row.Size = UDim2.new(1, -25, 0, 27)

    local labelObject = Instance.new("TextLabel")
    labelObject.Parent = row
    labelObject.BackgroundTransparency = 1
    labelObject.Position = UDim2.new(0, 8, 0, 0)
    labelObject.Size = UDim2.new(1, -100, 1, 0)
    labelObject.Font = Enum.Font.Code
    labelObject.Text = label
    labelObject.TextColor3 = Color3.fromRGB(180, 180, 180)
    labelObject.TextSize = 11
    labelObject.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox")
    box.Parent = row
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    box.BorderColor3 = Color3.fromRGB(40, 40, 40)
    box.Position = UDim2.new(1, -82, 0, 3)
    box.Size = UDim2.new(0, 74, 0, 21)
    box.Font = Enum.Font.SourceSans
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 12
    box.ClearTextOnFocus = false

    return box
end

local WalkSpeedBox = makeSettingRow(30, "WalkSpeed", DEFAULT_WALKSPEED)
local JumpPowerBox = makeSettingRow(61, "JumpPower", DEFAULT_JUMPPOWER)
local GravityBox = makeSettingRow(92, "Gravity", DEFAULT_GRAVITY)

local function makeToggleRow(y, label)
    local row = Instance.new("TextButton")
    row.Parent = PlayerSettingsPage
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0, 10, 0, y)
    row.Size = UDim2.new(1, -25, 0, 29)
    row.AutoButtonColor = false
    row.Text = ""

    local cube = Instance.new("Frame")
    cube.Parent = row
    cube.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    cube.BorderColor3 = Color3.fromRGB(70, 70, 70)
    cube.Position = UDim2.new(0, 8, 0, 7)
    cube.Size = UDim2.new(0, 15, 0, 15)

    local labelObject = Instance.new("TextLabel")
    labelObject.Parent = row
    labelObject.BackgroundTransparency = 1
    labelObject.Position = UDim2.new(0, 31, 0, 0)
    labelObject.Size = UDim2.new(1, -40, 1, 0)
    labelObject.Font = Enum.Font.Code
    labelObject.Text = label
    labelObject.TextColor3 = Color3.fromRGB(180, 180, 180)
    labelObject.TextSize = 11
    labelObject.TextXAlignment = Enum.TextXAlignment.Left

    return row, cube
end

local FlyRow, FlyIndicator = makeToggleRow(127, "Fly")
local NoclipRow, NoclipIndicator = makeToggleRow(160, "Noclip")

local ApplyStatsButton = Instance.new("TextButton")
ApplyStatsButton.Parent = PlayerSettingsPage
ApplyStatsButton.BackgroundColor3 = Color3.fromRGB(0, 70, 255)
ApplyStatsButton.BorderSizePixel = 0
ApplyStatsButton.Position = UDim2.new(0, 10, 0, 195)
ApplyStatsButton.Size = UDim2.new(1, -25, 0, 27)
ApplyStatsButton.Font = Enum.Font.Code
ApplyStatsButton.Text = "APPLY PLAYER STATS"
ApplyStatsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyStatsButton.TextSize = 11

local ResetStatsButton = Instance.new("TextButton")
ResetStatsButton.Parent = PlayerSettingsPage
ResetStatsButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ResetStatsButton.BorderColor3 = Color3.fromRGB(50, 50, 50)
ResetStatsButton.Position = UDim2.new(0, 10, 0, 226)
ResetStatsButton.Size = UDim2.new(1, -25, 0, 27)
ResetStatsButton.Font = Enum.Font.Code
ResetStatsButton.Text = "RESET DEFAULTS"
ResetStatsButton.TextColor3 = Color3.fromRGB(180, 180, 180)
ResetStatsButton.TextSize = 11

local function updateToggleIndicator(indicator, active)
    if active then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
        indicator.BorderColor3 = Color3.fromRGB(0, 140, 255)
    else
        indicator.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        indicator.BorderColor3 = Color3.fromRGB(70, 70, 70)
    end
end

local function getHumanoid()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function applyStats()
    if not Session.Active then
        return
    end

    local humanoid = getHumanoid()

    if not humanoid then
        return
    end

    local speed = tonumber(WalkSpeedBox.Text)
    local jump = tonumber(JumpPowerBox.Text)
    local gravity = tonumber(GravityBox.Text)

    if speed then
        humanoid.WalkSpeed = speed
    end

    if jump then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = jump
    end

    if gravity then
        workspace.Gravity = gravity
    end
end

connect(ApplyStatsButton.MouseButton1Click, applyStats)

connect(ResetStatsButton.MouseButton1Click, function()
    WalkSpeedBox.Text = tostring(DEFAULT_WALKSPEED)
    JumpPowerBox.Text = tostring(DEFAULT_JUMPPOWER)
    GravityBox.Text = tostring(DEFAULT_GRAVITY)

    applyStats()
end)

local function removeFlyObjects()
    if flyVelocity then
        pcall(function()
            flyVelocity:Destroy()
        end)

        flyVelocity = nil
    end

    if flyGyro then
        pcall(function()
            flyGyro:Destroy()
        end)

        flyGyro = nil
    end

    local character = LocalPlayer.Character

    if character then
        for _, object in ipairs(character:GetDescendants()) do
            if object.Name == "DENOS_WARE_FlyVelocity"
                or object.Name == "DENOS_WARE_FlyGyro" then

                pcall(function()
                    object:Destroy()
                end)
            end
        end
    end
end

local function stopFly()
    Session.Fly = false

    removeFlyObjects()

    updateToggleIndicator(FlyIndicator, false)

    local humanoid = getHumanoid()

    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function startFly()
    if not Session.Active or Session.Fly then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    Session.Fly = true

    updateToggleIndicator(FlyIndicator, true)

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "DENOS_WARE_FlyVelocity"
    flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root

    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "DENOS_WARE_FlyGyro"
    flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyGyro.P = 9000
    flyGyro.D = 500
    flyGyro.Parent = root

    local connection

    connection = RunService.RenderStepped:Connect(function()
        if not Session.Active or not Session.Fly then
            if connection then
                connection:Disconnect()
            end

            return
        end

        if not root.Parent or not flyVelocity or not flyGyro then
            stopFly()
            return
        end

        local camera = workspace.CurrentCamera

        if not camera then
            return
        end

        local direction = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.new(0, 1, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.new(0, 1, 0)
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        flyVelocity.Velocity = direction * 60
        flyGyro.CFrame = camera.CFrame
    end)

    table.insert(Session.Connections, connection)
end

connect(FlyRow.MouseButton1Click, function()
    if Session.Fly then
        stopFly()
    else
        startFly()
    end
end)

local function applyNoclip()
    local character = LocalPlayer.Character

    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            object.CanCollide = false
        end
    end
end

local function stopNoclip()
    Session.Noclip = false

    updateToggleIndicator(NoclipIndicator, false)

    local character = LocalPlayer.Character

    if character then
        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("BasePart") then
                pcall(function()
                    object.CanCollide = true
                end)
            end
        end
    end
end

local function startNoclip()
    if not Session.Active or Session.Noclip then
        return
    end

    Session.Noclip = true

    updateToggleIndicator(NoclipIndicator, true)

    local connection = RunService.Stepped:Connect(function()
        if Session.Active and Session.Noclip then
            applyNoclip()
        end
    end)

    table.insert(Session.Connections, connection)
end

connect(NoclipRow.MouseButton1Click, function()
    if Session.Noclip then
        stopNoclip()
    else
        startNoclip()
    end
end)

connect(LocalPlayer.CharacterAdded, function(character)
    if not Session.Active then
        return
    end

    task.wait(0.5)

    if not Session.Active then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        local speed = tonumber(WalkSpeedBox.Text)
        local jump = tonumber(JumpPowerBox.Text)

        if speed then
            humanoid.WalkSpeed = speed
        end

        if jump then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = jump
        end
    end

    if Session.Noclip then
        applyNoclip()
    end

    if Session.Fly then
        stopFly()

        task.wait(0.1)

        if Session.Active then
            startFly()
        end
    end
end)

local function setActivePage(page)
    if not Session.Active then
        return
    end

    TeleporterPage.Visible = page == TeleporterPage
    SaverPage.Visible = page == SaverPage
    PlayerSettingsPage.Visible = page == PlayerSettingsPage

    local buttons = {
        {NavTeleporterBtn, TeleporterPage},
        {NavSaverBtn, SaverPage},
        {NavPlayerSettingsBtn, PlayerSettingsPage}
    }

    for _, data in ipairs(buttons) do
        data[1].BackgroundColor3 =
            data[2] == page
            and Color3.fromRGB(30, 30, 30)
            or Color3.fromRGB(25, 25, 25)

        data[1].TextColor3 =
            data[2] == page
            and Color3.fromRGB(0, 100, 255)
            or Color3.fromRGB(150, 150, 150)
    end
end

connect(NavTeleporterBtn.MouseButton1Click, function()
    setActivePage(TeleporterPage)
end)

connect(NavSaverBtn.MouseButton1Click, function()
    setActivePage(SaverPage)
end)

connect(NavPlayerSettingsBtn.MouseButton1Click, function()
    setActivePage(PlayerSettingsPage)
end)

local function openPlayerList()
    if not Session.Active then
        return
    end

    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local count = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            count += 1

            local button = Instance.new("TextButton")
            button.Parent = PlayerListFrame
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            button.Size = UDim2.new(1, 0, 0, 25)
            button.Font = Enum.Font.SourceSans
            button.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 12
            button.ZIndex = 6

            button.MouseButton1Click:Connect(function()
                if not Session.Active then
                    return
                end

                InputBox.Text = player.Name
                targetPlayerName = player.Name
                PlayerListFrame.Visible = false
                TPButton.Visible = true
            end)
        end
    end

    PlayerListFrame.CanvasSize =
        UDim2.new(0, 0, 0, count * 25)

    PlayerListFrame.Visible = true
    TPButton.Visible = false
end

connect(InputBox.Focused, openPlayerList)

connect(InputBox.FocusLost, function()
    task.wait(0.2)

    if not Session.Active then
        return
    end

    PlayerListFrame.Visible = false
    TPButton.Visible = true
    targetPlayerName = InputBox.Text
end)

local function teleportToPlayer()
    if not Session.Active then
        return
    end

    if targetPlayerName == "" then
        return
    end

    local target = Players:FindFirstChild(targetPlayerName)

    if not target then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower() == targetPlayerName:lower()
                or player.DisplayName:lower() == targetPlayerName:lower() then

                target = player
                break
            end
        end
    end

    if not target or not target.Character then
        return
    end

    if not LocalPlayer.Character then
        return
    end

    local targetRoot =
        target.Character:FindFirstChild("HumanoidRootPart")

    local localRoot =
        LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if targetRoot and localRoot then
        localRoot.CFrame = targetRoot.CFrame
    end
end

connect(TPButton.MouseButton1Click, teleportToPlayer)

local updateInstanceList

updateInstanceList = function()
    if not Session.Active then
        return
    end

    for _, child in ipairs(InstanceListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    CounterLabel.Text =
        "Slots: " .. #savedInstances .. " / " .. maxInstances

    for i, inst in ipairs(savedInstances) do
        if not inst.Part or not inst.Part.Parent then
            continue
        end

        local row = Instance.new("Frame")
        row.Parent = InstanceListFrame
        row.Size = UDim2.new(1, -5, 0, 24)
        row.BackgroundColor3 =
            selectedInstanceIndex == i
            and Color3.fromRGB(0, 40, 120)
            or Color3.fromRGB(25, 25, 25)
        row.BorderSizePixel = 0

        local selectButton = Instance.new("TextButton")
        selectButton.Parent = row
        selectButton.BackgroundTransparency = 1
        selectButton.Size = UDim2.new(0.6, 0, 1, 0)
        selectButton.Font = Enum.Font.Code

        local pos = inst.Part.Position

        selectButton.Text =
            " [" .. i .. "] " ..
            string.format(
                "X:%.0f Y:%.0f Z:%.0f",
                pos.X,
                pos.Y,
                pos.Z
            )

        selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectButton.TextSize = 10
        selectButton.TextXAlignment = Enum.TextXAlignment.Left

        selectButton.MouseButton1Click:Connect(function()
            if not Session.Active then
                return
            end

            if not inst.Part or not inst.Part.Parent then
                return
            end

            selectedInstanceIndex = i
            MoveHandles.Adornee = inst.Part

            local currentPos = inst.Part.Position

            InputX.Text = string.format("%.1f", currentPos.X)
            InputY.Text = string.format("%.1f", currentPos.Y)
            InputZ.Text = string.format("%.1f", currentPos.Z)

            updateInstanceList()
        end)

        local keyButton = Instance.new("TextButton")
        keyButton.Parent = row
        keyButton.Position = UDim2.new(0.6, 2, 0, 2)
        keyButton.Size = UDim2.new(0.25, -4, 1, -4)
        keyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        keyButton.Font = Enum.Font.Code
        keyButton.Text = inst.Key.Name
        keyButton.TextColor3 = Color3.fromRGB(0, 255, 150)
        keyButton.TextSize = 9

        keyButton.MouseButton1Click:Connect(function()
            if not Session.Active then
                return
            end

            bindingInstanceIndex = i
            listeningForUIBind = false
            listeningForTPBind = false
            keyButton.Text = "..."
        end)

        local deleteButton = Instance.new("TextButton")
        deleteButton.Parent = row
        deleteButton.Position = UDim2.new(0.85, 2, 0, 2)
        deleteButton.Size = UDim2.new(0.15, -4, 1, -4)
        deleteButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        deleteButton.Font = Enum.Font.SourceSansBold
        deleteButton.Text = "X"
        deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)

        deleteButton.MouseButton1Click:Connect(function()
            if not Session.Active then
                return
            end

            local part = inst.Part

            if part then
                pcall(function()
                    part:Destroy()
                end)
            end

            if MoveHandles.Adornee == part then
                MoveHandles.Adornee = nil
            end

            table.remove(savedInstances, i)

            if selectedInstanceIndex == i then
                selectedInstanceIndex =
                    #savedInstances > 0 and 1 or nil
            elseif selectedInstanceIndex
                and selectedInstanceIndex > i then

                selectedInstanceIndex -= 1
            end

            updateInstanceList()
        end)
    end

    InstanceListFrame.CanvasSize =
        UDim2.new(0, 0, 0, #savedInstances * 26)
end

connect(AddCubeBtn.MouseButton1Click, function()
    if not Session.Active then
        return
    end

    if #savedInstances >= maxInstances then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local part = Instance.new("Part")
    part.Name = "DENOS_WARE_TeleportPoint"
    part.Size = Vector3.new(3, 3, 3)
    part.Position = root.Position
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(0, 70, 255)
    part.Transparency = 0.4
    part.Parent = workspace

    local defaultKeys = {
        Enum.KeyCode.J,
        Enum.KeyCode.L,
        Enum.KeyCode.U,
        Enum.KeyCode.O,
        Enum.KeyCode.P
    }

    table.insert(savedInstances, {
        Part = part,
        Key = defaultKeys[#savedInstances + 1]
            or Enum.KeyCode.Unknown
    })

    selectedInstanceIndex = #savedInstances
    MoveHandles.Adornee = part

    updateInstanceList()
end)

local function modifyCoordinates()
    if not Session.Active then
        return
    end

    if not selectedInstanceIndex then
        return
    end

    local saved = savedInstances[selectedInstanceIndex]

    if not saved or not saved.Part then
        return
    end

    local part = saved.Part

    if not part.Parent then
        return
    end

    part.Position = Vector3.new(
        tonumber(InputX.Text) or part.Position.X,
        tonumber(InputY.Text) or part.Position.Y,
        tonumber(InputZ.Text) or part.Position.Z
    )

    updateInstanceList()
end

connect(InputX.FocusLost, modifyCoordinates)
connect(InputY.FocusLost, modifyCoordinates)
connect(InputZ.FocusLost, modifyCoordinates)

local handleStartPosition = nil

connect(MoveHandles.MouseButton1Down, function()
    if MoveHandles.Adornee then
        handleStartPosition = MoveHandles.Adornee.Position
    end
end)

connect(MoveHandles.MouseDrag, function(face, distance)
    if not Session.Active then
        return
    end

    if not MoveHandles.Adornee then
        return
    end

    if not handleStartPosition then
        return
    end

    MoveHandles.Adornee.Position =
        handleStartPosition +
        Vector3.FromNormalId(face) * distance

    if selectedInstanceIndex
        and savedInstances[selectedInstanceIndex]
        and savedInstances[selectedInstanceIndex].Part
            == MoveHandles.Adornee then

        local p = MoveHandles.Adornee.Position

        InputX.Text = string.format("%.1f", p.X)
        InputY.Text = string.format("%.1f", p.Y)
        InputZ.Text = string.format("%.1f", p.Z)
    end
end)

connect(MoveHandles.MouseButton1Up, function()
    handleStartPosition = nil

    if Session.Active then
        updateInstanceList()
    end
end)

connect(UIBindBtn.MouseButton1Click, function()
    if not Session.Active then
        return
    end

    listeningForUIBind = true
    listeningForTPBind = false
    bindingInstanceIndex = nil

    UIBindBtn.Text = "UI: [ ... ]"
    UIBindBtn.TextColor3 = Color3.fromRGB(0, 100, 255)
end)

connect(TPBindBtn.MouseButton1Click, function()
    if not Session.Active then
        return
    end

    listeningForTPBind = true
    listeningForUIBind = false
    bindingInstanceIndex = nil

    TPBindBtn.Text = "Fast TP: [ ... ]"
    TPBindBtn.TextColor3 = Color3.fromRGB(0, 100, 255)
end)

local cleaningUp = false

local function resetCharacter()
    local character = LocalPlayer.Character

    if not character then
        return
    end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = DEFAULT_WALKSPEED
        end)

        pcall(function()
            humanoid.UseJumpPower = true
        end)

        pcall(function()
            humanoid.JumpPower = DEFAULT_JUMPPOWER
        end)

        pcall(function()
            humanoid.PlatformStand = false
        end)

        pcall(function()
            humanoid.AutoRotate = true
        end)
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            pcall(function()
                object.CanCollide = true
            end)
        end

        if object.Name == "DENOS_WARE_FlyVelocity"
            or object.Name == "DENOS_WARE_FlyGyro" then

            pcall(function()
                object:Destroy()
            end)
        end
    end

    pcall(function()
        character:SetAttribute("DENOS_WARE_Fly", nil)
    end)

    pcall(function()
        character:SetAttribute("DENOS_WARE_Noclip", nil)
    end)
end

local function removeDenosObjects()
    for _, inst in ipairs(savedInstances) do
        if inst.Part then
            pcall(function()
                inst.Part:Destroy()
            end)
        end
    end

    table.clear(savedInstances)

    MoveHandles.Adornee = nil

    local character = LocalPlayer.Character

    if character then
        for _, object in ipairs(character:GetDescendants()) do
            if object.Name == "DENOS_WARE_FlyVelocity"
                or object.Name == "DENOS_WARE_FlyGyro" then

                pcall(function()
                    object:Destroy()
                end)
            end
        end
    end

    local gui = PlayerGui:FindFirstChild("DENOS_WARE_Panel")

    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end
end

local function fullyDestroy()
    if cleaningUp then
        return
    end

    cleaningUp = true

    Session.Active = false
    Session.Fly = false
    Session.Noclip = false

    listeningForUIBind = false
    listeningForTPBind = false
    bindingInstanceIndex = nil

    removeFlyObjects()

    pcall(function()
        resetCharacter()
    end)

    pcall(function()
        workspace.Gravity = DEFAULT_GRAVITY
    end)

    pcall(function()
        removeDenosObjects()
    end)

    disconnectAll()

    pcall(function()
        local character = LocalPlayer.Character

        if character then
            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid.WalkSpeed = DEFAULT_WALKSPEED
                humanoid.UseJumpPower = true
                humanoid.JumpPower = DEFAULT_JUMPPOWER
                humanoid.PlatformStand = false
                humanoid.AutoRotate = true
            end

            for _, object in ipairs(character:GetDescendants()) do
                if object:IsA("BasePart") then
                    object.CanCollide = true
                end
            end
        end
    end)

    if _G.DenosWareSession == Session then
        _G.DenosWareSession = nil
    end

    table.clear(Session)

    print("DENOS WARE successfully deactivated")
end

Session.Cleanup = fullyDestroy

connect(CloseButton.MouseButton1Click, fullyDestroy)

connect(UserInputService.InputBegan, function(input, gameProcessed)
    if not Session.Active then
        return
    end

    if listeningForUIBind
        or listeningForTPBind
        or bindingInstanceIndex then

        if input.UserInputType == Enum.UserInputType.Keyboard then

            if listeningForUIBind then
                panelToggleKey = input.KeyCode

                UIBindBtn.Text =
                    "UI: [ " .. panelToggleKey.Name .. " ]"

                UIBindBtn.TextColor3 =
                    Color3.fromRGB(120, 120, 120)

                listeningForUIBind = false

            elseif listeningForTPBind then
                instantTPKey = input.KeyCode

                TPBindBtn.Text =
                    "Fast TP: [ " .. instantTPKey.Name .. " ]"

                TPBindBtn.TextColor3 =
                    Color3.fromRGB(120, 120, 120)

                listeningForTPBind = false

            elseif bindingInstanceIndex
                and savedInstances[bindingInstanceIndex] then

                savedInstances[bindingInstanceIndex].Key =
                    input.KeyCode

                bindingInstanceIndex = nil

                updateInstanceList()
            end
        end

        return
    end

    if gameProcessed then
        return
    end

    if panelToggleKey
        and input.KeyCode == panelToggleKey then

        MainFrame.Visible = not MainFrame.Visible
    end

    if instantTPKey
        and input.KeyCode == instantTPKey then

        teleportToPlayer()
    end

    for _, inst in ipairs(savedInstances) do
        if inst.Key and input.KeyCode == inst.Key then

            if LocalPlayer.Character
                and inst.Part
                and inst.Part.Parent then

                local root =
                    LocalPlayer.Character:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if root then
                    root.CFrame =
                        CFrame.new(
                            inst.Part.Position +
                            Vector3.new(0, 3, 0)
                        )
                end
            end

            break
        end
    end
end)

setActivePage(TeleporterPage)

updateToggleIndicator(FlyIndicator, false)
updateToggleIndicator(NoclipIndicator, false)

print("DENOS WARE successfully loaded")
