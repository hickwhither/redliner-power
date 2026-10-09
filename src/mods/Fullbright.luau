local LightingOwnership = require("../core/LightingOwnership")

local Fullbright = {}
local enabled = false
local destroyed = false

function Fullbright.enable()
    if destroyed or enabled then return end
    LightingOwnership.acquire("Fullbright", {
        Brightness = 5,
        ClockTime = 12,
        FogEnd = 1e10,
        GlobalShadows = false,
        Ambient = Color3.fromRGB(255, 255, 255),
        OutdoorAmbient = Color3.fromRGB(255, 255, 255),
    }, 1)
    enabled = true
end

function Fullbright.disable()
    if not enabled then return end
    enabled = false
    LightingOwnership.release("Fullbright")
end

function Fullbright.destroy()
    if destroyed then return end
    destroyed = true
    Fullbright.disable()
end

function Fullbright.isEnabled()
    return enabled
end

return Fullbright
