-- VITOR HUB - VERSION COMPLETE (UPDATED 2026) - COM AIM IGNORE POPUP E SCRIPTS MENU CORRIGIDO
-- Compatible with: Delta, Arceus X, Ronix, Fluxus, Solara

repeat wait() until game:IsLoaded()
repeat wait() until game.Players.LocalPlayer

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local Clipboard = (setclipboard or toclipboard or function() end)

-- ==================== CENTRALIZED STATE SYSTEM ====================
local UIState = {
    currentSpeed = 16,
    currentJump = 50,
    currentTPWalkSpeed = 16,
    infjumpEnabled = false,
    xrayEnabled = false,
    noclipEnabled = false,
    fullbrightEnabled = false,
    noFogEnabled = false,
    dayEnabled = false,
    nightEnabled = false,
    tpwalkEnabled = false,
    ghostEnabled = false,
    aimbotChaseEnabled = false,
    aimbotNormalEnabled = false,
    telekillEnabled = false,
    bringAllEnabled = false,
    freeCamEnabled = false,
    rainbowActive = true,
    currentColor = Color3.fromRGB(0, 170, 255),
    rVal = 0,
    gVal = 170,
    bVal = 255,
    IgnoreList = {},
    TelekillIgnoreList = {},
    AimbotIgnoreList = {},
    sessionStart = os.time(),
    noClipCameraEnabled = false,
    aimbotChaseDistance = 200,
    aimbotNormalDistance = 200,
}

-- ==================== PLAYER CACHE SYSTEM ====================
local PlayerCache = { list = {}, thumbnails = {}, lastUpdate = 0 }

local function updatePlayerCache()
    local newList = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(newList, plr)
        end
    end
    table.sort(newList, function(a, b) return a.Name:lower() < b.Name:lower() end)
    PlayerCache.list = newList
    PlayerCache.lastUpdate = tick()
end

local function getPlayerThumbnail(userId)
    if PlayerCache.thumbnails[userId] then
        return PlayerCache.thumbnails[userId]
    end
    local success, thumbnail = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    local result = success and thumbnail or "rbxasset://textures/ui/GuiImagePlaceholder.png"
    PlayerCache.thumbnails[userId] = result
    return result
end

updatePlayerCache()

-- ==================== AIMBOT IGNORE FUNCTIONS ====================
local function AddAimbotIgnore(userId)
    if not userId then return end
    for _, id in pairs(UIState.AimbotIgnoreList) do
        if id == userId then return end
    end
    table.insert(UIState.AimbotIgnoreList, userId)
end

local function RemoveAimbotIgnore(userId)
    for i, id in pairs(UIState.AimbotIgnoreList) do
        if id == userId then
            table.remove(UIState.AimbotIgnoreList, i)
            break
        end
    end
end

local function IsAimbotIgnored(userId)
    for _, id in pairs(UIState.AimbotIgnoreList) do
        if id == userId then return true end
    end
    return false
end

-- ==================== JUMP POWER ====================
local function setJumpPower(value)
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local humanoid = char.Humanoid
        pcall(function() humanoid.JumpPower = value end)
        pcall(function() humanoid.JumpHeight = value * 0.144 end)
        pcall(function() humanoid.UseJumpPower = true end)
    end
end

-- ==================== VARIABLES ====================
local infjump = UIState.infjumpEnabled
local xray = UIState.xrayEnabled
local noclipEnabled = UIState.noclipEnabled
local noclipConnection = nil
local fullbrightEnabled = UIState.fullbrightEnabled
local fullbrightConnection = nil
local noFogEnabled = UIState.noFogEnabled
local dayEnabled = UIState.dayEnabled
local nightEnabled = UIState.nightEnabled
local tpwalkEnabled = UIState.tpwalkEnabled
local tpwalkConnection = nil
local tpwalkSpeed = UIState.currentTPWalkSpeed
local ghostEnabled = UIState.ghostEnabled
local noClipCameraEnabled = UIState.noClipCameraEnabled

local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogEnd = Lighting.FogEnd
local originalGlobalShadows = Lighting.GlobalShadows
local originalClockTime = Lighting.ClockTime
local originalOcclusionMode = nil

-- ==================== NO CLIP CAMERA ====================
local function toggleNoClipCamera(state)
    noClipCameraEnabled = state
    UIState.noClipCameraEnabled = state
    if state then
        originalOcclusionMode = player.DevCameraOcclusionMode
        player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        StarterGui:SetCore("SendNotification", { Title = "No Clip Camera", Text = "Activated - Camera goes through walls", Duration = 2 })
    else
        player.DevCameraOcclusionMode = originalOcclusionMode or Enum.DevCameraOcclusionMode.Zoom
        StarterGui:SetCore("SendNotification", { Title = "No Clip Camera", Text = "Deactivated - Normal camera", Duration = 2 })
    end
end

-- ==================== FLOAT FUNCTION (DRAGGABLE) ====================
local function executeFloat()
    pcall(function()
        local plr = Players.LocalPlayer
        local floatEnabled = false
        local upHold = false
        local downHold = false
        local floatSpeed = 35
        local character, root, humanoid
        local floors = {}
        local bodyVel = nil
        local draggingFloat = false
        local dragStartFloat = nil

        local function setupChar()
            character = plr.Character or plr.CharacterAdded:Wait()
            root = character:WaitForChild("HumanoidRootPart")
            humanoid = character:WaitForChild("Humanoid")
        end

        setupChar()
        plr.CharacterAdded:Connect(function() task.wait(0.5); setupChar() end)

        local gui = Instance.new("ScreenGui")
        gui.Name = "FloatGui"
        gui.ResetOnSpawn = false
        gui.Parent = game.CoreGui

        local frame = Instance.new("Frame", gui)
        frame.Size = UDim2.new(0,120,0,180)
        frame.Position = UDim2.new(0,20,0.4,0)
        frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
        frame.Active = true
        
        local titleBar = Instance.new("Frame", frame)
        titleBar.Size = UDim2.new(1,0,0,25)
        titleBar.Position = UDim2.new(0,0,0,0)
        titleBar.BackgroundColor3 = Color3.fromRGB(0,170,255)
        titleBar.BackgroundTransparency = 0.5
        titleBar.Active = true
        
        local titleLabel = Instance.new("TextLabel", titleBar)
        titleLabel.Size = UDim2.new(1,0,1,0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "≡ FLOAT ≡"
        titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
        titleLabel.TextSize = 12
        titleLabel.Font = Enum.Font.GothamBold
        
        local exit = Instance.new("TextButton", frame)
        exit.Size = UDim2.new(1,0,0,30)
        exit.Position = UDim2.new(0,0,0,30)
        exit.Text = "Exit"
        exit.BackgroundColor3 = Color3.fromRGB(150,0,0)

        local toggle = Instance.new("TextButton", frame)
        toggle.Position = UDim2.new(0,0,0,65)
        toggle.Size = UDim2.new(1,0,0,40)
        toggle.Text = "OFF"

        local up = Instance.new("TextButton", frame)
        up.Position = UDim2.new(0,0,0,110)
        up.Size = UDim2.new(1,0,0,40)
        up.Text = "↑"

        local down = Instance.new("TextButton", frame)
        down.Position = UDim2.new(0,0,0,155)
        down.Size = UDim2.new(1,0,0,40)
        down.Text = "↓"

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingFloat = true
                dragStartFloat = input.Position
            end
        end)
        
        UIS.InputChanged:Connect(function(input)
            if draggingFloat and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStartFloat
                frame.Position = UDim2.new(0, frame.AbsolutePosition.X + delta.X, 0, frame.AbsolutePosition.Y + delta.Y)
                dragStartFloat = input.Position
            end
        end)
        
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingFloat = false
            end
        end)

        up.MouseButton1Down:Connect(function() upHold = true end)
        up.MouseButton1Up:Connect(function() upHold = false end)
        down.MouseButton1Down:Connect(function() downHold = true end)
        down.MouseButton1Up:Connect(function() downHold = false end)

        local function createFloor()
            local p = Instance.new("Part")
            p.Size = Vector3.new(500,1,500)
            p.Position = root.Position - Vector3.new(0,3,0)
            p.Anchored = true
            p.Transparency = 1
            p.CanCollide = true
            p.Parent = workspace
            table.insert(floors, p)
        end

        local function removeAllFloors()
            for _,p in ipairs(floors) do if p then p:Destroy() end end
            floors = {}
        end

        RunService.Stepped:Connect(function()
            if floatEnabled and character then
                for _,v in ipairs(character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)

        local function restoreCollision()
            if character then
                for _,v in ipairs(character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true end
                end
            end
        end

        exit.MouseButton1Click:Connect(function()
            floatEnabled = false
            removeAllFloors()
            if bodyVel then bodyVel:Destroy() end
            restoreCollision()
            gui:Destroy()
        end)

        toggle.MouseButton1Click:Connect(function()
            floatEnabled = not floatEnabled
            toggle.Text = floatEnabled and "ON" or "OFF"
            if floatEnabled then
                humanoid.WalkSpeed = 35
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
                bodyVel.Velocity = Vector3.new(0,0,0)
                bodyVel.Parent = root
            else
                removeAllFloors()
                if bodyVel then bodyVel:Destroy() end
                restoreCollision()
                humanoid.WalkSpeed = 16
            end
        end)

        RunService.RenderStepped:Connect(function()
            if not root or not humanoid then return end
            if floatEnabled and bodyVel then
                if upHold then
                    bodyVel.Velocity = Vector3.new(0, floatSpeed, 0)
                elseif downHold then
                    bodyVel.Velocity = Vector3.new(0, -floatSpeed, 0)
                else
                    bodyVel.Velocity = Vector3.new(0, 0, 0)
                    if not floors[#floors] or (root.Position - floors[#floors].Position).Magnitude > 5 then
                        createFloor()
                    end
                end
            end
        end)
    end)
end

-- ==================== FREE CAM ====================
local freeCamEnabled = UIState.freeCamEnabled
local freeCamScriptActive = false
local freeCamButtonRef = nil
local freeCamGuiInstance = nil
local freeCamMoveConnection = nil
local freeCamSpeedValue = 2

local function AncorarPersonagem()
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = false
            end
        end
    end
end

local function DesancorarPersonagem()
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = true
            end
        end
    end
end

local function TeleportarPersonagemFreeCam()
    local posicaoAtualCamera = Camera.CFrame.Position
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        DesancorarPersonagem()
        player.Character.HumanoidRootPart.CFrame = CFrame.new(posicaoAtualCamera)
        task.wait(0.05)
        if freeCamEnabled then AncorarPersonagem() end
        pcall(function()
            StarterGui:SetCore("SendNotification", { Title = "Free Cam", Text = "Teleported to camera position!", Duration = 2 })
        end)
    end
end

local function activateFreeCam()
    if freeCamScriptActive then return end
    freeCamEnabled = true
    UIState.freeCamEnabled = true
    freeCamScriptActive = true
    
    local freeCamYaw = 0
    local freeCamPitch = 0
    local moveForward = false
    local moveBack = false
    local moveLeft = false
    local moveRight = false
    local moveUp = false
    local moveDown = false
    local lastPosition = Camera.CFrame.Position
    
    local camCF = Camera.CFrame
    local look = camCF.LookVector
    freeCamYaw = math.atan2(-look.X, -look.Z)
    freeCamPitch = math.asin(look.Y)
    lastPosition = camCF.Position
    
    local freeCamGUI = Instance.new("ScreenGui")
    freeCamGUI.Name = "FreeCamGUI_Vitor"
    freeCamGUI.ResetOnSpawn = false
    freeCamGUI.Parent = player:FindFirstChild("PlayerGui") or CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = freeCamGUI
    mainFrame.Size = UDim2.new(0, 180, 0, 160)
    mainFrame.Position = UDim2.new(0.5, -90, 0.4, -80)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = mainFrame
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Thickness = 1.5
    
    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 0.2
    title.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
    title.Text = "FREE CAM"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    
    local speedText = Instance.new("TextLabel")
    speedText.Parent = mainFrame
    speedText.Size = UDim2.new(0.4, 0, 0, 25)
    speedText.Position = UDim2.new(0, 10, 0, 40)
    speedText.BackgroundTransparency = 1
    speedText.Text = "Speed:"
    speedText.TextColor3 = Color3.fromRGB(180, 180, 180)
    speedText.TextSize = 12
    speedText.Font = Enum.Font.Gotham
    speedText.TextXAlignment = Enum.TextXAlignment.Left
    
    local speedInput = Instance.new("TextBox")
    speedInput.Parent = mainFrame
    speedInput.Size = UDim2.new(0, 50, 0, 25)
    speedInput.Position = UDim2.new(0.55, 0, 0, 40)
    speedInput.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    speedInput.BackgroundTransparency = 0.2
    speedInput.Text = tostring(freeCamSpeedValue)
    speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedInput.TextSize = 14
    speedInput.Font = Enum.Font.GothamBold
    speedInput.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 6)
    
    local speedDown = Instance.new("TextButton")
    speedDown.Parent = mainFrame
    speedDown.Size = UDim2.new(0, 25, 0, 25)
    speedDown.Position = UDim2.new(0.75, 0, 0, 40)
    speedDown.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    speedDown.Text = "-"
    speedDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedDown.TextSize = 18
    speedDown.Font = Enum.Font.GothamBold
    Instance.new("UICorner", speedDown).CornerRadius = UDim.new(0, 6)
    
    local speedUp = Instance.new("TextButton")
    speedUp.Parent = mainFrame
    speedUp.Size = UDim2.new(0, 25, 0, 25)
    speedUp.Position = UDim2.new(0.85, 0, 0, 40)
    speedUp.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    speedUp.Text = "+"
    speedUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedUp.TextSize = 18
    speedUp.Font = Enum.Font.GothamBold
    Instance.new("UICorner", speedUp).CornerRadius = UDim.new(0, 6)
    
    local teleportBtn = Instance.new("TextButton")
    teleportBtn.Parent = mainFrame
    teleportBtn.Size = UDim2.new(0.8, 0, 0, 30)
    teleportBtn.Position = UDim2.new(0.1, 0, 0, 75)
    teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    teleportBtn.Text = "TELEPORT"
    teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportBtn.TextSize = 12
    teleportBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", teleportBtn).CornerRadius = UDim.new(0, 6)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0.8, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.1, 0, 0, 115)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    closeBtn.Text = "EXIT"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    
    local function updateSpeed()
        local newSpeed = tonumber(speedInput.Text)
        if newSpeed and newSpeed > 0 then
            freeCamSpeedValue = math.min(newSpeed, 1000)
            speedInput.Text = tostring(freeCamSpeedValue)
        else
            speedInput.Text = tostring(freeCamSpeedValue)
        end
    end
    
    speedInput.FocusLost:Connect(updateSpeed)
    speedDown.MouseButton1Click:Connect(function()
        freeCamSpeedValue = math.max(1, freeCamSpeedValue - 1)
        speedInput.Text = tostring(freeCamSpeedValue)
    end)
    speedUp.MouseButton1Click:Connect(function()
        freeCamSpeedValue = math.min(1000, freeCamSpeedValue + 1)
        speedInput.Text = tostring(freeCamSpeedValue)
    end)
    
    teleportBtn.MouseButton1Click:Connect(TeleportarPersonagemFreeCam)
    
    -- D-PAD for movement
    local dpadFrame = Instance.new("Frame")
    dpadFrame.Parent = freeCamGUI
    dpadFrame.Size = UDim2.new(0, 200, 0, 200)
    dpadFrame.Position = UDim2.new(0.02, 0, 0.6, 0)
    dpadFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dpadFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", dpadFrame).CornerRadius = UDim.new(0, 20)
    
    local btnSize = 60
    local upBtn = Instance.new("TextButton")
    upBtn.Parent = dpadFrame
    upBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    upBtn.Position = UDim2.new(0.5, -btnSize/2, 0, 10)
    upBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    upBtn.Text = "↑"
    upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    upBtn.TextSize = 30
    upBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 12)
    
    local leftBtn = Instance.new("TextButton")
    leftBtn.Parent = dpadFrame
    leftBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    leftBtn.Position = UDim2.new(0, 10, 0.5, -btnSize/2)
    leftBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    leftBtn.Text = "←"
    leftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    leftBtn.TextSize = 30
    leftBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", leftBtn).CornerRadius = UDim.new(0, 12)
    
    local downBtn = Instance.new("TextButton")
    downBtn.Parent = dpadFrame
    downBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    downBtn.Position = UDim2.new(0.5, -btnSize/2, 1, -btnSize - 10)
    downBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    downBtn.Text = "↓"
    downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    downBtn.TextSize = 30
    downBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 12)
    
    local rightBtn = Instance.new("TextButton")
    rightBtn.Parent = dpadFrame
    rightBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    rightBtn.Position = UDim2.new(1, -btnSize - 10, 0.5, -btnSize/2)
    rightBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    rightBtn.Text = "→"
    rightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rightBtn.TextSize = 30
    rightBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", rightBtn).CornerRadius = UDim.new(0, 12)
    
    local vertFrame = Instance.new("Frame")
    vertFrame.Parent = freeCamGUI
    vertFrame.Size = UDim2.new(0, 80, 0, 140)
    vertFrame.Position = UDim2.new(0.02, 210, 0.6, 30)
    vertFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    vertFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", vertFrame).CornerRadius = UDim.new(0, 12)
    
    local subirBtn = Instance.new("TextButton")
    subirBtn.Parent = vertFrame
    subirBtn.Size = UDim2.new(0, 70, 0, 55)
    subirBtn.Position = UDim2.new(0.5, -35, 0, 8)
    subirBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    subirBtn.Text = "▲"
    subirBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    subirBtn.TextSize = 24
    subirBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", subirBtn).CornerRadius = UDim.new(0, 12)
    
    local descerBtn = Instance.new("TextButton")
    descerBtn.Parent = vertFrame
    descerBtn.Size = UDim2.new(0, 70, 0, 55)
    descerBtn.Position = UDim2.new(0.5, -35, 1, -63)
    descerBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    descerBtn.Text = "▼"
    descerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    descerBtn.TextSize = 24
    descerBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", descerBtn).CornerRadius = UDim.new(0, 12)
    
    upBtn.MouseButton1Down:Connect(function() moveForward = true end)
    upBtn.MouseButton1Up:Connect(function() moveForward = false end)
    upBtn.MouseLeave:Connect(function() moveForward = false end)
    downBtn.MouseButton1Down:Connect(function() moveBack = true end)
    downBtn.MouseButton1Up:Connect(function() moveBack = false end)
    downBtn.MouseLeave:Connect(function() moveBack = false end)
    leftBtn.MouseButton1Down:Connect(function() moveLeft = true end)
    leftBtn.MouseButton1Up:Connect(function() moveLeft = false end)
    leftBtn.MouseLeave:Connect(function() moveLeft = false end)
    rightBtn.MouseButton1Down:Connect(function() moveRight = true end)
    rightBtn.MouseButton1Up:Connect(function() moveRight = false end)
    rightBtn.MouseLeave:Connect(function() moveRight = false end)
    subirBtn.MouseButton1Down:Connect(function() moveUp = true end)
    subirBtn.MouseButton1Up:Connect(function() moveUp = false end)
    subirBtn.MouseLeave:Connect(function() moveUp = false end)
    descerBtn.MouseButton1Down:Connect(function() moveDown = true end)
    descerBtn.MouseButton1Up:Connect(function() moveDown = false end)
    descerBtn.MouseLeave:Connect(function() moveDown = false end)
    
    local cameraTouchActive = false
    local cameraTouchId = nil
    
    local function isTouchOverButton(touchPos)
        local pos = dpadFrame.AbsolutePosition
        local size = dpadFrame.AbsoluteSize
        if touchPos.X >= pos.X and touchPos.X <= pos.X + size.X and
           touchPos.Y >= pos.Y and touchPos.Y <= pos.Y + size.Y then
            return true
        end
        local pos2 = vertFrame.AbsolutePosition
        local size2 = vertFrame.AbsoluteSize
        if touchPos.X >= pos2.X and touchPos.X <= pos2.X + size2.X and
           touchPos.Y >= pos2.Y and touchPos.Y <= pos2.Y + size2.Y then
            return true
        end
        return false
    end
    
    UIS.TouchStarted:Connect(function(touch)
        if not freeCamScriptActive then return end
        if not isTouchOverButton(touch.Position) then
            cameraTouchActive = true
            cameraTouchId = touch.KeyCode
        end
    end)
    
    UIS.TouchMoved:Connect(function(touch)
        if not freeCamScriptActive then return end
        if cameraTouchActive and touch.KeyCode == cameraTouchId then
            local delta = touch.Delta
            freeCamYaw = freeCamYaw - delta.X * 0.005
            freeCamPitch = math.clamp(freeCamPitch - delta.Y * 0.005, math.rad(-80), math.rad(80))
        end
    end)
    
    UIS.TouchEnded:Connect(function(touch)
        if touch.KeyCode == cameraTouchId then
            cameraTouchActive = false
            cameraTouchId = nil
        end
    end)
    
    AncorarPersonagem()
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = CFrame.new(lastPosition) * CFrame.Angles(0, freeCamYaw, 0) * CFrame.Angles(freeCamPitch, 0, 0)
    
    freeCamMoveConnection = RunService.RenderStepped:Connect(function(dt)
        if not freeCamScriptActive then return end
        local moveDirection = Vector3.new()
        local yawCF = CFrame.Angles(0, freeCamYaw, 0)
        local forwardVec = yawCF.LookVector
        local rightVec = yawCF.RightVector
        if moveForward then moveDirection = moveDirection + forwardVec end
        if moveBack then moveDirection = moveDirection - forwardVec end
        if moveLeft then moveDirection = moveDirection - rightVec end
        if moveRight then moveDirection = moveDirection + rightVec end
        if moveUp then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if moveDown then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        if moveDirection.Magnitude > 0 then
            lastPosition = lastPosition + (moveDirection.Unit * freeCamSpeedValue * dt * 60)
        end
        Camera.CFrame = CFrame.new(lastPosition) * CFrame.Angles(0, freeCamYaw, 0) * CFrame.Angles(freeCamPitch, 0, 0)
    end)
    
    local function destroyFreeCam()
        if freeCamMoveConnection then freeCamMoveConnection:Disconnect() end
        DesancorarPersonagem()
        Camera.CameraType = Enum.CameraType.Custom
        pcall(function() freeCamGUI:Destroy() end)
        freeCamScriptActive = false
        freeCamEnabled = false
        UIState.freeCamEnabled = false
        if freeCamButtonRef then
            freeCamButtonRef.Text = "Activate Free Cam"
            freeCamButtonRef.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        end
    end
    
    closeBtn.MouseButton1Click:Connect(destroyFreeCam)
    freeCamGuiInstance = freeCamGUI
