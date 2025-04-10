local M = {}

-- Global state store
M.store = {}
M.listeners = {}
M.events = {}

-- State storage path - if nil, persistence is disabled
M.storage_path = nil

-- Basic state operations
function M.set(module, key, value)
    if not M.store[module] then
        M.store[module] = {}
    end
    local old_value = M.store[module][key]
    M.store[module][key] = value
    
    -- Notify listeners of the change
    M._notify_listeners(module, key, value, old_value)
    
    -- Save state if persistence is enabled
    if M.storage_path then
        M._schedule_save()
    end
end

function M.get(module, key)
    return M.store[module] and M.store[module][key]
end

-- Subscription system
function M.subscribe(module, key, callback)
    if not M.listeners[module] then
        M.listeners[module] = {}
    end
    if not M.listeners[module][key] then
        M.listeners[module][key] = {}
    end
    table.insert(M.listeners[module][key], callback)
    
    -- Return a function to unsubscribe
    return function()
        for i, cb in ipairs(M.listeners[module][key]) do
            if cb == callback then
                table.remove(M.listeners[module][key], i)
                return
            end
        end
    end
end

function M._notify_listeners(module, key, value, old_value)
    if M.listeners[module] and M.listeners[module][key] then
        for _, callback in ipairs(M.listeners[module][key]) do
            callback(value, old_value)
        end
    end
end

-- Event bus for module communication
function M.emit(event_name, data)
    data = data or {}
    if not M.events[event_name] then return end
    
    for _, handler in ipairs(M.events[event_name]) do
        handler(data)
    end
end

function M.on(event_name, handler)
    if not M.events[event_name] then
        M.events[event_name] = {}
    end
    table.insert(M.events[event_name], handler)
    
    -- Return unsubscribe function
    return function()
        for i, h in ipairs(M.events[event_name]) do
            if h == handler then
                table.remove(M.events[event_name], i)
                return
            end
        end
    end
end

-- State persistence
function M.enable_persistence(path)
    M.storage_path = path or vim.fn.stdpath('data') .. '/sysinit_state.json'
    M._load_state()
end

function M.disable_persistence()
    M.storage_path = nil
end

-- Load state from disk
function M._load_state()
    if not M.storage_path then return end
    
    local file = io.open(M.storage_path, "r")
    if not file then return end
    
    local content = file:read("*all")
    file:close()
    
    if content and #content > 0 then
        local ok, data = pcall(vim.json.decode, content)
        if ok and data then
            -- Merge instead of replace to preserve any new state
            for module, values in pairs(data) do
                if type(values) == "table" then
                    M.store[module] = M.store[module] or {}
                    for k, v in pairs(values) do
                        M.store[module][k] = v
                    end
                end
            end
        end
    end
end

-- Save state to disk (debounced)
local save_timer = nil
function M._schedule_save()
    if save_timer then
        vim.loop.timer_stop(save_timer)
    end
    
    save_timer = vim.defer_fn(function()
        M._save_state()
        save_timer = nil
    end, 1000) -- Debounce for 1 second
end

function M._save_state()
    if not M.storage_path then return end
    
    -- Only save state marked as persistent
    local persistent_state = {}
    for module, values in pairs(M.store) do
        if values._persistent then
            persistent_state[module] = {}
            for k, v in pairs(values) do
                if k ~= "_persistent" then
                    persistent_state[module][k] = v
                end
            end
        end
    end
    
    local encoded = vim.json.encode(persistent_state)
    local file = io.open(M.storage_path, "w")
    if file then
        file:write(encoded)
        file:close()
    end
end

-- Mark a module's state as persistent
function M.mark_persistent(module)
    if not M.store[module] then
        M.store[module] = {}
    end
    M.store[module]._persistent = true
end

-- API for module communication patterns
function M.request(target_module, request_type, data, callback)
    local request_id = tostring(math.random(1000000))
    local response_event = target_module .. ".response." .. request_id
    
    -- Set up one-time listener for response
    local cleanup = M.on(response_event, function(response)
        callback(response)
        cleanup()
    end)
    
    -- Send the request
    M.emit(target_module .. ".request", {
        type = request_type,
        data = data,
        request_id = request_id
    })
    
    -- Return function to cancel request
    return function()
        cleanup()
        M.emit(target_module .. ".cancel", { request_id = request_id })
    end
end

function M.respond(request, response)
    M.emit(request.sender .. ".response." .. request.request_id, response)
end

return M