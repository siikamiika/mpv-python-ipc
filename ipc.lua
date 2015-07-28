local utils = require "mp.utils"

local registered_events = {}
local observed_properties = {}

function unescape(input)
    return input:gsub("{c(%d+)}", function (charcode) return string.char(tonumber(charcode)) end)
end

function send_data(data)
    local id = data[1]
    table.remove(data, 1)
    local all = utils.format_json(data)
    local buflen = 1000
    local chunks = math.ceil(all:len() / buflen)
    local Start = 1
    local End = buflen
    for i = 1, chunks do
        local chunk = all:sub(Start, End)
        local line = utils.format_json({id, chunks, i, chunk})
        print(line)
        Start = Start + buflen
        End = End + buflen
    end
end

function get_property(req_id, property, native)
    local gp = mp.get_property
    if native then gp = mp.get_property_native end
    local property = unescape(property)
    send_data({req_id, gp(property)})
end

function get_property_native(req_id, property)
    get_property(req_id, property, true)
end

function set_property(req_id, property, value)
    local property = unescape(property)
    local value = utils.parse_json(unescape(value))
    mp.set_property(property, value)
    send_data({req_id})
end

function register_event(req_id, event_name)
    local event_name = unescape(event_name)
    registered_events[event_name] = function()
        send_data({req_id})
    end
    mp.register_event(event_name, registered_events[event_name])
    send_data({req_id})
end

function unregister_event(req_id, event_name)
    local event_name = unescape(event_name)
    mp.unregister_event(registered_events[event_name])
    send_data({req_id})
end

function observe_property(req_id, property)
    local property = unescape(property)
    observed_properties[property] = function(name, value)
        send_data({req_id, name, value or ""})
    end
    mp.observe_property(property, "native", observed_properties[property])
    send_data({req_id})
end

function unobserve_property(req_id, property)
    local property = unescape(property)
    mp.unobserve_property(observed_properties[property])
    send_data({req_id})
end

function commandv(req_id, args)
    local args = utils.parse_json(unescape(args))
    mp.commandv(unpack(args))
    send_data({req_id})
end

mp.register_event("client-message", function(e)
    local msg = e.args
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
    elseif msg[2] == 'commandv' then
        commandv(msg[1], msg[3])
    end
end)

print([[{"ready":true}]])
