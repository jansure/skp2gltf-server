--- 功能描述：查询进程状态，是否存在进程名
--- Created by yangpengfei.
--- DateTime: 2019/8/15 9:30
---
local shell = require "resty.shell"
local cmd
local param
-- 查询进程且不显示当前grep进程
--cmd = "ps -ef |grep -v grep |grep "
-- "-C"必须提供精确的进程名，并且它并不能通过部分名字或者通配符查找
-- cmd = "ps -C "
-- windows执行查询进程命令，例如 tasklist /fi "imagename eq nginx.exe"
cmd = "tasklist /fi "
-- 响应内容的数据格式
ngx.header.content_type = "text/plain; charset=utf-8"

-- 读取get请求参数 name参数传入进程名称
--local local_args = ngx.req.get_uri_args()
--param = local_args["name"]
--if nil == param then
--	ngx.say("name参数不能为空！\n")
--end

param = ngx.var.arg_name
if not param then
	ngx.status = ngx.HTTP_BAD_REQUEST
	ngx.print("name参数不能为空！\n")
	ngx.exit(ngx.status)
end

local args = {
	-- socket = "unix:/tmp/shell.sock",  --这是第一步的unxi socket
	-- 先在此端口上启动sockpro服务 ./sockproc.exe 5000 --foreground
	socket = {host = "127.0.0.1", port = 5000},
	-- 连接超时时间（毫秒）
	timeout = 3000,
	data = "\"imagename eq " .. param .. ".exe\"" .. "\r\n",
}

local status, out, err = shell.execute(cmd, args)
--ngx.say("process shell status:\n" .. status)

if not out then
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
	ngx.print("Result:\n", status, "\n", "err:\n", err)
	ngx.exit(ngx.status)
end

if 256 == status then
	ngx.print("Result: 此进程不存在\n")
end
-- 命令输出结果
ngx.print("Result:\n", out)