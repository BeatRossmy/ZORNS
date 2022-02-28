Signal = {
  -- range: [-1,1]
  new = function (v)
    return {value=v}
  end,
  map = function (s,l,h,q)
    if type(s)=="table" then s = s.value end
    local v = util.linlin(-5,5,l,h,s)
    if q then v = util.round(v,q) end
    return v
  end,
  to_midi = function (s)
    if type(s)=="table" then s = s.value end
    local v = util.linlin(-5,5,0,120,s)
    v = util.round(v,1)
    return v
  end,
  to_level = function (s)
    if type(s)=="table" then s = s.value end
    local v = util.linlin(-5,5,0,15,s)
    v = util.round(v,1)
    return v
  end
}

include("lib/zorns_module")

include("lib/modules")


g = grid.connect()
g.key = function(x,y,z)
  local selected_module = nil
  
  for _,n in pairs(nodes) do
    if n:in_area(x,y) then
      selected_module = n
      break
    end
  end
  
  if selected_module then
    selected_module:grid_event(x,y,z)
  else
    -- empty cell
    if z==1 and not selected_cell then
      selected_cell = {x=x, y=y}
      option = 0
    else
      if option~=0 then
        table.insert(nodes,modules[option].new(selected_cell.x,selected_cell.y))
      end
      selected_cell = nil
    end
  end
  
end
m_out = midi.connect(2)

selected_port = nil
selected_cell = nil
option = 0

nodes = {}
CTRL_RATE = 1/128 -- 1/128

ctrl_loop = function ()
  for _,n in pairs(nodes) do n:ctrl_rate() end
end

draw_loop = function ()
  for _,n in pairs(nodes) do n:show(g) end
  g:refresh()
end

screen_loop = function ()
  
end

function redraw()
  screen.clear()
  
  if selected_port then
    screen.move(16,16)
    screen.text("type: "..selected_port.module.name)
    screen.move(32,32)
    screen.text(string.format(selected_port.name..": %.2f",selected_port.signal.value))
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
  
  --metro.init(redraw, 1/15):start()
  clock.run(
    function()
      while true do
        clock.sleep(1/15)
        redraw()
      end
    end  
  )
  
  --[[lfo_1 = sine_lfo(1,1)
  
  lfo_2 = sine_lfo(8,1)
  lfo_2.inputs[1].value = -0.666
  
  quant = quantizer(1,3)
  
  m_o = new_output(1,5)
  
  lfo_1.outputs[1] = m_o.inputs[1]
  lfo_2.outputs[1] = quant.inputs[1]
  quant.outputs[1] = m_o.inputs[2]
  
  table.insert(nodes,lfo_1)
  table.insert(nodes,lfo_2)
  table.insert(nodes,quant)
  table.insert(nodes,m_o)--]]
end

function key (n,z)
  if n==1 and z==1 and selected_port then
    selected_port.signal = nil
    selected_port.module[selected_port.type][selected_port.index] = Signal.new(1)
    selected_port = nil
  end
end

function enc (n,d)
  if selected_port then
    selected_port.signal.value = util.clamp(selected_port.signal.value+d*0.1,-5,5)
    print(selected_port.signal.value)
  elseif selected_cell then
    option = util.clamp(option+d,0,#modules)
    print(option)
  end
end