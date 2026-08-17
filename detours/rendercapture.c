int (*original)(lua_State* L);
int captureCounter = 0;

int detour(lua_State* L) {
  captureCounter++;
  return original(L);
}
