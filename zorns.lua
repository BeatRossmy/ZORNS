local UI = require "ui"
musicutil = require "musicutil"

include("lib/connections")

include("lib/zorns_module")

include("lib/module_catalogue")

scale_names = {
  "Major",
  "Natural Minor",
  "Phrygian",
  "Major Pentatonic",
  "Minor Pentatonic"
}
scales = {}
for i,n in pairs(scale_names) do scales[i] = musicutil.generate_scale (0, n, 10) end

local category_list = UI.ScrollingList.new (8, 8, 2, category_names)
local module_list = UI.ScrollingList.new (40, 8, 2, module_names[category_list.index])

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
  con.target.module:add_connection(con.target.port,con)
end

g = grid.connect()
g.key = function(x,y,z)
  
  -- FIRST SELECTION
  if not selection and z==1 then
    selection = select_module(x,y)
    if selection then
      selection.module:grid_event(x,y,z)
    end
  -- REMOVE SELECTION
  elseif selection and x==selection.x and y==selection.y and z==0 then
    if selection.type=="empty_cell" then
      local c = category_list.index
      local m = module_list.index
      print(c,m)
      if m>1 then
        table.insert(MODULES,catalogue[c].modules[m-1].new(selection.x,selection.y))
      end
    end
    selection = nil
  -- SECOND SELECTION
  elseif selection and z==1 then
    local sec_sel = select_module(x,y)
    if sec_sel then
      print("create connection")
      local con = create_connection(selection,sec_sel)
      if con then
        local old_con = con.target.module:contains_connection(con)
        if old_con  then 
          print("connection exists")
          con = old_con
          selection.type = "connection"
          selection.module = old_con
          selection.port = nil
        else
          print("set connection")
          set_connection(con)
        end
      end
    end
  end
  
  if selection==nil and z==1 then
    selection = SEL.new(x,y,nil,nil,"empty_cell")
    option = 0
  end
  
  if selection then print("sel",selection.x,selection.y,selection.type) end
end

m_out = midi.connect(2)

selection = nil
--option = 0
--catalogue_entry = {category=1, module=0}
MODULES = {}
CTRL_RATE = 1/128 -- 1/128

ctrl_loop = function ()
  for _,m in pairs(MODULES) do m:ctrl_rate() end
end

draw_loop = function ()
  g:all(0)
  for _,m in pairs(MODULES) do m:show(g) end
  g:refresh()
end

-- screen_loop = function () end

function redraw()
  screen.clear()
  
  --[[if selection and selection.type~="empty_cell" then
    local port = SEL.get_port(selection)
    local port_name = SEL.get_name(selection)
    local path = selection.module.name.."->"..selection.type.."->"..port_name
    
    screen.move(16,16)
    screen.text(path)
    
    if selection.type=="value" or selection.type=="input" then
      local y = 48
      local r = 4
      
      -- MAIN PARAM
      local t = ""..selection.module:show_param()
      screen.move(16,32)
      screen.text(t)
      
      -- SIGNAL
      if port.bias~=nil then
        screen.move(16,y)
        screen.line(112,y)
        screen.stroke()
        local x = util.linlin(0,1,16,112,port.bias)
        screen.move(x,y-r)
        screen.line(x,y+r)
        screen.stroke()
      end
      -- GATE
      --[[if port.gate~=nil then
        y = y+12
        screen.circle(64,y,1.5*r)
        if port.gate==1 then screen.fill() end
        screen.stroke()
      end--]]
    
    --end --]]
    
  if selection and (selection.type=="value" or selection.type=="input") then
    local port = SEL.get_port(selection)
    local port_name = SEL.get_name(selection)
    local path = selection.module.name.."->"..selection.type.."->"..port_name
    
    local y = 48
    local r = 4
    
    -- MAIN PARAM
    local t = ""..selection.module:show_param()
    screen.move(16,32)
    screen.text(t)
    
    -- SIGNAL
    if port.bias~=nil then
      screen.move(16,y)
      screen.line(112,y)
      screen.stroke()
      local x = util.linlin(0,1,16,112,port.bias)
      screen.move(x,y-r)
      screen.line(x,y+r)
      screen.stroke()
    end
    
  elseif SEL.is_connection(selection) then
    
    screen.move(32,32)
    screen.text("strength: " .. string.format("%.2f",selection.module.strength))
    
  elseif SEL.is_empty(selection) then
    category_list:redraw ()
    module_list:redraw ()
    
  elseif not selection then
    screen.move(32,32)
    screen.text("hold empty cell")
  end
  screen.update()
end

function init ()
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
      for i,m in pairs(MODULES) do
        if m==selection.module then
          print("delete", m)
          MODULES[i] = nil
          selection = nil
        end
      end
    end
  end
end

function enc (n,d)
  
  if SEL.is_module(selection) and n==1 then
    selection.module:enc(d)
    
  --elseif SEL.is_input(selection) then
  --  local port = SEL.get_port(selection)
  --  port.bias = util.clamp(port.bias+d*0.01,0,1)
    
  elseif SEL.is_input(selection) or SEL.is_value(selection) then
    local port = SEL.get_port(selection)
    --VALUE.add(port, d) -- <- works because both have bias
    PORT.change_bias(port,d)
    
  elseif SEL.is_connection(selection) then
    CON.change_strength(selection.module,d)
    
  elseif SEL.is_empty(selection) then
    if n==2 then
      category_list:set_index_delta(d,false)
      module_list = UI.ScrollingList.new (40, 8, 1, module_names[category_list.index])
    elseif n==3 then
      module_list:set_index_delta(d,false)
    end
  end
end