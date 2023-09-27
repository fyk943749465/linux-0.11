/*
 *  linux/boot/head.s
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 *  head.s contains the 32-bit startup code.
 *
 * NOTE!!! Startup happens at absolute address 0x00000000, which is also where
 * the page directory will exist. The startup code will be overwritten by
 * the page directory.
 */

/*
 * head.s 含有 32 位启动代码
 * 注意!!! 32启动代码是从绝对地址0x0000 0000 开始的,这里也同样是页目录将存放的地方
 * 因此这里的启动代码将被页目录覆盖掉 
 */

/*
 * 在GNU汇编语言中，使用的寄存器通常是x86体系结构的一部分，这些寄存器分为通用寄存器、特殊目的寄存器和段寄存器。以下是x86体系结构中常见的寄存器以及它们的位数：
 *
 * 通用寄存器：
 *
 * eax（32位）：累加器，用于算术和逻辑操作。
 * ebx（32位）：基址寄存器，通常用于存储指针和数据地址。
 * ecx（32位）：计数寄存器，通常用于循环计数。
 * edx（32位）：数据寄存器，用于数据操作。
 * esi（32位）：源变址寄存器，通常用于数据传输。
 * edi（32位）：目标变址寄存器，通常用于数据传输。
 * 特殊目的寄存器：
 * 
 * esp（32位）：堆栈指针，用于堆栈操作。
 * ebp（32位）：堆栈基址指针，通常用于函数调用。
 * eip（32位）：指令指针，用于存储下一条要执行的指令地址。
 * eflags（32位）：标志寄存器，包含处理器状态标志，如零标志、进位标志等。
 * 段寄存器：
 *
 * cs（16位）：代码段寄存器，用于存储代码段的选择子。
 * ds（16位）：数据段寄存器，用于存储数据段的选择子。
 * ss（16位）：堆栈段寄存器，用于存储堆栈段的选择子。
 * es（16位）：附加段寄存器，通常用于额外的数据段。
 * fs（16位）：附加段寄存器，通常用于附加的数据段。
 * gs（16位）：附加段寄存器，通常用于附加的数据段。
 * 这些寄存器的名称和用途在x86汇编语言中是标准的，但在不同的汇编语法中（如AT&T语法和Intel语法）可能会稍有不同。通常，这些寄存器用于执行各种算术、逻辑、数据传输、
 * 堆栈操作和控制流操作。程序员可以根据需要使用这些寄存器来执行特定的任务。
 */

/* 在x86体系结构的32位保护模式下，段寄存器的寻址方式发生了变化，与实模式下的寻址方式有很大的不同。在保护模式下，段寄存器不再存储段的物理地址，
 * 而是存储一个称为 "段选择子"（Segment Selector）的值。这个段选择子用于索引全局描述符表（Global Descriptor Table，简称GDT）
 * 或局部描述符表（Local Descriptor Table，简称LDT）中的段描述符。
 * 每个段选择子由以下部分组成：
 *    索引（Index）：指定了描述符在GDT或LDT中的索引位置。索引值从0开始递增。
 *    特权级别（Privilege Level，简称PL）：表示段的特权级别，通常有0、1、2、3四个特权级别，0 最高，3 最低。
 *    表（Table）：指示了是从GDT还是LDT中检索段描述符。如果表位为0，表示从GDT中检索，如果为1，表示从LDT中检索。
 *    TI（Table Indicator）：表示是否使用局部描述符表。如果TI为0，表示使用GDT，如果为1，表示使用LDT。
 * 每个段选择子在GDT或LDT中对应一个段描述符，段描述符包含了有关段的重要信息，包括段的起始地址、段的长度、访问权限、
 * 段的类型等。在执行指令时，CPU会使用段选择子来索引描述符表，然后从相应的段描述符中获取段的属性。
 * 这种寻址方式提供了更高的灵活性和安全性，允许操作系统在不同的特权级别之间隔离不同的段，并为每个段定义不同的访问权限。
 * 这种方式是保护模式的核心特性，有助于实现多任务处理、内存保护和操作系统安全性。
 * 总之，在32位保护模式下，段寄存器存储的是段选择子，通过段选择子可以间接地访问段描述符，从而控制内存访问和特权级别。
 */

