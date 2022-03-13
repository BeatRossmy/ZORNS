local system_modules = {
  --[[{
    name = "note/i",
    new = function (x,y,id)
      
    end
  },--]]
  {
    name = "clock",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "clock")
      m:add_output("pulse",OUT.new())
      m:add_param({name="ppq",value=3,options=main_clock.div_names})
      m.pulse = 0
      m.ctrl_rate = function (self)
        local ppq = g.source and 1 or self:param("ppq")
        local phase = main_clock:get_phase(ppq)
        if phase==1 then
          self:write("pulse",1)
        elseif phase==-1 then
          self:write("pulse",0)
        end
      end
      return m
    end
  },
  {
    name = "phasor",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "phasor")
      m:add_param({name="time",value=3,options={0.25,0.5,1,2,3,4,5,6,7,8}})
      m:add_param({name="invert",value=1,options={"false","true"}})
      m:add_output("signal",OUT.new())
      m.ctrl_rate = function (self)
        local b = clock.get_beats()
        local t = self:param("time")
        local v = math.fmod(b,t)/t
        if self:param("invert")==2 then v = 1-v end
        self:write("signal",v)
      end
      return m
    end
  }
}

return system_modules