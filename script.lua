local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char) character = char end)

-- Status Variables
local flying, noclip, isInvis, spinning, orbiting = false, false, false, false, false
local flySpeed, spinSpeedRPM = 50, 10
local orbitRadius, orbitHeight, orbitAngle = 5, 0, 0
local targetOrbitPlayer = nil
local disabledParts, originalTransparencies = {}, {}

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevControlPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 580)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -290)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Draggable, mainFrame.Active, mainFrame.Visible = true, true, false
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "  Developer Control Panel"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font, titleLabel.TextSize, titleLabel.TextXAlignment = Enum.Font.SourceSansBold, 18, Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local buttonContainer = Instance.new("ScrollingFrame")
buttonContainer.Size = UDim2.new(1, 0, 1, -40)
buttonContainer.Position = UDim2.new(0, 0, 0, 40)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ScrollBarThickness = 4
buttonContainer.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.HorizontalAlignment, listLayout.SortOrder = Enum.HorizontalAlignment.Center, Enum.SortOrder.LayoutOrder
listLayout.Parent = buttonContainer

local function createButton(text, order, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 260, 0, 34)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    btn.Text, btn.TextColor3 = text, Color3.fromRGB(255, 255, 255)
    btn.Font, btn.TextSize = Enum.Font.SourceSansBold, 14
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    btn.Parent = buttonContainer
    return btn
end

local function createTextBox(placeholder, text, order)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 260, 0, 32)
    box.LayoutOrder = order
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.PlaceholderText, box.Text, box.TextColor3 = placeholder, text, Color3.fromRGB(255, 255, 255)
    box.Font, box.TextSize = Enum.Font.SourceSans, 14
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = box
    box.Parent = buttonContainer
    return box
end

local flyBtn = createButton("Fly: OFF", 1, Color3.fromRGB(70, 30, 30))
local noclipBtn = createButton("Noclip: OFF", 2, Color3.fromRGB(70, 30, 30))
local invisBtn = createButton("Invisibility: OFF", 3, Color3.fromRGB(70, 30, 30))
local tpInput = createTextBox("Teleport: Choose player...", "", 4)

local tpListFrame = Instance.new("ScrollingFrame")
tpListFrame.Size = UDim2.new(0, 260, 0, 100)
tpListFrame.Position = UDim2.new(0.5, -130, 0, 160)
tpListFrame.BackgroundColor3, tpListFrame.BorderSizePixel, tpListFrame.ZIndex = Color3.fromRGB(20, 20, 20), 0, 10
tpListFrame.Visible, tpListFrame.ScrollBarThickness = false, 6
tpListFrame.Parent = mainFrame

local tpListLayout = Instance.new("UIListLayout")
tpListLayout.Padding = UDim.new(0, 4)
tpListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tpListLayout.Parent = tpListFrame
Instance.new("UICorner", tpListFrame).CornerRadius = UDim.new(0, 6)

local tpBtn = createButton("Teleport to Player", 5, Color3.fromRGB(0, 120, 215))

-- ORBIT SELECTION & CONFIGURATION ELEMENTS
local orbitInput = createTextBox("Orbit: Choose player...", "", 6)

local orbitListFrame = Instance.new("ScrollingFrame")
orbitListFrame.Size = UDim2.new(0, 260, 0, 100)
orbitListFrame.Position = UDim2.new(0.5, -130, 0, 235)
orbitListFrame.BackgroundColor3, orbitListFrame.BorderSizePixel, orbitListFrame.ZIndex = Color3.fromRGB(20, 20, 20), 0, 10
orbitListFrame.Visible, orbitListFrame.ScrollBarThickness = false, 6
orbitListFrame.Parent = mainFrame

local orbitListLayout = Instance.new("UIListLayout")
orbitListLayout.Padding = UDim.new(0, 4)
orbitListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
orbitListLayout.Parent = orbitListFrame
Instance.new("UICorner", orbitListFrame).CornerRadius = UDim.new(0, 6)

local orbitRadiusInput = createTextBox("Orbit Radius (Studs)", "5", 7)
local orbitHeightInput = createTextBox("Orbit Height (Studs)", "0", 8)
local orbitBtn = createButton("Orbit: OFF", 9, Color3.fromRGB(70, 30, 30))

local spinInput = createTextBox("Spin Speed (RPM)...", "10", 10)
local spinBtn = createButton("Spin: OFF", 11, Color3.fromRGB(70, 30, 30))
local resetBtn = createButton("Reset All (Stats & Body)", 12, Color3.fromRGB(215, 85, 0))
local destroyBtn = createButton("Destroy GUI & Effects", 13, Color3.fromRGB(180, 25, 25))

buttonContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 120, 0, 40)
toggleButton.Position = UDim2.new(1, -140, 1, -60)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.Text, toggleButton.TextColor3 = "Open Panel", Color3.fromRGB(255, 255, 255)
toggleButton.Font, toggleButton.TextSize = Enum.Font.SourceSansBold, 16
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)
toggleButton.Parent = screenGui

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    toggleButton.Text = mainFrame.Visible and "Close Panel" or "Open Panel"
    if not mainFrame.Visible then tpListFrame.Visible, orbitListFrame.Visible = false, false end
