--[[
    ⚓ SAILOR PIECE HUB ⚓
    Version: 2.0
    - Fixed Auto Farm (correct remotes)
    - Fixed Kill Aura
    - Fixed Haki (Armament, Observation, Conqueror)
    - Fixed Auto Stats
    - Fixed Boss Farm
    - Added 1-Hour Key Timer
]]

-- ========================
-- SERVICES
-- ========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========================
-- REMOTE REFERENCES
-- ========================
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local CombatRemotes = ReplicatedStorage:WaitForChild("CombatSystem", 10) and ReplicatedStorage.CombatSystem:WaitForChild("Remotes", 10)
local MainRemotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function GetRemote(parent, name)
    if not parent then return nil end
    return parent:FindFirstChild(name)
end

-- Combat
local RequestHit        = GetRemote(CombatRemotes, "RequestHit")
local CombatRemote      = GetRemote(Remotes, "CombatRemote")
local KatanaCombat      = GetRemote(Remotes, "KatanaCombatRemote")

-- Haki
local HakiRemote        = GetRemote(Remotes, "HakiRemote")
local ObsHakiRemote     = GetRemote(Remotes, "ObservationHakiRemote")
local ConqHakiRemote    = GetRemote(Remotes, "ConquerorHakiRemote")
local ConqHakiRemote2   = GetRemote(MainRemotes, "ConquerorHakiRemote")

-- Stats
local AllocateStat      = GetRemote(Remotes, "AllocateStat")
local AllocateStats2    = GetRemote(MainRemotes, "AllocateStats")

-- Boss
local RequestBoss       = GetRemote(MainRemotes, "RequestSummonBoss")
local RequestAutoSpawn  = GetRemote(MainRemotes, "RequestAutoSpawn")
local RequestStrongest  = GetRemote(MainRemotes, "RequestSpawnStrongestBoss")
local AutoSpawnStrongest = GetRemote(MainRemotes, "RequestAutoSpawnStrongest")

-- Dungeon
local RequestDungeon    = GetRemote(MainRemotes, "RequestDungeonPortal")
local JoinDungeon       = GetRemote(MainRemotes, "JoinDungeonPortal")

-- ========================
-- KEY SYSTEM CONFIG
-- ========================
local ValidKeys = {
    "SAILORPIECE-FREE-2024",
    "SAILORPIECE-VIP-001",
    "SP-ADMIN-KEY",
}

local KEY_DURATION = 60 * 60 -- 1 hour in seconds
local keyExpireTime = nil
local keyAccepted = false

local function CheckKey(input)
    for _, key in pairs(ValidKeys) do
        if input == key then return true end
    end
    return false
end

local function IsKeyValid()
    if not keyAccepted then return false end
    if keyExpireTime and tick() > keyExpireTime then
        keyAccepted = false
        return false
    end
    return true
end

-- ========================
-- TOGGLES
-- ========================
local Toggles = {
    AutoFarmMobs      = false,
    AutoFarmBosses    = false,
    AutoFarmWorldBoss = false,
    KillAura          = false,
    AutoHaki          = false,
    AutoObsHaki       = false,
    AutoConqHaki      = false,
    AutoStats         = false,
    AutoDungeon       = false,
    ESPPlayers        = false,
    InfiniteJump      = false,
    SpeedHack         = false,
}

-- ========================
-- UTILITY
-- ========================
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetNearestMob(maxDist, nameFilter)
    local nearest, nearestDist = nil, maxDist or 150
    local root = GetRootPart()
    if not root then return nil end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= GetCharacter() then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local mobRoot = obj:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and mobRoot then
                if not nameFilter or obj.Name:lower():find(nameFilter:lower()) then
                    local dist = (mobRoot.Position - root.Position).Magnitude
                    if dist < nearestDist then
                        nearest = obj
                        nearestDist = dist
                    end
                end
            end
        end
    end
    return nearest
end

local function TeleportTo(pos)
    local root = GetRootPart()
    if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end

-- ========================
-- COMBAT LOOP
-- ========================
local lastAttack = 0

