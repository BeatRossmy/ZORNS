catalogue = {
  -- ===========================================
  -- =================== I/O ===================
  -- ===========================================
  {
    name = "I/O",
    modules = {
      {
        name = "clock",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "clock")
          -- OUTPUTS
          --m:add_output("start",OUT.new())
          --m:add_output("stop",OUT.new())
          m:add_output("pulse",OUT.new())
          -- PARAMS
          m:add_param({name="ppq",value=3,options=main_clock.div_names})
          -- FIELDS
          m.pulse = 0
          -- CTRL
          m.ctrl_rate = function (self)
            local ppq = g.source and 1 or self:param("ppq")
            local phase = main_clock:get_phase(ppq)
            if phase==1 then
              --print(clock.get_beats(), main_clock:get(ppq))
              self:write("pulse",1)
            elseif phase==-1 then
              self:write("pulse",0)
            end
          end
          return m
        end
      },
      {
        name = "note/o",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "note/o")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          m:add_input("pitch",IN.new(0))
          m:add_input("velocity",IN.new(0.5))
          m:add_input("channel",IN.new(0))
          -- PARAMS
          m:add_param({name="dev",value=1,options=midi_device_names})
          -- FIELDS
          m.state = {pitch=0, velocity=0, channel=1}
          -- CTRL
          m.ctrl_rate = function (self)
            local phase = self:inlet("gate").phase
            if phase==1 then -- "rising"
              local p = Signal.to_midi(self:inlet("pitch").signal)
              local v = Signal.to_midi(self:inlet("velocity").signal)
              local ch = Signal.map(self:inlet("channel").signal,1,16,1)
              self.state = {pitch=p, velocity=v, channel=ch, dev=self:param("dev")}
              connected_midi_devices[self.state.dev]:note_on(p,v,ch)
            elseif phase==-1 then -- "falling"
              connected_midi_devices[self.state.dev]:note_off(self.state.pitch,0,self.state.channel)
            end
          end
          return m
        end
      },
      {
        name = "engine_out",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "engine_out")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          m:add_input("hz",IN.new(0))
          m:add_input("amp",IN.new(0.5))
          m:add_input("cutoff",IN.new(0.5))
          -- CTRL
          m.ctrl_rate = function (self)
            local phase = self:inlet("gate").phase
            if phase==1 then -- "rising"
              local hz = Signal.to_midi(self:inlet("hz").signal)
              local v = self:inlet("amp").signal
              local f = self:inlet("cutoff").signal
              hz = musicutil.note_num_to_freq(hz)
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
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "lfo")
          -- INPUTS
          m:add_input("freq",IN.new(0.25))
          m:add_input("amp",IN.new(1))
          -- PARAMS
          m:add_param({name="shape",value=1,options={"sine","tri","ramp","rect"}})
          -- OUTPUTS
          m:add_output("signal",OUT.new())
          -- FIELDS
          m.phase = 0
          m.lfo_functions = {lfo_sine,lfo_tri,lfo_ramp,lfo_rect}
          -- CTRL
          m.ctrl_rate = function (self)
            local f = self:inlet("freq").signal
            local a = self:inlet("amp").signal
            local delta = CTRL_RATE * 2 * math.pi
            local freq = Signal.map(f,0.01,3)
            self.phase = self.phase + delta * freq
            local v = self.lfo_functions[self:param("shape")](self.phase) * a
            self:write("signal",v)
          end
          return m
        end
      },
      {
        name = "S&H",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "S&H")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          m:add_input("cv",IN.new(0.5))
          -- OUTPUTS
          m:add_output("cv",OUT.new())
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:inlet("gate")
            if not g.source or g.phase==1 then -- "rising"
              local cv = self:inlet("cv").signal
              cv = self:inlet("cv").source and cv or (math.random() * cv)
              self:write("cv",cv)
            end
          end
          return m
        end
      },
      {
        name="math",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "math")
          -- INPUTS
          m:add_input("A",IN.new(0))
          m:add_input("B",IN.new(0.5))
          -- OUTPUTS
          m:add_output("C",OUT.new())
          -- PARAMS
          m:add_param({name="oprtr",value=3,options={"+","-","*","/","^"}})
          m.operations = {math_add,math_sub,math_mult,math_div,math_pow}
          m:add_param({name="qnt",value=1,options={0,1/2,1/3,1/4,1/10,1/120}})
          -- CTRL
          m.ctrl_rate = function (self)
            local a = self:inlet("A").signal
            local b = self:inlet("B").signal
            local c = self.operations[self:param("oprtr")](a,b)
            local q = self:param("qnt")
            c = util.round(c,q)
            self:write("C",c)
          end
          return m
        end
      },
      {
        name = "+oct",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "+oct")
          -- INPUTS
          m:add_input("signal",IN.new(0))
          m:add_input("offset",IN.new(0.5))
          -- OUTPUTS
          m:add_output("signal",OUT.new())
          -- CTRL
          m.ctrl_rate = function (self)
            local s = self:inlet("signal").signal
            local o = self:inlet("offset").signal
            local v = s + util.round(o,0.1)
            self:write("signal",v)
          end
          return m
        end
      },
      {
        name = "sqncr",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "sqncr")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          m:add_input("reset",IN.new(0,false))
          -- OUTPUTS
          m:add_output("cv",OUT.new())
          m:add_output("gate",OUT.new())
          -- FIELDS
          m.values = {}
          for i=1,8 do m.values[i] = VALUE.new(0,false) end
          --m.step = #m.values
          m.step = 0
          -- PARAMS
          m:add_param({name="ppq",value=3,options=main_clock.div_names})
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:inlet("gate")
            local r = self:inlet("reset")
            
            local ppq = g.source and 1 or self:param("ppq")
            local phase = g.source and g.phase or main_clock:get_phase(ppq)
            
            if r.phase==1 then self.step = 0 end
            if phase==1 then
              local s = g.source and (self.step+1) or (main_clock:get(ppq))
              self.step = wrap(s,1,#self.values)
              local v = self.values[self.step]
              local t = v.gate
              -- t = t and (g.source and g.gate or main_clock:get_pulse(ppq))
              self:write("cv",v.value)
              self:write("gate",t and 1 or 0)
            elseif phase==-1 then
              self:write("gate",0)
            end
          end
          
          m.show_ui = function (self,x_off,y_off,g)
            for i,v in pairs(self.values) do
              local l = Signal.map(v.value,3,10,1) + (v.gate and 5 or 0)
              --if i==util.wrap(self.step,1,#self.values) then l=l+5 end
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
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "euclid")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          m:add_input("pulses",IN.new(0.3))
          m:add_input("length",IN.new(0.25))
          m:add_input("offset",IN.new(0))
          -- OUTPUTS
          m:add_output("gate",OUT.new())
          -- PARAMS
          m:add_param({name="ppq",value=3,options=main_clock.div_names})
          -- FIELDS
          m.counter = 0
          m.rhythm = {}
          --m.ui_width = #m.values
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:inlet("gate")
            
            local ppq = g.source and 1 or self:param("ppq")
            local phase = g.source and g.phase or main_clock:get_phase(ppq)
            
            if phase==1 then -- "rising"
              self.counter = g.source and (self.counter+1) or main_clock:get(ppq)
              local l = Signal.map(self:inlet("length").signal,1,64,1)
              local p = Signal.map(self:inlet("pulses").signal,0,l,1)
              local o = Signal.map(self:inlet("offset").signal,0,l,1)
              self.rhythm = er.gen(p,l,o)                                       -- <== TODO: avoid generating patterns all over
              local state = self.rhythm[wrap(self.counter,1,#self.rhythm)]
              self:write("gate", state and 1 or 0)
            elseif phase==-1 then -- "falling"  
              self:write("gate", 0)
            end
            
          end
          return m
        end
      },
      {
        name = "scale",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "scale")
          -- INPUTS
          m:add_input("signal",IN.new(0))
          -- OUTPUTS
          m:add_output("signal",OUT.new(0))
          -- PRAMS
          m:add_param({name="scale",value=3,options={"major","minor","penta"}})
          m:add_param({name="root",value=1,options={"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}})
          m:add_param({name="oct",value=3,options={-24,-12,0,12,24}})
          -- CTRL
          m.ctrl_rate = function (self)
            local v = self:inlet("signal").signal * 120 -- -> 0-120
            v = self:param("oct") + (self:param("root")-1) + musicutil.snap_note_to_array(v,scales[self:param("scale")])
            v = v/120
            self:write("signal",v)
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
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "bool")
          -- INPUTS
          m:add_input("A",IN.new(0,false))
          m:add_input("B",IN.new(0,false))
          -- OUTPUTS
          m:add_output("C",OUT.new())
          -- PARAMS
          m:add_param({name="oprtr",value=1,options={"&&","||","!&","^"}})
          m.logic_operations = {logic_and,logic_or,logic_nand,logic_xor}
          -- CTRL
          m.ctrl_rate = function (self)
            local a = self:inlet("A").gate
            local b = self:inlet("B").gate
            
            local o = self:param("oprtr")
            local c = m.logic_operations[o](a,b)
            
            self:write("C",c and 1 or 0)
          end
          return m
        end
      },
      {
        name = "p_div",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "p_div")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          m:add_input("reset",IN.new(0,false))
          -- OUTPUTS
          m:add_output("/1",OUT.new())
          m:add_output("/2",OUT.new())
          -- PARAMS
          m:add_param({name="ppq",value=3,options=main_clock.div_names})
          m:add_param({name="o1%",value=1,options={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}})
          m:add_param({name="o2%",value=3,options={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}})
          -- FIELDS
          m.counter = 0
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:inlet("gate")
            local r = self:inlet("reset")
            
            local ppq = g.source and 1 or self:param("ppq")
            local phase = g.source and g.phase or main_clock:get_phase(ppq)
            
            if phase==1 then -- "rising"
              self.counter = g.source and (self.counter+1) or main_clock:get(ppq)
              for i=1,2 do
                local t = self.counter%self:param(i+1)==0
                self:write(i, t and 1 or 0)
              end
            elseif phase==-1 then
              for i=1,2 do self:write(i, 0) end
            end
            
          end
          return m
        end
      },
      {
        name = "b_gate",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "b_gate")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          m:add_input("chance",IN.new(0.5))
          -- OUTPUTS
          m:add_output("A",OUT.new())
          m:add_output("B",OUT.new())
          -- PARAMS
          m:add_param({name="ppq",value=3,options=main_clock.div_names})
          -- FIELDS
          m.last_gate ="A"
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:inlet("gate")
            
            local ppq = g.source and 1 or self:param("ppq")
            local phase = g.source and g.phase or main_clock:get_phase(ppq)
            
            if phase==1 then -- "rising"
              local t = self:inlet("chance").signal
              local r = math.random()
              self.last_gate = (r<t and "B" or "A")
              self:write(self.last_gate,1)
            elseif phase==-1 then -- "falling"
              self:write(self.last_gate,0)
            end
            
          end
          return m
        end
      },
      {
        name = "inv",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "inv")
          -- INPUTS
          m:add_input("signal",IN.new(0))
          -- VALUES
          -- OUTPUTS
          m:add_output("signal",OUT.new())
          -- FIELDS
          -- CTRL
          m.ctrl_rate = function (self)
            local v = self:inlet("signal").signal
            v = Signal.map(v,1,0)
            self:write("signal",v)
          end
          return m
        end
      },
      {
        name = "latch",
        new = function (x,y,id)
          local m = zorns_module(x and x or 0, y and y or 0, id, "latch")
          -- INPUTS
          m:add_input("gate",IN.new(0,false))
          -- VALUES
          m.state = false
          -- OUTPUTS
          m:add_output("gate",OUT.new())
          -- FIELDS
          -- CTRL
          m.ctrl_rate = function (self)
            local g = self:inlet("gate")
            if g.phase==1 then -- "rising"
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