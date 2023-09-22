#
# if you want the ram-disk device, define this to be the
# size in blocks.
#
RAMDISK = #-DRAMDISK=512

AS86	=as86 -0 -a                # 8086  汇编器和连接器,后带的参数含义分别是
LD86	=ld86 -0                   # -0 生成 8086 目标程序; -a 生成与 gas 和 gld 部分兼容的代码(gas 和 gld 是 gun 汇编器和连接器)

AS	=gas                           # GUN 的汇编器和连接器
LD	=gld
LDFLAGS	=-s -x -M                  # GUN 连接器 gld 运行时用到的选项: 含义是: -s 输出文件中省略所有的符号信息 -x 删除所有的局部符号 -M 在标准输出设备上打印连接映像
								   # 由连接程序产生的一种内存地址映像,其中列出了程序段转入到内存中的位置信息.具体来讲有如下信息:
								   # 1. 目标文件及符号信息映射到内存中的位置
								   # 2. 公共符号如何放置
								   # 3. 连接中包含的所有文件成员及其引用的符号
CC	=gcc $(RAMDISK)                # gcc 是 GNU C 程序编译器.对于UNIX类的脚本程序而言,在引用定义的标识符时,需要前面加上 $符号并用括号括住标识符
CFLAGS	=-Wall -O -fstrength-reduce -fomit-frame-pointer \
-fcombine-regs -mstring-insns      # gcc 的选项.前一行最后的 \ 符号表示下一行是续行. 选项含义:-Wall 打印所有警告信息; -0 对代码进行优化 -fstrength-reduce 优化循环语句 -mstring-insns 是linus 在学习gcc编译器时为gcc增加的选项,用于gcc-1.40
                                   # 在复制结构等操作时使用 386 cpu的字符串指令,可以去掉
CPP	=cpp -nostdinc -Iinclude       # cpp 是 gcc的预处理器.-nostdinc -Iinclude 的含义是不要搜索标准的头文件目录中的文件,而是使用-I选项指定的目录或者是在当前目录里搜索文件

#
# ROOT_DEV specifies the default root-device when making the image.
# This can be either FLOPPY, /dev/xxxx or empty, in which case the
# default of /dev/hd6 is used by 'build'.
#
ROOT_DEV=/dev/hd6                  # ROOT_DEV 指定在创建内存映像文件时所使用的默认根文件系统所在的设备,这可以是软盘,/dev/xxxx或者干脆空着.
								   # 空着时 build 程序(在tools/目录中)就使用默认值/dev/hd6

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o    # kernel目录,mm目录和fs目录所产生的目标代码文件.为了方便表示这里将它们用 ARCHIVES(归档文件)标识符表示
DRIVERS =kernel/blk_drv/blk_drv.a kernel/chr_drv/chr_drv.a  #块和字符设备库文件. .a表示该文件是归档文件,也即包含有许多可执行二进制代码子程序集合的库文件,
                                                            #通常是用 GNU的ar程序生成.ar是GUN的二进制文件处理程序,用于创建\修改以及从归档文件中抽取文件
MATH	=kernel/math/math.a        # 数学运算库文件         
LIBS	=lib/lib.a                 # 由lib/目录中的文件所编译生成的通用库文件

.c.s:                              # make 老式的隐式后缀规则.该行执行make利用下面的命令将所有的 .c文件编译生成.s汇编程序,':'表示下面是该规则的命令.
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -S -o $*.s $<    # 指使用 gcc 采用前面 CFLAGS 所指定的选项以及仅使用 include/目录中的头文件,在适当的编译后不进行汇编就停止(-S),从而产生
	                                     # 与输入的各个 C 文件对应的汇编语言形式的代码文件.默认情况下所产生的汇编程序文件是原C文件名去掉.c而加上.s后缀.-o 表示其后是输出文件的
										 # 形式.其中$*.s(或$@)是自动目标变量,$<代表第一个先决条件,这里即是符合条件 *.c 文件
.s.o:                                    # 表示将所有的.s汇编程序文件编译成.o目标文件.下一条是实现该操作的具体命令
	$(AS) -c -o $*.o $<                  # 使用gas编译器将汇编程序编译成.o目标文件.-c 表示值编译或汇编,但不进行连接操作
.c.o:                                    # 类似上面, *.c 文件 -> *.o目标文件
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -c -o $*.o $<    # 使用 gccc 将 C 语言文件编译成目标文件但不连接

all:	Image                            # all 表示创建 Makefile 所知的最顶层目标. 这里即是 image 文件

Image: boot/bootsect boot/setup tools/system tools/build                   # 说明目标(Image文件) 是由分号后面的4个元素产生,分别是 boot/ 目录中的 bootsect 和 setup,tools/目录中的system和build文件
	tools/build boot/bootsect boot/setup tools/system $(ROOT_DEV) > Image  
	sync                                 # 这两行是执行的命令,第一行表示使用tools目录下的build工具程序(下面会说明如何生成)将bootsect\setup和system文件 
	                                     # 以$(ROOT_DEV) 为根文件系统设备组装成内核映像文件 Image. 第二行的 sync同步命令是迫使缓冲块数据立即写盘并更新超级块
disk: Image                              # 表示disk 这个目标要由 Image 产生
	dd bs=8192 if=Image of=/dev/PS0      # dd 为 unix标准命令:复制一个文件,根据选项进行转换和格式化.bs=表示一次读/写的字节数 if=表示输入的文件 of=表示输出到的文件
										 # 这里的/dev/PS0 是指第一个软盘驱动器(设备文件)
tools/build: tools/build.c               # 由 tools 目录下的 build.c 程序生成执行程序 build.
	$(CC) $(CFLAGS) \
	-o tools/build tools/build.c         # 编译生成执行程序 build 的命令