RunService.Heartbeat:Connect(function()
    if not IsKeyValid() then return end
    local root = GetRootPart()
    if not root then return end

    -- Auto Farm Mobs / Kill Aura
    if Toggles.AutoFarmMobs or Toggles.KillAura then
        local mob = GetNearestMob(60)
        if mob then
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobRoot then
                -- Teleport next to mob
                root.CFrame = CFrame.new(mobRoot.Position + Vector3.new(0, 0, 3.5))
                -- Fire attack remote with correct args
                if tick() - lastAttack > 0.15 then
                    lastAttack = tick()
                    if RequestHit then
                        RequestHit:FireServer(mob, mobRoot.Position)
                    end
                    if CombatRemote then
                        CombatRemote:FireServer("Attack", mob)
                    end
                end
            end
        end
    end

    -- Auto Haki (Armament)
    if Toggles.AutoHaki then
        if HakiRemote then
            HakiRemote:FireServer("Activate")
        end
    end

    -- Auto Observation Haki
    if Toggles.AutoObsHaki then
        if ObsHakiRemote then
            ObsHakiRemote:FireServer("Activate")
        end
    end

    -- Auto Stats (fires slowly to avoid spam kicks)
    if Toggles.AutoStats and tick() % 1 < 0.05 then
        if AllocateStat then
            AllocateStat:FireServer("Strength", 1)
            AllocateStat:FireServer("Defense", 1)
            AllocateStat:FireServer("Speed", 1)
        end
        if AllocateStats2 then
            AllocateStats2:FireServer({Strength = 1, Defense = 1, Speed = 1})
        end
    end
end)

-- Auto Farm Bosses loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if not IsKeyValid() then task.wait(1) continue end
        if Toggles.AutoFarmBosses then
            -- Find boss in workspace
            local boss = GetNearestMob(500, "Boss")
            if boss then
                local bossRoot = boss:FindFirstChild("HumanoidRootPart")
                if bossRoot then
                    TeleportTo(bossRoot.Position)
                    if RequestHit then RequestHit:FireServer(boss, bossRoot.Position) end
                    if CombatRemote then CombatRemote:FireServer("Attack", boss) end
                end
            else
                -- No boss found, try to request auto spawn
                if RequestAutoSpawn then RequestAutoSpawn:FireServer() end
            end
        end

        if Toggles.AutoFarmWorldBoss then
            local boss = GetNearestMob(1000, "Anos") or GetNearestMob(1000, "Rimuru") or GetNearestMob(1000, "Strongest")
            if boss then
                local bossRoot = boss:FindFirstChild("HumanoidRootPart")
                if bossRoot then
                    TeleportTo(bossRoot.Position)
                    if RequestHit then RequestHit:FireServer(boss, bossRoot.Position) end
                end
            else
                if AutoSpawnStrongest then AutoSpawnStrongest:FireServer() end
                if RequestStrongest then RequestStrongest:FireServer() end
            end
        end

        if Toggles.AutoDungeon then
            if RequestDungeon then RequestDungeon:FireServer() end
            if JoinDungeon then JoinDungeon:FireServer() end
        end

        if Toggles.AutoConqHaki then
            if ConqHakiRemote then ConqHakiRemote:FireServer("Activate") end
            if ConqHakiRemote2 then ConqHakiRemote2:FireServer("Activate") end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Toggles.InfiniteJump and IsKeyValid() then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Speed Hack
RunService.RenderStepped:Connect(function()
    if not IsKeyValid() then return end
    local hum = GetHumanoid()
    if not hum then return end
    if Toggles.SpeedHack then
        hum.WalkSpeed = 80
    elseif hum.WalkSpeed == 80 then
        hum.WalkSpeed = 16
    end
end)

-- ========================
-- ESP
-- ========================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "SPHub_ESP"
ESPFolder.Parent = workspace

local function AddESP(player)
    if player == LocalPlayer then return end
    local function makeTag()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if ESPFolder:FindFirstChild("ESP_"..player.Name) then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "ESP_"..player.Name
        bb.Adornee = root
        bb.Size = UDim2.new(0, 120, 0, 36)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = ESPFolder
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "👤 "..player.Name
        lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        lbl.TextStrokeTransparency = 0
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = bb
    end
    player.CharacterAdded:Connect(makeTag)
    if player.Character then makeTag() end
