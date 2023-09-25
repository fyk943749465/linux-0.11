!
!	setup.s		(C) 1991 Linus Torvalds
!
! setup.s is responsible for getting the system data from the BIOS,
! and putting them into the appropriate places in system memory.
! both setup.s and system has been loaded by the bootblock.
!
! This code asks the bios for memory/disk/other parameters, and
! puts them in a "safe" place: 0x90000-0x901FF, ie where the
! boot-block used to be. It is then up to the protected mode
! system to read them from there before the area is overwritten
! for buffer-blocks.
!
! setup.s 负责从 BIOS 中获取系统数据,并将这些数据放到系统内存的适当地方.
! 此时 setup.s 和 system 已经由 bootsect 引导块加载到内存中.
!
! 这段代码询问 bios 有关内存/磁盘/其他参数,并将这些参数放到一个"安全的"地方:0x90000 - 0x901FF,
! 也即原来 bootsect 代码块曾经在的地方,然后在被缓冲块覆盖掉之前,由保护模式的 System 读取

! NOTE! These had better be the same as in bootsect.s!
! 注意,以下这些参数最好和 bootsect.s 中的相同!

INITSEG  = 0x9000	! we move boot here - out of the way          ! 原来 bootsect 所处的段
SYSSEG   = 0x1000	! system loaded at 0x10000 (65536).           ! system 在 0x10000(64k)处
SETUPSEG = 0x9020	! this is the current segment                 ! 本程序所在的段地址

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

entry start
start:

! ok, the read went well so we get current cursor position and save it for
! posterity.
! ok, 整个读磁盘过程都正常,现在将光标位置保存以备今后使用.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax                             ! 将ds置成#INITSEG(0x9000).这已经在bootsect程序中设置过,但是现在是setup程序,linus觉得需要再重新设置一下.
	mov	ah,#0x03	! read cursor pos     ! BIOS 中断 0x10 的读光标功能号 ah = 0x03
	xor	bh,bh                             ! 输入: bh = 页号
	int	0x10		! save it in known place, con_init fetches   ! 0x10 中断
	mov	[0],dx		! it from 0x90000.    ! 将列号存放再 ds:0 处

										!	在 x86 架构的计算机上，使用 0x10 中断来访问BIOS（Basic Input/Output System）的功能，
										!   其中 ah 寄存器的值为 0x03 用于查询光标位置。
										!	具体而言，当 ah 的值为 0x03 时，int 0x10 中断会返回以下信息：
										!	ah 寄存器中包含 0x03，表示功能号，用于查询光标位置。
										!	bh 寄存器中包含当前光标的页码（page number），通常为0。
										!	cx 寄存器中包含当前光标的行坐标（Y坐标），以0开始的数值。
										!	dh 寄存器中包含当前光标的列坐标（X坐标），以0开始的数值。
										!	因此，当你执行 int 0x10 中断并设置 ah 寄存器的值为 0x03 后，
										!   你可以通过读取 bh、cx 和 dh 寄存器来获取当前文本模式下的光标位置信息。

! Get memory size (extended mem, kB)
						   ! 下面3句取扩展内存的大小值(KB).是调用中断 0x15,功能号 ah=0x88
						   ! 返回: ax = 从0x100000 (1M) 处开始的扩展内存大小(KB).
						   ! 若出错则CF置位, ax = 出错码

	mov	ah,#0x88
	int	0x15
	mov	[2],ax             ! 将扩展内存数值存放在 0x90002 处(1个字,即2个字节) ,如果0x15号中断查询失败,ax寄存器的低字节al中包含错误代码

! Get video-card data:
						   ! 下面这段用于取显示卡当前显示模式. 调用 BIOS 中断 0x10,功能号 ah=0x0f 
						   ! 返回: ah = 字符列数, al = 显示模式, bh = 当前显示页
						   ! 0x90004(1字节存放当前页), 0x90006 显示模式  0x90007 字符列数 

	mov	ah,#0x0f		
	int	0x10
	mov	[4],bx		! bh = display page                      ! 存放当前页
	mov	[6],ax		! al = video mode, ah = window width     ! 存放显示模式和字符列数

