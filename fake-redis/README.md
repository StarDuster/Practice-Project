# fake-redis

一个极其简单的 kv 存储。

> 你可能用了假的 redis

实现功能：kv


## 安装

Python 调试版本3.6，不能运行在 Python 2.x

依赖库：cmd2，requests，argparse

```
pip3 install cmd2 argparse
```

## 说明



## 使用方法

运行客户端：

```
./kvclient.py --host [IP] --port [PORT]  
```
如果运行时没有指定，默认连接127.0.0.1:5678，连接失败将显示错误并退出。

客户端启动后进入提示符等待输入：

```
connecting to 127.0.0.1 port 5678
(kvclient)
```

服务端：



## 已知问题

* 没有调试发送和接收缓冲，发送超大内容会丢失
* 没有对 pickle 序列化的内容进行检查，奇怪的输入可能造成命令执行等不可预知的问题

##参考

* Python 核心编程
* [PYMOTW](https://pymotw.com/3/)
* [Dive Into Python3](http://www.diveintopython3.net/)
* [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
* [cnblogs: Python socket 编程基础篇](http://www.cnblogs.com/jasonwang-2016/p/5646242.html)