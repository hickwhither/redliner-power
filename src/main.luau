local Runtime = require("./core/Runtime")
if not Runtime.acquire() then return end

local controller
local ui
local stopped = false
local function unload()
    if stopped then return end
    stopped = true
    if controller then
        local ok, message = pcall(controller.destroy)
        if not ok then warn(message) end
    end
    if ui then
        local ok, message = pcall(ui.destroy)
        if not ok then warn(message) end
    end
    Runtime.release()
end

local ok, message = xpcall(function()
    controller = require("./core/Controller")
    ui = require("./ui/UI")
    ui.start(unload)
    controller.init()
end, debug.traceback)

if not ok then
    unload()
    warn("Redliner initialization failed: " .. tostring(message))
end