end

local function deactivateFreeCam()
    if freeCamGuiInstance then pcall(function() freeCamGuiInstance:Destroy() end) end
    if freeCamMoveConnection then freeCamMoveConnection:Disconnect() end
    DesancorarPersonagem()
    Camera.CameraType = Enum.CameraType.Custom
    freeCamScriptActive = false
    freeCamEnabled = false
    UIState.freeCamEnabled = false
    if freeCamButtonRef then
        freeCamButtonRef.Text = "Activate Free Cam"
        freeCamButtonRef.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    end
end

local function toggleFreeCam(state, buttonRef)
    if state == freeCamScriptActive then return end
    if buttonRef then freeCamButtonRef = buttonRef end
    if state then
        if freeCamScriptActive then deactivateFreeCam() end
        activateFreeCam()
        if freeCamButtonRef then
            freeCamButtonRef.Text = "Deactivate Free Cam"
            freeCamButtonRef.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        end
    else
        deactivateFreeCam()
        if freeCamButtonRef then
            freeCamButtonRef.Text = "Activate Free Cam"
            freeCamButtonRef.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        end
    end
end

-- ==================== BRING ALL ====================
local bringAllEnabled = UIState.bringAllEnabled
local bringAllConnection = nil

local function bringAllPlayers()
    if not bringAllEnabled then return end
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function() plr.Character.HumanoidRootPart.CFrame = myHRP.CFrame * CFrame.new(0, 5, 0) end)
        end
    end
end

local function toggleBringAll(state)
    if state == bringAllEnabled then return end
    bringAllEnabled = state
    UIState.bringAllEnabled = state
    if bringAllConnection then bringAllConnection:Disconnect() end
    if bringAllEnabled then
        bringAllConnection = RunService.RenderStepped:Connect(bringAllPlayers)
        StarterGui:SetCore("SendNotification", { Title = "Bring All", Text = "Players will be brought to you continuously", Duration = 2 })
    else
        StarterGui:SetCore("SendNotification", { Title = "Bring All", Text = "Disabled", Duration = 1 })
    end
end

-- ==================== UI VARIABLES ====================
local currentColor = UIState.currentColor
local activeTab = "HOME"
local isMinimized = false
local dragOffset = Vector2.new()
local uiDragging = false
local rainbowActive = UIState.rainbowActive
local rainbowConnection = nil
local rVal, gVal, bVal = UIState.rVal, UIState.gVal, UIState.bVal

-- ==================== AIMBOT PERSEGUIR (WITH PREDICTION - CHASE) ====================
local aimbotChaseEnabled = UIState.aimbotChaseEnabled
local aimbotChaseConnection = nil
local aimbotChaseDistance = UIState.aimbotChaseDistance
local ChaseSettings = { distance = 200, prediction = 0.12 }

local function getPredictedPositionChase(target)
    local character = target.Character
    if not character then return nil end    
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then return nil end
    
    local currentPos = head.Position
    local velocity = hrp.AssemblyLinearVelocity
    
    if velocity.Magnitude > 2 then
        local predictedPos = currentPos + (velocity * ChaseSettings.prediction)
        return predictedPos
    end
    
    return currentPos
end

local function isPlayerVisible(target)
    local char = player.Character
    if not char then return false end
    
    local targetHead = target.Character and target.Character:FindFirstChild("Head")
    if not targetHead then return false end
    
    local cameraPos = Camera.CFrame.Position
    local targetPos = targetHead.Position
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {char, player.Character}
    
    local rayResult = workspace:Raycast(cameraPos, (targetPos - cameraPos).Unit * 1000, raycastParams)
    
    if rayResult and rayResult.Instance then
        local hitChar = rayResult.Instance:FindFirstAncestorOfClass("Model")
        if hitChar == target.Character then
            return true
        end
    end
    return false
end

local function getBestVisibleTargetChase()
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return nil end
    
    local camera = Camera
    local cameraPos = camera.CFrame.Position
    local cameraDir = camera.CFrame.LookVector
    local bestTarget = nil
    local bestScore = math.huge
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and not IsAimbotIgnored(plr.UserId) and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local humanoid = plr.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local distance = (head.Position - cameraPos).Magnitude
                    
                    if distance <= ChaseSettings.distance then
                        if isPlayerVisible(plr) then
                            local targetPos = getPredictedPositionChase(plr) or head.Position
                            local targetDir = (targetPos - cameraPos).Unit
                            local dot = cameraDir:Dot(targetDir)
                            local angle = math.deg(math.acos(dot))
                            
                            local score = angle + (distance / 10)
                            
                            if score < bestScore then
                                bestScore = score
                                bestTarget = plr
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

local function toggleAimbotChase(state)
    aimbotChaseEnabled = state
    UIState.aimbotChaseEnabled = state
    if aimbotChaseConnection then aimbotChaseConnection:Disconnect() end
    if state then
        aimbotChaseConnection = RunService.RenderStepped:Connect(function()
            if not aimbotChaseEnabled or not player.Character then return end
            local target = getBestVisibleTargetChase()
            if target and target.Character then
                local predictedPos = getPredictedPositionChase(target)
                if predictedPos then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
                elseif target.Character:FindFirstChild("Head") then
                    local head = target.Character.Head
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                end
            end
        end)
        StarterGui:SetCore("SendNotification", { Title = "Aimbot Chase", Text = "Activated (" .. ChaseSettings.distance .. " studs, with prediction)", Duration = 2 })
    else
        StarterGui:SetCore("SendNotification", { Title = "Aimbot Chase", Text = "Deactivated", Duration = 1 })
    end
end

local function setAimbotChaseDistance(value)
    aimbotChaseDistance = value
    ChaseSettings.distance = value
    UIState.aimbotChaseDistance = value
    if aimbotChaseEnabled then
        StarterGui:SetCore("SendNotification", { Title = "Aimbot Chase", Text = "Distance set to " .. value .. " studs", Duration = 1 })
    end
end

-- ==================== AIMBOT NORMAL (CENTER HEAD - NO PREDICTION) ====================
local aimbotNormalEnabled = UIState.aimbotNormalEnabled
local aimbotNormalConnection = nil
local aimbotNormalDistance = UIState.aimbotNormalDistance
local NormalSettings = { distance = 200 }

local function getBestVisibleTargetNormal()
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return nil end
    
    local camera = Camera
    local cameraPos = camera.CFrame.Position
    local cameraDir = camera.CFrame.LookVector
    local bestTarget = nil
    local bestScore = math.huge
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and not IsAimbotIgnored(plr.UserId) and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local humanoid = plr.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local distance = (head.Position - cameraPos).Magnitude
                    
                    if distance <= NormalSettings.distance then
                        if isPlayerVisible(plr) then
                            local targetPos = head.Position
                            local targetDir = (targetPos - cameraPos).Unit
                            local dot = cameraDir:Dot(targetDir)
                            local angle = math.deg(math.acos(dot))
                            
                            local score = angle + (distance / 10)
                            
                            if score < bestScore then
                                bestScore = score
                                bestTarget = plr
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

local function toggleAimbotNormal(state)
    aimbotNormalEnabled = state
    UIState.aimbotNormalEnabled = state
    if aimbotNormalConnection then aimbotNormalConnection:Disconnect() end
    if state then
        aimbotNormalConnection = RunService.RenderStepped:Connect(function()
            if not aimbotNormalEnabled or not player.Character then return end
            local target = getBestVisibleTargetNormal()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local head = target.Character.Head
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end)
        StarterGui:SetCore("SendNotification", { Title = "Aimbot Normal", Text = "Activated (" .. NormalSettings.distance .. " studs, center head)", Duration = 2 })
    else
        StarterGui:SetCore("SendNotification", { Title = "Aimbot Normal", Text = "Deactivated", Duration = 1 })
    end
end

local function setAimbotNormalDistance(value)
    aimbotNormalDistance = value
    NormalSettings.distance = value
    UIState.aimbotNormalDistance = value
    if aimbotNormalEnabled then
        StarterGui:SetCore("SendNotification", { Title = "Aimbot Normal", Text = "Distance set to " .. value .. " studs", Duration = 1 })
    end
end

-- ==================== TELEKILL ====================
local telekillEnabled = UIState.telekillEnabled
local telekillCurrentTarget = nil
local telekillFollowConnection = nil

local function getRandomAliveTargetForTelekill()
    local alivePlayers = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and not IsAimbotIgnored(plr.UserId) and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local humanoid = plr.Character.Humanoid
            if humanoid.Health > 0 then
                table.insert(alivePlayers, plr)
            end
        end
    end
    if #alivePlayers > 0 then return alivePlayers[math.random(1, #alivePlayers)] end
    return nil
end

local function telekillFollowTarget()
    if not telekillCurrentTarget or not telekillCurrentTarget.Character then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        if not telekillCurrentTarget then return end
    end
    local targetChar = telekillCurrentTarget.Character
    local targetHead = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not targetHead or not myHRP then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        return
    end
    local humanoid = targetChar:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        return
    end
    local targetPos = targetHead.Position + Vector3.new(0, 2, 0)
    myHRP.CFrame = CFrame.new(targetPos)
end

