/*
 *  linux/init/main.c
 *
 *  (C) 1991  Linus Torvalds
 * 
 * 用于执行内核初始化工作,然后移动到用户模式创建新进程,并在控制台设备上运行shell程序.
 * 程序首先根据内存的多少对缓冲区内存容量进行分配,如果还设置了要使用虚拟盘,则在缓冲区
 * 内存后面也为它留下空间.之后就进行所有硬件的初始化工作,包括人工创建第一个任务(task0),
 * 并设置了中断允许标志.在执行从核心态到用户态之后,系统第一次调用创建进程函数fork(),创建
 * 出一个用于运行init()的进程,在该子进程中,系统将进行控制台环境设置,并且在生成一个子进程用来运行shell程序.
 */

/* Linux系统调用和调用库函数是两种不同的方式，用于与操作系统内核进行交互和执行各种操作。它们之间的主要区别在于调用的层次和执行方式：
 * 系统调用（System Calls）：
 * 层次：系统调用位于操作系统内核和用户空间程序之间，属于操作系统的一部分。它们提供了一种用户程序与操作系统内核进行通信和请求服务的标准接口。
 * 权限：系统调用通常具有更高的权限级别，因此可以执行特权操作，例如文件系统访问、进程管理、网络通信等。用户程序通过系统调用接口请求内核来执行这些操作。
 * 性能开销：由于涉及从用户空间切换到内核空间的上下文切换，系统调用通常具有较高的性能开销。因此，它们通常用于执行需要操作系统的核心功能的任务。
 * 示例：一些常见的系统调用包括 open、read、write、fork、exec、kill 等。这些调用直接与操作系统内核进行通信，执行文件操作、进程管理、信号处理等操作。
 * 调用库函数（Calling Library Functions）：
 * 层次：库函数是在用户空间的程序库中实现的函数，它们提供了一组封装好的功能和服务，通常构建在系统调用之上。这些函数以高级抽象的方式提供了对系统功能的访问。
 * 权限：库函数通常在用户空间中运行，其权限受限于用户程序的权限。它们无法执行特权操作，但可以通过调用系统调用来委托操作系统来执行这些操作。
 * 性能开销：由于库函数通常在用户空间运行，它们的性能开销较低，因为不需要进行用户空间和内核空间之间的上下文切换。
 * 示例：标准C库（如 glibc）包含了许多常用的库函数，例如 printf、malloc、strlen、strcpy 等。这些函数封装了底层的系统调用，提供了更高级别的接口。
 * 总之，系统调用和调用库函数之间的主要不同在于其层次、权限和性能开销。系统调用是用户程序直接与操作系统内核交互的底层接口，提供了对系统资源和功能的直接访问。
 * 而调用库函数是在用户空间中实现的高级抽象接口，它们通常构建在系统调用之上，提供了更便捷和易用的功能。通常，开发人员会首选使用库函数，除非需要执行特权操作或直接
 * 与内核进行交互时才会使用系统调用。
 */


/*
 * #define __LIBRARY__ 和 #include <unistd.h> 一起出现时，通常表示正在为使用Linux内核系统调用的目的编写代码。这种编写代码的方式常见于Linux下的系统编程或内核模块
 * 开发。让我们分别解释这两行代码的含义：
 * #define __LIBRARY__：
 * 这是一个预处理宏定义指令，将标识符 __LIBRARY__ 设置为一个特定的值，通常为 1 或者没有设置具体的值。
 * 这个宏定义通常被用来告诉编译器，代码将使用系统调用而不是C库函数来执行操作。
 * 当 __LIBRARY__ 被定义为非零值时，通常表示代码将直接调用Linux内核提供的系统调用，而不使用标准C库函数。这种方法可以在编写操作系统级代码或内核模块时非常有用。
 * #include <unistd.h>：
 * 这是一个包含头文件的预处理指令，它将系统头文件 <unistd.h> 包含到您的源代码中。
 * <unistd.h> 头文件包含了与 POSIX 标准兼容的函数和符号，通常用于系统级编程。这些函数包括 read、write、fork、exec 等，它们用于与操作系统进行交互，执行系统调用。
 * 当您编写系统级代码时，通常需要包含这样的头文件以访问系统调用的声明和常量。
 * 综合起来，这两行代码的组合表明您正在编写一个直接与Linux内核交互的程序，它将使用系统调用而不是标准C库函数来执行操作。这种方式常见于系统编程、
 * 内核开发或需要更底层控制的应用程序中。在这种上下文中，__LIBRARY__ 宏定义可能会触发一些特殊的编译行为或条件编译指令，以确保代码正确地使用系统调用。
 */

