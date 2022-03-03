Signal = {
  map = function (s,l,h,q)
    if type(s)=="table" then s = s.value end
    local v = util.linlin(0,1,l,h,s)
    if q then v = util.round(v,q) end
    return v
  end,
  to_midi = function (s)
    if type(s)=="table" then s = s.value end
    local v = util.linlin(0,1,0,120,s)
    v = util.round(v,1)
    return v
  end
}

SEL = {
  new = function (_x,_y,_m,_p,_t)
    return {x=_x, y=_y, module=_m, port=_p, type=_t}
  end,
  get_port = function (sel)
    return sel.module:get_port(sel.port)
  end,
  get_name = function (sel)
    return sel.module:get_port_name(sel.port)
  end,
  is_empty = function (sel)
    return (sel and sel.type=="empty_cell")
  end,
  is_module = function (sel)
    return (sel and (sel.type=="input" or sel.type=="value" or sel.type=="output"))
  end,
  is_input = function (sel)
    return (sel and sel.type=="input")
  end,
  is_value = function (sel)
    return (sel and sel.type=="value")
  end,
  is_ouput = function (sel)
    return (sel and sel.type=="output")
  end,
  is_connection = function (sel)
    return (sel and sel.type=="connection")
  end
}

CON = {
  new = function (src,trgt,str)
    return {
      source = {module=src.module, port=src.port}, --src
      target = {module=trgt.module, port=trgt.port}, --trgt
      strength = str
    }
  end,
  get = function (con)
    if not con then return 0 end
    return PORT.get_value(con.source.module:get_port(con.source.port)) * con.strength
  end,
  change_strength = function (con, d)
    con.strength = util.clamp(con.strength+d*0.01,0,1)
  end
}

--[[
value: state of port
last_value: last state
bias: offset to source value, can be changed when selected
source: value received from connection
gate: boolean derived from 
change: boolean if value changed
--]]

PORT = {
  new = function (v)
    return {value=v}
  end,
  get_value = function (p)
    if not p.source then
      return p.value
    end
    return util.clamp(p.value + CON.get(p.source),0,1)
  end,
  set_value = function (p,v)
    if p.value~=nil then p.value = util.clamp(v,0,1) end
  end,
  change_value = function (p,d)
    if p.value~=nil then p.value = util.clamp(p.value+d*0.01,0,1) end
  end,
  toggle_gate = function (p)
    if p.gate~=nil then p.gate = p.gate>=0.5 and 0 or 1 end
  end
}

IN = {
  new = function (v,g)
    local _in = PORT.new(v)
    _in.gate = g
    _in.source = nil
    return _in
  end,
  
  read = function (_in)
    local s = {signal = PORT.get_value(_in), phase="no", gate=_in.gate}
    if _in.gate~=nil then
      if _in.gate==0 and s.signal>=0.5 then
        _in.gate = 1
        s.phase = "rising" 
      elseif _in.gate==1 and s.signal<0.5 then
        _in.gate = 0
        s.phase = "falling"
      end
    end
    return s
  end
}

VALUE = {
  new = function (v,g)
    local val = PORT.new(v)
    val.gate = g
    return val
  end
}

OUT = {
  new = function () 
    return PORT.new(0)
  end
}