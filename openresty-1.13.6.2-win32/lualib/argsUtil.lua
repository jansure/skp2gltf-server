---/usr/local/openresty/lualib
local _M = {
    _VERSION = '0.10'
}

local inspect = require "inspect"
local args = {}
local file_args = {}
local is_have_file_param = false
local error_code, error_msg
local body_data
--- 以分隔符为准，将字符串分隔为table，table的key为1/2/3等，value为分隔出的字符串
local function explode(_str, seperator)
    local pos, arr = 0, {}
    for st, sp in function()
        return string.find(_str, seperator, pos, true)
    end do
        table.insert(arr, string.sub(_str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(_str, pos))
    return arr
end

function _M.init_form_args()
    local receive_headers = ngx.req.get_headers()
    local request_method = ngx.var.request_method
    if "GET" == request_method then
        args = ngx.req.get_uri_args()
    elseif "POST" == request_method then
        ngx.req.read_body()
        local content_type = receive_headers["content-type"]
        --判断是否是multipart/form-data类型的表单
        if content_type ~= nil and string.sub(content_type, 1, 20) == "multipart/form-data;" then
            ngx.log(ngx.ERR, "------是multipart/form-data类型的表单------")
            --body_data可是符合http协议的请求体，不是普通的字符串
            body_data = ngx.req.get_body_data()
            print(body_data)

            --请求体的size大于nginx配置里的client_body_buffer_size，则会导致请求体被缓冲到磁盘临时文件里，client_body_buffer_size默认是8k或者16k
            if not body_data then
                local datafile = ngx.req.get_body_file()
                --读取请求体数据，若为空则error
                if not datafile then
                    error_code = 1
                    error_msg = "no request body found"
                else
                    local fh, err = io.open(datafile, "r")
                    if not fh then
                        error_code = 2
                        error_msg = "failed to open " .. tostring(datafile) .. "for reading: " .. tostring(err)
                    else
                        fh:seek("set")
                        body_data = fh:read("*a")
                        --local filesize = fh:seek("end")
                        fh:close()
                        --if filesize == "0" then
                        if body_data == "" then
                            error_code = 3
                            error_msg = "request body is empty"
                        end
                    end
                end
            end
            local new_body_data = {}
            --确保取到请求体的数据
            if not error_code then
                local boundary = "--" .. string.sub(content_type, 31)
                --将请求体数据转换为table
                local body_data_table = explode(tostring(body_data), boundary)
                local first_string = table.remove(body_data_table, 1)
                local last_string = table.remove(body_data_table)
                --循环table，处理参数
                for i, v in ipairs(body_data_table) do
                    ngx.log(ngx.ERR, "------body_data_table[i]:", body_data_table[i])
                    --查找文件类型的参数，capture是参数名称，capture2是文件名
                    local start_pos, end_pos, capture, capture2 = string.find(v, 'Content%-Disposition: form%-data; name="(.+)"; filename="(.*)"')
                    --普通参数
                    if not start_pos then
                        local t = explode(v, "\r\n\r\n")
                        local temp_param_name = string.sub(t[1], 41, -2)
                        local temp_param_value = string.sub(t[2], 1, -3)
                        args[temp_param_name] = temp_param_value
                    else
                        is_have_file_param = true
                        --文件类型的参数，capture是参数名称，capture2是文件名
                        file_args[capture] = capture2
                        table.insert(new_body_data, v)
                        --print(inspect(new_body_data))
                    end
                end
                table.insert(new_body_data, 1, first_string)
                table.insert(new_body_data, last_string)
                --print(table.concat(new_body_data, ", "))
                --去掉app_key,app_secret等几个参数，把业务级别的参数传给内部的API
                --body_data可是符合http协议的请求体，不是普通的字符串
                body_data = table.concat(new_body_data, boundary)
                --print(body_data)
            end
        else
            ngx.log(ngx.ERR, "------非multipart/form-data类型的表单------")
            args = ngx.req.get_post_args()
            is_have_file_param = false
            file_args = {}
        end
    end
    return args, is_have_file_param, file_args, body_data
end

function _M.split(self, s, delim)

    if type(delim) ~= "string" or string.len(delim) <= 0 then
        return nil
    end

    local start = 1
    local t = {}

    while true do
        local pos = string.find(s, delim, start, true) -- plain find

        if not pos then
            break
        end

        table.insert(t, string.sub(s, start, pos - 1))
        start = pos + string.len(delim)
    end

    table.insert(t, string.sub(s, start))

    return t
end

function _M.get_post_form_data(self, form, err)

    if not form then
        ngx.log(ngx.ERR, "failed to new upload: ", err)
        return {}
    end

    form:set_timeout(1000) -- 1 sec
    local paramTable = { ["s"] = 1 }
    local tempkey = ""
    while true do
        local typ, res, err = form:read()
        if not typ then
            ngx.log(ngx.ERR, "failed to read: ", err)
            return {}
        end
        local key = ""
        local value = ""
        if typ == "header" then
            local key_res = _M.split(res[2], ";")
            key_res = key_res[2]
            key_res = _M.split(key_res, "=")
            key = (string.gsub(key_res[2], "\"", ""))
            paramTable[key] = ""
            tempkey = key
        end
        if typ == "body" then
            value = res
            if paramTable.s ~= nil then
                paramTable.s = nil
            end
            paramTable[tempkey] = value
        end
        if typ == "eof" then
            break
        end
    end
    return paramTable
end

return _M