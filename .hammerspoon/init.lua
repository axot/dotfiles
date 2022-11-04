local logger = hs.logger.new("MySpoon", "debug")

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function pressFn(mods, key)
    if key == nil then
        key = mods
        mods = {}
    end

    return function() hs.eventtap.keyStroke(mods, key, 1000) end
end

function appRemap(mods, key, remapMods, remapKey)
    fn = pressFn(remapMods, remapKey)
    return hs.hotkey.new(mods, key, fn, nil, fn)
end

-- Translate user input keymap to hs.hotkey functions
function keymapToHotkeys(keymap)
    local hotkeys = {}

    for i, item in pairs(keymap) do
        metaFrom = item[1]
        keyFrom = item[2]
        metaTo = item[3]
        keyTo = item[4]

        table.insert(hotkeys, appRemap(metaFrom, keyFrom, metaTo, keyTo))

        logger.d("Mapping " ..
            tostring(metaFrom) .. tostring(keyFrom) .. " -> " ..
            tostring(metaTo) .. tostring(keyTo))
    end

    return hotkeys
end

function bind_exclude(appTitles, keymap)
    appTitles_str = ""
    for k, v in pairs(appTitles) do
        appTitles_str = appTitles_str .. k .. ", "
    end

    logger.d("Found binding for app " .. appTitles_str)

    local eventtap = nil
    local enabled = false
    local hotkeys = keymapToHotkeys(keymap)

    local function enableKeys()
        for i, hotkey in pairs(hotkeys) do
            hotkey:enable()
        end
    end

    local function disableKeys()
        for i, hotkey in pairs(hotkeys) do
            hotkey:disable()
        end
    end

    local function enableKanaAbc()
        logger.d("enable kana")

        if eventtap == nil then
            local prevKeyCode
            local keyMap = hs.keycodes.map

            eventtap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown}, function (e)
                local keyCode = e:getKeyCode()
                local isCmdKeyUp = not(e:getFlags()['cmd']) and e:getType() == hs.eventtap.event.types.flagsChanged

                if not isCmdKeyUp then
                    prevKeyCode = keyCode
                    return
                elseif isCmdKeyUp and prevKeyCode == keyMap['cmd'] then
                    hs.alert.closeAll()
                    hs.alert.show('ABC')
                    hs.eventtap.keyStroke({}, keyMap['eisu'], 0)
                elseif isCmdKeyUp and prevKeyCode == keyMap['rightcmd'] then
                    hs.alert.closeAll()
                    hs.alert.show('Kana')
                    hs.eventtap.keyStroke({}, keyMap['kana'], 0)
                end
                prevKeyCode = keyCode
            end)
        end

        eventtap:start()
        enabled = true
    end

    local function disableKanaAbc()
        logger.d("disable kana")
        eventtap:stop()
        enabled = false
    end

    enableKeys()
    enableKanaAbc()

    windowtap = hs.application.watcher.new(function (name, type, app)
        if type == hs.application.watcher.activated and has_value(appTitles, name) then
            items = hs.tabs.tabWindows(app)

            if #(items) > 0 then
                title = items[1]:title()
            end

            if enabled and string.find(items[1]:title(), 'DynamoDB') then
                hs.alert.closeAll()
                hs.alert.show("disable key remap")
                disableKeys()
                disableKanaAbc()
            end
        elseif type == hs.application.watcher.activated then
            if enabled == false then
                hs.alert.closeAll()
                hs.alert.show("enable key remap")
                enableKeys()
                enableKanaAbc()
            end
        end
    end)

    windowtap:start()
end

-- カーソル移動
bind_exclude({'WorkSpacesClient.macOS', 'Visual Studio', 'Google Chrome'}, {
    { {'ctrl'}, 'f', {}, 'right' },
    { {'ctrl'}, 'b', {}, 'left' },
    { {'ctrl'}, 'n', {}, 'down' },
    { {'ctrl'}, 'p', {}, 'up' },
})
