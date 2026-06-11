-- =======================================================================
-- 🌐 EMPIRE ZÉRO v6.1 | CAR MODS & PERFORMANCE UPDATE | REFAIT À NEUF
-- =======================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Tables de gestion pour éviter les fuites de mémoire (Memory Leaks)
local ESPConnections = {}
local CharacterConnections = {}
local FlySessionToken = 0 -- Jeton pour forcer le bon fonctionnement du Fly

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
local Window = Kavo.CreateLib("EMPIRE ZÉRO v6.1 - Stable", "DarkTheme")

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
            
            task.spawn(function()
                -- La boucle s'arrête proprement si on coupe l'option ou si on change de session
                while getgenv().CarFly and currentToken == FlySessionToken and task.wait() do
                    local curVehicle, curSeat = GetCurrentVehicle()
                    if curVehicle and curVehicle:FindFirstChild("EmpireCarVelocity") and curVehicle:FindFirstChild("EmpireCarGyro") then
                        curVehicle.EmpireCarGyro.cframe = Camera.CFrame
                        local moveVector = Vector3.new(0, 0, 0)
                        
                        -- Déplacements basés sur l'orientation de la caméra
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
        FlySessionToken = FlySessionToken + 1 -- Invalide instantanément l'ancienne boucle
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
        FlingConnection = RunService.Heartbeat:Connect(function()
            if getgenv().VehicleFling then
                local vehicle = GetCurrentVehicle()
                if vehicle then
                    vehicle.RotVelocity = Vector3.new(0, 5000, 0)
                end
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

-- Liaison native au cycle de rendu pour éviter les surcharges de calculs répétitifs
RunService.PostSimulation:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed ~= getgenv().InfVitesse then
        -- Évite de forcer la vitesse si le joueur est assis (évite les bugs de véhicules)
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
        task.wait(0.8) -- Fréquence optimisée pour réduire l'impact CPU tout en restant réactif
        if getgenv().HitBox then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    -- Applique le changement uniquement si la taille est différente (évite le stuttering graphique)
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
    
    -- Stockage propre de la connexion au cas où le joueur meurt / réapparaît
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
    -- Déconnexion stricte de l'événement lié au joueur pour libérer la RAM
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
        -- Nettoyage global sans laisser de traces résiduelles
        if ESPConnections["PlayerAdded"] then ESPConnections["PlayerAdded"]:Disconnect() end
        if ESPConnections["PlayerRemoving"] then ESPConnections["PlayerRemoving"]:Disconnect() end
        ESPConnections = {}
        
        for _, p in pairs(Players:GetPlayers()) do
            RemoveESP(p)
        end
    end
end)