.text
.globl _idt,_gdt,_pg_dir,_tmp_floppy_area  # 声明全局标识符
_pg_dir:                                   # 页目录将会存放在这里
startup_32:                                # 设置各个数据段寄存器
	movl $0x10,%eax                        # 对于GNU汇编来说,每个直接数要以$开始,否则是表示地址
										   # 每个寄存器名都要以 '%'开头, eax 表示32位的 ax 寄存器
										   # 再次注意!!! 这里已经是 32 位运行模式,因此这里的 $0x10 并不是把地址 0x10(0b0001 0000) 装入各个段寄存器,它现在
										   # 是全局段描述符表中的偏移值,或者更正确地说是一个描述符表项的选择符. 这里$0x10的含义是请求特权级0(位0-1=0)
										   # 选择全局描述符表(位2=0),选择表中第2项(位3-15=2).它正好指向表中的数据段描述符.
										   # 下面代码的含义是: 置ds,es,fs,gs中的选择符为setup.s中构造的数据段(全局段描述符表的第2项),并将堆栈放置在 stack_start 
										   # 指向的 user_stack 数组区,然后使用本程序后面定义的新中断描述符表和全局描述符表. 新全局段描述符表中初始内容与setup.s中
										   # 的基本一样,仅段限长从8MB修改成了16MB. stack_start 定义在kernel/sched.c. 它是指向user_stack数组末端的一个长指针
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	mov %ax,%gs
	lss _stack_start,%esp                  # 在x86汇编语言中，lss 指令的含义是 "Load Segment Selector"，即加载段选择子。这个指令主要用于加载一个段选择子
										   #（通常是GDT或LDT中的一个条目）并将其值存储到一个指定的寄存器中。
										   # 表示_stack_start -> ss:esp, 设置系统堆栈
										   # stack_start 定义在 kernel/sched.c 69 行
							
	call setup_idt                         # 调用设置中断描述符表子程序
	call setup_gdt                         # 调用设置全局描述符表子程序
	movl $0x10,%eax		# reload all the segment registers    # 因为修改了 gdt,所以需要重新装载所有的段寄存器. CS代码段寄存器已经在 setup_gdt中重新加载过了
	mov %ax,%ds		# after changing gdt. CS was already      # 由于段描述符中的段限长从 setup.s 程序的 8MB 改成了本程序设置的 16MB,因此这里再次对所有段寄存器
	mov %ax,%es		# reloaded in 'setup_gdt'                 # 执行加载操作是必须的.另外,通过使用 bochs跟踪观察,如果不对 CS 再次执行加载, 那么在执行到行26,这里
	mov %ax,%fs                                               # 是行72(因为加了很多注释,修改了源码的行数)时CS代码段不可见部分的限长还是8MB,这样看来应该重新加载CS
	mov %ax,%gs                                               # 但在实际机器上测试结果表明 CS 已经加载过了
	lss _stack_start,%esp                  # 重新设置系统堆栈
	xorl %eax,%eax                         # 下面代码用于测试 A20 地址线是否已经开启,.采用的方法时向内存地址0x000000 处写入任意一个数值,燃控看内存 0x100000(1M)处是否也是这个
1:	incl %eax		# check that A20 really IS enabled     # 数值.如果一直相同的话,就一直比较下去,也即死循环,死机了.表示地址A20没有选通,结果内核就不能使用1M以上的内存.
	movl %eax,0x000000	# loop forever if it isn't
	cmpl %eax,0x100000
	je 1b                # 1b 表示向后(backward)跳转到标号1去(79行);若时 5f 则表示向前(forward)跳转到标号5去
/*
 * NOTE! 486 should set bit 16, to check for write-protect in supervisor
 * mode. Then it would be unnecessary with the "verify_area()"-calls.
 * 486 users probably want to set the NE (#5) bit also, so as to use
 * int 16 for math errors.
 */

