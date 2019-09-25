--- 功能描述：前提windows系统安装cygwin，并在5000端口上启动sockpro服务，接收POST请求
--- POST请求参数为dirid
--- 1、启动计算进程VTK2GLTF.exe，将计算结果文件输出到该目录的result文件夹下
--- 2、返回计算进程的结果
--- Created by yangpengfei.
--- DateTime: 2019/8/14 9:30
---
local shell = require("resty.shell")
-- 响应内容的数据格式
ngx.header.content_type = "text/plain; charset=utf-8"
-- 读取post请求参数
ngx.req.read_body()
local local_args = ngx.req.get_post_args()
-- dirid参数传入所在目录名称
local dirid = local_args["dirid"]
-- ngx.log(ngx.INFO, "dirid参数: ", dirid)
if not dirid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.print("dirid参数不能为空！")
    ngx.exit(ngx.status)
end

local args = {
    -- socket = "unix:/tmp/shell.sock",
    -- 先在此端口上启动sockpro服务 ./sockproc.exe 5000 --foreground
    socket = {host = "127.0.0.1", port = 5000},
    -- 连接超时时间（毫秒）
    timeout = 3000,
    data = "\r\n",
}

-- 启动计算进程
local exeDir = "/cygdrive/d/openform-web/VTKRelease/VTK2GLTF.exe"
local vtkDir = " `cygpath -w /cygdrive/d/openform-web/VTKRelease/"..dirid.."` "
local GLTFDir = " `cygpath -w  /cygdrive/d/openform-web/VTKRelease/"..dirid.."/result".."` "
local GDAL_DATADir = " `cygpath -w /cygdrive/d/openform-web/VTKRelease/GDAL_DATA` "
local cmd = exeDir .. vtkDir .. GLTFDir .. GDAL_DATADir

--local status, result, err = shell.execute("/cygdrive/d/openform-web/VTKRelease/VTK2GLTF.exe `cygpath -w /cygdrive/d/openform-web/VTKRelease/data` `cygpath -w  /cygdrive/d/openform-web/VTKRelease/data` `cygpath -w /cygdrive/d/openform-web/VTKRelease/GDAL_DATA`", args)
local status, result, err = shell.execute(cmd, args)

if not result then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.log(ngx.ERR, "执行计算进程失败，请确认fileserver服务启动的目录是否正确，并且以下目录存在：", vtkDir, "\n", GLTFDir)
    ngx.print("Result:\n执行计算进程失败，请确认vtk文件存在，并且result子目录存在。")
    ngx.exit(ngx.status)
end

if err ~= nil then
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    ngx.print("err: ", err)
    ngx.exit(ngx.status)
end

ngx.print("result: ", result)