! check for EGA/VGA and some config parameters
					! 检查显示方式(EGA/VGA)并取参数
					! 调用 BIOS 中断 0x10, 附件功能选择 - 取方式信息
					! 功能号: ah = 0x12, bl = 0x10
					! 返回: bh = 显示状态 (0x00 - 彩色模式, I/O 端口=0x3dX)
					!                     (0x01 - 单色模式, I/O 端口=0x3bX)
					! bl = 安装的显示内存
					! (0x00 64k, 0x01 128k, 0x02 192k, 0x03 256k)
					! cx = 显示卡特性参数

					! 在 x86 架构的计算机中，0x10 中断用于访问 BIOS（Basic Input/Output System）的功能。
					! 当 ah 寄存器的值为 0x12 时，表示要查询VGA（Video Graphics Array）或SVGA（Super VGA）显示模式信息。
					! 具体而言，如果 ah 寄存器的值为 0x12，并且 bl 寄存器的值为 0x10，则表示查询当前VGA或SVGA显示模式的信息。返回的信息通常包括：
					! ah 寄存器的值：表示操作是否成功。如果成功，ah 寄存器的值为 0x12，否则为其他值，表示错误。
					! al 寄存器的值：表示当前的VGA或SVGA显示模式编号。
					! 其他寄存器的值：根据不同的BIOS实现和硬件情况，可能会包含其他显示模式的信息，如分辨率、颜色深度等。
					! 通过查询当前显示模式的信息，您可以了解当前计算机的图形显示设置，这对于编写与图形显示相关的程序或调整显示设置非常有用。

	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax      ! 内存单元 0x90008 显示中断操作的状态
	mov	[10],bx     ! 内存单元 0x9000A = 安装的显示内存 / 0x9000B = 显示状态(彩色/单色)
	mov	[12],cx     ! 内存单元 0x9000C = 显示卡特性参数


		! 硬盘参数表（Hard Disk Parameter Table）是个人计算机（PC）的基本输入/输出系统（BIOS）中的一个数据结构，用于存储关于硬盘（通常是固态硬盘或机械硬盘）
		! 的基本信息和参数。这些信息包括硬盘的容量、几何结构、磁道数、扇区数、每磁道扇区数等。
		! 在早期的个人计算机系统中，BIOS会在启动过程中检测硬盘并读取硬盘参数表，以了解硬盘的特性和配置。这些参数对于BIOS和操作系统来说都是重要的，
		! 因为它们决定了如何正确地访问和管理硬盘上的数据。
		! 关于 int 0x41 中断向量位置存放硬盘参数表的情况，这是正确的。在一些PC BIOS实现中，特别是早期的PC系统中，int 0x41 中断向量位置被用来存放
		! 第一个硬盘的基本参数表。这个参数表包含了硬盘的几何信息，如磁头数、柱面数、每磁道扇区数等。操作系统和应用程序可以使用这些参数来正确地访问硬盘上的数据。
		! 请注意，这种方法是比较古老的做法，现代操作系统和硬件通常使用更复杂的方式来管理硬盘，而不仅仅依赖于BIOS中的硬盘参数表。但在一些旧的PC系统中，
		! 仍然可能会使用这种方式来访问硬盘信息。不同的BIOS和操作系统可能会有不同的实现方式，因此具体情况可能会有所不同。

! Get hd0 data
					! 取第一个硬盘的信息(复制硬盘参数表)
					! 第1个硬盘参数表的首地址竟然是中断向量 0x41的向量值! 而第2个硬盘参数表紧接着第1个表的后面,中断向量0x46的向量值也指向这第2个硬盘的参数表首地址.
					! 表的长度是 16 个字节(0x10). 下面两段程序分别复制 BIOS 有关两个硬盘的参数表, 0x90080 处存放第1个硬盘的表, 0x90090处存放第2个硬盘的表.
	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x41] ! 在汇编语言中，lds 指令用于将一个指定的内存地址的数据加载到一个段寄存器中，同时将该地址的段选择子加载到指定的通用寄存器中。
					! x86 32位模式下,一个中断向量占4字节的存储空间, 所以现在是取 0x41中断向量的 段地址和偏移地址.
					! 在x86架构的计算机系统中，0x41 对应的中断向量通常用于系统调用（System Call）。系统调用是一种机制，
					! 允许用户空间的应用程序请求操作系统内核提供特定的服务或功能。这些服务包括文件操作、进程管理、网络通信等。
					! 具体的系统调用和功能会因操作系统而异，但通常它们由操作系统提供，并通过中断来触发。0x41 可以被视为一个示例中断向量，表示一个特定的系统调用。
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0080  ! 传输的目的地址 0x9000:0x0080 -> es:di 
	mov	cx,#0x10    ! 循环次数 16次  将 ds:si 指向的 16 字节传输给 es:di
	rep              
	movsb

