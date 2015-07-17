local utils = require "mp.utils"

local registered_events = {}
local observed_properties = {}

function string:split(delim, max_splits)
    if max_splits == nil or max_splits < 1 then
        max_splits = 0
    end
    local result = {}
    local pattern = "(.-)"..delim.."()"
    local splits = 0
    local last_pos = 1
    for part, pos in self:gmatch(pattern) do
        splits = splits + 1
        result[splits] = part
        last_pos = pos
        if splits == max_splits then break end
    end
    result[splits + 1] = self:sub(last_pos)
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

function register_event(req_id, event_name)
    registered_events[event_name] = function()
        local event_notification = utils.format_json({req_id})
        print(event_notification)
    end
    mp.register_event(event_name, registered_events[event_name])
    response = utils.format_json({req_id})
    print(response)
end

function unregister_event(req_id, event_name)
    mp.unregister_event(registered_events[event_name])
    response = utils.format_json({req_id})
    print(response)
end

function observe_property(req_id, property)
    observed_properties[property] = function(name, value)
        local event_notification = utils.format_json({req_id, name, value})
        print(event_notification)
    end
    mp.observe_property(property, "native", observed_properties[property])
    response = utils.format_json({req_id})
    print(response)
end

function unobserve_property(req_id, property)
    mp.unobserve_property(observed_properties[property])
    response = utils.format_json({req_id})
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
    elseif msg[2] == 'registerevent' then
        register_event(msg[1], msg[3])
    elseif msg[2] == 'unregisterevent' then
        unregister_event(msg[1], msg[3])
    elseif msg[2] == 'observeproperty' then
        observe_property(msg[1], msg[3])
    elseif msg[2] == 'unobserveproperty' then
        unobserve_property(msg[1], msg[3])
    end
end)
