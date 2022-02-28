include("lib/connections")

include("lib/zorns_module")

include("lib/modules")

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
  if a.type==b.type or a.type=="value" or b.type=="value" then return end
  local src = a.type=="output" and a or b
  local trgt = a.type=="input" and a or b
  local con = CON.new(src,trgt,1)
  trgt.module:add_connection(trgt.port,con)
  -- table.insert(CONNECTIONS,con)
end

g = grid.connect()
g.key = function(x,y,z)
  -- local selected_module = nil
  
  -- FIRST SELECTION
  if not selection and z==1 then
    selection = select_module(x,y)
    if selection then
      selection.module:grid_event(x,y,z)
    end
  -- REMOVE SELECTION
  elseif selection and x==selection.x and y==selection.y and z==0 then
    selection = nil
  -- SECOND SELECTION
  elseif selection and z==1 then
    local sec_sel = select_module(x,y)
    if sec_sel then
      print("create connection")
      create_connection(selection,sec_sel)
    end
  end
  
  if selection==nil then
    -- empty cell
    if z==1 and not selected_cell then
      selected_cell = {x=x, y=y}
      option = 0
    elseif z==0 and selected_cell then
      if option~=0 then
        table.insert(MODULES,modules[option].new(selected_cell.x,selected_cell.y))
      end
      selected_cell = nil
    end
  end
  
end

m_out = midi.connect(2)

selection = nil -- NEW

selected_port = nil
selected_cell = nil
option = 0

-- nodes = {}
MODULES = {}
-- CONNECTIONS = {}
CTRL_RATE = 1/128 -- 1/128

ctrl_loop = function ()
  for _,m in pairs(MODULES) do m:ctrl_rate() end
end

draw_loop = function ()
  for _,m in pairs(MODULES) do m:show(g) end
  g:refresh()
end

screen_loop = function ()
  
end

function redraw()
  screen.clear()
  
  --if selected_port then
  if selection then
    local port = SEL.get_port(selection)
    local port_name = SEL.get_name(selection)
    local path = selection.module.name.."->"..selection.type.."->"..port_name
    
    screen.move(16,16)
    screen.text(path)
    
    if selection.type=="input" then
      local y = 48
      local r = 4
      screen.move(16,y)
      screen.line(112,y)
      screen.stroke()
      -- SIGNAL
      local x = util.linlin(0,1,16,112,IN.get(port))
      screen.move(x,y-r)
      screen.line(x,y+r)
      screen.stroke()
      -- BIAS
      x = util.linlin(0,1,16,112,port.bias)
      screen.circle(x,y,r)
      screen.stroke()
    end
    
  elseif not selected_cell then
    screen.move(32,32)
    screen.text("hold empty cell")
  else
    local o = option==0 and "none" or modules[option].name
    screen.move(32,32)
    screen.text("add: "..o)
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
  if n==1 and z==1 and selection then
    local port = SEL.get_port(selection)
    port.source = nil
  end
end

function enc (n,d)
  if selection and selection.type=="input" then
    local port = SEL.get_port(selection)
    port.bias = util.clamp(port.bias+d*0.01,0,1)
  elseif selected_cell then
    option = util.clamp(option+d,0,#modules)
    print(option)
  end
end