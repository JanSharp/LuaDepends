
--[[
MIT License

Copyright (c) 2022 Jan Mischak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local real_require = require

local loading_modules = {}
local results = {}

local function depends_internal(module, allow_circular)
  if results[module] ~= nil then
    return results[module]
  end

  local loading_results = loading_modules[module]
  if loading_results then
    if not allow_circular then
      error("Circular require dependencies for module '"..module.."'.")
    end
    local loading_result = setmetatable({}, {
      __index = function()
        error("Attempt to index into module '"..module.."' before it was done loading.")
      end,
      __newindex = function()
        error("Attempt to assign to module '"..module.."' before it was done loading.")
      end,
    })
    loading_results[#loading_results+1] = loading_result
    return loading_result
  end

  loading_results = {}
  loading_modules[module] = loading_results
  local result = real_require(module)
  loading_modules[module] = nil
  results[module] = result
  if not loading_results[1] then
    return result
  end

  if type(result) ~= "table" then
    error("Modules loaded using 'depends' must return a table. module: '"..module.."'.")
  end
  for _, loading_result in ipairs(loading_results) do
    setmetatable(loading_result, nil)
    for k, v in pairs(result) do
      loading_result[k] = v
    end
    setmetatable(loading_result, getmetatable(result))
  end
  return result
end

-- Factorio mod debugger support
---@diagnostic disable-next-line: undefined-global
if __DebugAdapter then __DebugAdapter.defineGlobal("depends") end

---@generic T
---@param module `T`
---@return T
function depends(module)
  return depends_internal(module, true)
end

---@generic T
---@param module `T`
---@return T
function require(module)
  return depends_internal(module, false)
end
