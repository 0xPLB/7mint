
local wm = mint.fn.include("menu/wm.lua")
local navbar = {}
local w, h = imgui.get_monitor_size()

-- pairs() walks the enum in hash order, so flatten it once into value order and
-- keep the row stable.
local categories = {}
for name, value in pairs(mint.enums.category) do
  categories[#categories + 1] = { name = name, value = value }
end
table.sort(categories, function(a, b) return a.value < b.value end)

function navbar.draw()
  if imgui.is_visible() then
    imgui.set_next_window_pos(0, 0)
    imgui.set_next_window_size(w, 34)
    imgui.begin_window("##7mint-navbar", true, 47)
    -- Place the cursor once; same_line keeps every following button on the row.
    imgui.set_cursor_pos(5, 6)
    for i, category in ipairs(categories) do
      if i > 1 then
        imgui.same_line(0, 6)
      end
      
      if imgui.button(category.name) then
        wm.toggle(category.name, category.value)
      end
    end
    imgui.end_window()
  end
end

return navbar
