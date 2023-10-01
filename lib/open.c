/*
 *  linux/lib/open.c
 *
 *  (C) 1991  Linus Torvalds
 *   文件打开函数
 */

// open 系统调用用于将一个文件名称转换成一个文件描述符.当调用成功时,返回的文件描述符将是进程没有打开的最小数值的描述符.
// 该调用创建一个新的打开文件,并不与任何其它进程共享. 在执行 exec 函数时, 该新的文件描述符将始终保持着打开状态.
// 文件的读写指针被设置在文件开始位置.
#define __LIBRARY__
#include <unistd.h>  // Linux标准头文件,定义各种符号常数和类型,并申明了各种函数.如定义了__LIBRARY__,则还含系统调用号和内嵌汇编_syscall0()等.
#include <stdarg.h>  // 标准参数头文件.以宏的形式定义变量参数泪飙. 主要说明了一个类型 va_list 和三个宏 va_start, va_arg 和 va_end,用于 vsprintf,vprintf,vfprintf函数


// 打开文件
// 打开并有可能创建一个文件
// 参数: filename - 文件名; flag - 文件打开标志; ....
// 返回: 文件描述, 若出错则置出错码,并返回-1.
int open(const char * filename, int flag, ...)
{

	// 这段代码是使用汇编语言内嵌汇编在C程序中调用Linux内核的系统调用 open 来打开一个文件。以下是对这段代码的详细解释：
	// register int res; ：这一行定义了一个整数类型的寄存器变量 res，用于存储系统调用的结果或错误码。
	// va_list arg; ：这一行定义了一个 va_list 类型的变量 arg，它用于处理可变数量的参数（variadic arguments）。
	// va_start(arg, flag); ：这一行使用 va_start 宏来初始化 arg，以便后续能够访问变长参数列表。flag 是作为参数传递给 va_start 的最后一个已知参数，
	// 它用于确定可变参数列表的位置。
	// __asm__("int $0x80" ...)：这一部分是内嵌汇编代码，用于调用系统中断 int 0x80 来执行系统调用。
	// "=a" (res)：这是一个输出操作数约束（output operand constraint），它指示编译器将系统调用的返回值放入 res 变量中。
	// "0" (__NR_open), "b" (filename), "c" (flag), "d" (va_arg(arg, int))：这些是输入操作数约束（input operand constraints），
	// 它们指示编译器将相应的值传递给系统调用。具体约束如下：
	// "0" (__NR_open) : 使用 0 约束将系统调用号 __NR_open 放入 EAX 寄存器，表示要执行 open 系统调用。
	// "b" (filename) : 使用 b 约束将文件名 filename 放入 EBX 寄存器，表示要打开的文件名。
	// "c" (flag) : 使用 c 约束将标志 flag 放入 ECX 寄存器，表示文件打开标志。
	// "d" (va_arg(arg, int)) : 使用 d 约束将可变参数中的一个整数参数放入 EDX 寄存器，这个参数通常是文件属性（mode）。
	// 这段代码的核心是使用汇编内嵌代码来执行 int 0x80 中断，将参数传递给系统调用，并将结果存储在 res 变量中。
	// 具体的系统调用参数（例如文件名、标志和属性）由宏定义或可变参数传递给这段代码，以便根据需要执行不同的文件打开操作。
	// 在执行完系统调用后，res 变量将包含 open 系统调用的返回值（文件描述符或错误码）。这种技术通常用于直接访问Linux内核的系统调用，
	// 通常在底层系统编程或内核模块开发中使用。


	register int res;
	va_list arg;

	// 利用 va_start() 宏函数,取得flag后面参数的指针,然后调用系统中断 int 0x80, 功能 open进行文件打开操作
	// %0 - eax(返回的描述符或出错码); %1 - eax(系统中断调用功能号__NR_open)
	// %2 - ebx(文件名 filename); %3 - ecx(打开文件标志flag); %4 - edx(后随参数文件属性mode)
	va_start(arg,flag);
	__asm__("int $0x80"
		:"=a" (res)
		:"0" (__NR_open),"b" (filename),"c" (flag),
		"d" (va_arg(arg,int)));

	// 系统中断调用返回值大于或等于0,表示时一个文件描述符,则直接返回之.
	if (res>=0)
		return res;
	// 说明返回值小于0,则代表一个出错码.设置该出错码并返回-1
	errno = -res;
	return -1;
}
