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
  end
}

CON = {
  new = function (src,trgt,str) 
    return {
      source = src,
      target = trgt,
      strength = str
    }
  end,
  get = function (con)
    if not con then return 0 end
    return OUT.get(con.source.module:get_port(con.source.port)) * con.strength
  end
}

OUT = {
  new = function () 
    return {
      signal = 0
    }
  end,
  set = function (_out, v)
    _out.signal = v
  end,
  get = function (_out)
    return (_out and _out.signal or 0)
  end
}

IN = {
  new = function (b)
    return {
      bias = b and b or 0,
      source = nil
    }
  end,
  triggered = function (v, state)
    local phase = "no"
    if not state.triggered and v>=0.5 then
      state.triggered = true
      phase = "rising" 
    elseif state.triggered and v<0.5 then
      state.triggered = false
      phase = "falling"
    end
    return phase
  end,
  get = function (_in)
    return util.clamp(_in.bias + CON.get(_in.source),0,1)
  end
}