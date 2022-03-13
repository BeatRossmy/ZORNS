xor = function (a,b)
  return (a or b) and (a~=b)
end

main_clock = {
  pulse = 0,
  last_pulse = 0,
  
  div_names = {"1/4","1/2","1","2","3","4"},
  divisions = {1/4,1/2,1,2,3,4},
  phases = {0,0,0,0,0,0},
  pulses = {0,0,0,0,0,0},
  
  update = function (self)
    self.last_pulse = self.pulse
    self.pulse = clock.get_beats() + 1/8
    for i,d in pairs(self.divisions) do
      local a,b = 0,0
      a = math.floor(self.pulse*2*d)%2
      b = math.floor(self.last_pulse*2*d)%2
      if (a~=b) then
        self.phases[i] = b-a
        if a==0 then self.pulses[i] = math.floor(self.pulse*d)+1 end
      else
        self.phases[i] = 0
      end
      
    end
  end,
  
  change = function (self, d)
    return math.floor(self.pulse*d)~=math.floor(self.last_pulse*d)
  end,
  
  get = function (self, d)
    return self.pulses[d]
  end,
  
  get_pulse = function (self, d)
    return math.floor(self.pulse*d*2)%2==0
  end,
  
  get_phase = function (self, d)
    return self.phases[d]
  end
}

wrap = function (n, min, max)
  return ((n-min)%(max-min+1))+min
end

math_add = function (a,b)
  return a+b
end

math_sub = function (a,b)
  return a-b
end

math_mult = function (a,b)
  return a*b
end

math_div = function (a,b)
  return a/b
end

math_pow = function (a,b)
  return a^b
end

lfo_sine = function (phase)
  local v = (1+math.sin(phase))/2
  return v
end

lfo_tri = function (phase)
  local v = lfo_ramp(phase)
  local i = 1-v
  v = v<i and v or i
  return v*2
end

lfo_ramp = function (phase)
  local v = math.fmod(phase,2*math.pi)/(2*math.pi)
  return v
end

lfo_rect = function (phase)
  local v = math.fmod(phase,2*math.pi)>math.pi and 1 or 0
  return v
end

logic_and = function (a,b)
  return (a and b)  
end

logic_or = function (a,b)
  return (a or b)
end

logic_nand = function (a,b)
  return not(a and b)
end

logic_xor = function (a,b)
  return (a or b) and not(a==b)  
end

pinknoise_generator = function ()
  return {
    r_values = {0,0,0,0,0},
    counter = 0,
    
    get = function (self)
      self.counter = self.counter+1;
      local r = 0
      for i=1,5 do
        local d = {1,3,5,7,11}
        if self.counter%d[i]==0 then
          self.r_values[i] = math.random()
        end
        r = r + self.r_values[i]/5
      end
      return util.clamp(r,0,1)
    end
  }
end