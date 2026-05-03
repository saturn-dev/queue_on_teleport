--== SERVICES ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/saturn-dev/queue_on_teleport/refs/heads/main/run.lua"))()]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--== CONFIG: Script to run after teleport ==--

queue_on_teleport(payloadScript)

-- Wait for game to fully load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Wait for RobberyConsts module to load
local function waitForRobberyConsts()
    local RobberyConsts
    repeat
        local success, result = pcall(function()
            local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyFolder then
                local consts = robberyFolder:FindFirstChild("RobberyConsts")
                if consts then
                    RobberyConsts = require(consts)
                end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    return RobberyConsts
end

-- Wait for Crown Jewel robbery state value
local function waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
    local powerPlantValue
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local PP_ID = ENUM_ROBBERY and ENUM_ROBBERY.CROWN_JEWEL
            if PP_ID then
                powerPlantValue = folder:FindFirstChild(tostring(PP_ID))
            end
        end
        task.wait(0.5)
    until powerPlantValue
    return powerPlantValue
end

local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

local powerPlantValue = waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

local function isPowerPlantOpen()
    local status = powerPlantValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function HidePickingTeam()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local teamSelectFolder = ReplicatedStorage:WaitForChild("TeamSelect", 10)
    if not teamSelectFolder then return end

    local TeamChooseUI = require(teamSelectFolder:WaitForChild("TeamChooseUI", 10))

    repeat
        task.wait()
        pcall(function()
            TeamChooseUI.Hide()
        end)
    until
        not playerGui:FindFirstChild("TeamSelectGui")
        or not playerGui.TeamSelectGui.Enabled
        or player.TeamColor == BrickColor.new("Bright red")
        or (player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health <= 0)
end
task.spawn(function()
    task.wait(250)
    serverHop()
end)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local WEBHOOK_URL = "https://discord.com/api/webhooks/1388992756093026514/Ix-HSEw6A-vEqGDNfg4TILYZqSBAMjJol_uZhTYuS1_ORiuDF60PxKSTIgUe37JL_CFV"

local function runwebhook()
    local data = HttpService:JSONEncode({
        embeds = {
            {
                title = "Casino Robbery",
                description = "Successfully robbed the Casino",
                color = 0xFF69B4, -- pink to match the image
                thumbnail = {
                    url = "https://static.wikia.nocookie.net/rblx-jailbreak/images/f/fc/HyperPink.png"
                },
                fields = {
                    {
                        name = "Player",
                        value = localPlayer.Name,
                        inline = true
                    },
                    {
                        name = "Game",
                        value = "Jailbreak",
                        inline = true
                    }
                },
                footer = {
                    text = "by @oksaturn"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    })

    pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, data, Enum.HttpContentType.ApplicationJson)
    end)
end

--== Server hopping logic using Raise API ==--
local function serverHop()
    print("🌐 Crown Jewel closed, searching for new server...")

    local success, result = pcall(function()
        local url = "https://robloxapi.robloxapipro.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list.")
        task.wait(5)
        return serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No servers available. Retrying...")
        task.wait(10)
        return serverHop()
    end

local chosenServer = candidates[math.random(1, #candidates)]
print("🚀 Teleporting to server:", chosenServer)

task.delay(3, function()
    serverHop()
end)



    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out. Trying another...")
    end)

    local success, err = pcall(function()
        
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)

    if not success then
        warn("❌ Teleport failed:", err)
        task.cancel(teleportCheck)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    if teleportFailed then
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    task.cancel(teleportCheck)
end

--== Fallback to server hop when robbery closed ==--
local function teleportToRandomServer()
    print("🔁 Crown Jewel is closed. Teleporting in 5 seconds...")
    task.wait(5)
    serverHop()
end

--== Main loop ==--
while true do
    if isPowerPlantOpen() then
        print("⚡ Crown Jewel is OPEN! Staying in this server.")
HidePickingTeam()
wait(1)
        
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local liftHeight = 200
local targetPos = Vector3.new(-1693, 129, -1632)
local totalDuration = 20  -- adjust to taste

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")
local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

if not root then
    warn("No root part found!")
    return
end

humanoid.PlatformStand = true

local BG = Instance.new("BodyGyro")
BG.P = 9e4
BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
BG.CFrame = root.CFrame
BG.Parent = root

local BV = Instance.new("BodyVelocity")
BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
BV.Velocity = Vector3.new(0, 0, 0)
BV.Parent = root

local startPos = root.Position
local startCFrame = root.CFrame

-- Waypoints: up 300 studs, then to target
local wp1 = startPos + Vector3.new(0, liftHeight, 0)
local wp2 = targetPos

local d1 = (wp1 - startPos).Magnitude
local d2 = (wp2 - wp1).Magnitude
local totalDist = d1 + d2

local phases = {
    {from = startPos, to = wp1, duration = totalDuration * (d1 / totalDist)},
    {from = wp1,      to = wp2, duration = totalDuration * (d2 / totalDist)},
}

local currentPhase = 1
local elapsed = 0

local connection
connection = RunService.Heartbeat:Connect(function(dt)
    local phase = phases[currentPhase]
    elapsed = elapsed + dt
    
    local distance = phase.to - phase.from
    BV.Velocity = distance / phase.duration
    
    BG.CFrame = startCFrame
    
    if elapsed >= phase.duration then
        currentPhase = currentPhase + 1
        elapsed = 0
        if currentPhase > #phases then
            connection:Disconnect()
            BV.Velocity = Vector3.new(0, 0, 0)
            task.wait(0.1)
            BG:Destroy()
            BV:Destroy()
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
end)
task.wait(25)
local function CasinoRob()
    
    --== SERVICES ==--
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

  

    --== CONFIG: Script to run after teleport ==--

    --== Utility: Wait for game & modules ==--
    local function waitForRobberyConsts()
        local RobberyConsts
        repeat
            pcall(function()
                local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
                if robberyFolder then
                    local consts = robberyFolder:FindFirstChild("RobberyConsts")
                    if consts then
                        RobberyConsts = require(consts)
                    end
                end
            end)
            task.wait(0.5)
        until RobberyConsts
        return RobberyConsts
    end

    local function waitForCrownJewelValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
        local value
        repeat
            local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
            if folder then
                local CJ_ID = ENUM_ROBBERY and ENUM_ROBBERY.CROWN_JEWEL
                if CJ_ID then
                    value = folder:FindFirstChild(tostring(CJ_ID))
                end
            end
            task.wait(0.5)
        until value
        return value
    end

    --== Wrapper: Initializes and exposes functions ==--
    local function CrownJewelChecker()
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end

        local RobberyConsts = waitForRobberyConsts()
        local ENUM_STATUS = RobberyConsts.ENUM_STATUS
        local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
        local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

        local crownJewelValue = waitForCrownJewelValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

        -- Function #1 → check if OPEN
        local function isCrownJewelOpen()
            return crownJewelValue.Value == ENUM_STATUS.OPENED
        end

        -- Function #2 → check if STARTED
        local function isCrownJewelStarted()
            return crownJewelValue.Value == ENUM_STATUS.STARTED
        end

        return isCrownJewelOpen, isCrownJewelStarted
    end

    --== Usage Example ==--
    local isOpen, isStarted = CrownJewelChecker()

    if isOpen() then
        print("💎 Crown Jewel robbery is OPEN!")
    elseif isStarted() then
        print("🔥 Crown Jewel robbery has STARTED!")
    else
        print("❌ Crown Jewel is closed.")
    end

    local function firePrisonerEvent()
        local function FindRemoteEvent()
            while true do
                for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                        print("✅ Found RemoteEvent:", obj.Name)
                        return obj
                    end
                end
                warn("⏳ RemoteEvent not found yet, waiting...")
                wait(1)
            end
        end
        
        local mainRemote = FindRemoteEvent()
        
        -- Find GUIDs
        local policeGUID, enterGUID, hijackGUID, deathGUID
        for _, t in pairs(getgc(true)) do
            if typeof(t) == "table" and not getmetatable(t) then
                if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
                    policeGUID = t["lnu8qihc"]
                    print("✅ Found Police GUID")
                end
                if t["ole3gm5p"] and type(t["ole3gm5p"]) == "string" and t["ole3gm5p"]:sub(1,1) == "!" then
                    enterGUID = t["ole3gm5p"]
                    print("✅ Found enterGUID")
                end
                if t["muw6nit5"] and type(t["muw6nit5"]) == "string" and t["muw6nit5"]:sub(1,1) == "!" then
                    hijackGUID = t["muw6nit5"]
                    print("✅ Found hijackGUID")
                end
                if t["p14s6fjq"] and type(t["p14s6fjq"]) == "string" and t["p14s6fjq"]:sub(1,1) == "!" then
                    deathGUID = t["p14s6fjq"]
                    print("✅ Found deathGUID")
                end
            end
        end
        task.wait(2)
        -- Fire prisoner
        local humanoidRootPart = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

        if policeGUID then
            mainRemote:FireServer(policeGUID, "Prisoner")
            print("🔫 Fired prisoner event")
        else
            warn("❌ Missing Police GUID")
        end

        return hijackGUID, enterGUID, mainRemote, deathGUID
    end

    local hijackGUID, enterGUID, mainRemote, deathGUID = firePrisonerEvent()

    task.wait(2)

    -- Teleport local player once to the specified CFrame (position + orientation)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- Wait for character & root part
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")

    -- Target CFrame
    local targetCF = CFrame.new(
        -182.869904, 17.3167152, -4683.11572,
        -0.961297989, 0, -0.275510818,
         0,          1,  0,
         0.275510818, 0, -0.961297989
    )

    -- Prefer PivotTo for whole character (more stable), fallback to HRP if needed
    if character and character.PrimaryPart then
        character:PivotTo(targetCF)
    else
        hrp.CFrame = targetCF
    end

    task.wait(2)

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- Wait for character
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    -- Teleport 500 studs up
    hrp.CFrame = hrp.CFrame + Vector3.new(0,700, 0)

    -- Freeze the player (can't move/jump)
    humanoid.PlatformStand = true

    task.wait(2)

    --== SERVICES ==--
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer

    --== HELPER FUNCTIONS ==--

    -- Force CFrame to target every Heartbeat
    local function holdAtPosition(position, stopSignal)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart")
        local target = CFrame.new(position + Vector3.new(0, 3, 0))

        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not root or not root.Parent or stopSignal.Value then
                conn:Disconnect()
                return
            end
            root.CFrame = target
        end)
    end

    -- Spam the remote for ~2 seconds
    local function hackComputer(remote, index)
        print("[DEBUG] Hacking computer #" .. index .. " for 2 seconds...")
        local startTime = tick()
        while tick() - startTime < 2 and not isStarted() do  -- Added check for isStarted()
            
            for i = 1, 200 do
                remote:FireServer()
                task.wait(0.01)
            end
            
        end
        print("[DEBUG] Finished hacking computer #" .. index)
    end

    --== FUNCTIONS ==--

    local function hackAllComputers()
        task.spawn(function()
            local computersFolder = Workspace:WaitForChild("Casino"):WaitForChild("Computers")
            local computers = computersFolder:GetChildren()

            print("[DEBUG] Found " .. #computers .. " computers under Casino.Computers")

            for i, computer in ipairs(computers) do
                if computer:IsA("Model") then
                    local remote = computer:FindFirstChild("CasinoComputerHack")
                    if remote and remote:IsA("RemoteEvent") then
                        local pos = computer:GetPivot().Position
                        print("[DEBUG] Moving to computer #" .. i .. " at position:", pos)

                        -- Create a stop signal for this station
                        local stopSignal = Instance.new("BoolValue")
                        stopSignal.Value = false

                        -- Lock CFrame until we're done with this computer
                        holdAtPosition(pos, stopSignal)

                        -- Wait until team is Criminal
                        while LocalPlayer.Team == nil or LocalPlayer.Team.Name ~= "Criminal" do
                            print("[DEBUG] Waiting for Criminal team before hacking...")
                            task.wait(1)
                            if isStarted() then break end  -- Added check for isStarted()
                        end

                        -- Skip if robbery started while waiting
                        if isStarted() then
                            print("[DEBUG] Crown Jewel started - breaking computer hacking loop")
                            stopSignal.Value = true
                            break
                        end

                        -- Hack this computer
                        hackComputer(remote, i)

                        -- Stop holding position so we can move to the next
                        stopSignal.Value = true
                        task.wait(0.1)
                        
                        -- Check if robbery started after this computer
                        if isStarted() then
                            print("[DEBUG] Crown Jewel started - breaking computer hacking loop")
                            break
                        end
                    else
                        print("[DEBUG] Skipping computer #" .. i .. " (no CasinoComputerHack RemoteEvent found)")
                    end
                end
            end

            print("✅ [DEBUG] All computers processed.")
        end)
    end

    local function collectNearestCash()
        task.spawn(function()
            local lootFolder = Workspace:WaitForChild("Casino"):WaitForChild("Loots")
            local loots = lootFolder:GetDescendants()

            -- Find nearest CasinoCash
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = character:WaitForChild("HumanoidRootPart")
            local nearest, nearestDist

            for _, loot in ipairs(loots) do
                if loot.Name == "Casino_Cash" then
                    local pos = loot:GetPivot().Position
                    local dist = (root.Position - pos).Magnitude
                    if not nearest or dist < nearestDist then
                        nearest, nearestDist = loot, dist
                    end
                end
            end

            if not nearest then
                warn("[DEBUG] No CasinoCash found in Workspace.Casino.Loots!")
                return
            end

            print("[DEBUG] Nearest CasinoCash at:", nearest:GetPivot().Position)

            -- Lock to the cash position
            local stopSignal = Instance.new("BoolValue")
            stopSignal.Value = false
            holdAtPosition(nearest:GetPivot().Position, stopSignal)

            -- Run CasinoLootCollect
            local remote = nearest:FindFirstChild("CasinoLootCollect")
            if remote and remote:IsA("RemoteEvent") then
                print("[DEBUG] Collecting CasinoCash for 5 seconds...")
                local startTime = tick()
                while tick() - startTime < 3 do
                    remote:FireServer()
                    task.wait(0.001)
                end
                print("[DEBUG] Finished collecting CasinoCash")
            else
                warn("[DEBUG] CasinoLootCollect remote not found under CasinoCash!")
            end

            -- Stop holding position
            stopSignal.Value = true
        end)
    end

    --== MAIN SEQUENCE ==--

    hackAllComputers()

    -- Wait until robbery starts or all computers are processed
    while not isStarted() do
        task.wait(0.1)
    end

    collectNearestCash()

    -- Define the target position as a CFrame
    local targetPosition = CFrame.new(1128.31506, 129.162865, 1300.4928)

    -- Get the Players service and RunService
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    -- Get the local player
    local player = Players.LocalPlayer

    -- Variables to track toggle state
    local isToggled = false
    local teleportLoopConnection = nil

    -- Function to start continuous teleportation
    local function startContinuousTeleport()
        -- Ensure the character exists
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            player.CharacterAdded:Wait()
        end

        local character = player.Character
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")

        -- Make the player sit
        humanoid.Sit = true

        -- Continuously teleport the player to the target position
        teleportLoopConnection = RunService.Stepped:Connect(function()
            if humanoidRootPart and humanoidRootPart.Parent then
                humanoidRootPart.CFrame = targetPosition
            else
                -- Disconnect the loop if the HumanoidRootPart is destroyed
                if teleportLoopConnection then
                    teleportLoopConnection:Disconnect()
                    teleportLoopConnection = nil
                end
            end
        end)
    end

    task.wait(1)

    -- Function to stop continuous teleportation
    local function stopContinuousTeleport()
        -- Stop the teleportation loop
        if teleportLoopConnection then
            teleportLoopConnection:Disconnect()
            teleportLoopConnection = nil
        end

        -- Ensure the character exists
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            player.CharacterAdded:Wait()
        end

        local character = player.Character
        local humanoid = character:WaitForChild("Humanoid")

        -- Make the player stand up
        humanoid.Sit = false
    end

    -- Function to auto-toggle teleportation for 3 seconds
    local function autoToggleTeleport()
        if isToggled then
            print("Already toggled on. Skipping.")
            return
        end

        -- Start continuous teleportation
        startContinuousTeleport()
        isToggled = true
        print("Auto-toggled ON: Teleporting for 3 seconds.")

        -- Wait for 3 seconds
        task.wait(5)

        -- Stop continuous teleportation
        stopContinuousTeleport()
        isToggled = false
        print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
    end

    -- Automatically execute the auto-toggle logic when the script runs
    autoToggleTeleport()

    task.wait(0.7)

    -- Services
    task.wait(0.7)

    local function spawnVehicle()
        local GarageSpawnVehicle = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle")
        if GarageSpawnVehicle and GarageSpawnVehicle:IsA("RemoteEvent") then
            GarageSpawnVehicle:FireServer("Chassis", "Camaro")
        end
    end

    spawnVehicle()
    task.wait(0.7)
    local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local cruiseHeight = 587
local targetPos = Vector3.new(-283, 18, 1599)
local totalDuration = 30

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")
local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

if not root then
    warn("No root part found!")
    return
end

humanoid.PlatformStand = true

local BG = Instance.new("BodyGyro")
BG.P = 9e4
BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
BG.CFrame = root.CFrame
BG.Parent = root

local BV = Instance.new("BodyVelocity")
BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
BV.Velocity = Vector3.new(0, 0, 0)
BV.Parent = root

local startPos = root.Position
local startCFrame = root.CFrame

local wp1 = Vector3.new(startPos.X, cruiseHeight, startPos.Z)
local wp2 = Vector3.new(targetPos.X, cruiseHeight, targetPos.Z)
local wp3 = targetPos

local d1 = (wp1 - startPos).Magnitude
local d2 = (wp2 - wp1).Magnitude
local d3 = (wp3 - wp2).Magnitude
local totalDist = d1 + d2 + d3

local phases = {
    {from = startPos, to = wp1, duration = totalDuration * (d1 / totalDist)},
    {from = wp1,      to = wp2, duration = totalDuration * (d2 / totalDist)},
    {from = wp2,      to = wp3, duration = totalDuration * (d3 / totalDist)},
}

local currentPhase = 1
local elapsed = 0

local connection
connection = RunService.Heartbeat:Connect(function(dt)
    local phase = phases[currentPhase]
    elapsed = elapsed + dt
    
    -- Constant velocity: distance / time, applied steadily the whole phase
    local distance = phase.to - phase.from
    BV.Velocity = distance / phase.duration
    
    BG.CFrame = startCFrame
    
    if elapsed >= phase.duration then
        currentPhase = currentPhase + 1
        elapsed = 0
        if currentPhase > #phases then
            connection:Disconnect()
            BV.Velocity = Vector3.new(0, 0, 0)
            task.wait(0.1)
            BG:Destroy()
            BV:Destroy()
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
end)
    end

CasinoRob()
wait(3)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local money = localPlayer.leaderstats.Money

local previousMoney = money.Value
local timeoutDuration = 150 -- seconds
local hopped = false

-- Watch for money increasing by 750
money.Changed:Connect(function(newValue)
    if not hopped and (newValue - previousMoney) == 750 then
        hopped = true
        print("Money went up by $750! Server hopping...")
        runwebhook()
        task.wait(10)
        serverHop()
    end
    previousMoney = newValue
end)

-- 150 second timeout
local startTime = tick()

while not hopped do
    if tick() - startTime >= timeoutDuration then
        print("150 second timeout reached. Server hopping...")
        hopped = true
        serverHop()
        break
    end
    task.wait(1)
end


        break
    else
        teleportToRandomServer()
        break
    end
end
