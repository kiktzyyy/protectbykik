if game.PlaceId == 79546208627805 then
    -- Lobby teleport
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local teleporter3 = workspace.Teleporter3

    local enterParts = {}
    for _, obj in ipairs(teleporter3:GetChildren()) do
        if obj.Name == "EnterPart" and obj:IsA("BasePart") then
            table.insert(enterParts, obj)
        end
    end

    if #enterParts == 0 then
        warn("Tidak ditemukan part 'EnterPart'")
        return
    end

    local randomPart = enterParts[math.random(1, #enterParts)]
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    local tween = TweenService:Create(hrp, TweenInfo.new(2), {Position = randomPart.Position + Vector3.new(0, 5, 0)})
    tween:Play()

    tween.Completed:Connect(function()
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TeleportEvent"):FireServer("Chosen", 1)
    end)

elseif game.PlaceId == 126509999114328 then

local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

RunService.Stepped:Connect(function()
    pcall(function()
        sethiddenproperty(plr, "SimulationRadius", math.huge)
        sethiddenproperty(plr, "MaxSimulationRadius", math.huge)
    end)
end)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local player = Players.LocalPlayer
    local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    local placeId = game.PlaceId
    local KillAuraRadius = 5000
    local hopFileName = "hopServers.json"
    _G.Settings = {Main = {["Kill Aura"] = true}}

    local toolsDamageIDs = {
        ["Old Axe"] = "_1",
        ["Good Axe"] = "_1",
        ["Strong Axe"] = "_1",
    }

    local function loadHopList()
        local success, content = pcall(readfile, hopFileName)
        if success and content then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, content)
            if ok and type(data) == "table" then
                return data
            end
        end
        return {}
    end

    local function saveHopList(hopList)
        pcall(writefile, hopFileName, HttpService:JSONEncode(hopList))
    end

    local function shuffleTable(t)
        for i = #t, 2, -1 do
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
    end

local function hopServerWithRetry(reason)
    print("[ServerHop] Reason:", reason or "Unknown")
    local hopList = loadHopList()

    while true do
        local success, response = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100")
        end)

        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.data then
                local candidates = {}
                for _, server in ipairs(data.data) do
                    if server.playing > 0 and server.playing < server.maxPlayers
                        and server.id ~= game.JobId
                        and not table.find(hopList, server.id) then
                        table.insert(candidates, server)
                    end
                end

                if #candidates == 0 then
                    hopList = {}
                    saveHopList(hopList)
                    task.wait(1)
                else
                    shuffleTable(candidates)
                    local target = candidates[1]
                    table.insert(hopList, target.id)
                    saveHopList(hopList)

                    print("[ServerHop] Trying:", target.id)
                    local ok = pcall(function()
                        TeleportService:TeleportToPlaceInstance(placeId, target.id, player)
                    end)
                    task.wait(1)
                end
            else
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end

    local function getToolAndDamageID()
        for toolName, suffix in pairs(toolsDamageIDs) do
            local tool = player:FindFirstChild("Inventory") and player.Inventory:FindFirstChild(toolName)
            if tool then
                return tool, suffix
            end
        end
        return nil, nil
    end

    local function findBasePart(model)
        for _, v in ipairs(model:GetDescendants()) do
            if v:IsA("BasePart") then
                return v
            end
        end
        return nil
    end

    local function teleportRandomChests(times)
        local itemsFolder = workspace:FindFirstChild("Items")
        if not itemsFolder then return end

        local chests = {}
        for _, item in ipairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and string.find(item.Name, "Chest") and item:FindFirstChild("Main") then
                table.insert(chests, item)
            end
        end

        if #chests == 0 then return end

        times = math.min(times, #chests)

        local shuffled = {}
        for i = 1, #chests do
            shuffled[i] = chests[i]
        end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end

        for i = 1, times do
            local chest = shuffled[i]
            if chest and chest.Main then
                local character = player.Character or player.CharacterAdded:Wait()
                character:PivotTo(chest.Main.CFrame + Vector3.new(0, 5, 0))
                task.wait(1)
            end
        end
    end

    local function tpToStrongholdChest()
        local itemsFolder = workspace:FindFirstChild("Items")
        if not itemsFolder then return false end
        local chest = itemsFolder:FindFirstChild("Stronghold Diamond Chest")
        if not chest then return false end
        local mainPart = chest:FindFirstChild("Main")
        if not mainPart then return false end
        local character = player.Character or player.CharacterAdded:Wait()
        character:PivotTo(mainPart.CFrame + Vector3.new(0, 5, 0))
        return true
    end

    local function killAuraLoop()
        task.spawn(function()
            local hitCounter = 1
            while true do
                task.wait(0.2)
                if _G.Settings.Main["Kill Aura"] then
                    local character = player.Character or player.CharacterAdded:Wait()
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local tool, suffix = getToolAndDamageID()
                    if tool and suffix and hrp then
                        local foundEnemy = false
                        for _, enemy in ipairs(Workspace.Characters:GetChildren()) do
                            if enemy:IsA("Model") and enemy ~= character then
                                local part = findBasePart(enemy)
                                if part and (part.Position - hrp.Position).Magnitude <= KillAuraRadius then
                                    foundEnemy = true
                                    coroutine.wrap(function()
                                        for i = 1, 13 do
                                            if not _G.Settings.Main["Kill Aura"] or not enemy or not enemy.Parent then
                                                break
                                            end
                                            local damageID = tostring(hitCounter) .. suffix
                                            pcall(function()
                                                RemoteEvents.ToolDamageObject:InvokeServer(
                                                    enemy,
                                                    tool,
                                                    damageID,
                                                    CFrame.new(part.Position)
                                                )
                                            end)
                                            hitCounter += 1
                                            task.wait(0.2)
                                        end
                                    end)()
                                end
                            end
                        end
                        if not foundEnemy then
                            task.wait(0.2)
                        end
                    end
                end
            end
        end)
    end

    local function fireProximityLoop()
        task.spawn(function()
            while true do
                task.wait(0.5)
                local itemsFolder = workspace:FindFirstChild("Items")
                if itemsFolder then
                    local chest = itemsFolder:FindFirstChild("Stronghold Diamond Chest")
                    if chest then
                        local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            fireproximityprompt(prompt, 0)
                        end
                    end
                end
            end
        end)
    end

    local function takeDiamonds()
        for _, diamond in ipairs(Workspace.Items:GetChildren()) do
            if diamond.Name == "Diamond" and diamond:IsA("Model") then
                RemoteEvents.RequestTakeDiamonds:FireServer(diamond)
            end
        end
    end

    local function waitForDiamonds(timeout)
        timeout = timeout or 60
        local start = os.time()
        while os.time() - start < timeout do
            local found = false
            for _, d in ipairs(Workspace.Items:GetChildren()) do
                if d.Name == "Diamond" then
                    found = true
                    break
                end
            end
            if found then return true end
            task.wait(1)
        end
        return false
    end
    
  local function teleportBetweenChestAndPart(chestMain, partTarget)
    task.spawn(function()
            local char = player.Character or player.CharacterAdded:Wait()
            char:PivotTo(partTarget.CFrame + Vector3.new(0, 5, 0))
            task.wait(0.5)

            char:PivotTo(chestMain.CFrame + Vector3.new(0, 5, 0))
            task.wait(0.5)
    end)
end

    -- Main Loop
    teleportRandomChests(5)
    local teleported = tpToStrongholdChest()
    if teleported then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, nil)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, nil)
        killAuraLoop()
        fireProximityLoop()
        
        local partTarget = workspace.Map.Landmarks.Stronghold.Building.Floor:FindFirstChild("Part")
        
        if chestMain and partTarget then
        teleportBetweenChestAndPart(chestMain, partTarget)
        end

        local dropped = waitForDiamonds(500)
        if dropped then
            takeDiamonds()
            task.wait(3)
            hopServerWithRetry("Diamonds collected")
        else
            hopServerWithRetry("Diamond not dropped in time")
        end
    else
        hopServerWithRetry("No Stronghold Chest found")
    end
end
