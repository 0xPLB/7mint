---> hooks.lua
--- engine events -> module manager dispatch

local mm = mint.mm

hook.pre("lje-util/render", "OnRender2D", function()    
    mm.Dispatch("OnRender2D")
end)

hook.pre("lje-util/render", "OnRender3D", function()
    cam.Start({type = "3D"})
    render.PushRenderTarget(lje.util.rendertarget)

    mm.Dispatch("OnRender3D")

    render.PopRenderTarget()
    cam.End()
end)

hook.pre("CalcView", "OnCalcView", function(ply, pos, angles, fov)
    mm.Dispatch("OnCalcView", ply, pos, angles, fov)
end)

hook.pre("Think", "OnThink", function()
    mm.Dispatch("OnThink")
end)

hook.pre("CreateMove", "OnCreateMove", function(cmd)
    mm.Dispatch("OnCreateMove", cmd)
end)

hook.pre("Shutdown", "OnShutdown", function(cmd)
    
end)

gameevent.Listen("player_hurt")
hook.pre("player_hurt", "OnPlayerHurt", function(data)
    mm.Dispatch("OnPlayerHurt", data)
end)

gameevent.Listen("entity_killed")
hook.pre("entity_killed", "OnEntityDeath", function(data)
    mm.Dispatch("OnEntityDeath", data)
end)