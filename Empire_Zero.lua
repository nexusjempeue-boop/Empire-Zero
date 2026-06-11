-- =======================================================================
-- 🌐 EMPIRE ZÉRO v6.2 | ULTIMATE STABILITY & FIX UPDATE | REFAIT À NEUF
-- =======================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Tables de gestion strictes (Garbage Collection garanti)
local ESPConnections = {}
local CharacterConnections = {}
local FlySessionToken = 0

-- 🛡️ PROTECTION / BYPASS SÉCURISÉ (Vérification stricte de la structure)
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
local Window = Kavo.CreateLib("EMPIRE ZÉRO v6.2 - Haute Stabilité", "DarkTheme")

-- Configuration Globale
getgenv().CarFlySpeed = 50
getgenv().InfVitesse = 16
getgenv().HitboxTaille = 2

-- Onglets
local MainTab = Window:NewTab("Mouvements")
local CombatTab = Window:NewTab("Combat")
local CarTab = Window:NewTab("Car Mods")
local VisualsTab = Window:NewTab("Visuals")

-- ==========================================
-- 🚗 CAR MODS
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

CarSection:NewToggle("Car Fly", "Permet de faire voler votre véhicule", function(state)
    getgenv().CarFly = state
    local vehicle, seat = GetCurrentVehicle()
    
    if state then
        FlySessionToken = FlySessionToken + 1
        local currentToken = FlySessionToken
        
        if vehicle and vehicle:IsDescendantOf(Workspace) then
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
            
            task.spawn(function()
                while getgenv().CarFly and currentToken == FlySessionToken and task.wait() do
                    local curVehicle, curSeat = GetCurrentVehicle()
                    if curVehicle and curVehicle:IsDescendantOf(Workspace) and curVehicle:FindFirstChild("EmpireCarVelocity") and curVehicle:FindFirstChild("EmpireCarGyro") then
                        curVehicle.EmpireCarGyro.cframe = Camera.CFrame
                        local moveVector = Vector3.new(0, 0, 0)
                        
                        if UserInputService:IsKeyDown(Enum.KeyCode.Z) then moveVector = moveVector + Camera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - Camera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector - Camera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Camera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
                        
                        curVehicle.EmpireCarVelocity.velocity = moveVector * getgenv().CarFlySpeed
                    else
                        break
                    end
                end
            end)
        end
    else
        FlySessionToken = FlySessionToken + 1 -- Invalide instantanément la boucle parallèle
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

local FlingConnection
CarSection:NewToggle("Vehicle Fling ?", "Propulse les véhicules au contact", function(state)
    getgenv().VehicleFling = state
    if state then
        if FlingConnection then FlingConnection:Disconnect() end
        FlingConnection = RunService.Heartbeat:Connect(function()
            if getgenv().VehicleFling then
                local vehicle = GetCurrentVehicle()
                if vehicle and vehicle:IsDescendantOf(Workspace) then
                    vehicle.RotVelocity = Vector3.new(0, 5000, 0)
                end
            end
        end)
    else
        if FlingConnection then 
            FlingConnection:Disconnect() 
            FlingConnection
