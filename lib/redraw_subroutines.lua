function redraw_default_values ()
  screen.level(15)
  screen.line_width(1)
  screen.font_size(8)
end

function redraw_no_selection ()
  redraw_default_values()
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
  for _,m in pairs(MODULES.list) do
    local x = m.x*5
    local y = m.y*5
    --local w = m:get_width()
    local w = #m.input+#m.output
    if w==1 then
      screen.line_width(1)
      screen.pixel(24+x,16+y)
      screen.stroke()
      screen.line_width(2)
    else
      screen.move(24+x,16+y)
      screen.line(24+x+(w-1)*5,16+y)
      screen.stroke()
    end
    if #m.value>0 then
      local x = m.x*5
      local y = (m.y+1)*5
      local w = #m.value
      if w==1 then
        screen.line_width(1)
        screen.pixel(24+x,16+y)
        screen.stroke()
        screen.line_width(2)
      else
        screen.move(24+x,16+y)
        screen.line(24+x+(w-1)*5,16+y)
        screen.stroke()
      end
    end
  end
end

function redraw_module_settings (sel)
  redraw_default_values()
  -- MODULE NAME
  local x = 64
  local y = 12
  local m = MODULES.list[sel.module_id]
  
  if m.name then
    screen.move(x,y)
    screen.font_size(16)
    screen.text(m.name)
    screen.font_size(8)
  end
  
  -- PARAMS
  local y = 22
  screen.level(3)
  screen.move(x,y)
  screen.text("E2")
  screen.move(x+28,y)
  screen.text("E3")
  local params = m.params
  local param_count = #params
  for i,p in ipairs(params) do
    y = 32+9*(i-1)
    screen.level(module_param==i and 15 or 3)
    screen.move(x,y)
    screen.text(p.name..":")
    screen.move(x+28,y)
    if p.options then
      screen.text(p.options[p.value])
    else
      screen.text(p.value)
    end
  end
  
  -- DELETE
  screen.level(3)
  screen.move(x, 62)
  screen.text("K1 > delete")
end

function redraw_module_port (sel)
  redraw_default_values()
  
  local m = MODULES.list[sel.module_id]
  local port = SEL.get_port(sel)
  local port_name = SEL.get_name(sel)
  local path = port_name .. (sel.type=="output" and " >" or "")
  local x = 0
  local selected_cell = SEL.get_cell(sel)
  
  -- MODULE CELLS
  --[[local w = m:get_width()
  x = 32-(w*2)
  for i=1,w do
    screen.rect(x+(i-1)*4,8,4,4)
    -- if i==sel.port_id then
    if i==sellected_cell then
      screen.fill()
    end
    screen.stroke()
  end--]]
  
  -- PORT NAME
  screen.move(32,22)
  screen.text_center(path)
  -- VALUE DIAL
  if port.value~=nil then
    screen.move(12,42)
    screen.level(3)
    screen.text_center("E1")
    draw_dial(32-11, 40-11, 11, port.value, port.signal, port.mapping)
  end
end

function redraw_connection (sel)
  redraw_default_values()
  local con = CONNECTIONS.list[sel.con_id]
  if con then
    screen.move(64,8)
    screen.text_center("connection")
    draw_dial(64-11, 40-11, 11, con.strength, nil, nil)
  end
end