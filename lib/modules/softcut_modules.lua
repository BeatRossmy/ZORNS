local softcut_modules = {
  {
    name = "sc_voice",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "sc_voice")
      
      m:add_input("trigger",IN.new(0,false,GATE_STATES))
      m:add_input("phase",IN.new(0,nil))
      
      m.on_sc_change = function (self)
        local v = self:param("voice")
        local b = self:param("buffer")
        local l = self:param("length")
        local r = self:param("rate")
        local lo = self:param("loop")
        
        audio.level_cut(1.0)
        audio.level_adc_cut(1)
        audio.level_eng_cut(1)
        softcut.level_input_cut(1, v, 1.0)
        softcut.level_input_cut(2, v, 1.0)
        
        softcut.fade_time(v, 0.1)
      	softcut.rec(v, 1)
      	softcut.rec_level(1, 0.75)
      	softcut.pre_level(1, 0.75)
        softcut.level_slew_time(v,0.1)
        softcut.rate_slew_time(v,0.1)
        
        softcut.enable(v,1)
        softcut.buffer(v,1)
        softcut.level(v,1.0)
        softcut.loop(v,1)
        softcut.loop_start(v,1)
        softcut.loop_end(v,1+l)
        softcut.position(v,1)
        softcut.play(v,1)
        softcut.rate(v,r)
        
      end
      
      m:add_param({name="buffer",value=1,options={1,2},action=m.on_sc_change})
      m:add_param({name="length",value=1,min=0,max=10,delta=0.1,action=m.on_sc_change})
      m:add_param({name="voice",value=1,options={1,2,3,4,5,6},action=m.on_sc_change})
      m:add_param({name="loop",value=1,options={"false","true"},action=m.on_sc_change})
      m:add_param({name="rate",value=1,options={0.25,0.5,1,2,4},action=m.on_sc_change})
        
      m.ctrl_rate = function (self)
        local phase = self:inlet("phase").signal
        local g = self:inlet("trigger")
        if g.phase==1 then
          softcut.position(self:param("voice"),1+phase*self:param("length"))
          softcut.play(self:param("voice"),1+phase*self:param("length"))
        end
      end
      
      return m
    end
  },
  {
    name = "sc_buff",
    new = function (x,y,id)
      local m = zorns_module(x and x or 0, y and y or 0, id, "sc_buff")
      m:add_input("trigger",IN.new(0,false,GATE_STATES))
      m:add_input("phase",IN.new(0,nil))
      -- FIELDS
      m.values = {}
      for i=1,8 do m.values[i] = VALUE.new(nil,nil) end
      
      m.on_sc_change = function (self)
        local v = self:param("voice")
        local b = self:param("buffer")
        local l = self:param("length")
        
        audio.level_cut(1.0)
        audio.level_adc_cut(1)
        audio.level_eng_cut(1)
        softcut.level_input_cut(1, v, 1.0)
        softcut.level_input_cut(2, v, 1.0)
        
        softcut.enable(v,1)
        softcut.buffer(v,1)
        softcut.level(v,1.0)
        softcut.loop(v,1)
        softcut.loop_start(v,1)
        softcut.loop_end(v,1+l)
        softcut.position(v,1)
        softcut.play(v,1)
        softcut.fade_time(v, 0.1)
      	softcut.rec(v, 1)
      	softcut.rec_level(1, 0.75)
      	softcut.pre_level(1, 0.75)
        softcut.level_slew_time(v,0.1)
        softcut.rate_slew_time(v,0.1)
      end
      
      m.phase = 0
      m:add_param({name="buffer",value=1,options={1,2},action=m.on_sc_change})
      m:add_param({name="length",value=1,min=0,max=10,delta=0.1,action=m.on_sc_change})
      m:add_param({name="voice",value=1,options={1,2,3,4,5,6},action=m.on_sc_change})
      
      --
      
      m.ctrl_rate = function (self)
        self.phase = self:inlet("phase").signal
        -- if trigger launch voice from current phase
        local g = self:inlet("trigger")
        if g.phase==1 then
          softcut.position(self:param("voice"),1+self.phase*self:param("length"))
        end
      end
      
      m.show_ui = function (self,x_off,y_off,g)
        local l = 3
        if SEL.not_this_module(selection, self) then l = math.floor(l*0.5) end
        for i,v in pairs(self.values) do
          g:led(x_off+i,y_off,l)
        end
        
        local p = self.phase*8
        local i = math.floor(self.phase*8)
        l = math.floor(3+(1-(p-i))*12)
        local l_n = math.floor(3+(p-i)*12)
        if SEL.not_this_module(selection, self) then
          l = math.floor(l*0.5)
          l_n = math.floor(l_n*0.5)
        end
        g:led(x_off+i+1,y_off,l)
        g:led(x_off+((i+1)%8)+1,y_off,l_n)
      end
      return m
    end
  }
}


return softcut_modules