end

local function ToggleESP(state)
    if state then
        for _, p in pairs(Players:GetPlayers()) do AddESP(p) end
        Players.PlayerAdded:Connect(function(p) if Toggles.ESPPlayers then AddESP(p) end end)
    else
        ESPFolder:ClearAllChildren()
    end
end

-- ========================
-- GUI BUILD
-- ========================
if PlayerGui:FindFirstChild("SailorPieceHub") then
    PlayerGui.SailorPieceHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SailorPieceHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- ========================
-- MAIN FRAME (hidden until key accepted)
-- ========================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 400)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚓ Sailor Piece Hub v2.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Key timer display in title bar
local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(0, 120, 1, 0)
TimerLabel.Position = UDim2.new(1, -200, 0, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Key: 1:00:00"
TimerLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
TimerLabel.TextSize = 12
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.Parent = TitleBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -65, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.TextSize = 13
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -33, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local minimized = false
local hiddenOnMin = {}

local function AddHideOnMin(f) table.insert(hiddenOnMin, f) end

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, f in pairs(hiddenOnMin) do f.Visible = not minimized end
    MainFrame.Size = minimized and UDim2.new(0, 560, 0, 45) or UDim2.new(0, 560, 0, 400)
    MinBtn.Text = minimized and "▢" or "—"
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -50)
Sidebar.Position = UDim2.new(0, 5, 0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
AddHideOnMin(Sidebar)

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = Sidebar

local SidebarPad = Instance.new("UIPadding")
SidebarPad.PaddingTop = UDim.new(0, 6)
SidebarPad.PaddingLeft = UDim.new(0, 5)
SidebarPad.PaddingRight = UDim.new(0, 5)
SidebarPad.Parent = Sidebar

-- Content Area
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Size = UDim2.new(1, -155, 1, -55)
ContentArea.Position = UDim2.new(0, 150, 0, 50)
ContentArea.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 4
ContentArea.ScrollBarImageColor3 = Color3.fromRGB(100, 180, 255)
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = MainFrame
Instance.new("UICorner", ContentArea).CornerRadius = UDim.new(0, 10)
AddHideOnMin(ContentArea)

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = ContentArea

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 8)
ContentPad.PaddingLeft = UDim.new(0, 8)
ContentPad.PaddingRight = UDim.new(0, 8)
ContentPad.Parent = ContentArea

-- ========================
-- GUI HELPERS
-- ========================
local function CreateToggle(parent, label, toggleKey, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 42)
    Row.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
    Row.BorderSizePixel = 0
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -60, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    Lbl.TextSize = 13
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.TextWrapped = true
    Lbl.Parent = Row

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 44, 0, 24)
    Toggle.Position = UDim2.new(1, -52, 0.5, -12)
    Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    Toggle.Text = ""
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Row
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 12)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    Knob.BorderSizePixel = 0
    Knob.Parent = Toggle
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local on = false
    Toggle.MouseButton1Click:Connect(function()
        on = not on
        if toggleKey then Toggles[toggleKey] = on end
        TweenService:Create(Toggle, TweenInfo.new(0.18), {
            BackgroundColor3 = on and Color3.fromRGB(60, 200, 90) or Color3.fromRGB(50, 50, 70)
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        }):Play()
        if callback then callback(on) end
    end)
    return Row
end

local function CreateButton(parent, label, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundColor3 = color or Color3.fromRGB(50, 100, 200)
    Btn.Text = label
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 13
    Btn.Font = Enum.Font.GothamBold
    Btn.BorderSizePixel = 0
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    local orig = Btn.BackgroundColor3
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(
            math.min(orig.R*255+30, 255),
            math.min(orig.G*255+30, 255),
            math.min(orig.B*255+30, 255)
        )}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = orig}):Play()
    end)
    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    return Btn
end

local function CreateSection(parent, text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 26)
    f.BackgroundTransparency = 1
    f.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. text
    lbl.TextColor3 = Color3.fromRGB(100, 180, 255)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
