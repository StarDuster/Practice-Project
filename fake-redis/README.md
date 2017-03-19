# fake-redis

一个极其简单而没用的 kv 存储。

> 你可能用了假的 redis

实现功能：kv 存储，多客户端连接，获取 URL 并存储，简单的用户验证。

## 安装

Python 调试版本3.6，不能运行在 Python 2.x

依赖库：cmd2，requests，argparse，selectors，pickle 等

```
pip3 install cmd2 argparse requests 
```

## 说明

没有数据持久化，服务端数据全部以字典形式保存。

客户端使用 cmd2 模块，使用面向对象模式，主类为`KvClient(cmd2.Cmd)`

服务端基于 Python 官网文档的 selectors demo 改写，使用单线程 IO 复用实现多用户连接。

客户端和服务端的数据交互使用 pickle 序列化的字典，其格式如下：

```
{'command':'', 'key':'', 'value':'', 'url':'', \
'username':'', 'password':'', 'cookie':''}
```

客户端 cookie 在 send_data 里附加，服务端执行 URL 指令前验证 cookie 是否存在于服务端 cookie 列表中，不在则返回 not authed 消息。

URL 超时时间为1秒，因为水平有限，服务器没有做异步，太久了所有客户端都会卡住。

## 使用方法

#### 用法举例

首先启动服务端：

```
./kvserver.py --host [IP] --port [PORT]  
```
如果运行时没有将`--host`或者`--port`都指定，则默认绑定 127.0.0.1:5678。

运行客户端：

```
./kvclient.py --host [IP] --port [PORT]  
```
如果运行时没有将`--host`或者`--port`都指定，则默认连接 127.0.0.1:5678，连接失败将显示错误并退出。

客户端启动后进入提示符等待输入：

#### 客户端指令说明

客户端没有完全按照指南要求一次执行发送一个请求，而是直接像 shell 中一样执行命令即可，可以使用的命令有`set``get``auth``url`，命令不区分大小写。

`set [key] [value]`将在服务端上记录一组 K-V 值，key 值存在时覆盖原值。

`get [key]`向服务端查询 key 值对应的 value。

`auth [username] [password]`向服务端发送认证，服务端读取`auth.conf`查询 username 是否在文件里，密码是否匹配，通过则返回 cookie，客户端保存 cookie，之后每次发送请求都携带 cookie。如果认证失败，返回 'auth failed'。

`url [key] [url]`向服务端发送 url 请求，服务端将代为访问 url 中的页面，获取 Content-Length 字段和 http 响应码联合作为一个字符串保存。如果没有执行 auth 命令，返回 'not authed'


#### 用法样例

```
connecting to 127.0.0.1 port 5678
Welcome to fake-redis, a useless kv storage service
(kvclient) url baidu http://baidu.com
Received not authed
(kvclient) auth user1 pass1
Received {'cookie': '56b160ac'}
(kvclient) url baidu http://baidu.com
Received done!
(kvclient) get baidu
Received length:81, code: 200
(kvclient) set sina sina.com
Received done!
(kvclient) get sina
Received sina.com
(kvclient)
```



## 已知问题

* 没有调试发送和接收缓冲，发送超大内容会丢失
* 没有对 pickle 序列化的内容进行检查，奇怪的输入可能造成命令执行等不可预知的问题
* 如 [163.com](http://163.com) 等链接跟随301则最终的响应头里没有 Content-Length 字段，这种情况我认为仍然 URL 执行成功并存储为 None
* 没有销毁断开连接客户端的 cookie，由于 cookie 生成带时间戳，理论不会重复，但是会引起内存泄露
* 客户端没有捕获 Ctrl+C，也没有监测链接状态，服务端挂掉之后客户端不会有反应

## 参考

* Python 核心编程
* [PYMOTW](https://pymotw.com/3/)
* [Dive Into Python3](http://www.diveintopython3.net/)
* [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
* [cnblogs: Python socket 编程基础篇](http://www.cnblogs.com/jasonwang-2016/p/5646242.html)