local function toggleTelekill(state)
    telekillEnabled = state
    UIState.telekillEnabled = state
    if telekillFollowConnection then telekillFollowConnection:Disconnect() end
    if state then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        if telekillCurrentTarget then
            StarterGui:SetCore("SendNotification", { Title = "Telekill", Text = "Following: " .. telekillCurrentTarget.Name, Duration = 2 })
        end
        telekillFollowConnection = RunService.Heartbeat:Connect(telekillFollowTarget)
    else
        StarterGui:SetCore("SendNotification", { Title = "Telekill", Text = "Disabled", Duration = 1 })
    end
end

-- ==================== GHOST MODE ====================
local function toggleGhost(state)
    ghostEnabled = state
    UIState.ghostEnabled = state
    if state then
        pcall(function() loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))() end)
        StarterGui:SetCore("SendNotification", { Title = "Ghost Mode", Text = "Activated", Duration = 1 })
    else
        StarterGui:SetCore("SendNotification", { Title = "Ghost Mode", Text = "Deactivated", Duration = 1 })
    end
end

-- ==================== HACK FUNCTIONS ====================
local function toggleFullbright(state)
    fullbrightEnabled = state
    UIState.fullbrightEnabled = state
    if fullbrightConnection then fullbrightConnection:Disconnect() end
    if state then
        dayEnabled = false; nightEnabled = false
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        fullbrightConnection = RunService.RenderStepped:Connect(function()
            if fullbrightEnabled then
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.new(1,1,1)
                Lighting.GlobalShadows = false
            end
        end)
        StarterGui:SetCore("SendNotification", { Title = "Fullbright", Text = "Activated", Duration = 1 })
    else
        Lighting.Brightness = originalBrightness
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.GlobalShadows = originalGlobalShadows
        StarterGui:SetCore("SendNotification", { Title = "Fullbright", Text = "Deactivated", Duration = 1 })
    end
end

local function toggleNoFog(state)
    noFogEnabled = state
    UIState.noFogEnabled = state
    if state then
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 0
        local atmosphere = Lighting:FindFirstChild("Atmosphere")
        if atmosphere then
            atmosphere.Density = 0
            atmosphere.Offset = 0
        end
        task.spawn(function()
            while noFogEnabled and task.wait(0.5) do
                Lighting.FogEnd = 1000000
                if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Density = 0 end
            end
        end)
        StarterGui:SetCore("SendNotification", { Title = "No Fog", Text = "Activated", Duration = 1 })
    else
        Lighting.FogEnd = originalFogEnd
        local atmosphere = Lighting:FindFirstChild("Atmosphere")
        if atmosphere then atmosphere.Density = 0.2 end
        StarterGui:SetCore("SendNotification", { Title = "No Fog", Text = "Deactivated", Duration = 1 })
    end
end

local function toggleDay(state)
    dayEnabled = state
    UIState.dayEnabled = state
    if state then
        fullbrightEnabled = false; nightEnabled = false
        if fullbrightConnection then fullbrightConnection:Disconnect() end
        Lighting.ClockTime = 12
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.new(0.5,0.5,0.5)
        Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
        StarterGui:SetCore("SendNotification", { Title = "Day", Text = "Activated", Duration = 1 })
    else
        Lighting.ClockTime = originalClockTime
        StarterGui:SetCore("SendNotification", { Title = "Day", Text = "Deactivated", Duration = 1 })
    end
end

local function toggleNight(state)
    nightEnabled = state
    UIState.nightEnabled = state
    if state then
        fullbrightEnabled = false; dayEnabled = false
        if fullbrightConnection then fullbrightConnection:Disconnect() end
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
        Lighting.Ambient = Color3.new(0.2,0.2,0.2)
        Lighting.OutdoorAmbient = Color3.new(0.2,0.2,0.2)
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
        StarterGui:SetCore("SendNotification", { Title = "Night", Text = "Activated", Duration = 1 })
    else
        Lighting.ClockTime = originalClockTime
        StarterGui:SetCore("SendNotification", { Title = "Night", Text = "Deactivated", Duration = 1 })
    end
end

local function toggleXRay(state)
    xray = state
    UIState.xrayEnabled = state
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent and not part.Parent:FindFirstChild("Humanoid") then
            pcall(function() part.LocalTransparencyModifier = state and 0.7 or 0 end)
        end
    end
    StarterGui:SetCore("SendNotification", { Title = "X-Ray", Text = state and "Activated" or "Deactivated", Duration = 1 })
end

local function toggleNoclip(state)
    noclipEnabled = state
    UIState.noclipEnabled = state
    if noclipConnection then noclipConnection:Disconnect() end
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipEnabled and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
        StarterGui:SetCore("SendNotification", { Title = "Noclip", Text = "Activated", Duration = 1 })
    else
        StarterGui:SetCore("SendNotification", { Title = "Noclip", Text = "Deactivated", Duration = 1 })
    end
end

local function toggleTpwalk(state)
    tpwalkEnabled = state
    UIState.tpwalkEnabled = state
    if tpwalkConnection then tpwalkConnection:Disconnect() end
    if state then
        tpwalkConnection = RunService.RenderStepped:Connect(function()
            if tpwalkEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                local moveDir = player.Character.Humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    root.CFrame = root.CFrame + moveDir * tpwalkSpeed * 0.1
                end
            end
        end)
        StarterGui:SetCore("SendNotification", { Title = "Tp Walk", Text = "Activated", Duration = 1 })
    else
        StarterGui:SetCore("SendNotification", { Title = "Tp Walk", Text = "Deactivated", Duration = 1 })
    end
end

-- ==================== INFINITE JUMP ====================
UIS.JumpRequest:Connect(function()
    if infjump and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================== FUNÇÃO PARA PEGAR A ARMA DO PLAYER (ESP ITEM) ====================
local function getPlayerWeapon(plr)
    local character = plr.Character
    if not character then return nil end
    
    local weaponName = nil
    
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            weaponName = child.Name
            break
        end
    end
    
    if not weaponName then
        local backpack = plr:FindFirstChild("Backpack")
        if backpack then
            for _, child in pairs(backpack:GetChildren()) do
                if child:IsA("Tool") then
                    weaponName = child.Name
                    break
                end
            end
        end
    end
    
    if weaponName then
        weaponName = weaponName:gsub("[%p%c%s]+", "")
    end
    
    return weaponName
end

-- ==================== ESP MENU (Box + Tracer + ITEM) ====================
local EspMenuActive = false
local EspDrawings = {}
local EspUpdateConnection = nil
local EspMenuGui = nil
local EspMenuState = {box = true, name = true, dist = true, health = true, tracer = true, item = true}
local neonHue = 0

local function CleanupEspDrawings(plr)
    local data = EspDrawings[plr]
    if data then
        for _, line in pairs(data.box or {}) do
            pcall(function() if line then line:Remove() end end)
        end
        pcall(function() if data.nameText then data.nameText:Remove() end end)
        pcall(function() if data.distText then data.distText:Remove() end end)
        pcall(function() if data.healthText then data.healthText:Remove() end end)
        pcall(function() if data.tracer then data.tracer:Remove() end end)
        pcall(function() if data.itemText then data.itemText:Remove() end end)
        EspDrawings[plr] = nil
    end
end

local function CreateEspDrawings()
    local lines = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(0, 255, 255)
        line.Thickness = 1.5
        line.Transparency = 0.6
        lines[i] = line
    end
    
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = Color3.fromRGB(0, 255, 0)
    distText.Size = 12
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Color = Color3.fromRGB(255, 50, 50)
    healthText.Size = 11
    healthText.Center = true
    healthText.Outline = true
    healthText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(255, 0, 0)
    tracer.Thickness = 1.5
    tracer.Transparency = 0.4
    
    local itemText = Drawing.new("Text")
    itemText.Visible = false
    itemText.Color = Color3.fromRGB(255, 0, 255)
    itemText.Size = 7
    itemText.Center = true
    itemText.Outline = true
    itemText.OutlineColor = Color3.fromRGB(0, 0, 0)
    itemText.OutlineThickness = 1
    itemText.Transparency = 0
    
    return {box = lines, nameText = nameText, distText = distText, healthText = healthText, tracer = tracer, itemText = itemText}
end

local function UpdateEspDrawing(plr)
    if plr == player then return end
    
    local playerExists = false
    for _, p in pairs(Players:GetPlayers()) do
        if p == plr then
            playerExists = true
            break
        end
    end
    
    if not playerExists then
        CleanupEspDrawings(plr)
        return
    end
    
    local data = EspDrawings[plr]
    if not data then
        data = CreateEspDrawings()
        EspDrawings[plr] = data
    end
    
    local character = plr.Character
    if not character or not character.Parent then
        for _, line in pairs(data.box) do if line then line.Visible = false end end
        if data.nameText then data.nameText.Visible = false end
        if data.distText then data.distText.Visible = false end
        if data.healthText then data.healthText.Visible = false end
        if data.tracer then data.tracer.Visible = false end
        if data.itemText then data.itemText.Visible = false end
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    local head = character:FindFirstChild("Head")
    if not rootPart or not head then
        for _, line in pairs(data.box) do if line then line.Visible = false end end
        if data.nameText then data.nameText.Visible = false end
        if data.distText then data.distText.Visible = false end
        if data.healthText then data.healthText.Visible = false end
        if data.tracer then data.tracer.Visible = false end
        if data.itemText then data.itemText.Visible = false end
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local health = humanoid and humanoid.Health or 0
    local weaponName = getPlayerWeapon(plr)
    
    local width = 2.5
    local height = (head.Position.Y - rootPart.Position.Y) + 1.5
    local halfWidth = width / 2
    
    local topPos = head.Position + Vector3.new(0, 0.3, 0)
    local bottomPos = rootPart.Position - Vector3.new(0, height / 2, 0)
    
    local rightVec = Camera.CFrame.RightVector
    local upVec = Camera.CFrame.UpVector
    
    local topLeft = topPos - rightVec * halfWidth + upVec * 0.2
    local topRight = topPos + rightVec * halfWidth + upVec * 0.2
    local bottomLeft = bottomPos - rightVec * halfWidth
    local bottomRight = bottomPos + rightVec * halfWidth
    
    local function toScreen(pos)
        local vec, onScreen = Camera:WorldToViewportPoint(pos)
        return Vector2.new(vec.X, vec.Y), onScreen and vec.Z > 0
    end
    
    local tL, tLVis = toScreen(topLeft)
    local tR, tRVis = toScreen(topRight)
    local bL, bLVis = toScreen(bottomLeft)
    local bR, bRVis = toScreen(bottomRight)
    
    if EspMenuState.box then
        data.box[1].From = tL; data.box[1].To = tR; data.box[1].Visible = tLVis and tRVis
        data.box[2].From = bL; data.box[2].To = bR; data.box[2].Visible = bLVis and bRVis
        data.box[3].From = tL; data.box[3].To = bL; data.box[3].Visible = tLVis and bLVis
        data.box[4].From = tR; data.box[4].To = bR; data.box[4].Visible = tRVis and bRVis
    else
        for _, line in pairs(data.box) do if line then line.Visible = false end end
    end
    
    local headScreen, headVis = toScreen(head.Position + Vector3.new(0, 1.2, 0))
    if headVis then
        local distance = (Camera.CFrame.Position - head.Position).Magnitude
        
        if EspMenuState.name then
            data.nameText.Text = plr.Name
            data.nameText.Position = Vector2.new(headScreen.X, headScreen.Y - 35)
            data.nameText.Visible = true
        else
            data.nameText.Visible = false
        end
        
        if EspMenuState.dist then
            data.distText.Text = string.format("%.0fm", distance)
            data.distText.Position = Vector2.new(headScreen.X, headScreen.Y - 20)
            data.distText.Visible = true
        else
            data.distText.Visible = false
        end
        
        if EspMenuState.health then
            if health <= 25 then
                data.healthText.Color = Color3.fromRGB(255, 0, 0)
            elseif health <= 50 then
                data.healthText.Color = Color3.fromRGB(255, 165, 0)
            else
                data.healthText.Color = Color3.fromRGB(0, 255, 0)
            end
            data.healthText.Text = string.format("❤️ %d", health)
            data.healthText.Position = Vector2.new(headScreen.X, headScreen.Y - 8)
            data.healthText.Visible = true
        else
            data.healthText.Visible = false
        end
        
        if EspMenuState.item and weaponName and weaponName ~= "" then
            data.itemText.Text = ">>> " .. string.upper(weaponName) .. " <<<"
            data.itemText.Position = Vector2.new(headScreen.X, headScreen.Y - 50)
            neonHue = (neonHue + 0.02) % 1
            data.itemText.Color = Color3.fromHSV(neonHue, 1, 1)
            data.itemText.Visible = true
        else
            data.itemText.Visible = false
        end
    else
        if EspMenuState.item and weaponName and weaponName ~= "" then
            data.itemText.Text = ">>> " .. string.upper(weaponName) .. " <<<"
            local screenPos, isOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
            if isOnScreen then
                data.itemText.Position = Vector2.new(screenPos.X, screenPos.Y - 50)
            else
                local clampedX = math.clamp(screenPos.X, 50, Camera.ViewportSize.X - 50)
                local clampedY = math.clamp(screenPos.Y, 50, Camera.ViewportSize.Y - 50)
                data.itemText.Position = Vector2.new(clampedX, clampedY - 50)
            end
            neonHue = (neonHue + 0.02) % 1
            data.itemText.Color = Color3.fromHSV(neonHue, 1, 1)
            data.itemText.Visible = true
        else
            if data.itemText then data.itemText.Visible = false end
        end
        
        data.nameText.Visible = false
        data.distText.Visible = false
        data.healthText.Visible = false
    end
    
    if EspMenuState.tracer then
        local viewportSize = Camera.ViewportSize
        local originScreen = Vector2.new(viewportSize.X / 2, viewportSize.Y - 60)
        local targetScreen, targetVis = toScreen(head.Position)
        
        if targetVis then
            data.tracer.From = originScreen
            data.tracer.To = targetScreen
            data.tracer.Visible = true
        else
            local direction = (head.Position - Camera.CFrame.Position).Unit
            local edgePoint = originScreen + Vector2.new(direction.X * 1000, direction.Y * 1000)
            data.tracer.From = originScreen
            data.tracer.To = edgePoint
            data.tracer.Visible = true
        end
    else
        if data.tracer then data.tracer.Visible = false end
    end
end

local function StartEspUpdateLoop()
    if EspUpdateConnection then EspUpdateConnection:Disconnect() end
    EspUpdateConnection = RunService.RenderStepped:Connect(function()
        for _, plr in pairs(Players:GetPlayers()) do
            UpdateEspDrawing(plr)
        end
        for plr, _ in pairs(EspDrawings) do
            local stillExists = false
            for _, p in pairs(Players:GetPlayers()) do
                if p == plr then
                    stillExists = true
                    break
                end
            end
            if not stillExists then
                CleanupEspDrawings(plr)
            end
        end
    end)
end

local function CreateEspMenu()
    if EspMenuActive then return end
    EspMenuActive = true
    
    StartEspUpdateLoop()
    
    EspMenuGui = Instance.new("ScreenGui")
    EspMenuGui.Name = "VitorHubESPMenu"
    EspMenuGui.ResetOnSpawn = false
    EspMenuGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = EspMenuGui
    mainFrame.Size = UDim2.new(0, 280, 0, 390)
    mainFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
    
    local border = Instance.new("UIStroke")
    border.Parent = mainFrame
    border.Color = currentColor
    border.Thickness = 2
    border.Transparency = 0.3
    
    local titleBar = Instance.new("Frame")
    titleBar.Parent = mainFrame
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = currentColor
    titleBar.BackgroundTransparency = 0.2
    titleBar.Active = true
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 15)
    
    local menuDragging = false
    local menuDragOffset = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            menuDragging = true
            menuDragOffset = Vector2.new(input.Position.X - mainFrame.AbsolutePosition.X, input.Position.Y - mainFrame.AbsolutePosition.Y)
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if menuDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            mainFrame.Position = UDim2.new(0, input.Position.X - menuDragOffset.X, 0, input.Position.Y - menuDragOffset.Y)
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            menuDragging = false
            menuDragOffset = nil
        end
    end)
    
    local title = Instance.new("TextLabel")
    title.Parent = titleBar
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "VITOR HUB - ESP MENU"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeEsp = Instance.new("TextButton")
    closeEsp.Parent = titleBar
    closeEsp.Size = UDim2.new(0, 35, 0, 35)
    closeEsp.Position = UDim2.new(1, -40, 0.5, -17.5)
    closeEsp.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeEsp.Text = "✕"
    closeEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeEsp.TextSize = 18
    closeEsp.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeEsp).CornerRadius = UDim.new(1, 0)
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Parent = mainFrame
    contentContainer.Size = UDim2.new(1, -20, 1, -60)
    contentContainer.Position = UDim2.new(0, 10, 0, 55)
    contentContainer.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = contentContainer
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local espBoxToggle = Instance.new("TextButton")
    espBoxToggle.Parent = contentContainer
    espBoxToggle.Size = UDim2.new(0, 240, 0, 40)
    espBoxToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    espBoxToggle.BackgroundTransparency = 0.2
    espBoxToggle.Text = "■ ESP BOX: ON"
    espBoxToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBoxToggle.TextSize = 14
    espBoxToggle.Font = Enum.Font.GothamBold
    Instance.new("UICorner", espBoxToggle).CornerRadius = UDim.new(0, 8)
    
    local nameToggle = Instance.new("TextButton")
    nameToggle.Parent = contentContainer
    nameToggle.Size = UDim2.new(0, 240, 0, 35)
    nameToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    nameToggle.Text = "Show Name: ON"
    nameToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameToggle.TextSize = 12
    Instance.new("UICorner", nameToggle).CornerRadius = UDim.new(0, 6)
    
    local distToggle = Instance.new("TextButton")
    distToggle.Parent = contentContainer
    distToggle.Size = UDim2.new(0, 240, 0, 35)
    distToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    distToggle.Text = "Show Distance: ON"
    distToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    distToggle.TextSize = 12
    Instance.new("UICorner", distToggle).CornerRadius = UDim.new(0, 6)
    
    local healthToggle = Instance.new("TextButton")
    healthToggle.Parent = contentContainer
    healthToggle.Size = UDim2.new(0, 240, 0, 35)
    healthToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    healthToggle.Text = "Show Health: ON"
    healthToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthToggle.TextSize = 12
    Instance.new("UICorner", healthToggle).CornerRadius = UDim.new(0, 6)
    
    local tracerToggle = Instance.new("TextButton")
    tracerToggle.Parent = contentContainer
    tracerToggle.Size = UDim2.new(0, 240, 0, 35)
    tracerToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    tracerToggle.Text = "ESP Tracer: ON"
    tracerToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tracerToggle.TextSize = 12
    Instance.new("UICorner", tracerToggle).CornerRadius = UDim.new(0, 6)
    
    local itemToggle = Instance.new("TextButton")
    itemToggle.Parent = contentContainer
    itemToggle.Size = UDim2.new(0, 240, 0, 35)
    itemToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    itemToggle.Text = "ESP ITEM (Weapon): ON"
    itemToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemToggle.TextSize = 12
    Instance.new("UICorner", itemToggle).CornerRadius = UDim.new(0, 6)
    
    local function UpdateAllVisibility()
        for _, data in pairs(EspDrawings) do
            if EspMenuState.box then
                for _, line in pairs(data.box) do if line then line.Visible = true end end
            else
                for _, line in pairs(data.box) do if line then line.Visible = false end end
            end
            if data.nameText then data.nameText.Visible = EspMenuState.name end
            if data.distText then data.distText.Visible = EspMenuState.dist end
            if data.healthText then data.healthText.Visible = EspMenuState.health end
            if data.tracer then data.tracer.Visible = EspMenuState.tracer end
            if data.itemText then data.itemText.Visible = EspMenuState.item end
        end
    end
    
    espBoxToggle.MouseButton1Click:Connect(function()
        EspMenuState.box = not EspMenuState.box
        espBoxToggle.Text = EspMenuState.box and "■ ESP BOX: ON" or "■ ESP BOX: OFF"
        espBoxToggle.BackgroundColor3 = EspMenuState.box and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
        UpdateAllVisibility()
    end)
    
    nameToggle.MouseButton1Click:Connect(function()
        EspMenuState.name = not EspMenuState.name
        nameToggle.Text = "Show Name: " .. (EspMenuState.name and "ON" or "OFF")
        nameToggle.BackgroundColor3 = EspMenuState.name and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 50)
        UpdateAllVisibility()
    end)
    
    distToggle.MouseButton1Click:Connect(function()
        EspMenuState.dist = not EspMenuState.dist
        distToggle.Text = "Show Distance: " .. (EspMenuState.dist and "ON" or "OFF")
        distToggle.BackgroundColor3 = EspMenuState.dist and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 50)
        UpdateAllVisibility()
    end)
    
    healthToggle.MouseButton1Click:Connect(function()
        EspMenuState.health = not EspMenuState.health
        healthToggle.Text = "Show Health: " .. (EspMenuState.health and "ON" or "OFF")
        healthToggle.BackgroundColor3 = EspMenuState.health and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 50)
        UpdateAllVisibility()
    end)
    
    tracerToggle.MouseButton1Click:Connect(function()
        EspMenuState.tracer = not EspMenuState.tracer
        tracerToggle.Text = "ESP Tracer: " .. (EspMenuState.tracer and "ON" or "OFF")
        tracerToggle.BackgroundColor3 = EspMenuState.tracer and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 50)
        UpdateAllVisibility()
    end)
    
    itemToggle.MouseButton1Click:Connect(function()
        EspMenuState.item = not EspMenuState.item
        itemToggle.Text = "ESP ITEM (Weapon): " .. (EspMenuState.item and "ON" or "OFF")
        itemToggle.BackgroundColor3 = EspMenuState.item and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 50)
        UpdateAllVisibility()
    end)
    
    closeEsp.MouseButton1Click:Connect(function()
        EspMenuActive = false
        if EspUpdateConnection then EspUpdateConnection:Disconnect() end
        for plr, data in pairs(EspDrawings) do
            for _, line in pairs(data.box) do if line then pcall(function() line:Remove() end) end end
            if data.nameText then pcall(function() data.nameText:Remove() end) end
            if data.distText then pcall(function() data.distText:Remove() end) end
            if data.healthText then pcall(function() data.healthText:Remove() end) end
            if data.tracer then pcall(function() data.tracer:Remove() end) end
            if data.itemText then pcall(function() data.itemText:Remove() end) end
        end
        EspDrawings = {}
        EspMenuGui:Destroy()
        EspMenuGui = nil
    end)
    
    StarterGui:SetCore("SendNotification", { Title = "ESP MENU", Text = "ESP Menu activated! Menu is draggable.", Duration = 3 })
