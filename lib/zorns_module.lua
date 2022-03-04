restore_module = function (obj)
  local m = nil
  for _,category in pairs(catalogue) do
    for _,entry in pairs(category.modules) do
      if entry.name==obj.name then
        m = entry.new(obj.x,obj.y,obj.id)
      end
    end
  end
  for n,e in ipairs(obj.inputs) do
    m.inputs[n].value = e.value
  end
  for n,e in ipairs(obj.values) do
    m.values[n].value = e.value
    m.values[n].gate = e.gate
  end
  for n,e in ipairs(obj.params) do
    m.params[n].value = e.value
  end
  return m
end

restore_connections = function (obj)
  local c = nil
  for i,_in in ipairs(obj.inputs) do
    if _in.source then
      local strength = _in.source.strength
      local source_id = _in.source.source.module.id
      local source_cell = _in.source.source.port_id
      local target_id = obj.id
      local target_cell = i
      print("connection:", source_id, source_cell, "= "..strength.." =>", target_id, target_cell)
      local con = restore_connection(source_id,source_cell,target_id,target_cell,strength)
      MODULES[target_id]:add_connection(target_cell,con)
    end
  end
  return c
end

zorns_module = function (_x,_y,_id,_n)
  return {
    id = _id,
    name = _n,
    x = _x,
    y = _y,
    
    inputs = {names={},indices={}},
    values = {},
    outputs = {names={},indices={}},
    main_param = 0,
    
    params = {indices={}},
    
    -- UPDATE OUTPUTS
    ctrl_rate = function (self) end,
    
    -- UPDATE INPUTS
    propagate_signals = function (self)
      for _,i in ipairs(self.inputs) do
        -- read: process conenctions and bias, deduce changes, etc. ...
        IN.read(i)
      end
    end,
    
    add_input = function (self, n, s)
      table.insert(self.inputs,s)
      self.inputs.indices[n] = #self.inputs
      self.inputs.names[#self.inputs] = n
    end,
    
    add_output = function (self, n, s)
      table.insert(self.outputs,s)
      self.outputs.indices[n] = #self.outputs
      self.outputs.names[#self.outputs] = n
    end,
    
    add_param = function (self, p)
      table.insert(self.params,p)
      self.params.indices[p.name] = #self.params
    end,
    
    add_connection = function (self, c, con)
      local inlet = self.inputs[c]
      inlet.source = con
    end,
    
    inlet = function (self, n)
      if type(n)=="string" then
        return self.inputs[self.inputs.indices[n]]
      elseif type(n)=="number" then
        return self.inputs[n]
      end
    end,
    
    param = function (self, n)
      local i = type(n)=="number" and n or self.params.indices[n]
      local param = self.params[i]
      if param.options --[[and param.value<=#param.options--]] and type(param.options[param.value])=="number" then
        return param.options[param.value]
      else
        return param.value
      end
    end,
    
    outlet = function (self, n)
      if type(n)=="string" then
        return self.outputs[self.outputs.indices[n]]
      elseif type(n)=="number" then
        return self.outputs[n]
      end
    end,
    
    get_width = function (self)
      return #self.inputs + #self.values + #self.outputs
    end,
    
    contains_connection = function (self, con)
      local inlet = self:inlet(con.target.port_id)
      if (inlet.source and inlet.source.source.module == con.source.module and inlet.source.source.port_id == con.source.port_id) then
        return inlet.source
      else
        return nil
      end
    end,
    
    write = function (self, n, v)
      self:outlet(n).signal = v
    end,
    
    in_area = function (self,x,y)
      local w = #self.inputs + #self.values + #self.outputs
      return (y==self.y and x>=self.x and x<self.x+w)
    end,
    
    get_cell = function (self,x,y)
      if self:in_area(x,y) then
        return x-self.x+1
      end
      return nil
    end,
    
    get_port_name = function (self, c)
      if c<=#self.inputs then
        return self.inputs.names[c]
      elseif c<=#self.inputs+#self.values then
        return "value"
      else
        return self.outputs.names[c-(#self.inputs+#self.values)]
      end
    end,
    
    get_type = function (self,c)
      if c<=#self.inputs then
        return "input"
      elseif c<=#self.inputs+#self.values then
        return "value"
      else
        return "output"
      end
    end,
    
    get_port = function (self, p)
      local port = nil
      if p<=#self.inputs then
        port = self.inputs[p]
      elseif self.values and p<=#self.inputs+#self.values then
        port = self.values[p-#self.inputs]
      elseif p>#self.inputs+#self.values then
        p = p-#self.values-#self.inputs
        port = self.outputs[p]
      end
      return port
    end,
    
    change_param = function (self, p, d)
      if #self.params>0 then
        local param = self.params[p]
        if param.options then
          param.value = util.clamp(param.value+d,1,#param.options)
        elseif param.min and param.max and param.delta then
          param.value = util.clamp(param.value+d*param.delta,param.min,param.max)
        end
      end
    end,
    
    grid_event = function (self,x,y,z)
      if self:in_area(x,y) then
        x = x-self.x+1
        y = y-self.y+1
        
        if x>#self.inputs and x<=#self.inputs+#self.values then
          x = x-#self.inputs
          self:grid_ui(x,y,z)
        end
        
      end
    end,
    
    grid_ui = function (self,x,y,z) end,
    
    show_ui = function (self,x,y,g) end,
    
    show = function (self, g)
      -- show inputs
      for i=1, #self.inputs do
        local l = Signal.map(self:inlet(i).signal,3,15,1)
        g:led(self.x+i-1,self.y,l)
      end
      
      -- show ui
      self:show_ui(self.x+#self.inputs-1,self.y,g)
      
      -- show outputs
      for i=1, #self.outputs do
        local l = Signal.map(self:outlet(i).signal,3,15,1)
        g:led(self.x+#self.values+#self.inputs+i-1,self.y,l)
      end
    end
  }
end