#define __LIBRARY__        // 定义该变量时为了包括定义在 unistd.h 中的内嵌汇编代码等信息
#include <unistd.h>        // *.h 头文件所在的默认目录是 include/,则在代码中就不用明确指明位置. 如果不是unix的标准头文件,则需要指明所在的目录,并用双括号括住.
						   // 标准符号常数与类型文件.定义了各种符号常数和类型,并申明了各种函数.如果定义了 __LIBRARY__,则还含系统调用号和内嵌汇编代码syscall0()等.
#include <time.h>          // 时间类型头文件.其中最主要定义了 tm 结构和一些有关时间的函数原形.

/*
 * we need this inline - forking from kernel space will result
 * in NO COPY ON WRITE (!!!), until an execve is executed. This
 * is no problem, but for the stack. This is handled by not letting
 * main() use the stack at all after fork(). Thus, no function
 * calls - which means inline code for fork too, as otherwise we
 * would use the stack upon exit from 'fork()'.
 *
 * Actually only pause and fork are needed inline, so that there
 * won't be any messing with the stack from main(), but we define
 * some others too.
 */

/* 我们需要下面这些内嵌语句 - 从内核空间创建进程(forking)将导致没有写时赋值(Copy on write!)
 * 直到执行一个 execve 调用.这对堆栈可能带来问题. 处理的方法时在 fork()调用之后不让 main()使用 
 * 任何堆栈. 因此就不能有函数调用 - 这意味这 fork 也要使用内嵌的代码, 否则我们就从fork() 退出时就要使用堆栈了. 
 * 实际上只有 pause 和 fork 需要使用内嵌方式,以保证从 main() 中不会弄乱堆栈,但是我们同时还定义了其它一些参数
 */

// 本程序将会在移动到用户模式(切换到任务0)后才执行fork(),因此避免了在内核空间写时复制问题.
// 在执行了 move_to_user_mode()之后,本程序就以任务0的身份在运行了.而任务0是所有创建的子进程的父进程. 当创建第一个子进程时,任务0的堆栈也会被复制.因此希望在main.c
// 运行在任务0的环境下时不要有对堆栈的任何操作,以免弄乱堆栈,从而也不会弄乱所有子进程的堆栈.

// 这是 unistd.h中的内嵌宏代码.以内嵌汇编的形式调用 Linux 的系统调用中断 0x80.该中断是所有系统调用的入口.这条语句实际上是
// int fork() 创建进程的系统调用.
// syscall0 名称中的0表示无参数,1表示有一个参数

// static inline：
// static：这个关键字用于限制符号的作用域，将其限制在当前编译单元（通常是一个源文件）中，使得它不会在链接时与其他编译单元冲突。
// inline：这个关键字建议编译器将函数内联展开，而不是生成函数调用。这可以提高代码执行的效率，因为不需要进行函数调用的开销。
// (int, fork) 这部分指定了系统调用的返回类型和名称。在这里，系统调用的返回类型被指定为 int，并且系统调用的名称是 fork。
static inline _syscall0(int, fork)
static inline _syscall0(int, pause)                 // int pause() 系统调用, 暂停进程的执行,直到收到一个信号
static inline _syscall1(int, setup, void*, BIOS)    // int setup(void * BIOS) 系统调用,仅用于 linux 初始化(仅在这个程序中被调用)
static inline _syscall0(int, sync)                  // int sync() 系统调用: 更新文件系统

