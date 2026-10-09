local AutoAim = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local aimConnection = nil
local enabled = false
local destroyed = false
local statusText = nil
local uiConnection = nil

local function updateStatus()
    if statusText then
        statusText.Text = enabled and "Aim : ON" or "Aim : OFF"
        statusText.Color = enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
end

-- The controller calls init even while disabled to display the OFF status.
function AutoAim.init()
    if destroyed or statusText then return end
    statusText = Drawing.new("Text")
    statusText.Visible = true
    statusText.Center = true
    statusText.Outline = true
    statusText.Size = 22
    statusText.Font = 2
    updateStatus()

    uiConnection = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if camera then
            local viewportSize = camera.ViewportSize
            statusText.Position = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.55)
        end
    end)
end

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
            if player.Name == "BekS41z" then continue end

            if player.Character.Parent ~= workspace.Entities then return end
            
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

function AutoAim.enable()
    if destroyed or enabled then return end
    enabled = true
    updateStatus()

    aimConnection = RunService.RenderStepped:Connect(function()
        if not enabled then return end

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

function AutoAim.disable()
    enabled = false
    updateStatus()

    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
end

function AutoAim.destroy()
    if destroyed then return end
    destroyed = true
    AutoAim.disable()
    if uiConnection then
        uiConnection:Disconnect()
        uiConnection = nil
    end
    if statusText then
        statusText:Remove()
        statusText = nil
    end
end

function AutoAim.isEnabled()
    return enabled
end

return AutoAim
