--- 下载单个.gltf文件
-- 读取get请求参数
local local_args = ngx.req.get_uri_args()
-- dirid参数传入所在目录名称
local dirid = local_args["dirid"]
local name = local_args["name"]
local file_name

if nil == dirid or nil == name then
    ngx.print("参数有误！\n")
else
    file_name = "D:/openform-web/VTKRelease/"..dirid.."/"..name..".gltf"
    --- 以只读方式打开文件
    --local f = assert(io.open(file_name, 'r'), "该文件不存在！")
    local f = io.open(file_name, 'r')
    if nil == f then
        ngx.log(ngx.ERR, file_name, "该文件不存在！")
        ngx.print("该文件不存在！")
    else
        --- 从当前位置读取整个文件
        local file_data = f:read("*a")
        --- 关闭打开的文件
        f:close()
        ngx.print(file_data)
    end
end
