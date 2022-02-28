modules = {
  {
    name = "lfo",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "lfo")
      -- INPUTS
      m:add_input_field("frequency",Signal.new(1))
      m:add_input_field("amplitude",Signal.new(1))
      -- OUTPUTS
      m:add_output_field("signal",Signal.new(0))
      -- FIELDS
      m.phase = 0
      -- CTRL
      m.ctrl_rate = function (self)
        local delta = (CTRL_RATE) * 2 * math.pi
        local freq = Signal.map(self:read_in("frequency"),0.01,10)
        self.phase = self.phase + delta * freq
        local v = math.sin(self.phase) * Signal.map(self:read_in("amplitude"),0,5)
        self:write_out("signal",v)
      end
      return m
    end
  },
  {
    name = "bernoulli_gate",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "bernoulli_gate")
      -- INPUTS
      m:add_input_field("gate",Signal.new(1))
      m:add_input_field("tendency",Signal.new(0))
      -- OUTPUTS
      m:add_output_field("A",Signal.new(0))
      m:add_output_field("B",Signal.new(0))
      -- FIELDS
      m.state = {triggered=false, gate="A"}
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read_in("gate")
        local t = self:read_in("tendency")
        
        local r = math.random()*10-5
        local trig = false
        
        if not self.state.triggered and g>=0 then
          self.state = {triggered=true, gate=(r<t and "B" or "A")}
          trig = true
        elseif self.state.triggered and g<0 then
          self.state.triggered = false
          trig = true
        end
        
        if trig then
          g = self.state.triggered and 5 or -5
          local o = self.state.gate
          self:write_out(o,g)
        end
        
      end
      return m
    end
  },
  {
    name = "clock_div",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "clock_div")
      -- INPUTS
      m:add_input_field("gate",Signal.new(1))
      m:add_input_field("reset",Signal.new(0))
      -- OUTPUTS
      m:add_output_field("/1",Signal.new(0))
      m:add_output_field("/2",Signal.new(0))
      m:add_output_field("/3",Signal.new(0))
      m:add_output_field("/4",Signal.new(0))
      m:add_output_field("/5",Signal.new(0))
      m:add_output_field("/6",Signal.new(0))
      m:add_output_field("/7",Signal.new(0))
      m:add_output_field("/8",Signal.new(0))
      -- FIELDS
      m.state = {triggered=false}
      m.counter = 0
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read_in("gate")
        
        if not self.state.triggered and g>=0 then
          self.state = {triggered=true}
          self.counter = self.counter + 1
        elseif self.state.triggered and g<0 then
          self.state = {triggered=false}
        end
        
        for i=1,8 do
          self:write_out(i,(self.counter%i==0 and g>0) and 5 or -5)
        end
        
      end
      return m
    end
  },
  {
    name = "gate_sequencer",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "gate_sequencer")
      -- INPUTS
      m:add_input_field("gate",Signal.new(1))
      m:add_input_field("reset",Signal.new(0))
      -- OUTPUTS
      m:add_output_field("signal",Signal.new(0))
      -- FIELDS
      m.state = {triggered=false}
      m.ui_width = 8
      m.seq = {0,0,0,0,0,0,0,0}
      m.step = 1
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read_in("gate")
        
        if not self.state.triggered and g>=0 then
          self.state = {triggered=true}
          self.step = util.wrap(self.step+1,1,8)
        elseif self.state.triggered and g<0 then
          self.state = {triggered=false}
        end
        
        local v = (self.state.triggered and self.seq[self.step]==1) and 5 or -5
        self:write_out("signal",v)
      end
      m.show_ui = function (self,x_off,y_off,g)
        for i=1,8 do
          local l = self.seq[i]==1 and 10 or 5
          if i==self.step then l=l+5 end
          g:led(x_off+i,y_off,l)
        end
      end
      m.grid_ui = function (self,x,y,z)
        if z==1 and self.seq[x]==1 then self.seq[x]=0
        elseif z==1 and self.seq[x]==0 then self.seq[x]=1 end
      end
      return m
    end
  },
  {
    name = "quantizer",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "quantizer")
      -- INPUTS
      m:add_input_field("unquantized",Signal.new(0))
      -- OUTPUTS
      m:add_output_field("signal",Signal.new(0))
      -- FIELDS
      m.map = {1,0,1,0,0,1,0,1,0,1,0,0}
      m.q = 1
      -- CTRL
      m.ctrl_rate = function (self)
        local v = (self:read_in("unquantized") + 5 ) * 12 -- -> 0-120
        local oct = math.floor(v/12)
        local i = util.round(v,1)%12
        
        -- contained in map
        if self.map[i+1]==1 then
          v = oct*12 + i
          self.q = i+1
        -- not contained
        else
          local min_d = 12
          local min_i = 0
          for p=1,12 do
            if self.map[p]==1 then
              local d = math.abs((i+1)-p)
              if d<min_d then
                min_d = d
                min_i = p
              end
            end
          end
          v = oct*12 + (min_i-1)
          self.q = min_i
        end
        
        v = v/12 - 5
        self:write_out("signal",v)
      end
      
      m.ui_width = 12
      m.show_ui = function (self,x_off,y_off,g)
        for i=1,12 do
          local l = self.map[i]==1 and 10 or 5
          if i==self.q then l=15 end
          g:led(x_off+i,y_off,l)
        end
      end
      m.grid_ui = function (self,x,y,z)
        if z==1 and self.map[x]==1 then self.map[x]=0
        elseif z==1 and self.map[x]==0 then self.map[x]=1 end
      end
      return m
    end
  },
  {
    name = "midi_out",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "midi_out")
      -- INPUTS
      m:add_input_field("gate",Signal.new(0))
      m:add_input_field("pitch",Signal.new(0))
      m:add_input_field("velocity",Signal.new(0))
      -- OUTPUTS
      --
      -- FIELDS
      m.state = {triggered=false, pitch=0, velocity=0}
      m.device = nil
      m.channel = 1
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read_in("gate")
        local p = self:read_in("pitch")
        local v = self:read_in("velocity")
        
        if not self.state.triggered and g>=0 then
          
          p = Signal.to_midi(p)
          --print("*",p)
          self.state = {triggered=true, pitch=p, velocity=v}
          m_out:note_on(self.state.pitch,100,self.channel)
        elseif self.state.triggered and g<0 then
          m_out:note_off(self.state.pitch,0,self.channel)
          self.state = {triggered=false, pitch=0, velocity=0}
        end
      end
      return m
    end
  }
}