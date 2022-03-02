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
    return OUT.get(con.source.module:get_port(con.source.port)) * con.strength
  end,
  change_strength = function (con, d)
    con.strength = util.clamp(con.strength+d*0.01,0,1)
  end
}

PORT = {
  new = function (b,g)
    return {bias=b, gate=g}
  end,
  set_bias = function (p,b)
    if p.bias~=nil then p.bias = util.clamp(b,0,1) end
  end,
  change_bias = function (p,d)
    if p.bias~=nil then p.bias = util.clamp(p.bias+d*0.01,0,1) end
  end,
  toggle_gate = function (p)
    if p.gate~=nil then p.gate = p.gate>=0.5 and 0 or 1 end
  end
}

IN = {
  new = function (b,g)
    local _in = PORT.new(b,g)
    _in.source = nil
    
    --[[_in.read = function (self)
      local s = {signal = self:get(), phase="no", gate=self.gate}
      if self.gate~=nil then
        if self.gate==0 and s.signal>=0.5 then
          self.gate = 1
          s.phase = "rising" 
        elseif self.gate==1 and s.signal<0.5 then
          self.gate = 0
          s.phase = "falling"
        end
      end
      return s
    end
    
    _in.get = function (self)
      return util.clamp(self.bias + CON.get(self.source),0,1)
    end--]]
    
    return _in
  end,
  
  read = function (_in)
    local s = {signal = IN.get(_in), phase="no", gate=_in.gate}
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
  end,
  
  get = function (_in)
    return util.clamp(_in.bias + CON.get(_in.source),0,1)
  end
}

VALUE = {
  new = function (v,g)
    return PORT.new(v,g)
  end,
  toggle = function (v)
    if v.gate~=nil then v.gate = v.gate==1 and 0 or 1 end
  end,
  set = function (v, l)
    if v.bias~=nil then v.bias = l end
  end,
  add = function (v, d)
    if v.bias~=nil then v.bias = util.clamp(v.bias+d*0.01,0,1) end
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