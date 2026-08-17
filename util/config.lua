---> config.lua
--- Schema handling for MODULE:config. Builds the ordered field descriptors the
--- menu draws, and keeps the live value table (module.c) in step with them.
--- Deliberately imgui free: this runs in the client state too, where a module only
--- ever reads its values back out and nothing is drawn.

local config = {}

local function clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

local function round(n, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(n * mult + 0.5) / mult
end

---> Color is a game global and fields are also built from the menu state, so fall
--- back to a bare table. Both read the same way through .r/.g/.b/.a.
function config.color(r, g, b, a)
    if Color then
        return Color(r, g, b, a)
    end

    return { r = r, g = g, b = b, a = a }
end

---> Animation modes color_picker4_ex understands. Kept as the strings the widget
--- speaks, so the value goes out to the picker and comes back without translating.
config.anim = {
    NONE    = "none",
    PULSE   = "pulse",
    RAINBOW = "rainbow",
}

local ANIM_MODES = {
    [config.anim.NONE]    = true,
    [config.anim.PULSE]   = true,
    [config.anim.RAINBOW] = true,
}

---> The widget's own slider runs 0.05 to 5 cycles per second. Storing anything
--- outside that would be a setting the picker could not show or get back to.
local ANIM_SPEED_MIN, ANIM_SPEED_MAX = 0.05, 5

local function to_anim(mode, key)
    if mode == nil then return config.anim.NONE end

    mode = tostring(mode)
    if ANIM_MODES[mode] then return mode end

    if key then
        mint.fn.warn(("config field '%s' has an unknown animation '%s'"):format(key, mode))
    end

    return config.anim.NONE
end

local function to_anim_speed(speed)
    return clamp(round(tonumber(speed) or 1, 2), ANIM_SPEED_MIN, ANIM_SPEED_MAX)
end

---> Accepts Color(...), { r = , g = , b = , a = } and { r, g, b, a }. Always
--- returns a fresh color, so no two values can end up aliasing one declaration.
--- `anim` and `anim_speed` ride along on the colour: Color() is a plain table, and
--- keeping them together means a module still reads one value per field.
local function to_color(value, key)
    if type(value) ~= "table" then return nil end

    local r = value.r or value[1]
    local g = value.g or value[2]
    local b = value.b or value[3]
    if not (r and g and b) then return nil end

    local color = config.color(
        clamp(round(r), 0, 255),
        clamp(round(g), 0, 255),
        clamp(round(b), 0, 255),
        clamp(round(value.a or value[4] or 255), 0, 255)
    )

    color.anim = to_anim(value.anim, key)
    color.anim_speed = to_anim_speed(value.anim_speed)

    return color
end

---> Options are drawn as labels and stored as values, so they have to be strings,
--- and they have to be unique - a duplicate would make two rows indistinguishable
--- and the stored value ambiguous. `lookup` is the set the coercers test against.
local function build_options(field)
    local raw = type(field.options) == "table" and field.options or {}
    local list, lookup, n = {}, {}, 0

    for i = 1, #raw do
        local option = tostring(raw[i])

        if not lookup[option] then
            lookup[option] = true
            n = n + 1
            list[n] = option
        end
    end

    if n == 0 then
        mint.fn.warn(("config field '%s' declares no options"):format(field.key))
        list[1] = "none"
        lookup["none"] = true
    end

    field.options = list
    field.lookup = lookup
end

---> One entry per supported type. `build` normalises the declaration once, at
--- include time; `coerce` pulls a stored value back into what the field allows and
--- is called on every write, so clamping lives in exactly one place per type.
config.types = {}

config.types.boolean = {
    build = function(field)
        field.default = field.default == true
    end,

    coerce = function(field, value)
        return value ~= false
    end,
}

config.types.slider = {
    build = function(field)
        field.min = tonumber(field.min) or 0
        field.max = tonumber(field.max) or 100

        if field.max < field.min then
            field.min, field.max = field.max, field.min
        end

        ---> Nothing fractional was declared, so this is an int slider. `decimals`
        --- is the override for a field that wants fractions off whole bounds.
        if field.decimals == nil then
            local default = tonumber(field.default) or field.min
            local whole = field.min % 1 == 0 and field.max % 1 == 0 and default % 1 == 0

            field.decimals = whole and 0 or 2
        end

        field.default = clamp(
            round(tonumber(field.default) or field.min, field.decimals),
            field.min, field.max
        )
    end,

    coerce = function(field, value)
        value = tonumber(value)
        if not value then return field.default end

        return clamp(round(value, field.decimals), field.min, field.max)
    end,
}

config.types.color_picker = {
    build = function(field)
        field.default = to_color(field.default, field.key)
            or to_color({ 255, 255, 255, 255 }, field.key)

        ---> Declared beside the colour rather than inside it, since Color() has
        --- nowhere to put them: anim = "rainbow", anim_speed = 2.
        if field.anim ~= nil then
            field.default.anim = to_anim(field.anim, field.key)
        end

        if field.anim_speed ~= nil then
            field.default.anim_speed = to_anim_speed(field.anim_speed)
        end
    end,

    coerce = function(field, value)
        return to_color(value, field.key) or to_color(field.default, field.key)
    end,
}

config.types.dropdown_single = {
    build = function(field)
        build_options(field)

        local default = field.default ~= nil and tostring(field.default) or nil

        if default and not field.lookup[default] then
            mint.fn.warn(("config field '%s' defaults to '%s', which is not one of its options")
                :format(field.key, default))
            default = nil
        end

        field.default = default or field.options[1]
    end,

    coerce = function(field, value)
        value = value ~= nil and tostring(value) or nil
        if value and field.lookup[value] then return value end

        return field.default
    end,
}

config.types.dropdown_multiple = {
    build = function(field)
        build_options(field)

        local declared = field.default
        field.default = config.types.dropdown_multiple.coerce(field, declared)

        if type(declared) == "table" and #declared ~= #field.default then
            mint.fn.warn(("config field '%s' defaults to options it does not declare")
                :format(field.key))
        end
    end,

    ---> Rebuilt in option order every time, so the preview text and the stored
    --- value never depend on the order the ticks happened to be made in.
    coerce = function(field, value)
        local wanted = {}

        if type(value) == "table" then
            for i = 1, #value do
                wanted[tostring(value[i])] = true
            end
        end

        local list, n = {}, 0

        for i = 1, #field.options do
            local option = field.options[i]

            if wanted[option] then
                n = n + 1
                list[n] = option
            end
        end

        return list
    end,
}

---> The channels to actually draw with this frame, animation applied. Returns
--- 0..255 the way the stored colour reads, so it drops straight into
--- surface.SetDrawColor.
---
--- The picker only ever runs in the menu state, so the animation cannot come back
--- out of it - imgui.color_anim is what evaluates it here, in whatever state the
--- module happens to be drawing in. An lje-imgui too old to have that function
--- leaves the colour static rather than erroring.
function config.animate(value)
    if type(value) ~= "table" then return 255, 255, 255, 255 end

    local mode = value.anim
    if not mode or mode == config.anim.NONE then
        return value.r, value.g, value.b, value.a
    end

    if not (imgui and imgui.color_anim) then
        return value.r, value.g, value.b, value.a
    end

    local r, g, b, a = imgui.color_anim(
        value.r / 255, value.g / 255, value.b / 255, value.a / 255,
        mode, value.anim_speed
    )

    return r * 255, g * 255, b * 255, a * 255
end

---> Pulls a stored value back into what the field allows. nil means "never set",
--- which is the declared default rather than an empty value.
function config.coerce(field, value)
    if value == nil then
        value = field.default
    end

    return config.types[field.type].coerce(field, value)
end

local function build_field(key, declaration, owner)
    if type(declaration) ~= "table" then
        mint.fn.warn(("%s: config field '%s' is not a table"):format(owner, key))
        return
    end

    local handler = config.types[declaration.type]

    if not handler then
        mint.fn.warn(("%s: config field '%s' has an unknown type '%s'")
            :format(owner, key, tostring(declaration.type)))
        return
    end

    ---> Copied, so a live field can never write back into the module file's table
    --- and a re-include always starts from the declaration as written.
    local field = {}
    for k, v in pairs(declaration) do
        field[k] = v
    end

    field.key  = key
    field.name = tostring(declaration.name or key)
    field.pos  = tonumber(declaration.pos)

    handler.build(field)

    return field
end

---> Turns a declaration table into the ordered descriptor list. `pos` decides the
--- rows, then the key breaks ties: pairs() alone would reshuffle the menu every
--- frame, the same way it would have reshuffled the navbar.
function config.build(schema, owner)
    local fields, n = {}, 0

    if type(schema) ~= "table" then
        mint.fn.warn(("%s declared a config that is not a table"):format(owner))
        return fields
    end

    for key, declaration in pairs(schema) do
        local field = build_field(key, declaration, owner)

        if field then
            n = n + 1
            fields[n] = field
        end
    end

    table.sort(fields, function(a, b)
        if a.pos ~= b.pos then
            return (a.pos or math.huge) < (b.pos or math.huge)
        end

        return a.key < b.key
    end)

    return fields
end

---> Builds the value table against a field list. Values for fields that survived a
--- re-include are kept, ones the file no longer declares are dropped, and new
--- fields come in at their default.
function config.values(fields, existing)
    local values = {}

    for i = 1, #fields do
        local field = fields[i]
        values[field.key] = config.coerce(field, existing and existing[field.key])
    end

    return values
end

mint.config = config
return config
