---> window manager
if mint.wm then return mint.wm end

local wm = {}

-- name -> { name, id }. Populated by the navbar, drained by wm.draw.
wm.windows = {}

function wm.open(name, id)
    wm.windows[name] = { name = name, id = id }
end

function wm.close(name)
    wm.windows[name] = nil
end

function wm.is_open(name)
    return wm.windows[name] ~= nil
end

function wm.toggle(name, id)
    if wm.is_open(name) then
        wm.close(name)
    else
        wm.open(name, id)
    end
end

-- Buckets a category's modules by sub_category. `order` keeps the headers in
-- registration order, since pairs() over `groups` would shuffle them per frame.
local function group_by_subcategory(category)
    local groups = {}
    local order = {}
    local modules = mint.mm.GetAll()

    for i = 1, #modules do
        local module = modules[i]
        if module.v.category == category then
            local key = module.v.sub_category
            local group = groups[key]

            if not group then
                group = {}
                groups[key] = group
                order[#order + 1] = key
            end

            group[#group + 1] = module
        end
    end

    return groups, order
end

-- One collapsing header per sub_category, with that group's modules inside.
local function draw_subcategories(win)
    local groups, order = group_by_subcategory(win.id)

    for i = 1, #order do
        local key = order[i]

        -- ## suffix keeps the id unique per window, the label itself is shown.
        if imgui.collapsing_header(key .. "##" .. win.name .. i) then
            imgui.indent(8)

            local group = groups[key]
            for j = 1, #group do
                local module = group[j]
                local changed, enabled = imgui.checkbox(module.name .. "##" .. module.id, module.v.enabled)

                if changed then
                    if enabled then
                        module:Enable()
                    else
                        module:Disable()
                    end
                end
            end

            imgui.unindent(8)
        end
    end
end

-- Runs every frame, outside any other window's begin/end pair.
function wm.draw()
    if imgui.is_visible() then
        for name, win in pairs(wm.windows) do
            local _, open = imgui.begin_window("##" .. win.name .. win.id, true, 1)
            imgui.text(win.name)
            imgui.separator()
            draw_subcategories(win)
            imgui.end_window()
            if not open then
                wm.close(name)
            end
        end
    end
end

mint.wm = wm
return wm
