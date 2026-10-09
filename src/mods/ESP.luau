local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local activeESP = {}       -- Chứa các hàm cập nhật đang chạy
local playerConnections = {} -- Quản lý sự kiện của từng người chơi
local updateConnection = nil
local playerJoinConn, playerLeaveConn
local enabled = false
local destroyed = false
local generation = 0
local pendingTasks = {}

-- Hàm tạo trọn bộ ESP 2D (Khung dọc + Thanh máu dọc + Tên ở dưới)
local function createPlayer2DESP(character, player)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return nil end
    
    -- 1. Tạo BillboardGui bao quanh nhân vật
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_2D_" .. player.Name
    billboardGui.Size = UDim2.new(4.5, 0, 6.0, 0) -- Tỉ lệ khung chữ nhật dọc chuẩn dáng người
    billboardGui.AlwaysOnTop = true
    billboardGui.Adornee = rootPart
    billboardGui.Parent = rootPart
    
    -- 2. Khung hình chữ nhật chính (Box)
    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "Box"
    boxFrame.Size = UDim2.new(0.75, 0, 0.9, 0) -- Thu gọn chiều ngang để thành hình chữ nhật dọc
    boxFrame.Position = UDim2.new(0.125, 0, 0.05, 0)
    boxFrame.BackgroundTransparency = 1
    boxFrame.Parent = billboardGui
    
    -- Viền của khung chữ nhật (Màu tím neon)
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(255, 0, 255)
    boxStroke.Thickness = 1.5
    boxStroke.LineJoinMode = Enum.LineJoinMode.Miter
    boxStroke.Parent = boxFrame
    
    -- 3. Thanh máu dọc (Lồng vào cạnh trái của Khung)
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBg"
    healthBg.Size = UDim2.new(0.08, 0, 1, 0) -- Thanh dọc siêu mỏng
    healthBg.Position = UDim2.new(-0.1, 0, 0, 0) -- Nằm sát bên trái cạnh khung
    healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = boxFrame
    
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    
    -- 4. Username người chơi (Đã chuyển xuống ĐÁY KHUNG)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 15)
    nameLabel.Position = UDim2.new(0, 0, 1, 4) -- Đẩy xuống dưới đáy khung 4 pixel
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    -- Thêm viền chữ đen để nhìn rõ trên mọi địa hình bản đồ
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = boxFrame
    
    -- Hàm cập nhật lượng máu theo thời gian thực
    return function()
        if not enabled or not character.Parent or not humanoid.Parent or not rootPart.Parent then
            billboardGui:Destroy()
            return false
        end
        
        local healthPercent = math.clamp(player.ReadOnly.health / player.ReadOnly.health_max, 0, 1)
        
        -- Cập nhật thanh máu tụt dần từ TRÊN xuống DƯỚI
        healthFill.Size = UDim2.new(1, 0, healthPercent, 0)
        healthFill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
        
        -- Đổi màu thanh máu tùy theo tình trạng
        if healthPercent > 0.5 then
            healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá
        elseif healthPercent > 0.25 then
            healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Vàng
        else
            healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
        end
        return true
    end
end

-- [Hệ thống quản lý sự kiện và vòng lặp]
function ESP.enable()
    if destroyed or enabled then return end
    enabled = true
    generation += 1
    local currentGeneration = generation
    
    local function setupPlayerESP(player)
        if not enabled or generation ~= currentGeneration or player == Players.LocalPlayer or playerConnections[player] then return end
        
        local function onCharacterAdded(character)
            if not enabled or generation ~= currentGeneration then return end
            local pending
            pending = task.delay(0.3, function()
                pendingTasks[pending] = nil
                if not enabled or destroyed or generation ~= currentGeneration then return end
                if not playerConnections[player] or player.Character ~= character then return end

                local espUpdate = createPlayer2DESP(character, player)
                if espUpdate then table.insert(activeESP, espUpdate) end
            end)
            pendingTasks[pending] = player
        end
        
        local conn = player.CharacterAdded:Connect(onCharacterAdded)
        playerConnections[player] = conn
        
        if player.Character then
            onCharacterAdded(player.Character)
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayerESP(player)
    end
    
    playerJoinConn = Players.PlayerAdded:Connect(setupPlayerESP)
    playerLeaveConn = Players.PlayerRemoving:Connect(function(player)
        if not enabled or generation ~= currentGeneration then return end
        if playerConnections[player] then
            playerConnections[player]:Disconnect()
            playerConnections[player] = nil
        end
        for pending, owner in pairs(pendingTasks) do
            if owner == player then
                task.cancel(pending)
                pendingTasks[pending] = nil
            end
        end
    end)
    
    -- Vòng lặp cập nhật mượt mà chuẩn 60FPS+ bằng Heartbeat
    updateConnection = RunService.Heartbeat:Connect(function()
        if not enabled or generation ~= currentGeneration then return end
        
        for i = #activeESP, 1, -1 do
            local isAlive = activeESP[i]()
            if not isAlive then
                table.remove(activeESP, i)
            end
        end
    end)
end

function ESP.disable()
    enabled = false
    generation += 1

    for pending in pairs(pendingTasks) do
        task.cancel(pending)
    end
    table.clear(pendingTasks)
    
    if updateConnection then updateConnection:Disconnect() updateConnection = nil end
    if playerJoinConn then playerJoinConn:Disconnect() playerJoinConn = nil end
    if playerLeaveConn then playerLeaveConn:Disconnect() playerLeaveConn = nil end
    
    for player, conn in pairs(playerConnections) do
        conn:Disconnect()
    end
    table.clear(playerConnections)
    
    for _, updateFunc in ipairs(activeESP) do
        updateFunc() -- Gọi lần cuối để tự hủy GUI
    end
    table.clear(activeESP)
end

function ESP.destroy()
    if destroyed then return end
    destroyed = true
    ESP.disable()
end

function ESP.isEnabled()
    return enabled
end

return ESP
