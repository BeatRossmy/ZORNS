zorns_module = function (_x,_y,_n)
  return {
    name = _n,
    x = _x,
    y = _y,
    ui_width = 0,
    
    inputs = {names={},indices={}},
    outputs = {names={},indices={}},
    
    ctrl_rate = function (self) end,
    
    add_input_field = function (self, n, s)
      table.insert(self.inputs,s)
      self.inputs.indices[n] = #self.inputs
      self.inputs.names[#self.inputs] = n
      --self.inputs.names[n] = #self.inputs
    end,
    
    add_output_field = function (self, n, s)
      table.insert(self.outputs,s)
      self.outputs.indices[n] = #self.outputs
      self.outputs.names[#self.outputs] = n
      --self.outputs.names[n] = #self.outputs
    end,
    
    read_in = function (self, i)
      i = type(i)=="string" and self.inputs.indices[i] or i
      return self.inputs[i].value
    end,
    
    write_out = function (self, i, v)
      i = type(i)=="string" and self.outputs.indices[i] or i
      self.outputs[i].value = v
    end,
    
    in_area = function (self,x,y)
      local w = #self.inputs + self.ui_width + #self.outputs
      return (y==self.y and x>=self.x and x<self.x+w)
    end,
    
    get_port = function (self,x)
      local port = nil
      if x<=#self.inputs then
        port = {signal=self.inputs[x], module=self, type="inputs", name=self.inputs.names[x], index=x}
      elseif x>#self.inputs+self.ui_width then
        x = x-self.ui_width-#self.inputs
        port = {signal=self.outputs[x], module=self, type="outputs", name=self.outputs.names[x], index=x}
      end
      return port
    end,
    
    grid_event = function (self,x,y,z)
      local w = #self.inputs + self.ui_width + #self.outputs
      if y==self.y and x>=self.x and x<self.x+w then
        x = x-self.x+1
        y = y-self.y+1
        
        local sel_p = self:get_port(x)
        
        if x>#self.inputs and x<=#self.inputs+self.ui_width then
          x = x-#self.inputs
          self:grid_ui(x,y,z)
        else
          
          if not selected_port then
            if z==1 then selected_port = sel_p end
            
          elseif selected_port.module==sel_p.module and z==0 then
            selected_port = nil
            
          elseif selected_port.signal~=sel_p.signal and selected_port.type ~=sel_p.type and z==1 then
            -- assign connection
            local out_p = selected_port.type=="outputs" and selected_port or sel_p
            local in_p = selected_port.type=="inputs" and selected_port or sel_p
            
            print(in_p.name, out_p.name)
            
            in_p.module.inputs[in_p.index] = nil
            in_p.module.inputs[in_p.index] = out_p.signal
            
          end
          
        end
        
        --[[
        -- in inputs
        if x<=#self.inputs then
          
          if selected_port==nil then
            if z==1 then
              selected_port = {signal=self.inputs[x], module=self, type="inputs", name=self.inputs.names[x], index=x}
            end
          elseif selected_port.signal==self.inputs[x] and z==0 then
            selected_port = nil
          elseif selected_port.signal~=self.inputs[x] and z==1 then
            if selected_port.type=="outputs" then
              self.inputs[x] = selected_port.signal
            end
          end
          
        -- in ui
        elseif x<=#self.inputs+self.ui_width then
          x = x-#self.inputs
          self:grid_ui(x,y,z)
          
        -- in outputs
        else
          x = x-self.ui_width-#self.inputs
          if selected_port==nil then
            if z== 1 then
              selected_port = {signal=self.outputs[x], module=self, type="outputs", name=self.outputs.names[x], index=x}
            end
          elseif selected_port.signal==self.outputs[x] and z==0 then
            selected_port = nil
          elseif selected_port.signal~=self.outputs[x] and z==1 then
            if selected_port.type=="inputs" then
              self.outputs[x] = selected_port.signal
            end
          end
          
        end
        --]]
      end
    end,
    
    grid_ui = function (self,x,y,z) end,
    
    show_ui = function (self,x,y,g) end,
    
    show = function (self, g)
      -- show inputs
      for i=1, #self.inputs do
        local l = Signal.map(self.inputs[i].value,5,15,1)
        g:led(self.x+i-1,self.y,l)
      end
      
      -- show ui
      self:show_ui(self.x+#self.inputs-1,self.y,g)
      
      -- show outputs
      for i=1, #self.outputs do
        local l = Signal.map(self.outputs[i].value,5,15,1)
        g:led(self.x+self.ui_width+#self.inputs+i-1,self.y,l)
      end
    end
  }
end