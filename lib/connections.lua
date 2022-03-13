SIGNAL = {
  map = function (s,a,b,c)
    if type(a)=="table" and #a>0 then
      return SIGNAL.map_list(s,a)
    elseif type(a)=="table" and a.min and a.max then
      return SIGNAL.xmap(s,a.min,a.max,a.q)
    elseif type(a)=="number" and type(b)=="number" then
      return SIGNAL.xmap(s,a,b,c)
    end
    return s
  end,
  -- with upper number => [l,h]
  map_range = function (s,l,h,q)
    l = l and l or 0
    h = h and h or 1
    local v = l + s * (h-l)
    if q and q>0 then
      v = math.floor(v/q)*q
    end
    return v
  end,
  -- without upper number => [l,h[
  xmap = function (s,l,h,q)
    s = s==1 and (s-0.0000001) or s
    return SIGNAL.map_range(s,l,h,q)
  end,
  map_list = function (s,list)
    local i = SIGNAL.xmap(s,1,#list+1,1)
    return list[i]
  end
  
}

SEL = {
  new = function (_x,_y,_m_id,_p_id,_t)
    return {x=_x, y=_y, module_id=_m_id, port_id=_p_id, type=_t}
  end,
  get_port = function (sel)
    -- return MODULES.list[sel.module_id]:get_port(sel.port_id)
    return MODULES.list[sel.module_id][sel.type][sel.port_id]
  end,
  get_name = function (sel)
    -- return MODULES.list[sel.module_id]:get_port_name(sel.port_id)
    return MODULES.list[sel.module_id]:get_port_name(sel)
  end,
  get_cell = function (sel)
    return MODULES.list[sel.module_id]:id_to_cell(sel)
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
  is_output = function (sel)
    return (sel and sel.type=="output")
  end,
  is_connection = function (sel)
    return (sel and sel.type=="connection")
  end,
  not_this_module = function (sel, m)
    return (sel and sel.module_id and sel.module_id~=m.id)
  end
}

CON = {
  new = function (a,b,str,_id)
    --local a_type = MODULES.list[a.module_id]:get_type(a.port_id)
    if (a.type=="value" or b.type=="value") then return nil end
    local a_type = a.type
    local src = a_type=="output" and a or b
    local trgt = a_type=="input" and a or b
    return {
      source = {module_id=src.module_id, port_id=src.port_id},
      target = {module_id=trgt.module_id, port_id=trgt.port_id},
      strength = str,
      id = _id
    }
  end,
  equals = function (a,b)
    local bool = a.source.module_id==b.source.module_id and a.source.port_id==b.source.port_id
    bool = bool and a.target.module_id==b.target.module_id and a.target.port_id==b.target.port_id
    return bool
  end,
  contains = function (list, con)
    for i,c in pairs(list) do
      if CON.equals(c,con) then return i end
    end
    return nil
  end,
  change_strength = function (con_id, d)
    local con = CONNECTIONS.list[con_id]
    con.strength = util.clamp(con.strength+d*0.01,0,1)
  end,
  get_signal = function (con_id)
    local con = CONNECTIONS.list[con_id]
    if not con then return 0 end
    local src = MODULES.list[con.source.module_id]:outlet(con.source.port_id)
    return src.signal * con.strength
  end,
  remove = function (con_id)
    local con = CONNECTIONS.list[con_id]
    -- remove from source
    local src = MODULES.list[con.source.module_id]:outlet(con.source.port_id)
    table.remove(src.targets,tabutil.key(src.targets,con_id))
    -- remove from target
    local trgt = MODULES.list[con.target.module_id]:inlet(con.target.port_id)
    trgt.source = nil
    -- remove from list
    CONNECTIONS.list[con_id] = nil
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
    if p.value~=nil then p.value = util.clamp(p.value+d*1/240,0,1) end
  end,
  toggle_gate = function (p)
    if p.gate~=nil then p.gate = not p.gate end
  end,
  --[[get_connections = function (p)
    if p.source then return p.source
    elseif p.targets then return p.targets end
    return nil
  end--]]
}

IN = {
  new = function (v,g,m)
    return {signal=v, value=v, gate=g, phase=(g~=nil and 0 or nil), source=nil, mapping=m, change=true}
  end,
  
  read = function (_in)
    local s = IN.calc_signal(_in)
    
    _in.change = s~=_in.signal
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
    return util.clamp((_in.source and (_in.value + CON.get_signal(_in.source)) or _in.value),0,1)
  end
}

VALUE = {
  new = function (v,g,m) return {value=v, gate=g, mapping=m} end
}

OUT = {
  new = function () return {signal= 0, targets={}} end
}

PARAM = {
  new = function () return {} end,
  change = function (m,p,d)
    if p.options then
      p.value = util.clamp(p.value+d,1,#p.options)
    elseif p.min and p.max and p.delta then
      p.value = util.clamp(p.value+d*p.delta,p.min,p.max)
    end
    if p.action then
      p.action(m)
    end
  end,
  set = function (m,p,v)
    if p.options then
      p.value = util.clamp(v,1,#p.options)
    elseif p.min and p.max and p.delta then
      p.value = util.clamp(v,p.min,p.max)
    end
    if p.action then
      p.action(m)
    end
  end,
  get = function (p)
    if p.options and type(p.options[p.value])=="number" then
      return p.options[p.value]
    else
      return p.value
    end
  end
}