end

local function CreateDivider(parent)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    f.BorderSizePixel = 0
    f.Parent = parent
end

-- ========================
-- TABS
-- ========================
local Tabs = {}
local ActiveTab = nil

local TabDefs = {
    { Name = "⚔️ Farm",      Key = "Farm"     },
    { Name = "👊 Combat",    Key = "Combat"   },
    { Name = "🌀 Haki",      Key = "Haki"     },
    { Name = "🗺️ Teleport", Key = "Teleport" },
    { Name = "👁️ ESP",      Key = "ESP"      },
    { Name = "⚙️ Misc",     Key = "Misc"     },
}

local function ClearContent()
    for _, c in pairs(ContentArea:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
end

local function SetTab(key)
    ActiveTab = key
    for k, btn in pairs(Tabs) do
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (k == key) and Color3.fromRGB(50, 100, 200) or Color3.fromRGB(22, 22, 38)
        }):Play()
    end
    ClearContent()

    -- ─── FARM TAB ───
    if key == "Farm" then
        CreateSection(ContentArea, "MOB FARMING")
        CreateToggle(ContentArea, "Auto Farm Mobs", "AutoFarmMobs")
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "BOSS FARMING")
        CreateToggle(ContentArea, "Auto Farm Bosses", "AutoFarmBosses")
        CreateToggle(ContentArea, "Auto Farm World Bosses (Anos/Rimuru/Strongest)", "AutoFarmWorldBoss")
        CreateButton(ContentArea, "Spawn Boss Now", Color3.fromRGB(160, 60, 60), function()
            if RequestBoss then RequestBoss:FireServer() end
        end)
        CreateButton(ContentArea, "Spawn Strongest Boss Now", Color3.fromRGB(120, 40, 140), function()
            if RequestStrongest then RequestStrongest:FireServer() end
        end)
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "DUNGEON")
        CreateToggle(ContentArea, "Auto Dungeon", "AutoDungeon")
        CreateButton(ContentArea, "Join Dungeon Now", Color3.fromRGB(50, 120, 160), function()
            if RequestDungeon then RequestDungeon:FireServer() end
            if JoinDungeon then JoinDungeon:FireServer() end
        end)
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "STATS")
        CreateToggle(ContentArea, "Auto Distribute Stats", "AutoStats")
        CreateButton(ContentArea, "Dump All Stats (Strength/Defense/Speed)", Color3.fromRGB(50, 140, 80), function()
            for i = 1, 99 do
                if AllocateStat then
                    AllocateStat:FireServer("Strength", 1)
                    AllocateStat:FireServer("Defense", 1)
                    AllocateStat:FireServer("Speed", 1)
                end
            end
        end)

    -- ─── COMBAT TAB ───
    elseif key == "Combat" then
        CreateSection(ContentArea, "AURA")
        CreateToggle(ContentArea, "Kill Aura (Auto Attack Nearest Mob)", "KillAura")
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "MOVEMENT")
        CreateToggle(ContentArea, "Speed Hack (WalkSpeed 80)", "SpeedHack")
        CreateToggle(ContentArea, "Infinite Jump", "InfiniteJump")
        CreateButton(ContentArea, "Reset Speed to Normal", Color3.fromRGB(80, 80, 100), function()
            Toggles.SpeedHack = false
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end)

    -- ─── HAKI TAB ───
    elseif key == "Haki" then
        CreateSection(ContentArea, "ARMAMENT HAKI")
        CreateToggle(ContentArea, "Auto Armament Haki", "AutoHaki")
        CreateButton(ContentArea, "Activate Armament Haki Now", Color3.fromRGB(30, 30, 100), function()
            if HakiRemote then HakiRemote:FireServer("Activate") end
        end)
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "OBSERVATION HAKI")
        CreateToggle(ContentArea, "Auto Observation Haki", "AutoObsHaki")
        CreateButton(ContentArea, "Activate Observation Haki Now", Color3.fromRGB(30, 80, 30), function()
            if ObsHakiRemote then ObsHakiRemote:FireServer("Activate") end
        end)
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "CONQUEROR HAKI")
        CreateToggle(ContentArea, "Auto Conqueror Haki", "AutoConqHaki")
        CreateButton(ContentArea, "Activate Conqueror Haki Now", Color3.fromRGB(100, 20, 20), function()
            if ConqHakiRemote then ConqHakiRemote:FireServer("Activate") end
            if ConqHakiRemote2 then ConqHakiRemote2:FireServer("Activate") end
        end)

    -- ─── TELEPORT TAB ───
    elseif key == "Teleport" then
        CreateSection(ContentArea, "ISLANDS")
        local islands = {
            {"🏝️ Starter Island",   Vector3.new(0, 5, 0)},
            {"⚓ Marine Island",     Vector3.new(500, 5, 200)},
            {"🏴‍☠️ Pirate Island", Vector3.new(-500, 5, 300)},
            {"🌵 Desert Island",    Vector3.new(1000, 5, 0)},
            {"☁️ Sky Island",       Vector3.new(0, 500, 1000)},
            {"🧊 Ice Island",       Vector3.new(-1000, 5, -500)},
            {"⚔️ Dungeon Entrance", Vector3.new(200, 5, 400)},
        }
        for _, isl in pairs(islands) do
            CreateButton(ContentArea, isl[1], Color3.fromRGB(40, 80, 160), function()
                TeleportTo(isl[2])
            end)
        end
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "FIND IN-GAME")
        CreateButton(ContentArea, "Teleport to Nearest Boss", Color3.fromRGB(140, 40, 40), function()
            local boss = GetNearestMob(2000, "Boss") or GetNearestMob(2000, "Anos") or GetNearestMob(2000, "Rimuru")
            if boss then
                local r = boss:FindFirstChild("HumanoidRootPart")
                if r then TeleportTo(r.Position) end
            end
        end)
        CreateButton(ContentArea, "Teleport to Nearest NPC", Color3.fromRGB(60, 120, 60), function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= GetCharacter() then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local r = obj:FindFirstChild("HumanoidRootPart")
                    if hum and r and hum.MaxHealth == math.huge then
                        TeleportTo(r.Position) return
                    end
                end
            end
        end)

    -- ─── ESP TAB ───
    elseif key == "ESP" then
        CreateSection(ContentArea, "PLAYERS")
        CreateToggle(ContentArea, "Player ESP (Name Tags)", "ESPPlayers", function(on)
            ToggleESP(on)
        end)
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "MOBS")
        CreateButton(ContentArea, "Highlight All Mobs", Color3.fromRGB(160, 60, 60), function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= GetCharacter() then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and not obj:FindFirstChildOfClass("SelectionBox") then
                        local sb = Instance.new("SelectionBox")
                        sb.Adornee = obj
                        sb.Color3 = Color3.fromRGB(255, 60, 60)
                        sb.LineThickness = 0.04
                        sb.Parent = obj
                    end
                end
            end
        end)
        CreateButton(ContentArea, "Clear All Highlights", Color3.fromRGB(60, 60, 80), function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("SelectionBox") then obj:Destroy() end
            end
            ESPFolder:ClearAllChildren()
        end)

    -- ─── MISC TAB ───
    elseif key == "Misc" then
        CreateSection(ContentArea, "GAME")
        CreateButton(ContentArea, "Rejoin Server", Color3.fromRGB(60, 60, 100), function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        end)
        CreateButton(ContentArea, "FPS Boost (Disable Shadows)", Color3.fromRGB(60, 100, 60), function()
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").FogEnd = 9e9
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                end
            end
        end)
        CreateButton(ContentArea, "Reset All Toggles OFF", Color3.fromRGB(120, 50, 50), function()
            for k in pairs(Toggles) do Toggles[k] = false end
        end)
        CreateDivider(ContentArea)
        CreateSection(ContentArea, "KEY INFO")
        local keyInfoLbl = Instance.new("TextLabel")
        keyInfoLbl.Size = UDim2.new(1, 0, 0, 50)
        keyInfoLbl.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
        keyInfoLbl.TextColor3 = Color3.fromRGB(160, 200, 160)
        keyInfoLbl.TextSize = 12
        keyInfoLbl.Font = Enum.Font.Gotham
        keyInfoLbl.Text = "Your key expires 1 hour after entry.\nYou'll be prompted to re-enter when it expires."
        keyInfoLbl.TextWrapped = true
        keyInfoLbl.Parent = ContentArea
        Instance.new("UICorner", keyInfoLbl).CornerRadius = UDim.new(0, 8)
    end
