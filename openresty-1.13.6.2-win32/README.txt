运行在Windows服务器
1、	安装cygwin
2、	安装openresty，启动nginx.exe
3、	准备sockpro，并在5000端口启动
$ ./sockproc.exe 5000 --foreground
4、	准备file-server，并免密启动
$ ./file_server-master.exe -dir .  -debug -port ':8081'

以下为接口调用说明：
1、上传vtk文件
请求方法：PUT
请求路径：http://localhost:8080/uploadfile
请求参数格式：body的form-data（key : files ;  value : 待上传的文件）
内部逻辑：先在当前目录创建一个以GUID作为名称的文件夹，再将文件上传到此目录，
		  上传成功后在此目录下新建result文件夹，用于存放后续计算结果文件
响应结果：上传的文件所在目录名称

2、列出目录下的文件列表
请求方法：GET
请求路径：http://localhost:8080/listfile?dirid=test
请求参数说明：dirid--文件所在目录名称
响应结果：该目录下的文件列表（json格式）
响应结果说明："Name": 文件名,"Size": 文件大小,"ModTime": 最近修改时间,"IsDir": 是否文件夹,"IsText": 是否文本格式

3、调用可执行程序VTK2GLTF.exe-启动计算进程
请求方法：POST
请求路径：http://localhost:8080/VTK2GLTF
请求参数说明：dirid--文件所在目录名称
响应结果：VTK文件名称、经度值、纬度值、高度值

4、下载计算结果文件zip包
请求方法：GET
请求路径：http://localhost:8080/download?dirid=test
请求参数说明：dirid--文件所在目录名称
响应结果：该目录下的result文件夹压缩包
