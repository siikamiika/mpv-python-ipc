local utils = require "mp.utils"

function string.split(str, delim, maxsplit)
    local result = {}
    local buffer = ""
    local splits = 0
    for c in str:gmatch(".") do
        if splits ~= maxsplit and c == delim then
            table.insert(result, buffer)
            buffer = ""
            splits = splits + 1
        else
            buffer = buffer..c
        end
    end
    table.insert(result, buffer)
    return result
end

function unescape(input)
    return input:gsub("{c(%d+)}", function (charcode) return string.char(tonumber(charcode)) end)
end

function get_property(req_id, property, native)
    local gp = mp.get_property
    if native then gp = mp.get_property_native end
    local property = unescape(property)
    local val = utils.format_json({req_id, gp(property)})
    print(val)
end

function get_property_native(req_id, property)
    get_property(req_id, property, true)
end

function set_property(req_id, property, value)
    local property = unescape(property)
    local value = utils.parse_json(unescape(value))
    mp.set_property(property, value)
    local response = utils.format_json({req_id})
    print(response)
end

mp.register_event("client-message", function(e)
    local msg = e.args[2]
    msg = msg:split("_")
    msg[1] = tonumber(msg[1])
    if msg[2] == 'getproperty' then
        get_property(msg[1], msg[3])
    elseif msg[2] == 'getpropertynative' then
        get_property_native(msg[1], msg[3])
    elseif msg[2] == 'setproperty' then
        set_property(msg[1], msg[3], msg[4])
    end
end)
