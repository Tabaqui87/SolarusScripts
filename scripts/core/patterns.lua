---------------------------------------------------------------------------------------------------
-- Script name:   patterns
-- Author:        Tabaqui87
-- Version:       1.0
-- 
-- Description:   Parse map dat files upon map changing and stores patterns in a table.
-- 
-- Usage:         You can define tags for specific tilesets and patterns in the
--                "patterns_config.lua". This script extends the map metatable by adding the
--                following methods to access patterns and tags at given coordinates:
--                map:get_pattern_at(x, y, layer): returns the topmost pattern at the given
--                  coordinates.
--                map:get_pattern_tag_at(x, y, layer): returns the tag of the pattern at the given
--                  coordinates. You can tag patterns in the config tile to represent diggable
--                  tiles or tiles with a specific behaviour (sound, footsteps, etc...).
-- 
-- Dependencies:  multi_events
---------------------------------------------------------------------------------------------------

local config = require("scripts/core/patterns_config")

---------------------------------------------------------------------------------------------------
-- Map metatable
---------------------------------------------------------------------------------------------------

local map_meta = sol.main.get_metatable("map")

---------------------------------------------------------------------------------------------------
-- Map methods
---------------------------------------------------------------------------------------------------

function map_meta:get_pattern_at(x, y, layer)
  local cx = math.floor(x / config.cell_size)
  local cy = math.floor(y / config.cell_size)
  return unpack((self.patterns and self.patterns[layer] and self.patterns[layer][cy] and self.patterns[layer][cy][cx]) or {})
end

function map_meta:get_pattern_tag_at(x, y, layer)
  local pattern, tileset = self:get_pattern_at(x, y, layer)
  return (config.tags[tileset] and config.tags[tileset][pattern]) or nil
end

function map_meta:load_patterns()
  local path = string.format("maps/%s.dat", self:get_id())
  if sol.file.exists(path) then
    pcall(setfenv(sol.main.load_file(path), setmetatable({
      tile = function(data)
        local x1 = math.floor(data.x / config.cell_size)
        local y1 = math.floor(data.y / config.cell_size)
        local x2 = math.floor((data.x + data.width) / config.cell_size)
        local y2 = math.floor((data.y + data.height) / config.cell_size)
        if not self.patterns then
          self.patterns = {}
        end
        if not self.patterns[data.layer] then
          self.patterns[data.layer] = {}
        end
        for y = y1, y2 do
          if not self.patterns[data.layer][y] then
            self.patterns[data.layer][y] = {}
          end
          for x = x1, x2 do
            self.patterns[data.layer][y][x] = { data.pattern, data.tileset or self:get_tileset() }
          end
        end
      end
    }, {
      __index = function(k)
        return function() end
      end
    })))
  end
end

---------------------------------------------------------------------------------------------------
-- Game metatable
---------------------------------------------------------------------------------------------------

local game_meta = sol.main.get_metatable("game")

---------------------------------------------------------------------------------------------------
-- Game events
---------------------------------------------------------------------------------------------------

game_meta:register_event("on_map_changed", function(self, map, camera)
  map:load_patterns()
end)

return true