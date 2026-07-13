---------------------------------------------------------------------------------------------------
-- Script name:   feather_state
-- Author:        Tabaqui87
-- Version:       1.0
-- 
-- Description:   Feather state.
---------------------------------------------------------------------------------------------------

local state = require("scripts/hero/state")

local feather_state = state:subclass()

---------------------------------------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------------------------------------

function feather_state:initialize(item, slot)
  state.initialize(self, "feather")
  self:set_can_control_direction(false)
  self:set_gravity_enabled(false)
  self:set_affected_by_ground("deep_water", false)
  self:set_affected_by_ground("shallow_water", false)
  self:set_affected_by_ground("grass", false)
  self:set_affected_by_ground("hole", false)
  self:set_affected_by_ground("ice", false)
  self:set_affected_by_ground("ladder", false)
  self:set_affected_by_ground("prickles", false)
  self:set_affected_by_ground("lava", false)
  self:set_can_be_hurt(false)
  self:set_can_use_sword(false)
  self:set_can_use_item(false)
  self:set_can_interact(false)
  self:set_can_push(false)
  self:set_can_pick_treasure(false)
  self:set_can_use_switch(false)
  self:set_can_use_stream(false)
  self:set_can_use_stairs(false)
  self:set_can_use_jumper(false)
  self:set_item(item)
  self:set_slot(slot)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

function feather_state:get_item()
  return self.item
end

function feather_state:set_item(item)
  self.item = item
end

function feather_state:get_slot()
  return self.slot
end

function feather_state:set_slot(slot)
  self.slot = slot
end

---------------------------------------------------------------------------------------------------
-- Item state
---------------------------------------------------------------------------------------------------

function feather_state:is_item_assigned()
  return self:get_game():get_item_assigned(self:get_slot()) == self:get_item()
end

function feather_state:is_item_command_pressed()
  return self:get_game():is_command_pressed(string.format("item_%d", self:get_slot()))
end

---------------------------------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------------------------------

function feather_state:on_started(previous_state_name, previous_state)
  pcall(sol.audio.play_sound, "jump")
  local entity = self:get_entity()
  local sprite, shadow_sprite = entity:get_sprite(), entity:get_sprite("shadow")
  entity:set_animation("jumping")
  local gliding = false
  local speed_y = 120
  local delta_y = 0
  sol.timer.start(self, 10, function()
    speed_y = speed_y - ((gliding and 200) or 400) * 0.01
    delta_y = math.max(0, delta_y + speed_y * 0.01)
    sprite:set_xy(0, -delta_y)
    shadow_sprite:set_animation("big")
    if speed_y <= 0 and delta_y == 0 then
      pcall(sol.audio.play_sound, "land")
      entity:unfreeze()
    else
      if speed_y <= 0 and not gliding and self:get_item():get_variant() == 2 and self:is_item_assigned() and self:is_item_command_pressed() then
        pcall(sol.audio.play_sound, "throw")
        gliding = true
        speed_y = 40
        entity:set_animation("gliding")
      end
      return true
    end
  end)
end

function feather_state:on_finished(next_state_name, next_state)
  self:get_item():set_finished()
end

return feather_state