boot/head.o: boot/head.s                 # 利用上面给出的.s.o 规则生成head.o 目标文件 

tools/system:	boot/head.o init/main.o \
		$(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)      # 表示 tools 目录中的 system 文件要由分号右边所列的元素生成
	$(LD) $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	$(DRIVERS) \
	$(MATH) \
	$(LIBS) \
	-o tools/system > System.map                    # 生成 system 的命令. 最后的 > System.map 表示 gld 需要将连接映象重定向存放在 System.map文件中
													# 关于 System.map 文件的用户参见注释后的说明

kernel/math/math.a:                                 # 数学协处理函数文件 math.a 由下一行上的命令实现.
	(cd kernel/math; make)                          # 进入 kernel/math/ 目录,运行 make 工具程序.

kernel/blk_drv/blk_drv.a:                           # 块设备函数文件 blk_drv.a
	(cd kernel/blk_drv; make)

kernel/chr_drv/chr_drv.a:                           # 字符设备函数文件 chr_drv.a
	(cd kernel/chr_drv; make)

kernel/kernel.o:                                    # 内核目标模块
	(cd kernel; make)

mm/mm.o:                                            # 内存管理模块
	(cd mm; make)

fs/fs.o:                                            # 文件系统目标模块
	(cd fs; make)

lib/lib.a:                                          # 库函数
	(cd lib; make)

boot/setup: boot/setup.s                          # 这里开始的三行是使用 8086 汇编器和连接器 
	$(AS86) -o boot/setup.o boot/setup.s          # 对 setup.s 文件进行编译生成 setup 文件
	$(LD86) -s -o boot/setup boot/setup.o         # -s选项表示要去除缪包文件中的符号信息

boot/bootsect:	boot/bootsect.s                   # 同上.生成 bootsect.o 磁盘引导块
	$(AS86) -o boot/bootsect.o boot/bootsect.s
	$(LD86) -s -o boot/bootsect boot/bootsect.o

tmp.s:	boot/bootsect.s tools/system              # 这四行的作用是在bootsect.s 程序开头添加一行有关system文件长度信息.
                                                  # 方法是首先生成含有"SYSSIZE = system 文件实际长度"一行信息的tmp.s文件,然后将bootsect.s 文件添加在其后
												  # 取得 system 长度的方法是: 首先利用命令 ls 对 system 文件进行长列表显示,用grep命令取得列表上文件字节数字段信息
												  # 并定向保存在tmp.s临时文件中. cut 命令用于剪切字符串,tr用于去除行尾的回车符.
												  # 其中:(实际长度+15)/16 用于获得用'节'表示的长度信息.1节=16字节.
	(echo -n "SYSSIZE = (";ls -l tools/system | grep system \
		| cut -c25-31 | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
	cat boot/bootsect.s >> tmp.s

clean:   # 当执行 'make clean' 时,就会执行下面的命令,去除所有编译连接生成的文件.
         # rm 是文件删除命令,选项-f含义是忽略不存在的文件,并且不显示删除信息
	rm -f Image System.map tmp_make core boot/bootsect boot/setup
	rm -f init/*.o tools/system tools/build boot/*.o
	(cd mm;make clean)
	(cd fs;make clean)
	(cd kernel;make clean)
	(cd lib;make clean)

backup: clean   # 该规则将首先执行上面的clean规则,然后对linux/ 目录进行压缩,生成backup.Z压缩文件. cd.. 表示退到linux/ 的上一级目录
                # tar cf -linux 表示对 linux/ 目录执行tar归档程序. -cf表示需要创建新的归档文件 
				# | compress - 表示将 tar程序的执行通过管道操作('|')传递给压缩程序,并将压缩程序输出成 backup.Z文件
	(cd .. ; tar cf - linux | compress - > backup.Z)
	sync        # 迫使缓冲块数据立即写盘并更新磁盘超级块

dep:            # 该目标和规则用于各文件之间的依赖关系.创建的这些依赖关系是为了给make用来确定是否需要重建一个目标对象的.比如当某个头文件被改动过后,make就通过生成的依赖关系,
                # 重新编译与该头文件有关的所有 *.c 文件. 具体方法如下:
				# 使用字符串编辑程序 sed 对 Makefile 文件(这里是自己) 进行处理.输出为 删除 Makefile 文件中'###Dependencies'行后面的所有行,并生成 tmp_make 临时文件
				# 然后对 init/ 目录下的每一个C文件(其实只有一个C文件,即main.c)执行gcc预处理操作. -M 标志告诉预处理程序输出描述每个目标文件相关性的规则,并且这些规则符合
				# make 语法.对于每一个源文件,预处理程序输出一个make规则,其结果形式是相应源程序文件的目标文件名加上其依赖关系--该源文件中包含的所有头文件列表.
				# $$i 实际上是$($i)的意思. 这里的$i是这句前面的shell变量的值. 然后把预处理结果都添加到临时文件 tmp_make中,然后将该临时文件复制成新的 Makefile 文件.
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in init/*.c;do echo -n "init/";$(CPP) -M $$i;done) >> tmp_make
	cp tmp_make Makefile
	(cd fs; make dep)
	(cd kernel; make dep)
	(cd mm; make dep)

### Dependencies:
init/main.o : init/main.c include/unistd.h include/sys/stat.h \
  include/sys/types.h include/sys/times.h include/sys/utsname.h \
  include/utime.h include/time.h include/linux/tty.h include/termios.h \
  include/linux/sched.h include/linux/head.h include/linux/fs.h \
  include/linux/mm.h include/signal.h include/asm/system.h include/asm/io.h \
  include/stddef.h include/stdarg.h include/fcntl.h 
