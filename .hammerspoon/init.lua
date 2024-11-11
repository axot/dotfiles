--- Logger initialization
-- @local
local logger = hs.logger.new("MySpoon", "debug")

--- Helper Functions

--- Check if a table contains a specific value
-- @param tab Table to search in
-- @param val Value to search for
-- @return boolean True if value is found, false otherwise
local function has_value(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

--- Log key mapping information
-- @param metaFrom Source modifier keys
-- @param keyFrom Source key
-- @param metaTo Destination modifier keys
-- @param keyTo Destination key
local function logMapping(metaFrom, keyFrom, metaTo, keyTo)
    logger.d("Mapping " ..
        tostring(metaFrom) .. tostring(keyFrom) .. " -> " ..
        tostring(metaTo) .. tostring(keyTo))
end

--- Key Mapping and Remapping Functions

--- Create a function to simulate key press
-- @param mods Modifier keys (optional)
-- @param key Key to press
-- @return function Function that simulates the key press
local function pressFn(mods, key)
    if key == nil then
        key = mods
        mods = {}
    end
    return function() hs.eventtap.keyStroke(mods, key, 1000) end
end

--- Create a hotkey for app-specific remapping
-- @param metaFrom Source modifier keys
-- @param keyFrom Source key
-- @param metaTo Destination modifier keys
-- @param keyTo Destination key
-- @return hs.hotkey Hotkey object
local function appRemap(metaFrom, keyFrom, metaTo, keyTo)
    local fn = pressFn(metaTo, keyTo)
    return hs.hotkey.new(metaFrom, keyFrom, fn, nil, fn)
end

--- Convert keymap to hotkeys
-- @param keymap Table of key mappings
-- @return table Table of hotkey objects
local function keymapToHotkeys(keymap)
    local hotkeys = {}
    for _, item in pairs(keymap) do
        local metaFrom, keyFrom, metaTo, keyTo = table.unpack(item)
        table.insert(hotkeys, appRemap(metaFrom, keyFrom, metaTo, keyTo))
        logMapping(metaFrom, keyFrom, metaTo, keyTo)
    end
    return hotkeys
end

--- App Watcher Functions
local keyboardHotkeys
local kanaEventTap
local kanaHandlingEnabled = false
local mouseSideButtonEventTap
local ctrlIsDown = false

--- Enable all keyboard hotkeys
local function enableKeys()
    for _, hk in pairs(keyboardHotkeys) do
        hk:enable()
    end
end

--- Disable all keyboard hotkeys
local function disableKeys()
    for _, hk in pairs(keyboardHotkeys) do
        hk:disable()
    end
end

--- Enable Kana/ABC input switching
function enableKanaAbc()
    logger.d("enable kana")

    if not kanaEventTap then
        local prevKeyCode
        local prevFlags
        local keyMap = hs.keycodes.map

        --- Check if CMD key is released
        -- @param e Event object
        -- @return boolean True if CMD key is released, false otherwise
        local function isCmdKeyUp(e)
            return not e:getFlags()['cmd'] and e:getType() == hs.eventtap.event.types.flagsChanged
        end

        --- Check if only CMD key was pressed
        -- @param flags Event flags
        -- @return boolean True if only CMD was pressed, false otherwise
        local function isCmdKeyAlone(flags)
            if flags then
                return flags['cmd'] and not flags['shift'] and not flags['alt'] and not flags['ctrl']
            end
            return false
        end

        --- Process key up event for CMD keys
        -- @param e Event object
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

                return false
            end)
    end

    kanaEventTap:start()
    kanaHandlingEnabled = true
end

--- Disable Kana/ABC input switching
function disableKanaAbc()
    logger.d("disable kana")
    kanaEventTap:stop()
    kanaHandlingEnabled = false
end

--- Detect tab title for different applications
-- @param app hs.application object
-- @return string|nil The title of the active tab or nil if not found
local function detectTabTitle(app)
    local appName = app:name()
    local detectors = {
        ["Google Chrome"] = function()
            local script = [[
                tell application "Google Chrome"
                    get title of active tab of first window
                end tell
            ]]
            local ok, result = hs.osascript.applescript(script)
            return ok and result or nil
        end,
        ["Safari"] = function()
            local script = [[
                tell application "Safari"
                    get name of current tab of first window
                end tell
            ]]
            local ok, result = hs.osascript.applescript(script)
            return ok and result or nil
        end,
        ["Firefox"] = function()
            local script = [[
                tell application "Firefox"
                    get name of active tab of first window
                end tell
            ]]
            local ok, result = hs.osascript.applescript(script)
            return ok and result or nil
        end,
        -- Add more detectors for other applications as needed
    }

    local detector = detectors[appName]
    if detector then
        return detector()
    end

    -- Fallback for applications without specific detectors
    return app:focusedWindow() and app:focusedWindow():title() or nil
end

--- Create app watcher function
-- @param appTitles Table of app titles to watch
-- @param disableKeyRemapTitle Title that triggers key remap disabling
-- @return function App watcher function
function appWatcherFn(appTitles, disableKeyRemapTitle)
    return function(name, type, app)
        if type == hs.application.watcher.activated and has_value(appTitles, name) then
            local title = detectTabTitle(app)

            if title and kanaHandlingEnabled and string.find(title, disableKeyRemapTitle) then
                hs.alert.closeAll()
                hs.alert.show("disable key remap")
                disableKeys()
                disableKanaAbc()
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

--- Create and start app watcher
-- @param appTitles Table of app titles to watch
-- @param keymap Table of key mappings
-- @param disableKeyRemapTitle Title that triggers key remap disabling
-- @return hs.application.watcher App watcher object
local function createAppWatcher(appTitles, keymap, disableKeyRemapTitle)
    keyboardHotkeys = keymapToHotkeys(keymap)
    enableKeys()
    enableKanaAbc()

    local watcher = hs.application.watcher.new(appWatcherFn(appTitles, disableKeyRemapTitle))
    watcher:start()

    return watcher
end

--- Mouse Button Logic

--- Handle side button events
-- @param e Event object
-- @return boolean True if event was handled, false otherwise
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

--- Initialize mouse event tap
local function initializeMouseEventTap()
    mouseSideButtonEventTap = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown}, handleSideButtonEvent)
    mouseSideButtonEventTap:start()
end

--- Initialization Logic

--- Initialize the application
local function initialize()
    createAppWatcher(
        { 'WorkSpacesClient.macOS', 'Visual Studio', 'Google Chrome', 'iPhone Mirroring', 'Safari', 'Firefox'},
        {
            { { 'ctrl' }, 'f', {}, 'right' },
            { { 'ctrl' }, 'b', {}, 'left' },
            { { 'ctrl' }, 'n', {}, 'down' },
            { { 'ctrl' }, 'p', {}, 'up' },
        },
        'DynamoDB共同編集'
    )

    initializeMouseEventTap()
end

initialize()

--- Timer to check tap status
checkTapStatus = hs.timer.new(60, function()  -- checks every 60 seconds
    if not mouseSideButtonEventTap:isEnabled() then
        print("Event tap has been disabled.")
    else
        print("Event tap has been enabled.")
    end
end)

checkTapStatus:start()

--- Switch to Chinese input method
local function switchToChineseInput()
    hs.alert.show("SCIM.ITABC")
    hs.keycodes.currentSourceID("com.apple.inputmethod.SCIM.ITABC")
end

hs.hotkey.bind({"ctrl"}, "space", switchToChineseInput)