! Get hd1 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x46]  ! 取中断向量 0x46的值,也即 hd1 参数表的地址 -> ds:si
	mov	ax,#INITSEG  
	mov	es,ax
	mov	di,#0x0090   ! 传输的目的地址: 0x9000:0x0090 -> es:di 
	mov	cx,#0x10
	rep
	movsb

! Check that there IS a hd1 :-)
						! 检查系统是否存在第2个硬盘,如果不存在则第2个表清零.
						! 利用BIOS 中断调用 0x13 的去盘类型功能.
						! 功能号 ah = 0x15 
						! 输入: dl = 驱动号(0x8X是硬盘, 0x80 指第一个硬盘, 0x81 指第二个硬盘)
						! 输出: ah = 类型码; 00 --没有这个盘 CF 置位; 01 --是软驱,没有 change-line支持;
						!                     02 --是软驱(或其他可移动设备), 有 change-line 支持; 03 -- 是硬盘

	mov	ax,#0x01500
	mov	dl,#0x81
	int	0x13
	jc	no_disk1        ! 如果有进位,CF=1,表示没有第二课硬盘
	cmp	ah,#3           ! 检查是否是硬盘
	je	is_disk1        ! 如果是硬盘,则执行 is_disk1
no_disk1:               ! 如果没有第2块硬盘,则对第2个硬盘表清零
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	mov	ax,#0x00
	rep
	stosb               ! stosb 指令用于将 AL 寄存器中的字节数据存储到目标地址，并根据方向标志位的设置来控制操作方向 es:si 是目标位置
is_disk1:

! now we want to move to protected mode ...                  ! 现在操作系统即将进入保护模式

	cli			! no interrupts allowed !

! 汇编语言中的 cli 指令是一个控制指令，它的含义是 "clear interrupt flag"，即清除中断标志位。
! 这个指令用于禁用中断处理器，阻止CPU响应所有中断请求，包括外部硬件中断和内部中断。
! 当执行 cli 指令时，它会将CPU的中断标志位（IF，Interrupt Flag）设置为 0，从而禁用中断。这意味着，
! 即使有外部中断请求（如硬件中断、时钟中断等），CPU也不会响应这些中断请求，直到中断标志位被重新设置为 1（使用 sti 指令）以启用中断处理器。
! cli 和 sti 指令通常在操作系统内核中用于管理中断处理。例如，在操作系统的关键性代码段中，可能会使用 
! cli 来关闭中断，以确保临界区代码能够原子执行，而在临界区代码结束后使用 sti 来重新启用中断。
! 总之，cli 指令用于禁用中断处理器，阻止CPU响应中断请求，而 sti 指令用于重新启用中断处理器，允许CPU响应中断请求。
! 这些指令在多任务操作系统和临界区代码的实现中非常有用。

! first we move the system to it's rightful place

! 首先我们将 system 模块移动到正确的位置. bootsect 引导程序是将 system 模块读入到从 0x10000(64k) 开始的位置.由于当时假设 system 模块最大长度不会超过 0x80000(512k)
! 也即其末端不会超过内存地址 0x90000, 所以bootsect 会将自己移动到 0x90000 开始的地方,并把 setup 加载到它的后面.
! 下面这段程序的用途是把整个 system 模块移动到 0x00000 位置,即把从0x10000 到0x8ffff的内存数据块(512k),整块地向内存低端
! 移动了 0x10000(64k)的位置

	mov	ax,#0x0000
	cld			! 'direction'=0, movs moves forward   ! DF = 0 向前偏移 即 si di 值增加, DF=1 向后偏移, si di值减小
													  ! 在汇编语言中，cld 是 x86 指令，它的含义是 "Clear Direction Flag"，
													  ! 即清除方向标志位。这个方向标志位（DF，Direction Flag）通常用于字符串操作指令，如 movsb、movsw、movsd、lodsb 等。
													  ! 方向标志位（DF）可以有两个状态：
													  ! 如果 DF 被设置为 1，表示字符串操作指令应该递减源地址和目标地址，即向低地址方向进行操作。
													  ! 如果 DF 被设置为 0，表示字符串操作指令应该递增源地址和目标地址，即向高地址方向进行操作（这是默认状态）。
