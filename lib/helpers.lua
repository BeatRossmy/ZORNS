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
  return (a==1 and b==1)  
end

logic_or = function (a,b)
  return (a==1 or b==1)
end

logic_nand = function (a,b)
  return not(a==1 and b==1)
end

logic_xor = function (a,b)
  return (a==1 or b==1) and not(a==b)  
end