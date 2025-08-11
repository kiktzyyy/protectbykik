if game.PlaceId == 79546208627805 then
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
        warn("Tidak ditemukan part dengan nama 'EnterPart' di workspace.Teleporter3")
        return
    end

    local randomPart = enterParts[math.random(1, #enterParts)]

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenGoal = {Position = randomPart.Position + Vector3.new(0, 5, 0)}

    local tween = TweenService:Create(hrp, tweenInfo, tweenGoal)
    tween:Play()

    print("Tween ke part:", randomPart.Name, "di", randomPart.Parent.Name)

    tween.Completed:Connect(function()
        local args = {
            "Chosen",
            [3] = 1
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TeleportEvent"):FireServer(unpack(args))
    end)

elseif game.PlaceId == 126509999114328 then
    local Players = game:GetService("Players") 
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")

    local player = Players.LocalPlayer
    local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    local placeId = game.PlaceId
    local MIN_PLAYERS, MAX_PLAYERS = 2, 5
    local hitCounter = 1
    local KillAuraRadius = 500

    local toolsDamageIDs = {
        ["Old Axe"] = "_1",
        ["Good Axe"] = "_1",
        ["Strong Axe"] = "_1",
    }

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
        if not itemsFolder then
            warn("[TeleportRandom] Items folder not found!")
            return
        end

        local chests = {}
        for _, item in ipairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and string.find(item.Name, "Chest") and item:FindFirstChild("Main") then
                table.insert(chests, item)
            end
        end

        if #chests == 0 then
            warn("[TeleportRandom] No chests found in Items folder!")
            return
        end

        for i = 1, times do
            local chest = chests[math.random(1, #chests)]
            if chest and chest.Main then
                local character = player.Character or player.CharacterAdded:Wait()
                character:PivotTo(chest.Main.CFrame + Vector3.new(0,5,0))
                print(("[TeleportRandom] Teleported to chest %d/%d: %s"):format(i, times, chest.Name))
                task.wait(1)
            end
        end
    end

    local function tpToStrongholdChest()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        if not hrp then
            warn("[Teleport] HumanoidRootPart not found!")
            return false
        end

        local itemsFolder = workspace:WaitForChild("Items", 10)
        if not itemsFolder then
            warn("[Teleport] Items folder not found!")
            return false
        end

        local chest = itemsFolder:FindFirstChild("Stronghold Diamond Chest")
        if not chest then
            warn("[Teleport] Stronghold Diamond Chest not found!")
            return false
        end

        local mainPart = chest:FindFirstChild("Main")
        if not mainPart then
            warn("[Teleport] Main part in chest not found!")
            return false
        end

        character:PivotTo(mainPart.CFrame + Vector3.new(0, 5, 0))
        print("[Teleport] Teleported to Stronghold Diamond Chest at", mainPart.Position)
        return true
    end

    local function killAuraLoop()
        task.spawn(function()
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
                    if chest and chest:IsA("Model") then
                        local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            fireproximityprompt(prompt, 0)
                            print("[Proximity] Fired proximity prompt on Stronghold Diamond Chest")
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
                print("[Diamond] Took diamond:", diamond.Name)
            end
        end
    end

    local function waitForDiamondsToBeCollected(timeout)
        timeout = timeout or 15
        local startTime = os.time()
        while os.time() - startTime < timeout do
            local diamondCount = 0
            for _, d in ipairs(Workspace.Items:GetChildren()) do
                if d.Name == "Diamond" and d:IsA("Model") then
                    diamondCount = diamondCount + 1
                end
            end

            if diamondCount == 0 then
                print("[Diamond] Semua diamond sudah diambil")
                return true
            end
            print("[Diamond] Masih ada diamond:", diamondCount, "Menunggu...")
            task.wait(2)
        end
        warn("[Diamond] Timeout menunggu diamond habis")
        return false
    end

    -- Server hop with saving tried servers
    local hopFileName = "hopServers.json"

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
        local json = HttpService:JSONEncode(hopList)
        pcall(writefile, hopFileName, json)
    end

    local function shuffleTable(t)
        for i = #t, 2, -1 do
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
    end

    local function hopServerWithRetry(reason)
        print("[ServerHop] Mulai hop server. Reason:", reason or "Unknown")

        local serversUrl = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"

        local success, response = pcall(function()
            return game:HttpGet(serversUrl)
        end)

        if not success then
            warn("[ServerHop] Gagal mengambil daftar server:", response)
            return
        end

        local data = HttpService:JSONDecode(response)
        if not data or not data.data then
            warn("[ServerHop] Data server tidak valid.")
            return
        end

        local hopList = loadHopList()

        local candidates = {}
        for _, server in ipairs(data.data) do
            if server.playing > 0 and server.playing < server.maxPlayers and server.id ~= game.JobId and not table.find(hopList, server.id) then
                table.insert(candidates, server)
            end
        end

        if #candidates == 0 then
            print("[ServerHop] Tidak ada server baru yang ditemukan, reset hop list dan coba lagi.")
            hopList = {}
            saveHopList(hopList)
            return hopServerWithRetry(reason) -- coba ulang setelah reset
        end

        shuffleTable(candidates)

        for _, server in ipairs(candidates) do
            print("[ServerHop] Mencoba teleport ke server:", server.id, "players:", server.playing)
            local teleportSuccess, teleportError = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
            end)
            if teleportSuccess then
                table.insert(hopList, server.id)
                saveHopList(hopList)
                print("[ServerHop] Teleport berhasil!")
                return
            else
                warn("[ServerHop] Gagal teleport:", teleportError)
            end
        end

        warn("[ServerHop] Gagal teleport ke semua server yang tersedia.")
    end

    -- Main logic
    _G.Settings = {Main = {["Kill Aura"] = true}}

    while true do
        teleportRandomChests(5)
        
        local teleported = tpToStrongholdChest()
        if teleported then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, nil)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, nil)
            task.wait(0.2)

            killAuraLoop()
            fireProximityLoop()
            task.wait(3)
            takeDiamonds()
            local success = waitForDiamondsToBeCollected(20)
            if not success then
                warn("[Main] Diamond tidak habis diambil, coba lagi nanti.")
            end

            hopServerWithRetry("Diamonds collected, hopping server")
            break
        else
            hopServerWithRetry("Failed to teleport to diamond chest")
            break
        end
    end
else
    print("PlaceId tidak cocok, script tidak dijalankan.")
end