do_move:
	mov	es,ax		! destination segment   ! es:di -> 目的地址(初始为 0x0000:0x0)
	add	ax,#0x1000
	cmp	ax,#0x9000                          ! 判断是否已经把从 0x8000 段开始的 64k 代码移动完了
	jz	end_move                            ! 根据 zero flag 位来进行跳转, zf=1,跳转,表示前面操作的结果是0,即ax与0x9000相等.
	mov	ds,ax		! source segment        ! 数据还没有赋值完成,执行下面的代码
	sub	di,di
	sub	si,si
	mov 	cx,#0x8000                      ! 移动 0x8000字(64k字节)
	rep
	movsw
	jmp	do_move

! then we load the segment descriptors

! 此后,我们会加载段描述符. 从这里开始会遇到 32 位保护模式的操作,因此需要 Intel 32 位保护模式编程方面的知识了.
! 有关这方面的信息清查阅列表后的简单介绍或附录中的详细说明.这里仅做概要说明.
! 再进入保护模式中运行之前, 我们需要首先设置好需要使用的段描述符表.这里需要设置全局描述符表和中断描述符表.

! lidt 指令用于加载中断描述符表(idt)寄存器,它的操作数是6个字节:
!  0-1字节是描述符表的长度值(字节)
!  2-5字节是描述符表的32位线性基地址
! 中断描述符表中的每一表项(8字节)指出发生中断时需要调用的代码的信息,与中断向量有些相似,但要包含跟多的信息.

! ldgt 指令用于加载全局描述符表(gdt)寄存器,其操作数格式与lidt指令相同.全局描述符表中的每个描述项(8字节)描述了
! 保护模式下数据和代码段(块)的信息.其中包括段的最大长度限制(16位), 段的线性地址(32位),段的特权级,段是否再内存
! 读写许可以及其它一些保护模式运行的标志.

end_move:
	mov	ax,#SETUPSEG	! right, forgot this at first. didn't work :-)   
	mov	ds,ax                                                  ! ds指向本程序段
	lidt	idt_48		! load idt with 0,0                    ! 加载中断描述符表(idt)寄存器,idt_48 是6字节操作数的位置,
															   ! 前 2 字节表示 idt 表的限长, 后 4 字节表示 idt 表所处的基地址
															   ! 在这条指令中，idt_48 是一个标号（label）或地址，它指向了要加载到 IDT 寄存器
															   ! 中的 IDT 表的起始地址。这个标号通常是汇编代码中定义的一个符号，用于表示 IDT 表的位置。
															   ! 具体来说，lidt 指令的含义是加载 IDT 寄存器的值。IDT 寄存器存储了用于处理中断和异常的中断
															   ! 描述符表的地址。加载 IDT 寄存器的操作是为了告诉处理器在发生中断或异常时应该去查找哪个中断描述符来执行相应的处理程序。
	lgdt	gdt_48		! load gdt with whatever appropriate   ! 加载全局描述符表(gdt)寄存器, gdt_48 是 6 字节操作数的位置

! that was painless, now we enable A20 
										    ! 以上操作很简单,现在我们开启 A20 地址线. 参见程序列表后有关 A20 信号线说明
											! 关于所涉及到的一些端口和命令,可参考 kernel/chr_drv/keyboard.S 程序后对键盘接口的说明.

	call	empty_8042
	mov	al,#0xD1		! command write     ! 0xD1 命令码 - 表示要写数据到 8042 的 P2 端口.
	out	#0x64,al                            ! 向端口 0x64 发送 0xD1
	call	empty_8042                      ! 测试读缓冲区是否为空,看命令是否被接受
	mov	al,#0xDF		! A20 on            ! 选通 A20 地址线的参数
	out	#0x60,al
	call	empty_8042                      ! 输入缓冲区为空,则表示 A20 线已经选通

