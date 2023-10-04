/*
 *  linux/kernel/traps.c
 *
 *  (C) 1991  Linus Torvalds
 * 硬件中断程序
 * 各硬件异常的实际处理程序,这里的函数会被 asm.s中的中断调用
 */

/*
 * 'Traps.c' handles hardware traps and faults after we have saved some
 * state in 'asm.s'. Currently mostly a debugging-aid, will be extended
 * to mainly kill the offending process (probably by giving it a signal,
 * but possibly by killing it outright if necessary).
 */
/* 
 * 在程序 asm.s中保存了一些状态后,本程序用来处理硬件陷阱和故障.目前主要用于调试目的,
 * 以后将扩展用来杀死遭损坏的进程(主要时通过发送一个信号,但如果必要也会直接杀死)
 */
#include <string.h>       // 字符串 头文件. 主要定义了一些有关字符串操作的嵌入函数.

#include <linux/head.h>   // head 头文件, 定义了段描述符的简单结构,和几个选择符常量
#include <linux/sched.h>  // 调度程序头文件,定义了任务结构task_struct,初始任务0的数据,
                          // 还有一些有关描述符参数设置和获取的嵌入式汇编函数宏语句
#include <linux/kernel.h> // 内核头文件,含有一些内置常用函数的原形定义.
#include <asm/system.h>   // 系统头文件.定义了设置或修改描述符/中断门的嵌入式汇编宏.
#include <asm/segment.h>  // 段操作头文件.定义了有关段寄存器操作的嵌入式汇编函数.
#include <asm/io.h>       // 输入/输出头文件.定义硬件端口输入/输出宏汇编语句.

// 以下语句定义了三个嵌入式汇编宏语句函数. 有关嵌入式汇编的基本语法见列表后或参见附录.
// 取段 seg 中的地址 addr 处的一个字节.
// 用圆括号括住的组合语句(花括号中的语句)可以作为表达式使用,其中最后的__res是输出置

// 这段代码是一段宏定义，看起来是用于汇编嵌入（inline assembly）的目的，它的主要作用是从指定的内存地址中读取一个字节，并返回该字节的值。
// 让我解释一下这段代码的各个部分：
// #define get_seg_byte(seg, addr)：这是一个宏定义，定义了一个名为 get_seg_byte 的宏，它接受两个参数 seg 和 addr。
// register char __res; ：这里声明了一个寄存器变量 __res，用于存储读取的字节值。
// __asm__()：这是内联汇编的语法，允许在C或C++代码中嵌入汇编指令。
// "push %%fs;mov %%ax,%%fs;movb %%fs:%2,%%al;pop %%fs"：这是内联汇编的汇编指令部分。它执行以下操作：
// push % %fs：将段寄存器 fs 的当前值压入栈。
// mov % %ax, %% fs：将16位通用寄存器 ax 的值加载到段寄存器 fs 中，这是为了设置一个新的段寄存器值，通常是用于指定数据段。
// movb%% fs: % 2, %% al：从内存地址 % 2 处读取一个字节（8位）的数据，存储到通用寄存器 al 中。 % 2 是在宏参数中传递的 addr 参数。
// pop % %fs：将之前压入栈的 fs 寄存器的值弹出，恢复原始状态。
// : "=a" (__res) : "0" (seg), "m" (*(addr))：这是内联汇编的操作数部分，指定了输入和输出操作数以及使用的寄存器约束。具体含义如下：
//	"=a" (__res)：将通用寄存器 al 的值作为输出操作数，并将结果存储到变量 __res 中。
//	"0" (seg)：将输入参数 seg 的值放置在通用寄存器 ax 中。
//	"m" (*(addr))：表示要读取的内存地址是 addr，使用间接寻址方式。
//	__res; ：最后，宏返回变量 __res 的值，这是从内存中读取的字节值。
//	综合起来，这个宏定义的作用是从指定的内存地址中读取一个字节，并将其返回。在执行之前，它使用内联汇编来设置段寄存器 fs 的值，以便指定数据段，
// 然后从该段中读取一个字节的数据，最后将段寄存器 fs 恢复到原始状态。这个宏允许在C或C++代码中方便地执行这种操作，而不必编写完整的汇编代码。
/*
限定字符		描述							限定字符	描述
a				使用寄存器eax					m			使用内存地址
b				使用寄存器ebx					o			使用内存地址并可以加偏移值
m、o、V、p		使用寄存器ecx					I			使用常数0~31 立即数
g、X			寄存器或内存					J			使用常数0~63 立即数
I、J、N、i、n	立即数							K			使用常数0~255立即数
D				使用edi							L			使用常数0~65535 立即数
q				使用动态分配字节
				可寻址寄存器
				（eax、ebx、ecx或edx）			M			使用常数0~3 立即数
r				使用任意动态分配的寄存器		N			使用1字节常数（0~255）立即数
g				使用通用有效的地址即可
			   （eax、ebx、ecx、edx或内存变量）	O			使用常数0~31 立即数
A				使用eax与edx联合（64位）		i			立即数
c               使用寄存器 ecx
d               使用寄存器 edx 
S               使用 esi
*/


#define get_seg_byte(seg,addr) ({ \
register char __res; \
__asm__("push %%fs;mov %%ax,%%fs;movb %%fs:%2,%%al;pop %%fs" \
	:"=a" (__res):"0" (seg),"m" (*(addr))); \
__res;})

// 取段 seg 中地址 addr 处的一个长字(4字节)
#define get_seg_long(seg,addr) ({ \
register unsigned long __res; \
__asm__("push %%fs;mov %%ax,%%fs;movl %%fs:%2,%%eax;pop %%fs" \
	:"=a" (__res):"0" (seg),"m" (*(addr))); \
__res;})

// 取fs段寄存器的值(选择符)
#define _fs() ({ \
register unsigned short __res; \
__asm__("mov %%fs,%%ax":"=a" (__res):); \
__res;})

// 以下定义一些函数原型
int do_exit(long code);                 // 程序退出处理. (kernel/exit.c)

void page_exception(void);              // 页异常.实际上 page_fault(mm/page.s)

// 以下定义了一些中断处理程序原型,代码在(kernel/asm.s 或 system_call.s)中
void divide_error(void);                  // int 0
void debug(void);                         // int 1
void nmi(void);                           // int 2
void int3(void);                          // int 3
void overflow(void);                      // int 4
void bounds(void);                        // int 5
void invalid_op(void);                    // int 6
void device_not_available(void);          // int 7
void double_fault(void);                  // int 8
void coprocessor_segment_overrun(void);   // int 9
void invalid_TSS(void);                   // int 10
void segment_not_present(void);           // int 11
void stack_segment(void);                 // int 12
void general_protection(void);            // int 13
void page_fault(void);                    // int 14
void coprocessor_error(void);             // int 16
void reserved(void);                      // int 15
void parallel_interrupt(void);            // int 39
void irq13(void);                         // int 45 协处理器中断处理

// 该子程序用来打印出错中断的名称,出错号,调用程序的EIP,EFLAGS,ESP,FS段寄存器值,
// 段的基址,段的长度,进程号pid,任务号,10字节指令码.如果堆栈在用户数据段,则还打印16字节的堆栈内容
static void die(char * str,long esp_ptr,long nr)
{
	long * esp = (long *) esp_ptr;
	int i;

	printk("%s: %04x\n\r",str,nr&0xffff);
	printk("EIP:\t%04x:%p\nEFLAGS:\t%p\nESP:\t%04x:%p\n",
		esp[1],esp[0],esp[2],esp[4],esp[3]);
	printk("fs: %04x\n",_fs());
	printk("base: %p, limit: %p\n",get_base(current->ldt[1]),get_limit(0x17));
	if (esp[4] == 0x17) {
		printk("Stack: ");
		for (i=0;i<4;i++)
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
		printk("\n");
	}
	str(i);
	printk("Pid: %d, process nr: %d\n\r",current->pid,0xffff & i);
	for(i=0;i<10;i++)
		printk("%02x ",0xff & get_seg_byte(esp[1],(i+(char *)esp[0])));
	printk("\n\r");
	do_exit(11);		/* play segment exception */
}

// 以下这些以do_开头的函数是对应名称中断处理程序调用的C函数
void do_double_fault(long esp, long error_code)
{
	die("double fault",esp,error_code);
}

void do_general_protection(long esp, long error_code)
{
	die("general protection",esp,error_code);
}

void do_divide_error(long esp, long error_code)
{
	die("divide error",esp,error_code);
}

void do_int3(long * esp, long error_code,
		long fs,long es,long ds,
		long ebp,long esi,long edi,
		long edx,long ecx,long ebx,long eax)
{
	int tr;

	__asm__("str %%ax":"=a" (tr):"0" (0));   // 取任务寄存器值 -> tr
	printk("eax\t\tebx\t\tecx\t\tedx\n\r%8x\t%8x\t%8x\t%8x\n\r",
		eax,ebx,ecx,edx);
	printk("esi\t\tedi\t\tebp\t\tesp\n\r%8x\t%8x\t%8x\t%8x\n\r",
		esi,edi,ebp,(long) esp);
	printk("\n\rds\tes\tfs\ttr\n\r%4x\t%4x\t%4x\t%4x\n\r",
		ds,es,fs,tr);
	printk("EIP: %8x   CS: %4x  EFLAGS: %8x\n\r",esp[0],esp[1],esp[2]);
}

void do_nmi(long esp, long error_code)
{
	die("nmi",esp,error_code);
}

void do_debug(long esp, long error_code)
{
	die("debug",esp,error_code);
}

void do_overflow(long esp, long error_code)
{
	die("overflow",esp,error_code);
}

void do_bounds(long esp, long error_code)
{
	die("bounds",esp,error_code);
}

void do_invalid_op(long esp, long error_code)
{
	die("invalid operand",esp,error_code);
}

void do_device_not_available(long esp, long error_code)
{
	die("device not available",esp,error_code);
}

void do_coprocessor_segment_overrun(long esp, long error_code)
{
	die("coprocessor segment overrun",esp,error_code);
}

void do_invalid_TSS(long esp,long error_code)
{
	die("invalid TSS",esp,error_code);
}

void do_segment_not_present(long esp,long error_code)
{
	die("segment not present",esp,error_code);
}

void do_stack_segment(long esp,long error_code)
{
	die("stack segment",esp,error_code);
}

void do_coprocessor_error(long esp, long error_code)
{
	if (last_task_used_math != current)
		return;
	die("coprocessor error",esp,error_code);
}

void do_reserved(long esp, long error_code)
{
	die("reserved (15,17-47) error",esp,error_code);
}

// 下面是异常(陷阱)中断程序初始化子程序.设置他们的中断调用门(中断向量).
// set_trap_gate()与set_system_gate()的主要区别在于前者设置的特权级为0,后者是3. 因此,
// 断点陷阱中断int3,溢出中断overflow和边界出错中断 bounds可以有任何程序产生.
// 这两个函数均是嵌入式汇编宏程序(include/asm/system.h)
void trap_init(void)
{
	int i;

	set_trap_gate(0,&divide_error);             // 设置除操作出错的中断向量值.以下雷同
	set_trap_gate(1,&debug);
	set_trap_gate(2,&nmi);
	set_system_gate(3,&int3);	/* int3-5 can be called from all */
	set_system_gate(4,&overflow);
	set_system_gate(5,&bounds);
	set_trap_gate(6,&invalid_op);
	set_trap_gate(7,&device_not_available);
	set_trap_gate(8,&double_fault);
	set_trap_gate(9,&coprocessor_segment_overrun);
	set_trap_gate(10,&invalid_TSS);
	set_trap_gate(11,&segment_not_present);
	set_trap_gate(12,&stack_segment);
	set_trap_gate(13,&general_protection);
	set_trap_gate(14,&page_fault);
	set_trap_gate(15,&reserved);
	set_trap_gate(16,&coprocessor_error);

	// 下面将int17-48的陷阱门先均设置为reserved,以后每个硬件初始化时会重新设置自己的陷阱门
	for (i=17;i<48;i++)
		set_trap_gate(i,&reserved);
	set_trap_gate(45,&irq13);              // 设置协处理器的陷阱门
	outb_p(inb_p(0x21)&0xfb,0x21);         // 允许主 8259A芯片的 IRQ2中断请求
	outb(inb_p(0xA1)&0xdf,0xA1);           // 运行从 8259A芯片的 IRQ3中断请求
	set_trap_gate(39,&parallel_interrupt); // 设置并行口的陷阱门
}
