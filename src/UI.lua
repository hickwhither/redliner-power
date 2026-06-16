local UI = _G.offlineservice("UI")

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Private State

UI.settings = {}
UI.handlers = {}
UI.stopHandlers = {}
UI.buttonCount = 0
UI._connections = {}
UI.bindings = {}
UI.keybindButtons = {}
UI.toggleButtons = {}
UI.awaitingKeybind = nil

-- References
local screenGui, mainFrame, scrollingFrame

----------------------------------------------------------------
-- CÔNG CỤ TẠO NHANH (INTERNAL)
----------------------------------------------------------------

local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    return inst
end

----------------------------------------------------------------
-- PHƯƠNG THỨC PUBLIC
----------------------------------------------------------------

-- Đăng ký sự kiện khi nhấn nút
function UI.addEventHandler(name, fn)
    if type(fn) ~= "function" then return end
    UI.handlers[name] = UI.handlers[name] or {}
    table.insert(UI.handlers[name], fn)
end

-- Đăng ký hành động khi dừng script
function UI.addStopHandler(fn)
    if type(fn) ~= "function" then return end
    table.insert(UI.stopHandlers, fn)
end

local function setToggleState(name, value)
    UI.settings[name] = value

    local button = UI.toggleButtons[name]
    if button then
        button.BackgroundColor3 = value and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 45, 45)
    end

    local list = UI.handlers[name]
    if list then
        for _, fn in ipairs(list) do
            task.spawn(pcall, fn, value)
        end
    end
end

-- Hàm tạo nút toggle với ô keybind
function UI.createButton(name)
    if UI.settings[name] ~= nil then return end -- Tránh tạo trùng

    UI.buttonCount = UI.buttonCount + 1
    UI.settings[name] = false

    local function getBtnColor()
        return UI.settings[name] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 45, 45)
    end

    local row = create("Frame", {
        Name = name .. "_Row",
        Parent = scrollingFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        LayoutOrder = UI.buttonCount
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = row
    })

    local btn = create("TextButton", {
        Name = name,
        Parent = row,
        Size = UDim2.new(0.72, 0, 1, 0),
        BackgroundColor3 = getBtnColor(),
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = true
    })

    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
    create("UIStroke", {
        Thickness = 1,
        Color = Color3.new(1, 1, 1),
        Transparency = 0.8,
        Parent = btn
    })

    local bindBtn = create("TextButton", {
        Name = name .. "_Keybind",
        Parent = row,
        Size = UDim2.new(0, 80, 0.9, 0),
        BackgroundColor3 = Color3.fromRGB(70, 70, 70),
        BorderSizePixel = 0,
        Text = "Bind",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        AutoButtonColor = true
    })

    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bindBtn })
    create("UIStroke", {
        Thickness = 1,
        Color = Color3.new(1, 1, 1),
        Transparency = 0.8,
        Parent = bindBtn
    })

    local function getKeybindText()
        local boundKey = UI.bindings[name]
        return boundKey and boundKey.Name or "Bind"
    end

    local function updateBindText(isWaiting)
        bindBtn.Text = isWaiting and "Press key..." or getKeybindText()
    end

    btn.MouseButton1Click:Connect(function()
        setToggleState(name, not UI.settings[name])
    end)

    bindBtn.MouseButton1Click:Connect(function()
        if UI.awaitingKeybind then
            return
        end
        UI.awaitingKeybind = name
        updateBindText(true)
    end)

    UI.toggleButtons[name] = btn
    UI.keybindButtons[name] = bindBtn
    updateBindText(false)

    return btn
end

-- Dừng toàn bộ script
local function stopScript()
    for _, fn in ipairs(UI.stopHandlers) do task.spawn(pcall, fn) end
    for _, conn in ipairs(UI._connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(UI._connections)
    if screenGui then screenGui:Destroy() end
    _G.UI.settings = {}
    _G.running = false
end

-- Đóng/Mở UI
local function toggleUI()
    mainFrame.Visible = not mainFrame.Visible
end

----------------------------------------------------------------
-- KHỞI TẠO GIAO DIỆN
----------------------------------------------------------------

screenGui = create("ScreenGui", {
    Name = "Internal_UI",
    ResetOnSpawn = false,
    Parent = CoreGui
})

mainFrame = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0.17, 0, 0.4, 0),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    AnchorPoint = Vector2.new(0.5, 0.8),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    Active = true,
    Draggable = true,
    Parent = screenGui
})

create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = mainFrame })
create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(60, 60, 60), Parent = mainFrame })

local title = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    Text = "INTERNAL CONTROL",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = mainFrame
})

scrollingFrame = create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -135),
    Position = UDim2.new(0, 10, 0, 80),
    BackgroundTransparency = 1,
    ScrollBarThickness = 2,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = mainFrame
})

create("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = scrollingFrame
})

-- Nút Stop phía dưới cùng
local stopBtn = create("TextButton", {
    Size = UDim2.new(1, -20, 0, 35),
    Position = UDim2.new(0, 10, 1, -45),
    BackgroundColor3 = Color3.fromRGB(150, 40, 40),
    Text = "STOP SCRIPT",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Parent = mainFrame
})
create("UICorner", { Parent = stopBtn })
stopBtn.MouseButton1Click:Connect(stopScript)

----------------------------------------------------------------
-- TẠO CÁC NÚT THEO YÊU CẦU
----------------------------------------------------------------

UI.createButton("Fullbright")
UI.createButton("NoFog")
UI.createButton("AutoAim")

----------------------------------------------------------------
-- PHÍM TẮT
----------------------------------------------------------------

table.insert(UI._connections, UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if UI.awaitingKeybind then
        local waitingName = UI.awaitingKeybind
        if input.KeyCode == Enum.KeyCode.Escape then
            UI.bindings[waitingName] = nil
        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
            UI.bindings[waitingName] = input.KeyCode
        end

        local bindBtn = UI.keybindButtons[waitingName]
        if bindBtn then
            bindBtn.Text = UI.bindings[waitingName] and UI.bindings[waitingName].Name or "Bind"
        end
        UI.awaitingKeybind = nil
        return
    end

    if input.KeyCode == Enum.KeyCode.Backquote then
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            stopScript()
        else
            toggleUI()
        end
        return
    end

    for name, keyCode in pairs(UI.bindings) do
        if keyCode == input.KeyCode then
            setToggleState(name, not UI.settings[name])
            break
        end
    end
end))

print("✅ UI Loaded: [Backquote] để ẩn/hiện, [Ctrl + Backquote] để dừng.")
