local backdrop = {}
local script_info = lje.script.info()
local w, h = imgui.get_monitor_size()
local surface 
if lje.state.menu then
    surface = lje.secure.pull("surface", lje.state.menu)
else
    surface = lje.secure.pull("surface", lje.state.client)
end


function backdrop.draw()
    if imgui.is_visible() then
        surface.SetDrawColor(0, 0, 0, 230)
        surface.DrawRect(0, 0, w, h)
        surface.SetFont("DefaultFixedDropShadow")
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(15, h - 30)
        surface.DrawText(string.format("7mint-%s by pngmeow", script_info.version))
        surface.SetTextPos(15, h - 20)
        surface.DrawText("[https://github.com/0xPLB/7mint]")

    end
end

return backdrop