end

-- ==================== SPECTATE + TP FUNCTION ====================
local function executeSpectate()
    pcall(function()
        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local CoreGui = game:GetService("CoreGui")
        local Camera = workspace.CurrentCamera
        local RunService = game:GetService("RunService")
        local player = Players.LocalPlayer

        local SpectateSettings = {
            Ativo = true,
            ModoEspectador = false,
            PlayerIndex = 1,
            PlayerList = {}
        }

        local spectatingConnection = nil
        local currentTarget = nil
        local headSitWeld = nil
        local jumpConnection = nil
        local sitAnimationTrack = nil
        local sitBodyGyro = nil
        local gyroConnection = nil
        
        local bangV1Active = false
        local bangV2Active = false
        local bangConnection = nil
        local bangTime = 0

        local function atualizarListaPlayers()
            SpectateSettings.PlayerList = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player then
                    table.insert(SpectateSettings.PlayerList, plr)
                end
            end
            table.sort(SpectateSettings.PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)
        end

        local function voltarParaPropriaCamera()
            if spectatingConnection then
                spectatingConnection:Disconnect()
                spectatingConnection = nil
            end
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                Camera.CameraSubject = player.Character
            end
            Camera.CameraType = Enum.CameraType.Custom
            currentTarget = player
            SpectateSettings.ModoEspectador = false
        end

        local function espectarPlayer(playerTarget)
            if not playerTarget then return false end
            if playerTarget == player then
                voltarParaPropriaCamera()
                return true
            end
            local character = playerTarget.Character
            if not character then return false end
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            if not rootPart then return false end
            currentTarget = playerTarget
            Camera.CameraSubject = rootPart
            Camera.CameraType = Enum.CameraType.Custom
            SpectateSettings.ModoEspectador = true
            return true
        end

        local function teleportarParaAlvo()
            if not currentTarget or currentTarget == player then
                StarterGui:SetCore("SendNotification", { Title = "Spectator", Text = "You are not spectating anyone.", Duration = 2 })
                return
            end
            local targetChar = currentTarget.Character
            if not targetChar then return end
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
            if not targetRoot then return end
            local myChar = player.Character
            if not myChar then return end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
            if not myRoot then return end
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 0)
            StarterGui:SetCore("SendNotification", { Title = "Teleport", Text = "Teleported to " .. currentTarget.Name, Duration = 2 })
        end
        
        local function startBangV1()
            if bangV1Active then
                if bangConnection then bangConnection:Disconnect() end
                bangV1Active = false
                StarterGui:SetCore("SendNotification", { Title = "Bang V1", Text = "Deactivated", Duration = 1 })
                return
            end
            
            if not currentTarget or currentTarget == player then
                StarterGui:SetCore("SendNotification", { Title = "Bang V1", Text = "Select a player to spectate first", Duration = 2 })
                return
            end
            
            bangV1Active = true
            bangTime = 0
            if bangConnection then bangConnection:Disconnect() end
            
            bangConnection = RunService.RenderStepped:Connect(function()
                if not bangV1Active or not currentTarget or not currentTarget.Character then
                    if bangConnection then bangConnection:Disconnect() end
                    bangV1Active = false
                    return
                end
                
                local targetChar = currentTarget.Character
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                local myChar = player.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                
                if not targetHRP or not myHRP then return end
                
                bangTime = bangTime + 0.025
                local offset = math.sin(bangTime * 8) * 2.5
                local direction = targetHRP.CFrame.LookVector * -1
                local behindPos = targetHRP.Position + direction * (3 + offset)
                myHRP.CFrame = CFrame.new(behindPos, targetHRP.Position)
            end)
            
            StarterGui:SetCore("SendNotification", { Title = "Bang V1", Text = "Activated - Teleporting behind target", Duration = 2 })
        end
        
        local function startBangV2()
            if bangV2Active then
                if bangConnection then bangConnection:Disconnect() end
                bangV2Active = false
                StarterGui:SetCore("SendNotification", { Title = "Bang V2", Text = "Deactivated", Duration = 1 })
                return
            end
            
            if not currentTarget or currentTarget == player then
                StarterGui:SetCore("SendNotification", { Title = "Bang V2", Text = "Select a player to spectate first", Duration = 2 })
                return
            end
            
            bangV2Active = true
            bangTime = 0
            if bangConnection then bangConnection:Disconnect() end
            
            bangConnection = RunService.RenderStepped:Connect(function()
                if not bangV2Active or not currentTarget or not currentTarget.Character then
                    if bangConnection then bangConnection:Disconnect() end
                    bangV2Active = false
                    return
                end
                
                local targetChar = currentTarget.Character
                local targetHead = targetChar:FindFirstChild("Head")
                local myChar = player.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                
                if not targetHead or not myHRP then return end
                
                bangTime = bangTime + 0.025
                local offsetX = math.sin(bangTime * 10) * 1.5
                local offsetZ = math.cos(bangTime * 8) * 1
                local frontPos = targetHead.Position + Vector3.new(offsetX, 0, offsetZ)
                myHRP.CFrame = CFrame.new(frontPos, targetHead.Position)
            end)
            
            StarterGui:SetCore("SendNotification", { Title = "Bang V2", Text = "Activated - Trolling in front of target", Duration = 2 })
        end

        local function criarAnimacaoSentado()
            local char = player.Character
            if not char then return end
            local humanoid = char:FindFirstChild("Humanoid")
            if not humanoid then return end
            local sitAnim = Instance.new("Animation")
            sitAnim.AnimationId = "rbxassetid://1781562148"
            sitAnimationTrack = humanoid:LoadAnimation(sitAnim)
            if sitAnimationTrack then
                sitAnimationTrack:Play()
            end
        end

        local function removerAnimacaoSentado()
            if sitAnimationTrack then
                sitAnimationTrack:Stop()
                sitAnimationTrack = nil
            end
        end

        local function soltarDaCabeca()
            if headSitWeld then
                headSitWeld:Destroy()
                headSitWeld = nil
            end
            if sitBodyGyro then
                sitBodyGyro:Destroy()
                sitBodyGyro = nil
            end
            if gyroConnection then
                gyroConnection:Disconnect()
                gyroConnection = nil
            end
            if jumpConnection then
                jumpConnection:Disconnect()
                jumpConnection = nil
            end
            removerAnimacaoSentado()
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
                humanoid.AutoRotate = true
            end
        end

        local function sentarNaCabeca()
            if not currentTarget or currentTarget == player then
                StarterGui:SetCore("SendNotification", { Title = "Head Sit", Text = "Spectate another player first.", Duration = 2 })
                return
            end
            
            local targetChar = currentTarget.Character
            if not targetChar then return end
            local targetHead = targetChar:FindFirstChild("Head")
            if not targetHead then return end
            
            local myChar = player.Character
            if not myChar then return end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
            if not myRoot then return end
            local myHumanoid = myChar:FindFirstChild("Humanoid")
            if not myHumanoid then return end
            
            soltarDaCabeca()
            
            local headPos = targetHead.Position
            myRoot.CFrame = CFrame.new(headPos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, targetHead.Orientation.Y, 0)
            
            headSitWeld = Instance.new("WeldConstraint")
            headSitWeld.Part0 = myRoot
            headSitWeld.Part1 = targetHead
            headSitWeld.Parent = myRoot
            
            myHumanoid.PlatformStand = true
            myHumanoid.AutoRotate = false
            
            sitBodyGyro = Instance.new("BodyGyro")
            sitBodyGyro.Parent = myRoot
            sitBodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
            sitBodyGyro.P = 10000
            sitBodyGyro.D = 500
            sitBodyGyro.CFrame = targetHead.CFrame
            
            gyroConnection = RunService.Heartbeat:Connect(function()
                if not headSitWeld or not sitBodyGyro then
                    if gyroConnection then gyroConnection:Disconnect() end
                    return
                end
                if targetHead and targetHead.Parent then
                    sitBodyGyro.CFrame = targetHead.CFrame
                end
            end)
            
            criarAnimacaoSentado()
            
            local function onJump()
                if headSitWeld then
                    soltarDaCabeca()
                    StarterGui:SetCore("SendNotification", { Title = "Head Sit", Text = "You jumped and released.", Duration = 2 })
                end
            end
            jumpConnection = UserInputService.JumpRequest:Connect(onJump)
            
            StarterGui:SetCore("SendNotification", { Title = "Head Sit", Text = "Sitting on " .. currentTarget.Name .. "'s head. Jump to release.", Duration = 3 })
        end

        local function proximoPlayer()
            atualizarListaPlayers()
            if #SpectateSettings.PlayerList == 0 then
                voltarParaPropriaCamera()
                StarterGui:SetCore("SendNotification", { Title = "Spectator", Text = "No players available.", Duration = 2 })
                return
            end
            SpectateSettings.PlayerIndex = SpectateSettings.PlayerIndex + 1
            if SpectateSettings.PlayerIndex > #SpectateSettings.PlayerList then
                SpectateSettings.PlayerIndex = 1
            end
            local target = SpectateSettings.PlayerList[SpectateSettings.PlayerIndex]
            if target then 
                espectarPlayer(target)
                StarterGui:SetCore("SendNotification", { Title = "Spectator", Text = "Now spectating: " .. target.Name, Duration = 2 })
            end
        end

        local function anteriorPlayer()
            atualizarListaPlayers()
            if #SpectateSettings.PlayerList == 0 then
                voltarParaPropriaCamera()
                StarterGui:SetCore("SendNotification", { Title = "Spectator", Text = "No players available.", Duration = 2 })
                return
            end
            SpectateSettings.PlayerIndex = SpectateSettings.PlayerIndex - 1
            if SpectateSettings.PlayerIndex < 1 then
                SpectateSettings.PlayerIndex = #SpectateSettings.PlayerList
            end
            local target = SpectateSettings.PlayerList[SpectateSettings.PlayerIndex]
            if target then 
                espectarPlayer(target)
                StarterGui:SetCore("SendNotification", { Title = "Spectator", Text = "Now spectating: " .. target.Name, Duration = 2 })
            end
        end

        local function iniciarLoopEspectador()
            if spectatingConnection then spectatingConnection:Disconnect() end
            spectatingConnection = RunService.Heartbeat:Connect(function()
                if not SpectateSettings.Ativo then return end
                if SpectateSettings.ModoEspectador and currentTarget and currentTarget ~= player then
                    if not currentTarget.Character then
                        voltarParaPropriaCamera()
                    end
                end
            end)
        end

        local function criarGUIEspectador()
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "VitorHubEspectador"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = player:FindFirstChild("PlayerGui") or CoreGui
            
            local mainFrame = Instance.new("Frame")
            mainFrame.Parent = screenGui
            mainFrame.Size = UDim2.new(0, 520, 0, 90)
            mainFrame.Position = UDim2.new(0.5, -260, 0.85, 0)
            mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
            mainFrame.BackgroundTransparency = 0.15
            mainFrame.BorderSizePixel = 0
            mainFrame.Active = true
            mainFrame.Draggable = true
            Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
            
            local border = Instance.new("UIStroke")
            border.Parent = mainFrame
            border.Color = Color3.fromRGB(0, 200, 255)
            border.Thickness = 2
            border.Transparency = 0.3
            
            local titleBar = Instance.new("Frame")
            titleBar.Parent = mainFrame
            titleBar.Size = UDim2.new(1, 0, 0, 35)
            titleBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
            titleBar.BackgroundTransparency = 0.2
            titleBar.Active = true
            Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 15)
            
            local title = Instance.new("TextLabel")
            title.Parent = titleBar
            title.Size = UDim2.new(1, -40, 1, 0)
            title.Position = UDim2.new(0, 10, 0, 0)
            title.BackgroundTransparency = 1
            title.Text = "VITOR HUB - SPECTATOR"
            title.TextColor3 = Color3.fromRGB(0, 200, 255)
            title.TextSize = 13
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            
            local fecharTitleBtn = Instance.new("TextButton")
            fecharTitleBtn.Parent = titleBar
            fecharTitleBtn.Size = UDim2.new(0, 30, 0, 30)
            fecharTitleBtn.Position = UDim2.new(1, -35, 0.5, -15)
            fecharTitleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            fecharTitleBtn.Text = "✕"
            fecharTitleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            fecharTitleBtn.TextSize = 16
            fecharTitleBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", fecharTitleBtn).CornerRadius = UDim.new(1, 0)
            
            local buttonContainer = Instance.new("Frame")
            buttonContainer.Parent = mainFrame
            buttonContainer.Size = UDim2.new(1, -20, 0, 40)
            buttonContainer.Position = UDim2.new(0, 10, 0, 42)
            buttonContainer.BackgroundTransparency = 1
            
            local layout = Instance.new("UIGridLayout")
            layout.Parent = buttonContainer
            layout.CellSize = UDim2.new(0, 65, 0, 35)
            layout.CellPadding = UDim2.new(0, 6, 0, 0)
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            
            local esquerdaBtn = Instance.new("TextButton")
            esquerdaBtn.Parent = buttonContainer
            esquerdaBtn.Size = UDim2.new(0, 65, 0, 35)
            esquerdaBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            esquerdaBtn.Text = "←"
            esquerdaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            esquerdaBtn.TextSize = 28
            esquerdaBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", esquerdaBtn).CornerRadius = UDim.new(0, 8)
            
            local fecharGuiBtn = Instance.new("TextButton")
            fecharGuiBtn.Parent = buttonContainer
            fecharGuiBtn.Size = UDim2.new(0, 70, 0, 35)
            fecharGuiBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            fecharGuiBtn.Text = "CLOSE"
            fecharGuiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            fecharGuiBtn.TextSize = 11
            fecharGuiBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", fecharGuiBtn).CornerRadius = UDim.new(0, 8)
            
            local headSitBtn = Instance.new("TextButton")
            headSitBtn.Parent = buttonContainer
            headSitBtn.Size = UDim2.new(0, 75, 0, 35)
            headSitBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
            headSitBtn.Text = "HEAD SIT"
            headSitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            headSitBtn.TextSize = 10
            headSitBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", headSitBtn).CornerRadius = UDim.new(0, 8)
            
            local teleportarBtn = Instance.new("TextButton")
            teleportarBtn.Parent = buttonContainer
            teleportarBtn.Size = UDim2.new(0, 75, 0, 35)
            teleportarBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
            teleportarBtn.Text = "TELEPORT"
            teleportarBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            teleportarBtn.TextSize = 10
            teleportarBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", teleportarBtn).CornerRadius = UDim.new(0, 8)
            
            local bangV1Btn = Instance.new("TextButton")
            bangV1Btn.Parent = buttonContainer
            bangV1Btn.Size = UDim2.new(0, 75, 0, 35)
            bangV1Btn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
            bangV1Btn.Text = "BANG V1"
            bangV1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            bangV1Btn.TextSize = 11
            bangV1Btn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", bangV1Btn).CornerRadius = UDim.new(0, 8)
            
            local bangV2Btn = Instance.new("TextButton")
            bangV2Btn.Parent = buttonContainer
            bangV2Btn.Size = UDim2.new(0, 75, 0, 35)
            bangV2Btn.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
            bangV2Btn.Text = "BANG V2"
            bangV2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            bangV2Btn.TextSize = 11
            bangV2Btn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", bangV2Btn).CornerRadius = UDim.new(0, 8)
            
            local direitaBtn = Instance.new("TextButton")
            direitaBtn.Parent = buttonContainer
            direitaBtn.Size = UDim2.new(0, 65, 0, 35)
            direitaBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            direitaBtn.Text = "→"
            direitaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            direitaBtn.TextSize = 28
            direitaBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", direitaBtn).CornerRadius = UDim.new(0, 8)
            
            esquerdaBtn.MouseButton1Click:Connect(anteriorPlayer)
            direitaBtn.MouseButton1Click:Connect(proximoPlayer)
            teleportarBtn.MouseButton1Click:Connect(teleportarParaAlvo)
            headSitBtn.MouseButton1Click:Connect(sentarNaCabeca)
            bangV1Btn.MouseButton1Click:Connect(startBangV1)
            bangV2Btn.MouseButton1Click:Connect(startBangV2)
            
            local function desativarTudo()
                SpectateSettings.Ativo = false
                if bangConnection then bangConnection:Disconnect() end
                bangV1Active = false
                bangV2Active = false
                soltarDaCabeca()
                voltarParaPropriaCamera()
                screenGui:Destroy()
                StarterGui:SetCore("SendNotification", { Title = "Vitor Hub", Text = "Spectator mode deactivated.", Duration = 2 })
            end
            
            fecharGuiBtn.MouseButton1Click:Connect(desativarTudo)
            fecharTitleBtn.MouseButton1Click:Connect(desativarTudo)
            
            local dragging = false
            local dragOffset = nil
            
            titleBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local mousePos = input.Position
                    local framePos = mainFrame.AbsolutePosition
                    dragOffset = Vector2.new(mousePos.X - framePos.X, mousePos.Y - framePos.Y)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                    local mousePos = input.Position
                    local newX = mousePos.X - dragOffset.X
                    local newY = mousePos.Y - dragOffset.Y
                    mainFrame.Position = UDim2.new(0, newX, 0, newY)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    dragOffset = nil
                end
            end)
        end

        atualizarListaPlayers()
        if #SpectateSettings.PlayerList > 0 then
            SpectateSettings.PlayerIndex = 1
            espectarPlayer(SpectateSettings.PlayerList[1])
        end
        iniciarLoopEspectador()
        criarGUIEspectador()
        
        StarterGui:SetCore("SendNotification", { Title = "Vitor Hub", Text = "Spectator activated | ← → to navigate | HEAD SIT to sit | BANG to troll", Duration = 4 })
    end)
end

-- ==================== WAYPOINT FUNCTION ====================
local function executeWaypoint()
    pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        local waypoints = {}

        local wayGui = Instance.new("ScreenGui")
        wayGui.Name = "VitorHubWaypoint"
        wayGui.ResetOnSpawn = false
        wayGui.Parent = player:WaitForChild("PlayerGui")

        local frame = Instance.new("Frame", wayGui)
        frame.Size = UDim2.new(0,480,0,520)
        frame.Position = UDim2.new(0.5,-240,0.5,-260)
        frame.BackgroundColor3 = Color3.fromRGB(20,20,30)
        frame.Active = true
        frame.Draggable = true
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0,18)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1,0,0,50)
        title.BackgroundTransparency = 1
        title.Text = "Vitor Hub - Waypoint"
        title.TextColor3 = Color3.fromRGB(0,200,255)
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 24
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Position = UDim2.new(0,12,0,0)

        local function makeBtn(txt,x)
            local b = Instance.new("TextButton", frame)
            b.Size = UDim2.new(0,40,0,40)
            b.Position = UDim2.new(1,x,0,5)
            b.Text = txt
            b.BackgroundColor3 = Color3.fromRGB(40,40,40)
            b.TextColor3 = Color3.fromRGB(255,255,255)
            b.AutoButtonColor = false
            Instance.new("UICorner", b)
            b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(0,170,255)}):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end)
            return b
        end

        local close = makeBtn("✕",-50)
        local minimize = makeBtn("—",-100)

        local add = Instance.new("TextButton", frame)
        add.Size = UDim2.new(1,-20,0,50)
        add.Position = UDim2.new(0,10,0,60)
        add.Text = " Save Waypoint"
        add.BackgroundColor3 = Color3.fromRGB(0,170,255)
        add.TextColor3 = Color3.fromRGB(255,255,255)
        add.Font = Enum.Font.GothamBlack
        Instance.new("UICorner", add)

        local scroll = Instance.new("ScrollingFrame", frame)
        scroll.Size = UDim2.new(1,-20,1,-130)
        scroll.Position = UDim2.new(0,10,0,125)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 16
        scroll.ScrollingEnabled = true

        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0,12)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
        end)

        local function createWaypoint(data)
            local pos = Vector3.new(unpack(data.pos))
            local item = Instance.new("Frame", scroll)
            item.Size = UDim2.new(1,-5,0,120)
            item.BackgroundColor3 = Color3.fromRGB(35,35,35)
            Instance.new("UICorner", item)

            local label = Instance.new("TextBox", item)
            label.Size = UDim2.new(1,-20,0,40)
            label.Position = UDim2.new(0,10,0,5)
            label.Text = data.name
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255,255,255)
            label.Font = Enum.Font.GothamBlack
            label.TextSize = 20

            local function makeBtn2(txt,y,color)
                local b = Instance.new("TextButton", item)
                b.Size = UDim2.new(1,-20,0,30)
                b.Position = UDim2.new(0,10,0,y)
                b.Text = txt
                b.BackgroundColor3 = color
                b.TextColor3 = Color3.fromRGB(255,255,255)
                Instance.new("UICorner", b)
                b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(0,200,255)}):Play() end)
                b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=color}):Play() end)
                return b
            end

            local tp = makeBtn2(" Teleport",50,Color3.fromRGB(0,170,255))
            local del = makeBtn2(" Delete Waypoint",85,Color3.fromRGB(170,0,0))

            tp.MouseButton1Click:Connect(function() if root and root.Parent then root.CFrame = CFrame.new(pos) end end)
            del.MouseButton1Click:Connect(function()
                for i,v in pairs(waypoints) do if v == data then table.remove(waypoints,i); break end end
                item:Destroy()
            end)
        end

        add.MouseButton1Click:Connect(function()
            local data = {name="Waypoint - " .. #waypoints + 1, pos={root.Position.X,root.Position.Y,root.Position.Z}}
            table.insert(waypoints,data)
            createWaypoint(data)
        end)

        for _,v in pairs(waypoints) do createWaypoint(v) end

        local ballWay = Instance.new("TextButton", wayGui)
        ballWay.Size = UDim2.new(0,60,0,60)
        ballWay.Position = UDim2.new(0.1,0,0.5,0)
        ballWay.Text = "V"
        ballWay.Visible = false
        ballWay.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", ballWay).CornerRadius = UDim.new(1,0)
        ballWay.Active = true
        ballWay.Selectable = true
        ballWay.Draggable = true

        minimize.MouseButton1Click:Connect(function() frame.Visible = false; ballWay.Visible = true end)
        ballWay.MouseButton1Click:Connect(function() frame.Visible = true; ballWay.Visible = false end)
        close.MouseButton1Click:Connect(function() wayGui:Destroy() end)

        StarterGui:SetCore("SendNotification", { Title = "Waypoint", Text = "Waypoint system activated!", Duration = 2 })
    end)
end

-- ==================== AIM IGNORE POPUP MENU ====================
local AimIgnorePopupActive = false
local AimIgnorePopupGui = nil
local AimIgnoreListContainer = nil
local AimIgnoreSearchText = ""

