modules = {
  {
    name = "lfo",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "lfo")
      -- INPUTS
      m:add_input("frequency",IN.new(0.25))
      m:add_input("amplitude",IN.new(1))
      -- VALUES
      -- OUTPUTS
      m:add_output("signal",OUT.new())
      -- FIELDS
      m.phase = 0
      -- CTRL
      m.ctrl_rate = function (self)
        local delta = (CTRL_RATE) * 2 * math.pi
        local freq = Signal.map(self:read("frequency"),0.01,3)
        self.phase = self.phase + delta * freq
        local v = (1+math.sin(self.phase))/2 * self:read("amplitude")
        self:write("signal",v)
      end
      return m
    end
  },
  {
    name = "inverter",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "inv")
      -- INPUTS
      m:add_input("signal",IN.new(0))
      -- VALUES
      -- OUTPUTS
      m:add_output("signal",OUT.new())
      -- FIELDS
      -- CTRL
      m.ctrl_rate = function (self)
        local v = Signal.map(self:read("signal"),1,0)
        self:write("signal",v)
      end
      return m
    end
  },
  {
    name = "latch",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "latch")
      -- INPUTS
      m:add_input("gate",IN.new(0))
      -- VALUES
      m.state = {triggered=false, on=false}
      -- OUTPUTS
      m:add_output("gate",OUT.new())
      -- FIELDS
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read("gate")
        local phase = IN.triggered(g,self.state)
        if phase=="rising" then
          self.state.on = not self.state.on
        end
        self:write("gate",self.state.on and 1 or 0)
      end
      return m
    end
  },
  {
    name = "S&H",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "S&H")
      -- INPUTS
      m:add_input("gate",IN.new(0))
      m:add_input("cv",IN.new(0.5))
      -- VALUES
      m.state = {triggered=false, cv=0}
      -- OUTPUTS
      m:add_output("cv",OUT.new())
      -- FIELDS
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read("gate")
        local cv = self:read("cv")
        local phase = IN.triggered(g,self.state)
        if phase=="rising" then
          self.state.cv = self.inputs[2].source and cv or (math.random() * cv)
        end
        self:write("cv",self.state.cv)
      end
      return m
    end
  },
  {
    name = "bernoulli_gate",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "b_gate")
      -- INPUTS
      m:add_input("gate",IN.new(0))
      m:add_input("chance",IN.new(0.5))
      -- OUTPUTS
      m:add_output("A",OUT.new())
      m:add_output("B",OUT.new())
      -- FIELDS
      m.state = {triggered=false, gate="A"}
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read("gate")
        local t = self:read("chance")
        
        local r = math.random()
        local trig = false
        
        if not self.state.triggered and g>=0.5 then
          self.state = {triggered=true, gate=(r<t and "B" or "A")}
          trig = true
        elseif self.state.triggered and g<0.5 then
          self.state.triggered = false
          trig = true
        end
        
        if trig then
          g = self.state.triggered and 1 or 0
          local o = self.state.gate
          self:write(o,g)
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
      m:add_input("gate",IN.new(0))
      m:add_input("reset",IN.new(0))
      -- OUTPUTS
      m:add_output("/1",OUT.new())
      m:add_output("/2",OUT.new())
      m:add_output("/3",OUT.new())
      m:add_output("/4",OUT.new())
      m:add_output("/5",OUT.new())
      m:add_output("/6",OUT.new())
      m:add_output("/7",OUT.new())
      m:add_output("/8",OUT.new())
      -- FIELDS
      m.state = {triggered=false}
      m.counter = 0
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read("gate")
        local phase = IN.triggered(g,self.state)
        if phase=="rising" then
          self.counter = self.counter + 1
        end
        for i=1,8 do
          self:write(i,(self.counter%i==0 and g>=0.5) and 1 or 0)
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
      m:add_input("gate",IN.new(0))
      m:add_input("reset",IN.new(0))
      -- OUTPUTS
      m:add_output("signal",OUT.new())
      -- FIELDS
      m.state = {triggered=false}
      m.ui_width = 8
      m.seq = {0,0,0,0,0,0,0,0}
      m.step = 1
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read("gate")
        local phase = IN.triggered(g,self.state)
        if phase=="rising" then
          self.step = util.wrap(self.step+1,1,8)
        end
        local v = (self.state.triggered and self.seq[self.step]==1) and 1 or 0
        self:write("signal",v)
      end
      m.show_ui = function (self,x_off,y_off,g)
        for i=1,8 do
          local l = self.seq[i]==1 and 10 or 3
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
      m:add_input("unquantized",IN.new(0))
      -- OUTPUTS
      m:add_output("signal",OUT.new(0))
      -- FIELDS
      m.map = {1,0,1,0,0,1,0,1,0,1,0,0}
      m.q = 1
      -- CTRL
      m.ctrl_rate = function (self)
        local v = self:read("unquantized") * 120 -- -> 0-120
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
        
        v = v/120
        self:write("signal",v)
      end
      
      m.ui_width = 12
      m.show_ui = function (self,x_off,y_off,g)
        for i=1,12 do
          local l = self.map[i]==1 and 10 or 3
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
      m:add_input("gate",IN.new(0))
      m:add_input("pitch",IN.new(0))
      m:add_input("velocity",IN.new(0.5))
      m:add_input("channel",IN.new(0))
      -- OUTPUTS
      -- FIELDS
      m.state = {triggered=false, pitch=0, velocity=0, channel=1}
      m.device = nil
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:read("gate")
        local p = Signal.to_midi(self:read("pitch"))
        local v = Signal.to_midi(self:read("velocity"))
        local ch = Signal.map(self:read("channel"),1,16,1)
        
        local phase = IN.triggered(g,self.state)
        if phase=="rising" then
          self.state = {triggered=true, pitch=p, velocity=v, channel=ch}
          m_out:note_on(p,v,ch)
        elseif phase=="falling" then
          m_out:note_off(self.state.pitch,0,self.state.channel)
        end
      end
      return m
    end
  }
}