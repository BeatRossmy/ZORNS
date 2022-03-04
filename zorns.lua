engine.name = 'PolyPerc'

er = require "lib.er"
local UI = require "ui"
musicutil = require "musicutil"
tabutil = require "tabutil"

include("lib/grid_ui")

include("lib/redraw_subroutines")

include("lib/helpers")

include("lib/connections")

include("lib/zorns_module")

include("lib/module_catalogue")

scale_names = {
  "Major",
  "Natural Minor",
  "Minor Pentatonic"
}
scales = {}
for i,n in pairs(scale_names) do scales[i] = musicutil.generate_scale (0, n, 10) end

category_list = UI.ScrollingList.new (38, 8, 2, category_names)
module_list = UI.ScrollingList.new (70, 8, 2, module_names[category_list.index])

value_dial = UI.Dial.new(32-11, 40-11, 22, 0.25, 0, 1, 0.01, 0, {},'')

dirty_screen = true

module_param = 1

connected_midi_devices = {}
midi_device_names = {}
for _,d in pairs(midi.devices) do
  if d.port then
    table.insert(connected_midi_devices,midi.connect(d.port))
    midi_device_names[#connected_midi_devices] = d.name
    --connected_midi_devices[d.port] = midi.connect(d.port)
    --midi_device_names[d.port] = d.name
  end
end

select_module = function (x,y)
  for _,m in pairs(MODULES) do
    if m:in_area(x,y) then
      local p = m:get_cell(x,y)
      local t = m:get_type(p)
      return SEL.new(x,y,m,p,t)
    end
  end
  return nil
end

create_connection = function (a,b)
  if a.type==b.type or a.type=="value" or b.type=="value" then return nil end
  local src = a.type=="output" and a or b
  local trgt = a.type=="input" and a or b
  local con = CON.new(src,trgt,1)
  return con
end

set_connection = function (con)
  con.target.module:add_connection(con.target.port_id,con)
end

restore_connection = function (s_id,s_c,t_id,t_c,s)
  local src = SEL.new(nil,nil,MODULES[s_id],s_c,"output")
  local trgt = SEL.new(nil,nil,MODULES[t_id],t_c,"input")
  local con = create_connection(src,trgt)
  con.strength = s
  return con
end

selection = nil

MAX_ID=0
MODULES = {}
CTRL_RATE = 1/128 -- 1/128

ctrl_loop = function ()
  main_clock:update()
  for _,m in pairs(MODULES) do
    -- 1. calculate output states
    m:ctrl_rate()
    -- 2. propagate values to inputs
    m:propagate_signals()
  end
end

function redraw()
  if not dirty_screen then return end
  print("redraw")
  screen.clear()
  screen.level(15)
  if SEL.is_module(selection) then
    redraw_module_settings(selection) -- < == ERROR
    redraw_module_port(selection)
  
  elseif SEL.is_connection(selection) then
    redraw_connection(selection)
  
  elseif SEL.is_empty(selection) then
    category_list:redraw ()
    module_list:redraw ()
  
  elseif not selection then
    redraw_no_selection()
  end
  
  screen.update()
  dirty_screen = false
end

function init ()
  
  -- load patch if available
  stored_patch = tabutil.load(_path.data.."/zorns/patch.txt")
  if stored_patch then
    -- RESTORE MODULES
    for i,m in pairs(stored_patch) do
      print("=>",i)
      local mo = restore_module(m)
      MODULES[mo.id] = mo
      MAX_ID = mo.id
    end
    -- RESTORE CONNECTIONS
    for i,m in pairs(stored_patch) do
      print("=>",i)
      restore_connections(m)
    end
  end
  
  metro.init(ctrl_loop,CTRL_RATE):start()
  
  metro.init(draw_loop, 1/15):start()
  
  clock.run(
    function()
      while true do
        clock.sleep(1/15)
        redraw()
      end
    end  
  )
end

function key (n,z)
  dirty_screen = true
  if n==1 and z==1 then
    print("delete button")
    local deleted = false
    
    if SEL.is_input(selection) then
      local port = SEL.get_port(selection)
       if port.source then
         -- DELETE CONNECTION
         port.source = nil
         deleted = true
       end
    end
    if not deleted and SEL.is_module(selection) then
      -- DELETE MODULE
      --[[for i,m in pairs(MODULES) do
        if m==selection.module then
          MODULES[i] = nil
          selection = nil
        end
      end--]]
      MODULES[selection.module.id] = nil
      selection = nil
    end
  
  elseif n==2 and z==1 then
    -- save MODULS
    tabutil.save(MODULES, _path.data.."/zorns/patch.txt")
  
  elseif n==3 and z==1 then
    -- clear MOCULES
    for _,m in pairs(MODULES) do
      m = nil
    end
    MODULES = {}
  end
    
  
end

function enc (n,d)
  dirty_screen = true
  if SEL.is_module(selection) then
    if n==1 then
      local port = SEL.get_port(selection)
      PORT.change_value(port,d)  
    elseif n==2 then
      module_param = util.clamp(module_param+d,1,#selection.module.params)
    else
      selection.module:change_param(module_param,d)
    end
    
  elseif SEL.is_connection(selection) then
    CON.change_strength(selection.module,d)
    
  elseif SEL.is_empty(selection) then
    if n==2 then
      category_list:set_index_delta(d,false)
      module_list = UI.ScrollingList.new (70, 8, 1, module_names[category_list.index])
    elseif n==3 then
      module_list:set_index_delta(d,false)
    end
    
  end
end