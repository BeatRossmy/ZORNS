ID_LIST = {
  new = function ()
    return {
      id_counter = 0,
      
    }
  end
}

MOD_ID = 0
MODULES = {}
add_module = function (m)
  MOD_ID = MOD_ID+1
  m.id = MOD_ID
  MODULES[MOD_ID] = m
end
remove_module = function (m)
  MODULES[m.id] = nil
  m = nil
end