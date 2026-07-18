-- double pinyin aux code filter shape filtering via trigger key
-- based on rime-lua-aux-code by HowcanoeWang
-- Mintimate changes
--   1 show shape comment only after trigger key
--   2 config entry renamed to aux_code for this project

local AuxFilter = {}

-- log module
-- local log = require 'log'
-- log.outfile = "aux_code.log"

function AuxFilter.init(env)
    -- log.info("** AuxCode filter", env.name_space)

    -- each schema may use its own aux table no single module level table
    env.aux_code = AuxFilter.readAuxTxt(env.name_space)
    -- index only chars present in candidates avoid expanding the whole table
    env.aux_index = {}

    local engine = env.engine
    local config = engine.schema.config

    -- default trigger is semicolon read custom trigger from config
    env.trigger_key = config:get_string("aux_code/trigger_word") or ";"
    if env.trigger_key == "" then
        env.trigger_key = ";"
    end
    -- content replacement
    -- use upstream inline escaping preprocessed in init for notifier
    env.trigger_key_pattern = env.trigger_key:gsub("(%W)", "%%%1")

    -- whether to show aux code default show
    env.show_aux_notice = config:get_string("aux_code/show_aux_notice") or "always"

    ----------------------------
    -- keep selecting to commit keep aux delimiter present --
    ----------------------------
    env.notifier = engine.context.select_notifier:connect(function(ctx)
        -- handle selection only after delimiter is typed show_aux_notice
        -- only controls display must not reroute plain input below
        if not ctx.input:find(env.trigger_key, 1, true) then
            return
        end

        local preedit = ctx:get_preedit()
        local removeAuxInput = ctx.input:match("([^,]+)" .. env.trigger_key_pattern)
        local reeditTextFront = preedit.text:match("([^,]+)" .. env.trigger_key_pattern)

        -- ctx.text changes while selecting oaoaoa samples below
        -- ---- with aux code ----
        -- >>> 啊 oaoa；au
        -- >>> 啊吖 oa；au
        -- >>> 啊吖啊；au
        -- ---- without aux code ----
        -- >>> 啊 oaoa；
        -- >>> 啊吖 oa；
        -- >>> 啊吖啊；
        -- split the committed part preedit text
        -- 如果已經全部選完了，分割後的結果就是 nil，否則都是 吖卡 a 這種字符串
        -- verification
        -- log.info('select_notifier', ctx.input, removeAuxInput, preedit.text, reeditTextFront)

        -- when no letters remain leave split mode and drop the aux delimiter
        if not removeAuxInput then
            return
        end
        ctx.input = removeAuxInput
        if reeditTextFront and reeditTextFront:match("[a-z]") then
            -- append delimiter to word end re.match above removed it
            ctx.input = ctx.input .. env.trigger_key
        else
            -- commit the rest directly
            ctx:commit()
        end
    end)
end

----------------
-- read aux code file --
----------------
function AuxFilter.readAuxTxt(txtpath)
    --log.info("** AuxCode filter", 'read Aux code txt:', txtpath)
    AuxFilter.cache = AuxFilter.cache or setmetatable({}, { __mode = "v" })
    if AuxFilter.cache[txtpath] then
        return AuxFilter.cache[txtpath]
    end

    local defaultFile = 'ZRM_Aux-code_4.3.txt'
    local userPath = rime_api.get_user_data_dir() .. "/lua/aux_code/"
    local fileAbsolutePath = userPath .. txtpath .. ".txt"

    local file = io.open(fileAbsolutePath, "r") or io.open(userPath .. defaultFile, "r")
    if not file then
        -- stay usable when the optional aux file is missing retry on next deploy
        return {}
    end

    local auxCodes = {}
    for line in file:lines() do
        local clean_line = line:match("[^\r\n]+") -- strip line breaks otherwise value keeps trailing newline
        local key, value = clean_line:match("([^=]+)=(.+)") -- split variables around the equals sign
        if key and value then
            if auxCodes[key] then
                auxCodes[key] = auxCodes[key] .. " " .. value
            else
                auxCodes[key] = value
            end
        end
    end
    file:close()
    -- ensure code prints
    -- for key, value in pairs(AuxFilter.aux_code) do
    --     log.info(key, table.concat(value, ','))
    -- end

    AuxFilter.cache[txtpath] = auxCodes
    return auxCodes
