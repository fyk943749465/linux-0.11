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


# int16 -- 下面这段代码处理协处理器发出的出错信号.跳转执行C函数math_error()
# (kernel/math/math_emulate.c) 返回后将跳转到 ret_from_sys_call 处继续执行.
.align 2
_coprocessor_error:
	push %ds
	push %es
	push %fs
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl %eax
	movl $0x10,%eax           # ds,es置为指向内核数据段
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax           # fs 置为指向局部数据段(出错程序的数据段)
	mov %ax,%fs
	pushl $ret_from_sys_call  # 把下面调用返回的地址入栈
	jmp _math_error           # 执行 C 函数 math_error() (kernel/math/math_emulate.c)


# int7 -- 设备不存在或些处理不存在
# 如果控制寄存器 CR0 的 EM 标志置位,则当 CPU 执行一个 ESC 转义指令时就会引发该中断, 这样就可以有机会让这个中断
# 处理程序模拟 ESC 转移指令. CR0的TS标志时在 CPU 执行任务转换时设置的. TS 可以用来确定什么时候协处理器中的内容(上下文)
# 与 CPU 正在执行的任务不匹配了. 当 CPU 在运行一个转义指令时发现TS置为,就会引发该中断. 此时就应该恢复新任务的些处理
# 执行状态. 参见(kernel/sched.c)中的说明. 该中断最后将转移到标号 ret_from_sys_call 处执行下去.
.align 2
_device_not_available:
	push %ds
	push %es
	push %fs
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl %eax
	movl $0x10,%eax             # ds,es置为指向内核数据段
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax             # fs 置为指向局部数据段(出错程序的数据段)
	mov %ax,%fs
	pushl $ret_from_sys_call    # 把下面跳转或调用的返回地址入栈

	# clts 指令用于清除控制寄存器 CR0 中的 Task-Switched Flag（TSF）位，以取消任务切换的标志，
    # 使处理器继续执行当前任务。这是在操作系统内核开发中使用的一条重要指令。						
	clts				# clear TS so that we can use math  (TS位是第3位,EM为第2位, 从0开始到31)
	movl %cr0,%eax
	testl $0x4,%eax			# EM (math emulation bit)

	# 这里进行位测试，检查 CR0 寄存器的第 2 位是否被设置（即 EM 位，代表浮点数协处理器的数学仿真）。如果 EM 位被清除（为0），
    # 则执行跳转到 _math_state_restore 标签，表示浮点数协处理器可用，不需要进行数学仿真。
	je _math_state_restore
	pushl %ebp
	pushl %esi
	pushl %edi

	# "数学仿真"（Math Emulation）是一种在不具备硬件浮点数支持的系统上模拟浮点数运算的技术。在某些较早的计算机系统中，没有硬件浮点数处理器，
	# 因此无法直接执行浮点数运算。为了支持浮点数运算，系统开发人员需要实现浮点数运算的软件模拟，即数学仿真。
	# 数学仿真的基本思想是使用整数运算和位操作来模拟浮点数运算。它包括模拟浮点数的加法、减法、乘法、除法等基本运算，以及处理浮点数的特殊情况，
	# 如溢出、无穷大、NaN（非数字）、舍入等。
	# 数学仿真的实现可以相当复杂，因为浮点数运算涉及到许多规范和精度要求。因此，数学仿真的性能通常较低，而且需要大量的计算资源和代码来实现。
	# 在某些情况下，数学仿真可能仍然是必要的，例如在没有硬件浮点数支持的嵌入式系统中，或者在模拟器中运行的程序，其中浮点数运算需要在模拟器中进行。
	# 在你提供的汇编代码中，当检测到控制寄存器 CR0 的 EM 位（位 2）被设置时，意味着浮点数协处理器的数学仿真被启用，因此需要执行相应的数学仿真代码来
	# 支持浮点数运算。否则，如果 EM 位被清除，说明硬件浮点数支持可用，不需要进行仿真。这是为了在没有硬件浮点数支持的系统上模拟浮点数运算的一种常见场景。
	call _math_emulate
	popl %edi
	popl %esi
	popl %ebp
	ret                  # 跳转到 ret_from_sys_call 处执行


