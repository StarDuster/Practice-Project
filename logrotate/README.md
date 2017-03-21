# rotate_log.sh

简单的 logrotate 逻辑 shell 实现，最初参考了 Debian 等发行版中存在的 [savelog.sh](http://www.unix.com/man-page/linux/8/savelog/)

实现功能：对于指定的文件名为`filename<.n>`样式的文件，依次备份为`filename<.n+1>`，并可对一定数量以上的文件进行压缩。

经过以下 shell 测试工作正常：

* bash(4.3.11 x86_64-pc-linux-gnu)
* bash(3.2.57 x86_64-apple-darwin15)
* zsh(5.3.1 x86_64-apple-darwin15.6.0)
* ksh(93u+ 2012-08-01)

不完全兼容

* dash(0.5.7-4ubuntu1)
* dash(0.5.9.1 homebrew)

## 使用方法

#### 用法举例：

```
./rotate_log.sh -m truncate -s 10k -z 5 /path/to/app1.log /path/to/app2.log 
./rotate_log.sh --mode truncate --size 10k --count 5 app1.log
```

#### 参数说明：

各选项在不指定值的时候将使用默认值，可以不输入所有的选项

`-n` 使用此参数的时候不会执行实际操作，但是会正常打印输出并展示将进行的操作

`-m | --mode` 操作模式，指定为`move`时将`mv`移动源文件并`touch`创建新文件，指定为`truncate`时将`cp`复制到新文件并使用`truncate`清空源文件，执行时将判断`truncate`命令是否存在，不存在将直接退出不执行任何操作，默认值为 move

`-s | --size` 指定执行操作所需最小文件大小，当`filename`文件小于指定大小将直接退出不进行任何操作，参数以`G/g/M/m/K/k`结尾，如`-s 1m`，默认值为10k

`-z | --count` 指定需要执行压缩的最小文件编号，实际上也是目录下保留未压缩文件的数量，参数为纯数字，如`-z 10`，默认值为5

`filename` 附带完整路径的文件名，不指定路径则为脚本所在目录，需要注意文件名必须完全正确，即`app1.log`和`app2.log`不能输入`app*.log`

#### 输出样例：

```
$ ls | sort -t '.' -k5n                                                                        

test.xxx.yyy.log
test.xxx.yyy.log.1
test.xxx.yyy.log.2
test.xxx.yyy.log.3
···
test.xxx.yyy.log.15

$ bash /tmp/rotate.sh -m move -s 0k -z 5 /tmp/test/test.xxx.yyy.log

rotate mode is move
The minimal file to rotate is 0k
The count to keep uncopressed is 5
file /tmp/test/test.xxx.yyy.log check pass
total 16 files, 0 gzipped, 16 not gzipped
processing /tmp/test/test.xxx.yyy.log.15, rotate to /tmp/test/test.xxx.yyy.log.16
processing /tmp/test/test.xxx.yyy.log.14, rotate to /tmp/test/test.xxx.yyy.log.15
···
processing /tmp/test/test.xxx.yyy.log.1, rotate to /tmp/test/test.xxx.yyy.log.2
processing /tmp/test/test.xxx.yyy.log, rotate to /tmp/test/test.xxx.yyy.log.1
gzip /tmp/test/test.xxx.yyy.log.16, save to /tmp/test/test.xxx.yyy.log.16.gz
gzip /tmp/test/test.xxx.yyy.log.15, save to /tmp/test/test.xxx.yyy.log.15.gz
gzip /tmp/test/test.xxx.yyy.log.14, save to /tmp/test/test.xxx.yyy.log.14.gz
···
gzip /tmp/test/test.xxx.yyy.log.5, save to /tmp/test/test.xxx.yyy.log.5.gz
total 17 files, 12 gzipped, 5 not gzipped
```


## 已知问题

* 由于`echo`操作的参数定义存在区别，dash 的输出会每一行多一个"-e"，但是文件操作正常
* MacOS、BSD 等系统不存在`truncate`命令，执行时将无法通过检查直接退出，通过 homebrew 安装 coreutils 包，并执行`alias truncate="/usr/local/bin/gtruncate"`可以避免问题
* 没有对所有外部命令都进行存在检验，如`awk`，这些命令不存在执行将引起循环控制不正常
* `getopts`不能处理长选项，而部分 BSD 平台默认没有`getopt`工具，因此使用了较为 hack 的办法解析长选项
* `filename`参数如果带有错误的通配符，文件操作可能引起不可知的结果，此错误由于通配展开在脚本执行前，脚本内部无法得知传入的原始参数，故没有处理
* 当文件不是严格按照序号递增时（如 1 2 4 5 6），统计会出错，但是由于正常情况不会出现文件序号出现这样的断层，因此没做处理

## 参考

* [Linux Shell Scripting Tutorial A Beginner's handbook](https://bash.cyberciti.biz/guide/Main_Page)
* [GNU bash manual](https://www.gnu.org/software/bash/manual/html_node/)
* [TLDP: Advanced Bash-Scripting Guide](http://tldp.org/LDP/abs/html/)
* [IBM Developerworks: Bash 参数和参数扩展](https://www.ibm.com/developerworks/cn/linux/l-bash-parameters.html)
* [Stackoverflow: Using getopts in bash shell script to get long and short command line options](http://stackoverflow.com/questions/402377/using-getopts-in-bash-shell-script-to-get-long-and-short-command-line-options)

