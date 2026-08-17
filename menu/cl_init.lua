---> menu/cl_init.lua
local ui = {
    backdrop = "menu/menustate/mbackdrop.lua",
    wm = "menu/wm.lua",
    navbar = "menu/widgets/navbar.lua"
}

for i,v in pairs(ui) do
    ui[i] = mint.fn.include(v)
end

hook.pre("lje-util/render", "menurender", function()
    if mint.var.capture then return end
    imgui.new_frame()
    ui.navbar.draw()
    ui.wm.draw()
    imgui.render()
    ui.backdrop.draw()
end)

-- THIS WILL RENDER.
hook.pre("lje-util/render", "menurenxder", function()
    cam.Start2D()
    render.PushRenderTarget(lje.util.rendertarget)
    surface.DrawRect(20, 20, 200, 200)
    render.PopRenderTarget()
    cam.End2D()
end)

-- THIS WONT RENDER.
hook.pre("lje-util/render", "TEST", function()
    surface.DrawRect(400, 400, 200, 200)
end)
