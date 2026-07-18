-- unicode candidate translator
-- author Mintimate
-- unicode must be a standalone translator not a global lua filter
-- wrapping script_translator breaks lazy candidate expansion
-- of abbreviations on some librime versions

local unicode_translator = {}

local function format_u_plus(cp)
    return string.format("U+%04X", cp)
end

local function format_hex(cp)
    return string.format("%04X", cp)
end

local function format_html_entity(cp)
    return string.format("&#x%X;", cp)
end

local function format_perl_escape(cp)
    return string.format("\\x{%X}", cp)
end

local function codepoints(text)
    local result = {}

    local ok = pcall(function()
        for _, cp in utf8.codes(text) do
            result[#result + 1] = cp
        end
    end)

    if not ok then
        return nil
    end

    return result
end

local function join_codepoints(points, formatter, separator)
    local result = {}

    for i, cp in ipairs(points) do
        result[i] = formatter(cp)
    end

    return table.concat(result, separator or " ")
end

local function unique_candidates(candidates)
    local result = {}
    local seen = {}

    for _, text in ipairs(candidates) do
        if not seen[text] then
            seen[text] = true
            result[#result + 1] = text
        end
    end

    return result
end


local function js_escape(cp)
    if cp <= 0xFFFF then
        return string.format("\\u%04X", cp)
    end

    local value = cp - 0x10000
    local high = 0xD800 + math.floor(value / 0x400)
    local low = 0xDC00 + (value % 0x400)
    return string.format("\\u%04X\\u%04X", high, low)
end

local function unicode_candidates(points)
    return unique_candidates({
        join_codepoints(points, format_u_plus),
        join_codepoints(points, format_hex),
        join_codepoints(points, js_escape, ""),
        join_codepoints(points, format_html_entity, ""),
        join_codepoints(points, format_perl_escape, ""),
    })
end

function unicode_translator.init(env)
    env.unicode_memory = Memory(env.engine, env.engine.schema)
end

function unicode_translator.fini(env)
    if env.unicode_memory then
        env.unicode_memory:disconnect()
        env.unicode_memory = nil
    end
end

function unicode_translator.func(input, seg, env)
    local code
    if input:sub(1, 2) == "Uc" then
        code = input:sub(3)
    elseif seg:has_tag("unicode") then
        -- affix_segmentor strips the prefix first on some librime versions
        code = input
    else
        return
    end

    if code == "" then
        return
    end

    if not env.unicode_memory or not env.unicode_memory:dict_lookup(code, true, 50) then
        return
    end

    local entries_by_text = {}
    for entry in env.unicode_memory:iter_dict() do
        local weight = tonumber(entry.weight) or 0
        local saved = entries_by_text[entry.text]
        if not saved or weight > saved.weight then
            entries_by_text[entry.text] = {
                text = entry.text,
                weight = weight,
            }
        end
    end

    local entries = {}
    for _, entry in pairs(entries_by_text) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(a, b)
        if a.weight == b.weight then
            return a.text < b.text
        end
        return a.weight > b.weight
    end)

    for _, entry in ipairs(entries) do
        local points = codepoints(entry.text)

        if points and #points > 0 then
            for _, text in ipairs(unicode_candidates(points)) do
                yield(Candidate("unicode", seg.start, seg._end, text, "[" .. entry.text .. "]"))
            end
        end
    end
end

return unicode_translator
