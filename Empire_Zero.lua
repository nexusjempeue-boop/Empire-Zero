-- =======================================================================
--  🌐 EMPIRE ZÉRO v6.0 | CAR MODS UPDATE | KTH X Obscra
--  🔗 Discord : discord.gg/empirezero
-- =======================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 🛡️ PROTECTION ANTI-BAN & BYPASS DE LOGS (KTH X Obscra Edition)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and (tostring(self):lower():find("cheat") or tostring(self):lower():find("ban") or tostring(self):lower():find("kick")) then
        return nil
    end
    return oldNamecall(self, ...)
end)

-- 🎨 LIBRAIRIE GRAPHIQUE BYPASS (Kavo UI)
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("EMPIRE ZÉRO v6.0 - discord.gg/empirezero", "DarkTheme")

-- Configuration Globale
getgenv().CarFlySpeed = 50
getgenv().InfVitesse = 16
getgenv().HitboxTaille = 2

-- Onglets du Menu (Inspiré de image_12a0f8.jpg)
local MainTab = Window:NewTab("Mouvements")
local CombatTab = Window:NewTab("Combat")
local CarTab = Window:NewTab("Car Mods")
local VisualsTab = Window:NewTab("Visuals")
local CreditsTab = Window:NewTab("Credits")

-- ==========================================
-- 🚗 ONGLET : CAR MODS (INSPIRÉ DE VORTEX)
-- ==========================================
local CarSection = CarTab:NewSection("Car Mod Options")

-- Fonction pour choper le véhicule actuel du joueur
local function GetCurrentVehicle()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if char.Humanoid.SeatPart and char.Humanoid.SeatPart:IsA("VehicleSeat") then
            return char.Humanoid.SeatPart.AssemblyRootPart, char.Humanoid.SeatPart
        end
    end
    return nil, nil
end

-- CAR FLY VRAIMENT DÉVELOPPÉ A FOND
CarSection:NewToggle("Car Fly", "Permet de faire voler votre véhicule", function(state)
    getgenv().CarFly = state
    local vehicle, seat = GetCurrentVehicle()
    
    if state and vehicle then
        -- Création des forces physiques stables pour faire voler la voiture
        local BG = Instance.new("BodyGyro")
        local BV = Instance.new("BodyVelocity")
        
        BG.Name = "EmpireCarGyro"
        BG.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
        BG.cframe = vehicle.CFrame
        BG.Parent = vehicle
        
        BV.Name = "EmpireCarVelocity"
        BV.maxForce = Vector3.new(math.huge, math.huge, math.huge)
        BV.velocity = Vector3.new(0, 0, 0)
        BV.Parent = vehicle
        
        task.spawn(function()
            while getgenv().CarFly and task.wait() do
                local curVehicle, curSeat = GetCurrentVehicle()
                if curVehicle and curVehicle:FindFirstChild("EmpireCarVelocity") and curVehicle:FindFirstChild("EmpireCarGyro") then
                    local vel = curVehicle.EmpireCarVelocity
                    local gyro = curVehicle.EmpireCarGyro
                    
                    gyro.cframe = Camera.CFrame
                    local moveVector = Vector3.new(0, 0, 0)
                    
                    -- Contréles ZQSD / Flèches
                    if UserInputService:IsKeyDown(Enum.KeyCode.Z) then moveVector = moveVector + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, -1, 0) end
                    
                    vel.velocity = moveVector * getgenv().CarFlySpeed
                else
                    break
                end
            end
        end)
    else
        -- Nettoyage si on coupe ou si on descend de la voiture
        if vehicle then
            if vehicle:FindFirstChild("EmpireCarVelocity") then vehicle.EmpireCarVelocity:Destroy() end
            if vehicle:FindFirstChild("EmpireCarGyro") then vehicle.EmpireCarGyro:Destroy() end
        end
    end
end)

