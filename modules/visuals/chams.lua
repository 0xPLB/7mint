---> chams.lua

local chams_module = mint.mm.Register({
    id   = "visuals.chams",
    name = "chams",
    desc = "chams",

    v = {
        enabled      = false,
        category     = mint.enums.category.VISUALS,
        sub_category = "esp",
        risk         = mint.enums.risk.NONE,
    },
})

chams_module:config({
    enemy_color = {
        type = "color_picker",
        name = "Enemy Color",
        desc = "Colour the chams are drawn in",
        default = Color(255, 255, 255),
    }
})

function chams_module:OnRender3D()
    local r, g, b, a = self:Color("enemy_color")

    render.SuppressEngineLighting(true)
    render.MaterialOverride(mint.materials.glow)
    render.SetColorModulation(r / 255, g / 255, b / 255)
    render.SetBlend(a / 255)

    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then continue end

        ply:DrawModel()
    end

    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
    render.SuppressEngineLighting(false)
end

function chams_module:OnEnable()
    mint.fn.info("chams module enabled")
end

function chams_module:OnDisable()
    mint.fn.info("chams module disabled")
end

return chams_module
