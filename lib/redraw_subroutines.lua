function redraw_default_values ()
  screen.level(15)
  screen.line_width(1)
  screen.font_size(8)
end

function redraw_no_selection ()
  screen.move(64,12)
  screen.text_center("hold empty cell")
  screen.level(3)
  screen.line_width(1)
  for x=1,16 do
    for y=1,8 do
      screen.pixel(24+x*5,16+y*5)
      screen.stroke()
    end
  end
  screen.level(15)
  screen.line_width(2)
  for _,m in pairs(MODULES) do
    local x = m.x*5
    local y = m.y*5
    local w = m:get_width()
    if w==1 then
      screen.line_width(1)
      screen.pixel(24+x,16+y)
      --screen.fill()
      screen.stroke()
      screen.line_width(2)
    else
      screen.move(24+x,16+y)
      screen.line(24+x+(w-1)*5,16+y)
      screen.stroke()
    end
  end
end

function redraw_module_settings (sel)
  redraw_default_values()
  -- MODULE NAME
  local x = 64
  local y = 12
  
  if sel.module.name then 
    screen.move(x,y)
    screen.font_size(16)
    screen.text(sel.module.name)
    screen.font_size(8)
  end
  
  -- PARAMS
  local y = 22
  screen.level(3)
  screen.move(x,y)
  screen.text("E2")
  screen.move(x+28,y)
  screen.text("E3")
  local params = sel.module.params
  local param_count = #params
  for i,p in ipairs(params) do
    y = 32+9*(i-1)
    screen.level(module_param==i and 15 or 3)
    screen.move(x,y)
    print("param name")
    screen.text(p.name..":")
    screen.move(x+28,y)
    print("param value")
    screen.text(p.options[p.value])
  end
  
  -- DELETE
  screen.level(3)
  screen.move(x, 62)
  screen.text("K1 > delete")
end

function redraw_module_port (sel)
  redraw_default_values()
  
  local port = SEL.get_port(sel)
  local port_name = SEL.get_name(sel)
  local path = port_name .. (sel.type=="output" and " >" or "")
  
  local x = 0
  
  -- MODULE CELLS
  local w = sel.module:get_width()
  x = 32-(w*2)
  for i=1,w do
    screen.rect(x+(i-1)*4,8,4,4)
    if i==sel.port then
      screen.fill()
    end
    screen.stroke()
  end
  -- PORT NAME
  screen.move(32,22)
  screen.text_center(path)
  -- VALUE DIAL
  if port.value~=nil then
    screen.move(12,42)
    screen.level(3)
    screen.text_center("E1")
    value_dial.x = 32-11
    value_dial:set_value(port.value)
    screen.stroke()
    value_dial:redraw()
  end
end

function redraw_connection (sel) 
  screen.move(64,8)
  screen.text_center("connection")
  value_dial.x = 64-11
  value_dial:set_value(sel.module.strength)
  screen.stroke()
  value_dial:redraw()
end