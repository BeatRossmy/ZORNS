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
    return util.round(v,1)
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
      source = {module=src.module, port_id=src.port, port=src.module:get_port(src.port)},
      target = {module=trgt.module, port_id=trgt.port},
      strength = str
    }
  end,
  change_strength = function (con, d)
    con.strength = util.clamp(con.strength+d*0.01,0,1)
  end,
  get_signal = function (con)
    if not con then return 0 end
    local src = con.source.port
    return src.signal * con.strength
  end
}

PORT = {
  new = function (v)
    return {value=v}
  end,
  get_signal = function (p)
    return p.signal and p.signal or 0
  end,
  get = function (p)
    return p.signal and p.signal or p.value
  end,
  set_value = function (p,v)
    if p.value~=nil then p.value = util.clamp(v,0,1) end
  end,
  change_value = function (p,d)
    if p.value~=nil then p.value = util.clamp(p.value+d*0.01,0,1) end
  end,
  toggle_gate = function (p)
    if p.gate~=nil then p.gate = not p.gate end
  end
}

IN = {
  new = function (v,g)
    return {signal=v, value=v, gate=g, phase=(g~=nil and 0 or nil), source=nil}
  end,
  
  read = function (_in)
    local s = IN.calc_signal(_in)
    
    local change = s~=_in.signal
    _in.signal = s
    
    if _in.gate~=nil then
      local g = (s>=0.5)
      local ph = 0                               -- "no"
      if g and not _in.gate then ph = 1          -- "rising"
      elseif not g and _in.gate then ph = -1 end -- "falling"
      _in.gate, _in.phase = g, ph
    end
  end,
  calc_signal = function (_in)
    return (_in.source and (_in.value + CON.get_signal(_in.source)) or _in.value)
  end
}

VALUE = {
  new = function (v,g)
    return {value=v, gate=g}
  end
}

OUT = {
  new = function () 
    return {signal= 0}
  end
}