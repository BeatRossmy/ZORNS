local engine_modules = {
  {
    name = "engine_out",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "engine_out")
      m:add_input("gate",IN.new(0,false,GATE_STATES))
      m:add_input("pitch",IN.new(0,nil,NOTE_NAMES))
      m:add_input("amp",IN.new(0.5))
      m:add_input("cutoff",IN.new(0.5,nil,{min=100,max=5000,q=0.01}))
      m.ctrl_rate = function (self)
        local phase = self:inlet("gate").phase
        if phase==1 then -- "rising"
          local hz = SIGNAL.xmap(self:inlet("pitch").signal,0,120,1)
          local v = self:inlet("amp").signal
          local f = self:inlet("cutoff").signal
          hz = musicutil.note_num_to_freq(hz)
          engine.cutoff(SIGNAL.xmap(f,100,5000))
          engine.amp(v)
          engine.hz(hz)
        end
      end
      return m
    end
  }
}

return engine_modules