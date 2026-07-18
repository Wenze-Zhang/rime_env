-- https://github.com/amzxyz/rime_wanxiang
-- wanxiang family lua numpad behavior control
--   numpad digits follow kp_number_mode encode or commit directly
--   main keyboard digits select the nth candidate when menu is open
--
-- usage example schema.yaml
--   engine:
--     processors:
--       - lua_processor@*kp_number_processor
--   # numpad mode optional default auto
--   # auto    commit directly when idle encode while composing
--   # compose always encode never commit directly
--   kp_number_mode: auto

local RIME_PROCESS_RESULTS = {
    kRejected = 0, -- processor rejected the key stop chain without true
    kAccepted = 1, -- processor handled the key stop chain return true
    kNoop = 2,     -- processor skipped continue to next processor
}

-- wanxiang regex to lua no assertions good enough
local RegexParser = {}

function RegexParser.normalize(regex)
    local p = regex
    p = p:gsub("%(%?%:", "%(") -- clean non capture groups
    -- basic escapes
    p = p:gsub("\\d", "%%d"); p = p:gsub("\\D", "%%D")
    p = p:gsub("\\w", "%%w"); p = p:gsub("\\W", "%%W")
    p = p:gsub("\\s", "%%s"); p = p:gsub("\\S", "%%S")
    -- symbol escapes keep literal question mark
    p = p:gsub("\\%.", "%%."); p = p:gsub("\\%^", "%%^")
    p = p:gsub("\\%$", "%%$"); p = p:gsub("\\%*", "%%*")
    p = p:gsub("\\%+", "%%+"); p = p:gsub("\\%-", "%%-")
    p = p:gsub("\\%?", "%%?")
    p = p:gsub("\\%(", "%%("); p = p:gsub("\\%)", "%%)")
    p = p:gsub("\\%[", "%%["); p = p:gsub("\\%]", "%%]")
    
    return p
end

-- recursively expand question quantifier
-- input N[0-9]?A
-- output N[0-9]A and NA
local function expand_optional(pattern_list)
    local result = {}
    local has_expansion = false

    for _, pat in ipairs(pattern_list) do
        -- find first unescaped question quantifier
        -- locate the question mark and the atom it modifies
        local q_idx = nil
        local atom_start = nil
        local atom_end = nil

        local i = 1
        local len = #pat
        while i <= len do
            local char = string.sub(pat, i, i)
            
            if char == "%" then
                -- escape skip next char
                i = i + 2
            elseif char == "[" then
                -- char set
                local j = i + 1
                while j <= len do
                    if string.sub(pat, j, j) == "]" and string.sub(pat, j-1, j-1) ~= "%" then
                        break
                    end
                    j = j + 1
                end
                -- check whether question mark follows
                if j < len and string.sub(pat, j+1, j+1) == "?" then
                    atom_start = i
                    atom_end = j
                    q_idx = j + 1
                    break -- target found
                end
                i = j + 1
            elseif char == "?" then
                -- found a question mark modifying previous char
                -- ignore illegal regex with nothing before it
                if i > 1 then
                    q_idx = i
                    atom_end = i - 1
                    -- check whether previous char is an escape like %d
                    if atom_end > 1 and string.sub(pat, atom_end-1, atom_end-1) == "%" then
                        atom_start = atom_end - 1
                    else
                        atom_start = atom_end
                    end
                    break
                end
                i = i + 1
            else
                i = i + 1
            end
        end

        if q_idx then
            has_expansion = true
            -- 1 keep atom drop question mark
            local p1 = string.sub(pat, 1, atom_end) .. string.sub(pat, q_idx + 1)
            -- 2 drop atom and question mark
            local p2 = string.sub(pat, 1, atom_start - 1) .. string.sub(pat, q_idx + 1)
            
            table.insert(result, p1)
            table.insert(result, p2)
        else
            table.insert(result, pat)
        end
    end

    if has_expansion then
        if #result > 100 then return result end
        return expand_optional(result)
    end
    
    return result
end

function RegexParser.smart_split(str, sep)
    local results = {}
    local current = ""
    local paren_depth = 0
    local brack_depth = 0
    for i = 1, #str do
        local char = string.sub(str, i, i)
        local prev = (i > 1) and string.sub(str, i-1, i-1) or ""
        if prev == "%" then
            current = current .. char
        else
            if char == '(' then paren_depth = paren_depth + 1 end
            if char == ')' then paren_depth = paren_depth - 1 end
            if char == '[' then brack_depth = brack_depth + 1 end
            if char == ']' then brack_depth = brack_depth - 1 end
            if char == sep and paren_depth == 0 and brack_depth == 0 then
                table.insert(results, current); current = ""
            else
                current = current .. char
            end
        end
    end
    table.insert(results, current)
    return results
end

function RegexParser.expand_groups(str_list)
    local expanded = {}
    for _, str in ipairs(str_list) do
        local s_idx, e_idx = nil, nil
        local depth = 0
        for i = 1, #str do
            local char = string.sub(str, i, i)
            local prev = (i > 1) and string.sub(str, i-1, i-1) or ""
            if prev ~= "%" then
                if char == "(" then
                    if depth == 0 then s_idx = i end
                    depth = depth + 1
                elseif char == ")" then
                    depth = depth - 1
                    if depth == 0 and s_idx then e_idx = i; break end
                end
            end
        end
        if s_idx and e_idx then
            local prefix = string.sub(str, 1, s_idx - 1)
            local content = string.sub(str, s_idx + 1, e_idx - 1)
            local suffix = string.sub(str, e_idx + 1)
            local parts = RegexParser.smart_split(content, "|")
            for _, part in ipairs(parts) do
                table.insert(expanded, prefix .. part .. suffix)
            end
        else
            table.insert(expanded, str)
        end
    end
    return expanded
end

local function ensure_anchor(p)
    if not p or p == "" then return p end
    -- append dollar
    local last = string.sub(p, -1)
    local prev = string.sub(p, -2, -2)
    if last ~= "$" or (last == "$" and prev == "%") then p = p .. "$" end
    -- prepend caret
    local first = string.sub(p, 1, 1)
    if first ~= "^" then p = "^" .. p end
    return p
end

function RegexParser.convert(regex_str)
    if not regex_str or regex_str == "" then return {} end
    local norm = RegexParser.normalize(regex_str)
    -- 1 split on pipe
    local list = RegexParser.smart_split(norm, "|")
    -- 2 expand groups
    local loop = 0
    local changed = true
    while changed and loop < 5 do
        local new_list = RegexParser.expand_groups(list)
        if #new_list > #list then list = new_list else changed = false end
        loop = loop + 1
    end
    -- 3 expand question quantifier
    -- splits regex with question mark into multiple exact regexes
    list = expand_optional(list)
    -- 4 add anchors
    for i, p in ipairs(list) do list[i] = ensure_anchor(p) end
    return list
end

function load_regex_patterns(config, path)
    local patterns = {}
    local map = config:get_map(path)
    if not map then return patterns end
    local keys = map:keys()
    if not keys then return patterns end
    
    local count = 0
    local is_ud = (type(keys) == "userdata")
    if is_ud then
        if keys.size then count = keys.size 
        else pcall(function() count = keys:size() end) end
    else
        count = #keys
    end

    for i = 0, count - 1 do
        local k_str
        if is_ud then
            local it = keys:get_value_at(i)
            if it then k_str = it.value end
            if not k_str then pcall(function() k_str = keys[i] end) end
        else
            k_str = keys[i+1]
        end

        if k_str then
            local val = map:get_value(k_str)
            if val and val.value and val.value ~= "" then
                local lua_pats = RegexParser.convert(val.value)
                for _, p in ipairs(lua_pats) do
                    table.insert(patterns, p)
                end
            end
        end
    end
    return patterns
end


-- numpad keycode map
local KP = {
    [0xFFB1] = 1,  -- KP_1
    [0xFFB2] = 2,
    [0xFFB3] = 3,
    [0xFFB4] = 4,
    [0xFFB5] = 5,
    [0xFFB6] = 6,
    [0xFFB7] = 7,
    [0xFFB8] = 8,
    [0xFFB9] = 9,
    [0xFFB0] = 0,  -- KP_0
}
local P = {}

-- debug minimal logging uncomment when needed
-- local function log_info(msg)
--    log.info("kp_number: " .. tostring(msg))
-- end

-- check whether input plus digit matches a command pattern
local function is_function_code_after_digit(env, context, digit_char)
    if not context or not digit_char or digit_char == "" then return false end
    local code = context.input or ""
    local s = code .. digit_char
    
    local pats = env.function_patterns
    if not pats then return false end

    for _, pat in ipairs(pats) do
        -- lua pattern match
        if s:match(pat) then return true end
    end
    return false
end

---@param env Env
function P.init(env)
    local engine  = env.engine
    local config  = engine.schema.config
    local context = engine.context
    
    env.page_size = config:get_int("menu/page_size") or 6
    local m = config:get_string("kp_number_mode") or "auto"
    if m ~= "auto" and m ~= "compose" then m = "auto" end
    env.kp_mode = m

    env.context      = context
    env.is_composing = context:is_composing()
    env.has_menu     = context:has_menu()

    -- load and translate regex from wanxiang module
    -- handles all yaml regex to lua pattern conversion
    env.function_patterns = load_regex_patterns(config, "recognizer/patterns")

    -- log_info("Loaded " .. #(env.function_patterns or {}) .. " patterns.")
    env.kp_update_connection = context.update_notifier:connect(function(ctx)
        env.context      = ctx
        env.is_composing = ctx:is_composing()
        env.has_menu     = ctx:has_menu()
    end)
end
---@param env Env
function P.fini(env)
    if env.kp_update_connection then
        env.kp_update_connection:disconnect()
        env.kp_update_connection = nil
    end
    env.context           = nil
    env.is_composing      = nil
    env.has_menu          = nil
    env.function_patterns = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    if key:release() then return RIME_PROCESS_RESULTS.kNoop end

    local context = env.context or env.engine.context
    local mode    = env.kp_mode or "auto"
    local page_sz = env.page_size

    -- 1 numpad digit handling
    local kp_num = KP[key.keycode]
    if kp_num ~= nil then
        -- log_info("Key: " .. (tostring(kp_num)) .. " pressed.")
        
        if key:ctrl() or key:alt() or key:super() or key:shift() then
            return RIME_PROCESS_RESULTS.kNoop
        end
        local ch = tostring(kp_num)

        -- if a pattern matches like url or lookup force encode
        if is_function_code_after_digit(env, context, ch) then
            if context.push_input then context:push_input(ch)
            else context.input = (context.input or "") .. ch end
            return RIME_PROCESS_RESULTS.kAccepted
        end

        -- normal digit logic
        if mode == "auto" then
            if env.is_composing then
                if context.push_input then context:push_input(ch)
                else context.input = (context.input or "") .. ch end
            else
                env.engine:commit_text(ch)
            end
        else -- compose
            if context.push_input then context:push_input(ch)
            else context.input = (context.input or "") .. ch end
        end
        return RIME_PROCESS_RESULTS.kAccepted
    end

    -- 2 main keyboard digit handling
    local r = key:repr() or ""
    if r:match("^[0-9]$") then
        if key:ctrl() or key:alt() or key:super() then
             return RIME_PROCESS_RESULTS.kNoop
        end
        
        if is_function_code_after_digit(env, context, r) then
            if context.push_input then context:push_input(r)
            else context.input = (context.input or "") .. r end
            return RIME_PROCESS_RESULTS.kAccepted
        end

        if env.has_menu then
            local d = tonumber(r)
            if d == 0 then d = 10 end 
            if d and d >= 1 and d <= page_sz then
                local composition = context.composition
                if composition and not composition:empty() then
                    local seg  = composition:back()
                    local menu = seg and seg.menu
                    if menu and not menu:empty() then
                        local sel_index = seg.selected_index or 0
                        local page_start = math.floor(sel_index / page_sz) * page_sz
                        local index = page_start + (d - 1)
                        if index < menu:candidate_count() then
                            if context:select(index) then
                                return RIME_PROCESS_RESULTS.kAccepted
                            end
                        end
                    end
                end
            end
            return RIME_PROCESS_RESULTS.kNoop
        end
    end

    return RIME_PROCESS_RESULTS.kNoop
end

return P