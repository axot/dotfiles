local logger = hs.logger.new("MySpoon", "info")

-- Helper Functions
local function has_value(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function logMapping(metaFrom, keyFrom, metaTo, keyTo)
    logger.d("Mapping " ..
        tostring(metaFrom) .. tostring(keyFrom) .. " -> " ..
        tostring(metaTo) .. tostring(keyTo))
end

-- Key Mapping and Remapping Functions
local function pressFn(mods, key)
    if key == nil then
        key = mods
        mods = {}
    end
    return function() hs.eventtap.keyStroke(mods, key, 1000) end
end

local function appRemap(metaFrom, keyFrom, metaTo, keyTo)
    local fn = pressFn(metaTo, keyTo)
    return hs.hotkey.new(metaFrom, keyFrom, fn, nil, fn)
end

local function keymapToHotkeys(keymap)
    local hotkeys = {}
    for _, item in pairs(keymap) do
        local metaFrom, keyFrom, metaTo, keyTo = table.unpack(item)
        table.insert(hotkeys, appRemap(metaFrom, keyFrom, metaTo, keyTo))
        logMapping(metaFrom, keyFrom, metaTo, keyTo)
    end
    return hotkeys
end

-- App Watcher Functions
local keyboardHotkeys
local kanaEventTap
local kanaHandlingEnabled = false
local mouseSideButtonEventTap
local ctrlIsDown = false

local function enableKeys()
    for _, hk in pairs(keyboardHotkeys) do
        hk:enable()
    end
end

local function disableKeys()
    for _, hk in pairs(keyboardHotkeys) do
        hk:disable()
    end
end

function enableKanaAbc()
    logger.d("enable kana")

    if not kanaEventTap then
        local prevKeyCode
        local prevFlags
        local keyMap = hs.keycodes.map

        local function isCmdKeyUp(e)
            return not e:getFlags()['cmd'] and e:getType() == hs.eventtap.event.types.flagsChanged
        end

        local function isCmdKeyAlone(flags)
            if flags then
                return flags['cmd'] and not flags['shift'] and not flags['alt'] and not flags['ctrl']
            end
            return false
        end

        local function processKeyUp(e)
            if prevKeyCode == keyMap['cmd'] then
                hs.alert.closeAll()
                hs.alert.show('ABC')
                hs.eventtap.keyStroke({}, keyMap['eisu'], 0)
            elseif prevKeyCode == keyMap['rightcmd'] then
                hs.alert.closeAll()
                hs.alert.show('Kana')
                hs.eventtap.keyStroke({}, keyMap['kana'], 0)
            end
        end

        kanaEventTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown},
            function(e)
                local keyCode = e:getKeyCode()
                local flags = e:getFlags()

                if flags['ctrl'] then
                    ctrlIsDown = true
                else
                    ctrlIsDown = false
                end

                if not isCmdKeyUp(e) then
                    prevKeyCode = keyCode
                    prevFlags = flags
                    return false
                end

                if isCmdKeyUp(e) and isCmdKeyAlone(prevFlags) then
                    processKeyUp(e)
                end

                prevKeyCode = keyCode
                prevFlags = flags

                return true
            end)
    end

    kanaEventTap:start()
    kanaHandlingEnabled = true
end

function disableKanaAbc()
    logger.d("disable kana")
    kanaEventTap:stop()
    kanaHandlingEnabled = false
end

function appWatcherFn(appTitles)
    return function(name, type, app)
        if type == hs.application.watcher.activated and has_value(appTitles, name) then
            local items = hs.tabs.tabWindows(app)

            if items and #(items) > 0 then
                local title = items[1]:title()

                if kanaHandlingEnabled and string.find(title, 'DynamoDB共同編集') then
                    hs.alert.closeAll()
                    hs.alert.show("disable key remap")
                    disableKeys()
                    disableKanaAbc()
                end
            end
        elseif type == hs.application.watcher.activated then
            if not kanaHandlingEnabled then
                hs.alert.closeAll()
                hs.alert.show("enable key remap")
                enableKeys()
                enableKanaAbc()
            end
        end
    end
end

local function createAppWatcher(appTitles, keymap)
    keyboardHotkeys = keymapToHotkeys(keymap)
    enableKeys()
    enableKanaAbc()

    local watcher = hs.application.watcher.new(appWatcherFn(appTitles))
    watcher:start()

    return watcher
end

-- Mouse Button Logic
local function handleSideButtonEvent(e)
    local btn = e:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)

    if btn == 2 then  -- Middle Mouse Button
        if ctrlIsDown then
            hs.spaces.toggleMissionControl()
            hs.alert.show("Activated Mission Control")
        end
        return false
    elseif btn == 3 then
        if ctrlIsDown then  -- Ctrl + Mouse Button 3
            hs.eventtap.keyStroke({"fn", "ctrl"},"left",100)
            hs.alert.show("Moved Desktop Left")
        else  -- Mouse Button 3 without Ctrl
            hs.eventtap.keyStroke({ "cmd" }, "[")
            hs.alert.show("Goto Previous Page")
        end
        return true
    elseif btn == 4 then
        if ctrlIsDown then  -- Ctrl + Mouse Button 4
            hs.eventtap.keyStroke({"fn", "ctrl"},"right",100)
            hs.alert.show("Moved Desktop Right")
        else  -- Mouse Button 4 without Ctrl
            hs.eventtap.keyStroke({ "cmd" }, "]")
            hs.alert.show("Goto Next Page")
        end
        return true
    else
        return false
    end
end

local function initializeMouseEventTap()
    mouseSideButtonEventTap = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown}, handleSideButtonEvent)
    mouseSideButtonEventTap:start()
end

-- Initialization Logic
local function initialize()
    createAppWatcher(
        { 'WorkSpacesClient.macOS', 'Visual Studio', 'Google Chrome' },
        {
            { { 'ctrl' }, 'f', {}, 'right' },
            { { 'ctrl' }, 'b', {}, 'left' },
            { { 'ctrl' }, 'n', {}, 'down' },
            { { 'ctrl' }, 'p', {}, 'up' },
        }
    )

    initializeMouseEventTap()
end

initialize()

checkTapStatus = hs.timer.new(60, function()  -- checks every 10 seconds
    if not mouseSideButtonEventTap:isEnabled() then
        print("Event tap has been disabled.")
    else
        print("Event tap has been enabled.")
    end
end)

checkTapStatus:start()

local function switchToChineseInput()
    hs.alert.show("SCIM.ITABC")
    hs.keycodes.currentSourceID("com.apple.inputmethod.SCIM.ITABC")
end

hs.hotkey.bind({"ctrl"}, "space", switchToChineseInput)
