local AutoAim = _G.offlineservice("AutoAim")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local aimConnection = nil

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
            if rootPart and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                local screenPoint = Camera:WorldToViewportPoint(rootPart.Position)
                if screenPoint.Z > 0 then
                    local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
                    local distance = (screenPos - center).Magnitude
                    if distance < bestDistance then
                        bestDistance = distance
                        bestTarget = player
                    end
                end
            end
        end
    end

    return bestTarget
end

function AutoAim:startAutoAim()
    if aimConnection then return end

    aimConnection = RunService.RenderStepped:Connect(function()
        if not _G.UI.settings.AutoAim then
            return
        end

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer or not LocalPlayer.Character then
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local target = getBestTarget(LocalPlayer, camera)
        if not target or not target.Character then
            return
        end

        -- Nhắm vào đầu (Head) sẽ tự nhiên hơn khi dùng Camera, nếu không có Head thì dùng HumanoidRootPart
        local targetPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
        if not targetPart then
            return
        end

        --- Thay đổi ở đây: Giữ nguyên vị trí Camera hiện tại, chỉ xoay hướng nhìn về targetPart
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
    end)
end

function AutoAim:stopAutoAim()
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
end)