// #include <linux/tty.h> 是一个预处理指令，用于包含名为 tty.h 的Linux内核头文件。这个头文件通常用于 Linux 内核开发或与终端设备（tty）相关的系统级编程。
// 让我们来解释一下这个头文件可能包含的内容和其作用：
// 内核数据结构和宏：tty.h 可能包含了用于表示终端设备的内核数据结构和相关的宏。这些数据结构和宏可以用于与终端设备进行交互、管理和控制。
// 函数原型：这个头文件可能包含了与终端设备操作相关的函数原型。这些函数可以用于打开、关闭、读取、写入终端设备等操作。
// 常量和符号定义：tty.h 可能包含了一些常量和符号定义，用于表示终端设备的特性、状态或配置选项。这些常量和符号可以用于设置终端设备的属性或进行状态检查。
// 其他与终端设备相关的信息：此外，头文件可能还包含其他与终端设备相关的信息，例如终端设备的类型、名称、文件描述符等。
// 具体的内容和作用可能因 Linux 内核版本和具体用途而异。通常，<linux / tty.h> 头文件用于编写需要与终端设备进行交互的系统级程序，例如终端仿真器、终端控制程序、
// 终端驱动程序等。如果您需要详细了解头文件的内容和用法，建议查看 Linux 内核源代码中的相关文档或注释。
#include <linux/tty.h>   // tty头文件,定义了有关tty_io,串行通信方法的参数,常数.

// 调度程序头文件,定义了任务结构 task_struct,第一个初始任务的数据.还有一些以宏的形式定义的有关描述符参数设置和获取的嵌入式汇编函数程序.
#include <linux/sched.h>  
#include <linux/head.h>   // head头文件,定义了段描述符的简单结构,和几个选择符常量
#include <asm/system.h>   // 系统头文件,以宏的形式定义了许多有关设置或修改描述符/中断门等的嵌入式汇编子程序
#include <asm/io.h>       // io头文件,以宏的嵌入汇编程序形式定义对io端口操作的函数

#include <stddef.h>       // 标准定义头文件,定义了 NULL, offsetof(TYPE, MEMBER)
#include <stdarg.h>       // 标准参数头文件.以宏的形式定义变量参数列表.主要说明了一个类型(va_list)和三个宏(va_start,va_arg和va_end),vsprintf,vprinf,vfprintf
#include <unistd.h>        
#include <fcntl.h>        // 文件控制头文件.用于文件及其描述符的操作控制常数符号的定义.
#include <sys/types.h>    // 类型头文件.定义了基本的系统数据类型.

#include <linux/fs.h>     // 文件系统头文件.定义文件表结构(file,buffer_head,m_inode等)

static char printbuf[1024];  // 静态字符串数组,用作内核显示信息的缓存

extern int vsprintf();       // 送格式化输出到一字符串中
extern void init(void);      // 函数原形,初始化
extern void blk_dev_init(void);  // 块设备初始化子程序
extern void chr_dev_init(void);  // 字符设备初始化
extern void hd_init(void);       // 硬盘初始化程序
extern void floppy_init(void);   // 软驱初始化程序
extern void mem_init(long start, long end);      // 内存初始化
extern long rd_init(long mem_start, int length); // 虚拟盘初始化
extern long kernel_mktime(struct tm * tm);       // 计算系统开机启动时间
extern long startup_time;                        // 内核启动时间

/*
 * This is set up by the setup-routine at boot-time
 */

// 以下这些数据是由 setup.s 程序在引导实际设置的
#define EXT_MEM_K (*(unsigned short *)0x90002)           // 1M以后的扩展内存大小(KB)
#define DRIVE_INFO (*(struct drive_info *)0x90080)       // 硬盘参数表地址
#define ORIG_ROOT_DEV (*(unsigned short *)0x901FC)       // 跟文件系统所在设备号

/*
 * Yeah, yeah, it's ugly, but I cannot find how to do this correctly
 * and this seems to work. I anybody has more info on the real-time
 * clock I'd be interested. Most of this was trial and error, and some
 * bios-listing reading. Urghh.
 */

// 是啊,是啊,下面这段程序很差劲,但是我不知道如何正确地实现,而且好像它还能运行.如果有
// 关于实时时钟更多的资料,那我很感兴趣.这些都是试探出来的,以及看了一些bios程序,呵!

#define CMOS_READ(addr) ({ \         // 这段宏读取 CMOS 实时时钟信息
outb_p(0x80|addr,0x70); \            // 0x70 是写端口号, 0x80|addr 是要读取的 CMOS 内存地址
inb_p(0x71); \                       // 0x71 是读端口号
})
// 宏定义. 将 BCD码转换成二进制数值
#define BCD_TO_BIN(val) ((val)=((val)&15) + ((val)>>4)*10)

// 该子程序读取 COMS 时钟,并设置开机时间->startup_time(秒).参见后面CMOS内存列表
static void time_init(void)
{
	struct tm time;      // 时间结构 tm 定义在 include/time.h 中

	// CMOS 的访问速度很慢. 为了减小时间误差,在读取了下面循环中所有的数值后,若此时CMOS中秒值
	// 发生了变化,那么就重新读取所有值.这样内核就能把与CMOS的时间误差控制在1秒之内.
	do {
		time.tm_sec = CMOS_READ(0);       // 当前时间秒值(均是BCD码值)
		time.tm_min = CMOS_READ(2);       // 当前分钟值
		time.tm_hour = CMOS_READ(4);      // 当前小时值
		time.tm_mday = CMOS_READ(7);      // 一月中的当天日期
		time.tm_mon = CMOS_READ(8);       // 当前月份(1-12)
		time.tm_year = CMOS_READ(9);      // 当前年份
	} while (time.tm_sec != CMOS_READ(0));// 比较是否是在一秒内读取到的所有值
	BCD_TO_BIN(time.tm_sec);              // 转换成二进制数值
	BCD_TO_BIN(time.tm_min);
	BCD_TO_BIN(time.tm_hour);
	BCD_TO_BIN(time.tm_mday);
	BCD_TO_BIN(time.tm_mon);
	BCD_TO_BIN(time.tm_year);
	time.tm_mon--;                         // tm_mon 中月份范围是 0-11
	// 调用 kernel/mktime.c 中函数,计算从1970-01-01 0:0:0 起到开机当日经过的秒数,用作开机时间
	startup_time = kernel_mktime(&time);
}
// | 内核程序 | 高速缓冲 | 虚拟盘 | 主内存区 |
static long memory_end = 0;            // 机器具有的物理内存容量(字节数)
static long buffer_memory_end = 0;     // 高速缓冲区末端地址
static long main_memory_start = 0;     // 主内存(将用于分页)开始的位置

struct drive_info { char dummy[32]; } drive_info;   // 用于存放硬盘参数表信息

void main(void)		/* This really IS void, no error here. */
{			/* The startup routine assumes (well, ...) this */
			// 这里确实是 void,并没有错.在startup程序head.s中就是这样假设的,参见head.s的136行.
/*
 * Interrupts are still disabled. Do necessary setups, then
 * enable them
 */
/*  
 * 此时中断仍被禁止着, 做完必要的设置后就将其开启
 */
	// 下面这段代码用于保存:
	// 根设备号 -> ROOT_DEV;     高速缓冲末端地址 -> buffer_memory_end;
	// 机器内存数 -> memory_end; 主内存开始地址   -> main_memory_start;
 	ROOT_DEV = ORIG_ROOT_DEV;                // ROOT_DEV 定义在 fs/super.c 29行
 	drive_info = DRIVE_INFO;                 // 复制0x90080 处的硬盘参数表

	// 这个宏定义创建了一个宏 EXT_MEM_K。
	// * (unsigned short*)0x90002 表示从内存地址 0x90002 处读取一个无符号短整数（16位的整数），然后通过宏定义将其命名为 EXT_MEM_K。
	// 这个宏的作用是将地址 0x90002 处的数据解释为一个 unsigned short 类型的值，并将其赋值给 EXT_MEM_K。
	// 这条语句计算了一个变量 memory_end 的值。
	// (1 << 20) 表示将 1 左移 20 位，即将 1 左移 20 位得到 1048576，这是 1MB 的大小。
	// (EXT_MEM_K << 10) 表示将 EXT_MEM_K 左移 10 位。根据宏定义，EXT_MEM_K 是从内存地址 0x90002 读取的一个值。这里将其左移 10 位，相当于将其乘以 1024
	// （因为 1KB = 1024字节）。
	// 所以，memory_end 的值将等于 1MB（1048576字节）加上 EXT_MEM_K 的值乘以 1024字节。
	// 总之，这段代码的目的是计算 memory_end 的值，其中 EXT_MEM_K 是从内存地址 0x90002 读取的一个16位值，表示扩展内存的大小。将扩展内存的大小乘以 1024 字节后，
	// 与 1MB 相加，得到了 memory_end 的最终值，通常用于配置系统内存的参数。
	memory_end = (1<<20) + (EXT_MEM_K<<10);  // 内存大小 1 MB 字节 + 扩展内存(k)*1024字节
	memory_end &= 0xfffff000;                // 忽略不到 4Kb(1页)的内存数
	if (memory_end > 16*1024*1024)           // 如果内存超过 16Mb,则按16Mb计算
		memory_end = 16*1024*1024;           
	if (memory_end > 12*1024*1024)           // 如果内存大于 12Mb,则设置缓冲区末端4Mb
		buffer_memory_end = 4*1024*1024;
	else if (memory_end > 6*1024*1024)       // 如果内存大于 6Mb,则设置缓冲区末端 2Mb
		buffer_memory_end = 2*1024*1024;
	else                                     // 设置缓冲区末端 1Mb
		buffer_memory_end = 1*1024*1024;
	main_memory_start = buffer_memory_end;

// 如果定义了内存虚拟盘,则初始化虚拟盘.此时主内存将减少. 参见kernel/blk_drv/ramdisk.c
#ifdef RAMDISK
	main_memory_start += rd_init(main_memory_start, RAMDISK*1024);
#endif
// 以下是内核进行所有方面的初始化工作.阅读时最好跟着调用的程序深入看下去,若实在看不下去,就先放一放,
// 继续看下一个初始化调用.	
	mem_init(main_memory_start,memory_end);
	trap_init();     // 陷阱门(硬件中断向量)初始化
	blk_dev_init();  // 块设备初始化
	chr_dev_init();  // 字符设备初始化
	tty_init();      // tty 初始化
	time_init();     // 设置开机启动时间 -> startup_time
	sched_init();    // 调度程序初始化(加载了任务0的tr,ldtr)
	buffer_init(buffer_memory_end);  // 缓冲管理初始化,见内存链表等.
	hd_init();       // 硬盘初始化
	floppy_init();   // 软驱初始化
	sti();           // 所有初始化工作完成,开启中断
	// 下面过程通过在堆栈中设置的参数,利用中断返回指令启动任务0执行.
	move_to_user_mode();    // 移到用户模式下执行.
	if (!fork()) {		/* we count on this going ok */
		init();      // 在新建的子进程(任务1)中执行
	}
/*
 *   NOTE!!   For any other task 'pause()' would mean we have to get a
 * signal to awaken, but task0 is the sole exception (see 'schedule()')
 * as task 0 gets activated at every idle moment (when no other tasks
 * can run). For task0 'pause()' just means we go check if some other
 * task can run, and if not we return here.
 */
	// 下面代码开始以任务0的身份运行.
/*
 * 注意!! 对于任何其它的任务,'pause()'将意味我们必须等待收到一个信号才会返回就绪状态,但任务0(task0)时唯一的例外情况(参见schedule()),因为
 * 任务0在任何空闲时间都会被激活(当没有其它任务在运行时),因此对于任务0,'pause()'仅意味这我们返回来查看是否还有其它任务可以运行,如果没有的话我们就回到这里
 * 一直循环执行'pause()'.
 */
	// pause() 系统调用(kernel/sched.c,144)会把任务0转换成可中断等待状态,再执行调度函数.但是调度函数只要发现系统中没有其它任务可以运行时就会切换段任务0,
	// 而不依赖于任务0的状态
	for(;;) pause();
}

// 产生格式化信息并输出到标准输出设备stdout(1),这里时指屏幕上显示.参数'*fmt'指定输出将采用的格式,参见各种标准C语言书籍.该子程序正好时vsprintf如何使用的一个例子
// 该程序使用vsprintf()将格式化的字符串放入printbuf缓冲区,然后用write()将缓冲区的内容输出到标准设备(1-stdout).vsprintf()函数的实现见kernel/vsprintf.c
static int printf(const char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	write(1,printbuf,i=vsprintf(printbuf, fmt, args));
	va_end(args);
	return i;
}

static char * argv_rc[] = { "/bin/sh", NULL };    // 调用执行程序时参数的字符串数组
static char * envp_rc[] = { "HOME=/", NULL };     // 调用执行程序时的环境字符串数组

static char * argv[] = { "-/bin/sh",NULL };      // argv[0]中的字符'-'是传递给shell程序sh的一个标志.通过识别该标志,sh 程序会作为登录 shell执行.其执行过程与再shell提示符下执行 sh 不太一样
static char * envp[] = { "HOME=/usr/root", NULL };

// 在 main()中已经进行了系统初始化,包括内存管理,各种硬件设备和驱动程序.init()函数运行在 任务0第一次创建的子进程(任务1)中.
// 它首先对第一个将要执行的程序(shell)的环境进行初始化,然后加载该程序并执行之.
void init(void)
{
	int pid,i;
	// 这是一个系统调用.用于读取硬盘参数包括分区表信息并加载虚拟盘(若存在的话)和安装根文件系统设备.该函数是用25行上的宏定义的,对于函数是
	// sys_setup(),在kernel/blk_drv/hd.c 71行
	setup((void *) &drive_info);
	// 下面以读写访问方式打开设备 "/dev/tty0",它对应终端控制台.
	// 由于这是第一次打开文件操作,因此产生的文件句柄号(文件描述符)肯定是0.该句柄是unix类操作系统默认的控制台标准输入句柄stdin. 这里把它以读和写的方式打开是
	// 为了复制产生标准输出(写)句柄stdout和标准错误聚标stderr.
	(void) open("/dev/tty0",O_RDWR,0);
	(void) dup(0);              // 复制句柄,产生句柄1号 -- stdout 标准输出设备
	(void) dup(0);              // 复制句柄,产生句柄2号 -- stderr 标准错误输出设备

	// 下面打印缓冲区块数和总字节数,每块1024字节,
    // 以及主内存区空闲内存字节数.
	printf("%d buffers = %d bytes buffer space\n\r",NR_BUFFERS,
		NR_BUFFERS*BLOCK_SIZE);
	printf("Free mem: %d bytes\n\r",memory_end-main_memory_start);

	// 下面 fork() 用于创建一个子进程(任务2).对于被创建的子进程,fork()将返回0值.对于原进程(父进程)则返回子进程的进程号pid.
	// 所以下面的if语句内的内容,是子进程执行的内容.该子进程关闭了句柄0,以只读方式打开 /etc/rc 文件,并使用execve()函数将进程
	// 自身替换成 /bin/sh 程序(即shell程序),然后执行/bin/sh程序. 所带参数和环境变量分别有 argv_rc和envp_rc数组给出.关于execve()
	// 请参见 fs/exec.c程序, 182行.
	// 函数_exit()退出是的出错码1-操作未许可; 2--文件或目录不存在.
	if (!(pid=fork())) {
		close(0);
		if (open("/etc/rc",O_RDONLY,0))
			_exit(1);
		execve("/bin/sh",argv_rc,envp_rc);
		_exit(2);
	}

	// 下面还是父进程(1)执行的语句. wait()等待子进程停止或终止,返回值应是子进程的进程号pid.
	// 这三句的作用是父进程等待子进程的结束. &i 是存放返回状态信息的位置.如果wait()返回值不等于子进程号,则继续等待.
	if (pid>0)
		while (pid != wait(&i))
			/* nothing */;

	// 如果执行到这里,说明杠创建的子进程的执行已停止或终止了.下面循环中首先在创建一个子进程.如果出错,则显示"初始化程序创建子进程失败"信息并继续执行.对于
	// 所创建的子进程将关闭所有以前还遗留的句柄(stdin,stdout,stderr),新床一个会话并设置进程组号,然后重新打开 /dev/tty0 作为 stdin,并复制成stdout和stderr.
	// 再次执行系统解释程序/bin/sh.但这次执行所选用的参数和环境数组另选了一套. 然后父进程再次运行 wait()等待.如果子进程有停止了执行.则在标准输出上显示
	// 出错信息"子进程pid停止了运行,返回码是i",然后继续重试下去,形成"大"死循环
	while (1) {
		if ((pid=fork())<0) {
			printf("Fork failed in init\r\n");
			continue;
		}
		if (!pid) {                               // 新的子进程
			close(0);close(1);close(2);
			setsid();                             // 创建一新的会话期,见后面说明.
			(void) open("/dev/tty0",O_RDWR,0);
			(void) dup(0);
			(void) dup(0);
			_exit(execve("/bin/sh",argv,envp));
		}
		while (1)
			if (pid == wait(&i))
				break;
		printf("\n\rchild %d died with code %04x\n\r",pid,i);
		sync();
	}
	_exit(0);	/* NOTE! _exit, not exit() */

	// 注意! 是_exit(),不是exit(). 
	// _exit()和exit()都是用于正常终止一个函数. 但是_exit()直接是一个sys_exit系统调用, 而exit()则
	// 通常是普通库函数中的一个函数.它会先执行一些清除操作,例如调用执行各终止处理程序,关闭所有标准IO等,然后调用sys_exit.
}
