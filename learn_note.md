### 总体框架
- 初始化
  - freebsd协议栈需要的元素全部创建好.
    > 如: 接口/ip/默认路由等等
  - 设置接口的处理函数为ether_input, 报文通过ether_input可以送入freebsd的协议栈
  - 设置接口的发送回调函数为ff_veth_transmit, 这样，所有报文可以通过dpdk发送出去.
  - 设置相应的ff_veth_ioctl/ff_veth_start等控制函数，以便通过ifconfig控制freebsd协议栈.

- dpdk 接收报文

### 报文处理流程
- ff_veth_input
  - ff_veth_process_packet
	- ether_input
- ff_veth_transmit
  - ff_dpdk_if_send: 将协议栈的相应一个个的发送出去.

### kni.
- veth0 为f-stack创建的kni接口，用来处理协议报文.
- 数据报文无需走这个接口.
- 系统创建一个rte-ring用来向内核发送/接收kni报文.
- 系统为每个物理接口创建一个kni接口
- kni用的是单线程模式.
  - 系统只会启动一个kni线程，来处理所有kni业务，因此性能会是瓶颈.
- carrier=on
  - dpdk kni模块的默认接口是off
  - carrier=on意味着接口创建kni接口时会调用netif_carrier_on函数，否则调用netif_carrier_off函数.
	- netif_carrier_on
	  > 设备驱动监测到设备传递信号时调用
    - netif_carrier_off
	  > 设备驱动监测到设备丢失信号时调用
  - 没有carrier=on，协议栈并不会处理报文.
	- tcpdump -i veth0后，只能看到报文进入内核，而不会看到报文出内核.

### f-stack的多线程支持
- f-stack使用的是多进程，单线程模型.
  - 由于f-stack使用全局变量curthread(主线程)，因此无法支持单进程，多线程模式.
	- 如若curthread使用出现错误，那么应用程序将会崩溃.
	- 如若lock出现错误，也可能是应用程序崩溃.
  - 在nginx中，work-process会创建一个worker-thread, worker-thread使用和进程同样的cpu.
	- worker-thread的curthread会赋值为主线程, 因为主线程是处于挂起状态.

### f-stack nginx的实现
- f-stack nginx 支持reload操作. 
- [参考文档](https://cloud.tencent.com/developer/article/1005218)

### f-stack文件集
- ff_config.c
  - 解析config.ini配置.
- ff_compat.c
  - 主要是为兼容性所写的文件.
- ff_dpdk_if.c
  - 接口收发报文.
  - 物理接口启动.
  - 接口连接状态等等.
- ff_kni.c
  - kni接口相关操作.
  - 设置kni的bitmap等.
- ff_dpdk_pcap.c
  - 抓包.
- ff_epoll.c
  - 支持epoll接口.
- ff_freebsd_init.c
  - 初始化freebsd.
- ff_glue.c
  - 都是一些比较基础的函数。
  - 感觉类似于ff_compat.
- ff_host_interface.c
  - 封装系统调用, 如malloc等.
- ff_ini_parser.c
  - 读取ini文件的配置文件.
- ff_init.
  - 只有两个函数. 
    - ff_init
    - ff_run
- ff_init_main.c
  - 貌似是初始化当前进程变量等等.
- ff_kern_timeout.c
  - 处理时间相关.
- ff_ng_base.c
  - netgraph
  - 类似于vpp的graph node.
- ff_veth.c
  - 配置freebsd的veth接口
- lib/ff_syscall_wrapper.c
  - 某些内核调用，例如，添加默认路由等等.

### 工具集的使用

### 其他
- dpdk thread 
  - linux下其实也是通过pthread_create出来的，只不过，在pthread上再封装了一层.
  - slave thread 和 master thread通过pipe进行通信.
  - slave thread 在rte_eal_init 函数里创建并初始化.
	- 设置thread-affinity
    - 进入死循环，并等待master thread设置处理函数


