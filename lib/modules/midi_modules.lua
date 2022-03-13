local midi_modules = {
  --[[{
    name = "note/i",
    new = function (x,y,id)
      
    end
  },--]]
  {
    name = "cc/i",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "cc/i")
      m:add_output("cc",OUT.new())
      m:add_param({name="dev",value=1,options=MIDI_DEVICES.names})
      m:add_param({name="cc",value=1,min=1,max=128,delta=1})
      m:add_param({name="ch",value=1,min=1,max=16,delta=1})
      m.ctrl_rate = function (self)
        local v = MIDI_DEVICES.connected[self:param("dev")].ccs[self:param("ch")][self:param("cc")]/127
        self:write("cc",v)
      end
      return m
    end
  },
  {
    name = "note/o",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "note/o")
      m:add_input("gate",IN.new(0,false,GATE_STATES))
      m:add_input("pitch",IN.new(0,nil,NOTE_NAMES))
      m:add_input("velocity",IN.new(0.5,nil,{min=0,max=127,q=1}))
      m:add_input("channel",IN.new(0,nil,{min=1,max=16,q=1}))
      m:add_param({name="dev",value=1,options=MIDI_DEVICES.names})
      m.state = {pitch=0, velocity=0, channel=1}
      m.ctrl_rate = function (self)
        local phase = self:inlet("gate").phase
        if phase==1 then -- "rising"
          local p = SIGNAL.xmap(self:inlet("pitch").signal,0,120,1)
          local v = SIGNAL.xmap(self:inlet("velocity").signal,0,127,1)
          local ch = SIGNAL.map(self:inlet("channel").signal,self:inlet("channel").mapping)
          self.state = {pitch=p, velocity=v, channel=ch, dev=self:param("dev")}
          MIDI_DEVICES.connected[self.state.dev]:note_on(p,v,ch)
        elseif phase==-1 then -- "falling"
          MIDI_DEVICES.connected[self.state.dev]:note_off(self.state.pitch,0,self.state.channel)
        end
      end
      return m
    end
  },
  {
    name = "cc/o",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "cc/o")
      m:add_input("value",IN.new(0.5,nil,{min=0,max=127,q=1}))
      m:add_param({name="dev",value=1,options=MIDI_DEVICES.names})
      m:add_param({name="cc",value=1,min=0,max=127,delta=1})
      m:add_param({name="ch",value=1,min=1,max=16,delta=1})
      m.state = {value=0}
      m.ctrl_rate = function (self)
        local v = SIGNAL.xmap(self:inlet("value").signal,0,127,1)
        if v~=self.state.value then -- "rising"
          local d = self:param("dev")
          local cc = self:param("cc")
          local ch = self:param("ch")
          MIDI_DEVICES.connected[d]:cc(cc,v,ch)
          self.state.value = v
        end
      end
      return m
    end
  }
}

return midi_modules