end)

local function resetEnvironmentCollision()
    for part, _ in pairs(disabledParts) do if part and part.Parent then part.CanCollide = true end end
    table.clear(disabledParts)
end

local function stopFlying()
    flying = false
    flyBtn.Text, flyBtn.BackgroundColor3 = "Fly: OFF", Color3.fromRGB(70, 30, 30)
    if character then
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp:FindFirstChild("BodyVelocity") then hrp.BodyVelocity:Destroy() end
            if hrp:FindFirstChild("BodyGyro") then hrp.BodyGyro:Destroy() end
        end
    end
end

local function stopSpinning()
    spinning = false
    spinBtn.Text, spinBtn.BackgroundColor3 = "Spin: OFF", Color3.fromRGB(70, 30, 30)
    if character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart:FindFirstChild("SpinAngularVelocity") then
        character.HumanoidRootPart.SpinAngularVelocity:Destroy()
    end
end

local function stopOrbiting()
    orbiting = false
    orbitBtn.Text, orbitBtn.BackgroundColor3 = "Orbit: OFF", Color3.fromRGB(70, 30, 30)
    targetOrbitPlayer = nil
    if character and character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end
local function setupDropdownLogics(inputBox, displayFrame, layoutObj)
    local function refresh()
        for _, child in pairs(displayFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                local pBtn = Instance.new("TextButton")
                pBtn.Size, pBtn.BackgroundColor3 = UDim2.new(1, -10, 0, 30), Color3.fromRGB(45, 45, 45)
                pBtn.Text, pBtn.TextColor3 = "  " .. p.DisplayName .. " (@" .. p.Name .. ")", Color3.fromRGB(255, 255, 255)
                pBtn.Font, pBtn.TextXAlignment, pBtn.TextSize, pBtn.ZIndex = Enum.Font.SourceSans, Enum.TextXAlignment.Left, 14, 11
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
                pBtn.MouseButton1Click:Connect(function() inputBox.Text = p.Name; displayFrame.Visible = false end)
                pBtn.Parent = displayFrame
            end
        end
        displayFrame.CanvasSize = UDim2.new(0, 0, 0, layoutObj.AbsoluteContentSize.Y)
    end
    inputBox.Focused:Connect(function() refresh(); displayFrame.Visible = true end)
end

setupDropdownLogics(tpInput, tpListFrame, tpListLayout)
setupDropdownLogics(orbitInput, orbitListFrame, orbitListLayout)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        task.wait(0.1)
        if UserInputService:GetFocusedTextBox() ~= tpInput then tpListFrame.Visible = false end
        if UserInputService:GetFocusedTextBox() ~= orbitInput then orbitListFrame.Visible = false end
    end
end)

flyBtn.MouseButton1Click:Connect(function()
    if not flying then
        if spinning then stopSpinning() end
        if orbiting then stopOrbiting() end
        flying = true
        flyBtn.Text, flyBtn.BackgroundColor3 = "Fly: ON", Color3.fromRGB(30, 70, 30)
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            hum.PlatformStand = true
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce, bv.Velocity, bv.Parent = Vector3.new(1e5, 1e5, 1e5), Vector3.new(0, 0, 0), hrp
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque, bg.CFrame, bg.Parent = Vector3.new(1e5, 1e5, 1e5), hrp.CFrame, hrp
        end
    else
        stopFlying()
        if not noclip then resetEnvironmentCollision() end
    end
end)

RunService.RenderStepped:Connect(function()
    if flying and character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local moveDirection = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        local bv, bg = hrp:FindFirstChild("BodyVelocity"), hrp:FindFirstChild("BodyGyro")
        if bv and bg then bv.Velocity = moveDirection * flySpeed; bg.CFrame = cam.CFrame end
    end
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclip = not noclip
    noclipBtn.Text = noclip and "Noclip: ON" or "Noclip: OFF"
    noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(30, 70, 30) or Color3.fromRGB(70, 30, 30)
    if not noclip then resetEnvironmentCollision() end
end)

