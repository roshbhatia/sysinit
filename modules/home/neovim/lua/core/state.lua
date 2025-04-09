local M = {}

-- Global state store
M.store = {}
M.listeners = {}

function M.set(module, key, value)
    if not M.store[module] then
        M.store[module] = {}
    end
    M.store[module][key] = value
    M._notify_listeners(module, key, value)
end

function M.get(module, key)
    return M.store[module] and M.store[module][key]
end

function M.subscribe(module, key, callback)
    if not M.listeners[module] then
        M.listeners[module] = {}
    end
    if not M.listeners[module][key] then
        M.listeners[module][key] = {}
    end
    table.insert(M.listeners[module][key], callback)
end

function M._notify_listeners(module, key, value)
    if M.listeners[module] and M.listeners[module][key] then
        for _, callback in ipairs(M.listeners[module][key]) do
            callback(value)
        end
    end
end

return M