local function updateAimIgnorePopupList()
    if not AimIgnoreListContainer then return end
    
    for _, v in pairs(AimIgnoreListContainer:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    local playersToShow = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            if AimIgnoreSearchText == "" or plr.Name:lower():find(AimIgnoreSearchText) then
                table.insert(playersToShow, plr)
            end
        end
    end
    
    table.sort(playersToShow, function(a, b) return a.Name:lower() < b.Name:lower() end)
    
    local containerWidth = AimIgnoreListContainer.AbsoluteSize.X
    local itemWidth = 280
    local itemsPerRow = math.max(1, math.floor(containerWidth / itemWidth))
    local yOffset = 0
    
    for i, plr in pairs(playersToShow) do
        local isIgnored = IsAimbotIgnored(plr.UserId)
        
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = AimIgnoreListContainer
        rowFrame.Size = UDim2.new(0, itemWidth, 0, 70)
        rowFrame.Position = UDim2.new(0, ((i-1) % itemsPerRow) * (itemWidth + 10), 0, yOffset)
        rowFrame.BackgroundColor3 = isIgnored and Color3.fromRGB(50, 30, 30) or Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = 0.2
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 10)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 55, 0, 55)
        avatarFrame.Position = UDim2.new(0, 8, 0.5, -27.5)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = rowFrame
        nameLabel.Size = UDim2.new(0, 140, 0, 30)
        nameLabel.Position = UDim2.new(0, 75, 0.25, -15)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local ignoreBtn = Instance.new("TextButton")
        ignoreBtn.Parent = rowFrame
        ignoreBtn.Size = UDim2.new(0, 80, 0, 35)
        ignoreBtn.Position = UDim2.new(1, -90, 0.5, -17.5)
        ignoreBtn.BackgroundColor3 = isIgnored and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(0, 150, 0)
        ignoreBtn.Text = isIgnored and "Ignored" or "Ignore"
        ignoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ignoreBtn.TextSize = 12
        ignoreBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", ignoreBtn).CornerRadius = UDim.new(0, 6)
        
        ignoreBtn.MouseButton1Click:Connect(function()
            if IsAimbotIgnored(plr.UserId) then
                RemoveAimbotIgnore(plr.UserId)
                StarterGui:SetCore("SendNotification", { Title = "Aim Ignore", Text = plr.Name .. " removed from ignore list.", Duration = 1 })
            else
                AddAimbotIgnore(plr.UserId)
                StarterGui:SetCore("SendNotification", { Title = "Aim Ignore", Text = plr.Name .. " added to ignore list.", Duration = 1 })
            end
            updateAimIgnorePopupList()
        end)
        
        if i % itemsPerRow == 0 then
            yOffset = yOffset + 80
        end
    end
    
    AimIgnoreListContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, math.ceil(#playersToShow / itemsPerRow) * 80 + 10))
end

local function CreateAimIgnorePopup()
    if AimIgnorePopupActive then return end
    AimIgnorePopupActive = true
    
    AimIgnorePopupGui = Instance.new("ScreenGui")
    AimIgnorePopupGui.Name = "VitorHubAimIgnorePopup"
    AimIgnorePopupGui.ResetOnSpawn = false
    AimIgnorePopupGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = AimIgnorePopupGui
    mainFrame.Size = UDim2.new(0, 600, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
    
    local border = Instance.new("UIStroke")
    border.Parent = mainFrame
    border.Color = currentColor
    border.Thickness = 2
    border.Transparency = 0.3
    
    local titleBar = Instance.new("Frame")
    titleBar.Parent = mainFrame
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = currentColor
    titleBar.BackgroundTransparency = 0.2
    titleBar.Active = true
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 15)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = titleBar
    titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "VITOR HUB - AIM IGNORE"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Parent = titleBar
    minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
    minimizeBtn.Position = UDim2.new(1, -80, 0.5, -17.5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.TextSize = 28
    minimizeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(1, 0)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = titleBar
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -17.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 55)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        AimIgnoreSearchText = searchBox.Text:lower()
        updateAimIgnorePopupList()
    end)
    
    local clearSearchBtn = Instance.new("TextButton")
    clearSearchBtn.Parent = searchFrame
    clearSearchBtn.Size = UDim2.new(0, 30, 0, 30)
    clearSearchBtn.Position = UDim2.new(1, -35, 0.5, -15)
    clearSearchBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    clearSearchBtn.BackgroundTransparency = 0.2
    clearSearchBtn.Text = "✕"
    clearSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearSearchBtn.TextSize = 16
    clearSearchBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearSearchBtn).CornerRadius = UDim.new(1, 0)
    clearSearchBtn.MouseButton1Click:Connect(function() 
        searchBox.Text = "" 
        AimIgnoreSearchText = ""
        updateAimIgnorePopupList()
    end)
    
    local playersScrollingFrame = Instance.new("ScrollingFrame")
    playersScrollingFrame.Parent = mainFrame
    playersScrollingFrame.Size = UDim2.new(1, -20, 1, -115)
    playersScrollingFrame.Position = UDim2.new(0, 10, 0, 105)
    playersScrollingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    playersScrollingFrame.BackgroundTransparency = 0.3
    playersScrollingFrame.BorderSizePixel = 0
    playersScrollingFrame.ScrollBarThickness = 6
    playersScrollingFrame.ScrollBarImageColor3 = currentColor
    playersScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    Instance.new("UICorner", playersScrollingFrame).CornerRadius = UDim.new(0, 10)
    
    AimIgnoreListContainer = playersScrollingFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = playersScrollingFrame
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        playersScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local bottomBar = Instance.new("Frame")
    bottomBar.Parent = mainFrame
    bottomBar.Size = UDim2.new(1, -20, 0, 40)
    bottomBar.Position = UDim2.new(0, 10, 1, -50)
    bottomBar.BackgroundTransparency = 1
    
    local clearAllBtn = Instance.new("TextButton")
    clearAllBtn.Parent = bottomBar
    clearAllBtn.Size = UDim2.new(1, 0, 1, 0)
    clearAllBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    clearAllBtn.BackgroundTransparency = 0.2
    clearAllBtn.Text = "Clear All Ignored"
    clearAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearAllBtn.TextSize = 14
    clearAllBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearAllBtn).CornerRadius = UDim.new(0, 8)
    clearAllBtn.MouseButton1Click:Connect(function()
        UIState.AimbotIgnoreList = {}
        updateAimIgnorePopupList()
        StarterGui:SetCore("SendNotification", { Title = "Aim Ignore", Text = "All players removed from ignore list!", Duration = 2 })
    end)
    
    local minimizeBall = Instance.new("TextButton")
    minimizeBall.Parent = AimIgnorePopupGui
    minimizeBall.Size = UDim2.new(0, 60, 0, 60)
    minimizeBall.Position = UDim2.new(0.5, -30, 0.5, -30)
    minimizeBall.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    minimizeBall.Text = "I"
    minimizeBall.TextColor3 = currentColor
    minimizeBall.TextSize = 24
    minimizeBall.Font = Enum.Font.GothamBold
    minimizeBall.Visible = false
    minimizeBall.Active = true
    minimizeBall.Draggable = true
    Instance.new("UICorner", minimizeBall).CornerRadius = UDim.new(1, 0)
    local ballStroke = Instance.new("UIStroke")
    ballStroke.Parent = minimizeBall
    ballStroke.Thickness = 3
    ballStroke.Color = currentColor
    ballStroke.Transparency = 0.2
    
    local isPopupMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isPopupMinimized = true
        mainFrame.Visible = false
        minimizeBall.Visible = true
    end)
    
    minimizeBall.MouseButton1Click:Connect(function()
        isPopupMinimized = false
        mainFrame.Visible = true
        minimizeBall.Visible = false
        updateAimIgnorePopupList()
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        AimIgnorePopupActive = false
        if AimIgnorePopupGui then AimIgnorePopupGui:Destroy() end
        AimIgnorePopupGui = nil
        AimIgnoreListContainer = nil
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function() updateAimIgnorePopupList() end)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function() updateAimIgnorePopupList() end)
    
    updateAimIgnorePopupList()
end

-- ==================== SCRIPTS MENU ====================
local ScriptsMenuActive = false
local ScriptsMenuGui = nil
local scriptsDragging = false
local scriptsDragStart = nil
local scriptsSearchText = ""

local function updateScriptsList()
    if not ScriptsMenuGui then return end
    
    local contentScrolling = ScriptsMenuGui:FindFirstChild("MainFrame"):FindFirstChild("ContentScrolling")
    if not contentScrolling then return end
    
    for _, v in pairs(contentScrolling:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    local scripts = {
        {name = "Piggy", code = 'loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Veno-hub-v4-0-piggy-229874"))()', key = "VENOHUBONTOP"},
        {name = "MM2", code = 'loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-KEYLESS-Zuri-Hub-OP-Aimbot-ESP-KILL-AURA-HITBOX-AUTO-FARM-230571"))()', key = nil},
        {name = "Brookheaven", code = 'loadstring(game:HttpGet("https://pastebin.com/raw/PHArhuvs"))()', key = nil},
        {name = "Blade Ball", code = 'loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-UPD-Auto-Parry-Keyless-229154"))()', key = nil},
        {name = "Flee The Facility", code = 'loadstring(game:HttpGet("https://api.kodamo.net/loader/5u0q818jobns1ldlg6cy"))()', key = nil},
        {name = "The Rake", code = 'loadstring(game:HttpGet("https://rawscripts.net/raw/The-Rake-REMASTERED-Project-The-Rake-33649"))()', key = nil},
        {name = "The Doors", code = 'loadstring(game:HttpGet("https://rawscripts.net/raw/FLOOR-2-DOORS-Sensation-V2-20105"))()', key = nil},
        {name = "Distrito Da Violencia", code = 'loadstring(game:HttpGet("https://rawscripts.net/raw/Violence-District-CyberCoders-Menu-II-Violence-Distric-214897"))()', key = nil}
    }
    
    local filteredScripts = {}
    for _, script in pairs(scripts) do
        if scriptsSearchText == "" or script.name:lower():find(scriptsSearchText) then
            table.insert(filteredScripts, script)
        end
    end
    
    for _, script in pairs(filteredScripts) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Parent = contentScrolling
        itemFrame.Size = UDim2.new(0, 500, 0, 55)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        itemFrame.BackgroundTransparency = 0.2
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 10)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = itemFrame
        nameLabel.Size = UDim2.new(0, 150, 0, 30)
        nameLabel.Position = UDim2.new(0, 15, 0, 12)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = script.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local executeBtn = Instance.new("TextButton")
        executeBtn.Parent = itemFrame
        executeBtn.Size = UDim2.new(0, 85, 0, 35)
        executeBtn.Position = UDim2.new(0.35, 0, 0, 10)
        executeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        executeBtn.Text = "Execute"
        executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        executeBtn.TextSize = 12
        executeBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", executeBtn).CornerRadius = UDim.new(0, 6)
        executeBtn.MouseButton1Click:Connect(function()
            pcall(function() loadstring(script.code)() end)
            StarterGui:SetCore("SendNotification", { Title = "Scripts Menu", Text = "Executing: " .. script.name, Duration = 2 })
        end)
        
        local copyBtn = Instance.new("TextButton")
        copyBtn.Parent = itemFrame
        copyBtn.Size = UDim2.new(0, 85, 0, 35)
        copyBtn.Position = UDim2.new(0.52, 0, 0, 10)
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        copyBtn.Text = "Copy"
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.TextSize = 12
        copyBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
        copyBtn.MouseButton1Click:Connect(function()
            Clipboard(script.code)
            StarterGui:SetCore("SendNotification", { Title = "Scripts Menu", Text = "Script copied to clipboard!", Duration = 2 })
        end)
        
        if script.key then
            local copyKeyBtn = Instance.new("TextButton")
            copyKeyBtn.Parent = itemFrame
            copyKeyBtn.Size = UDim2.new(0, 85, 0, 35)
            copyKeyBtn.Position = UDim2.new(0.69, 0, 0, 10)
            copyKeyBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
            copyKeyBtn.Text = "Copy Key"
            copyKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            copyKeyBtn.TextSize = 12
            copyKeyBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", copyKeyBtn).CornerRadius = UDim.new(0, 6)
            copyKeyBtn.MouseButton1Click:Connect(function()
                Clipboard(script.key)
                StarterGui:SetCore("SendNotification", { Title = "Scripts Menu", Text = "Key copied to clipboard!", Duration = 2 })
            end)
        end
    end
    
    local contentLayout = contentScrolling:FindFirstChildOfClass("UIListLayout")
    if contentLayout then
        contentScrolling.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end
end

local function CreateScriptsMenu()
    if ScriptsMenuActive then return end
    ScriptsMenuActive = true
    
    ScriptsMenuGui = Instance.new("ScreenGui")
    ScriptsMenuGui.Name = "VitorHubScriptsMenu"
    ScriptsMenuGui.ResetOnSpawn = false
    ScriptsMenuGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = ScriptsMenuGui
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 550, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
    
    local border = Instance.new("UIStroke")
    border.Parent = mainFrame
    border.Color = currentColor
    border.Thickness = 2
    border.Transparency = 0.3
    
    local titleBar = Instance.new("Frame")
    titleBar.Parent = mainFrame
    titleBar.Size = UDim2.new(1, 0, 0, 55)
    titleBar.BackgroundColor3 = currentColor
    titleBar.BackgroundTransparency = 0.2
    titleBar.Active = true
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 15)
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            scriptsDragging = true
            scriptsDragStart = Vector2.new(input.Position.X - mainFrame.AbsolutePosition.X, input.Position.Y - mainFrame.AbsolutePosition.Y)
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if scriptsDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            mainFrame.Position = UDim2.new(0, input.Position.X - scriptsDragStart.X, 0, input.Position.Y - scriptsDragStart.Y)
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            scriptsDragging = false
            scriptsDragStart = nil
        end
    end)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = titleBar
    titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "VITOR HUB - SCRIPTS MENU"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local infoFrame = Instance.new("Frame")
    infoFrame.Parent = titleBar
    infoFrame.Size = UDim2.new(0, 250, 1, 0)
    infoFrame.Position = UDim2.new(0.42, 0, 0, 0)
    infoFrame.BackgroundTransparency = 1
    
    local horarioLabel = Instance.new("TextLabel")
    horarioLabel.Parent = infoFrame
    horarioLabel.Size = UDim2.new(0, 110, 1, 0)
    horarioLabel.Position = UDim2.new(0, 0, 0, 0)
    horarioLabel.BackgroundTransparency = 1
    horarioLabel.Text = "00:00:00"
    horarioLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    horarioLabel.TextSize = 14
    horarioLabel.Font = Enum.Font.GothamBold
    horarioLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local fpsLabelScripts = Instance.new("TextLabel")
    fpsLabelScripts.Parent = infoFrame
    fpsLabelScripts.Size = UDim2.new(0, 100, 1, 0)
    fpsLabelScripts.Position = UDim2.new(0, 120, 0, 0)
    fpsLabelScripts.BackgroundTransparency = 1
    fpsLabelScripts.Text = "FPS: 0"
    fpsLabelScripts.TextColor3 = Color3.fromRGB(0, 255, 0)
    fpsLabelScripts.TextSize = 14
    fpsLabelScripts.Font = Enum.Font.GothamBold
    fpsLabelScripts.TextXAlignment = Enum.TextXAlignment.Left
    
    local minimizeBtnScripts = Instance.new("TextButton")
    minimizeBtnScripts.Parent = titleBar
    minimizeBtnScripts.Size = UDim2.new(0, 35, 0, 35)
    minimizeBtnScripts.Position = UDim2.new(1, -80, 0.5, -17.5)
    minimizeBtnScripts.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    minimizeBtnScripts.Text = "−"
    minimizeBtnScripts.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtnScripts.TextSize = 28
    minimizeBtnScripts.Font = Enum.Font.GothamBold
    Instance.new("UICorner", minimizeBtnScripts).CornerRadius = UDim.new(1, 0)
    
    local closeBtnScripts = Instance.new("TextButton")
    closeBtnScripts.Parent = titleBar
    closeBtnScripts.Size = UDim2.new(0, 35, 0, 35)
    closeBtnScripts.Position = UDim2.new(1, -40, 0.5, -17.5)
    closeBtnScripts.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtnScripts.Text = "✕"
    closeBtnScripts.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtnScripts.TextSize = 18
    closeBtnScripts.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtnScripts).CornerRadius = UDim.new(1, 0)
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 65)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search scripts..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        scriptsSearchText = searchBox.Text:lower()
        updateScriptsList()
    end)
    
    local clearSearchBtn = Instance.new("TextButton")
    clearSearchBtn.Parent = searchFrame
    clearSearchBtn.Size = UDim2.new(0, 30, 0, 30)
    clearSearchBtn.Position = UDim2.new(1, -35, 0.5, -15)
    clearSearchBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    clearSearchBtn.BackgroundTransparency = 0.2
    clearSearchBtn.Text = "✕"
    clearSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearSearchBtn.TextSize = 16
    clearSearchBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearSearchBtn).CornerRadius = UDim.new(1, 0)
    clearSearchBtn.MouseButton1Click:Connect(function() 
        searchBox.Text = "" 
        scriptsSearchText = ""
        updateScriptsList()
    end)
    
    local contentScrolling = Instance.new("ScrollingFrame")
    contentScrolling.Parent = mainFrame
    contentScrolling.Name = "ContentScrolling"
    contentScrolling.Size = UDim2.new(1, -20, 1, -125)
    contentScrolling.Position = UDim2.new(0, 10, 0, 115)
    contentScrolling.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    contentScrolling.BackgroundTransparency = 0.3
    contentScrolling.BorderSizePixel = 0
    contentScrolling.ScrollBarThickness = 6
    contentScrolling.ScrollBarImageColor3 = currentColor
    contentScrolling.ScrollingDirection = Enum.ScrollingDirection.Y
    Instance.new("UICorner", contentScrolling).CornerRadius = UDim.new(0, 10)
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Parent = contentScrolling
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScrolling.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    local lastFrameTime = tick()
    local frameCountScripts = 0
    RunService.RenderStepped:Connect(function()
        frameCountScripts = frameCountScripts + 1
        local now = tick()
        if now - lastFrameTime >= 1 then
            fpsLabelScripts.Text = "FPS: " .. frameCountScripts
            frameCountScripts = 0
            lastFrameTime = now
        end
    end)
    
    local function updateTime()
        while ScriptsMenuActive and ScriptsMenuGui do
            local horaBR = tonumber(os.date("!%H")) - 3
            if horaBR < 0 then horaBR = horaBR + 24 end
            horarioLabel.Text = string.format("%02d", horaBR) .. os.date(":%M:%S")
            task.wait(0.5)
        end
    end
    coroutine.wrap(updateTime)()
    
    local minimizeBallScripts = Instance.new("TextButton")
    minimizeBallScripts.Parent = ScriptsMenuGui
    minimizeBallScripts.Size = UDim2.new(0, 60, 0, 60)
    minimizeBallScripts.Position = UDim2.new(0.5, -30, 0.5, -30)
    minimizeBallScripts.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    minimizeBallScripts.Text = "S"
    minimizeBallScripts.TextColor3 = currentColor
    minimizeBallScripts.TextSize = 24
    minimizeBallScripts.Font = Enum.Font.GothamBold
    minimizeBallScripts.Visible = false
    minimizeBallScripts.Active = true
    minimizeBallScripts.Draggable = true
    Instance.new("UICorner", minimizeBallScripts).CornerRadius = UDim.new(1, 0)
    local ballStrokeScripts = Instance.new("UIStroke")
    ballStrokeScripts.Parent = minimizeBallScripts
    ballStrokeScripts.Thickness = 3
    ballStrokeScripts.Color = currentColor
    ballStrokeScripts.Transparency = 0.2
    
    local isScriptsMinimized = false
    minimizeBtnScripts.MouseButton1Click:Connect(function()
        isScriptsMinimized = true
        mainFrame.Visible = false
        minimizeBallScripts.Visible = true
    end)
    
    minimizeBallScripts.MouseButton1Click:Connect(function()
        isScriptsMinimized = false
        mainFrame.Visible = true
        minimizeBallScripts.Visible = false
        updateScriptsList()
    end)
    
    closeBtnScripts.MouseButton1Click:Connect(function()
        ScriptsMenuActive = false
        if ScriptsMenuGui then ScriptsMenuGui:Destroy() end
        ScriptsMenuGui = nil
    end)
    
    updateScriptsList()
