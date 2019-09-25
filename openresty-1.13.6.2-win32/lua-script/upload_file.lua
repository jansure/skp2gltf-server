--- 功能描述：前提启动file-manager服务，接收body类型为form-data的PUT请求
--- 1、先在当前目录创建一个以GUID作为名称的文件夹
--- 2、调用内部代理接口（/uploadAndUnzip）把请求中的文件(一个或多个)上传到此文件夹，并解压
--- 3、若上传成功，返回文件夹GUID；若上传失败，删除第1步所创建的文件夹
--- Created by yangpengfei.
--- DateTime: 2019/8/15 9:30
---
local json = require("cjson")
local guid = require ("guid")
local http = require("resty.http")
-- file-manager服务地址
local fileManager = "http://127.0.0.1:8081"
local httpc = http:new()
-- 设置连接超时时间
httpc:set_timeout(5000)
-- 响应内容的数据格式
-- ngx.header.content_type = "text/plain; charset=utf-8"
ngx.header.content_type = "application/json; charset=utf-8"

-- 读取get请求参数，根据参数判断是否需要解压文件
local local_args = ngx.req.get_uri_args()
-- unzip参数传入所在目录名称
local unzip = local_args["unzip"]
if not unzip or unzip == "" then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.print("unzip参数不能为空！")
    ngx.exit(ngx.status)
end

-- 创建新文件夹
-- 生成一个随机标识，作为新文件夹名称
local dirName = guid.generate()
ngx.log(ngx.INFO, "待新建的目录名称：", dirName)
local res1, err1 = httpc:request_uri(
        fileManager,
        {
            -- 指定具体路径
            path = '/',
            -- 请求的参数
            query = { format = 'json' },
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json;charset=UTF-8",
            },
            -- 请求体数据
            body = "{\"action\":\"createFolder\",\"params\":{\"source\":\"/"..dirName.."\"}}"
        }
)
--若文件夹创建失败，则返回状态码并退出
if not res1 or res1.status ~= ngx.HTTP_OK then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.log(ngx.ERR, "新建目录失败：", err1, "请检查fileManager服务是否可连接")
    ngx.print("新建目录失败：", err1)
    ngx.exit(ngx.status)
end

--若文件夹创建成功，则上传文件，并解压文件
ngx.req.read_body()
local res, err = ngx.location.capture('/uploadAndUnzip',
        { method = ngx.HTTP_PUT,
          args = {unzip = unzip, destPath = dirName},
          always_forward_body = true }
)

--如果上传失败，删除所建目录
if not res or res.status ~= ngx.HTTP_OK then
    ngx.log(ngx.ERR, "上传文件失败：", err, "请检查uploadAndUnzip接口是否正常")
    local res2, err2 = httpc:request_uri(
            fileManager,
            {
                path = '/',
                method = "POST",
                headers = {
                    ["Content-Type"] = "application/json;charset=UTF-8",
                },
                --{"action":"delete","paramslist":["/7AED6B57-18E1-B312-77E9-B756AE4D65F9"]}
                body = "{\"action\":\"delete\",\"paramslist\":[\"/"..dirName.."\"]}"
            }
    )
    if not res2 or res2.status ~= ngx.HTTP_OK then
        ngx.log(ngx.ERR, "删除创建的目录：", dirName, "失败，err：", err2)
        ngx.status = res2.status
        ngx.print("删除创建的目录失败：", err2)
        ngx.exit(ngx.status)
    end
    ngx.log(ngx.INFO, "已删除创建的目录：", dirName)
    ngx.status = res.status
    -- 如果调用上传接口失败，则使用子请求状态码退出
    ngx.exit(res.status)
end

if res.truncated then
    ngx.log(ngx.ERR, "上传文件时数据被意外截断！文件所在目录：", dirName)
end

--创建result文件夹
local res3, err3 = httpc:request_uri(
        fileManager,
        {
            path = '/',
            query = { format = 'json' },
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json;charset=UTF-8",
            },
            body = "{\"action\":\"createFolder\",\"params\":{\"source\":\"/"..dirName.."/result\"}}"
        }
)
if not res3 or res3.status ~= ngx.HTTP_OK then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.log(ngx.ERR, "在目录：", dirName, "下创建result目录失败，err：", err3)
    ngx.print("创建result目录失败：", err3)
    ngx.exit(ngx.status)
end
-- res.body="ok"
ngx.log(ngx.INFO, "上传文件完成：", res.body, " 所在目录为：", dirName)
--ngx.print("上传文件所在目录为：", dirName)
-- 输出json格式的结果 例如：{ "dirid": "19B512E8-2D34-99A4-7EB9-81FA91647B84"}
ngx.print(json.encode({dirid=dirName}))