end

-- Build sidebar tabs
for _, tab in pairs(TabDefs) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 36)
    Btn.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
    Btn.Text = tab.Name
    Btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    Btn.TextSize = 12
    Btn.Font = Enum.Font.Gotham
    Btn.BorderSizePixel = 0
    Btn.Parent = Sidebar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    Btn.MouseEnter:Connect(function()
        if ActiveTab ~= tab.Key then
            Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        end
    end)
    Btn.MouseLeave:Connect(function()
        if ActiveTab ~= tab.Key then
            Btn.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
        end
    end)
    Btn.MouseButton1Click:Connect(function() SetTab(tab.Key) end)
    Tabs[tab.Key] = Btn
end

-- ========================
-- KEY SYSTEM UI
-- ========================
local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.Size = UDim2.new(0, 420, 0, 310)
KeyFrame.Position = UDim2.new(0.5, -210, 0.5, -155)
KeyFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true
KeyFrame.Parent = ScreenGui
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 14)

-- Key frame top bar
local KFTop = Instance.new("Frame")
KFTop.Size = UDim2.new(1, 0, 0, 60)
KFTop.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
KFTop.BorderSizePixel = 0
KFTop.Parent = KeyFrame
Instance.new("UICorner", KFTop).CornerRadius = UDim.new(0, 14)