/*
 * 注意! 下面这段程序中, 486 应该将为 16 置位, 以检查在超级用户模式下的写保护,此后"verify_area()"调用中就不需要了.
 * 486 的用户通常也会想将 NE(#5)置位,以便对数学协处理器的出错 使用 int 16
 */

 # 下面这段程序用于检查数学写处理器芯片是否存在.方法是修改控制寄存器CR0,在假设存在协处理器的情况下执行一个协处理器指令,
 # 如果出错的话,则说明协处理器芯片不存在,需要设置CR0中的协处理器仿真位 EM(位2),并复位协处理器存在标志MP(位1)

	movl %cr0,%eax		    # check math chip
	andl $0x80000011,%eax	# Save PG,PE,ET
/* "orl $0x10020,%eax" here for 486 might be good */
	orl $2,%eax		        # set MP  设置CRO芯片的 MP标志位
	movl %eax,%cr0
	call check_x87
	jmp after_page_tables

/*
 * We depend on ET to be correct. This checks for 287/387.
 */

 # 我们依赖于ET 标志的正确性来检测 287/387存在与否
check_x87:
	fninit                                     
									# fninit 是x86汇编语言中的一条指令，用于初始化浮点协处理器（FPU）的状态。FPU是处理浮点数运算的协处理器，
									# 它可以执行浮点数的加法、减法、乘法、除法等操作。在使用FPU之前，需要对其进行初始化，以确保其状态正确设置。
									# fninit 指令的主要作用是将FPU的各种寄存器和标志位重置为初始状态，即清除所有的浮点数数据、标志位和控制寄存器。
									# 这将确保FPU在接下来的浮点数运算中处于可预测的状态。
									# 使用 fninit 指令通常包括以下步骤：
									# 清除FPU数据寄存器，将其设置为零。
									# 清除FPU控制寄存器，将其设置为默认值。
									# 清除FPU标志寄存器中的各种标志位。
									# 确保FPU状态位被设置为初始状态，通常是非异常状态。
									# 初始化FPU是非常重要的，因为如果FPU的状态不正确，可能会导致浮点数运算产生不确定的结果或引发异常。
									# 需要注意的是，fninit 指令在x86汇编语言中是针对16位实模式和32位保护模式的FPU的指令。在64位长模式（Long Mode）下，
									# 使用SSE（Streaming SIMD Extensions）和AVX（Advanced Vector Extensions）等更先进的指令集进行浮点数运算，而不再使用FPU。
									# 因此，64位系统中不再使用 fninit 指令初始化FPU。
	fstsw %ax
									# fstsw %ax 指令是x86汇编语言中的一条指令，用于将浮点状态字（FPU Status Word）的值存储到通用寄存器 ax 中。
									# 具体含义如下：
									# fstsw：这部分指令表示将浮点状态字存储。
									# %ax：这是通用寄存器 ax 的一种表示方式，它是16位寄存器。
									# 浮点状态字是FPU（浮点处理单元）的一部分，它包含了有关浮点计算的状态信息和标志位。通过执行 fstsw %ax 指令，你可以将FPU状态字
									# 的值加载到寄存器 ax 中，以便在汇编程序中进一步处理或检查FPU的状态。
									# 一旦状态字被加载到 ax 寄存器中，你可以使用其他指令来检查浮点数运算中是否发生了异常或获取其他相关信息。通常，状态字中的不同
									# 位对应于不同的状态标志，用于指示浮点运算中的各种条件，例如溢出、零除错误、无效操作等。
									# 需要注意的是，使用FPU指令集时，正确处理FPU的状态非常重要，以确保浮点运算的正确性和稳定性。因此，在进行浮点数运算后，
									# 通常需要检查FPU状态字以确保没有发生异常或错误。
	cmpb $0,%al                     # 判断状态
	je 1f			/* no coprocessor: have to set bits */  # 向前跳转到标号1处
	movl %cr0,%eax                  # 这里是改写控制寄存器 cr0, 首先用 eax保存cr0, 然后执行以后操作
	xorl $6,%eax		/* reset MP, set EM */ # 6(0b0000 0110)
	movl %eax,%cr0                  # 将 eax 值给到cr0
	ret
.align 2                            # 这里 .align 2 的含义是指存储边界对齐调整. 2 表示调整到地址最后2位为0,即按4字节方式对齐内存地址
1:	.byte 0xDB,0xE4		/* fsetpm for 287, ignored by 387 */  # 287 协处理器码
	ret

