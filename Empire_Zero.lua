-- =======================================================================
-- 🌐 EMPIRE ZÉRO v6.1 | REVISED MOBILE & CAR MODS UPDATE | LOGO TOGGLE
-- =======================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Tables de gestion
local ESPConnections = {}
local CharacterConnections = {}
local FlySessionToken = 0
local FlingConnection = nil
local MobileUI = nil

-- 🛡️ PROTECTION / BYPASS SÉCURISÉ
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and self:IsA("RemoteEvent") then
        local nameLower = tostring(self.Name):lower()
        if nameLower:find("cheat") or nameLower:find("ban") or nameLower:find("kick") then
            return nil
        end
    end
    return oldNamecall(self, ...)
end)

-- 🎨 LIBRAIRIE GRAPHIQUE (Kavo UI)
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("EMPIRE ZÉRO v6.1 - Mobile & PC", "DarkTheme")

-- Configuration Globale
getgenv().CarFlySpeed = 50
getgenv().InfVitesse = 16
getgenv().HitboxTaille = 2

-- Onglets
local MainTab = Window:NewTab("Mouvements")
local CombatTab = Window:NewTab("Combat")
local CarTab = Window:NewTab("Car Mods")
local VisualsTab = Window:NewTab("Visuals")

-- =======================================================================
-- 👁️ GESTION DU BOUTON FLOTTANT EMPIRE ZÉRO (REOUVERTURE)
-- =======================================================================
local MainGui = nil
-- Recherche de la Frame principale créée par Kavo UI
for _, gui in pairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui:FindFirstChild("Main") then
        MainGui = gui
        break
    end
end

if MainGui then
    local MainFrame = MainGui:FindFirstChild("Main")
    
    -- Création du bouton avec le logo de l'Empire
    local EmpireToggleButton = Instance.new("ImageButton")
    EmpireToggleButton.Name = "EmpireToggleBtn"
    EmpireToggleButton.Size = UDim2.new(0, 65, 0, 65)
    EmpireToggleButton.Position = UDim2.new(0.05, 0, 0.15, 0) -- Position initiale en haut à gauche
    EmpireToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    EmpireToggleButton.BackgroundTransparency = 0.3
    EmpireToggleButton.Image = "rbxassetid://1514682630803816508" -- Ton logo injecté via asset id
    EmpireToggleButton.Visible = false
    EmpireToggleButton.Parent = MainGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 15)
    UICorner.Parent = EmpireToggleButton

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 0, 0) -- Contour rouge stylé Empire
    UIStroke.Thickness = 2
    UIStroke.Parent = EmpireToggleButton

    -- Rendre le logo déplaçable sur l'écran (Drag) pour le confort sur Mobile/PC
    local dragging, dragInput, dragStart, startPos
    EmpireToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = EmpireToggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    EmpireToggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            EmpireToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Détection du clic sur la croix (X) d'origine de Kavo
    local CloseBtn = MainFrame:FindFirstChild("CloseBtn") or MainFrame:Descendents() and MainFrame:FindFirstChild("Close", true)
    if MainFrame and MainFrame:FindFirstChild("TopBar") then
        -- Kavo met souvent le bouton de fermeture dans la TopBar
        CloseBtn = MainFrame.TopBar:FindFirstChild("CloseBtn") or MainFrame.TopBar:FindFirstChild("Close")
    end

    if CloseBtn and CloseBtn:IsA("GuiButton") then
        CloseBtn.MouseButton1Click:Connect(function()
            MainFrame.Visible = false
            EmpireToggleButton.Visible = true
        end)
    end

    -- Action lors du clic sur le logo Empire : réaffiche le menu et cache le logo
    EmpireToggleButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        EmpireToggleButton.Visible = false
    end)
end

-- ==========================================
-- 🚗 CONFIGURATION CAR MODS ADVANCED
-- ==========================================
local CarSection = CarTab:NewSection("Car Mod Options")

local function GetCurrentVehicle()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        return hum.SeatPart.AssemblyRootPart, hum.SeatPart
    end
    return nil, nil
end

local function TeleportToOWNVehicle()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil, nil end

    local targetSeat = nil

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") then
            local vehicleModel = v:FindFirstAncestorOfClass("Model")
            if vehicleModel then
                local ownerValue = vehicleModel:FindFirstChild("Owner") or vehicleModel:FindFirstChild("Player")
                if vehicleModel.Name == LocalPlayer.Name or vehicleModel.Name:find(LocalPlayer.Name) or (ownerValue and tostring(ownerValue.Value) == LocalPlayer.Name) then
                    targetSeat = v
                    break
                end
            end
        end
    end

    if not targetSeat then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("VehicleSeat") and not v.Occupant then
                targetSeat = v
                break
            end
        end
    end

    if targetSeat then
        targetSeat:Sit(hum)
        task.wait(0.15)
        return targetSeat.AssemblyRootPart, targetSeat
    end
    return nil, nil
end