end

-- lazy per char aux index false means char not in table avoids rechecking
local function get_char_aux_index(env, char)
    local cached = env.aux_index[char]
    if cached ~= nil then
        return cached or nil
    end

    local codes = env.aux_code[char]
    if not codes then
        env.aux_index[char] = false
        return nil
    end

    local entry = { k1 = {}, k12 = {} }
    for code in codes:gmatch("%S+") do
        if #code >= 1 then
            entry.k1[code:sub(1, 1)] = true
        end
        if #code >= 2 then
            entry.k12[code:sub(1, 2)] = true
        end
    end
    env.aux_index[char] = entry
    return entry
end

-- any char hit in a phrase returns both aux digits must come from the same
-- full code of one char avoid cross matching different chars or codes
local function word_matches_aux(env, word, aux_str)
    if not word or word == "" or aux_str == "" then
        return false
    end

    local one_key = #aux_str == 1
    local target = aux_str:sub(1, 2)
    for _, code_point in utf8.codes(word) do
        local entry = get_char_aux_index(env, utf8.char(code_point))
        if entry and ((one_key and entry.k1[target]) or (not one_key and entry.k12[target])) then
            return true
        end
    end
    return false
end

------------------
-- filter main function --
------------------
function AuxFilter.func(input, env)
    local context = env.engine.context
    local inputCode = context.input
    local has_trigger = inputCode:find(env.trigger_key, 1, true) ~= nil

    -- no aux trigger typed pass through skip hot path
    if not has_trigger and env.show_aux_notice ~= "always" then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local auxStr = ''
    if has_trigger then
        local localSplit = inputCode:match(env.trigger_key_pattern .. "([a-z]+)")
        if localSplit then
            auxStr = localSplit:sub(1, 2)
        end
    end

    local showComment = env.show_aux_notice == "always" or env.show_aux_notice == true or
        (env.show_aux_notice == "trigger" and has_trigger)

    -- iterate candidates
    for cand in input:iter() do
        local current_cand = cand
        local auxCodes = env.aux_code[current_cand.text] -- non nil only for single chars

        -- add aux code hint to candidate
        if showComment and auxCodes and #auxCodes > 0 then
            local codeComment = auxCodes:gsub(' ', ',')
            if current_cand:get_dynamic_type() == "Shadow" then
                local shadowText = current_cand.text
                local shadowComment = current_cand.comment or ""
                local originalCand = current_cand:get_genuine()
                if originalCand then
                    current_cand = ShadowCandidate(originalCand, originalCand.type, shadowText,
                        (originalCand.comment or "") .. shadowComment .. '(' .. codeComment .. ')')
                else
                    current_cand.comment = (current_cand.comment or "") .. '(' .. codeComment .. ')'
                end
            else
                current_cand.comment = (current_cand.comment or "") .. '(' .. codeComment .. ')'
            end
        end

        -- pass through without aux input with aux only exact per char hits
        if #auxStr == 0 then
            yield(current_cand)
        elseif (current_cand.type == 'user_phrase' or current_cand.type == 'phrase' or
                current_cand.type == 'simplified') and word_matches_aux(env, current_cand.text, auxStr) then
            yield(current_cand)
        end
    end
end

function AuxFilter.fini(env)
    if env.notifier then
        env.notifier:disconnect()
        env.notifier = nil
    end
    env.aux_index = nil
    env.aux_code = nil
end

return AuxFilter
