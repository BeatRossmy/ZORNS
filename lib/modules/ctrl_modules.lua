local ctrl_modules = {
  {
    name = "lfo",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "lfo")
      -- INPUTS
      m:add_input("freq",IN.new(0.25,nil,{min=0.01,max=10,q=0.01}))
      m:add_input("amp",IN.new(1))
      -- PARAMS
      m:add_param({name="shape",value=1,options={"sine","tri","ramp","rect"}})
      m:add_param({name="pol",value=1,options={"polar","bipolar"}})
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
        local freq = SIGNAL.map(f,0.01,10)
        self.phase = self.phase + delta * freq
        local v = 0
        if self:param("pol")==2 then
          v = (self.lfo_functions[self:param("shape")](self.phase)-0.5) * a
        else
          v = self.lfo_functions[self:param("shape")](self.phase) * a
        end
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
      m:add_input("gate",IN.new(0,false,GATE_STATES))
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
      m:add_input("offset",IN.new(0.5,nil,{min=0,max=10,q=1}))
      -- OUTPUTS
      m:add_output("signal",OUT.new())
      -- CTRL
      m.ctrl_rate = function (self)
        local s = self:inlet("signal").signal
        local o = self:inlet("offset").signal
        --local v = s + util.round(o,0.1)
        local v = s + SIGNAL.xmap(o,0,1,0.1)
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
      m:add_input("gate",IN.new(0,false,GATE_STATES))
      m:add_input("reset",IN.new(0,false,GATE_STATES))
      -- OUTPUTS
      m:add_output("cv",OUT.new())
      m:add_output("gate",OUT.new())
      -- FIELDS
      m.value = {}
      for i=1,8 do
        m.value[i] = VALUE.new(0,false,NOTE_NAMES)
      end
      m.step = 0
      
      m.change_steps = function (self)
        local s = self:param("steps")
        if s<#self.value then
          for i=#self.value,s+1,-1 do
            self.value[i] = nil
          end
        elseif s>#self.value then
          for i=#self.value+1,s,1 do
            self.value[i] = VALUE.new(0,false,NOTE_NAMES)
          end
        end
      end
      -- PARAMS
      m:add_param({name="ppq",value=3,options=main_clock.div_names})
      m:add_param({name="steps",value=8,options={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},action=m.change_steps})
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate")
        local r = self:inlet("reset")
        
        local ppq = g.source and 1 or self:param("ppq")
        local phase = g.source and g.phase or main_clock:get_phase(ppq)
        
        if r.phase==1 then self.step = 0 end
        if phase==1 then
          local s = g.source and (self.step+1) or (main_clock:get(ppq))
          self.step = wrap(s,1,#self.value)
          local v = self.value[self.step]
          local t = v.gate
          self:write("cv",v.value)
          self:write("gate",t and 1 or 0)
        elseif phase==-1 then
          self:write("gate",0)
        end
      end
      
      m.show_ui = function (self,g)
        for i,v in pairs(self.value) do
          local l = SIGNAL.map(v.value,3,10,1) + (v.gate and 5 or 0)
          if i==self.step then l=l+5 end
          l = util.clamp(l,0,15)
          if selection and selection.module_id and selection.module_id~=self.id then l = math.floor(l*0.5) end
          g:led(self.x-1+i,self.y+1,l)
        end
      end
      m.grid_ui = function (self,x,y,z)
        if z==1 then PORT.toggle_gate(self.value[x]) end
      end
      return m
    end
  },
  {
    name = "euclid",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "euclid")
      -- INPUTS
      m:add_input("gate",IN.new(0,false,GATE_STATES))
      m:add_input("pulses",IN.new(0.3))
      m:add_input("length",IN.new(0.25,nil,{min=1,max=64,q=1}))
      m:add_input("offset",IN.new(0))
      -- OUTPUTS
      m:add_output("gate",OUT.new())
      -- PARAMS
      m:add_param({name="ppq",value=3,options=main_clock.div_names})
      -- FIELDS
      m.counter = 0
      m.rhythm = {}
      -- CTRL
      m.ctrl_rate = function (self)
        local g = self:inlet("gate")
        local p = self:inlet("pulses")
        local l = self:inlet("length")
        local o = self:inlet("offset")
        
        local ppq = g.source and 1 or self:param("ppq")
        local phase = g.source and g.phase or main_clock:get_phase(ppq)
        
        if phase==1 then -- "rising"
          l = SIGNAL.map(l.signal,1,64,1)
          --update mapping 
          p.mapping = {min=0,max=l,q=1}
          o.mapping = {min=0,max=l,q=1}
          p = SIGNAL.map(p.signal,0,l,1)
          o = SIGNAL.map(o.signal,0,l,1)
          self.rhythm = EURYTM[l][p]
          
          self.counter = g.source and (self.counter+1) or main_clock:get(ppq)
          local state = self.rhythm[wrap(self.counter+o,1,#self.rhythm)]
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
      m:add_input("signal",IN.new(0,nil,NOTE_NAMES))
      -- OUTPUTS
      m:add_output("signal",OUT.new(0))
      -- PRAMS
      m:add_param({name="scale",value=3,options=SCALES.short_names})
      m:add_param({name="root",value=1,options=OCTAVE})
      m:add_param({name="oct",value=3,options={-24,-12,0,12,24}})
      -- CTRL
      m.ctrl_rate = function (self)
        local v = self:inlet("signal").signal * 120 -- -> 0-120
        v = self:param("oct") + (self:param("root")-1) + musicutil.snap_note_to_array(v,SCALES.values[self:param("scale")])
        v = v/120
        self:write("signal",v)
      end
      return m
    end
  }
}

return ctrl_modules