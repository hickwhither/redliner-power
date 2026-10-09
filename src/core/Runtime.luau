local Runtime = {}
-- Only the execution guard is global so separate runs cannot create duplicate UIs.
local environment = getgenv and getgenv() or _G
local key = "__REDLINER_POWER_RUNNING"

function Runtime.acquire()
    if environment[key] then return false end
    environment[key] = true
    return true
end

function Runtime.release()
    environment[key] = nil
end

return Runtime
