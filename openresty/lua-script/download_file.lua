-- 读取get请求参数
local local_args = ngx.req.get_uri_args()
-- id参数传入所在目录名称
local id = local_args["id"]
local name = local_args["name"]
local file_name
ngx.header.content_type = "text/plain; charset=utf-8"

if nil == id or nil == name then
    ngx.say("参数不能为空！\n")
else
    file_name = "D:/openform-web/VTKRelease/"..id.."/"..name..".gltf"
    --- 以只读方式打开文件
    --local f = assert(io.open(file_name, 'r'), "该文件不存在！")
    local f = io.open(file_name, 'r')
    if nil == f then
        ngx.print("该文件不存在！")
    else
        --- 从当前位置读取整个文件
        local file_data = f:read("*a")
        --- 关闭打开的文件
        f:close()
        ngx.print(file_data)
    end
end