# int32 -- (int 0x20)时钟中断处理程序.中断频率被设置为 100Hz (include/linux/sched.h),
# 定时芯片 8253/8254 是在(kernel/sched.c)处初始化的. 因此这里 jiffies 每10毫秒加1.
# 这段代码将 jiffies 增1,发送结束中断指令给8259控制器,然后用当前特权级作为参数调用 C 
# 函数 do_time(long CPL). 当调用返回时转去检测并处理信号.
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
	incl _jiffies       # 从开机开始算起的滴答数时间值(10ms/滴答), 这里将滴答数+1

	# 在计算机硬件和操作系统领域，EOI（End Of Interrupt）是一个缩写，表示中断处理的结束信号。EOI 信号用于通知中断控制器（例如，PIC、APIC等）
	# 或其他硬件部件，表明正在处理的中断已经处理完毕，可以继续处理其他中断或任务。
	# EOI 通常在中断服务例程（ISR）执行完成后发送。当操作系统或硬件处理某个中断时，它会执行相应的中断处理程序，处理完后，发送 EOI 信号。
	# 这个信号的发送告诉中断控制器可以将中断状态清除，并允许接受和处理下一个中断。
	# EOI 的确切实现方式取决于中断控制器和硬件平台。在x86体系结构中，有两个常见的中断控制器：8259A 可编程中断控制器（PIC）和高级可编程中断控制器（APIC）。
	# 在这两种情况下，EOI 的方式可能不同。
	# 总之，EOI 是中断处理的结束信号，用于通知硬件中断控制器或其他部件，当前中断已经处理完毕，可以继续处理其他中断或任务。

	# 由于初始化中断控制芯片时没有采用自动EOI,所以这里需要发指令结束该硬件中断.
	movb $0x20,%al		# EOI to interrupt controller #1
	outb %al,$0x20      # 操作命令字 OCW2 送 0x20 端口

	# 下面三句从选择符中取出当前特权级别(0或3)并压入堆栈, 作为 do_timer 的参数

	# movl CS(%esp), %eax 是一条汇编指令，它的含义是从堆栈中读取位于栈顶的一个叫做 CS 的偏移量处的双字（4字节）数据，并将该数据加载到 %eax 寄存器中。
    # 这个指令的具体含义和功能取决于上下文，特别是栈上数据的结构和用途。在这个指令中，CS 通常是一个相对于栈顶的偏移量，用于访问特定数据或者控制栈上的某些操作。
    # 需要注意的是，这个指令中的 CS 可能是一个占位符，而实际的偏移量可能在代码的其他地方进行了定义或计算。因此，为了正确理解这个指令的含义，需要查看
	# 指令所在上下文以及任何相关的代码。
	movl CS(%esp),%eax          # CS是相对于栈顶esp的一个偏移量
	andl $3,%eax		# %eax is CPL (0 or 3, 0=supervisor)
	pushl %eax


	# do_timer(CPL)执行任务切换,计时等工作,在kernel/shched.c 实现
	call _do_timer		# 'do_timer(long CPL)' does everything from
	addl $4,%esp		# task switching to accounting ...   指向新的栈顶位置
	jmp ret_from_sys_call    # 时间中断调用返回

# 这是 sys_execve()系统调用. 取中断调用程序的代码指针作为参数调用C函数do_execve()
.align 2
_sys_execve:

	# lea EIP(%esp), %eax 这行代码使用了 x86 汇编语言中的 LEA 指令，其含义是将栈顶指针 %esp 寄存器的值与指令指针 %eip 相加，然后将结果加载到 %eax 寄存器中。
    # 需要注意的是，在这个上下文中，EIP 和 ESP 不是通常的寄存器名，而是寄存器的扩展形式。通常，EIP 是指令指针寄存器，ESP 是栈指针寄存器。在汇编语言中，
	# 寄存器名称通常以 % 开头，例如 %eip 和 %esp。
	# 这个指令的实际含义取决于上下文，因为在汇编语言中，寄存器和内存地址可以以多种方式组合在一起。LEA 指令通常被用于执行一些复杂的地址计算，而不是简单的加载。
    # 因此，要完全理解这个指令的含义，需要查看它在程序的上下文中是如何使用的，包括 EIP 和 ESP 的具体值以及指令后续的操作。
	lea EIP(%esp),%eax
	pushl %eax
	call _do_execve
	addl $4,%esp     # 丢弃调用时压入栈的 EIP 值
	ret            

# sys_fork()调用,用于创建子进程,是system_call功能2. 原形在 include/linux/sys.h中.
# 首先调用C函数 find_empty_process(),取得一个进程号pid.若返回负数则说明目前任务数组已满.
# 然后调用 copy_process() 复制进程.
.align 2
_sys_fork:
	call _find_empty_process            # 调用 find_empty_process() (kernel/fork.c)
	testl %eax,%eax                     # 测试,影响标志寄存器SF位,符号标志位
	js 1f                               # 如果测试结果为负数,则跳转到标号1处执行
	push %gs
	pushl %esi
	pushl %edi
	pushl %ebp
	pushl %eax
	call _copy_process                  # 调用C函数的 copy_process()(kernel/fork.c)
	addl $20,%esp                       # 丢弃这里所有压栈的内容
1:	ret


# int46 -- (int 0x2E) 硬盘中断处理程序,响应硬件中断请求 IRQ14
# 当硬盘操作完成或出错就会发出此中断信号.(参见kernel/blk_drv/hd.c)
# 首先向8259A中断控制从芯片发送结束硬件中断指令(EOI),然后取变量do_hd中的函数指针放入edx
# 寄存器中,并置do_hd为NULL,接着判断edx函数指针是否为空. 如果为空,则给edx赋值指向unexpected_hd_interrupt(),用于显示出错信息.
# 随后向8259A主芯片发送EOI指令,并调用edx中指针指向的函数:read_intr(), write_intr()或unexpected_hd_interrupt().
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
	# 由于初始化中断控制芯片时没有采用自动 EOI,所以这里需要发指令结束该硬件中断.
	movb $0x20,%al
	outb %al,$0xA0		# EOI to interrupt controller #1
	jmp 1f			# give port chance to breathe
1:	jmp 1f          # 延时作用
1:	xorl %edx,%edx
	# xchgl 是x86汇编语言中的指令，它的含义是"交换（exchange）两个操作数的值"。具体来说，xchgl 用于交换一个通用寄存器和一个内存位置或另一个寄存器的值。
	# xchgl 指令将 operand1 和 operand2 的值进行交换，即 operand1 的值将成为新的 operand2 的值，而 operand2 的值将成为新的 operand1 的值。
	# 这个交换操作是原子的，不会被中断，因此在多线程或多进程环境中用于同步操作是非常有用的。
	xchgl _do_hd,%edx            # do_hd定义为一个函数指针,将被赋值read_intr()或write_intr()函数地址.(kernel/blk_drv/hd.c)
								 # 放到edx 寄存器后就将 do_hd 指针变量置为 NULL
	testl %edx,%edx              # 测试函数指针是否为NULL
	jne 1f                       # 若空,则使指针指向C函数 unexpected_hd_interrupt()
	movl $_unexpected_hd_interrupt,%edx
1:	outb %al,$0x20               # 送主8259A中断控制器EOI指令(结束硬件中断)
	call *%edx		# "interesting" way of handling intr.   调用do_hd指向的 C 函数
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

# int38 -- (int 0x26) 软盘驱动器中断处理程序,响应硬件中断请求 IRQ6
# 其处理过程与上面对硬盘的处理基本一样(kernel/blk_drv/floppy.c)
# 首先向 8259A 中断控制器主芯片发送 EOI 指令, 返回取变量do_floppy中的函数指针放入 eax 寄存器中, 并置 do_floppy为NULL, 
# 接着判断 eax 函数指针是否为空. 如为空,则给 eax 赋值指向 unexpected_floppy_interrupt(),用于显示出错信息. 随后调用 eax 指向
# 的函数 : rw_interrupt, seek_interrupt, recal_interrupt, reset_interrupt 或 unexpected_floppy_interrupt 
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
	xchgl _do_floppy,%eax       # do_floppy 为一函数指针,将被赋值实际处理 C 函数程序, 
								# 放到 eax 寄存器后就将 do_floppy 指针变量置空.
	testl %eax,%eax             # 测试函数指针是否等于NULL?
	jne 1f
	movl $_unexpected_floppy_interrupt,%eax
1:	call *%eax		# "interesting" way of handling intr.  调用 do_floppy 指向的函数
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

# int 39 -- (int 0x27) 并行口中断处理程序, 对应硬件中断请求信号IRQ7
# 本版本内核还为实现,这里只是发送 EOI 指令 
_parallel_interrupt:
	pushl %eax
	movb $0x20,%al
	outb %al,$0x20
	popl %eax
	iret
