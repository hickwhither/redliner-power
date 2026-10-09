local LightingOwnership = require("../core/LightingOwnership")

local NoFog = {}
local enabled = false
local destroyed = false

function NoFog.enable()
    if destroyed or enabled then return end
    LightingOwnership.acquire("NoFog", {
        FogEnd = 100000,
        FogStart = 99000,
    }, 2)
    enabled = true
end

function NoFog.disable()
    if not enabled then return end
    enabled = false
    LightingOwnership.release("NoFog")
end

function NoFog.destroy()
    if destroyed then return end
    destroyed = true
    NoFog.disable()
end

function NoFog.isEnabled()
    return enabled
end

return NoFog