end

-- ==================== CREATE GUI PRINCIPAL ====================
local gui = Instance.new("ScreenGui")
gui.Name = "VitorHub"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100

local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.new(0, 630, 0, 430)
main.Position = UDim2.new(0.5, -315, 0.5, -215)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Draggable = true
main.ZIndex = 10
main.Visible = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)
local mainStroke = Instance.new("UIStroke")
mainStroke.Parent = main
mainStroke.Thickness = 2.5
mainStroke.Color = currentColor
mainStroke.Transparency = 0.2

local topBar = Instance.new("Frame")
topBar.Parent = main
topBar.Size = UDim2.new(1, 0, 0, 55)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBar.BackgroundTransparency = 0.1
topBar.ZIndex = 11
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 20)

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        uiDragging = true
        dragOffset = Vector2.new(input.Position.X - main.AbsolutePosition.X, input.Position.Y - main.AbsolutePosition.Y)
    end
end)
UIS.InputChanged:Connect(function(input)
    if uiDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        main.Position = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        uiDragging = false
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = topBar
titleLabel.Size = UDim2.new(0, 250, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Vitor Hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 12

local minBtn = Instance.new("TextButton")
minBtn.Parent = topBar
minBtn.Size = UDim2.new(0, 40, 0, 40)
minBtn.Position = UDim2.new(1, -90, 0.5, -20)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 28
minBtn.Font = Enum.Font.GothamBold
minBtn.ZIndex = 12
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = topBar
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0.5, -20)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 12
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.MouseButton1Click:Connect(function() 
    deactivateFreeCam()
    pcall(function() gui:Destroy() end) 
end)

-- ==================== TOP STATUS BAR ====================
local infoFrame = Instance.new("Frame")
infoFrame.Parent = main
infoFrame.Size = UDim2.new(0, 540, 0, 30)
infoFrame.Position = UDim2.new(0, 45, 0, 140)
infoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
infoFrame.BackgroundTransparency = 0.3
infoFrame.ZIndex = 11
Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 8)

local statusLayout = Instance.new("UIListLayout")
statusLayout.Parent = infoFrame
statusLayout.FillDirection = Enum.FillDirection.Horizontal
statusLayout.Padding = UDim.new(0, 10)
statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local brasiliaLabel = Instance.new("TextLabel")
brasiliaLabel.Parent = infoFrame
brasiliaLabel.Size = UDim2.new(0, 130, 1, 0)
brasiliaLabel.BackgroundTransparency = 1
brasiliaLabel.Text = "Brasilia: 00:00:00"
brasiliaLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
brasiliaLabel.TextSize = 12
brasiliaLabel.Font = Enum.Font.GothamBold
brasiliaLabel.TextXAlignment = Enum.TextXAlignment.Center
brasiliaLabel.ZIndex = 12

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Parent = infoFrame
fpsLabel.Size = UDim2.new(0, 130, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "Fps: 0"
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsLabel.TextSize = 12
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextXAlignment = Enum.TextXAlignment.Center
fpsLabel.ZIndex = 12

local playersLabel = Instance.new("TextLabel")
playersLabel.Parent = infoFrame
playersLabel.Size = UDim2.new(0, 80, 1, 0)
playersLabel.BackgroundTransparency = 1
playersLabel.Text = "Players: 0"
playersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playersLabel.TextSize = 12
playersLabel.Font = Enum.Font.GothamBold
playersLabel.TextXAlignment = Enum.TextXAlignment.Center
playersLabel.ZIndex = 12

local servidorLabel = Instance.new("TextLabel")
servidorLabel.Parent = infoFrame
servidorLabel.Size = UDim2.new(0, 130, 1, 0)
servidorLabel.BackgroundTransparency = 1
servidorLabel.Text = "Server: 00:00:00"
servidorLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
servidorLabel.TextSize = 12
servidorLabel.Font = Enum.Font.GothamBold
servidorLabel.TextXAlignment = Enum.TextXAlignment.Center
servidorLabel.ZIndex = 12

local lastTime = tick()
local frameCount = 0
local fpsConnection = RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastTime >= 1 then
        fpsLabel.Text = "Fps: " .. frameCount
        frameCount = 0
        lastTime = now
    end
end)

coroutine.wrap(function()
    while task.wait(0.1) do
        local horaBR = tonumber(os.date("!%H")) - 3
        if horaBR < 0 then horaBR = horaBR + 24 end
        brasiliaLabel.Text = "Brasilia: " .. string.format("%02d", horaBR) .. os.date(":%M:%S")
        playersLabel.Text = "Players: " .. #Players:GetPlayers()
        local sessionSeconds = os.difftime(os.time(), UIState.sessionStart)
        servidorLabel.Text = string.format("Server: %02d:%02d:%02d", math.floor(sessionSeconds / 3600), math.floor((sessionSeconds % 3600) / 60), sessionSeconds % 60)
    end
end)()

-- ==================== AVATAR ====================
local avatarFrame = Instance.new("Frame")
avatarFrame.Parent = main
avatarFrame.Size = UDim2.new(0, 80, 0, 80)
avatarFrame.Position = UDim2.new(0, 20, 0, 75)
avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
avatarFrame.BackgroundTransparency = 0.9
avatarFrame.BorderSizePixel = 0
avatarFrame.ZIndex = 11
Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
local avatarStroke = Instance.new("UIStroke")
avatarStroke.Parent = avatarFrame
avatarStroke.Thickness = 3
avatarStroke.Color = currentColor
avatarStroke.Transparency = 0.2

local avatarImg = Instance.new("ImageLabel")
avatarImg.Parent = avatarFrame
avatarImg.Size = UDim2.new(1, -6, 1, -6)
avatarImg.Position = UDim2.new(0, 3, 0, 3)
avatarImg.BackgroundTransparency = 1
local success, thumbnail = pcall(function()
    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)
avatarImg.Image = success and thumbnail or "rbxasset://textures/ui/GuiImagePlaceholder.png"
avatarImg.ZIndex = 12
Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

local nome = Instance.new("TextLabel")
nome.Parent = main
nome.Size = UDim2.new(0, 350, 0, 30)
nome.Position = UDim2.new(0, 115, 0, 85)
nome.BackgroundTransparency = 1
nome.Text = player.Name
nome.TextColor3 = Color3.fromRGB(255, 255, 255)
nome.TextSize = 24
nome.Font = Enum.Font.GothamBold
nome.TextXAlignment = Enum.TextXAlignment.Left
nome.ZIndex = 11
local nomeGlow = Instance.new("UIStroke")
nomeGlow.Parent = nome
nomeGlow.Thickness = 1.5
nomeGlow.Color = currentColor
nomeGlow.Transparency = 0.2

local admin = Instance.new("TextLabel")
admin.Parent = main
admin.Size = UDim2.new(0, 350, 0, 22)
admin.Position = UDim2.new(0, 115, 0, 115)
admin.BackgroundTransparency = 1
admin.Text = "Admin"
admin.TextColor3 = Color3.fromRGB(255, 50, 50)
admin.TextSize = 18
admin.Font = Enum.Font.GothamBold
admin.TextXAlignment = Enum.TextXAlignment.Left
admin.ZIndex = 11

-- ==================== TABS ====================
local tabContainer = Instance.new("Frame")
tabContainer.Parent = main
tabContainer.Size = UDim2.new(0, 590, 0, 45)
tabContainer.Position = UDim2.new(0, 20, 0, 180)
tabContainer.BackgroundTransparency = 1
tabContainer.ClipsDescendants = true
tabContainer.ZIndex = 11

local tabScrollingFrame = Instance.new("ScrollingFrame")
tabScrollingFrame.Parent = tabContainer
tabScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
tabScrollingFrame.BackgroundTransparency = 1
tabScrollingFrame.BorderSizePixel = 0
tabScrollingFrame.CanvasSize = UDim2.new(10, 0, 0, 0)
tabScrollingFrame.ScrollBarThickness = 0
tabScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.X
tabScrollingFrame.ZIndex = 11

local tabLayout = Instance.new("UIListLayout")
tabLayout.Parent = tabScrollingFrame
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 10)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

local function createTabButton(text)
    local btn = Instance.new("TextButton")
    btn.Parent = tabScrollingFrame
    btn.Size = UDim2.new(0, 110, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    return btn
end

local homeBtn = createTabButton("Home")
local visualBtn = createTabButton("Visual")
local aimbotBtn = createTabButton("Aimbot")
local serverBtn = createTabButton("Server")
local calcBtn = createTabButton("Calc")
local colorBtn = createTabButton("Color")
local adminsBtn = createTabButton("Admins")

homeBtn.BackgroundColor3 = currentColor
homeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Parent = main
contentFrame.Size = UDim2.new(0, 590, 0, 170)
contentFrame.Position = UDim2.new(0, 20, 0, 235)
contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = currentColor
contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
contentFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
contentFrame.ZIndex = 11
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 12)

local contentList = Instance.new("UIListLayout")
contentList.Parent = contentFrame
contentList.Padding = UDim.new(0, 8)
contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center

contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 15)
end)

local ball = Instance.new("TextButton")
ball.Parent = gui
ball.Size = UDim2.new(0, 60, 0, 60)
ball.Position = UDim2.new(0.5, -30, 0.5, -30)
ball.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
ball.Text = "V"
ball.TextColor3 = currentColor
ball.TextSize = 32
ball.Font = Enum.Font.GothamBold
ball.Visible = false
ball.Active = true
ball.Draggable = true
ball.ZIndex = 50
Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
local ballStroke = Instance.new("UIStroke")
ballStroke.Parent = ball
ballStroke.Thickness = 3
ballStroke.Color = currentColor
ballStroke.Transparency = 0.2

-- ==================== CREATION FUNCTIONS ====================
local function clearContent()
    for _, v in pairs(contentFrame:GetChildren()) do
        if v ~= contentList then v:Destroy() end
    end
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(0, 560, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamSemibold
    btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createSliderWithInput(parent, name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(0, 560, 0, 70)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 12
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.4, 0, 0.4, 0)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    
    local inputBox = Instance.new("TextBox")
    inputBox.Parent = frame
    inputBox.Size = UDim2.new(0, 80, 0, 32)
    inputBox.Position = UDim2.new(0.42, 0, 0, 3)
    inputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    inputBox.BackgroundTransparency = 0.3
    inputBox.Text = tostring(default)
    inputBox.TextColor3 = currentColor
    inputBox.TextSize = 16
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Size = UDim2.new(0.15, 0, 0.4, 0)
    valueLabel.Position = UDim2.new(0.85, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = currentColor
    valueLabel.TextSize = 16
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.ZIndex = 13
    
    local bg = Instance.new("Frame")
    bg.Parent = frame
    bg.Size = UDim2.new(0.9, 0, 0, 18)
    bg.Position = UDim2.new(0.05, 0, 0, 45)
    bg.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    bg.ZIndex = 13
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Parent = bg
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = currentColor
    fill.ZIndex = 14
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local dragBtn = Instance.new("TextButton")
    dragBtn.Parent = bg
    dragBtn.Size = UDim2.new(1, 0, 1, 0)
    dragBtn.BackgroundTransparency = 1
    dragBtn.Text = ""
    dragBtn.ZIndex = 15
    
    local val = default
    local dragging = false
    
    local function updateValue(newVal)
        val = math.clamp(newVal, min, max)
        local perc = (val - min) / (max - min)
        fill.Size = UDim2.new(perc, 0, 1, 0)
        valueLabel.Text = tostring(val)
        inputBox.Text = tostring(val)
        callback(val)
    end
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(inputBox.Text)
            if num then
                updateValue(num)
            else
                inputBox.Text = tostring(val)
            end
        end
    end)
    
    dragBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mouse = UIS:GetMouseLocation()
            local pos = bg.AbsolutePosition
            local size = bg.AbsoluteSize
            local perc = math.clamp((mouse.X - pos.X) / size.X, 0, 1)
            local newVal = math.floor(min + (max - min) * perc)
            if newVal ~= val then
                updateValue(newVal)
            end
        end
    end)
    
    updateValue(default)
end

local function createToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(0, 560, 0, 42)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 12
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = frame
    toggleBtn.Size = UDim2.new(0, 60, 0, 30)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 13
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
    
    local indicator = Instance.new("Frame")
    indicator.Parent = toggleBtn
    indicator.Size = UDim2.new(0, 24, 0, 24)
    indicator.Position = default and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
    indicator.BackgroundColor3 = default and currentColor or Color3.fromRGB(100, 100, 100)
    indicator.ZIndex = 14
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    local state = default
    
    local function updateToggle()
        indicator.Position = state and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
        indicator.BackgroundColor3 = state and currentColor or Color3.fromRGB(100, 100, 100)
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
        callback(state)
    end)
end

