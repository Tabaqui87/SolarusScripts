---------------------------------------------------------------------------------------------------
-- Script name:   attack_consequences
-- Author:        Tabaqui87
-- Version:       1.0
-- 
-- Description:   Extends the enemy metatable to declare custom attack consequences.
-- 
-- Usage:         Declare custom attack consequences with enemy:set_attack_consequence() and
--                enemy:set_attack_consequence_sprite(). From your custom weapons colliders you
--                can then call enemy:try_hurt(attack) and the engine will try to handle them in a
--                "standard" way. Some events like enemy:on_hurt() and state:on_attacked_enemy()
--                have been modified to accept the custom attack name instead of "script".
-- 
-- Dependencies:  multi_events
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Standard attack list
---------------------------------------------------------------------------------------------------

local STANDARD_ATTACK_TYPES = {
  ["sword"] = true,
  ["thrown_item"] = true,
  ["explosion"] = true,
  ["arrow"] = true,
  ["hookshot"] = true,
  ["boomerang"] = true,
  ["fire"] = true
}

local function is_standard_attack(attack)
  return STANDARD_ATTACK_TYPES[attack] or false
end

---------------------------------------------------------------------------------------------------
-- Enemy meta
---------------------------------------------------------------------------------------------------

local enemy_meta = sol.main.get_metatable("enemy")

---------------------------------------------------------------------------------------------------
-- Enemy default methods
---------------------------------------------------------------------------------------------------

local get_attack_consequence = enemy_meta.get_attack_consequence
local set_attack_consequence = enemy_meta.set_attack_consequence
local set_default_attack_consequences = enemy_meta.set_default_attack_consequences

local get_attack_consequence_sprite = enemy_meta.get_attack_consequence_sprite
local set_attack_consequence_sprite = enemy_meta.set_attack_consequence_sprite
local set_default_attack_consequences_sprite = enemy_meta.set_default_attack_consequences_sprite

---------------------------------------------------------------------------------------------------
-- Enemy attack consequence methods
---------------------------------------------------------------------------------------------------

function enemy_meta:get_attack_consequence(attack)
  if self.consequence and self.consequence[attack] then
    return self.consequence[attack]
  end
  if is_standard_attack(attack) then
    return get_attack_consequence(attack)
  end
  return "ignored"
end

function enemy_meta:set_attack_consequence(attack, consequence)
  if is_standard_attack(attack) then
    set_attack_consequence(self, attack, consequence)
  end
  if not self.consequence then
    self.consequence = {}
  end
  self.consequence[attack] = consequence
end

function enemy_meta:set_default_attack_consequences()
  set_default_attack_consequences(self)
  self.consequence = nil
end

function enemy_meta:get_attack_consequence_sprite(sprite, attack)
  if self.consequence_sprite and self.consequence_sprite[sprite] and self.consequence_sprite[sprite][attack] then
    return self.consequence_sprite[sprite][attack]
  end
  return self:get_attack_consequence(attack)
end

function enemy_meta:set_attack_consequence_sprite(sprite, attack, consequence)
  if is_standard_attack(attack) then
    set_attack_consequence_sprite(self, sprite, attack, consequence)
  end
  if not self.consequence_sprite then
    self.consequence_sprite = {}
  end
  if not self.consequence_sprite[sprite] then
    self.consequence_sprite[sprite] = {}
  end
  self.consequence_sprite[sprite][attack] = consequence
end

function enemy_meta:set_default_attack_consequences_sprite(sprite)
  set_default_attack_consequences_sprite(sprite)
  if self.consequence_sprite and self.consequence_sprite[sprite] then
    self.consequence_sprite[sprite] = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Enemy methods
---------------------------------------------------------------------------------------------------

function enemy_meta:try_hurt(attack, sprite)
  local consequence
  if sprite then
    consequence = self:get_attack_consequence_sprite(sprite, attack)
  else
    consequence = self:get_attack_consequence(attack)
  end
  local hero = self:get_game():get_hero()
  local hero_state = (hero:get_state() == "custom" and hero:get_state_object()) or nil
  local on_attacked_enemy
  if hero_state then
    on_attacked_enemy = hero_state.on_attacked_enemy
    hero_state.on_attacked_enemy = function()
      if on_attacked_enemy then
        on_attacked_enemy(hero_state, self, sprite, attack, consequence)
      end
    end
  end
  if consequence == "protected" then
    local sound = self:get_attack_failure_sound()
    if sound and sound ~= "" then
      pcall(sol.audio.play_sound, sound)
    end
  elseif consequence == "immobilized" then
    local on_hurt = self.on_hurt
    self.on_hurt = nil
    self:hurt(0)
    self.on_hurt = on_hurt
    self:immobilize()
  elseif consequence == "custom" then
    self:on_custom_attack_received(attack, sprite)
  elseif type(consequence) == "number" and consequence >= 0 then
    local on_hurt = self.on_hurt
    self.on_hurt = function(self)
      if on_hurt then
        on_hurt(self, attack)
      end
    end
    self:hurt(consequence)
    self.on_hurt = on_hurt
  elseif type(consequence) == "function" then
    consequence()
  end
  if hero_state then
    hero_state.on_attacked_enemy = on_attacked_enemy
  end
end

return true