/*
 *  linux/kernel/system_call.s
 *
 *  (C) 1991  Linus Torvalds
 *  系统调用程序
 *	
 *	实现了 Linux 系统调用 (int 0x80) 的接口处理过程,实际的处理过程包含在各系统调用
 *  相应的 C 语言处理函数中,这些处理函数分布在整个Linux内核代码中.
 *
 */

/*
 *  system_call.s  contains the system-call low-level handling routines.
 * This also contains the timer-interrupt handler, as some of the code is
 * the same. The hd- and flopppy-interrupts are also here.
 *
 * NOTE: This code handles signal-recognition, which happens every time
 * after a timer-interrupt and after each system call. Ordinary interrupts
 * don't handle signal-recognition, as that would clutter them up totally
 * unnecessarily.
 *
 * Stack layout in 'ret_from_system_call':
 *
 *	 0(%esp) - %eax
 *	 4(%esp) - %ebx
 *	 8(%esp) - %ecx
 *	 C(%esp) - %edx
 *	10(%esp) - %fs
 *	14(%esp) - %es
 *	18(%esp) - %ds
 *	1C(%esp) - %eip
 *	20(%esp) - %cs
 *	24(%esp) - %eflags
 *	28(%esp) - %oldesp
 *	2C(%esp) - %oldss
 */

/*
 * system_call.s 文件保护系统调用(system_call)底层处理子程序. 由于有些代码比较类似,所以同时 
 * 也包括时钟中断处理(timer-interrupt)句柄. 硬盘和软盘的中断处理程序也在这里.
 * 
 * 注意: 这段代码处理信号(signal)识别,在每次时钟中断和系统调用之后都会进行识别.一般中断信号
 * 并不处理信号识别, 因为会给系统造成混乱.
 * 
 * 从系统调用返回(ret_from_system_call)时堆栈的内容见上面 24-35行
 */

SIG_CHLD	= 17             # 定义 SIG_CHLD 信号(子进程停止或结束)

EAX		= 0x00               # 堆栈中各个寄存器的偏移位置
EBX		= 0x04
ECX		= 0x08
EDX		= 0x0C
FS		= 0x10
ES		= 0x14
DS		= 0x18
EIP		= 0x1C
CS		= 0x20
EFLAGS		= 0x24
OLDESP		= 0x28           # 当有特权级变化时
OLDSS		= 0x2C

# 以下这些是任务结构(task_struct)中变量的偏移值,参见include/linux/sched.h 
state	= 0		# these are offsets into the task-struct.  # 进程状态码
counter	= 4         # 任务运行时间计数(递减)(滴答数),运行时间片
priority = 8        # 运行优先数. 任务开始运行时 counter=priority,越大则运行时间越长
signal	= 12        # 信号位图,每个比特位代表一种信号,信号值=位偏移值+1 
sigaction = 16		# MUST be 16 (=len of sigaction)   // sigaction 结构长度必须是16字节
				    # 信号执行属性结构数组的偏移值,对应信号将要执行的操作和标志信息
blocked = (33*16)   # 受阻塞信号位图的偏移量

# 以下定义在 sigaction 结构中的偏移量, 参加 include/signal.h
# offsets within sigaction
sa_handler = 0              # 信号处理过程的句柄(描述符)
sa_mask = 4                 # 信号量屏蔽码
sa_flags = 8                # 信号集
sa_restorer = 12            # 恢复函数指针, 参见 kernel/signal.c

nr_system_calls = 72        # Linux 0.11 版内核中的系统调用总数

/*
 * Ok, I get parallel printer interrupts while using the floppy for some
 * strange reason. Urgel. Now I just ignore them.
 */

/*
 * 好了,在使用软驱时我收集到了并行打印机中断,很奇怪.何,现在不管它.
 *
 */
# 定义入口点
.globl _system_call,_sys_fork,_timer_interrupt,_sys_execve
.globl _hd_interrupt,_floppy_interrupt,_parallel_interrupt
.globl _device_not_available, _coprocessor_error

# 错误的系统调用号
.align 2                          # 内存 4 字节对齐
bad_sys_call:
	movl $-1,%eax                 # eax 中置-1,退出中断
	iret

# 重新执行调度程序入口. 调度程序 schedule在(kernel/sched.c)
.align 2
reschedule:
    # 这条指令的作用是将 ret_from_sys_call 地址推入栈中，以便在系统调用执行完成后能够正确返回到用户空间。
    # 在系统调用处理的过程中，内核会在堆栈中保存一些状态信息，并在完成系统调用时使用这个地址来返回到用户程序中，继续执行用户程序的代码。
	pushl $ret_from_sys_call       # 将 ret_from_sys_call 的地址入栈(101行)
	jmp _schedule                  # 在sched.c中定义

# int 0x80 -- linux 系统调用入口点(调用中断 int 0x80, eax 中时调用号)
.align 2
_system_call:
	cmpl $nr_system_calls-1,%eax   # 调用号如果超出范围的话就在eax中置-1并退出
	ja bad_sys_call                # 如果超过了合法的系统调用号,0-71, 则系统调用直接退出
	push %ds                       # 保存原段寄存器值
	push %es
	push %fs
	pushl %edx            # ebx, ecx, edx 中放着下体哦那个调用相应的C语言函数的调用参数
	pushl %ecx		# push %ebx,%ecx,%edx as parameters
	pushl %ebx		# to the system call
	movl $0x10,%edx		# set up ds,es to kernel space
	mov %dx,%ds         # ds, es指向内核数据段(全局描述符表中数据段描述符)
	mov %dx,%es
	movl $0x17,%edx		# fs points to local data space
	mov %dx,%fs         # fs指向局部数据段(局部描述符表中数据段描述符)

# 下面这句操作数的含义是:调用地址 = _sys_call_table + %eax * 4 
# 对应的C程序中的 sys_call_table在include/linux/sys.h中,其中定义了一个包括72个
# 系统调用C处理函数的地址数组表.
	call _sys_call_table(,%eax,4)
	pushl %eax                       # 系统调用的返回值入栈
	movl _current,%eax               # 取当前任务(进程)数据结构地址 -> eax (_current是当前任务,在sched.c中定义)

# 下面查看当前任务的运行状态.如果不在就绪状态(state不等于0)就去执行调度程序
	cmpl $0,state(%eax)		# state       # 当然任务状态与0比较
	jne reschedule                        # 如果当前任务状态不等于0,就执行 reschedule, 调用c语言的 schedule()函数
	cmpl $0,counter(%eax)		# counter # 任务时间片与0比较
	je reschedule                         # 如果任务的时间片用完了,则调用 schedule()

# 以下这段代码执行从系统调用C函数返回后,对信号量进行识别处理.
ret_from_sys_call:
    
	# 首先判别当前任务释放是初始化任务task0,如果是则不必对齐进行信号量方面的处理,直接返回
	movl _current,%eax		# task[0] cannot have signals
	cmpl _task,%eax         # _task 对应 c程序中的 task[] 数组,直接引用task相当于引用task[0], 当前任务与task[0]比较
	je 3f                   # 如果当前任务是task[0],则向前跳转到 3 标号处
	
	# 通过对原调用程序代码选择符的检查来判断调用程序释放是内核任务(例如任务1). 如果是直接退出中断
    # 否则对于普通进程则需要进行信号量的处理. 这里比较选择符是否为普通用户代码段的选择符 0x000f (RPL=3, 局部表, 第一个段(代码段))
    # 如果不是则跳转退出中断程序.
	cmpw $0x0f,CS(%esp)		# was old code segment supervisor ?
	jne 3f

	# 如果原堆栈段选择符不为0x17(也即原堆栈不在用户数据段中),则也退出.
	cmpw $0x17,OLDSS(%esp)		# was stack segment = 0x17 ?
	jne 3f

	# 下面这段代码的用途是首先取当前任务结构中的信号位图(32位,每位代表1种信号),然后用任务结构中的信号阻塞(屏蔽)码,阻塞不允许的信号位,
    # 取得数值最小的信号值,再吧原信号位图中该信号对应的位复位(置0),最后将该信号值作为参数之一调用do_signal()
    # do_signal() 在(kernel/signal.c)中, 其参数包括13个入栈的信息.
	movl signal(%eax),%ebx        # 取信号位图->ebx, 每1位代表1种信号,共32个信号
	movl blocked(%eax),%ecx       # 取阻塞(屏蔽)信号位图 ->ecx
	notl %ecx                     # 每位取反
	andl %ebx,%ecx                # 获得许可的信号位图
	bsfl %ecx,%ecx                # 从低位(位0)开始扫描位图,看是否有1的位, 若有,则ecx保留改为的偏移值(即第几位0-31)
	je 3f                         # 如果没有信号,则向前跳转退出
	btrl %ecx,%ebx                # 复位该信号(ebx含有原signal位图)
	movl %ebx,signal(%eax)        # 重新保存signal 位图信息 -> current-signal. 
	incl %ecx                     # 将信号跳转为从1开始的数(1-32)
	pushl %ecx                    # 将信号值入栈,作为调用do_signal的参数之一
	call _do_signal               # 调用 C 函数信号处理程序(kernel/signal.c)
	popl %eax                     # 弹出信号值
3:	popl %eax
	popl %ebx
	popl %ecx
	popl %edx
	pop %fs
	pop %es
	pop %ds
	iret

.align 2
_coprocessor_error:
	push %ds
	push %es
	push %fs
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl %eax
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	pushl $ret_from_sys_call
	jmp _math_error

.align 2
_device_not_available:
	push %ds
	push %es
	push %fs
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl %eax
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	pushl $ret_from_sys_call
	clts				# clear TS so that we can use math
	movl %cr0,%eax
	testl $0x4,%eax			# EM (math emulation bit)
	je _math_state_restore
	pushl %ebp
	pushl %esi
	pushl %edi
	call _math_emulate
	popl %edi
	popl %esi
	popl %ebp
	ret

.align 2
_timer_interrupt:
	push %ds		# save ds,es and put kernel data space
	push %es		# into them. %fs is used by _system_call
	push %fs
	pushl %edx		# we save %eax,%ecx,%edx as gcc doesn't
	pushl %ecx		# save those across function calls. %ebx
	pushl %ebx		# is saved as we use that in ret_sys_call
	pushl %eax
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	incl _jiffies
	movb $0x20,%al		# EOI to interrupt controller #1
	outb %al,$0x20
	movl CS(%esp),%eax
	andl $3,%eax		# %eax is CPL (0 or 3, 0=supervisor)
	pushl %eax
	call _do_timer		# 'do_timer(long CPL)' does everything from
	addl $4,%esp		# task switching to accounting ...
	jmp ret_from_sys_call

.align 2
_sys_execve:
	lea EIP(%esp),%eax
	pushl %eax
	call _do_execve
	addl $4,%esp
	ret

.align 2
_sys_fork:
	call _find_empty_process
	testl %eax,%eax
	js 1f
	push %gs
	pushl %esi
	pushl %edi
	pushl %ebp
	pushl %eax
	call _copy_process
	addl $20,%esp
1:	ret

_hd_interrupt:
	pushl %eax
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	movb $0x20,%al
	outb %al,$0xA0		# EOI to interrupt controller #1
	jmp 1f			# give port chance to breathe
1:	jmp 1f
1:	xorl %edx,%edx
	xchgl _do_hd,%edx
	testl %edx,%edx
	jne 1f
	movl $_unexpected_hd_interrupt,%edx
1:	outb %al,$0x20
	call *%edx		# "interesting" way of handling intr.
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

_floppy_interrupt:
	pushl %eax
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	movb $0x20,%al
	outb %al,$0x20		# EOI to interrupt controller #1
	xorl %eax,%eax
	xchgl _do_floppy,%eax
	testl %eax,%eax
	jne 1f
	movl $_unexpected_floppy_interrupt,%eax
1:	call *%eax		# "interesting" way of handling intr.
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

_parallel_interrupt:
	pushl %eax
	movb $0x20,%al
	outb %al,$0x20
	popl %eax
	iret
