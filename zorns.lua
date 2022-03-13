engine.name = 'PolyPerc'

er = require "lib.er"
local UI = require "ui"
musicutil = require "musicutil"
tabutil = require "tabutil"

include("lib/id_list")
include("lib/global_variables")
include("lib/grid_ui")
include("lib/redraw_subroutines")
include("lib/helpers")
include("lib/connections")
include("lib/zorns_module")
include("lib/module_catalogue")

DIAL = include("lib/dial")

category_list = UI.ScrollingList.new (38, 8, 2, category_names)
module_list = UI.ScrollingList.new (70, 8, 2, module_names[category_list.index])

module_param = 1

dirty_screen = true
selection = nil

CTRL_RATE = 1/128

MODULES = ID_LIST.new()

CONNECTIONS = ID_LIST.new()

select_module = function (x,y)
  for _,m in pairs(MODULES.list) do
    if m:in_area(x,y) then
      local info = m:get_cell_info(x,y)
      tabutil.print(info)
      return SEL.new(x,y,m.id,info.port_id,info.type)
    end
  end
  return nil
end

ctrl_loop = function ()
  main_clock:update()
  for _,m in pairs(MODULES.list) do
    m:ctrl_rate()
    --m:propagate_signals()
  end
  for _,m in pairs(MODULES.list) do
    m:propagate_signals()
  end
end

function redraw()
  if not dirty_screen then return end
  dirty_screen = false
  screen.clear()
  if SEL.is_module(selection) then
    redraw_module_settings(selection)
    redraw_module_port(selection)
    dirty_screen = true
  elseif SEL.is_connection(selection) then
    redraw_connection(selection)
  elseif SEL.is_empty(selection) then
    category_list:redraw ()
    module_list:redraw ()
  elseif not selection then
    redraw_no_selection()
  end
  screen.update()
end

function init ()
  -- LOAD PATCH
  stored_patch = tabutil.load(_path.data.."/zorns/patch.txt")
  if stored_patch then
    for i,m in pairs(stored_patch.modules) do
      local mo = restore_module(m)
      MODULES:insert(mo)
    end
    for i,con in pairs(stored_patch.connections) do
      CONNECTIONS:insert(con)
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
    
    if SEL.is_connection(selection) then
      CON.remove(selection.con_id)
      selection = nil
    elseif SEL.is_module(selection) then
      -- DELETE ALL CONNECTIONS
      local sel_id = selection.module_id
      for id,con in pairs(CONNECTIONS.list) do
        if con.source.module_id==sel_id or con.target.module_id==sel_id then
          CON.remove(selection.con_id)
        end
      end
      -- DELETE MODULE
      MODULES:pop_id(selection.module_id)
      selection = nil
    end
  
  elseif n==2 and z==1 then
    -- save MODULES
    tabutil.save({modules=MODULES.list,connections=CONNECTIONS.list}, _path.data.."/zorns/patch.txt")
  
  elseif n==3 and z==1 then
    -- clear MODULES
    MODULES = ID_LIST.new()
    CONNECTIONS = ID_LIST.new()
  end
    
end

function enc (n,d)
  dirty_screen = true
  if SEL.is_module(selection) then
    local m = MODULES.list[selection.module_id]
    if n==1 then
      local port = SEL.get_port(selection)
      PORT.change_value(port,d)  
    elseif n==2 then
      module_param = util.clamp(module_param+d,1,#m.params)
    else
      m:change_param(module_param,d)
    end
    
  elseif SEL.is_connection(selection) then
    CON.change_strength(selection.con_id,d)
    
  elseif SEL.is_empty(selection) then
    if n==2 then
      category_list:set_index_delta(d,false)
      module_list = UI.ScrollingList.new (70, 8, 1, module_names[category_list.index])
    elseif n==3 then
      module_list:set_index_delta(d,false)
    end
    
  end
end