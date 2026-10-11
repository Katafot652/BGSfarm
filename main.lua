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
    EggName = "Malevolent Egg",
    HouseCooldown = 60,
    TotalPasses = 3
}

local function pressTKey()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
end

local function getEggPlatformCFrame()
    local eggsFolder = Workspace:FindFirstChild("Eggs")
    if eggsFolder then
        local targetEgg = eggsFolder:FindFirstChild(Settings.EggName)
        if targetEgg then
            local hotkey = targetEgg:FindFirstChild("Hotkey")
            if hotkey and hotkey:IsA("BasePart") then
                return hotkey.CFrame + Vector3.new(0, 2.5, 0)
            end
            local primary = targetEgg:FindFirstChild("Primary") or targetEgg:FindFirstChildWhichIsA("BasePart")
            if primary then
                return primary.CFrame + Vector3.new(0, 2.5, 4)
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

-- Створення меню
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BGS_MalevolentCombo_GUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 160)
Frame.Position = UDim2.new(0.05, 0, 0.35, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 20, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(245, 120, 25)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 26)
Title.Position = UDim2.new(0, 10, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "🎃 Houses + Jump Farm"
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

local HouseBtn = Instance.new("TextButton")
HouseBtn.Size = UDim2.new(0.88, 0, 0, 32)
HouseBtn.Position = UDim2.new(0.06, 0, 0, 34)
HouseBtn.Text = "Будинки: OFF"
HouseBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 35)
HouseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HouseBtn.Font = Enum.Font.SourceSansBold
HouseBtn.TextSize = 14
HouseBtn.Parent = Frame
Instance.new("UICorner", HouseBtn).CornerRadius = UDim.new(0, 6)

local HatchBtn = Instance.new("TextButton")
HatchBtn.Size = UDim2.new(0.88, 0, 0, 32)
HatchBtn.Position = UDim2.new(0.06, 0, 0, 72)
HatchBtn.Text = "Auto [T] Hatch: OFF"
HatchBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 35)
HatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HatchBtn.Font = Enum.Font.SourceSansBold
HatchBtn.TextSize = 14
HatchBtn.Parent = Frame
Instance.new("UICorner", HatchBtn).CornerRadius = UDim.new(0, 6)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 35)
Status.Position = UDim2.new(0.05, 0, 0, 112)
Status.BackgroundTransparency = 1
Status.Text = "Статус: Очікування"
Status.TextColor3 = Color3.fromRGB(190, 190, 190)
Status.TextSize = 12
Status.Font = Enum.Font.SourceSans
Status.Parent = Frame

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

                            -- Телепорт на землю перед дверима
                            root.CFrame = CFrame.new(targetPos.X, targetPos.Y + 1.2, targetPos.Z)

                            pcall(function()
                                firetouchinterest(root, rootPart, 0)
                                task.wait(0.03)
                                firetouchinterest(root, rootPart, 1)
                            end)

                            -- Очікування 0.2с перед стрибком
                            task.wait(0.2)

                            -- Стрибок для оновлення колізії сервером
                            humanoid.Jump = true

                            -- Очікування 0.3с після стрибка перед наступним ТП
                            task.wait(0.3)
                        end
                    end
                    task.wait(0.3)
                end
            end

            local eggCFrame = getEggPlatformCFrame()
            if Settings.AutoHatch and eggCFrame then
                root.CFrame = eggCFrame
                task.wait(0.3)
                pressTKey()
                isHatchingActive = true
            end

            local cooldown = Settings.FarmHouses and Settings.HouseCooldown or 3
            local startTime = tick()

            while (tick() - startTime) < cooldown and _G.HalloweenFarmSession == thisSession do
                if not (Settings.FarmHouses or Settings.AutoHatch) then break end
                local left = math.max(0, math.floor(cooldown - (tick() - startTime)))
                
                if Settings.AutoHatch then
                    Status.Text = string.format("Хетч [T] (КД: %dc)", left)
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
