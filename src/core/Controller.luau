local features = {
    AutoAim = require("../mods/AutoAim"),
    ESP = require("../mods/ESP"),
    Fullbright = require("../mods/Fullbright"),
    NoFog = require("../mods/NoFog"),
}
local Utils = require("./Utils")
local Controller = {}
local destroyed = false

function Controller.init()
    if destroyed then return end
    features.AutoAim.init()
end

function Controller.destroy()
    if destroyed then return end
    destroyed = true
    for _, feature in pairs(features) do
        local ok, message = pcall(feature.destroy)
        if not ok then warn(message) end
    end
    local ok, message = pcall(Utils.destroy)
    if not ok then warn(message) end
end

return Controller
