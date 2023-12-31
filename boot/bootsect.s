! BIOS（Basic Input/Output System）的中断向量表（IVT，Interrupt Vector Table）是在计算机启动时由计算机的固件加载到内存中的。
! 具体来说，这个过程通常发生在计算机加电自检（POST，Power-On Self-Test）和引导过程的早期阶段。
! 以下是大致的加载过程：
! 加电自检（POST）：当计算机加电时，首先会执行一系列硬件自检和初始化操作，这称为加电自检（POST）。在这个过程中，计算机检查各种硬件组件的状态，
! 确保它们正常工作，并加载固件，包括 BIOS。
! BIOS 初始化：BIOS 是计算机的固件，它存储在主板上的闪存或只读存储器（ROM）中。在POST期间，计算机将执行BIOS初始化过程，
! 这包括将BIOS中的代码加载到内存中的固定位置。
! 中断向量表加载：BIOS初始化过程中，BIOS会将中断向量表（IVT）加载到内存中的固定地址处。在x86架构的计算机上，IVT通常位于内存地址0x0000:0x0000处，
! 也就是物理内存的0地址。IVT包含了处理各种中断和异常情况的处理程序地址。
! 引导过程：一旦BIOS完成初始化，它将寻找启动设备（通常是硬盘或光盘驱动器）上的引导扇区，并将控制权传递给引导扇区的引导加载程序（Bootloader）。
! 引导加载程序将继续加载操作系统，并在需要时使用IVT中的中断处理程序。
! 总之，BIOS的中断向量表是在计算机启动时由BIOS加载到内存中的，以支持对中断和异常的处理。这是计算机启动过程中的一部分，确保计算机能够正确响应各种硬件和软件事件。

