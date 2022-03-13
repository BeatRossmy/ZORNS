restore_module = function (obj)
  local m = nil
  for _,category in pairs(catalogue) do
    for _,entry in pairs(category.modules) do
      if entry.name==obj.name then
        m = entry.new(obj.x,obj.y,obj.id)
      end
    end
  end
  for n,e in ipairs(obj.input) do
    m.input[n].value = e.value
    m.input[n].source = e.source
  end
  for n,e in ipairs(obj.value) do
    m.value[n] = VALUE.new(e.value,e.gate,e.mapping)
  end
  for n,e in ipairs(obj.params) do
    --m.params[n].value = e.value
    PARAM.set(m,m.params[n],e.value)
  end
  for n,e in ipairs(obj.output) do
    print(table.unpack(e.targets))
    m.output[n].targets = {table.unpack(e.targets)}
  end
  return m
end

zorns_module = function (_x,_y,_id,_n)
  return {
    id = _id,
    name = _n,
    x = _x,
    y = _y,
    
    input = NAMED_LIST.new(),
    value = {},
    output = NAMED_LIST.new(),
    params = NAMED_LIST.new(),
    
    -- UPDATE OUTPUTS
    ctrl_rate = function (self) end,
    
    -- UPDATE INPUTS
    propagate_signals = function (self)
      for _,i in ipairs(self.input) do IN.read(i) end
    end,
    
    add_input = function (self, n, s)
      NAMED_LIST.add(self.input,n,s)
    end,
    
    add_output = function (self, n, s)
      NAMED_LIST.add(self.output,n,s)
    end,
    
    add_param = function (self, p)
      NAMED_LIST.add(self.params, p.name, p)
    end,
    
    add_connection = function (self, con_id)
      local con = CONNECTIONS.list[con_id]
      if self.id==con.target.module_id then
        local inlet = self.input[con.target.port_id]
        inlet.source = con_id
      end
      if self.id==con.source.module_id then
        local outlet = self.output[con.source.port_id]
        table.insert(outlet.targets, con_id)
      end
    end,
    
    --[[remove_connection = function (self,con_id)
      
      local con = CONNECTIONS.list[con_id]
      tabutil.print(con)
      if self.id==con.target.module_id then
        local inlet = self.input[con.target.port_id]
        if inlet.source==con_id then inlet.source = nil end
      end
      if self.id==con.source.module_id then
        local outlet = self.output[con.target.port_id]
        local index = tabutil.key(outlet.targets,con_id)
        if index and index>0 and index<=#outlet.targets then table.remove(outlet.targets,index) end
      end
    end,--]]
    
    inlet = function (self, n)
      return NAMED_LIST.get(self.input,n)
    end,
    
    param = function (self, n)
      local param = NAMED_LIST.get(self.params,n)
      return PARAM.get(param)
    end,
    
    outlet = function (self, n)
      return NAMED_LIST.get(self.output,n)
    end,
    
    contains_connection = function (self, con_id)
      local inlet = self:inlet(con.target.port_id)
      return inlet.source==con_id
    end,
    
    write = function (self, n, v)
      self:outlet(n).signal = v
    end,
    
    get_width = function (self)
      return #self.input + #self.value + #self.output
    end,
    
    in_area = function (self,x,y)
      local w = #self.input + #self.output
      local a = (y==self.y and x>=self.x and x<self.x+w)
      w = #self.value
      print(w)
      a = a or (y==self.y+1 and x>=self.x and x<self.x+w)
      return a
    end,
    
    cell_to_id = function (self, port)
      local id = port.x
      if port.y==1 and port.x<=#self.input then
        id = port.x
      elseif port.y==1 and port.x<=#self.input+#self.output then
        id = port.x-#self.input
      end
      return id
    end,
    
    id_to_cell = function (self, info)
      local t = info.type
      local id = info.port_id
      local c = 0
      if t=="input" then
        c = id
      elseif t=="value" then
        c = #self.input + id
      elseif t=="output" then
        c = #self.input + id
      end
      return c
    end,

    get_cell_info = function (self,abs_x,abs_y)
      local rel_x = abs_x-self.x+1
      local rel_y = abs_y-self.y+1
      local n = self:get_port_name({x=rel_x, y=rel_y})
      local t = self:get_type({x=rel_x, y=rel_y})
      local i = self:cell_to_id({x=rel_x, y=rel_y})
      return {name=n,type=t,port_id=i}
    end,
    
    get_port_name = function (self, port)
      if port.type and (port.type=="input" or port.type=="output") then
        return self[port.type].names[port.port_id]
      elseif port.x and port.y==1 then
        return (port.x<=#self.input) and self.input.names[port.x] or self.output.names[port.x-#self.input]
      end
      return "value"
    end,

    get_type = function (self, port)
      if port.x and port.y==1 then
        return (port.x<=#self.input) and "input" or "output"
      end
      return "value"
    end,
    
    get_port = function (self, port)
      if port.type then
        return self[port.type][port.port_id]
      elseif port.x and port.y==1 then
        return (port.x<=#self.input) and self.input[port.x] or self.output[port.x-#self.input]
      elseif port.x and port.y>=1 then
        return self.value[port.x]
      end
    end,
    
    change_param = function (self, p, d)
      if #self.params>0 then
        local param = self.params[p]
        PARAM.change(self,param,d)
      end
    end,
    
    grid_event = function (self,x,y,z)
      if self:in_area(x,y) then
        x = x-self.x+1
        y = y-self.y+1
        if y>1 then
          self:grid_ui(x,y,z)
        end
      end
    end,
    
    grid_ui = function (self,x,y,z) end,
    
    show_ui = function (self,x,y,g) end,
    
    show = function (self, g)
      -- show input
      for i=1, #self.input do
        local l = SIGNAL.map(self:inlet(i).signal,3,15,1)
        if selection and selection.module_id and selection.module_id~=self.id then l = math.floor(l/3) end
        g:led(self.x+i-1,self.y,l)
      end
      -- show ui
      self:show_ui(g)
      -- show output
      for i=1, #self.output do
        local l = SIGNAL.map(self:outlet(i).signal,3,15,1)
        if selection and selection.module_id and selection.module_id~=self.id then l = math.floor(l/3) end
        g:led(self.x+#self.input+i-1,self.y,l)
      end
    end,
    
    show_connection = function (self, sel, g)
      local cons = {}
      if sel.type=="input" then
        cons = {self:get_port(sel).source}
      elseif sel.type=="output" then
        cons = self:get_port(sel).targets
      end
      for _,con_id in pairs(cons) do
        local con = CONNECTIONS.list[con_id]
        local src = MODULES.list[con.source.module_id]
        local trgt = MODULES.list[con.target.module_id]
        local x = src.x+src:id_to_cell({port_id=con.source.port_id,type="output"})-1
        local y = src.y
        g:led(x,y,15)
        x = trgt.x+con.target.port_id-1
        y = trgt.y
        g:led(x,y,15)
      end
    end
  }
end