! well, that went ok, I hope. Now we have to reprogram the interrupts :-(
! we put them right after the intel-reserved hardware interrupts, at
! int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
! messed this up with the original PC, and they haven't been able to
! rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
! which is used for the internal hardware interrupts as well. We just
! have to reprogram the 8259's, and it isn't fun.


! 希望以上一切正常. 现在我们必须重新对中断进行编程
! 我们将他们放在正好处于 intel 保留的硬件中断后面, int 0x20-0x2F 
! 在那里我们不会引起冲突.不幸的时 IBM 在原 PC机中搞糟了, 以后也没纠正过来.
! PC 机的 bios 将中断放在了 0x08-0x0f, 这些中断也被用于内部硬件中断.
! 所以我们就必须重新对 8259 中断控制器进行编程,这一点没劲.

! Intel 8259A（或简称8259）是一款广泛用于早期个人计算机（PC）和其他计算机系统中的可编程中断控制器（PIC）芯片。
! 它的主要功能是处理中断请求（IRQ）并进行中断控制，允许计算机系统对外部设备的中断请求进行管理和响应。
! 以下是一些关于8259A芯片的主要特点和功能：
! 中断控制：8259A允许计算机系统同时连接多个外部设备，每个设备都可以触发中断请求。芯片负责协调这些中断请求，并按优先级分配中断处理。
! 可编程性：8259A是可编程的，这意味着系统设计者可以配置它来处理特定的中断需求。它具有8个中断请求线（IRQ0至IRQ7），
! 可以与外部设备连接，而且这些IRQ可以通过编程映射到不同的中断向量（中断处理程序）。
! 级联模式：当需要更多的IRQ线时，8259A支持级联模式。这意味着多个8259A芯片可以级联在一起，以扩展中断处理的能力。
! 这种级联配置通常在早期PC中使用，以支持更多的外部设备。
! 屏蔽中断：8259A允许对每个IRQ进行屏蔽，这意味着系统可以选择性地禁用或启用特定的中断源。这对于系统的稳定性和性能非常重要。
! 中断嵌套：8259A支持中断嵌套，这意味着一个中断处理程序可以在另一个中断处理程序的上下文中执行。这对于处理紧急中断和高优先级中断非常有用。
! EOI（End of Interrupt）：当8259A完成对中断的处理后，它会发送一个EOI信号，通知CPU中断已被处理完毕，CPU可以继续正常执行程序。
! 8259A芯片在早期的PC和兼容机中扮演了重要的角色，但随着计算机架构的发展，它的功能被更先进的中断控制器所取代。
! 现代计算机通常使用APIC（高级可编程中断控制器）来管理中断，但8259A仍然具有历史重要性，因为它是早期PC硬件的一部分，对于理解计算机系统的发展历史具有重要意义。



	mov	al,#0x11		! initialization sequence            ! 0x11 表示初始化命令开始, 是ICW1命令字,表示边缘触发,多片8259级联,最后要发送ICW4命令字
	out	#0x20,al		! send it to 8259A-1                 ! 发送到 8259A 主芯片

! 下面定义的两个字是直接使用机器码表示的两条相对跳转指令,起延时作用.
! 0xeb 是直接近跳转指令的操作码,带1个字节的相对偏移值.因此跳转范围是-127到127. CPU通过把这个相对偏移值加到 EIP 寄存器
! 中就形成了一个新的有效地址. 此时 EIP 指向下一条被执行的指令. 执行是所划分的 CPU 时钟周期数是7至10个. 0x00eb 表示跳转
! 值是0的一条指令,因此还是直接执行下一条指令. 这两条指令功课提供14-20个CPU时钟周期的延时时间. 在as86中没有表示相应指令
! 的助记符,因此 Linus 在 setup.s 等一些汇编程序中就直接使用机器码来表示这种指令. 另外, 每个空操作指令 NOP 的时钟周期数
! 是3个, 因此若要达到相同的延迟效果就需要6至7个NOP指令 
	.word	0x00eb,0x00eb		! jmp $+2, jmp $+2           ! $ 表示当前指令的地址
	out	#0xA0,al		! and to 8259A-2                     ! 发送到8259A从芯片(0x11)
	.word	0x00eb,0x00eb
	mov	al,#0x20		! start of hardware int's (0x20)     ! 送主芯片 ICW2 命令字,起始中断号,要送奇地址.
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x28		! start of hardware int's 2 (0x28)   ! 送从芯片 ICW2 命令字,从芯片的起始中断号
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x04		! 8259-1 is master                   ! 送从主芯片 ICW3 命令字, 主芯片的 IR2 连从芯片 INT
	out	#0x21,al
	.word	0x00eb,0x00eb     
	mov	al,#0x02		! 8259-2 is slave                    ! 送从芯片 ICW3 命令字, 表示从芯片的INT连到主芯片的IR2引脚上
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x01		! 8086 mode for both                 ! 送主芯片 ICW4 命令字. 8086 模式; 普通 EOI 方式,需要发送指令来复位,初始化结束,芯片就绪.
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al                                             ! 送从芯片 ICW4 命令字
	.word	0x00eb,0x00eb
	mov	al,#0xFF		! mask off all interrupts for now
	out	#0x21,al                                             ! 屏蔽主芯片上所有中断请求
	.word	0x00eb,0x00eb
	out	#0xA1,al                                             ! 屏蔽从芯片上所有中断请求

! well, that certainly wasn't fun :-(. Hopefully it works, and we don't
! need no steenking BIOS anyway (except for the initial loading :-).
! The BIOS-routine wants lots of unnecessary data, and it's less
! "interesting" anyway. This is how REAL programmers do it.

! 哼,上面这段当然没劲, 希望这样能工作, 而且我们也不再需要乏味的 BIOS了(除了初始化的加载)
! BIOS 子程序要求很多不必要的数据,而且它一点都没趣.那是"真正"的程序员所做的事.
!
! Well, now's the time to actually move into protected mode. To make
! things as simple as possible, we do no register set-up or anything,
! we let the gnu-compiled 32-bit programs do that. We just jump to
! absolute address 0x00000, in 32-bit protected mode.

! 这里设置进入32位保护模式运行, 首先加载机器状态字,也称控制寄存器CR0,其他比特为0置1将导致
! CPU 工作在保护模式.

! lmsw 是x86汇编语言中的一条指令，它的含义是 "Load Machine Status Word"，即加载机器状态字。这个指令用于加载新的控制寄存器的值，以更改处理器的系统状态。
! 具体来说，lmsw 指令通常用于修改控制寄存器 CR0 的某些位，以控制处理器的运行模式或设置特定的系统状态。CR0 是一个重要的控制寄存器，包含了多个位，
! 每个位都用于控制处理器的不同特性和模式。
! lmsw 指令的操作数通常是一个内存地址，指向一个16位的机器状态字（Machine Status Word）。这个机器状态字中的位对应于控制寄存器 CR0 的特定位，
! 通过加载这个机器状态字，可以修改这些位的值。
! 在使用 lmsw 指令时，通常需要谨慎，因为修改控制寄存器的值可能会对系统的整体行为产生重大影响。这通常是操作系统内核或低级系统软件的任务，
! 用于管理和控制处理器的运行模式和特性。
! 总结一下，lmsw 指令的主要含义是加载一个新的机器状态字，用于修改控制寄存器 CR0 的特定位，以更改处理器的系统状态和特性。这是一项高级操作，需要小心谨慎地使用。

! 在x86体系结构中，控制寄存器（Control Registers）是用于控制和配置处理器行为的一组寄存器。最常见的控制寄存器是CR0、CR2、CR3和CR4。这些寄存器允许操作系统和系统软件来管理和控制处理器的运行模式、内存分页、缓存、系统调试和其他关键系统功能。
! CR0（Control Register 0）：CR0 是最重要的控制寄存器之一。它包含了多个位，用于控制处理器的基本运行模式和特性。一些重要的位包括：
! 最低位（PE）：启用或禁用保护模式。在保护模式下，处理器运行在较为安全和受保护的操作系统环境中。
! 第五位（PG）：启用或禁用分页机制。分页是用于虚拟内存管理的重要特性。
! 第十七位（NE）：启用或禁用数学协处理器错误异常。
! 其他位用于控制缓存、监视、任务切换和系统管理等。
! CR1（Control Register 1）：CR1 并不存在于x86架构中。在早期的x86处理器中，确实存在CR1，但它在后来的架构中已经被废弃，不再使用。因此，在较新的x86架构中，没有CR1寄存器。
! CR2（Control Register 2）：CR2 包含当前的页目录表地址。在分页模式下，它用于存储当前正在使用的页目录表的地址。
! CR3（Control Register 3）：CR3 包含页表根地址（Page Table Base Address）。它指向页表的根，用于虚拟地址到物理地址的转换。CR3也用于启用和禁用分页机制。
! CR4（Control Register 4）：CR4 包含了一些处理器的控制标志位，用于启用或禁用一些高级特性，如物理地址扩展（PAE）、全速浮点异常（FPE）、虚拟化（VT-x）等。
! 需要注意的是，这些控制寄存器的含义和位的配置可能会因处理器的不同架构而有所不同。不同的x86处理器系列和架构版本可能支持不同的特性和位。因此，在编写系统软件或内核时，需要根据目标处理器的规格文档来了解各个控制寄存器的确切含义和功能。

	mov	ax,#0x0001	! protected mode (PE) bit               ! 保护模式比特位(PE)
	lmsw	ax		! This is it!                           ! 就这样加载机器状态字 (启用保护模式)
	jmpi	0,8		! jmp offset 0 of segment 8 (cs)        ! 跳转到cs段8,偏移0处

! 我们已经将 system  模块移动到了 0x00000 开始的地方,所以这里的偏移地址是0, 这里的段地址值8 已经是保护模式下的段选择符了,
! 用于选择描述符表和描述符项已经所要求的特权级. 段选择符长度为16(2字节); 
! 位0-1表示请求的特权级 0-3, linux系统只用到了两级:0级和3级;
! 位2用于选择全局描述符表(0)还是局部描述符表(1)
! 位3-15 是描述符表的索引,指出选择第几项描述符.
! 所以段选择符 8(0b0000,0000,0000,1000) 表示请求的特权级0,使用全局描述符表的第1项目,该项指出
! 代码的基地址是0, 因此这里的跳转指令就是去执行 system 中的代码.

! This routine checks that the keyboard command queue is empty
! No timeout is used - if this hangs there is something wrong with
! the machine, and we probably couldn't proceed anyway.


! 下面这个子程序检查键盘命令队列是否为空,这里不使用超市方法 - 如果这里死机,则说明PC机有问题,我们就没办法再处理下去了.
! 只有当输入缓冲区空闲是(状态寄存器位2=0),才可以对其进行写命令.
! 在 x86 汇编语言中，端口 0x64 是一个重要的 I/O 端口，通常用于与计算机的键盘控制器进行通信。键盘控制器是计算机硬件中的一个部分，负责管理键盘输入和发送键盘相关的命令和状态信息。
! 端口 0x64 用于向键盘控制器发送命令或读取状态信息。通过读取或写入这个端口，计算机可以执行以下操作：
! 发送命令给键盘控制器：计算机可以通过向端口 0x64 写入特定的命令字节，以要求键盘控制器执行特定的操作，如启用或禁用键盘、重置键盘等。
! 读取键盘控制器状态：计算机可以通过从端口 0x64 读取数据，获取键盘控制器的状态信息。这些状态信息通常包括键盘输入缓冲区是否有数据、键盘控制器是否准备好接受命令、键盘是否处于锁定状态（例如，Caps Lock、Num Lock、Scroll Lock）等。
! 接收来自键盘的数据：当计算机从键盘读取数据时，键盘通常将数据发送到端口 0x60，计算机可以通过读取端口 0x60 来接收来自键盘的按键数据。
! 总之，端口 0x64 在 x86 汇编中代表与键盘控制器的通信接口，通过该接口，计算机可以与键盘控制器进行交互，获取键盘状态、发送命令和接收键盘输入数据。


! 在计算机中，8042 是一个集成电路芯片，通常称为 "8042 键盘控制器" 或 "8042 控制器"。这个芯片在早期的PC硬件架构中扮演了关键的角色，负责处理键盘输入和与键盘通信。8042 控制器有一个状态寄存器，状态字节的各个位用于表示不同的状态和事件。在8042控制器的状态字节中，通常有以下含义：
! Bit 0 (IBF - Input Buffer Full)：这个位表示键盘输入缓冲区是否已满。如果IBF位为1，表示输入缓冲区已满，不能接受更多的键盘输入数据。如果IBF位为0，表示输入缓冲区为空，可以接受新的键盘输入。
! Bit 1 (OBF - Output Buffer Full)：这个位表示输出缓冲区是否已满。如果OBF位为1，表示输出缓冲区包含了可读取的键盘数据。如果OBF位为0，表示输出缓冲区为空，没有可读取的键盘数据。
! Bit 2 (Data)：这个位表示最后接收到的数据是来自键盘还是来自鼠标。如果Data位为0，表示数据来自键盘。如果Data位为1，表示数据来自鼠标。
! Bit 3 (Time Out)：这个位表示8042控制器的定时器是否超时。如果Time Out位为1，表示已发生超时。这个位通常与键盘通信的定时相关。
! Bit 4 (Parity Error)：这个位表示键盘输入数据的奇偶校验是否正确。如果Parity Error位为1，表示存在奇偶校验错误。
! Bit 5 (Receive Timeout)：这个位表示接收键盘数据时是否发生了超时。如果Receive Timeout位为1，表示接收数据时发生了超时。
! Bit 6 (General Error)：这个位表示一般错误，通常不常用。
! Bit 7 (Command Data)：这个位表示8042控制器的状态字节是否包含命令数据。如果Command Data位为1，表示状态字节包含命令数据。如果Command Data位为0，表示状态字节包含的是键盘数据。

empty_8042:
	.word	0x00eb,0x00eb                              ! .word 定义一个字数组,有两个元素. 这是两个跳转指令的机器码(跳转到下一句),相当于延时空操作, 
	in	al,#0x64	! 8042 status port                 ! 读 AT 键盘控制器状态寄存器
                                                       ! in al, #0x64 是x86汇编语言中的一条指令，它的含义是从I/O端口地址0x64读取一个字节数据，并将该数据存储在AL寄存器中。
													   ! 这个指令通常用于与计算机的键盘控制器进行通信。在x86架构中，0x64端口是与键盘控制器相关的I/O端口，通过读取这个端口，可以获取键盘控制器的状态和数据。
													   ! 在这个指令中：
													   ! in 是输入操作指令，用于从指定的I/O端口读取数据。
													   ! al 是x86架构中的8位累加器寄存器，它用于存储从I/O端口读取的数据。
													   ! #0x64 是指定要读取的I/O端口的地址，这里是0x64。
													   ! 执行这条指令后，AL寄存器中将包含来自0x64端口的一个字节数据，通常是与键盘控制器相关的状态信息或键盘输入数据。程序可以进一步分析和处理这个数据以实现键盘输入的功能或监视键盘控制器的状态。
	test	al,#2		! is input buffer full?        ! 测试是否还由数据可读
	jnz	empty_8042	! yes - loop                       ! 如果有数据可读,跳转后继续读取. 零标志位不等于1,则进行跳转
	ret                                                ! 键盘缓冲区没有可读数据,返回

! 全局描述符表开始处. 描述符表由多个 8 字节的描述符项组成.
! 这里给出了 3 个描述符项. 第 1 项无用, 但需存在.
! 第 2 项是系统代码段
! 第 3 项是系统数据段描述符,每个描述符的具体含义灿姐列表后说明.

gdt:
	.word	0,0,0,0		! dummy   ! 第一个描述符,不用
! 这里在 gdt 表中的偏移量是0x08,当加载代码段寄存器(段选择符)时,使用的是这个偏移值.
	.word	0x07FF		! 8Mb - limit=2047 (2048*4096=8Mb)   
	.word	0x0000		! base address=0
	.word	0x9A00		! code read/exec
	.word	0x00C0		! granularity=4096, 386
! 这里在 gdt 表中的偏移量是 0x10, 当加载数据段寄存器(如ds等)时,使用的时这个偏移值.
	.word	0x07FF		! 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		! base address=0
	.word	0x9200		! data read/write
	.word	0x00C0		! granularity=4096, 386

idt_48:
	.word	0			! idt limit=0
	.word	0,0			! idt base=0L

gdt_48:
	.word	0x800		! gdt limit=2048, 256 GDT entries    ! 全局表长度为2k字节,因为每8字节组成一个段描述符项,所以表中共有 256 项
	.word	512+gdt,0x9	! gdt base = 0X9xxxx                 ! 四个字节构成的内存线性地址: 0x0009<<16 + 0x0200 + gdt, 也即 0x90200 + gdt(即本程序段中的偏移地址)
	
.text
endtext:
.data
enddata:
.bss
endbss:
