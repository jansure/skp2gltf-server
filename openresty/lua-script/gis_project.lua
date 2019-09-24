local cjson = require("cjson")
cjson.encode_keep_buffer = 0
local unicode = require("unicode")
--local lc = require('lc')
local utf8 = require('lua-utf8')
local stringext = require('stringext')

--- 函数：读取文件
function getFile(file_name)
    -- 以只读方式打开文件
    local f = assert(io.open(file_name, 'r'))
    -- 从当前位置读取整个文件
    local string = f:read("*a")
    -- 关闭打开的文件
    f:close()
    return string
end

--- 建立tcp连接
local tcpsock = ngx.socket.tcp()
local host = "127.0.0.1"
local port = 7000
local ok, err = tcpsock:connect(host, port)
if not ok then
    ngx.log(ngx.ERR, "failed to connect tcp server:", err)
    ngx.status = 500
    return nil, err
end
--- 3000 seconds timeout
tcpsock:settimeouts(30000, 30000, 30000)

local bytes
local vdata = {}
local reqdata
local reqdatalist = {}
local reqdatalistlen
reqdata = "{"
local args_tab = ngx.req.get_uri_args()
--ngx.header["Content-Type"]="charset=utf-8"
--- 拼接实际请求参数
for k, v in pairs(args_tab) do
    --ngx.log(ngx.ERR, "------k:", k)
    -- 使用utf8编码
    v = utf8.escape(v)
    ngx.log(ngx.ERR, "------v:", v)
    reqdata = reqdata .. (string.format("\"%s\"", k)) .. ":" .. v .. ","
end
reqdata = string.sub(reqdata, 0, string.len(reqdata) - 1) .. "}"
--ngx.log(ngx.ERR, "-----reqdata:", reqdata)
-- 将带发送的字符串拆分成单个字符的数组
reqdatalist, reqdatalistlen = stringext.stringToChars(reqdata)
-- 遍历字符数组，将中文字符替换为其unicode编码值
for i = 1, reqdatalistlen do
    if (stringext.isCJKCode(reqdatalist[i])) then
        reqdatalist[i] = unicode.encode(reqdatalist[i])
        --ngx.log(ngx.ERR, "-----reqdatalist----:", reqdatalist[i])
    end
end
-- 将字符数组转为字符串
reqdata = table.concat(reqdatalist)
--ngx.log(ngx.ERR, "-----reqdata table.concat(reqdatalist)----:", reqdata)

-- 发送请求数据
bytes, err = tcpsock:send(reqdata .. "\r\n\r\n")
if err then
    ngx.log(ngx.ERR, "failed to send request data to tcp server:", err)
    return
end
ngx.log(ngx.ERR, "successfully send request data to tcp server:", bytes)

-- 接收响应数据
local resp_tmp1, err, part = tcpsock:receive()
if (not resp_tmp1) and (err ~= 'timeout') then
    ngx.log(ngx.ERR, "failed to receive response from tcp server:", err)
    return nil, err
end
resp_tmp1 = resp_tmp1 or part
if not resp_tmp1 then
    ngx.log(ngx.ERR, "failed to receive response from tcp server:", err)
    return nil, 'timeout'
end
ngx.log(ngx.ERR, "successfully receive response from tcp server:", resp_tmp1)
-- 将响应解码为json格式
vdata = cjson.decode(resp_tmp1)
local resp = vdata["response"]

if resp == "server_getfile_prepare" then
    --- 新建项目请求接口（response值为server_getfile_prepare时上传文件）
    -- 读取请求体body
    ngx.req.read_body()
    -- 读取请求体data
    local bodydata = ngx.req.get_body_data()
    ngx.log(ngx.ERR, "request data: ", bodydata)

    -- 若请求体data为nil，说明数据超出限制，已被存入磁盘文件，使用get_body_file()函数获取
    if nil == bodydata then
        local file_name = ngx.req.get_body_file()
        ngx.log(ngx.ERR, "request file_name: ", file_name)
        if file_name then
            bodydata = getFile(file_name)

        end
    end

    -- 发送文件流到服务器
    bytes, err = tcpsock:send(bodydata)
    if err then
        ngx.log(ngx.ERR, "failed to send bodydata to tcp server:", err)
        return
    end
    ngx.log(ngx.ERR, "successfully send bodydata to tcp server:", bytes)

    -- 接收响应
    local resp_tmp2
    repeat
        resp_tmp2, err, part = tcpsock:receive()
        if (not resp_tmp2) and (err ~= 'timeout') then
            ngx.log(ngx.ERR, "failed to receive response from tcp server:", err)
            break
        end
        resp_tmp2 = resp_tmp2 or part
        if not resp_tmp2 then
            ngx.log(ngx.ERR, "failed to receive response from tcp server:", err)
            break
        end
        ngx.log(ngx.ERR, "successfully receive response from tcp server:", resp_tmp2)
        --resp_tmp2_data = cjson.decode(resp_tmp2)
        --ngx.log(ngx.ERR, "string.find(resp_tmp2,\"response\"):", string.find(resp_tmp2, "response"))
    until (string.find(resp_tmp2, "response") ~= nil)
    ngx.print(unicode.decode(resp_tmp2))

