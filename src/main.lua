if _G.running then
    return
end
_G.running = true
_G.doingSomething = false

local baseUrl = "https://raw.githubusercontent.com/hickwhither/redliner-power/refs/heads/main/src/"

local function fetch(name)
    print(name)
    local ok, res = pcall(function() return loadstring(game:HttpGet(baseUrl .. name))() end)
    if not ok then
        warn("Error loading module " .. name .. ": " .. tostring(res))
    end
    return res
end

_G.class = fetch("pack/class.lua")
_G.offlineservice = fetch("pack/offlineservice.lua")

fetch("Utils.lua")
fetch("UI.lua")
-- fetch("ESP.lua")

fetch("mods/Fullbright.lua")
fetch("mods/NoFog.lua")
fetch("mods/AutoAim.lua")

print("OK All modules loaded!")
