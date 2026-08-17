---> bounding.lua
--- box, name, weapon and health bar over every living player

local bounding_module = mint.mm.Register({
    id   = "visuals.bounding",
    name = "bounding box",
    desc = "box, name, weapon and health for every player",

    v = {
        enabled      = false,
        category     = mint.enums.category.VISUALS,
        sub_category = "esp",
        risk         = mint.enums.risk.NONE,
    },
})

bounding_module:config({
    box_color = {
        type = "color_picker",
        name = "Box Color",
        desc = "Outline around the player",
        default = Color(255, 255, 255, 255),
        pos = 1
    },
    text_color = {
        type = "color_picker",
        name = "Text Color",
        desc = "Name above the box and weapon below it",
        default = Color(255, 255, 255, 255),
        pos = 2
    },
    hp_high_color = {
        type = "color_picker",
        name = "Health Color (full)",
        desc = "Health bar of a player on full health",
        default = Color(0, 255, 0, 255),
        pos = 3
    },
    hp_low_color = {
        type = "color_picker",
        name = "Health Color (empty)",
        desc = "Health bar of a player about to die",
        default = Color(255, 0, 0, 255),
        pos = 4
    }
})

local corner

---> Screen space bounds of the player's OBB, or nil when the box is not fully in
--- front of the camera. One reused Vector: this runs per player per frame.
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

---> The bar fades between the two picked colours, so the red to green gradient is
--- now just the default pair rather than something baked into the draw. Both ends
--- come in already animated, so a pulsing colour pulses at whatever health it is.
local function health_color(lr, lg, lb, la, hr, hg, hb, ha, hp)
    return lr + (hr - lr) * hp,
           lg + (hg - lg) * hp,
           lb + (hb - lb) * hp,
           la + (ha - la) * hp
end

function bounding_module:OnRender2D()
    local localplayer = LocalPlayer()

    ---> Resolved once per frame rather than per player: the animation is a function
    --- of time alone, so every box would get the same answer anyway.
    local box_r, box_g, box_b, box_a = self:Color("box_color")
    local txt_r, txt_g, txt_b, txt_a = self:Color("text_color")
    local lr, lg, lb, la = self:Color("hp_low_color")
    local hr, hg, hb, ha = self:Color("hp_high_color")

    for _, ply in ipairs(player.GetAll()) do
        if ply == localplayer then continue end
        if not ply:Alive() then continue end

        local x, y, w, h = screen_bounds(ply)
        if not x then continue end

        ---> The black pair frames the box on both sides, so it stays readable
        --- against any background whatever colour is picked.
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2, 1)
        surface.DrawOutlinedRect(x + 1, y + 1, w - 2, h - 2, 1)

        surface.SetDrawColor(box_r, box_g, box_b, box_a)
        surface.DrawOutlinedRect(x, y, w, h, 1)

        local hp = math.Clamp(ply:Health() / math.max(ply:GetMaxHealth(), 1), 0, 1)
        local fill = math.floor(h * hp)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(x - 5, y - 1, 4, h + 2)

        surface.SetDrawColor(health_color(lr, lg, lb, la, hr, hg, hb, ha, hp))
        surface.DrawRect(x - 4, y + h - fill, 2, fill)

        surface.SetTextColor(txt_r, txt_g, txt_b, txt_a)

        ---> Set per player, not once above the loop: the weapon below the box
        --- switches to the smaller font and every later name would inherit it.
        surface.SetFont(mint.fonts.small)

        local name = ply:Nick()
        local tw, th = surface.GetTextSize(name)

        surface.SetTextPos(x + math.floor((w - tw) * 0.5), y - th - 2)
        surface.DrawText(name)

        local wep = weapon_name(ply)
        if wep then
            ---> Measured after the font switch, or the centring is off by whatever
            --- the two fonts differ by.
            surface.SetFont(mint.fonts.smaller)
            local ww = surface.GetTextSize(wep)

            surface.SetTextPos(x + math.floor((w - ww) * 0.5), y + h + 2)
            surface.DrawText(wep)
        end
    end
end

function bounding_module:OnEnable()
    mint.fn.info("bounding box module enabled")
end

function bounding_module:OnDisable()
    mint.fn.info("bounding box module disabled")
end

return bounding_module
