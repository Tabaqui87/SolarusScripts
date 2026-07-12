---------------------------------------------------------------------------------------------------
-- Script name:   autostart_items
-- Author:        Tabaqui87
-- Version:       1.0
-- 
-- Description:   Allows items to be started automatically whenever the hero becomes "free" while
--                the item command is being held (link's awakening shield).
-- 
-- Usage:         Call item:set_autostart() upon creation.
-- 
-- Dependencies:  multi_events
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Item metatable
---------------------------------------------------------------------------------------------------

local item_meta = sol.main.get_metatable("item")

---------------------------------------------------------------------------------------------------
-- Item properties
---------------------------------------------------------------------------------------------------

function item_meta:get_autostart()
  return self.autostart or false
end

function item_meta:set_autostart(autostart)
  self.autostart = autostart == nil or autostart
end

---------------------------------------------------------------------------------------------------
-- Hero metatable
---------------------------------------------------------------------------------------------------

local hero_meta = sol.main.get_metatable("hero")

---------------------------------------------------------------------------------------------------
-- Hero events
---------------------------------------------------------------------------------------------------

hero_meta:register_event("on_state_changed", function(self, new_state_name)
  if new_state_name == "free" then
    local game = self:get_game()
    for slot = 1, 2 do
      local item = game:get_item_assigned(slot)
      if item and item:get_autostart() and game:is_command_pressed(string.format("item_%d", slot)) then
        self:start_item(item)
        break
      end
    end
  end
end)

return true