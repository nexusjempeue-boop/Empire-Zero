-- =======================================================================
--  🌐 EMPIRE ZÉRO v2.0 | Développé par KTH
-- =======================================================================
print("--------------------------------------------------")
print("[EMPIRE ZÉRO] Initialisation par KTH...")
print("--------------------------------------------------")

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GreenDeno/Venyx-UI-Library/main/source.lua"))()
local venyx = library.new("EMPIRE ZÉRO v2.0", 5013109572)

-- Services Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Pages de l'interface
local main = venyx:addPage("Main", 5012544693)
local combat = venyx:addPage("Combat", 5012544693)
local visuals = venyx:addPage("Visuals", 5012544693)
local misc = venyx:addPage("Misc", 5012544693)

-- ==========================================
-- SECTION : MAIN (VOL)
-- ==========================================
local mainSection = main:addSection("Empire Main")
mainSection:addToggle("Fly", nil, function(state)
    getgenv().Fly = state
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 3)
    local hum = char:WaitForChild("Humanoid", 3)
    
    if not hrp or not hum then return end
    hum.PlatformStand = state
    
    if state then
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EmpireFly"
        BV.Velocity = Vector3.new(0, getgenv().FlySpeed or 10, 0)
        BV.MaxForce = Vector3.new(0, math.huge, 0)
        BV.Parent = hrp
    else
        local existingBV = hrp:FindFirstChild("EmpireFly")
        if existingBV then existingBV:Destroy() end
    end
end)

mainSection:addSlider("Fly Speed", 1, 100, 10, function(value)
    getgenv().FlySpeed = value
    if getgenv().Fly then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local BV = hrp and hrp:FindFirstChild("EmpireFly")
        if BV then
            BV.Velocity = Vector3.new(0, value, 0)
        end
    end
end)

-- ==========================================
-- SECTION : COMBAT (GODMODE & AUTOFARM)
-- ==========================================
local combatSection = combat:addSection("Empire Combat")
combatSection:addToggle("GodMode", nil, function(state)
    getgenv().GodMode = state
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        if state then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        else
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end)

combatSection:addToggle("AutoFarm", nil, function(state)
    getgenv().AutoFarm = state
    while getgenv().AutoFarm do
        local char = LocalPlayer.Character
        if char then
            for _, v in pairs(Workspace:GetChildren()) do
                if not getgenv().AutoFarm then break end
                if v:FindFirstChild("Humanoid") and v ~= char then
                    local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool") or char:FindFirstChildOfClass("Tool")
                    if tool then
                        if tool.Parent == LocalPlayer.Backpack then
                            char.Humanoid:EquipTool(tool)
                        end
                        tool:Activate()
                        task.wait(0.1) -- Anti-crash
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- SECTION : VISUALS (ESP)
-- ==========================================
local visualsSection = visuals:addSection("Empire Visuals")

local function CreateESP(player)
    if player == LocalPlayer then return end
    local function BaseESP(char)
        local head = char:WaitForChild("Head", 5)
        if head and not head:FindFirstChild("EmpireESP") then
            local BB = Instance.new("BillboardGui")
            BB.Name = "EmpireESP"
            BB.Size = UDim2.new(3, 0, 1.5, 0)
            BB.AlwaysOnTop = true
            
            local TL = Instance.new("TextLabel", BB)
            TL.Text = player.Name
            TL.TextColor3 = Color3.new(1, 0, 0) -- Rouge Empire
            TL.BackgroundTransparency = 1
            TL.TextSize = 18
            TL.Size = UDim2.new(1, 0, 1, 0)
            
            BB.Parent = head
        end
    end
    if player.Character then BaseESP(player.Character) end
    player.CharacterAdded:Connect(BaseESP)
end

visualsSection:addToggle("ESP", nil, function(state)
    getgenv().ESP = state
    if state then
        for _, v in pairs(Players:GetPlayers()) do
            CreateESP(v)
        end
        getgenv().EmpirePlayerConnection = Players.PlayerAdded:Connect(CreateESP)
    else
        if getgenv().EmpirePlayerConnection then 
            getgenv().EmpirePlayerConnection:Disconnect() 
        end
        for _, v in pairs(Players:GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("Head") then
                local esp = v.Character.Head:FindFirstChild("EmpireESP")
                if esp then esp:Destroy() end
            end
        end
    end
end)

-- ==========================================
-- SECTION : MISC (SERVEURS)
-- ==========================================
local miscSection = misc:addSection("Empire Misc")
miscSection:addButton("Rejoindre le même Serveur", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

miscSection:addButton("Changer de Serveur (Hop)", function()
    local Api = "https://games.roblox.com/v1/games/"
    local _place = game.PlaceId
    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
    
    local function ListServers(cursor)
        local success, raw = pcall(function()
            return game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
        end)
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
print("[EMPIRE ZÉRO] Chargé avec succès. Merci d'utiliser le script de KTH !")
print("--------------------------------------------------")