local KFTopFix = Instance.new("Frame")
KFTopFix.Size = UDim2.new(1, 0, 0.5, 0)
KFTopFix.Position = UDim2.new(0, 0, 0.5, 0)
KFTopFix.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
KFTopFix.BorderSizePixel = 0
KFTopFix.Parent = KFTop

local KFIcon = Instance.new("TextLabel")
KFIcon.Size = UDim2.new(1, 0, 0, 32)
KFIcon.Position = UDim2.new(0, 0, 0, 6)
KFIcon.BackgroundTransparency = 1
KFIcon.Text = "⚓ Sailor Piece Hub"
KFIcon.TextColor3 = Color3.fromRGB(100, 180, 255)
KFIcon.TextSize = 22
KFIcon.Font = Enum.Font.GothamBold
KFIcon.Parent = KFTop

local KFSub = Instance.new("TextLabel")
KFSub.Size = UDim2.new(1, 0, 0, 20)
KFSub.Position = UDim2.new(0, 0, 0, 38)
KFSub.BackgroundTransparency = 1
KFSub.Text = "v2.0 | Enter your key to continue"
KFSub.TextColor3 = Color3.fromRGB(120, 120, 150)
KFSub.TextSize = 12
KFSub.Font = Enum.Font.Gotham
KFSub.Parent = KFTop

local KFBox = Instance.new("TextBox")
KFBox.Size = UDim2.new(0, 340, 0, 46)
KFBox.Position = UDim2.new(0.5, -170, 0, 80)
KFBox.BackgroundColor3 = Color3.fromRGB(28, 28, 46)
KFBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KFBox.PlaceholderText = "Paste your key here..."
KFBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 110)
KFBox.Text = ""
KFBox.TextSize = 14
KFBox.Font = Enum.Font.Gotham
KFBox.BorderSizePixel = 0
KFBox.ClearTextOnFocus = false
KFBox.Parent = KeyFrame
Instance.new("UICorner", KFBox).CornerRadius = UDim.new(0, 8)