local function CreateMobileControls()
    if MobileUI then MobileUI:Destroy() end
    
    MobileUI = Instance.new("ScreenGui")
    MobileUI.Name = "EmpireMobileControls"
    MobileUI.ResetOnSpawn = false
    
    local UpBtn = Instance.new("TextButton")
    UpBtn.Size = UDim2.new(0, 70, 0, 70)
    UpBtn.Position = UDim2.new(0.85, 0, 0.55, 0)
    UpBtn.Text = "▲"
    UpBtn.TextSize = 30
    UpBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    UpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    UpBtn.BackgroundTransparency = 0.4
    UpBtn.Parent = MobileUI
    
    local DownBtn = Instance.new("TextButton")
    DownBtn.Size = UDim2.new(0, 70, 0, 70)
    DownBtn.Position = UDim2.new(0.85, 0, 0.7, 0)
    DownBtn.Text = "▼"
    DownBtn.TextSize = 30
    DownBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    DownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DownBtn.BackgroundTransparency = 0.4
    DownBtn.Parent = MobileUI

    local UICorner1 = Instance.new("UICorner") UICorner1.CornerRadius = UDim.new(0, 15) UICorner1.Parent = UpBtn
    local UICorner2 = Instance.new("UICorner") UICorner2.CornerRadius = UDim.new(0, 15) UICorner2.Parent = DownBtn

    local isGoingUp, isGoingDown = false, false
    UpBtn.MouseButton1Down:Connect(function() isGoingUp = true end)
    UpBtn.MouseButton1Up:Connect(function() isGoingUp = false end)
    DownBtn.MouseButton1Down:Connect(function() isGoingDown = true end)
    DownBtn.MouseButton1Up:Connect(function() isGoingDown = false end)
    
    pcall(function() MobileUI.Parent = CoreGui end)
    
    return function()
        if isGoingUp then return Vector3.new(0, 1, 0)
        elseif isGoingDown then return Vector3.new(0, -1, 0)
        end
        return Vector3.new(0, 0, 0)
    end
end

CarSection:NewToggle("Car Fly", "Te TP direct dans TA voiture et s'active immédiatement", function(state)
    getgenv().CarFly = state
    local vehicle, seat = GetCurrentVehicle()
    
    if state then
        FlySessionToken = FlySessionToken + 1
        local currentToken = FlySessionToken
        
        if not vehicle then
            vehicle, seat = TeleportToOWNVehicle()
        end
        
        if vehicle then
            local BG = vehicle:FindFirstChild("EmpireCarGyro") or Instance.new("BodyGyro")
            BG.Name = "EmpireCarGyro"
            BG.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
            BG.cframe = vehicle.CFrame
            BG.Parent = vehicle
            
            local BV = vehicle:FindFirstChild("EmpireCarVelocity") or Instance.new("BodyVelocity")
            BV.Name = "EmpireCarVelocity"
            BV.maxForce = Vector3.new(math.huge, math.huge, math.huge)
            BV.velocity = Vector3.new(0, 0, 0)
            BV.Parent = vehicle
            
            local GetMobileVertical = function() return Vector3.new(0,0,0) end
            if UserInputService.TouchEnabled then
                GetMobileVertical = CreateMobileControls()
            end
            
            task.spawn(function()
                while getgenv().CarFly and currentToken == FlySessionToken and task.wait() do
                    local curVehicle, curSeat = GetCurrentVehicle()
                    if curVehicle and curVehicle:FindFirstChild("EmpireCarVelocity") and curVehicle:FindFirstChild("EmpireCarGyro") then
                        curVehicle.EmpireCarGyro.cframe = Camera.CFrame
                        local moveVector = Vector3.new(0, 0, 0)
                        
                        if UserInputService:IsKeyDown(Enum.KeyCode.Z) then moveVector = moveVector + Camera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - Camera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector - Camera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Camera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
                        
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.MoveDirection.Magnitude > 0 then
                            moveVector = moveVector + hum.MoveDirection
                        end
                        
                        moveVector = moveVector + GetMobileVertical()
                        
                        curVehicle.EmpireCarVelocity.velocity = moveVector * getgenv().CarFlySpeed
                    else
                        break
                    end
                end
            end)
        end
    else
        FlySessionToken = FlySessionToken + 1
        if MobileUI then MobileUI:Destroy(); MobileUI = nil end
        if vehicle then
            local gyro = vehicle:FindFirstChild("EmpireCarGyro")
            local vel = vehicle:FindFirstChild("EmpireCarVelocity")
            if gyro then gyro:Destroy() end
            if vel then vel:Destroy() end
        end
    end
end)

CarSection:NewToggle("Safe Fly ?", "Active une stabilisation avancée anti-crash", function(state)
    local vehicle, seat = GetCurrentVehicle()
    if vehicle and vehicle.Parent then
        for _, part in pairs(vehicle.Parent:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not state
            end
        end
    end
end)

CarSection:NewSlider("Car Fly Speed", "Vitesse de vol", 10, 250, function(value)
    getgenv().CarFlySpeed = value
end)

CarSection:NewToggle("Vehicle Fling ?", "Fait tourner et propulse instantanément le véhicule", function(state)
    getgenv().VehicleFling = state
    if state then
        if FlingConnection then FlingConnection:Disconnect() end
        FlingConnection = RunService.Heartbeat:Connect(function()
            local vehicle, seat = GetCurrentVehicle()
            if vehicle and getgenv().VehicleFling then
                vehicle.RotVelocity = Vector3.new(0, 99999, 0)
            end
        end)
    else
        if FlingConnection then 
            FlingConnection:Disconnect() 
            FlingConnection = nil
        end
        local vehicle = GetCurrentVehicle()
        if vehicle then vehicle.RotVelocity = Vector3.new(0, 0, 0) end
    end
end)

-- ==========================================
-- 🏃 MOUVEMENTS JOUEUR
-- ==========================================
local MainSection = MainTab:NewSection("Options de Déplacement")

MainSection:NewSlider("WalkSpeed Forcé", "Modifier la vitesse", 16, 150, function(value)
    getgenv().InfVitesse = value
end)

RunService.PostSimulation:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed ~= getgenv().InfVitesse then
        if not hum.SeatPart then
            hum.WalkSpeed = getgenv().InfVitesse
        end
    end
end)

MainSection:NewSlider("JumpPower Forcé", "Sauter plus haut", 50, 200, function(value)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then 
        hum.UseJumpPower = true
        hum.JumpPower = value 
    end
end)

-- ==========================================
-- ⚔️ COMBAT (HITBOX & AIMBOT)
-- ==========================================
local CombatSection = CombatTab:NewSection("Assistance de Combat")

CombatSection:NewToggle("Grandes Hitbox", "Agrandit la tête des cibles", function(state)
    getgenv().HitBox = state
    if not state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    head.Size = Vector3.new(2, 2, 2)
                    head.Transparency = 0
                end
            end
        end
    end
end)

CombatSection:NewSlider("Taille Hitbox", "Rayon de la tête", 2, 20, function(value)
    getgenv().HitboxTaille = value
end)

task.spawn(function()
    while true do
        task.wait(0.8)
        if getgenv().HitBox then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    if head and head.Size.X ~= getgenv().HitboxTaille then
                        head.Size = Vector3.new(getgenv().HitboxTaille, getgenv().HitboxTaille, getgenv().HitboxTaille)
                        head.Transparency = 0.4
                        head.CanCollide = true
                    end
                end
            end
        end
    end
end)

CombatSection:NewToggle("Silent Aim / Aimbot", "Verrouille la visée (Clic Droit)", function(state)
    getgenv().Aimbot = state
end)

RunService.RenderStepped:Connect(function()
    if getgenv().Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local closest = nil
        local shortDist = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local mouse = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if dist < shortDist then closest = p; shortDist = dist end
                end
            end
        end
        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position), 0.15)
        end
    end
end)

-- ==========================================
-- 👀 VISUALS (ESP SANS FUITES DE MÉMOIRE)
-- ==========================================
local VisualsSection = VisualsTab:NewSection("Vision de l'Empire")

local function ApplyBillboard(p, character)
    if not character then return end
    local head = character:WaitForChild("Head", 5)
    if head and not head:FindFirstChild("EmpireESP") then
        local B = Instance.new("BillboardGui")
        B.Name = "EmpireESP"
        B.Size = UDim2.new(4,0,2,0)
        B.AlwaysOnTop = true
        B.Parent = head
        
        local T = Instance.new("TextLabel")
        T.Size = UDim2.new(1,0,1,0)
        T.Text = p.Name
        T.TextColor3 = Color3.fromRGB(255, 0, 0)
        T.BackgroundTransparency = 1
        T.TextSize = 14
        T.Parent = B
    end
end

local function CreateESP(p)
    if p == LocalPlayer then return end
    
    CharacterConnections[p] = p.CharacterAdded:Connect(function(char)
        if getgenv().ESP then
            ApplyBillboard(p, char)
        end
    end)
    
    if p.Character then
        ApplyBillboard(p, p.Character)
    end
end

local function RemoveESP(p)
    if CharacterConnections[p] then
        CharacterConnections[p]:Disconnect()
        CharacterConnections[p] = nil
    end
    if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("EmpireESP") then
        p.Character.Head.EmpireESP:Destroy()
    end
end

VisualsSection:NewToggle("ESP Joueurs Complet", "Affiche la position des ennemis", function(state)
    getgenv().ESP = state
    if state then
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
        ESPConnections["PlayerAdded"] = Players.PlayerAdded:Connect(CreateESP)
        ESPConnections["PlayerRemoving"] = Players.PlayerRemoving:Connect(RemoveESP)
    else
        if ESPConnections["PlayerAdded"] then ESPConnections["PlayerAdded"]:Disconnect() end
        if ESPConnections["PlayerRemoving"] then ESPConnections["PlayerRemoving"]:Disconnect() end
        ESPConnections = {}
        
        for _, p in pairs(Players:GetPlayers()) do
            RemoveESP(p)
        end
    end
end)
