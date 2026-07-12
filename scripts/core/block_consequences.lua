---------------------------------------------------------------------------------------------------
-- Script name:   block_consequences
-- Author:        Tabaqui87
-- Version:       1.0
-- 
-- Description:   Extends the enemy metatable by declaring a blocking behaviour.
-- 
-- Usage:         With the methods enemy:set_blocked_sound(), enemy:set_pushed_back_when_blocked()
--                and enemy:set_push_hero_when_blocked() you can define the blocking behaviour for
--                a specific enemy. You can then call the method enemy:try_block() from your shield
--                colliders to make the engine handle the response. You are responsible for
--                handling the hero response (enemy:get_push_hero_when_blocked()) in your scripts.
--                If the hero is in a custom state and the block was successful, the engine will
--                try to call the method state:on_blocked_enemy(enemy).
--                In the block_consequences_config.lua file you may define the name of an item
--                whose variant will be tested against enemy:get_minimum_shield_needed() to check
--                if the block will be successful.
-- 
-- Dependencies:  multi_events
---------------------------------------------------------------------------------------------------

local config = require("scripts/core/block_consequences_config")

---------------------------------------------------------------------------------------------------
-- Enemy metatable
---------------------------------------------------------------------------------------------------

local enemy_meta = sol.main.get_metatable("enemy")

---------------------------------------------------------------------------------------------------
-- Enemy properties
---------------------------------------------------------------------------------------------------

function enemy_meta:get_blocked_sound()
  return self.blocked_sound_id or "enemy_blocked"
end

function enemy_meta:set_blocked_sound(blocked_sound_id)
  self.blocked_sound_id = blocked_sound_id
end

function enemy_meta:is_pushed_back_when_blocked()
  return self.pushed_back_when_blocked == nil or self.pushed_back_when_blocked
end

function enemy_meta:set_pushed_back_when_blocked(pushed_back_when_blocked)
  self.pushed_back_when_blocked = pushed_back_when_blocked == nil or pushed_back_when_blocked
end

function enemy_meta:get_push_hero_when_blocked()
  return self.push_hero_when_blocked == nil or self.push_hero_when_blocked
end

function enemy_meta:set_push_hero_when_blocked(push_hero_when_blocked)
  self.push_hero_when_blocked = push_hero_when_blocked == nil or push_hero_when_blocked
end

---------------------------------------------------------------------------------------------------
-- Enemy methods
---------------------------------------------------------------------------------------------------

function enemy_meta:try_block()
  local game = self:get_game()
  local item = config.item_name and game:get_item(config.item_name)
  local minimum_shield_needed = self:get_minimum_shield_needed()
  if not item or (minimum_shield_needed > 0 and item:get_variant() >= minimum_shield_needed) then
    local hero = game:get_hero()
    local hero_state = hero:get_state_object()
    if hero_state and hero_state.on_blocked_enemy then
      hero_state:on_blocked_enemy(self)
    end
    if self:is_pushed_back_when_blocked() then
      local hurt_sound_id = self:get_hurt_sound()
      local on_hurt = self.on_hurt
      self.on_hurt = nil
      self:set_hurt_sound(self:get_blocked_sound())
      self:hurt(0)
      self:set_hurt_sound(hurt_sound_id)
      self.on_hurt = on_hurt
    else
      local blocked_sound_id = self:get_blocked_sound_id()
      if blocked_sound_id and blocked_sound_id ~= "" then
        pcall(sol.audio.play_sound, blocked_sound_id)
      end
    end
    self:on_blocked()
  end
end

return true