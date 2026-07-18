-- throttled gc
-- see librime-lua issue 307
-- default every 16 translations override via force_gc/interval
local function force_gc(_, _, env)
    if not env.gc_interval then
        local configured = env.engine.schema.config:get_int("force_gc/interval")
        env.gc_interval = (configured and configured > 0) and configured or 16
        env.gc_count = 0
    end

    env.gc_count = env.gc_count + 1
    if env.gc_count % env.gc_interval == 0 then
        collectgarbage("step")
    end
end

return force_gc
