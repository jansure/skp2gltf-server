--- 可以直接用反向代理实现
--- 列出dirid目录下所有文件
--- 此文件未使用
local http = require("resty.http")

local inheaders = ngx.req.get_headers()
local inmethod = ngx.var.request_method
local fileManager = "http://127.0.0.1:8081/"
-- 读取get请求参数
local local_args = ngx.req.get_uri_args()
-- dirid参数传入所在目录名称
local dirid = local_args["dirid"]
if nil == dirid then
    ngx.say("dirid参数不能为空！\n")
end
-- 列出目录下所有文件
local httpc = http:new()
local res, err = httpc:request_uri(
        fileManager,
        {
            path = fileManager .. dirid .. "/?format=json",
            method = inmethod,
            headers = inheaders
        }
)
if res.status ~= ngx.HTTP_OK then
    ngx.exit(res.status)
end
ngx.print(res.body)