local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("BGS_MalevolentCombo_GUI") then
    CoreGui.BGS_MalevolentCombo_GUI:Destroy()
end

_G.HalloweenFarmSession = (_G.HalloweenFarmSession or 0) + 1
local activeSession = _G.HalloweenFarmSession

local Settings = {
    FarmHouses = false,
    AutoHatch = false,
    SelectedEgg = "Malevolent Egg",
    HouseCooldown = 60,
    TotalPasses = 3
}

local EggList = {
    "Malevolent Egg",
    "Skull Egg",
    "Neon Pumpkin Egg"
}

-- Емуляція натискання клавіші T
local function pressTKey()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
end

-- Пошук платформи для будь-якого обраного яйця зі зміщенням НАЗАД (перед яйцем)
local function getEggPlatformCFrame(eggName)
    local eggsFolder = Workspace:FindFirstChild("Eggs")
    if eggsFolder then
        local targetEgg = eggsFolder:FindFirstChild(eggName)
        if targetEgg then
            -- 1. Якщо є деталь Hotkey (плитка перед яйцем)
            local hotkey = targetEgg:FindFirstChild("Hotkey")
            if hotkey and hotkey:IsA("BasePart") then
                -- Відступаємо на 3.5 studs назад від центру плити (перед стендом)
                return hotkey.CFrame + (hotkey.CFrame.LookVector * -3.5) + Vector3.new(0, 2.5, 0)
            end
            
            -- 2. Якщо Hotkey немає, беремо Primary або сам меш яйця
            local primary = targetEgg:FindFirstChild("Primary") or targetEgg:FindFirstChildWhichIsA("BasePart")
            if primary then
                -- Відступаємо на 6 studs перед яйцем
                return primary.CFrame + (primary.CFrame.LookVector * -6) + Vector3.new(0, 2.5, 0)
            end
        end
    end
    return nil
end

local function isHouseReady(house)
    for _, item in ipairs(house:GetDescendants()) do
        if item:IsA("TextLabel") or item:IsA("SurfaceGui") or item:IsA("BillboardGui") then
            local text = item:IsA("TextLabel") and item.Text or ""
            if text:find("%d%d:%d%d") or text:find("%d+s") then
                return false
            end
        end
    end
    return true
end

-- Створення GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BGS_MalevolentCombo_GUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 230, 0, 195)
Frame.Position = UDim2.new(0.05, 0, 0.35, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 20, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.ClipsDescendants = false
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(245, 120, 25)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 26)
Title.Position = UDim2.new(0, 10, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "🎃 Houses + Multi-Egg [T]"
Title.TextColor3 = Color3.fromRGB(255, 175, 60)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -24, 0, 4)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = Frame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

CloseBtn.MouseButton1Click:Connect(function()
    Settings.FarmHouses = false
    Settings.AutoHatch = false
    _G.HalloweenFarmSession = (_G.HalloweenFarmSession or 0) + 1
    ScreenGui:Destroy()
end)

-- Кнопка Будинки
local HouseBtn = Instance.new("TextButton")
HouseBtn.Size = UDim2.new(0.88, 0, 0, 30)
HouseBtn.Position = UDim2.new(0.06, 0, 0, 32)
HouseBtn.Text = "Будинки: OFF"
HouseBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 35)
HouseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HouseBtn.Font = Enum.Font.SourceSansBold
HouseBtn.TextSize = 13
HouseBtn.Parent = Frame
Instance.new("UICorner", HouseBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка Хатч
local HatchBtn = Instance.new("TextButton")
HatchBtn.Size = UDim2.new(0.88, 0, 0, 30)
HatchBtn.Position = UDim2.new(0.06, 0, 0, 66)
HatchBtn.Text = "Auto [T] Hatch: OFF"
HatchBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 35)
HatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HatchBtn.Font = Enum.Font.SourceSansBold
HatchBtn.TextSize = 13
HatchBtn.Parent = Frame
Instance.new("UICorner", HatchBtn).CornerRadius = UDim.new(0, 6)

-- Головна кнопка Dropdown
local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(0.88, 0, 0, 28)
DropdownBtn.Position = UDim2.new(0.06, 0, 0, 100)
DropdownBtn.Text = "🥚 " .. Settings.SelectedEgg .. " ▼"
DropdownBtn.BackgroundColor3 = Color3.fromRGB(42, 32, 30)
DropdownBtn.TextColor3 = Color3.fromRGB(255, 215, 120)
DropdownBtn.Font = Enum.Font.SourceSansBold
DropdownBtn.TextSize = 13
DropdownBtn.ZIndex = 5
DropdownBtn.Parent = Frame
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 5)

-- Контейнер для елементів списку
local DropdownList = Instance.new("Frame")
DropdownList.Size = UDim2.new(0.88, 0, 0, #EggList * 26)
DropdownList.Position = UDim2.new(0.06, 0, 0, 130)
DropdownList.BackgroundColor3 = Color3.fromRGB(32, 24, 22)
DropdownList.BorderSizePixel = 0
DropdownList.Visible = false
DropdownList.ZIndex = 10
DropdownList.Parent = Frame
Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 5)
local ListStroke = Instance.new("UIStroke", DropdownList)
ListStroke.Color = Color3.fromRGB(245, 120, 25)
ListStroke.Thickness = 1

