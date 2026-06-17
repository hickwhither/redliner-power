local AutoAim = _G.offlineservice("AutoAim")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local aimConnection = nil

--- ==========================================
--- KHỞI TẠO UI HIỂN THỊ TRẠNG THÁI AIM
--- ==========================================
local statusText = Drawing.new("Text")
statusText.Visible = true
statusText.Center = true
statusText.Outline = true
statusText.Size = 22
statusText.Font = 2 -- Phông chữ rõ nét, dễ nhìn
statusText.Text = "Aim : OFF"
statusText.Color = Color3.fromRGB(255, 0, 0) -- Mặc định là OFF (Màu đỏ)

-- Vòng lặp cập nhật vị trí chữ (X giữa, Y 3/4 màn hình) liên tục
local uiConnection = RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if camera then
        local viewportSize = camera.ViewportSize
        -- Tọa độ: X ở giữa (* 0.5), Y ở vị trí 3/4 (* 0.75)
        statusText.Position = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.55)
    end
end)

--- ==========================================
--- LOGIC CHECK TƯỜNG & AIM
--- ==========================================
local function getWallThickness(origin, targetPos, localChar, targetChar)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {localChar, targetChar}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result1 = workspace:Raycast(origin, targetPos - origin, params)
    if not result1 then return 0 end

    local result2 = workspace:Raycast(targetPos, origin - targetPos, params)
    if not result2 then return 0 end

    return (result1.Position - result2.Position).Magnitude
end

local function getBestTarget(LocalPlayer, Camera)
    local bestTarget = nil
    local bestDistance = math.huge
    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if player.Name == "HickWhither" then continue end
            if player.Name == "KSuMinhUwU" then continue end
            
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if rootPart and humanoid and humanoid.Health > 0 then
                local screenPoint = Camera:WorldToViewportPoint(rootPart.Position)
                if screenPoint.Z > 0 then
                    local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
                    local distance = (screenPos - center).Magnitude
                    
                    if distance < bestDistance then
                        local thickness = getWallThickness(Camera.CFrame.Position, rootPart.Position, LocalPlayer.Character, player.Character)
                        if thickness <= 30 then
                            bestDistance = distance
                            bestTarget = player
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

function AutoAim:startAutoAim()
    -- Cập nhật chữ sang ON khi kích hoạt
    statusText.Text = "Aim : ON"
    statusText.Color = Color3.fromRGB(0, 255, 0) -- Màu xanh lá
    
    if aimConnection then return end

    aimConnection = RunService.RenderStepped:Connect(function()
        if not _G.UI.settings.AutoAim then return end

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer or not LocalPlayer.Character then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local target = getBestTarget(LocalPlayer, camera)
        if not target or not target.Character then return end

        local targetPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
        if not targetPart then return end

        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
    end)
end

function AutoAim:stopAutoAim()
    -- Cập nhật chữ sang OFF khi tắt
    statusText.Text = "Aim : OFF"
    statusText.Color = Color3.fromRGB(255, 0, 0) -- Màu đỏ
    
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
end

_G.UI.addEventHandler("AutoAim", function(state)
    if state then
        AutoAim:startAutoAim()
    else
        AutoAim:stopAutoAim()
    end
end)

_G.UI.addStopHandler(function()
    AutoAim:stopAutoAim()
    -- Dọn dẹp UI khi tắt script hoàn toàn để tránh rác bộ nhớ
    if uiConnection then uiConnection:Disconnect() end
    if statusText then statusText:Remove() end
end)