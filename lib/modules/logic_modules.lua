local logic_modules = {
  {
    name = "bool",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "bool")
      m:add_input("A",IN.new(0,false,GATE_STATES))
      m:add_input("B",IN.new(0,false,GATE_STATES))
      m:add_output("C",OUT.new())
      m:add_param({name="oprtr",value=1,options={"&&","||","!&","^"}})
      m.logic_operations = {logic_and,logic_or,logic_nand,logic_xor}
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
      m:add_input("gate",IN.new(0,false,GATE_STATES))
      m:add_input("reset",IN.new(0,false,GATE_STATES))
      m:add_output("/1",OUT.new())
      m:add_output("/2",OUT.new())
      m:add_param({name="ppq",value=3,options=main_clock.div_names})
      m:add_param({name="o1%",value=1,options={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}})
      m:add_param({name="o2%",value=3,options={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}})
      m.counter = 0
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
      m:add_input("gate",IN.new(0,false,GATE_STATES))
      m:add_input("chance",IN.new(0.5))
      m:add_output("A",OUT.new())
      m:add_output("B",OUT.new())
      m:add_param({name="ppq",value=3,options=main_clock.div_names})
      m.last_gate ="A"
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
      m:add_input("signal",IN.new(0))
      m:add_output("signal",OUT.new())
      m.ctrl_rate = function (self)
        local v = self:inlet("signal").signal
        v = SIGNAL.map(v,1,0)
        self:write("signal",v)
      end
      return m
    end
  },
  {
    name = "latch",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "latch")
      m:add_input("gate",IN.new(0,false,GATE_STATES))
      m.state = false
      m:add_output("gate",OUT.new())
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

return logic_modules