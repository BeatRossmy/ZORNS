Gridbuffer = require "gridbuf"

g = grid.connect()

g.key = function(x,y,z)
  dirty_screen = true
  
  -- FIRST SELECTION
  if not selection and z==1 then
    selection = select_module(x,y)
    module_param = 1
    if selection then
      local m = MODULES.list[selection.module_id]
      m:grid_event(x,y,z)
    end
  -- REMOVE SELECTION
  elseif selection and x==selection.x and y==selection.y and z==0 then
    if selection.type=="empty_cell" then
      local c = category_list.index
      local m = module_list.index
      if m>1 then
        MODULES:push(catalogue[c].modules[m-1].new(selection.x,selection.y,nil))
      end
    end
    selection = nil
  -- SECOND SELECTION
  elseif selection and selection.module_id and z==1 then
    local sec_sel = select_module(x,y)
    if sec_sel then
      local con = CON.new(selection,sec_sel,1)
      if con then
        local index = CON.contains(CONNECTIONS.list,con)
        if not index then
          CONNECTIONS:push(con)
          MODULES.list[con.target.module_id]:add_connection(con.id)
          MODULES.list[con.source.module_id]:add_connection(con.id)
        else
          con = CONNECTIONS.list[index]
        end
        selection = SEL.new(selection.x,selection.y,nil,nil,"connection")
        selection.con_id = con.id
      end
    end
  end
  
  if selection==nil and z==1 then
    selection = SEL.new(x,y,nil,nil,"empty_cell")
    option = 0
  end
  
  --if selection then print("selection",selection.x,selection.y,selection.type,selection.port_id) end
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
  for _,m in pairs(MODULES.list) do m:show(g_buffer) end
  -- highlight connection
  if SEL.is_input(selection) or SEL.is_output(selection) then
    MODULES.list[selection.module_id]:show_connection(selection, g_buffer)
  end
  -- update
  g_buffer:draw()
end