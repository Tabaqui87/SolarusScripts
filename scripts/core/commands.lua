---------------------------------------------------------------------------------------------------
-- Script name:   commands
-- Author:        Tabaqui87
-- Version:       1.0
-- 
-- Description:   Disables the action and attack commands, delegating their effect to item_1 and 2.
-- 
-- Usage:         Declare a list of command effects in the commands_config.lua script for each
--                item command. If an effect is active, the engine will simulate the action command
--                instead of calling the item script.
-- 
--                With item:set_effect_trigger(effect) you can bind an effect to a specific item
--                (lift to the power bracelet for example): in this case the engine will simulate
--                the action command for that effect only if that item is being used. The effect
--                must not be associated to any item key.
-- 
--                With item:set_attack_trigger(true) you can make the engine simulate the attack
--                command whenever that item is being used (sword as an item).
-- 
-- Dependencies:  multi_events
---------------------------------------------------------------------------------------------------

local config = require("scripts/core/commands_config")

---------------------------------------------------------------------------------------------------
-- Game metatable
---------------------------------------------------------------------------------------------------

local game_meta = sol.main.get_metatable("game")

---------------------------------------------------------------------------------------------------
-- Game methods
---------------------------------------------------------------------------------------------------

function game_meta:has_effect(command, effect)
  return (self.effects and self.effects[command] and self.effects[command][effect]) or false
end

function game_meta:add_effect(command, effect)
  if not self.effects then
    self.effects = {}
  end
  if not self.effects[command] then
    self.effects[command] = {}
  end
  self.effects[command][effect] = true
end

function game_meta:has_effect_activator(effect)
  return (self.effect_activators and self.effect_activators[effect]) or false
end

function game_meta:is_effect_activator(effect, item)
  return (self.effect_activators and self.effect_activators[effect] and self.effect_activators[effect][item]) or false
end

function game_meta:add_effect_activator(effect, item)
  if not self.effect_activators then
    self.effect_activators = {}
  end
  if not self.effect_activators[effect] then
    self.effect_activators[effect] = {}
  end
  self.effect_activators[effect][item] = true
end

function game_meta:remove_effect_activator(effect, item)
  if self.effect_activators and self.effect_activators[effect] then
    self.effect_activators[effect][item] = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Game events
---------------------------------------------------------------------------------------------------

game_meta:register_event("on_started", function(self)
  self.simulated_action = {}
  self.simulated_attack = {}
  self:set_command_keyboard_binding("action", nil)
  self:set_command_keyboard_binding("attack", nil)
  for k, v1 in pairs(config) do
    for _, v2 in ipairs(v1) do
      self:add_effect(k, v2)
    end
  end
end)

game_meta:register_event("on_command_pressed", function(self, command)
  if command:match("^item_%d$") then
    local effect, item = self:get_command_effect("action"), self:get_item_assigned(tonumber(command:match("^item_(%d)$")))
    if effect ~= nil and (self:has_effect(command, effect) or (item and item:get_effect_trigger() == effect)) then
      self.simulated_action[command] = true
      self:simulate_command_pressed("action")
      return true
    end
    if item and item:get_attack_trigger() then
      self.simulated_attack[command] = true
      self:simulate_command_pressed("attack")
      return true
    end
  end
end)

game_meta:register_event("on_command_released", function(self, command)
  if self.simulated_action[command] then
    self.simulated_action[command] = nil
    self:simulate_command_released("action")
  end
  if self.simulated_attack[command] then
    self.simulated_attack[command] = nil
    self:simulate_command_released("attack")
  end
end)

---------------------------------------------------------------------------------------------------
-- Item metatable
---------------------------------------------------------------------------------------------------

local item_meta = sol.main.get_metatable("item")

---------------------------------------------------------------------------------------------------
-- Item properties
---------------------------------------------------------------------------------------------------

function item_meta:get_effect_trigger()
  return self.effect_trigger
end

function item_meta:set_effect_trigger(effect_trigger)
  self.effect_trigger = effect_trigger
end

function item_meta:get_attack_trigger()
  return self.attack_trigger or false
end

function item_meta:set_attack_trigger(attack_trigger)
  self.attack_trigger = attack_trigger == nil or attack_trigger
end

return true