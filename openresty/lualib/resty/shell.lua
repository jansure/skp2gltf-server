-- Copyright (C) 2014 Anton Jouline (juce)


local format = string.format
local match = string.match
local find = string.find
local tcp = ngx.socket.tcp
local tonumber = tonumber


local shell = {
    _VERSION = '0.02'
}

local default_socket = "unix:/tmp/shell.sock"


function shell.execute(cmd, args)
    local timeout = args and args.timeout
    local input_data = args and args.data or ""
    local socket = args and args.socket or default_socket

    local is_tcp
    if type(socket) == 'table' then
        if socket.host and tonumber(socket.port) then
            is_tcp = true
        else
            error('socket table must have host and port keys')
        end
    end

    local sock = tcp()
    local ok, err
    if is_tcp then
        ngx.log(ngx.INFO, "----socket.host----", socket.host)
    	ngx.log(ngx.INFO, "----socket.port----", socket.port)
        ok, err = sock:connect(socket.host, tonumber(socket.port))
    else
    --	ngx.log(ngx.ERR, "----socket----", socket)
        ok, err = sock:connect(socket)
    end
    if ok then
        --sock:settimeout(timeout or 15000)
        --sock:settimeouts(connect_timeout, send_timeout, read_timeout)单位毫秒
        sock:settimeouts(timeout or 15000, 5000, 3000)
        --sock:send(cmd .. "\r\n")
        sock:send(cmd .. " ")
        --sock:send(format("%d\r\n", #input_data))
        sock:send(input_data)
        sock:send("\r\n")

        ngx.log(ngx.INFO, "----cmd----", cmd)
        ngx.log(ngx.INFO, "---- #input_data----",  #input_data)
        --ngx.log(ngx.ERR, "---full cmd ----" , cmd .." " .. input_data)

        -- status code
        local data, err, partial = sock:receive('*l')
        -- 超时（请求超时或进程执行时间超时）err="timeout"
        if nil == data then
            return 1, nil, err
        end
        ngx.log(ngx.ERR, "---receive status code ----" .. data)
        if err then
            return -1, nil, err
        end
        local code = match(data,"status:([-%d]+)") or -1


        -- output stream
        data, err, partial = sock:receive('*l')
        --ngx.log(ngx.ERR, "---receive output stream ----" .. data)
        if err then
            return -1, nil, err
        end
        local n = tonumber(data) or 0
        local out_bytes = n > 0 and sock:receive(n) or nil

        -- error stream
        data, err, partial = sock:receive('*l')
        --ngx.log(ngx.ERR, "---receive error stream ----" .. data)
        if err then
            return -1, nil, err
        end
        n = tonumber(data) or 0
        local err_bytes = n > 0 and sock:receive(n) or nil

        sock:close()

        return tonumber(code), out_bytes, err_bytes
    end
    return -2, nil, err
end


return shell
