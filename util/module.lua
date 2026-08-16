---> module.lua
--- represents a "module"

MODULE = {}
MODULE.__index = MODULE

---> Creates a new module
function MODULE:New(data)
    local meta = {}

    ---> base descriptors
    meta.id   = data.id   or "nil"
    meta.name = data.name or "nil"
    meta.desc = data.desc or "nil"

    ---> metadata
    meta.v = data.v or {}
    meta.v.enabled = meta.v.enabled or false
    meta.v.noDisable = meta.v.noDisable or false

    meta.v.category = meta.v.category or "nil"
    meta.v.sub_category = meta.v.sub_category or "nil"
    
    meta.v.risk = meta.v.risk or mint.enums.risk.NONE

    ---> Descriptors are built in the menu state, where no game globals exist yet.
    --- Set by mm.Load once the client state is up.
    meta.v.loaded = false

    ---> config
    meta.c = data.c or nil

    return setmetatable(meta, self)
end

---> Marks the module live. Called by mm.Load once the client state is up, never
--- from the menu state.
function MODULE:Load()
    if self.v.loaded then return end
    self.v.loaded = true

    ---> Toggled on from the menu before the game existed, so OnEnable never fired.
    if self.v.enabled and self.OnEnable then
        self:OnEnable()
    end
end

---> Drops the module back to descriptor-only when the client state goes away, so
--- the next game re-runs Setup instead of reusing dead references. OnDisable is
--- deliberately skipped: the game state is already tearing down by this point.
function MODULE:Unload()
    self.v.loaded = false
end

---> Enables the module.
function MODULE:Enable()
    if self.v.enabled then return end
    self.v.enabled = true

    ---> Toggling from the menu only records the flag. MODULE:Load fires OnEnable
    --- later, once the game state can actually service it.
    if self.v.loaded and self.OnEnable then
        self:OnEnable()
    end
end

---> Disables the module, with an exception towards can_disable.
function MODULE:Disable()
    if self.v.noDisable then return end
    if not self.v.enabled then return end
    self.v.enabled = false

    if self.v.loaded and self.OnDisable then
        self:OnDisable()
    end
end

---> Toggles the module off/on, with an exception towards can_disable.
function MODULE:Toggle()
    if self.v.noDisable then return end
    if self.v.enabled then
        self:Disable()
    else
        self:Enable()
    end
end