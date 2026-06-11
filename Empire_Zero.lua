-- =======================================================================
--  🌐 EMPIRE ZÉRO v5.0 | INTERFACE SÉCURISÉE | Développé par KTH
-- =======================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 🛡️ PROTECTION ANTI-BAN (Interception des signaux de report/kick/ban)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and (tostring(self):lower():find("cheat") or tostring(self):lower():find("ban") or tostring(self):lower():find("kick")) then
        -- On bloque silencieusement la tentative du jeu de te bannir ou de te kick
        return nil
    end
    return oldNamecall(self, ...)
end)

-- 🎨 CHARGEMENT DE L'INTERFACE (Kavo UI Library - Version Bypass)
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("EMPIRE ZÉRO v5.0 - BY KTH", "DarkTheme")

-- Configuration par défaut
getgenv().FlySpeed = 10
getgenv().HitboxTaille = 2

-- Onglets principaux
local MainTab = Window:NewTab("Mouvements")
local CombatTab = Window:NewTab("Combat")
local VisualsTab = Window:NewTab("Visuals")
local MiscTab = Window:NewTab("Configuration")

-- ==========================================
-- ONGLET : MOUVEMENTS (VITESSE & FLY)
-- ==========================================
local MainSection = MainTab:NewSection("Options de Déplacement")

MainSection:NewSlider("Vitesse Légitime", "Modifie ton déplacement de manière fluide", 16, 120, function(value)
    getgenv().SpeedHack = value
end)

RunService.Stepped:Connect(function()
    if getgenv().SpeedHack and getgenv().SpeedHack > 16 then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (getgenv().SpeedHack / 130))
        end
    end
end)

MainSection:NewToggle("Fly discret (CFrame)", "Voler sans déclencher les détections physiques", function(state)
    getgenv().FlyBypass = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = state
    end
end)

MainSection:NewSlider("Vitesse de Vol", "Ajuste la vitesse du Fly", 1, 30, function(value)
    getgenv().FlySpeed = value
end)

RunService.RenderStepped:Connect(function()
    if getgenv().FlyBypass then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local camCFrame = Camera.CFrame
            local moveVector = Vector3.new(0,0,0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.Z) then moveVector = moveVector + camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector - camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0,1,0) end
            
            hrp.CFrame = hrp.CFrame + (moveVector * (getgenv().FlySpeed / 10))
        end
    end
end)

-- ==========================================
-- ONGLET : COMBAT (AIMBOT & HITBOX)
-- ==========================================
local CombatSection = CombatTab:NewSection("Assistance de Visée")

CombatSection:NewToggle("Grandes Hitbox", "Agrandit légèrement la tête des adversaires", function(state)
    getgenv().HitBox = state
    if not state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                p.Character.Head.Size = Vector3.new(2, 1, 1)
                p.Character.Head.Transparency = 0
            end
        end
    end
end)

CombatSection:NewSlider("Taille de la Hitbox", "Définit la largeur de la zone d'impact", 2, 15, function(value)
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
                        head.CanCollide = true
                        head.Transparency = 0.5
                    end
                end
            end
        end
    end
end)

CombatSection:NewToggle("Aimbot (Maintenir Clic Droit)", "Verrouille la caméra de façon fluide", function(state)
    getgenv().Aimbot = state
end)

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    closestPlayer = p
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if getgenv().Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.2)
        end
    end
end)

-- ==========================================
-- ONGLET : VISUALS (ESP)
-- ==========================================
local VisualsSection = VisualsTab:NewSection("Vision à travers les structures")

local function CreateESP(player)
    if player == LocalPlayer then return end
    local function BaseESP(char)
        local head = char:WaitForChild("Head", 5)
        if head and not head:FindFirstChild("EmpireESP") then
            local BB = Instance.new("BillboardGui")
            BB.Name = "EmpireESP"
            BB.Size = UDim2.new(4, 0, 2, 0)
            BB.AlwaysOnTop = true
            
            local TL = Instance.new("TextLabel", BB)
            TL.Text = player.Name .. " [" .. math.round(player:DistanceFromCharacter(head.Position)) .. "m]"
            TL.TextColor3 = Color3.fromRGB(255, 255, 255)
            TL.BackgroundTransparency = 1
            TL.TextSize = 14
            TL.Size = UDim2.new(1, 0, 1, 0)
            
            BB.Parent = head
        end
    end
    if player.Character then BaseESP(player.Character) end
    player.CharacterAdded:Connect(BaseESP)
end

VisualsSection:NewToggle("ESP Joueurs & Distance", "Voir l'emplacement exact des joueurs", function(state)
    getgenv().ESP = state
    if state then
        for _, v in pairs(Players:GetPlayers()) do CreateESP(v) end
        getgenv().EmpirePlayerConnection = Players.PlayerAdded:Connect(CreateESP)
    else
        if getgenv().EmpirePlayerConnection then getgenv().EmpirePlayerConnection:Disconnect() end
        for _, v in pairs(Players:GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("Head") then
                local esp = v.Character.Head:FindFirstChild("EmpireESP")
                if esp then esp:Destroy() end
            end
        end
    end
end)

-- ==========================================
-- ONGLET : CONFIGURATION (MISC)
-- ==========================================
local MiscSection = MiscTab:NewSection("Gestion Serveur")

MiscSection:NewButton("Rejoindre le même Serveur", "Relance la session actuelle", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

MiscSection:NewButton("Changer de Serveur (Hop)", "Trouve une autre instance publique disponible", function()
    local Api = "https://games.roblox.com/v1/games/"
    local _place = game.PlaceId
    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
    
    local function ListServers(cursor)
        local success, raw = pcall(function() return game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or "")) end)
        if success then return HttpService:JSONDecode(raw) end
    end
    
    local Next;
    local Servers = ListServers(Next)
    if Servers and Servers.data then
        for _, server in pairs(Servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(_place, server.id, LocalPlayer)
                break
            end
        end
    end
end)
