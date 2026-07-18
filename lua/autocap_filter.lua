--[[
	#302@abcdefg233  #305@Mirtle

	自动大写英文词汇：
	- 部分规则不做转换
	- 输入首字母大写，候选词转换为首字母大写： Hello → Hello
	- 输入至少前 2 个字母大写，候选词转换为全部大写： HEllo → HELLO

    大写时无法动态调整词频
--]]
local function autocap_filter(input, env)
    local code = env.engine.context.input -- input code
    local codeLen = #code
    local codeAllUCase = false
    local codeUCase = false
    -- skip when
    if codeLen == 1 or       -- code length is 1
        code:find("^[%l%p]") -- code starts with lowercase or punctuation
    then                     -- otherwise no candidate check
        for cand in input:iter() do
            yield(cand)
        end
        return
    ---- code all uppercase
    -- elseif code == code:upper() then
    --     codeAllUCase = true
    -- code first 2 to n chars uppercase
    elseif code:find("^%u%u+.*") then
        codeAllUCase = true
    -- code first char uppercase
    elseif code:find("^%u.*") then
        codeUCase = true
    end

    local pureCode = code:gsub("[%s%p]", "")     -- code without punctuation and spaces
    for cand in input:iter() do
        local text = cand.text                   -- candidate text
        local pureText = text:gsub("[%s%p]", "") -- candidate without punctuation and spaces
        -- skip when
        if
            text:find("[^%w%p%s]") or                 -- candidate has chars beyond letters digits punctuation spaces
            text:find("%s") or                        -- candidate contains spaces
            pureText:find("^" .. code) or             -- code fully matches candidate
            (cand.type ~= "completion" and            -- word differs from its code
                pureCode:lower() ~= pureText:lower()) -- like PS for Photoshop
        then
            yield(cand)
        -- code first 2 to 10 chars uppercase candidate becomes all uppercase
        elseif codeAllUCase then
            text = text:upper()
            yield(Candidate(cand.type, 0, codeLen, text, cand.comment))
        -- code first char uppercase candidate capitalized
        elseif codeUCase then
            text = text:gsub("^%a", string.upper)
            yield(Candidate(cand.type, 0, codeLen, text, cand.comment))
        else
            yield(cand)
        end
    end
end

return autocap_filter
