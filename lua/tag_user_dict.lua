--[[
	调试候选词工具代码。
    作者：[Mintimate](https://github.com/Mintimate)

    默认不启用，用于调试候选词。
--]]


local M = {}

function M.init(env)
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub('^*', '')
    M.user_table = config:get_string(env.name_space .. "/user_table")
    M.completion = config:get_string(env.name_space .. "/completion")
    M.sentence = config:get_string(env.name_space .. "/sentence")
    M.phrase = config:get_string(env.name_space .. "/phrase")
    M.user_phrase = config:get_string(env.name_space .. "/user_phrase")
end

function M.processCandidate(cand)
    if cand.comment ~= "" then
        cand:get_genuine().comment = cand.comment .. " "
    end
end

-- process input and apply conditions to each candidate
-- @param input object containing candidates
-- @param env environment object
function M.func(input, env)
    -- conditions applied to each candidate
    local conditions = {
        {type = "user_table", value = M.user_table}, -- user table condition
        {type = "sentence", value = M.sentence}, -- sentence condition
        {type = "user_phrase", value = M.user_phrase}, -- user phrase condition
        {type = "phrase", value = M.phrase}, -- phrase condition
        {type = "completion", value = M.completion} -- completion condition
    }

    -- iterate candidates in input
    for cand in input:iter() do
        -- apply conditions to candidate
        for _, condition in ipairs(conditions) do
            if cand.type == condition.type and condition.value then
                -- handle candidate
                M.processCandidate(cand)
                -- append condition value to candidate comment
                cand:get_genuine().comment = cand.comment .. condition.value
                break
            end
        end
        -- yield candidate
        yield(cand)
    end
end

return M

