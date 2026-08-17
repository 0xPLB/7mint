local HIDE_TIME = 5

if (renderCaptureDetour) then
    renderCaptureDetour:remove()
    renderCaptureDetour = nil
end

collectgarbage("collect")

local renderCapture = ffi.mem.unwrap_userdata(ffi.mem.upvalue(render.Capture, 1))
local detour, err = ffi.detour.create(renderCapture, lje.env.read_script_file("detours/rendercapture.c"))

if (not detour) then
    mint.fn.error(string.format("render.Capture detour failed: %s", tostring(err)))
    return
end

renderCaptureDetour = detour

local counterPtr = detour:get("captureCounter")
local lastCount = 0
local lastCaptureTime = 0

mint.var.capture = false
ffi.mem.try_write_u32(counterPtr, 0)

hook.pre("PostRender", "7mint/rendercapture", function()
    local count = ffi.mem.try_read_u32(counterPtr) or 0

    if (count > lastCount) then
        lastCount = count
        lastCaptureTime = SysTime()
    end

    mint.var.capture = (SysTime() - lastCaptureTime) < HIDE_TIME
end)

lje.env.on_cleanup(function()
    hook.removepre("PostRender", "7mint/rendercapture")
    detour:remove()
    renderCaptureDetour = nil
end)
