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
	cld			! 'direction'=0, movs moves forward
do_move:
	mov	es,ax		! destination segment
	add	ax,#0x1000
	cmp	ax,#0x9000
	jz	end_move
	mov	ds,ax		! source segment
	sub	di,di
	sub	si,si
	mov 	cx,#0x8000
	rep
	movsw
	jmp	do_move

! then we load the segment descriptors

end_move:
	mov	ax,#SETUPSEG	! right, forgot this at first. didn't work :-)
	mov	ds,ax
	lidt	idt_48		! load idt with 0,0
	lgdt	gdt_48		! load gdt with whatever appropriate

! that was painless, now we enable A20

	call	empty_8042
	mov	al,#0xD1		! command write
	out	#0x64,al
	call	empty_8042
	mov	al,#0xDF		! A20 on
	out	#0x60,al
	call	empty_8042

! well, that went ok, I hope. Now we have to reprogram the interrupts :-(
! we put them right after the intel-reserved hardware interrupts, at
! int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
! messed this up with the original PC, and they haven't been able to
! rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
! which is used for the internal hardware interrupts as well. We just
! have to reprogram the 8259's, and it isn't fun.

	mov	al,#0x11		! initialization sequence
	out	#0x20,al		! send it to 8259A-1
	.word	0x00eb,0x00eb		! jmp $+2, jmp $+2
	out	#0xA0,al		! and to 8259A-2
	.word	0x00eb,0x00eb
	mov	al,#0x20		! start of hardware int's (0x20)
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x28		! start of hardware int's 2 (0x28)
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x04		! 8259-1 is master
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x02		! 8259-2 is slave
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x01		! 8086 mode for both
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0xFF		! mask off all interrupts for now
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al

! well, that certainly wasn't fun :-(. Hopefully it works, and we don't
! need no steenking BIOS anyway (except for the initial loading :-).
! The BIOS-routine wants lots of unnecessary data, and it's less
! "interesting" anyway. This is how REAL programmers do it.
!
! Well, now's the time to actually move into protected mode. To make
! things as simple as possible, we do no register set-up or anything,
! we let the gnu-compiled 32-bit programs do that. We just jump to
! absolute address 0x00000, in 32-bit protected mode.

	mov	ax,#0x0001	! protected mode (PE) bit
	lmsw	ax		! This is it!
	jmpi	0,8		! jmp offset 0 of segment 8 (cs)

! This routine checks that the keyboard command queue is empty
! No timeout is used - if this hangs there is something wrong with
! the machine, and we probably couldn't proceed anyway.
empty_8042:
	.word	0x00eb,0x00eb
	in	al,#0x64	! 8042 status port
	test	al,#2		! is input buffer full?
	jnz	empty_8042	! yes - loop
	ret

gdt:
	.word	0,0,0,0		! dummy

	.word	0x07FF		! 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		! base address=0
	.word	0x9A00		! code read/exec
	.word	0x00C0		! granularity=4096, 386

	.word	0x07FF		! 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		! base address=0
	.word	0x9200		! data read/write
	.word	0x00C0		! granularity=4096, 386

idt_48:
	.word	0			! idt limit=0
	.word	0,0			! idt base=0L

gdt_48:
	.word	0x800		! gdt limit=2048, 256 GDT entries
	.word	512+gdt,0x9	! gdt base = 0X9xxxx
	
.text
endtext:
.data
enddata:
.bss
endbss:
