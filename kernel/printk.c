/*
 *  linux/kernel/printk.c
 *
 *  (C) 1991  Linus Torvalds
 * 通用程序
 * 内核专用的信息显示函数
 */

/*
 * When in kernel-mode, we cannot use printf, as fs is liable to
 * point to 'interesting' things. Make a printf with fs-saving, and
 * all is well.
 */
/* 
 * printk()是内核中使用的打印(显示)函数,功能与C标准函数库中的print()相同.重新编写这么一个函数 
 * 的原因是在内核中不能使用专用于用户模式的 fs 段寄存器, 需要首先保存它. printk()函数首先使用 
 * svprintf() 对参数进行格式化处理, 然后在保存了 fs 段寄存器的情况下 调用 tty_write进行信息打印显示
 */

/* 
 * 当处于内核模式时, 我们不能使用 printf,因为寄存器fs指向其它不感兴趣的地方.
 * 自己编制一个 printf并在使用前保存fs,一切就解决了.
 */
#include <stdarg.h>   //标准参数头文件.以宏的形式定义变量参数列表. 主要说明了一个类型(va_list)和三个宏(va_start,va_arg和va_end),
                      // 用于vsprintf,vprintf,vfprintf函数
#include <stddef.h>   // 表混定义头文件. 定义了 NULL, offsetof(TYPE,MEMBER)

#include <linux/kernel.h>  // 内核头文件. 含有一些内核常用函数的原形定义

static char buf[1024];

// 下面该函数 vsprintf() 在 linux/kernel/vsprintf.c中
extern int vsprintf(char * buf, const char * fmt, va_list args);

// 内核使用的显示函数
int printk(const char *fmt, ...)
{
	va_list args;                  // va_list 是一个用于访问可变参数列表的工具.它通常是一个指向参数的字符指针类型
	int i;

	va_start(args, fmt);           // 使用va_start宏来初始化va_list变化args,以便后续可访问可变参数列表.fmt是可变参数列表的前一个已知参数,
								   // 它用于确定参数列表的起始位置
	i=vsprintf(buf,fmt,args);      // 使用格式串fmt将参数列表args输出到buf中.
								   // 返回值 i 等于输出字符串的长度
	va_end(args);                  // 使用宏va_end来清理va_list变量args,以释放与可变参数列表相关的资源.通常是在使用完可变参数列表后的必要操作,
								   // 以保证资源正确释放
	__asm__("push %%fs\n\t"        // 保存 fs
		"push %%ds\n\t"
		"pop %%fs\n\t"             // 令 fs = ds
		"pushl %0\n\t"             // 将字符串长度压入堆栈(这个三个入栈是调用参数)
		"pushl $_buf\n\t"          // 将 buf 的地址压入堆栈
		"pushl $0\n\t"             // 将数值 0 压入堆栈, 是通道号channel
		"call _tty_write\n\t"      // 调用 tty_write 函数
		"addl $8,%%esp\n\t"        // 跳过(丢弃)两个入栈参数(buf,channel)
		"popl %0\n\t"              // 弹出字符串长度值,作为返回值
		"pop %%fs"                 // 恢复原fs寄存器
		::"r" (i):"ax","cx","dx"); // 通知编译器, 寄存器ax,cx,dx值可能已经改变
	return i;                      // 返回字符串长度
}