RunService.Stepped:Connect(function()
    if not character then return end
    if noclip or flying or orbiting then
        for _, part in pairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end
    if noclip and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        for _, part in pairs(workspace:GetPartsInPart(hrp)) do
            if part.CanCollide and not part:IsDescendantOf(character) then
                if flying or orbiting then disabledParts[part] = true; part.CanCollide = false
                else
                    local _, upVector = part.CFrame:ToWorldSpace():ToAxisAngle()
                    local angle = math.deg(math.acos(math.clamp(upVector.Y, -1, 1)))
                    if angle >= 25 then disabledParts[part] = true; part.CanCollide = false end
                end
            end
        end
    end
end)
-- ORBIT LOOP PROCESSING
RunService.Heartbeat:Connect(function(dt)
    if orbiting and targetOrbitPlayer and targetOrbitPlayer.Character and character then
        local tHrp = targetOrbitPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = character:FindFirstChild("HumanoidRootPart")
        local hum = character:FindFirstChildOfClass("Humanoid")
        
        if tHrp and myHrp then
            if hum then hum.PlatformStand = true end
            orbitAngle = orbitAngle + (dt * 3)
            
            local offsetX = math.cos(orbitAngle) * orbitRadius
            local offsetZ = math.sin(orbitAngle) * orbitRadius
            local targetPos = tHrp.Position + Vector3.new(offsetX, orbitHeight, offsetZ)
            
            myHrp.CFrame = CFrame.new(targetPos, Vector3.new(tHrp.Position.X, targetPos.Y, tHrp.Position.Z))
        end
    elseif orbiting then
        stopOrbiting()
    end
end)

orbitBtn.MouseButton1Click:Connect(function()
    orbiting = not orbiting
    if orbiting then
        local targetName = orbitInput.Text:lower()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():sub(1, #targetName) == targetName or p.DisplayName:lower():sub(1, #targetName) == targetName) then
                targetOrbitPlayer = p
                break
            end
        end
        if targetOrbitPlayer then
            if flying then stopFlying() end
            if spinning then stopSpinning() end
            orbitRadius = tonumber(orbitRadiusInput.Text) or 5
            orbitHeight = tonumber(orbitHeightInput.Text) or 0
            orbitBtn.Text, orbitBtn.BackgroundColor3 = "Orbit: ON", Color3.fromRGB(30, 70, 30)
        else
            orbiting = false
        end
    else
        stopOrbiting()
    end
end)

invisBtn.MouseButton1Click:Connect(function()
    isInvis = not isInvis
    invisBtn.Text = isInvis and "Invisibility: ON" or "Invisibility: OFF"
    invisBtn.BackgroundColor3 = isInvis and Color3.fromRGB(30, 70, 30) or Color3.fromRGB(70, 30, 30)
    if isInvis then
        table.clear(originalTransparencies)
        for _, obj in pairs(character:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then originalTransparencies[obj] = obj.Transparency; obj.Transparency = 1 end
        end
    else
        for obj, originalValue in pairs(originalTransparencies) do if obj and obj.Parent then obj.Transparency = originalValue end end
        table.clear(originalTransparencies)
    end
end)

tpBtn.MouseButton1Click:Connect(function()
    local targetName = tpInput.Text:lower()
    if targetName ~= "" then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():sub(1, #targetName) == targetName or p.DisplayName:lower():sub(1, #targetName) == targetName) then
                local tChar = p.Character
                local myHrp, tHrp = character:FindFirstChild("HumanoidRootPart"), tChar and tChar:FindFirstChild("HumanoidRootPart")
                if myHrp and tHrp then myHrp.CFrame = tHrp.CFrame + Vector3.new(0, 3, 0); break end
            end
        end
    end
end)

spinInput.FocusLost:Connect(function()
    local num = tonumber(spinInput.Text)
    if num then spinSpeedRPM = num else spinInput.Text = tostring(spinSpeedRPM) end
    if spinning and character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart:FindFirstChild("SpinAngularVelocity") then
        character.HumanoidRootPart.SpinAngularVelocity.AngularVelocity = Vector3.new(0, (spinSpeedRPM * (2 * math.pi)) / 60, 0)
    end
end)

spinBtn.MouseButton1Click:Connect(function()
    spinning = not spinning
    spinBtn.Text = spinning and "Spin: ON" or "Spin: OFF"
    spinBtn.BackgroundColor3 = spinning and Color3.fromRGB(30, 70, 30) or Color3.fromRGB(70, 30, 30)
    if spinning then
        if flying then stopFlying() end
        if orbiting then stopOrbiting() end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bav = Instance.new("BodyAngularVelocity")
            bav.Name = "SpinAngularVelocity"
            bav.MaxTorque = Vector3.new(0, 1e6, 0)
            bav.AngularVelocity = Vector3.new(0, (spinSpeedRPM * (2 * math.pi)) / 60, 0)
            bav.Parent = hrp
        end
    else stopSpinning() end
end)

resetBtn.MouseButton1Click:Connect(function()
    stopFlying(); stopSpinning(); stopOrbiting(); noclip, isInvis = false, false
    noclipBtn.Text, noclipBtn.BackgroundColor3 = "Noclip: OFF", Color3.fromRGB(70, 30, 30)
    invisBtn.Text, invisBtn.BackgroundColor3 = "Invisibility: OFF", Color3.fromRGB(70, 30, 30)
    resetEnvironmentCollision()
    if character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").Health = 0 end
end)

destroyBtn.MouseButton1Click:Connect(function() stopFlying(); stopSpinning(); stopOrbiting(); resetEnvironmentCollision(); screenGui:Destroy() end)