/*
 *  setup_idt
 *
 *  sets up a idt with 256 entries pointing to
 *  ignore_int, interrupt gates. It then loads
 *  idt. Everything that wants to install itself
 *  in the idt-table may do so themselves. Interrupts
 *  are enabled elsewhere, when we can be relatively
 *  sure everything is ok. This routine will be over-
 *  written by the page tables.
 */
 # 下面这段是设置中断描述符表的子程序 setup_idt
 # 将中断描述符表 idt 设置成具有 256 个项,并且都执行 ignore_int 中断门. 
 # 然后加载中断描述符表寄存器(用lidt指令). 真正使用的中断门以后再安装
 # 当我们再其它地方认为一切都正常时再开启中断.该子程序将会被页表覆盖掉.

 # 中断描述符表中的项虽然也是8个字节组成,但器格式与全局表中的不同,被称为门描述符
 # (Gate Descriptor).它的0-1,6-7字节是偏移量,2-3字节是选择符,4-5字节是一些标志
setup_idt:
    # lea 指令是 x86 汇编语言中的一条指令，它的主要作用是将一个有效地址（Effective Address）加载到目标操作数中，
	# 而不执行实际的内存读取操作。它常用于进行地址的计算和存储，而不是加载实际的数据。
	lea ignore_int,%edx                                        # 将 ignore_int 的有效地址(偏移值)值 -> edx 寄存器
	movl $0x00080000,%eax                                      # 将选择符0x0008 置入 eax 的高16 位中
	movw %dx,%ax		/* selector = 0x0008 = cs */           # 偏移值的低16位置入eax的低16位中,此时 eas含有门描述符低4字节的值
	movw $0x8E00,%dx	/* interrupt gate - dpl=0, present */  # 此时 edx 含有门描述符高 4 字节的值  0x8E00说明是中断门

	# IDT 是一个 8 字节的描述符数组(每一个描述符8字节,当作数组的一个元素)
	# IDT 本身存储是,是用6个字节.前两个字节表示idt表的限长, 后4个字节表示表的线性基地址.
	# 上面的代码执行完成后, edx 寄存器中的 值  31-16位(高16位) 存放偏移值  低16位的值是 0x8e00 说明这个一个中断门
	# eax 寄存器的 高16 位存放了段选择子, 低16 是偏移值,但这里是0. 因为 edx中的高16位已经有了偏移值

	# 判断一个中断是何种类型,关键是看这里的edx的低16中的值,其实更具体一点是dx中高8位的值. 
	# dx:   P|DPL|00101|   任务门
	#       P|PDL|01110|   中断门
	#   	P|PDL|01111|   陷阱门

	#	P占1位,代表 这个位只是 xx门是否有效, 1有效,0无效
	#	PDL占2位,代表 xx 门的特权级别。它指定了可以触发这个xx门的代码段的最高特权级别. DPL=0表示只有特权级别0的代码可以触发这个xx门。

	lea _idt,%edi         # _idt 是中断描述符表的地址,放在edi中
	mov $256,%ecx         # ecx 存放 256 表示循环 256 次
rp_sidt:
	movl %eax,(%edi)      # (%寄存器) 表示的是内存单元,即修改_idt表内存单元中的值,即构建_idt表   
	movl %edx,4(%edi)     # movl %edx, 4(%edi) 的含义是将%edx寄存器中的值移动到位于%edi寄存器的值加上4字节偏移量的内存地址中。
	addl $8,%edi          # 步长位 8 字节
	dec %ecx
	jne rp_sidt
	lidt idt_descr    # lidt 指令的作用是将IDT的起始地址和限制加载到IDT寄存器中，从而告诉处理器IDT的位置和结构。这样，处理器在发生中断或异常时能够找到
					  # 正确的中断描述符并跳转到相应的处理程序。
					  # 通常，lidt指令在操作系统内核的初始化过程中使用，以设置正确的中断和异常处理程序。配置正确的IDT是操作系统的关键部分，因为它确保
					  # 了系统能够正确响应中断事件。
	ret

/*
 *  setup_gdt
 *
 *  This routines sets up a new gdt and loads it.
 *  Only two entries are currently built, the same
 *  ones that were built in init.s. The routine
 *  is VERY complicated at two whole lines, so this
 *  rather long comment is certainly needed :-).
 *  This routine will beoverwritten by the page tables.
 */
 # 设置全局描述符表项 setup_gdt
 # 这个子程序设置一个新的全局描述符表 gdt,并加载.此时仅创建了两个表项,与前面的一样,该子程序只有两行
 # "非常的"复杂,所以当然需要这么长的注释了. 该子程序将被页表覆盖
setup_gdt:
	lgdt gdt_descr     # 加载全局描述符表寄存器(内容已经设置好了)
	ret

/*
 * I put the kernel page tables right after the page directory,
 * using 4 of them to span 16 Mb of physical memory. People with
 * more than 16MB will have to expand this.
 */

 # Linus 将内核的内存页表直接放在了页目录之后,使用了 4 个表来寻址 16MB 的物理内存.
 # 如果你有多于 16MB 的内存, 就需要在这里进行扩充修改

 # 每个页表长为 4 Kb 字节(1页内存页面),而每个页表项需要 4 个字节,因此一个页表共可以存放 1024 个表项.
 # 如果一个页表项寻址 4 KB 的地址空间,则夜歌页表就可以选择 4MB 的物理内存. 页表项的格式为: 项的前0-11位存放一些标志,例如是否在内存中(P位0)
 # 读写许可(R/W位1),普通用户还是超级用户使用(U/S位2),是否修改过(是否脏了)(D位6)等;表项的位12-31是页框地址,用于指出一页内存的物理起始地址
.org 0x1000    # .org（origin）是汇编语言中的伪指令，它用于设置汇编器的输出位置或地址。.org 指令的参数是一个地址或偏移量，它告诉汇编器将后续的指令或数据
               # 放置在指定的地址或偏移量处。
			   # 在汇编语言中，.org 指令通常用于定义程序的起始地址或指定数据和代码的存储位置。例如，.org 0x1000 表示后续的汇编指令或数据应该从
			   # 地址 0x1000 开始存放。
		       # 这在操作系统内核编程或嵌入式系统编程中非常有用，因为它允许程序员明确指定程序的加载地址或内存布局。一旦指定了起始地址，汇编器将确
			   # 保后续的指令或数据正确地放置在指定的地址处。
               # 请注意，.org 指令的确切行为可能会因汇编器而异，因此最好查看您使用的汇编器的文档，以了解它的具体行为和语法。
pg0:           # 第一个页表(偏移0开始处存放页表目录)

.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000     # 定义下面的内存数据块从偏移 0x5000 处开始
/*
 * tmp_floppy_area is used by the floppy-driver when DMA cannot
 * reach to a buffer-block. It needs to be aligned, so that it isn't
 * on a 64kB border.
 */
# 当DMA(直接存储器访问)不能访问缓冲块时,下面的tmp_floppy_area 内存块就可供软盘驱动程序使用.
# 其地址需要对齐调整,这样就不会跨越64kB边界了
_tmp_floppy_area:
	.fill 1024,1,0         # 共保留 1024向,每项1字节,填充数值0 汇编指令
						   # .fill 通常用于在汇编代码中填充一定数量的字节或字，以占据内存空间或创建占位符。
						   # 这个指令在不需要具体的指令或数据时非常有用，可以帮助在内存中留出一些空间，或者创建占位符以后续填充。
                           # .fill count, size, value

# 下面这几个入栈操作(pushl)用于为调用/init/main.c程序和返回作准备.
# 前面3个入栈0值应该分别是 envp, argv指针 和 argc值,但main()没有用到.
#  pushl $L6 这行代码是模拟调用 main.c程序时首先将返回地址入栈操作,所以如果main.c程序真的退出时,就会
# 返回到这里的标号L6处继续执行下去,也即死循环.
# pushl $_main 将main.c地址压入堆栈,这样,在设置分页处理(setup_paging)结束后,
# 执行'ret'返回指令时就会将main.c程序的地址弹出堆栈,并去执行main.c程序去了.
after_page_tables:
	pushl $0		# These are the parameters to main :-)
	pushl $0
	pushl $0
	pushl $L6		# return address for main, if it decides to.
	pushl $_main
	jmp setup_paging
L6:
	jmp L6			# main should never return here, but
				# just in case, we know what happens.

/* This is the default interrupt "handler" :-) */
int_msg:
	.asciz "Unknown interrupt\n\r"            # 定义字符串,"未知中断(回车换行)"
.align 2                    # 在汇编语言中，.align是一个指令，用于在内存中对齐数据或代码。.align后面的参数指定对齐的方式，通常是以2的幂为基础的指数。在你的示例中，.align 2的含义是将后续的数据或代码对齐到2的幂的边界，也就是4字节的边界。
ignore_int:
	pushl %eax           # 入栈
	pushl %ecx           # 入栈
	pushl %edx           # 入栈
	push %ds             # 这里需要注意!! ds es fs gs等虽然是16位的寄存器,但入栈后,仍然会以32位的形式入栈,也即需要占用4个字节的堆栈空间.
	push %es
	push %fs
	movl $0x10,%eax      # 置段选择符(使ds,es,fs指向gdt表中的数据段)
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	pushl $int_msg       # 把调用 printk 函数的参数指针(地址)入栈
	call _printk         # 该函数在/kernel/printk.c中, '_printk' 是 printk编译后模块中的内部表示法
	popl %eax            # 清理参数
	pop %fs
	pop %es
	pop %ds
	popl %edx           # 出栈
	popl %ecx           # 出栈
	popl %eax           # 出栈
	iret

# iret（Interrupt Return）指令是用于处理中断和异常的汇编指令，它用于从中断或异常处理程序中返回到被中断的程序。iret指令会影响以下寄存器并执行以下操作：
# EFLAGS寄存器：iret指令会从堆栈中弹出EFLAGS寄存器的值，并将其还原到EFLAGS寄存器中。EFLAGS寄存器包含了一些标志位，例如进位标志、溢出标志、零标志等，
# 用于控制程序的执行和处理条件码。
# CS寄存器：iret指令会从堆栈中弹出CS寄存器的值，并将其还原到CS寄存器中。CS寄存器是代码段寄存器，它指示了CPU应该执行的代码段。
# EIP寄存器：iret指令会从堆栈中弹出EIP寄存器的值，并将其还原到EIP寄存器中。EIP寄存器是指令指针寄存器，它指示了CPU应该执行的下一条指令的地址。
# SS寄存器：在某些体系结构中，iret指令也会从堆栈中弹出SS寄存器的值，并将其还原到SS寄存器中。SS寄存器是堆栈段寄存器，它指示了CPU应该使用的堆栈段。
# 作用：
# iret指令的主要作用是将控制从中断或异常处理程序返回到被中断的程序。在执行iret之后，CPU会继续执行被中断程序的指令，恢复被中断程序的上下文，
# 包括程序计数器（EIP）和标志寄存器（EFLAGS）。这使得操作系统能够在处理完中断或异常后将执行流程返回给应用程序或内核的适当位置，实现平滑的中断处理和任务切换。


/*
 * Setup_paging
 *
 * This routine sets up paging by setting the page bit
 * in cr0. The page tables are set up, identity-mapping
 * the first 16MB. The pager assumes that no illegal
 * addresses are produced (ie >4Mb on a 4Mb machine).
 *
 * NOTE! Although all physical memory should be identity
 * mapped by this routine, only the kernel page functions
 * use the >1Mb addresses directly. All "normal" functions
 * use just the lower 1Mb, or the local data space, which
 * will be mapped to some other place - mm keeps track of
 * that.
 *
 * For those with more memory than 16 Mb - tough luck. I've
 * not got it, why should you :-) The source is here. Change
 * it. (Seriously - it shouldn't be too difficult. Mostly
 * change some constants etc. I left it at 16Mb, as my machine
 * even cannot be extended past that (ok, but it was cheap :-)
 * I've tried to show which constants to change by having
 * some kind of marker at them (search for "16Mb"), but I
 * won't guarantee that's all :-( )
 */

# 这个子程序通过设置控制寄存器cr0的标志(PG位31)来启动对内存的分页处理功能, 并设置各个页表项的内容,以恒等映射前 16MB 的物理内存.
# 分页器假定不会产生非法的地址映射(也即在只有 4MB的机器上设置出大于 4MB的内存地址)
# 注意! 尽管所有的物理地址都应该有这个子程序进行恒等映射,但只有内核页面管理函数能直接使用>1MB的地址.所有"一般"函数仅使用低于1MB的地址空间,
# 或者是使用局部数据空间,地址空间将被映射到其它一些地方去 -- mm(内存管理程序)会管理这些事. 对于那些有多余 16MB 内存的家伙 - 真是太幸运了,我还没有
# 为什么你会有呢? 代码就在这里,对它进行修改吧.(实际上,这并不太困难的.通常只需修改一些常数等.我把它设置为16MB,因为我的机器再怎么扩充甚至不能超过这个
# 界限(当然,我的机器是很便宜的).我已经通过设置某些标志来给出需要改动的地方(搜索16mb),当我不能保证作这些改动就行了.

# 在内存物理地址0x0处开始存放1页页目录表和4页页表.页目录表是系统所有进程公用的,而这里的4页页表则是属于内核专用的.对于新的进程,系统会在主内存区为其申请
# 页面存放的页表. 1页内存长度是 4096 字节.

.align 2                # 内存地址2字节的2次幂对齐内存,即4字节内存对齐
setup_paging:           # 首先对 5 页内存(1页目录+4页页表)清零
	movl $1024*5,%ecx		/* 5 pages - pg_dir+4 page tables */
	xorl %eax,%eax
	xorl %edi,%edi			/* pg_dir is at 0x000 */  # 页目录从 0x0000地址开始
	cld;rep;stosl       # 这三个汇编指令通常一起使用，用于在x86汇编中进行内存操作，如从源到目标的复制。下面是它们的含义：
					    # cld：这是 "Clear Direction Flag" 的缩写。cld 指令用于清除方向标志寄存器 DF（Direction Flag）。当 DF 被清除时，字符串操作
						# （如 stos 和 movs）将从低地址向高地址移动数据，这是默认的方向。这通常用于设置字符串操作的方向，以确保数据按照从源到目标的方向进行操作。
				        # rep：这是 "Repeat" 的缩写。rep 前缀通常与字符串操作指令一起使用，以实现重复执行这些操作的功能。例如，rep stosl 表示重复执行 stosl 指令，
						# 直到 ecx 寄存器的值变为零，即重复执行 stosl 指令 ecx 次。
						# stosl：这是 "Store String to Destination" 的缩写。stosl 指令用于将数据从 eax 寄存器存储到目标地址，目标地址由 edi 寄存器指定,
						# 并根据 DF 寄存器的设置，递增或递减目标地址。通常，stosl 用于将 eax 中的数据写入内存中的目标地址，然后根据方向标志 DF 决定目标地址的递增
						# 或递减。这组指令通常用于执行字符串或数组的复制或填充操作，其中 cld 用于设置方向，rep 用于重复执行字符串操作，而 stosl（或类似的指令）
						# 用于实际的数据传输。这是一种高效的方式来执行大量数据的复制或初始化操作。

	# 下面 4 句设置页目录表中的项,因为我们(内核)共有4个页表,所以只需设置 4项.
	# 页目录项的结构与页表中项的结构一样, 4 个字节为1项目.
	# "$pg0+7"表示: 0x00001007,是页目录表中的第1项
	# 则第1个页表所在的地址 = 0x00001007 & 0xfffff000 = 0x1000 

	# 一个页表有1024项,内核中一共有4个页表共4096项目. 一个项能映射4K内存,那么4096项共可映射16MB的内存空间
	# 从后往前填写页表
	movl $pg0+7,_pg_dir		/* set present bit/user r/w */     
	movl $pg1+7,_pg_dir+4		/*  --------- " " --------- */
	movl $pg2+7,_pg_dir+8		/*  --------- " " --------- */
	movl $pg3+7,_pg_dir+12		/*  --------- " " --------- */

	# 下面 6 行填写4个页表中所有项的内容,共有:4页表*1024(项/页表)=4096项目(0-0xfff),
	# 也即能映射物理内存 4096*4kb = 16MB 
	# 每项的内容是: 当前项所映射的物理内存地址 + 该页的标志(这里均为7)
	# 使用的方法是从最后一个页表的最后一项开始按倒序填写.一个页表的最后一项在页表总的位置是1023*4 = 4092. 因此最后
	# 一页的最后一项的位置就是 $page3+4092
	movl $pg3+4092,%edi                                            # 最后一页的最后一项
	movl $0xfff007,%eax		/*  16Mb - 4096 + 7 (r/w user,p) */    # 最后一页最后一项对应的物理内存的页面地址是0xfff000, 加上属性标志7,即0xfff007
	std                                                            # 方向置位, edi值递减(4字节)
1:	stosl			/* fill pages backwards - more efficient :-) */ # 这里 edi指向的是页表的最后一项,循环向前填写,将页表初始化
	subl $0x1000,%eax                                              # 每填写好一项,物理地址值减0x1000(4k),一个页表项寻址4k空间
	jge 1b                                                         # 如果小于0,则说明全部填写好了
	# 设置页目录基地址寄存器 cr3 的值,指向页目录表
	xorl %eax,%eax		/* pg_dir is at 0x0000 */                  # 页目录表在内存 0x0000处
	movl %eax,%cr3		/* cr3 - page directory start */           # 设置控制寄存器 cr3的值, cr3的值为0,表示页目录在0x0000处
	# 设置启动使用分页处理(cr0的PG标志,位31)
	movl %cr0,%eax
	orl $0x80000000,%eax    # 0x8000 0000 二进制的第31位是1, 与 eax进行或操作,结果存在 eax中,强制让31位为1
	movl %eax,%cr0		/* set paging (PG) bit */   # cr0 的31 为1,表示启动分页处理了
	ret			/* this also flushes prefetch-queue */

#  在改变分页处理标志后要求使用转移指令刷新预取指令队列,这里用的是返回指令ret.
# 该返回指令的另一个作用是将堆栈中的main程序的地址弹出,并开始运行/init/main.c程序的
# 本程序到此就真正结束了


.align 2                # 按照4字节方式对齐内存地址边界
.word 0
idt_descr:              # 下面两行是lidt指令的6字节操作数:长度,基址
	.word 256*8-1		# idt contains 256 entries  # 共256个表项,每个表项8字节
	.long _idt          # 基地址
.align 2                
.word 0
gdt_descr:              # 下面两行是lgdt指令的6字节操作数:长度,基地址
	.word 256*8-1		# so does gdt (not that that's any # not -> note
	.long _gdt		# magic number, but it works for me :^)

	.align 3            # 按照8字节的方式对齐内存边界
_idt:	.fill 256,8,0		# idt is uninitialized    这里是idt表的基地址, 256项目,每项8字节, 填0

# 全局描述符表. 前4项分别是空项(不用), 代码段描述符,数据段描述符,系统段描述符,其中系统段描述符linux没有派用处.
# 后面还预留了252 项的空间,用于放置所创建任务的局部描述符LDT和对应的任务状态段TSS的描述符
# (0=nul, 1=cs, d-ds, 3-sys, 4-TSS0, 5-LDT0, 6-TSS1, 7-LDT1, 8-TSS2 etc...)
# 在汇编语言中，.quad 是一种用于定义一个64位（8字节）整数或地址的伪指令（pseudo-instruction）。
# .quad 通常用于声明数据或分配内存空间，以存储一个64位的整数值或一个地址。
_gdt:	
    .quad 0x0000000000000000	/* NULL descriptor */
	.quad 0x00c09a0000000fff	/* 16Mb */    # 0x08, 内核代码段最大长度 16M
	.quad 0x00c0920000000fff	/* 16Mb */    # 0x10, 内核数据段最大长度 16M
	.quad 0x0000000000000000	/* TEMPORARY - don't use */
	.fill 252,8,0			/* space for LDT's and TSS's etc */

# 一个GDT段描述符占用8个字节，包含三个部分：
# 段基址（32位），占据描述符的第16～39位和第55位～63位，前者存储低16位，后者存储高16位
# 段界限（20位），占据描述符的第0～15位和第48～51位，前者存储低16位，后者存储高4位。
# 段属性（12位），占据描述符的第39～47位和第49～55位，段属性可以细分为8种：TYPE属性、S属性、DPL属性、P属性、AVL属性、L属性、D/B属性和G属性。
# 原文链接：https://blog.csdn.net/abc123lzf/article/details/109289567