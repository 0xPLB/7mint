---> module_manager.lua
--- global module registry + hook dispatcher, lives in mint.mm

local mm = mint.mm

mm.modules = mm.modules or {} ---> array, registration order
mm.byId    = {}               ---> id -> module
mm.cache   = {}               ---> hook name -> array of modules implementing it

---> Every module file, in menu order. Included from boot for the descriptors the
--- menu draws, and again from main for the logic. Add new modules here, not in
--- boot.lua.
mm.paths = {
    "modules/misc/test.lua",
    "modules/visuals/chams.lua",
}

---> Collects every module that implements `name`. Cached until the module set changes.
local function collect(name)
    local list = {}
    local n = 0

    for i = 1, #mm.modules do
        local module = mm.modules[i]
        if type(module[name]) == "function" then
            n = n + 1
            list[n] = module
        end
    end

    mm.cache[name] = list
    return list
end

---> Refreshes a descriptor from a re-included file. Only the static half is taken:
--- enabled and loaded belong to the running module, not to the file.
local function refresh(module, data)
    module.name = data.name or module.name
    module.desc = data.desc or module.desc
    module.c    = module.c or data.c

    local v = data.v or {}
    module.v.category     = v.category     or module.v.category
    module.v.sub_category = v.sub_category or module.v.sub_category
    module.v.risk         = v.risk         or module.v.risk
    module.v.noDisable    = v.noDisable    or module.v.noDisable
end

---> Registers a module. Accepts a MODULE instance or a raw data table.
--- A second registration of the same id is a re-include rather than a mistake:
--- the descriptor is refreshed and the live instance handed back, so the file's
--- `function module:OnThink()` attaches to the module the menu already holds.
function mm.Register(module)
    local existing = mm.byId[module.id]

    if existing then
        if existing ~= module then
            refresh(existing, module)
        end

        return existing
    end

    if getmetatable(module) ~= MODULE then
        module = MODULE:New(module)
    end

    mm.modules[#mm.modules + 1] = module
    mm.byId[module.id] = module
    mm.cache = {} ---> module set changed, drop the hook lists

    return module
end

---> Strips the hook methods a module file attached, so a re-include cannot leave
--- a hook behind that the file no longer defines. MODULE's own methods live on
--- the metatable and are not touched, nor is runtime state like a cached flag.
local function strip(module)
    for key, value in pairs(module) do
        if type(value) == "function" then
            module[key] = nil
        end
    end
end

---> Includes every module file. Called from boot.lua in the menu state, where it
--- only produces descriptors - the hook bodies never run there - and again from
--- main.lua, where the same files bring the logic. Safe to call repeatedly.
function mm.Include()
    for i = 1, #mm.paths do
        mint.fn.include(mm.paths[i])
    end

    mm.cache = {} ---> the files may have added or dropped hooks
end

---> Hot reload. Drops every module's hooks and re-runs the files over the live
--- descriptors, so enable flags and config survive the reload.
function mm.Reload()
    for i = 1, #mm.modules do
        strip(mm.modules[i])
    end

    mm.Include()
end

---> Marks every module live. Called from main.lua once the client state is up, so
--- the enable flags the menu has been writing all along finally take effect.
function mm.Load()
    for i = 1, #mm.modules do
        mm.modules[i]:Load()
    end
end

---> Tears the modules back down to descriptors when the client state closes, so
--- the flags survive into the menu but the game-side logic does not.
function mm.Unload()
    for i = 1, #mm.modules do
        mm.modules[i]:Unload()
    end
end

---> Fetches a single module by id.
function mm.Get(id)
    return mm.byId[id]
end

---> Every registered module. Read only, this is the live array.
function mm.GetAll()
    return mm.modules
end

---> New array of the currently enabled modules.
function mm.GetEnabled()
    local list = {}
    local n = 0

    for i = 1, #mm.modules do
        local module = mm.modules[i]
        if module.v.enabled then
            n = n + 1
            list[n] = module
        end
    end

    return list
end

---> New array of the currently disabled modules.
function mm.GetDisabled()
    local list = {}
    local n = 0

    for i = 1, #mm.modules do
        local module = mm.modules[i]
        if not module.v.enabled then
            n = n + 1
            list[n] = module
        end
    end

    return list
end

---> Calls MODULE:<name>(...) on every enabled module that defines it.
function mm.Dispatch(name, ...)
    local list = mm.cache[name] or collect(name)

    for i = 1, #list do
        local module = list[i]
        if module.v.enabled and module.v.loaded then
            module[name](module, ...)
        end
    end
end

return mm
