catalogue = {
  -- ===========================================
  -- =================== I/O ===================
  -- ===========================================
  {
    name = "I/O",
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
            local g = self:read("gate")
            
            
            if g.phase=="rising" then
              local p = Signal.to_midi(self:read("pitch").signal)
              local v = Signal.to_midi(self:read("velocity").signal)
              local ch = Signal.map(self:read("channel").signal,1,16,1)
              self.state = {pitch=p, velocity=v, channel=ch}
              m_out:note_on(p,v,ch)
            elseif g.phase=="falling" then
              m_out:note_off(self.state.pitch,0,self.state.channel)
            end
          end
          return m
        end
      },
      {
        name = "engine_out",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "engine_out")
          -- INPUTS
          m:add_input("gate",IN.new(0,0))
          m:add_input("hz",IN.new(0))
          m:add_input("amp",IN.new(0.5))
          m:add_input("cutoff",IN.new(0.5))
          --m:add_input("release",IN.new(0.5))
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:read("gate")
            
            if g.phase=="rising" then
              local hz = Signal.to_midi(self:read("hz").signal)
              local v = self:read("amp").signal
              local f = self:read("cutoff").signal
              --local rel = self:read("release").signal
              
              hz = musicutil.note_num_to_freq(hz)
              
              --engine.release(Signal.map(rel,0.1,3.2))
              engine.cutoff(f*5000)
              engine.amp(v)
              engine.hz(hz)
            end
          end
          return m
        end
      }
    }
  },
  -- ============================================
  -- =================== CTRL ===================
  -- ============================================
  {
    name = "CTRL",
    modules = {
      {
        name = "lfo",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "lfo")
          -- INPUTS
          m:add_input("frequency",IN.new(0.25))
          m:add_input("amplitude",IN.new(1))
          -- PARAMS
          m:add_param({name="shape",value=1,options={"sine","tri","ramp","rect"}})
          -- OUTPUTS
          m:add_output("signal",OUT.new())
          -- FIELDS
          m.phase = 0
          m.lfo_functions = {lfo_sine,lfo_tri,lfo_ramp,lfo_rect}
          -- CTRL
          m.ctrl_rate = function (self)
            local f = self:read("frequency")
            local a = self:read("amplitude")
            local delta = (CTRL_RATE) * 2 * math.pi
            local freq = Signal.map(f.signal,0.01,3)
            self.phase = self.phase + delta * freq
            local v = self.lfo_functions[self:param("shape")](self.phase) * a.signal
            self:write("signal",v)
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
            local g = self:read("gate")
            if g.phase=="rising" then
              local cv = self:read("cv")
              self.state.cv = self:inlet("cv").source and cv.signal or (math.random() * cv.signal)
            end
            self:write("cv",self.state.cv)
          end
          return m
        end
      },
      {
        name = "vca",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "vca")
          -- INPUTS
          m:add_input("signal",IN.new(0))
          m:add_input("amp",IN.new(0.5))
          -- OUTPUTS
          m:add_output("signal",OUT.new())
          -- CTRL
          m.ctrl_rate = function (self)
            local s = self:read("signal")
            local a = self:read("amp")
            local v = s.signal * a.signal
            self:write("signal",v)
          end
          return m
        end
      },
      {
        name = "add",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "add")
          -- INPUTS
          m:add_input("signal",IN.new(0))
          m:add_input("offset",IN.new(0.5))
          -- OUTPUTS
          m:add_output("signal",OUT.new())
          -- CTRL
          m.ctrl_rate = function (self)
            local s = self:read("signal")
            local o = self:read("offset")
            local v = s.signal + o.signal
            self:write("signal",v)
          end
          return m
        end
      },
      {
        name = "+oct",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "+oct")
          -- INPUTS
          m:add_input("signal",IN.new(0))
          m:add_input("offset",IN.new(0.5))
          -- OUTPUTS
          m:add_output("signal",OUT.new())
          -- CTRL
          m.ctrl_rate = function (self)
            local s = self:read("signal")
            local o = self:read("offset")
            local v = s.signal + util.round(o.signal,0.1)
            self:write("signal",v)
          end
          return m
        end
      },
      {
        name = "sqncr",
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
            local g = self:read("gate")
            local r = self:read("reset")
            if g.phase=="rising" then self.step = util.wrap(self.step+1,1,#self.values) end
            if r.phase=="rising" then self.step = #self.values end
            local v = self.values[self.step]
            self:write("cv",v.value)
            self:write("gate",(v.gate==1 and g.gate==1) and 1 or 0)
          end
          m.show_ui = function (self,x_off,y_off,g)
            for i,v in pairs(self.values) do
              local l = Signal.map(v.value,3,10,1) + v.gate*5
              if i==self.step then l=l+5 end
              l = util.clamp(l,0,15)
              g:led(x_off+i,y_off,l)
            end
          end
          m.grid_ui = function (self,x,y,z)
            if z==1 then PORT.toggle_gate(self.values[x]) end
          end
          return m
        end
      },
      {
        name = "euclid",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "euclid")
          -- INPUTS
          m:add_input("gate",IN.new(0,0))
          m:add_input("pulses",IN.new(0.5))
          m:add_input("length",IN.new(0.5))
          m:add_input("offset",IN.new(0.5))
          -- OUTPUTS
          m:add_output("gate",OUT.new())
          -- FIELDS
          m.counter = 0
          m.rhythm = {}
          --m.ui_width = #m.values
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:read("gate")
            
            if g.phase=="rising" then
              self.counter = self.counter+1
              local p = Signal.map(self:read("pulses").signal,1,64,1)
              local l = Signal.map(self:read("length").signal,1,64,1)
              local o = Signal.map(self:read("offset").signal,1,64,1)
              self.rhythm = er.gen(p,l,o)
            end
            
            local state = g.gate==1
            if state then state = state and #self.rhythm>0 end
            if state then state = state and self.rhythm[util.wrap(self.counter,1,#self.rhythm)] end
            self:write("gate", state and 1 or 0)
          end
          return m
        end
      },
      {
        name = "scale",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "scale")
          -- INPUTS
          m:add_input("signal",IN.new(0))
          -- OUTPUTS
          m:add_output("signal",OUT.new(0))
          -- PRAMS
          m:add_param({name="scale",value=3,options={"major","minor","penta"}})
          m:add_param({name="root",value=1,options={"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}})
          m:add_param({name="oct",value=3,options={"-24","-12","0","12","24"}})
          -- CTRL
          m.ctrl_rate = function (self)
            local v = self:read("signal").signal * 120 -- -> 0-120
            v = (self:param("oct")-3)*12 + (self:param("root")-1) + musicutil.snap_note_to_array(v,scales[self:param("scale")])
            v = v/120
            self:write("signal",v)
          end
          return m
        end
      },
      {
        name = "qntzr",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "qntzr")
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
            local v = self:read("unquantized").signal * 120 -- -> 0-120
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
            PORT.toggle_gate(self.values[x])
          end
          return m
        end
      }
    }
  },
  -- =============================================
  -- =================== LOGIC ===================
  -- =============================================
  {
    name = "LOGIC",
    modules = {
      {
        name = "bool",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "bool")
          -- INPUTS
          m:add_input("A",IN.new(0,0))
          m:add_input("B",IN.new(0,0))
          -- OUTPUTS
          m:add_output("C",OUT.new())
          -- PARAMS
          m:add_param({name="oprtr",value=1,options={"&&","||","!&","^"}})
          m.logic_operations = {logic_and,logic_or,logic_nand,logic_xor}
          -- CTRL
          m.ctrl_rate = function (self)
            local a = self:read("A")
            local b = self:read("B")
            
            local o = self:param("operation")
            local c = m.logic_operations[o](a.gate,b.gate)
            
            self:write("C",c and 1 or 0)
          end
          return m
        end
      },
      {
        name = "p_div",
        new = function (x,y)
          local m = zorns_module(x and x or 0, y and y or 0, "p_div")
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
            local g = self:read("gate")
            local r = self:read("reset")
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
        name = "b_gate",
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
            local g = self:read("gate")
            
            if g.phase=="rising" then
              local t = self:read("chance")
              local r = math.random()
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
        name = "inv",
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
            local v = self:read("signal")
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
            local g = self:read("gate")
            if g.phase=="rising" then
              self.state = not self.state
              self:write("gate",self.state and 1 or 0)
            end
          end
          return m
        end
      }
    }
  }
}

category_names = {}
module_names = {}
for i,c in pairs(catalogue) do
  category_names[i] = c.name
  module_names[i] = {[1]="none"}
  for j,m in pairs(c.modules) do
    module_names[i][j+1] = m.name
  end
end