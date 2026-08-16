---> test.lua
--- dummy module, prints on every think

local test = mint.mm.Register({
    id   = "misc.test",
    name = "Test",
    desc = "prints a line every think",

    v = {
        enabled      = true,
        category     = mint.enums.category.MISC,
        sub_category = "test stuff",
        risk         = mint.enums.risk.NONE,
    },
})

function test:OnThink()
    mint.fn.debug("hi from test module")
end

function test:OnEnable()
    mint.fn.info("test module enabled")
end

function test:OnDisable()
    mint.fn.info("test module disabled")
end

return test
