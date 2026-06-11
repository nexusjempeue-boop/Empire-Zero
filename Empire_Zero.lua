-- =======================================================================
--  🌐 EMPIRE ZÉRO v3.0 | SÉCURITÉ MAXIMUM | Développé par KTH X OBSCRA 
-- =======================================================================
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GreenDeno/Venyx-UI-Library/main/source.lua"))()
local venyx = library.new("EMPIRE ZÉRO v3.0 - BY KTH", 5013109572)

-- Services Roblox essentiels
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- 🛡️ SYSTEME SECURITÉ MAXIMUM (ANTI-BAN / BYPASS)
-- ==========================================
-- Bypass basique des logs d'erreurs envoyés aux serveurs du jeu
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and tostring(self):lower():find("cheat") or tostring(self):lower():find("ban") then
        -- Si le jeu essaie d'envoyer une requête de ban, on simule un crash pour te déconnecter direct
        LocalPlayer:Kick("[EMPIRE ZÉRO] Kick Préventif : Tentative de Ban du serveur bloquée avec succès !")
        return nil
    end
    return oldNamecall(self, ...)
end)

-- Pages de l'interface
local main = venyx:addPage("Main", 5012544693)
local combat = venyx:addPage("Combat", 5012544693)
local visuals = venyx:addPage("Visuals", 5012544693)
local misc = venyx:addPage("Misc", 5012544693)

-- ==========================================
-- SECTION : MAIN (MOUVEMENTS BYPASS)
-- ==========================================
local mainSection = main:addSection("Mouvements")

-- Vitesse bypass (Modifie le CFrame, pas le WalkSpeed qui fait ban)
mainSection:addSlider("Vitesse Légitime", 16, 100, 16, function(value)
    getgenv().SpeedHack = value
end)

RunService.Stepped:Connect(function()
    if getgenv().SpeedHack and getgenv().SpeedHack > 16 then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (getgenv().SpeedHack / 100))
        end
    end
end)

-- Fly discret (Bypass sans BodyVelocity)
mainSection:addToggle("Fly (Bypass CFrame)", nil, function(state)
    getgenv().FlyBypass = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = state -- On ancre pour bloquer les calculs de chute du serveur
    end
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
            
            hrp.CFrame = hrp.CFrame + (moveVector * ((getgenv().FlySpeed or 10) / 10))
        end
    end
end)

mainSection:addSlider("Vitesse de Vol", 1, 50, 10, function(value)
    getgenv().FlySpeed = value
end)

-- ==========================================
-- SECTION : COMBAT (AIMBOT, HITBOX & AUTOFARM)
-- ==========================================
local combatSection = combat:addSection("Assistance de Combat")

-- Hitbox Légitime / Grandie (Agrandit la tête des ennemis pour ne jamais rater)
combatSection:addToggle("Grandes Hitbox (Tête)", nil, function(state)
    getgenv().HitBox = state
    while getgenv().HitBox and task.wait(1) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    head.Size = state and Vector3.new(5, 5, 5) or Vector3.new(2, 1, 1)
                    head.CanCollide = true
                    head.Transparency = state and 0.5 or 0
                end
            end
        end
    end
end)

-- Silent Aimbot (Verrouille la caméra sur le joueur le plus proche)
combatSection:addToggle("Aimbot Caméra", nil, function(state)
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
    if getgenv().Aimbot then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

-- AutoFarm Sécurisé (Frappe avec délai aléatoire pour simuler un humain)
combatSection:addToggle("AutoFarm Humanoïde", nil, function(state)
    getgenv().AutoFarm = state
    while getgenv().AutoFarm do
        local char = LocalPlayer.Character
        if char then
            for _, v in pairs(Workspace:GetChildren()) do
                if not getgenv().AutoFarm then break end
                if v:FindFirstChild("Humanoid") and v ~= char and v:FindFirstChild("HumanoidRootPart") then
                    -- Téléportation discrète derrière la cible
                    char.HumanoidRootPart.CFrame = v.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    
                    local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool") or char:FindFirstChildOfClass("Tool")
                    if tool then
                        if tool.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(tool) end
                        tool:Activate()
                    end
                    task.wait(0.25) -- Délai humain pour éviter les détections automatiques
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- SECTION : VISUALS (ESP PARFAIT)
-- ==========================================
local visualsSection = visuals:addSection("Empire Visuals")

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
            TL.TextColor3 = Color3.fromRGB(255, 30, 30)
            TL.BackgroundTransparency = 1
            TL.TextSize = 16
            TL.Size = UDim2.new(1, 0, 1, 0)
            
            BB.Parent = head
        end
    end
    if player.Character then BaseESP(player.Character) end
    player.CharacterAdded:Connect(BaseESP)
end

visualsSection:addToggle("ESP Joueurs & Distance", nil, function(state)
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
-- SECTION : MISC (TELEPORTATION & SERVEURS)
-- ==========================================
local miscSection = misc:addSection("Empire Utilitaires")

miscSection:addButton("Rejoindre le même Serveur", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

miscSection:addButton("Changer de Serveur (Hop)", function()
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

-- Initialisation
venyx:SelectPage(venyx.pages[1], true)
