zorns_module = function (_x,_y,_n)
  return {
    name = _n,
    x = _x,
    y = _y,
    
    inputs = {names={},indices={}},
    values = {},
    outputs = {names={},indices={}},
    main_param = 0,
    
    ctrl_rate = function (self) end,
    
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
    
    contains_connection = function (self, con)
      local inlet = self:inlet(con.target.port)
      if (inlet.source and inlet.source.source.module == con.source.module and inlet.source.source.port == con.source.port) then
        return inlet.source
      else
        return nil
      end
    end,
    
    add_connection = function (self, c, con)
      local inlet = self.inputs[c]
      inlet.source = con
    end,
    
    read = function (self, n)
      return IN.read(self:inlet(n))
    end,
    
    write = function (self, n, v)
      OUT.set(self:get_out(n),v)
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
    
    --[[get_in = function (self, n)
      if type(n)=="string" then
        return self.inputs[self.inputs.indices[n] ]
      elseif type(n)=="number" then
        return self.inputs[n]
      end
    end,--]]
    
    inlet = function (self, n)
      if type(n)=="string" then
        return self.inputs[self.inputs.indices[n]]
      elseif type(n)=="number" then
        return self.inputs[n]
      end
    end,
    
    get_out = function (self, n)
      if type(n)=="string" then
        return self.outputs[self.outputs.indices[n]]
      elseif type(n)=="number" then
        return self.outputs[n]
      end
    end,
    
    outlet = function (self, n)
      if type(n)=="string" then
        return self.outputs[self.outputs.indices[n]]
      elseif type(n)=="number" then
        return self.outputs[n]
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
    
    enc = function (self, d)
      self.main_param = util.clamp(self.main_param+d*0.01,0,1)
      self:param_change()
    end,
    
    param_change = function (self) end,
    
    show_param = function (self)
      return self.main_param
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
        --local l = Signal.map(self:inlet(i):get(),3,15,1)
        local l = Signal.map(self:read(i).signal,3,15,1)
        g:led(self.x+i-1,self.y,l)
      end
      
      -- show ui
      self:show_ui(self.x+#self.inputs-1,self.y,g)
      
      -- show outputs
      for i=1, #self.outputs do
        local l = Signal.map(OUT.get(self:get_out(i)),3,15,1)
        g:led(self.x+#self.values+#self.inputs+i-1,self.y,l)
      end
    end
  }
end