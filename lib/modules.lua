modules = {
  {
    name = "clock",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "clock")
      -- INPUTS
      -- VALUES
      -- OUTPUTS
      m:add_output("start",OUT.new())
      m:add_output("stop",OUT.new())
      m:add_output("4ppq",OUT.new())
      -- FIELDS
      m.pulse = 0
      -- CTRL
      m.ctrl_rate = function (self)
        local p = util.round(clock.get_beats()*8,1)
        
        -- TODO: start & stop trigger
        
        if p/2~=self.pulse and p%2==0 then
          self:write("4ppq",1)
        else
          self:write("4ppq",0)
        end
      end
      return m
    end
  },
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
        local f = self:inlet("frequency"):read()
        local a = self:inlet("amplitude"):read()
        local delta = (CTRL_RATE) * 2 * math.pi
        local freq = Signal.map(f.signal,0.01,3)
        self.phase = self.phase + delta * freq
        local v = (1+math.sin(self.phase))/2 * a.signal
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
        local v = self:inlet("signal"):read()
        v = Signal.map(v.signal,1,0)
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
      m:add_input("gate",IN.new(0,0))
      -- VALUES
      m.state = false
      -- OUTPUTS
      m:add_output("gate",OUT.new())
      -- FIELDS
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate"):read() -- => {signal=..., phase=...}
        if g.phase=="rising" then
          self.state = not self.state
        end
        self:write("gate",self.state and 1 or 0)
      end
      return m
    end
  },
  {
    name = "S&H",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "S&H")
      -- INPUTS
      m:add_input("gate",IN.new(0,0))
      m:add_input("cv",IN.new(0.5))
      -- VALUES
      m.state = {triggered=false, cv=0}
      -- OUTPUTS
      m:add_output("cv",OUT.new())
      -- FIELDS
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate"):read()
        local cv = self:inlet("cv"):read()
        if g.phase=="rising" then
          self.state.cv = self:inlet("cv").source and cv.signal or (math.random() * cv.signal)
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
      m:add_input("gate",IN.new(0,0))
      m:add_input("chance",IN.new(0.5))
      -- OUTPUTS
      m:add_output("A",OUT.new())
      m:add_output("B",OUT.new())
      -- FIELDS
      m.last_gate ="A"
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate"):read()
        local t = self:inlet("chance"):read()
        local r = math.random()
        
        if g.phase=="rising" then
          self.last_gate = (r<t.signal and "B" or "A")
          self:write(self.last_gate,1)
        elseif g.phase=="falling" then
          self:write(self.last_gate,0)
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
      m:add_input("gate",IN.new(0,0))
      m:add_input("reset",IN.new(0,0))
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
      m.counter = 0
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate"):read()
        local r = self:inlet("reset"):read()
        if g.phase=="rising" then
          self.counter = self.counter + 1
        end
        if r.phase=="rising" then
          self.counter = 0
        end
        for i=1,8 do
          self:write(i,(self.counter%i==0 and g.signal<0.5) and 1 or 0)
        end
      end
      return m
    end
  },
  {
    name = "sequencer",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "sqncr")
      -- INPUTS
      m:add_input("gate",IN.new(0,0))
      m:add_input("reset",IN.new(0,0))
      -- OUTPUTS
      m:add_output("cv",OUT.new())
      m:add_output("gate",OUT.new())
      -- FIELDS
      m.values = {}
      for i=1,8 do m.values[i] = VALUE.new(0,0) end
      m.step = #m.values
      --m.ui_width = #m.values
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate"):read()
        local r = self:inlet("reset"):read()
        if g.phase=="rising" then self.step = util.wrap(self.step+1,1,#self.values) end
        if r.phase=="rising" then self.step = #self.values end
        local v = self.values[self.step]
        self:write("cv",v.level)
        self:write("gate",(v.gate==1 and g.gate==1) and 1 or 0)
      end
      m.show_ui = function (self,x_off,y_off,g)
        for i,v in pairs(self.values) do
          local l = Signal.map(v.bias,3,10,1) + v.gate*5
          if i==self.step then l=l+5 end
          l = util.clamp(l,0,15)
          g:led(x_off+i,y_off,l)
        end
      end
      m.grid_ui = function (self,x,y,z)
        if z==1 then VALUE.toggle(self.values[x]) end
      end
      return m
    end
  },
  --[[{
    name = "gate_sequencer",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "gate_sequencer")
      -- INPUTS
      m:add_input("gate",IN.new(0))
      m:add_input("reset",IN.new(0))
      -- OUTPUTS
      m:add_output("signal",OUT.new())
      -- FIELDS
      m.ui_width = 8
      m.seq = {0,0,0,0,0,0,0,0}
      m.step = 8
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate"):read()
        local r = self:inlet("reset"):read()
        if g.phase=="rising" then
          self.step = util.wrap(self.step+1,1,8)
        end
        if r.phase=="rising" then
          self.step = 8
        end
        local v = (g.triggered and self.seq[self.step]==1) and 1 or 0
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
  },--]]
  {
    name = "quantizer",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "quantizer")
      -- INPUTS
      m:add_input("unquantized",IN.new(0))
      --VALUES
      local def = {1,0,1,0,0,1,0,1,0,1,0,0}
      for i=1,12 do m.values[i] = VALUE.new(nil,def[i]) end
      -- OUTPUTS
      m:add_output("signal",OUT.new(0))
      -- FIELDS
      m.q = 1
      -- CTRL
      m.ctrl_rate = function (self)
        local v = self:inlet("unquantized"):read().signal * 120 -- -> 0-120
        local oct = math.floor(v/12)
        local i = util.round(v,1)%12
        
        -- contained in map
        if self.values[i+1].gate==1 then
          v = oct*12 + i
          self.q = i+1
        -- not contained
        else
          local min_d = 12
          local min_i = 0
          for p=1,12 do
            if self.values[p].gate==1 then
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
      
      m.show_ui = function (self,x_off,y_off,g)
        for i=1,12 do
          local l = self.values[i].gate==1 and 10 or 3
          if i==self.q then l=15 end
          g:led(x_off+i,y_off,l)
        end
      end
      m.grid_ui = function (self,x,y,z)
        VALUE.toggle(self.values[x])
      end
      return m
    end
  },
  {
    name = "midi_out",
    new = function (x,y)
      local m = zorns_module(x and x or 0, y and y or 0, "midi_out")
      -- INPUTS
      m:add_input("gate",IN.new(0,0))
      m:add_input("pitch",IN.new(0))
      m:add_input("velocity",IN.new(0.5))
      m:add_input("channel",IN.new(0))
      -- OUTPUTS
      -- FIELDS
      m.state = {pitch=0, velocity=0, channel=1}
      --m.device = nil
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate"):read()
        local p = Signal.to_midi(self:inlet("pitch"):get())
        local v = Signal.to_midi(self:inlet("velocity"):get())
        local ch = Signal.map(self:inlet("channel"):get(),1,16,1)
        
        if g.phase=="rising" then
          self.state = {pitch=p, velocity=v, channel=ch}
          m_out:note_on(p,v,ch)
        elseif g.phase=="falling" then
          m_out:note_off(self.state.pitch,0,self.state.channel)
        end
      end
      return m
    end
  }
}