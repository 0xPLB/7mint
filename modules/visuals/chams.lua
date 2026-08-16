---> chams.lua

local chams_module = mint.mm.Register({
    id   = "visuals.chams",
    name = "chams",
    desc = "chams",

    v = {
        enabled      = false,
        category     = mint.enums.category.VISUALS,
        sub_category = "CHAMS",
        risk         = mint.enums.risk.NONE,
    },
})

function chams_module:OnRender3D()
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then continue end
        
        render.SuppressEngineLighting(true)
        render.MaterialOverride(mint.materials.glow)
        ply:DrawModel()
        render.MaterialOverride(nil)
        render.SuppressEngineLighting(false)
    end
end

local corner

local function screen_bounds(ply)
    corner = corner or Vector()
    local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
    local pos = ply:GetPos()

    local x1, y1 = math.huge, math.huge
    local x2, y2 = -math.huge, -math.huge

    for i = 0, 7 do
        corner.x = pos.x + (i % 2 == 0 and mins.x or maxs.x)
        corner.y = pos.y + (i % 4 < 2 and mins.y or maxs.y)
        corner.z = pos.z + (i < 4 and mins.z or maxs.z)

        local screen = corner:ToScreen()
        if not screen.visible then return end

        if screen.x < x1 then x1 = screen.x end
        if screen.x > x2 then x2 = screen.x end
        if screen.y < y1 then y1 = screen.y end
        if screen.y > y2 then y2 = screen.y end
    end

    x1, y1 = math.floor(x1), math.floor(y1)

    return x1, y1, math.floor(x2) - x1, math.floor(y2) - y1
end

local function weapon_name(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    local name = wep:GetPrintName()
    if not name or name == "<MISSING SWEP PRINT NAME>" then
        return wep:GetClass()
    end

    ---> print names are often untranslated language tokens
    if name:sub(1, 1) == "#" then
        name = language.GetPhrase(name:sub(2))
    end

    return name
end

function chams_module:OnRender2D()
    local localplayer = LocalPlayer()

    surface.SetFont("small")

    for _, ply in ipairs(player.GetAll()) do
        if ply == localplayer then continue end
        if not ply:Alive() then continue end

        local x, y, w, h = screen_bounds(ply)
        if not x then continue end

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2, 1)
        surface.DrawOutlinedRect(x + 1, y + 1, w - 2, h - 2, 1)

        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawOutlinedRect(x, y, w, h, 1)

        local hp = math.Clamp(ply:Health() / math.max(ply:GetMaxHealth(), 1), 0, 1)
        local fill = math.floor(h * hp)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(x - 5, y - 1, 4, h + 2)

        surface.SetDrawColor(255 - 255 * hp, 255 * hp, 0, 255)
        surface.DrawRect(x - 4, y + h - fill, 2, fill)

        local name = ply:Nick()
        local tw, th = surface.GetTextSize(name)

        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(x + math.floor((w - tw) * 0.5), y - th - 2)
        surface.DrawText(name)

        local wep = weapon_name(ply)
        if wep then
            local ww = surface.GetTextSize(wep)
            surface.SetFont("smaller")

            surface.SetTextPos(x + math.floor((w - ww) * 0.5), y + h + 2)
            surface.DrawText(wep)
        end
    end
end

function chams_module:OnEnable()
    mint.fn.info("chams module enabled")
end

function chams_module:OnDisable()
    mint.fn.info("chams module disabled")
end

return chams_module
