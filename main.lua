mint.var.state = mint.enums.states.MAIN

local fonts = {}
local fontdata = {}

function mint.fn.font(name, data) --> 
    local cached = fonts[name]
    if (cached) then
        return cached
    end

    local id = lje.util.random_string()
    surface.CreateFont(id, data)
    fonts[name] = id
    fontdata[id] = data

    return id
end

function mint.fn.fontdata(id)
    return fontdata[id]
end

mint.materials = {
    glow = CreateMaterial(lje.util.random_string(), "VertexLitGeneric", {
        ["$basetexture"] = "vgui/white_additive",
        ["$bumpmap"] = "vgui/white_additive",
        ["$model"] = "1",
        ["$nocull"] = "0",
        
        ["$selfillum"] = "1",
        ["$selfIllumFresnel"] = "1",
        ["$selfIllumFresnelMinMaxExp"] = "[0.0 0.3 0.6]",
        
        ["$selfillumtint"] = "[0 0 0]" -- only fresnel shows
    }),
    white = Material("trails/physbeam")
}

mint.fonts = {
    small = mint.fn.font("small", {
        font = "Verdana",
        size = 13,
        antialias = false,
        outline = true
    }),
    smaller = mint.fn.font("smaller", {
        font = "Verdana",
        size = 12,
        antialias = false,
        outline = true
    })
}

mint.fn.info("$#505050{Loading stuff into main}")
mint.fn.include("detours/rendercapture.lua")

mint.fn.include("util/hooks.lua")
mint.fn.include("menu/cl_init.lua")



---> Re-include the module files over the descriptors boot registered. Register
--- hands back the live instance, so whatever the menu toggled on survives and the
mint.mm.Include()
mint.mm.Load()

---> Client state is going away, so drop the game-side half. v.enabled survives in
--- the descriptor, and rejoining re-runs every Setup against the new state.
lje.env.on_cleanup(function()
    mint.mm.Unload()
end)
