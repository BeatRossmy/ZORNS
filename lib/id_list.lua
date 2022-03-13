ID_LIST = {
  new = function ()
    return {
      id_counter = 0,
      list = {},
      push = function (self, e)
        self.id_counter = self.id_counter+1
        e.id = self.id_counter
        self.list[self.id_counter] = e
      end,
      pop = function (self, e)
        self.list[e.id] = nil
        e = nil
      end,
      pop_id = function (self, e_id)
        self.list[e_id] = nil
      end,
      insert = function (self, e)
        if not self.list[e.id] then
          self.list[e.id] = e
          self.id_counter = e.id>self.id_counter and e.id or self.id_counter
        end
      end
    }
  end
}