!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.                   SYS_SIZE是要加载的节数(16字节为1节).0x3000 共为 0x30000 字节 = 196kb,对于当前的版本已经足够了.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux
!
SYSSIZE = 0x3000     ! 指编译连接后 system 模块的大小. 这里给出了一个最大默认值
!
!	bootsect.s		(C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves           bootsect.s 被 bios 启动子程序加载至 0x7c00(31kb)处,并将自己移动到地址0x90000(576kb)处,并跳转到那里
! iself out of the way to address 0x90000, and jumps there.
!
! It then loads 'setup' directly after itself (0x90200), and the system            它然后使用bios中断将'setup'直接加载到自己的后面(0x90200)(576.5kb),并将system加载到地址0x10000处
! at 0x10000, using BIOS interrupts. 
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no          注意!目前的内核系统最大长度限制为(8*65536)(512k)字节,即使实在将来这也应该没什么问题的.我想让它保持简单
! problem, even in the future. I want to keep it simple. This 512 kB               明了.这样512k的最大内核长度应该足够了,尤其这里没有像minix中一样包含缓冲区高速缓冲
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
!
! The loader has been made as simple as possible, and continuos                    加载程序已经做的够简单了,所以持续的读出错将导致死循环.只能手工重启.只要可能,通过异常读取所有的扇区,
! read errors will result in a unbreakable loop. Reboot by hand. It                加载过程可以做的更快
! loads pretty fast by getting whole sectors at a time whenever possible.

.globl begtext, begdata, begbss, endtext, enddata, endbss                          ! 定义了6个全局标识符
.text                 ! 文本段
begtext:              
.data                 ! 数据段
begdata:
.bss                  ! 未初始化数据段(Block Started by Symbol)
begbss:
.text

SETUPLEN = 4				! nr of setup-sectors                          ! setup程序的扇区数值(setup程序大小所占用的扇区)
BOOTSEG  = 0x07c0			! original address of boot-sector              ! bootsect 的原始地址(是段地址),是CPU加电后,BIOS程序从0磁道0柱面1扇区读取出来的bootsect程序放在此处的
INITSEG  = 0x9000			! we move boot here - out of the way           ! 后来bootsect程序将字节移动到的内存位置
SETUPSEG = 0x9020			! setup starts here                            ! 从0磁道0柱面2扇区开始读取4个扇区后, 读取的setup程序,存放在内存的这个位置,即移动后的bootsect程序之后
SYSSEG   = 0x1000			! system loaded at 0x10000 (65536).            ! system 模块加载到的 0x10000(64kb)处
ENDSEG   = SYSSEG + SYSSIZE		! where to stop loading                    ! 停止加载的段地址

! ROOT_DEV:	0x000 - same type of floppy as boot.                ! 根文件系统设备使用引导软驱设备
!		0x301 - first partition on first drive etc              ! 第1个硬盘的第1个分区
ROOT_DEV = 0x306            ! 指定根文件系统设备是第2个硬盘的第1个分区.
							! 这是 Linux 老式的硬盘命名方式,具体值的含义如下:
							! 设备号 = 主设备号 * 256 + 次设备号(也叫dev_no = (major<<8) + minor)
							! 主设备号: 1-内存,2-磁盘,3-硬盘,4-ttyx,5-tty,6-并行口,7-非命名管道
							! 0x300 - /dev/hd0   -  代表整个第1个硬盘
							! 0x301 - /dev/hd1   -  第1个硬盘的第1个分区
							! ...
							! 0x304 - /dev/hd4   -  第1个硬盘的第4个分区
							! 0x305 - /dev/hd5   -  代表整个第2个硬盘
							! 0x306 - /dev/hd6   -  第2个硬盘的第1个分区
							! ...
						    ! 0x306 - /dev/hd9   -  第2个硬盘的第4个分区
							! 从 linux 内核0.95版本后已经使用与现在相同的命名方法了

entry start          ! 告知连接程序,程序从 start 标号开始执行.
start:               ! 将自身(bootsect)从目前段0x7C00(31KB)移动到0x9000(576KB)处,共256字(512字节),然后跳转到移动后的代码的go标号处执行,即本程序的下一条语句
	mov	ax,#BOOTSEG        ! 将ds段寄存器置为0x7C0
	mov	ds,ax
	mov	ax,#INITSEG
	mov	es,ax              ! 将es段寄存器置为0x9000
	mov	cx,#256            ! 移动计数值 256字
	sub	si,si              ! 源地址  ds:si = 0x7C00:0x0000
	sub	di,di              ! 目标地址es:di = 0x9000:0x0000
	rep                    ! 重复执行,直到 cx = 0
	movw                   ! 移动1个字
	jmpi	go,INITSEG     ! 跳转到INITSEG指定的段地址,go标号指定的偏移地址处,继续执行,这里会修改CS以及IP寄存器的值
go:	mov	ax,cs              ! 从这里开始,已经在段地址 0x9000 处开始执行了, 上面的代码是在段地址 0x7c0 处执行的
	mov	ds,ax              ! 将 ds,es和ss都置成移动后代码所在的段处(0x9000).由于程序中有堆栈操作(push,pop,call),因此必须设置堆栈
	mov	es,ax
! put stack at 0x9ff00.    ! 这里修改ss=0x9000 sp=0xff00 因为ss:sp 指向的是程序中的堆栈,为了不影响后面加载setup程序,将 sp指向了段内的更远处.只是为了防止出现错误
	mov	ss,ax			   ! 将堆栈指针 SS:SP 指向 0x9ff00(即 0x9000:0xff00)处
	mov	sp,#0xFF00		! arbitrary value >>512
							!由于代码段移动过了,所以要重新设置堆栈段的位置. SP 只要指向远大于 512 偏移(即地址0x90200)处都可以.因为
							!从0x90200 地址开始处还要放置 setup 程序,而此时 setup 程序大约为 4 个扇区,因此 sp 要指向大于 (0x200 + 0x200*4 + 堆栈大小) 处

! load the setup-sectors directly after the bootblock.   ! 在 bootsect 程序块后紧跟着加载 setup 模块的代码数据
! Note that 'es' is already set up.                      ! 注意 es 已经设置好了(在移动代码时,es已经指向目的段地址处0x9000)

load_setup:
	mov	dx,#0x0000		! drive 0, head 0               DH=0x00 用于指定磁头号 DL表示硬盘驱动号 0x80表示主硬盘 0x81表示从硬盘
	mov	cx,#0x0002		! sector 2, track 0             CH=0x00 表示柱面号     CL=0x02 表示扇区号
	mov	bx,#0x0200		! address = 512, in INITSEG     es:bx=0x9000:0x0200 = 0x90200 将磁盘上0磁道2扇区的内容读取到内存0x90200处,读取4个扇区
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors  AH=0x02 表示读操作     AL=0x04 表示读取扇区的数量
	int	0x13			! read it                       0x13 号中断,代表开始从硬盘向内存读数据, 13号中断通常会影响标志寄存器的 CF位和ZF位.如13号中断02功能表示读磁盘,那么如果读到的结果为0,则ZF置1,否则置0
	jnc	ok_load_setup		! ok - continue             juc表示进位标志位FC=0,则进行跳转; 13号中断导致的: CF=0表示中断程序执行正确; CF=1表示中断程序执行出错了
	mov	dx,#0x0000
	mov	ax,#0x0000		! reset the diskette            复位磁盘  AH=0x00 复位磁盘驱动器
	int	0x13                                            !13号中断执行, AH=0x00 复位操作  执行 13号中断的复位操作,复位磁盘
	j	load_setup

ok_load_setup:
						! 利用bios中断 int 0x13 将setup模块从磁盘第2个扇区开始读到 0x90200开始处,共读取4个扇区.如果读出错,则复位驱动器,并重试,没有退路.

						! 功能号：通过设置 CPU 寄存器 AH 的值来指定所需的功能。不同的功能号代表不同的操作，如读取扇区、写入扇区、检测硬盘存在性等。
						! 以下是一些常见的功能号：
						! AH=0x00：复位磁盘驱动器
						! AH=0x02：读取扇区
						! AH=0x03：写入扇区
						! AH=0x08：获取磁盘参数

						! int 0x13 的使用方法如下:

						!  读取磁盘扇区
						!  ah = 0x02 读取磁盘扇区     al = 需要读出的扇区数量
						!  ch = 磁道(柱面)号的低8位   cl = 开始扇区 低6位(0-5),磁道号 高2位(6-7)
                        !  dh = 磁头号;               dl = 驱动器号(如果是硬盘则位7要置位)
						!  es:bx 指向数据缓冲区; 如果读取出错则 CF(Carry Flag 进位标志位) 标志置位;

						!  取磁盘驱动器参数
						!  ah = 0x08 取磁盘驱动器参数 dl = 驱动器号(如果是硬盘则要置位7位1)
					    !  返回信息:
						!  如果获取磁盘参数出错, 并且 ah = 状态码
                        !  ah = 0, al = 0, bl = 驱动器类型(AT/PS2)
						!  ch = 最大磁道号的低8位  cl = 每磁道最大扇区数(位0-5),最大磁道号的高2位(位6-7)				
						!  dh = 最大磁头数         dl = 驱动器数量
						!  es:di 软盘磁盘参数列表

						! 13号中断（int 0x13）通常会影响标志寄存器，特别是Carry标志位（CF）和ZF（Zero Flag）标志位。以下是一些常见的情况：
						! Carry标志位（CF）：
						!   如果int 0x13执行成功，CF通常会被清零（设置为0），表示操作没有错误或失败。
						!   如果int 0x13执行失败，CF通常会被设置为1，表示发生了错误。
						! Zero Flag（ZF）：
						!   ZF标志位通常用于表示操作的结果是否为零。对于int 0x13中断，ZF的设置通常取决于执行的具体操作。
						!   例如，如果使用int 0x13来读取磁盘扇区，并且成功读取了数据，那么ZF可能会被清零，因为读取的数据不是零。
						!   如果使用int 0x13来执行某个操作，但操作的结果为零，那么ZF可能会被设置为1，表示结果为零。
						! 总之，int 0x13中断通常会使用标志寄存器的CF和ZF来指示操作的成功或失败，以及结果的特性。程序员可以根据
						! 这些标志位的状态来进行错误处理和操作结果的判断。具体的标志位设置和意义会根据具体的int 0x13子功能和具体情况而有所不同。
						! 因此，在使用int 0x13中断时，通常需要查阅相关的文档或手册，以了解每个子功能的标志寄存器状态含义。
! Get disk drive parameters, specifically nr of sectors/track

	mov	dl,#0x00        ! dl 表示驱动号
	mov	ax,#0x0800		! AH=8 is get drive parameters  AH=8 表示获取磁盘参数
	int	0x13            ! 13号中断 8号子功能,获取磁盘参数   
	mov	ch,#0x00        ! 0柱面
	seg cs              ! 表示下一条语句的操作数在 cs 段寄存器所指的段中
	mov	sectors,cx      ! 保存每磁道扇区数
	mov	ax,#INITSEG
	mov	es,ax           ! 因为上面中断int 0x13 取磁盘参数改掉了 es 的值, 这里重新修改回来

! Print some inane message    ! 显示一些信息('Loding system ...' 回车换行,共24个字符)

						! 10号中断说明: 用于控制和操作文本模式和图形模式的文本和图像输出。它允许程序与计算机的显示硬件进行交互，从而实现屏幕上的文本和图形的显示和操作。
						! int 0x10 中断的使用通常涉及 AH 寄存器，AL 寄存器以及其他寄存器和内存位置，具体功能取决于 AH 寄存器中的值，
						! AH 寄存器用于指定不同的子功能。以下是一些常见的 int 0x10 中断子功能和它们的作用：

						! 文本模式输出：
						! AH=0x0E：在文本模式下显示字符。使用 AL 寄存器来指定要显示的字符，BH 寄存器来指定显示的页面，BL 寄存器来指定字符的颜色。

						! 光标控制：
						! AH=0x02：设置光标位置。使用 BH 寄存器来指定显示的页面，DH 寄存器来指定行号，DL 寄存器来指定列号。

						! 获取光标位置：
						! AH=0x03：获取光标的位置。返回的光标位置存储在 BH 寄存器（页号）、DH 寄存器（行号）、DL 寄存器（列号）中。

						! 图形模式操作：
						! AH=0x00：设置图形模式。
						! AH=0x01：设置文本模式。
						! AH=0x05：获取当前的显示页。
						! AH=0x06：设置当前的显示页。
						! AH=0x0D：在图形模式下绘制像素点。

						! 其他功能：
						! AH=0x07：滚动屏幕。

									!文本模式输出：
									!AH=0x0E：在文本模式下显示字符。
									!AH=0x13：写入字符串并移动光标。

									!光标控制：
									! AH=0x02：设置光标位置。
									! AH=0x03：获取光标位置。
									! AH=0x06：设置当前的显示页。
									! AH=0x07：滚动屏幕。

									!图形模式操作：
									! AH=0x00：设置图形模式。
									! AH=0x01：设置文本模式。
									! AH=0x0D：在图形模式下绘制像素点。
									! AH=0x0F：获取当前的图形模式。

									!其他功能：
									! AH=0x05：获取当前的显示页。
									! AH=0x0A：设置文本模式光标形状。
									! AH=0x0B：获取文本模式光标形状。
									
									!文本模式输出 (AH=0x0E)：
									! AL=0x00：在光标位置显示字符。
									! AL=0x01：在光标位置显示字符，并保持光标位置不变。

									!光标控制 (AH=0x02)：
									! AL=0x00：将光标设置为不可见。
									! AL=0x01：将光标设置为可见。
									! AL=0x02：获取光标位置。
									! AL=0x03：设置光标位置。

									! 图形模式操作 (AH=0x00 和 AH=0x01)：

									! 这些功能通常不涉及 AL 寄存器，而是使用 AL 寄存器来指定要设置的图形模式或文本模式的编号。
									! 其他功能 (AH=0x05、AH=0x0A、AH=0x0B)：
									! 这些功能也通常不涉及 AL 寄存器，而是使用 AL 寄存器来指定其他参数，例如显示页号、光标形状等。

	mov	ah,#0x03		! read cursor pos     ! ah=0x03  获取光标位置
	xor	bh,bh                                 ! bh=0x0    
	int	0x10                                  ! 10号中断
	
	mov	cx,#24                                              ! 代表要显示的字符串的数量 24 个字符
														    !                            7     6 5 4  3     2 1 0
	mov	bx,#0x0007		! page 0, attribute 7 (normal)      ! bh 存储页  bl 存储字符属性 BL    R G B  I     R G B
															!						     闪烁  背景   高亮  前景
	mov	bp,#msg1                                            ! 指向要显示的字符串
	mov	ax,#0x1301		! write string, move cursor         ! 写字符串并移动光标
	int	0x10

! ok, we've written the message, now
! we want to load the system (at 0x10000)                   ! 现在开始将 system 模块加载到 64 KB 处

	mov	ax,#SYSSEG                            ! SYSSEG=0x1000 系统段地址  es = system 段地址
	mov	es,ax		! segment of 0x010000     
	call	read_it                           ! 读取磁盘上 system 模块, es 为输入参数
	call	kill_motor                        ! 关闭驱动器马达,这样就可以知道驱动器的状态了(盘片的转动是通过主轴电机驱动的)

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.

! 此后,我们检查要使用哪个根文件系统设备(简称根设备).如果已经指定了设备(!=0),就直接使用给定的设备.
! 否则,就需要根据 BIOS 报告的每磁道扇区数来确定到底使用 /dev/PS0(2, 28) 还是 /dev/at0 (2, 8)
! 上面一行中两个设备文件的含义:
!    在 Linux 中软驱的主设备号是2,次设备号 = type * 4 + nr, 其中的 nr 为 0-3 分别对应软驱 A,B,C或D
!    type 是软驱的类型(2 -> 1.2M 或 7->1.44M等). 因为 7*4 + 0 = 28, 所以 /dev/PS0(2,28)指的是1.44M A 驱动器,其设备号是 0x021c
!    同理 /dev/at0 (2,8) 指的是 1.2M A驱动器,其设备号是0x0208.

	seg cs
	mov	ax,root_dev                   ! 根设备号
	cmp	ax,#0
	jne	root_defined                  ! 比较结果不为0,则跳转到 root_defined 处执行(两个操作数不相等,则执行跳转)
	seg cs
	mov	bx,sectors                    ! 每磁道的扇区数(之前利用0x13中断读取磁盘信息时得到的).
									  ! 如果 sectors = 15 则说明是 1.2Mb 的驱动器; 如果 sectors = 18,则说明是1.44MB的软驱					 
	mov	ax,#0x0208		! /dev/ps0 - 1.2Mb               
	cmp	bx,#15                        ! 判断每磁道扇区数是否=15,如果等于,则ax中就是引导驱动器的设备号
	je	root_defined
	mov	ax,#0x021c		! /dev/PS0 - 1.44Mb
	cmp	bx,#18                       
	je	root_defined
undef_root:                           ! 如果不一样,则死循环(死机)
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax                   ! 将检查过的设备号保存起来

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:

	jmpi	0,SETUPSEG                           ! 跳转到 0x9020:0000 处(setup.s程序的开始处)
												 ! 本程序到此结束

! This routine loads the system at address 0x10000, making sure
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can.
!
! in:	es - starting address segment (normally 0x1000)
!
sread:	.word 1+SETUPLEN	! sectors read of current track    ! 当前磁道中已读的扇区数,开始时,已经读1扇区的引导扇区, bootsect 和 setup 程序所占用的扇区数 SETUPLEN
head:	.word 0			! current head         ! 当前的磁头号
track:	.word 0			! current track        ! 当前的磁道号

read_it: 
						! 测试输入的值,从盘上读入的数据必须存放在位于内存地址 64KB 的边界开始处,否则进入死循环
						! 清 bx 寄存器,用于表示当前段内存放数据的开始位置
	mov ax,es
	test ax,#0x0fff     ! test 指令的执行过程如下:      执行结果是 0,  是因为: 0x1000 & 0x0fff = 0x0000   
						! 1. 将 operand1 和 operand2 按位进行与操作,并将结果保存在临时寄存器中
						! 2. 更新标志寄存器的值,特别是设置零标志位 ZF, 如果结果为0,则ZF置为1,否则为0. 这一句汇编是的zf=1
						! 3. 更新符号标志位SF,根据结果的最高位来设置(将结果的最高位的置复制到标志寄存器SF位)
						! test 指令通常用于执行位级别的逻辑与操作,例如检查某些位是否被设置或清楚,或者测试寄存器或内存位置中的某些位的状态
						! 这通常与条件条状指令(JZ或JNZ)一起使用,根据结果来控制程序的流程
die:	jne die			! es must be at 64kB boundary   ! 这里明显含义是,test指令结果不为0,则进行跳转,将陷入死循环.  
						! 要使得这里不进入死循环, 那么test 指令的执行结果必须为0. 意味着, ax的值即es的值 必须是 0x1000 的整数倍,. 可以是 0x1000 0x2000 0x3000等
	    xor bx,bx		! bx is starting address within segment   ! 将 bx 值指 0x0000
rp_read:
						! 判断是否已经读入全部数据.比较当前所读段是否就是系统数据末端所处的段(#ENDSEG),如果不是就跳转到 ok1_read 标号处继续读数据,否则退出
	mov ax,es
	cmp ax,#ENDSEG		! have we loaded all yet?  ! 是否已经读取到段末端
	jb ok1_read         ! 如果小于段末端地址,则跳转; 意味这 system 程序代码还未读完
	ret                 ! 过程返回,ret 指令实现段内转移. 会修改ip寄存器的值,让程序返回调用的地方. 栈顶指针sp的值也会发生变化.因为原来保存在栈中的ip的值出栈了.
ok1_read:
						! 计算和验证当前磁道需要读取的扇区,放在ax寄存器中
						! 根据当前磁道还未读取的扇区数以及段内数据字节开始偏移位置,计算如果全部读取这些未读扇区所读字节总数是否会
						! 超过 64KB 段长度限制. 若会超过,则根据此次最多能读取的字节数(64kB - 段内偏移位置),反算出此次需要读取的扇区数.
						! 一个扇区的大小通常是 512字节(B) 
	seg cs
	mov ax,sectors      ! 取每磁道的扇区数
	sub ax,sread        ! 减去当前磁道已经读取的扇区数
	mov cx,ax           ! 未读的扇区数存储在 cx 中
	shl cx,#9           ! 每个扇区的大小是 512 字节,因此,左移9位,相当于乘以 512,算出未读的字节数
	add cx,bx           ! cx = cx + bx (段内偏移值,第一次bx为0) = 此次读操作后,段内共读入的字节数
	jnc ok2_read        ! add 指令的结果,没有发生进位, 则跳转到 ok2_read (意思没有超过64KB) ,读取代码
						! 因为cx是16位寄存器, 最大值能表示 65535,再+1 即65536(64KB),如果上面的add指令导致进位,则就表示cx中不能表示这么大的值, 也就表示超过了段空间大小(64KB)
	je ok2_read         ! add 指令结果为0,则进行跳转,(表示上面的 add 指令执行中导致了进位,但是刚好要读取 64KB 大小的数据) 那么也继续读.
	xor ax,ax			! 若加上此次将读磁道上所有未读扇区的数据,超过了一个段空间大小(64KB)
	sub ax,bx			! 则计算次数最多能读取的字节数(64KB-段内读偏移位置),再转换成需要读取的扇区数两
	shr ax,#9           ! 右移动,相当于除以 512,得到的是扇区数
ok2_read:
	call read_track     ! 读取磁盘完成
	mov cx,ax           ! 该次操作已读取的扇区数      比如:一个磁道上有100个扇区, 该次读取了该磁道上5个
	add ax,sread        ! 当前磁道上已经读取的扇区数        但是总共读取了该磁道上 30, 还剩下70个扇区未读
	seg cs
	cmp ax,sectors      ! sectors 表示磁道上总共的扇区数,如果已读扇区数不等于总扇区说
	jne ok3_read        ! 调用 ok3_read 过程,继续读取.
	mov ax,#1           ! 读该磁道的下一磁头面(1号磁头)上的数据,如果已经完成,则去读下一磁道
	sub ax,head         ! 判断当前磁头号,  看一下操作的结果(head 现在是0,表示0号磁头对应的磁盘面)
	jne ok4_read        ! 如果是0号磁头,则去读1号磁头对应的磁盘面上的扇区的数据
	inc track           ! 增加磁道计数, 读取下一个磁道上的数据
ok4_read:
	mov head,ax         ! 保存当前的磁头号
	xor ax,ax           ! 清除当前磁道已读扇区,因为是新的盘面,已读扇区为0
ok3_read:
	mov sread,ax        ! 保存当前磁道上,已读扇区数
	shl cx,#9           ! 左移9位,相当于乘以512 , 相当于该次读取的字节数
	add bx,cx           ! 读取的字节数,加到总的字节数上去, 跳转当前段内偏移位置的开始位置
	jnc rp_read         ! 表示 没有超过当前段64KB的空间, 那么调用 rp_read 过程,继续读取数据
	mov ax,es           ! 否则,调整当前段,因为该段空间已经被用完了.
	add ax,#0x1000      ! 下一个段的地址,即将段基地址调整为指向下一个64KB内存开始处
	mov es,ax
	xor bx,bx           ! 清除段内开始偏移值,将该值置0,即偏移位置为0
	jmp rp_read         ! 调用 rp_read 继续读取数据

						! 读当前磁道上指定开始扇区和需读扇区数的数据到 es:bx 开始处
read_track:
	push ax             ! 调用过程之间,向将标志寄存器的值保存
	push bx
	push cx
	push dx
	mov dx,track        ! 取当前磁道号
	mov cx,sread        ! 取当前磁道上的已读扇区
	inc cx              ! 开始读扇区 cl = 开始读取的扇区
	mov ch,dl           ! ch = 单曲磁道号
	mov dx,head         ! 取当前磁头号
	mov dh,dl           ! dh = 磁头号
	mov dl,#0           ! dl = 驱动器号(为0表示当前A驱动器)
	and dx,#0x0100      ! 磁头号不大于 1
	mov ah,#2           ! 读磁盘扇区的功能号 0x02 表示读取操作
	int 0x13            ! 0x13 中断,开始磁盘读取,磁盘操作错误,会导致标志寄存器的CF置为1
	jc bad_rt           ! 磁盘读取的结果出错, 会导致跳转
	pop dx              ! 过程调用完成,恢复之前的标志寄存器
	pop cx
	pop bx
	pop ax
	ret                 ! 恢复过程调用之前的 ip寄存器的值,以便过程调用完成,继续向下执行之后的代码
bad_rt:	mov ax,#0       ! 功能号为0,表示执行磁盘复位操作.
	mov dx,#0
	int 0x13
	pop dx              ! 重读之前出栈标志寄存器,因为之前入栈了,为了恢复到重读之前的状态,出栈标志寄存器,以便重读
	pop cx
	pop bx
	pop ax
	jmp read_track      ! 因为上次读取磁盘出错后,磁盘进行了复位操作,然后继续重读

/*
 * This procedure turns off the floppy drive motor, so
 * that we enter the kernel in a known state, and
 * don't have to worry about it later.
 */
							! 这个子程序用来关闭软驱的马达,这样我能进入内核后它处于已知状态,以后也就无须担心它了
kill_motor: 
	push dx                 
	mov dx,#0x3f2           ! 软驱控制卡的驱动端口,只写
	mov al,#0               ! A 驱动器,关闭FDC,禁止DMA和中断请求,关闭马达
	outb                    ! 将al中的内容输出到dx指定的端口去
	pop dx
	ret

sectors:                    ! 存放当前启动软盘每磁道的扇区数
	.word 0

msg1:
	.byte 13,10                          ! 回车换行的 ASCII
	.ascii "Loading system ..."
	.byte 13,10,13,10                    ! 共 24 个 ASCII 码字符

.org 508                    ! 表示下面语句从地址 508(0x1FC)开始,所以 root_dev 在启动扇区的第 508 开始的2个字节中
root_dev:
	.word ROOT_DEV          ! 这里存放根文件系统所在的设备号(init/main.c中会用)
boot_flag:
	.word 0xAA55            ! 硬盘有效标识

.text
endtext:
.data
enddata:
.bss
endbss:
