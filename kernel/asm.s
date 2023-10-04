/*
 *  linux/kernel/asm.s
 *
 *  (C) 1991  Linus Torvalds
 *   硬件中断程序
 *   用于处理系统硬件异常所引起的中断,
 */

/*
 * asm.s contains the low-level code for most hardware faults.
 * page_exception is handled by the mm, so that isn't here. This
 * file also handles (hopefully) fpu-exceptions due to TS-bit, as
 * the fpu must be properly saved/resored. This hasn't been tested.
 */

/*
 * asm.s 程序中包括大部分的硬件故障(或出错)处理的底层次代码. 页异常是由内存管理程序 mm 处理的, 所以不在这里.
 * 此程序还处理(希望是这样) 由于 TS-位而造成的 fpu 异常,
 * 因为 fpu 必须正确地进行保存/恢复处理, 这些还没有测试过.
 */

 # 本代码文件主要涉及对 Intel 保留的中断 int0 -- int16 的处理(int17-int31留作今后使用).
 # 以下是一些全局函数名的声明,其原形在 traps.c 中说明

.globl _divide_error,_debug,_nmi,_int3,_overflow,_bounds,_invalid_op
.globl _double_fault,_coprocessor_segment_overrun
.globl _invalid_TSS,_segment_not_present,_stack_segment
.globl _general_protection,_coprocessor_error,_irq13,_reserved

# int0 下面是被0除出错(divide_error)处理代码. 标号'_divide_error'实际上是C语言函数 divide_error()编译后所生成模块对应的名称.
# '_do_divide_error'函数在traps.c中
# 首先要理解,这里的中断,是因为用户态执行过程中发生了错误, 因此需要调用中断程序处理.
# 在调用中断程序之前,需要先保护现场,然后切换到内核态后,调用内核态的函数.
# 调用内核态的函数时,需要将函数地址入栈,函数参数入栈,才能够调用.
_divide_error:
	pushl $_do_divide_error       # 首先将把要调用的函数地址入栈.这段程序的出错号为0.
no_error_code:                    # 这里是无出错号处理的入口处
# xchg1 %eax, (%esp) 的理解 :
# 在系统调用发生时，操作系统内核需要保存用户态的执行现场（如 ss、esp、eflags、cs 和 eip 寄存器的值），以便在系统调用
# 执行完毕后能够返回用户态并继续执行用户程序。这些寄存器保存了用户程序的状态，使得内核可以准确地还原用户程序的执行现场。
# 接下来，在内核态中，内核需要执行相应的系统调用服务例程。为了调用这些服务例程，通常会将函数地址（服务例程的入口地址）
# 存储在某个寄存器中，这通常是 eax 寄存器。内核通过将函数地址放入 eax 中，可以方便地访问和执行系统调用服务例程。
# 关于 xchgl 指令，它实际上是用于交换两个操作数的值。在这种情况下，它的目的是将栈顶元素（即函数地址）与 eax 寄存器中的值
# 进行交换。这是因为系统调用服务例程的返回值通常会存储在 eax 寄存器中。通过交换操作，系统调用服务例程的地址被加载到 
# eax 寄存器中，这样内核可以轻松地执行相应的系统调用服务例程，并且在服务例程执行完毕后，将结果返回到 eax 寄存器中。
# 总之，交换 eax 寄存器和栈顶元素的值是为了确保内核可以顺利地调用系统调用服务例程，并在执行完毕后将结果返回给用户程序。
# 这是操作系统在进行系统调用时的一种常见做法。
	xchgl %eax,(%esp)             # _do_divide_error 的地址 -> eax, eax 被交换入栈  将它们的值互相赋给对方。
								  # 这可以用于在不使用额外寄存器的情况下交换两个变量的值。
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %edi
	pushl %esi
	pushl %ebp
	push %ds                       # 16位的段寄存器入栈后也要占用4个字节
	push %es
	push %fs
	pushl $0		# "error code" #将出错码入栈
	lea 44(%esp),%edx              # lea 44(%esp), %edx 是x86汇编语言中的一条指令，它的含义是将栈指针 %esp 向上偏移44个字节的位置的有效地址加载到寄存器 %edx 中。
	pushl %edx
	movl $0x10,%edx                # 内核代码数据段选择符
	mov %dx,%ds
	mov %dx,%es
	mov %dx,%fs        # 下行上的 * 号表示是绝对调用操作数, 与程序指针 PC 无关
	call *%eax         # 调用 C 函数 do_divide_error() 
	addl $8,%esp       # 让堆栈指针重新指向寄存器fs入栈处 
					   # addl $8, %esp 是x86汇编语言中的一条指令，它的含义是将栈指针 %esp 的值增加8个字节，通常用于释放栈上的内存空间，
					   # 以便在函数返回时清除局部变量和函数调用所使用的栈空间。
	pop %fs
	pop %es
	pop %ds
	popl %ebp
	popl %esi
	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax          # 弹出原来 eax 中的内容
	iret

# int 1 -- debug 调试中断入口点. 处理过程同上
_debug:
	pushl $_do_int3		# _do_debug   C函数指针入栈
	jmp no_error_code

# int2 -- 非屏蔽中断调用入口点
_nmi:
	pushl $_do_nmi
	jmp no_error_code

# int3 -- 同_debug
_int3:
	pushl $_do_int3
	jmp no_error_code

# int4 -- 溢出出错处理中断入口点.
_overflow:
	pushl $_do_overflow
	jmp no_error_code

# int5 -- 边界检查出错中断入口点.
_bounds:
	pushl $_do_bounds
	jmp no_error_code

# int6 -- 无效操作指令出错中断入口点
_invalid_op:
	pushl $_do_invalid_op
	jmp no_error_code

# int9 -- 协处理器段超出出错中断入口点.
_coprocessor_segment_overrun:
	pushl $_do_coprocessor_segment_overrun
	jmp no_error_code

# int 15 - 保留
_reserved:
	pushl $_do_reserved
	jmp no_error_code

# int45 -- (=0x20 + 13) 数学协处理器发出的中断
# 当协处理器执行完一个操作是就会发出IRQ13中断信号,以通知CPU操作完成.
_irq13:
	pushl %eax
	xorb %al,%al        # 80387 在执行计算时, CPU会等待其操作的完成
	outb %al,$0xF0      # 通过写 0xF0 端口, 本中断将消除CPU的BUSY延续信号,并重新激活80387的处理器扩展请求引脚PEREQ.
					    # 该操作主要时为了确保在继续执行80387的任何指令之前,响应本中断.
	movb $0x20,%al
	outb %al,$0x20      # 向 8259 主中断控制芯片发送E01(中断结束)信号.
	jmp 1f
1:	jmp 1f
1:	outb %al,$0xA0      # 再向 8259 从中断控制芯片发送EO1(中断结束)信号.
	popl %eax
	jmp _coprocessor_error    # _coprocessor_error 原来再本文将中,现在已经放到了(kernel/system_call.s)

# 一些中断在调用时会在中断返回地址之后将出错号压入堆栈, 因此返回时也需要将出错号弹出.
# int8 -- 双出错故障.
_double_fault:
	pushl $_do_double_fault                      # C函数地址入栈
error_code:
	xchgl %eax,4(%esp)		# error code <-> %eax , eax 原来的值被保存在堆栈上
	xchgl %ebx,(%esp)		# &function <-> %ebx ,  ebx 原来的值被保存在堆栈上
	pushl %ecx
	pushl %edx
	pushl %edi
	pushl %esi
	pushl %ebp
	push %ds
	push %es
	push %fs
	pushl %eax			# error code   # 出错号入栈
	lea 44(%esp),%eax		# offset   # 程序返回地址处堆栈指针位置入栈
	pushl %eax
	movl $0x10,%eax                    # 置内核数据段选择符
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	call *%ebx                         # 调用相应的C函数,其参数已入栈
	addl $8,%esp                       # 堆栈指针重新指向栈中放置fs内容的位置
	pop %fs
	pop %es
	pop %ds
	popl %ebp
	popl %esi
	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	iret

# int10 -- 无效的任务状态段
_invalid_TSS:
	pushl $_do_invalid_TSS
	jmp error_code

# int11 -- 段不存在
_segment_not_present:
	pushl $_do_segment_not_present
	jmp error_code

# int12 -- 堆栈错误
_stack_segment:
	pushl $_do_stack_segment
	jmp error_code

# int13 -- 一般保护性出错
_general_protection:
	pushl $_do_general_protection
	jmp error_code


# int7 -- 设备不存在(_device_not_available)在(kernel/system_call.s)
# int14 -- 页错误(_page_fault)在(mm/page.s)
# int16 -- 协处理器错误(_coprocessor_error)在(kernel/system_call.s)
# 时钟中断 int0x20 (_timer_interrupt)在(kernel/system_call.s)
# 系统调用 int0x80 (_system_call)在(kernel/system_call.s)