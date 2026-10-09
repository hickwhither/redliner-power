local Lighting = game:GetService("Lighting")
local LightingOwnership = {}
local owners = {}
local properties = {}

local function apply(property, state)
    local value = state.original
    local priority = -math.huge
    for _, owner in pairs(owners) do
        if owner.values[property] ~= nil and owner.priority > priority then
            value = owner.values[property]
            priority = owner.priority
        end
    end
    -- One writer per property; equality also prevents reentrant lock callbacks.
    if Lighting[property] ~= value then
        Lighting[property] = value
    end
end

function LightingOwnership.acquire(name, values, priority)
    if owners[name] then return end
    owners[name] = { values = values, priority = priority }
    for property in pairs(values) do
        local state = properties[property]
        if not state then
            state = { original = Lighting[property], count = 0 }
            properties[property] = state
            state.connection = Lighting:GetPropertyChangedSignal(property):Connect(function()
                if properties[property] == state then
                    apply(property, state)
                end
            end)
        end
        state.count += 1
        apply(property, state)
    end
end

function LightingOwnership.release(name)
    local owner = owners[name]
    if not owner then return end
    owners[name] = nil
    for property in pairs(owner.values) do
        local state = properties[property]
        state.count -= 1
        if state.count == 0 then
            state.connection:Disconnect()
            properties[property] = nil
            Lighting[property] = state.original
        else
            apply(property, state)
        end
    end
end

function LightingOwnership.destroy()
    for name in pairs(owners) do
        LightingOwnership.release(name)
    end
end

return LightingOwnership
