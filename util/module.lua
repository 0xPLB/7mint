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

    ---> config: `fields` is what the menu draws, `c` is what the module reads.
    --- Both are filled in by MODULE:config, which the file calls after Register.
    meta.fields = data.fields or nil
    meta.c = data.c or nil

    return setmetatable(meta, self)
end

---> Declares the module's config.
function MODULE:config(schema)
    self.fields = mint.config.build(schema, self.id)
    self.c = mint.config.values(self.fields, self.c)

    return self.c
end

---> Channels of a colour field with its animation applied, ready to hand to
--- surface.SetDrawColor. Reading self.c.<key> directly still gives the colour the
--- user picked, which is the one to persist.
function MODULE:Color(key)
    return mint.config.animate(self.c and self.c[key])
end

---> Field descriptor by key, or nil when the module never declared it.
function MODULE:GetField(key)
    local fields = self.fields
    if not fields then return end

    for i = 1, #fields do
        if fields[i].key == key then
            return fields[i]
        end
    end
end

---> True when `option` is ticked in a dropdown_multiple field. That value is an
--- array, so this saves every caller writing the same loop.
function MODULE:HasOption(key, option)
    local value = self.c and self.c[key]
    if type(value) ~= "table" then return false end

    for i = 1, #value do
        if value[i] == option then return true end
    end

    return false
end

---> Puts every field back to its declared default.
function MODULE:ResetConfig()
    if not self.fields then return end
    self.c = mint.config.values(self.fields, nil)
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