local UIList = Instance.new("UIListLayout", DropdownList)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Статус
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 30)
Status.Position = UDim2.new(0.05, 0, 0, 158)
Status.BackgroundTransparency = 1
Status.Text = "Статус: Очікування"
Status.TextColor3 = Color3.fromRGB(190, 190, 190)
Status.TextSize = 12
Status.Font = Enum.Font.SourceSans
Status.Parent = Frame

-- Наповнення списку
for _, eggName in ipairs(EggList) do
    local ItemBtn = Instance.new("TextButton")
    ItemBtn.Size = UDim2.new(1, 0, 0, 26)
    ItemBtn.BackgroundTransparency = 1
    ItemBtn.Text = eggName
    ItemBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    ItemBtn.Font = Enum.Font.SourceSans
    ItemBtn.TextSize = 13
    ItemBtn.ZIndex = 11
    ItemBtn.Parent = DropdownList

    ItemBtn.MouseButton1Click:Connect(function()
        Settings.SelectedEgg = eggName
        DropdownBtn.Text = "🥚 " .. eggName .. " ▼"
        DropdownList.Visible = false
    end)
end

DropdownBtn.MouseButton1Click:Connect(function()
    DropdownList.Visible = not DropdownList.Visible
end)

local fixedDoorTargets = {}

local function startCoordinator()
    _G.HalloweenFarmSession = (_G.HalloweenFarmSession or 0) + 1
    activeSession = _G.HalloweenFarmSession
    local thisSession = activeSession

    task.spawn(function()
        local housesFolder = Workspace:WaitForChild("Houses", 5)
        local isHatchingActive = false

        while (Settings.FarmHouses or Settings.AutoHatch) and _G.HalloweenFarmSession == thisSession do
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = char:WaitForChild("HumanoidRootPart")
            local humanoid = char:WaitForChild("Humanoid")

            if isHatchingActive then
                pressTKey()
                isHatchingActive = false
                task.wait(0.2)
            end

            -- Обхід будинків
            if Settings.FarmHouses and housesFolder then
                for currentPass = 1, Settings.TotalPasses do
                    if not Settings.FarmHouses or _G.HalloweenFarmSession ~= thisSession then break end
                    Status.Text = string.format("Будинки (Круг %d/%d)...", currentPass, Settings.TotalPasses)

                    for _, house in ipairs(housesFolder:GetChildren()) do
                        if not Settings.FarmHouses or _G.HalloweenFarmSession ~= thisSession then break end

                        if not isHouseReady(house) then
                            continue
                        end

                        local activation = house:FindFirstChild("Activation")
                        local rootPart = activation and activation:FindFirstChild("Root")
                        local door = house:FindFirstChild("Door")

                        if not fixedDoorTargets[house] then
                            if door and door:IsA("BasePart") then
                                fixedDoorTargets[house] = door.Position + (door.CFrame.LookVector * 4)
                            elseif rootPart and rootPart:IsA("BasePart") then
                                fixedDoorTargets[house] = rootPart.Position
                            end
                        end

                        local targetPos = fixedDoorTargets[house]

                        if targetPos and rootPart then
                            rootPart.Anchored = true
                            rootPart.CanCollide = false

                            root.CFrame = CFrame.new(targetPos.X, targetPos.Y + 1.2, targetPos.Z)

                            pcall(function()
                                firetouchinterest(root, rootPart, 0)
                                task.wait(0.03)
                                firetouchinterest(root, rootPart, 1)
                            end)

                            task.wait(0.2)
                            humanoid.Jump = true
                            task.wait(0.3)
                        end
                    end
                    task.wait(0.3)
                end
            end

            -- Телепорт до обраного яйця
            local eggCFrame = getEggPlatformCFrame(Settings.SelectedEgg)
            if Settings.AutoHatch and eggCFrame then
                root.CFrame = eggCFrame
                task.wait(0.3)
                pressTKey()
                isHatchingActive = true
            end

            -- Таймер КД
            local cooldown = Settings.FarmHouses and Settings.HouseCooldown or 3
            local startTime = tick()

            while (tick() - startTime) < cooldown and _G.HalloweenFarmSession == thisSession do
                if not (Settings.FarmHouses or Settings.AutoHatch) then break end
                local left = math.max(0, math.floor(cooldown - (tick() - startTime)))
                
                if Settings.AutoHatch then
                    Status.Text = string.format("%s [T] (%dc)", Settings.SelectedEgg, left)
                else
                    Status.Text = string.format("КД будинків: %d сек...", left)
                end
                task.wait(1)
            end
        end

        if isHatchingActive then
            pressTKey()
        end
        Status.Text = "Статус: Зупинено"
    end)
end

HouseBtn.MouseButton1Click:Connect(function()
    Settings.FarmHouses = not Settings.FarmHouses
    if Settings.FarmHouses then
        HouseBtn.Text = "Будинки: ON"
        HouseBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
        startCoordinator()
    else
        HouseBtn.Text = "Будинки: OFF"
        HouseBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 35)
        if not Settings.AutoHatch then
            _G.HalloweenFarmSession = (_G.HalloweenFarmSession or 0) + 1
        end
    end
end)

HatchBtn.MouseButton1Click:Connect(function()
    Settings.AutoHatch = not Settings.AutoHatch
    if Settings.AutoHatch then
        HatchBtn.Text = "Auto [T] Hatch: ON"
        HatchBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
        startCoordinator()
    else
        HatchBtn.Text = "Auto [T] Hatch: OFF"
        HatchBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 35)
        if not Settings.FarmHouses then
            _G.HalloweenFarmSession = (_G.HalloweenFarmSession or 0) + 1
        end
    end
end)
