


local navbar = mint.fn.include("menu/widgets/navbar.lua")
local backdrop = mint.fn.include("menu/menustate/mbackdrop.lua")
local wm = mint.fn.include("menu/wm.lua")

imgui.set_style({
  colors = {
    button = { 0.2, 0.2, 0.2, 1.0 },
		button_hovered = { 0.3, 0.3, 0.3, 1.0 },
		button_active = { 0.1, 0.1, 0.1, 1.0 },
  },
	border = {
		frame = 1
	},
})

lje.vm.add_pre_engine_call_hook(function(func, nargs, nresults, name, gm, ...)
    if name == "DrawOverlay" and not lje.state.client then
        imgui.new_frame()
        backdrop.draw()
        navbar.draw()
        wm.draw()
        imgui.render()
    end
end, lje.state.menu)