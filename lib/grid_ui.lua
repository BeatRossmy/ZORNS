Gridbuffer = require "gridbuf"

g = grid.connect()

g.key = function(x,y,z)
  dirty_screen = true
  
  -- FIRST SELECTION
  if not selection and z==1 then
    selection = select_module(x,y)
    module_param = 1
    if selection then selection.module:grid_event(x,y,z) end
  -- REMOVE SELECTION
  elseif selection and x==selection.x and y==selection.y and z==0 then
    if selection.type=="empty_cell" then
      local c = category_list.index
      local m = module_list.index
      print(c,m)
      if m>1 then
        -- table.insert(MODULES,catalogue[c].modules[m-1].new(selection.x,selection.y))
        MAX_ID = MAX_ID+1
        MODULES[MAX_ID] = catalogue[c].modules[m-1].new(selection.x,selection.y,MAX_ID)
      end
    end
    selection = nil
  -- SECOND SELECTION
  elseif selection and selection.module and z==1 then
    local sec_sel = select_module(x,y)
    if sec_sel then
      print("create connection")
      local con = create_connection(selection,sec_sel)
      if con then
        local old_con = con.target.module:contains_connection(con)
        if old_con  then 
          print("connection exists")
          con = old_con
          selection.type = "connection"
          selection.module = old_con
          selection.port = nil
        else
          print("set connection")
          set_connection(con)
        end
      end
    end
  end
  
  if selection==nil and z==1 then
    selection = SEL.new(x,y,nil,nil,"empty_cell")
    option = 0
  end
  
  if selection then print("sel",selection.x,selection.y,selection.type) end
end

g_buffer = {
  last = Gridbuffer.new(16,8),
  current = Gridbuffer.new(16,8),
  grid = g,
  led = function (self,x,y,l)
    self.current:led_level_set(x,y,l)
  end,
  draw = function (self)
    for x=1,16 do
      for y=1,8 do
        local l = self.current.grid[y][x]
        if l~=self.last.grid[y][x] then
          self.grid:led(x,y,l)
        end
      end
    end
    self.grid:refresh()
    self.last = self.current
    self.current = Gridbuffer.new(16,8)
  end
}

draw_loop = function ()
  for _,m in pairs(MODULES) do m:show(g_buffer) end
  g_buffer:draw()
end