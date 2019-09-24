--- DateTime: 2019/8/14 9:30
---
local shell = require("resty.shell")

local args = {
    -- socket = "unix:/tmp/shell.sock",
    -- 先在此端口上启动sockpro服务 ./sockproc.exe 5000 --foreground
    socket = {host = "127.0.0.1", port = 5000},
    data = "\r\n",
}
local status, result, err = shell.execute("/cygdrive/d/openform-web/VTKRelease/VTK2GLTF.exe `cygpath -w /cygdrive/d/openform-web/VTKRelease/data/windpressure_building_11.vtk` `cygpath -w  /cygdrive/d/openform-web/VTKRelease/data` `cygpath -w /cygdrive/d/openform-web/VTKRelease/GDAL_DATA`", args)

ngx.header.content_type ="text/plain"

if err ~= nil then
    ngx.say("err: ".. err)
end
if result ~= nil then
    ngx.say("result: ".. result)
end