-- SAFE FLY ? (Empêche la voiture de glisser ou de s'écraser au sol)
CarSection:NewToggle("Safe Fly ?", "Active une stabilisation avancée anti-crash", function(state)
    getgenv().SafeCarFly = state
    local vehicle = GetCurrentVehicle()
    if vehicle then
        vehicle.CanCollide = not state
    end
end)

-- CAR FLY SPEED SLIDER
CarSection:NewSlider("Car Fly Speed", "Ajuste la vitesse de vol de la voiture", 10, 250, function(value)
    getgenv().CarFlySpeed = value
end)

-- VEHICLE FLING ? (Fait partir en toupie et voler les autres voitures au contact)
CarSection:NewToggle("Vehicle Fling ?", "Propulse violemment les véhicules touchés", function(state)
    getgenv().VehicleFling = state
    RunService.Heartbeat:Connect(function()
        if getgenv().VehicleFling then
            local vehicle = GetCurrentVehicle()
            if vehicle then
                -- On applique une vitesse angulaire folle invisible pour propulser les autres au contact physique
                vehicle.RotVelocity = Vector3.new(0, 9999, 0)
            end
        end
    end)
end)


-- ==========================================
-- 🏃 ONGLET : MOUVEMENTS (JOUEUR)
-- ==========================================
local MainSection = MainTab:NewSection("Options de Déplacement")

-- Vitesse physique forcée (Fonctionne enfin à 100%)
MainSection:NewSlider("WalkSpeed Forcé", "Augmente directement ta vitesse", 16, 150, function(value)
    getgenv().InfVitesse = value
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = getgenv().InfVitesse
    end
end)

-- JumpPower Forcé
MainSection:NewSlider("JumpPower Forcé", "Saute beaucoup plus haut", 50, 200, function(value)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = value end
end)


-- ==========================================
-- ⚔️ ONGLET : COMBAT (AIMBOT & HITBOX)
-- ==========================================
local CombatSection = CombatTab:NewSection("Assistance de Combat")

CombatSection:NewToggle("Grandes Hitbox", "Agrandit la tête des cibles", function(state)
    getgenv().HitBox = state
end)

CombatSection:NewSlider("Taille Hitbox", "Définit le rayon de la tête", 2, 20, function(value)
    getgenv().HitboxTaille = value
end)

task.spawn(function()
    while task.wait(1) do
        if getgenv().HitBox then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
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

-- Logique Aimbot Proche
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
        if closest then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position), 0.2)
        end
    end
end)


-- ==========================================
-- 👀 ONGLET : VISUALS (ESP)
-- ==========================================
local VisualsSection = VisualsTab:NewSection("Vision de l'Empire")

VisualsSection:NewToggle("ESP Joueurs Complet", "Affiche la position des ennemis", function(state)
    getgenv().ESP = state
    if state then
        getgenv().EmpireConnection = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function(char)
                local head = char:WaitForChild("Head", 5)
                if head then
                    local B = Instance.new("BillboardGui", head)
                    B.Name = "EmpireESP"
                    B.Size = UDim2.new(4,0,2,0)
                    B.AlwaysOnTop = true
                    local T = Instance.new("TextLabel", B)
                    T.Size = UDim2.new(1,0,1,0)
                    T.Text = p.Name
                    T.TextColor3 = Color3.fromRGB(255, 0, 0)
                    T.BackgroundTransparency = 1
                end
            end)
        end)
    else
        if getgenv().EmpireConnection then getgenv().EmpireConnection:Disconnect() end
        for _, v in pairs(Players:GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("Head") and v.Character.Head:FindFirstChild("EmpireESP") then
                v.Character.Head.EmpireESP:Destroy()
            end
        end
    end
end)


-- ==========================================
-- 👥 ONGLET : CREDITS & DISCORD
-- ==========================================
local CreditsSection = CreditsTab:NewSection("Créateurs & Communauté")
CreditsSection:NewLabel("Développeurs principaux : KTH X Obscra")
CreditsSection:NewLabel("Propriété exclusive de : Empire Zéro")
CreditsSection:NewButton("Copier le lien Discord", "Copie l'invitation dans ton presse-papier", function()
    setclipboard("discord.gg/empirezero")
end)