local KFSubmit = Instance.new("TextButton")
KFSubmit.Size = UDim2.new(0, 180, 0, 44)
KFSubmit.Position = UDim2.new(0.5, -90, 0, 142)
KFSubmit.BackgroundColor3 = Color3.fromRGB(50, 110, 200)
KFSubmit.Text = "Submit Key"
KFSubmit.TextColor3 = Color3.fromRGB(255, 255, 255)
KFSubmit.TextSize = 15
KFSubmit.Font = Enum.Font.GothamBold
KFSubmit.BorderSizePixel = 0
KFSubmit.Parent = KeyFrame
Instance.new("UICorner", KFSubmit).CornerRadius = UDim.new(0, 10)

local KFStatus = Instance.new("TextLabel")
KFStatus.Size = UDim2.new(1, 0, 0, 28)
KFStatus.Position = UDim2.new(0, 0, 0, 196)
KFStatus.BackgroundTransparency = 1
KFStatus.Text = ""
KFStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
KFStatus.TextSize = 13
KFStatus.Font = Enum.Font.Gotham
KFStatus.Parent = KeyFrame

local KFFreeNote = Instance.new("TextLabel")
KFFreeNote.Size = UDim2.new(1, -20, 0, 24)
KFFreeNote.Position = UDim2.new(0, 10, 0, 230)
KFFreeNote.BackgroundTransparency = 1
KFFreeNote.Text = "🔑 Free key: SAILORPIECE-FREE-2024"
KFFreeNote.TextColor3 = Color3.fromRGB(80, 200, 80)
KFFreeNote.TextSize = 12
KFFreeNote.Font = Enum.Font.Gotham
KFFreeNote.Parent = KeyFrame

local KFTimerNote = Instance.new("TextLabel")
KFTimerNote.Size = UDim2.new(1, -20, 0, 24)
KFTimerNote.Position = UDim2.new(0, 10, 0, 258)
KFTimerNote.BackgroundTransparency = 1
KFTimerNote.Text = "⏱️ Key is valid for 1 hour after entry"
KFTimerNote.TextColor3 = Color3.fromRGB(160, 160, 180)
KFTimerNote.TextSize = 11
KFTimerNote.Font = Enum.Font.Gotham
KFTimerNote.Parent = KeyFrame

-- ========================
-- KEY SUBMIT LOGIC
-- ========================
local function ShowKeyScreen()
    KeyFrame.Visible = true
    MainFrame.Visible = false
    -- Reset all toggles when key expires
    for k in pairs(Toggles) do Toggles[k] = false end
    KFBox.Text = ""
    KFStatus.Text = "⏰ Your key expired! Please re-enter."
    KFStatus.TextColor3 = Color3.fromRGB(255, 180, 50)
end

KFSubmit.MouseButton1Click:Connect(function()
    if CheckKey(KFBox.Text) then
        keyAccepted = true
        keyExpireTime = tick() + KEY_DURATION
        KFStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
        KFStatus.Text = "✔ Key accepted! Loading hub..."
        task.wait(0.8)
        KeyFrame.Visible = false
        MainFrame.Visible = true
        SetTab("Farm")
    else
        KFStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        KFStatus.Text = "✘ Invalid key. Try again."
        TweenService:Create(KeyFrame, TweenInfo.new(0.04, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 5, true), {
            Position = UDim2.new(0.5, -205, 0.5, -155)
        }):Play()
    end
end)

-- ========================
-- KEY TIMER COUNTDOWN
-- ========================
task.spawn(function()
    while true do
        task.wait(1)
        if keyAccepted and keyExpireTime then
            local remaining = keyExpireTime - tick()
            if remaining <= 0 then
                -- Key expired
                ShowKeyScreen()
                TimerLabel.Text = "Key: EXPIRED"
                TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            else
                local hours   = math.floor(remaining / 3600)
                local minutes = math.floor((remaining % 3600) / 60)
                local seconds = math.floor(remaining % 60)
                local timeStr = string.format("%d:%02d:%02d", hours, minutes, seconds)
                TimerLabel.Text = "Key: " .. timeStr
                -- Color changes as time runs low
                if remaining < 300 then
                    TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                elseif remaining < 600 then
                    TimerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
                else
                    TimerLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
                end
            end
        end
    end
end)

print("⚓ Sailor Piece Hub v2.0 loaded!")
