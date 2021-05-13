local function keyCode(key, modifiers)
   modifiers = modifiers or {}
   return function()
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), true):post()
      hs.timer.usleep(1000)
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), false):post()
   end
end

local function remapKey(modifiers, key, keyCode)
   hs.hotkey.bind(modifiers, key, keyCode, nil, keyCode)
end

-- カーソル移動
remapKey({'ctrl'}, 'f', keyCode('right'))
remapKey({'ctrl'}, 'b', keyCode('left'))
remapKey({'ctrl'}, 'n', keyCode('down'))
remapKey({'ctrl'}, 'p', keyCode('up'))

-- kana/abc
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

eventtap:start()

