catalogue = {
  -- ============================================
  -- =================== SYSTEM =================
  -- ============================================
  {
    name = "SYSTEM",
    modules = include("lib/modules/system_modules")
  },
  -- ============================================
  -- =================== ENGINE =================
  -- ============================================
  {
    name = "ENGINE",
    modules = include("lib/modules/engine_modules")
  },
  -- ============================================
  -- =================== MIDI ===================
  -- ============================================
  {
    name = "MIDI",
    modules = include("lib/modules/midi_modules")
  },
  -- ============================================
  -- =================== CTRL ===================
  -- ============================================
  {
    name = "CTRL",
    modules = include("lib/modules/ctrl_modules")
  },
  -- ============================================
  -- =================== SCUT ===================
  -- ============================================
  --{
  --  name = "S_CUT",
  --  modules = include("lib/modules/softcut_modules")
  --},
  -- =============================================
  -- =================== LOGIC ===================
  -- =============================================
  {
    name = "LOGIC",
    modules = include("lib/modules/logic_modules")
  }
}

category_names = {}
module_names = {}
for i,c in pairs(catalogue) do
  category_names[i] = c.name
  module_names[i] = {[1]="none"}
  for j,m in pairs(c.modules) do
    module_names[i][j+1] = m.name
  end
end