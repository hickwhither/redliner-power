local Fullbright = require("../mods/Fullbright")
local NoFog = require("../mods/NoFog")
local AutoAim = require("../mods/AutoAim")
local ESP = require("../mods/ESP")
local UI = {}
local library
local destroyLibrary

function UI.start(unload)
    library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/download/1.1.0/main.lua"))()
    destroyLibrary = library.Destroy
    -- Route the library's titlebar close through the same application lifecycle.
    library.Destroy = unload
    local window = library:CreateWindow({
        Title = "Redliner",
        SubTitle = "Internal controls",
        Size = UDim2.fromOffset(580, 460),
        TabWidth = 140,
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.Backquote,
    })
    local tab = window:AddTab({ Title = "Features", Icon = "settings" })

    local function addFeature(name, feature, defaultKey)
        local toggle = tab:AddToggle(name, {
            Title = name,
            Default = false,
            Callback = function(value)
                if value then feature.enable() else feature.disable() end
            end,
        })
        tab:AddKeybind(name .. "Key", {
            Title = name .. " key",
            Default = defaultKey or "None",
            Mode = "Toggle",
            Callback = function()
                -- Use the toggle value so mouse and keyboard actions stay in sync.
                toggle:SetValue(not toggle.Value)
            end,
        })
    end

    addFeature("Fullbright", Fullbright)
    addFeature("NoFog", NoFog)
    addFeature("AutoAim", AutoAim, "V")
    addFeature("ESP", ESP)
    tab:AddButton({ Title = "STOP / Unload", Callback = unload })
    tab:AddKeybind("UnloadKey", {
        Title = "Unload key",
        Default = "None",
        Mode = "Toggle",
        Callback = unload,
    })
    window:SelectTab(1)
end

function UI.destroy()
    if library and not library.Unloaded then destroyLibrary(library) end
end

return UI
