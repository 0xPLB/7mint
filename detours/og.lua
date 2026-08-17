local function getFnAddr(fn)
  return ffi.mem.unwrap_userdata(ffi.mem.upvalue(fn, 1))
end

local renderCapture = getFnAddr(render.Capture)
renderCaptureDetour = ffi.detour.create(
  renderCapture,
  [[
int (*original)(lua_State* L);
int captureCounter = 0;

int detour(lua_State* L) {
  captureCounter++;
  return original(L);
}
]]
)

local captureCounterPtr = renderCaptureDetour:get("captureCounter")
lje.con_printf("captureCounterPtr: 0x%X", captureCounterPtr or 0)
ffi.mem.try_write_u32(captureCounterPtr, 0) -- Initialize counter to 0

local lastCaptureCount = 0
local lastCaptureTime = 0
local function checkCapture()
  local currentCount = ffi.mem.try_read_u32(captureCounterPtr)
  lje.con_printf("Current capture count: %d", currentCount or -1)
  if currentCount ~= nil and currentCount > lastCaptureCount then
    lastCaptureCount = currentCount
    lastCaptureTime = SysTime()
  end
end