--[[
    7mint by pngmeow
]]

mint = {
    var = {
        state = 0,
        capture = 0
    },
    -- module manager
    mm = {
        modules = {}
    },
    enums = {},
    fn = {},
    materials = {},
    fonts = {}
}

mint.enums.states = {
    BOOT = 0, 
    MAIN = 1
}

mint.enums.category = {
    ["COMBAT"] = 1,
    ["MOVEMENT"] = 2,
    ["VISUALS"] = 3,
    ["MISC"] = 4,
    ["LUA"] = 5
}

mint.enums.risk = {
    ["NONE"] = 1,
    ["DETECTED"] = 2
}

function mint.fn.include(path)
    lje.con_printf("[$#7d25e8{7mint-include}] including %s", path)
    return lje.include(path)
end

mint.fn.include("util/util.lua")

---> Before module.lua: MODULE:config leans on mint.config.
mint.fn.include("util/config.lua")
mint.fn.include("util/module.lua")
mint.fn.include("util/module_manager.lua")
mint.fn.include("menu/init.lua")

---> Descriptors for the menu to draw and toggle. The hook bodies come along too,
--- but nothing dispatches them until we are in the client state.
mint.mm.Include()

mint.fn.info("$$#7d25e8{7mint} by pngmeow")
mint.fn.info("report bugs to $$#7d25e8{https://github.com/0xPLB/7mint}")