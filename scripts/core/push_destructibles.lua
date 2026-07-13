---------------------------------------------------------------------------------------------------
-- Script name:   push_destructibles
-- Author:        Tabaqui87
-- Version:       1.0
-- 
-- Description:   Allows destructibles to be pushed.
-- 
-- Usage:         Define an user property on destructibles with name "pushable" and value "true" to
--                allow the hero to push it. You can also toggle this behaviour dinamically from
--                scripts by calling destructible:set_pushable(pushable).
-- 
-- Dependencies:  multi_events
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Destructible metatable
---------------------------------------------------------------------------------------------------

local destructible_meta = sol.main.get_metatable("destructible")

---------------------------------------------------------------------------------------------------
-- Destructible properties
---------------------------------------------------------------------------------------------------

function destructible_meta:is_pushable()
  return self.pushable or false
end

function destructible_meta:set_pushable(pushable)
  self.pushable = pushable == nil or pushable
end

---------------------------------------------------------------------------------------------------
-- Destructible events
---------------------------------------------------------------------------------------------------

destructible_meta:register_event("on_created", function(self)
  self:set_pushable(self:get_property("pushable") == "true")
end)

---------------------------------------------------------------------------------------------------
-- Hero metatable
---------------------------------------------------------------------------------------------------

local hero_meta = sol.main.get_metatable("hero")

---------------------------------------------------------------------------------------------------
-- Hero properties
---------------------------------------------------------------------------------------------------

function hero_meta:get_pushed_object()
  return self.pushed_object
end

function hero_meta:set_pushed_object(pushed_object)
  self.pushed_object = pushed_object
end

---------------------------------------------------------------------------------------------------
-- Hero events
---------------------------------------------------------------------------------------------------

hero_meta:register_event("on_state_changing", function(self, state_name, next_state_name)
  if next_state_name == "pushing" then
    local entity = self:get_facing_entity()
    if entity and entity:get_type() == "destructible" and entity:is_pushable() then
      local hero, map = self, self:get_map()
      local visible = entity:is_visible()
      local x, y, layer = entity:get_position()
      local sprite = (entity:get_sprite() and entity:get_sprite():get_animation_set()) or ""
      local object = map:create_block({
        layer = layer,
        x = x,
        y = y,
        sprite = sprite,
        pushable = true,
        pullable = false
      })
      object.moving = false
      object.reverted = false
      object.is_moving = function(self)
        return self.moving
      end
      object.set_moving = function(self, moving)
        self.moving = moving == nil or moving
      end
      object.is_reverted = function(self)
        return self.reverted
      end
      object.set_reverted = function(self, reverted)
        self.reverted = reverted == nil or reverted
      end
      object.revert_to_entity = function(self)
        entity:set_position(self:get_position())
        entity:set_visible(visible)
        entity:set_enabled()
        self:set_reverted()
      end
      object:register_event("on_removed", function(self)
        if not self:is_reverted() then
          self:revert_to_entity()
          entity:remove()
          hero:set_pushed_object(nil)
        end
      end)
      object:register_event("on_moving", function(self)
        self:set_moving()
      end)
      object:register_event("on_moved", function(self)
        self:set_moving(false)
        if hero:get_state() ~= "pushing" then
          self:revert_to_entity()
          self:remove()
          hero:set_pushed_object(nil)
        end
      end)
      entity:set_visible(false)
      entity:set_enabled(false)
      self:set_pushed_object(object)
    end
  elseif state_name == "pushing" then
    local object = self:get_pushed_object()
    if object and not object:is_moving() then
      object:revert_to_entity()
      object:remove()
      self:set_pushed_object(nil)
    end
  end
end)

return true