elseif resp == "server_sendfile_prepare" then
    --- 下载计算结果文件请求接口（response值为server_sendfile_prepare时服务端准备下发文件）
    local filesize = vdata["file_size"]
    --ngx.log(ngx.ERR, "---待接收文件大小filesize----:", filesize)
    -- 客户端发送接收文件的标识{"response":"client_getfile_prepare"}
    bytes, err = tcpsock:send("{\"response\":\"client_getfile_prepare\"}" .. "\r\n\r\n")
    if err then
        ngx.log(ngx.ERR, "failed to send client_getfile_prepare to tcp server:", err)
        return
    end
    ngx.log(ngx.ERR, "successfully send client_getfile_prepare to tcp server:", bytes)

    -- 客户端接收文件
    local bufsize = 8192
    local receivesize = 0
    -- 先接收服务端发过来的4个字节\r\n\r\n
    local first4, err = tcpsock:receive(4)
    -- 开始接收文件内容
    while not ngx.worker.exiting() do
        if receivesize >= filesize then
            ngx.log(ngx.ERR, "---已接收完毕----:", receivesize)
            -- 发送接收文件完毕的标识{"response":"client_getfile_ok"}
            bytes, err = tcpsock:send("{\"response\":\"client_getfile_ok\"}" .. "\r\n\r\n")
            if err then
                ngx.log(ngx.ERR, "failed to send client_getfile_ok to tcp server:", err)
                return
            end
            ngx.log(ngx.ERR, "successfully send client_getfile_ok to tcp server:", bytes)

            --- receive response
            local resp_tmp3
            repeat
                resp_tmp3, err, part = tcpsock:receive()
                if (not resp_tmp3) and (err ~= 'timeout') then
                    ngx.log(ngx.ERR, "failed to receive response from tcp server:", err)
                    break
                end
                resp_tmp3 = resp_tmp3 or part
                if not resp_tmp3 then
                    ngx.log(ngx.ERR, "failed to receive response from tcp server:", err)
                    break
                end
                ngx.log(ngx.ERR, "successfully receive response from tcp server:", resp_tmp3)
                --resp_tmp2_data = cjson.decode(resp_tmp2)
                --ngx.log(ngx.ERR, "string.find(resp_tmp3,\"response\"):", string.find(resp_tmp3, "response"))
            until (string.find(resp_tmp3, "response") ~= nil)
            ngx.print(unicode.decode(resp_tmp3))

            break
        else
            repeat
                --接收数据
                local line, err, partial = tcpsock:receive(bufsize)
                line = line or partial

                --timeout则继续接收数据
                if (not line) and (err ~= 'timeout') then
                    ngx.log(ngx.ERR, 'receive error:', err)
                    return
                end
                if not line then
                    ngx.log(ngx.ERR, 'line is nil.')
                    break
                end

                --ngx.log(ngx.ERR, "---已接收line----:", line)
                receivesize = receivesize + string.len(line)
                --ngx.log(ngx.ERR, "---已接收大小----:", receivesize)
                ngx.print(line)
                ngx.flush(true)
            until true
        end
    end
else
    --- 不涉及文件上传下载的接口，直接输出响应数据
    -- 将响应中的unicode字符解码为utf8
    ngx.print(unicode.decode(resp_tmp1))
end
tcpsock:send("bye \r\n\r\n")
ngx.log(ngx.ERR, " send bye! ")
tcpsock:close()