-- ==================== LOAD HOME TAB ====================
local function loadHome()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = mainFrame
    controlsFrame.Size = UDim2.new(1, -20, 1, -20)
    controlsFrame.Position = UDim2.new(0, 10, 0, 10)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.ZIndex = 13
    
    local controlsList = Instance.new("UIListLayout")
    controlsList.Parent = controlsFrame
    controlsList.Padding = UDim.new(0, 8)
    controlsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createSliderWithInput(controlsFrame, "Walk Speed", 16, 500, UIState.currentSpeed, function(v)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = v
            UIState.currentSpeed = v
        end
    end)
    
    createSliderWithInput(controlsFrame, "Jump Power", 50, 500, UIState.currentJump, function(v)
        setJumpPower(v)
        UIState.currentJump = v
    end)
    
    createSliderWithInput(controlsFrame, "Tp Walk Speed", 1, 500, UIState.currentTPWalkSpeed, function(v) 
        tpwalkSpeed = v
        UIState.currentTPWalkSpeed = v 
    end)
    
    createToggle(controlsFrame, "Tp Walk", UIState.tpwalkEnabled, function(v) toggleTpwalk(v) end)
    createToggle(controlsFrame, "Infinite Jump", UIState.infjumpEnabled, function(v) infjump = v; UIState.infjumpEnabled = v end)
    createToggle(controlsFrame, "Noclip", UIState.noclipEnabled, function(v) toggleNoclip(v) end)
    createToggle(controlsFrame, "Ghost Mode", UIState.ghostEnabled, function(v) toggleGhost(v) end)
    createToggle(controlsFrame, "Free Cam", UIState.freeCamEnabled, function(v)
        local toggleRef = nil
        for _, child in pairs(controlsFrame:GetChildren()) do
            if child:IsA("Frame") then
                for _, btn in pairs(child:GetChildren()) do
                    if btn:IsA("TextButton") and btn.Text == "" then
                        toggleRef = btn
                        break
                    end
                end
            end
        end
        toggleFreeCam(v, toggleRef)
    end)
    
    createButton(controlsFrame, " Scripts Menu", CreateScriptsMenu)
    createButton(controlsFrame, " Waypoint System", executeWaypoint)
    createButton(controlsFrame, " Float", executeFloat)
    createButton(controlsFrame, " Spectate + TP", executeSpectate)
    createButton(controlsFrame, "Fly Gui V3", function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))() end)
    end)
    createButton(controlsFrame, "Fly Vehicle V4", function()
        pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/ScpGuest666/Random-Roblox-script/refs/heads/main/Roblox%20Fe%20Vehicle%20Fly%20GUI%20script'))() end)
    end)
    createButton(controlsFrame, "All Animations / All Emotes", function()
        pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))() end)
    end)
    createButton(controlsFrame, "Delta Keyboard Mobile", function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Xxtan31/Ata/main/deltakeyboardcrack.txt"))() end)
    end)
    createButton(controlsFrame, "Teleport Tool Fe", function()
        pcall(function()
            local mouse = game.Players.LocalPlayer:GetMouse()
            local tool = Instance.new("Tool")
            tool.RequiresHandle = false
            tool.Name = "QQ Teleport"
            tool.Activated:Connect(function()
                local pos = mouse.Hit + Vector3.new(0,2.5,0)
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X,pos.Y,pos.Z)
            end)
            tool.Parent = game.Players.LocalPlayer.Backpack
        end)
    end)
    createButton(controlsFrame, "Youtube Music Player", function()
        pcall(function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/Dan41/Roblox-Scripts/refs/heads/main/Youtube%20Music%20Player/YoutubeMusicPlayer.lua'),true))() end)
    end)
end

-- ==================== LOAD VISUAL TAB ====================
local function loadVisual()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Visual Settings"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = mainFrame
    controlsFrame.Size = UDim2.new(1, -20, 1, -20)
    controlsFrame.Position = UDim2.new(0, 10, 0, 40)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    controlsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 8)
    
    local toggleList = Instance.new("UIListLayout")
    toggleList.Parent = controlsFrame
    toggleList.Padding = UDim.new(0, 8)
    toggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createToggle(controlsFrame, "Day", UIState.dayEnabled, toggleDay)
    createToggle(controlsFrame, "Night", UIState.nightEnabled, toggleNight)
    createToggle(controlsFrame, "Fullbright", UIState.fullbrightEnabled, toggleFullbright)
    createToggle(controlsFrame, "No Fog", UIState.noFogEnabled, toggleNoFog)
    createToggle(controlsFrame, "X-Ray", UIState.xrayEnabled, toggleXRay)
    createToggle(controlsFrame, "No Clip Camera", UIState.noClipCameraEnabled, toggleNoClipCamera)
end

-- ==================== LOAD SERVER TAB ====================
local function loadServer()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Server"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = mainFrame
    buttonsFrame.Size = UDim2.new(1, -20, 0, 200)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 40)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    buttonsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", buttonsFrame).CornerRadius = UDim.new(0, 8)
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.Parent = buttonsFrame
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createButton(buttonsFrame, "Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)
    createButton(buttonsFrame, "Reset Character", function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
        end
    end)
    createButton(buttonsFrame, "Small Server", function()
        pcall(function()
            local placeId = game.PlaceId
            local response = game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100")
            local data = HttpService:JSONDecode(response)
            local smallestServer = nil
            local smallestPlayers = math.huge
            for _, server in ipairs(data.data) do
                if server.playing < smallestPlayers then
                    smallestPlayers = server.playing
                    smallestServer = server.id
                end
            end
            if smallestServer then
                TeleportService:TeleportToPlaceInstance(placeId, smallestServer, player)
                StarterGui:SetCore("SendNotification", { Title = "Small Server", Text = "Teleporting to server with " .. smallestPlayers .. " players", Duration = 3 })
            end
        end)
    end)
end

-- ==================== LOAD AIMBOT TAB ====================
local function loadAimbot()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Aimbot & ESP"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local togglesFrame = Instance.new("Frame")
    togglesFrame.Parent = mainFrame
    togglesFrame.Size = UDim2.new(1, -20, 0, 500)
    togglesFrame.Position = UDim2.new(0, 10, 0, 40)
    togglesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    togglesFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", togglesFrame).CornerRadius = UDim.new(0, 8)
    
    local togglesLayout = Instance.new("UIListLayout")
    togglesLayout.Parent = togglesFrame
    togglesLayout.Padding = UDim.new(0, 10)
    togglesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createToggle(togglesFrame, "Aimbot Perseguir (Chase - With Prediction)", UIState.aimbotChaseEnabled, toggleAimbotChase)
    createSliderWithInput(togglesFrame, "Aimbot Perseguir Distance", 0, 500, UIState.aimbotChaseDistance, function(v)
        setAimbotChaseDistance(v)
    end)
    
    local separator = Instance.new("Frame")
    separator.Parent = togglesFrame
    separator.Size = UDim2.new(0.9, 0, 0, 2)
    separator.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    separator.BackgroundTransparency = 0.5
    
    createToggle(togglesFrame, "Aimbot Normal (Center Head - No Prediction)", UIState.aimbotNormalEnabled, toggleAimbotNormal)
    createSliderWithInput(togglesFrame, "Aimbot Normal Distance", 0, 500, UIState.aimbotNormalDistance, function(v)
        setAimbotNormalDistance(v)
    end)
    
    local separator2 = Instance.new("Frame")
    separator2.Parent = togglesFrame
    separator2.Size = UDim2.new(0.9, 0, 0, 2)
    separator2.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    separator2.BackgroundTransparency = 0.5
    
    createToggle(togglesFrame, "Telekill", UIState.telekillEnabled, toggleTelekill)
    createToggle(togglesFrame, "Bring All", UIState.bringAllEnabled, toggleBringAll)
    createButton(togglesFrame, " ESP MENU (Box + Tracer + Item)", CreateEspMenu)
    
    local aimIgnoreBtn = Instance.new("TextButton")
    aimIgnoreBtn.Parent = togglesFrame
    aimIgnoreBtn.Size = UDim2.new(0, 560, 0, 42)
    aimIgnoreBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    aimIgnoreBtn.Text = "Open Aim Ignore Menu"
    aimIgnoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimIgnoreBtn.TextSize = 16
    aimIgnoreBtn.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", aimIgnoreBtn).CornerRadius = UDim.new(0, 8)
    aimIgnoreBtn.MouseButton1Click:Connect(CreateAimIgnorePopup)
end

-- ==================== LOAD CALCULATOR TAB ====================
local function loadCalculator()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Calculator"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local calcFrame = Instance.new("Frame")
    calcFrame.Parent = mainFrame
    calcFrame.Size = UDim2.new(0, 560, 0, 300)
    calcFrame.Position = UDim2.new(0, 0, 0, 40)
    calcFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    calcFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", calcFrame).CornerRadius = UDim.new(0, 12)
    
    local display = Instance.new("TextBox")
    display.Parent = calcFrame
    display.Size = UDim2.new(0.9, 0, 0, 50)
    display.Position = UDim2.new(0.05, 0, 0, 20)
    display.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    display.BackgroundTransparency = 0.2
    display.PlaceholderText = "0"
    display.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    display.Text = "0"
    display.TextColor3 = Color3.fromRGB(255, 255, 255)
    display.TextSize = 24
    display.Font = Enum.Font.GothamBold
    display.TextXAlignment = Enum.TextXAlignment.Right
    display.ClearTextOnFocus = false
    Instance.new("UICorner", display).CornerRadius = UDim.new(0, 8)
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = calcFrame
    buttonsFrame.Size = UDim2.new(0.9, 0, 0, 180)
    buttonsFrame.Position = UDim2.new(0.05, 0, 0, 90)
    buttonsFrame.BackgroundTransparency = 1
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Parent = buttonsFrame
    gridLayout.CellSize = UDim2.new(0, 120, 0, 40)
    gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    
    local function evaluateExpression(expr)
        local clean = expr:gsub("[^%d%+%-%*%/%.%(%)]", "")
        if clean == "" then return "0" end
        local func, err = loadstring("return " .. clean)
        if not func then return "Error" end
        local success, result = pcall(func)
        if success and type(result) == "number" then return tostring(result) else return "Error" end
    end
    
    local numbers = { {"7", "8", "9", "/"}, {"4", "5", "6", "*"}, {"1", "2", "3", "-"}, {"0", ".", "=", "+"} }
    
    for row = 1, 4 do
        for col = 1, 4 do
            local btnText = numbers[row][col]
            local btn = Instance.new("TextButton")
            btn.Parent = buttonsFrame
            btn.Size = UDim2.new(0, 120, 0, 40)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            btn.BackgroundTransparency = 0.2
            btn.Text = btnText
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 18
            btn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            
            btn.MouseButton1Click:Connect(function()
                local currentText = display.Text
                if btnText == "=" then
                    display.Text = evaluateExpression(currentText)
                elseif btnText == "C" then
                    display.Text = "0"
                else
                    if currentText == "0" or currentText == "Error" then
                        display.Text = btnText
                    else
                        display.Text = currentText .. btnText
                    end
                end
            end)
        end
    end
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = calcFrame
    clearBtn.Size = UDim2.new(0.9, 0, 0, 40)
    clearBtn.Position = UDim2.new(0.05, 0, 0, 280)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "Clear"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 18
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
    clearBtn.MouseButton1Click:Connect(function() display.Text = "0" end)
end

-- ==================== LOAD ADMINS TAB ====================
local function loadAdmins()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Admin Scripts"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = mainFrame
    buttonsFrame.Size = UDim2.new(1, -20, 0, 350)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 40)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    buttonsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", buttonsFrame).CornerRadius = UDim.new(0, 8)
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.Parent = buttonsFrame
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createButton(buttonsFrame, "Infinity Yield", function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end) end)
    createButton(buttonsFrame, "Dark Dex Explorer (Mobile)", function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifacttx/YumeHub/refs/heads/main/Universal/DarkDex_Mobile", true))() end) end)
    createButton(buttonsFrame, "Paranoia Admin Fe", function() pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Paranoia-Admin-FE-72345"))() end) end)
    createButton(buttonsFrame, "Nameless Admin Fe", function() pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source'))() end) end)
end

-- ==================== LOAD COLOR TAB ====================
local function loadColor()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Color Settings"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = mainFrame
    controlsFrame.Size = UDim2.new(1, -20, 0, 300)
    controlsFrame.Position = UDim2.new(0, 10, 0, 40)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    controlsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 8)
    
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Parent = controlsFrame
    toggleContainer.Size = UDim2.new(1, -20, 1, -20)
    toggleContainer.Position = UDim2.new(0, 10, 0, 10)
    toggleContainer.BackgroundTransparency = 1
    
    local toggleList = Instance.new("UIListLayout")
    toggleList.Parent = toggleContainer
    toggleList.Padding = UDim.new(0, 8)
    toggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createToggle(toggleContainer, "Rainbow Mode", rainbowActive, function(v)
        rainbowActive = v
        UIState.rainbowActive = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor
            avatarStroke.Color = currentColor
            nomeGlow.Color = currentColor
            ball.TextColor3 = currentColor
            ballStroke.Color = currentColor
            contentFrame.ScrollBarImageColor3 = currentColor
            homeBtn.BackgroundColor3 = currentColor
        end
    end)
    
    createSliderWithInput(toggleContainer, "Red", 0, 255, rVal, function(v)
        rVal = v; UIState.rVal = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor; avatarStroke.Color = currentColor; nomeGlow.Color = currentColor
            ball.TextColor3 = currentColor; ballStroke.Color = currentColor
            contentFrame.ScrollBarImageColor3 = currentColor; homeBtn.BackgroundColor3 = currentColor
        end
    end)
    
    createSliderWithInput(toggleContainer, "Green", 0, 255, gVal, function(v)
        gVal = v; UIState.gVal = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor; avatarStroke.Color = currentColor; nomeGlow.Color = currentColor
            ball.TextColor3 = currentColor; ballStroke.Color = currentColor
            contentFrame.ScrollBarImageColor3 = currentColor; homeBtn.BackgroundColor3 = currentColor
        end
    end)
    
    createSliderWithInput(toggleContainer, "Blue", 0, 255, bVal, function(v)
        bVal = v; UIState.bVal = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor; avatarStroke.Color = currentColor; nomeGlow.Color = currentColor
            ball.TextColor3 = currentColor; ballStroke.Color = currentColor
            contentFrame.ScrollBarImageColor3 = currentColor; homeBtn.BackgroundColor3 = currentColor
        end
    end)
end

-- ==================== TAB EVENTS ====================
homeBtn.MouseButton1Click:Connect(function() activeTab = "HOME"; loadHome() end)
visualBtn.MouseButton1Click:Connect(function() activeTab = "VISUAL"; loadVisual() end)
aimbotBtn.MouseButton1Click:Connect(function() activeTab = "AIMBOT"; loadAimbot() end)
serverBtn.MouseButton1Click:Connect(function() activeTab = "SERVER"; loadServer() end)
calcBtn.MouseButton1Click:Connect(function() activeTab = "CALC"; loadCalculator() end)
colorBtn.MouseButton1Click:Connect(function() activeTab = "COLOR"; loadColor() end)
adminsBtn.MouseButton1Click:Connect(function() activeTab = "ADMINS"; loadAdmins() end)

-- ==================== MINIMIZE/RESTORE ====================
minBtn.MouseButton1Click:Connect(function()
    if isMinimized then return end
    isMinimized = true
    TweenService:Create(main, TweenInfo.new(0.4), { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
    task.wait(0.3)
    main.Visible = false
    ball.Visible = true
    ball.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(ball, TweenInfo.new(0.4), { Size = UDim2.new(0, 60, 0, 60) }):Play()
end)

ball.MouseButton1Click:Connect(function()
    if not isMinimized then return end
    TweenService:Create(ball, TweenInfo.new(0.3), { Size = UDim2.new(0, 0, 0, 0) }):Play()
    task.wait(0.2)
    ball.Visible = false
    main.Visible = true
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    TweenService:Create(main, TweenInfo.new(0.4), { Size = UDim2.new(0, 630, 0, 430), Position = UDim2.new(0.5, -315, 0.5, -215), BackgroundTransparency = 0.1 }):Play()
    task.wait(0.4)
    isMinimized = false
end)

-- ==================== RAINBOW EFFECT ====================
local hue = 0
rainbowConnection = RunService.RenderStepped:Connect(function()
    if rainbowActive then
        hue = (hue + 0.003) % 1
        currentColor = Color3.fromHSV(hue, 1, 1)
        UIState.currentColor = currentColor
        mainStroke.Color = currentColor
        avatarStroke.Color = currentColor
        nomeGlow.Color = currentColor
        ball.TextColor3 = currentColor
        ballStroke.Color = currentColor
        contentFrame.ScrollBarImageColor3 = currentColor
        if activeTab == "HOME" then homeBtn.BackgroundColor3 = currentColor
        elseif activeTab == "VISUAL" then visualBtn.BackgroundColor3 = currentColor
        elseif activeTab == "AIMBOT" then aimbotBtn.BackgroundColor3 = currentColor
        elseif activeTab == "SERVER" then serverBtn.BackgroundColor3 = currentColor
        elseif activeTab == "CALC" then calcBtn.BackgroundColor3 = currentColor
        elseif activeTab == "COLOR" then colorBtn.BackgroundColor3 = currentColor
        elseif activeTab == "ADMINS" then adminsBtn.BackgroundColor3 = currentColor end
    end
end)

UIS.JumpRequest:Connect(function()
    if infjump and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================== START ====================
loadHome()

task.wait(1)
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Vitor Hub",
        Text = "Vitor Hub Loaded! 2 Aimbots | ESP with ITEM | Spectator with BANG | Aim Ignore Menu | Scripts Menu with 8 Games!",
        Duration = 3
    })
end)
