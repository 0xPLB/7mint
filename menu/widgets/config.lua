---> config widget
--- draws a module's declared config fields, one row each

local widget = {}

local ITEM_WIDTH = 150
local INDENT = 14

---> One drawer per config.types entry. Each writes straight into the module's value
--- table and returns whether its own row is hovered, so widget.draw can put the
--- tooltip up after the row is finished rather than inside a popup.
local drawers = {}

drawers.boolean = function(field, values)
    local changed, value = imgui.checkbox(field.name, values[field.key])

    if changed then
        values[field.key] = value
    end

    return imgui.is_item_hovered()
end

drawers.slider = function(field, values)
    imgui.set_next_item_width(ITEM_WIDTH)

    local slider = field.decimals == 0 and imgui.slider_int or imgui.slider_float
    local changed, value = slider(field.name, values[field.key], field.min, field.max)
    local hovered = imgui.is_item_hovered()

    ---> Back through coerce, so the clamp and the rounding rule live with the field
    --- instead of being repeated here.
    if changed then
        values[field.key] = mint.config.coerce(field, value)
    end

    return hovered
end

---> color_picker4_ex is lje-imgui's own control: swatch, four slots, and a popup
--- with a colour tab and an animation tab. Threading the animation back in on every
--- call is what makes the popup remember it - the widget's internal fallback only
--- lasts as long as the process.
---
--- color_edit4 covers an lje-imgui too old to have it, so the menu still draws.
drawers.color_picker = function(field, values)
    local color = values[field.key]
    local changed, r, g, b, a, mode, speed

    if imgui.color_picker4_ex then
        changed, r, g, b, a, mode, speed = imgui.color_picker4_ex(
            field.name,
            color.r / 255, color.g / 255, color.b / 255, color.a / 255,
            color.anim, color.anim_speed
        )
    else
        changed, r, g, b, a = imgui.color_edit4(
            field.name,
            color.r / 255, color.g / 255, color.b / 255, color.a / 255
        )

        mode, speed = color.anim, color.anim_speed
    end

    local hovered = imgui.is_item_hovered()

    if changed then
        values[field.key] = mint.config.coerce(field, {
            r = r * 255,
            g = g * 255,
            b = b * 255,
            a = a * 255,
            anim = mode,
            anim_speed = speed,
        })
    end

    return hovered
end

drawers.dropdown_single = function(field, values)
    imgui.set_next_item_width(ITEM_WIDTH)

    local open = imgui.begin_combo(field.name, values[field.key])
    ---> Read before the popup contents are submitted, they become the last item.
    local hovered = imgui.is_item_hovered()

    if open then
        for i = 1, #field.options do
            local option = field.options[i]

            if imgui.selectable(option, option == values[field.key]) then
                values[field.key] = option
            end
        end

        imgui.end_combo()
    end

    return hovered
end

local function preview(selected)
    if #selected == 0 then return "none" end
    return table.concat(selected, ", ")
end

---> Checkboxes inside the combo rather than selectables: the binding has no way to
--- pass SelectableFlags_NoAutoClosePopups, so a selectable would shut the popup on
--- the first tick and multi select would be one option per open.
drawers.dropdown_multiple = function(field, values)
    local selected = values[field.key]

    imgui.set_next_item_width(ITEM_WIDTH)

    local open = imgui.begin_combo(field.name, preview(selected))
    local hovered = imgui.is_item_hovered()

    if open then
        local ticked = {}
        for i = 1, #selected do
            ticked[selected[i]] = true
        end

        local dirty = false

        for i = 1, #field.options do
            local option = field.options[i]
            local changed, on = imgui.checkbox(option, ticked[option] == true)

            if changed then
                ticked[option] = on or nil
                dirty = true
            end
        end

        imgui.end_combo()

        ---> Rebuilt in option order, matching what config.coerce would produce, so
        --- the preview does not reorder itself as ticks are made.
        if dirty then
            local list, n = {}, 0

            for i = 1, #field.options do
                local option = field.options[i]

                if ticked[option] then
                    n = n + 1
                    list[n] = option
                end
            end

            values[field.key] = list
        end
    end

    return hovered
end

---> Every field of one module, indented under it. push_id scopes the whole block to
--- the module, so two modules that happen to name a field the same do not collide
--- on one imgui id.
function widget.draw(module)
    local fields = module.fields
    if not fields or #fields == 0 then return end

    imgui.push_id(module.id)
    imgui.indent(INDENT)

    for i = 1, #fields do
        local field = fields[i]
        local drawer = drawers[field.type]

        if drawer and drawer(field, module.c) and field.desc then
            imgui.set_tooltip(field.desc)
        end
    end

    imgui.unindent(INDENT)
    imgui.pop_id()
end

return widget
