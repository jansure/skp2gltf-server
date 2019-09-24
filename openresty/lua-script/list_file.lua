local lfs = require("lfs")

-- 读取get请求参数
local local_args = ngx.req.get_uri_args()
-- id参数传入所在目录名称
local id = local_args["id"]
local file_name
-- 列出目录下所有文件
local function attrdir (path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                print(f)
            end
        end
    end
end

if nil == id then
    ngx.say("参数不能为空！\n")
else
    attrdir("D:/openform-web/VTKRelease/"..id)
end
