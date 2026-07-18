local M = {}

local kRejected = 0 -- ime rejects the key
local kAccepted = 1 -- ime accepts handled by this processor
local kNoop = 2 -- pass to the next processor

function M.init(env)
  local config = env.engine.schema.config
  env.name_space = env.name_space:gsub('^*', '')
end

function M.func(key, env)
  local ctx = env.engine.context
  local config = env.engine.schema.config

  -- limit
  local length_limit = config:get_string(env.name_space)
  if(length_limit~=nil) then
    if(string.len(ctx.input) > tonumber(length_limit)) then
      -- ctx:clear()
      ctx:pop_input(1)
      return kAccepted
    end
  end

  -- pass
  return kNoop
end

return M