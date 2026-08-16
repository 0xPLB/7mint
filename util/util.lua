--- verbal print for info  
--- @param str string
function mint.fn.info(str)
    lje.con_printf("[$#7d25e8{7mint}] [$#196eff{inf}] [$#696969{%s}] %s", os.date("%H:%M:%S"), tostring(str))
end

--- verbal print for warn
--- @param str any
function mint.fn.warn(str)
    lje.con_printf("[$#7d25e8{7mint}] [$#ff9b19{wrn}] [$#696969{%s}] %s", os.date("%H:%M:%S"), tostring(str))
end

--- verbal print for error
--- @param str any
function mint.fn.error(str)
    lje.con_printf("[$#7d25e8{7mint}] [$#ff193f{err}] [$#696969{%s}] %s", os.date("%H:%M:%S"), tostring(str))
end

--- verbal print for debug
--- @param str any
function mint.fn.debug(str)
    lje.con_printf("[$#7d25e8{7mint}] [$#76f5c8{dbg}] [$#696969{%s}] %s", os.date("%H:%M:%S"), tostring(str))
end

function mint.fn.isInGame()
    if lje.state.client then
        return true
    end

    return false
end

