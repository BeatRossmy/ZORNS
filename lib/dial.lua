function draw_dial (x,y,r,v,s,mapping)
  screen.stroke()                                                     -- <== hacky bugg fix
  
  local start_angle = math.pi * 0.7
  local end_angle = math.pi * 2.3
  
  local fill_start_angle = s and util.linlin(0, 1,start_angle, end_angle, v) or start_angle
  local fill_end_angle = util.linlin(0, 1, start_angle, end_angle, (s and s or v))
  local fill_tip_angle = s and fill_start_angle or fill_end_angle
  
  if fill_end_angle < fill_start_angle then
    local temp_angle = fill_start_angle
    fill_start_angle = fill_end_angle
    fill_end_angle = temp_angle
  end
  
  -- FULL CIRCLE
  screen.level(5)
  screen.arc(x + r, y + r, r - 0.5, start_angle, end_angle)
  screen.stroke()
  
  -- VALUE RANGE
  screen.level(15)
  screen.line_width(2.5)
  screen.arc(x + r, y + r, r - 0.5, fill_start_angle, fill_end_angle)
  screen.stroke()
  screen.line_width(1)
  
  -- TIP
  screen.level(15)
  screen.line_width(5)
  screen.arc(x + r, y + r, r - 0.5, fill_tip_angle-0.1, fill_tip_angle+0.1)
  screen.stroke()
  screen.line_width(1)
  
  local value = ""
  if not mapping then
    value = util.round(v, 0.01)
  else
    value = SIGNAL.map(v,mapping)
    if mapping.unit then value = value .. mapping.unit end
  end
  
  screen.move(x + r, y + 2*r + 6)
  screen.text_center(value)
  screen.fill()
  
end