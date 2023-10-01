#
# Makefile for the FREAX-kernel.
#
# Note! Dependencies are done automagically by 'make dep', which also
# removes any old dependencies. DON'T put your own dependencies here
# unless it's something special (ie not a .c file).
#
# FREAX 内核的 Makefile 文件
#  
# 注意! 一百关系是有 make dep 自动进行的, 它也会自动去除原来的依赖信息.不要把你自己的依赖关系信息放在这里
# 除非是特别文件的(也即不是一个.c文件的信息). (Linux最初的名字叫 FREAX, 后来被ftp.funet.fi的管理员改成了Linux这个名字)

AR	=gar              # GUN 的二进制文件处理程序, 用于创建,修改以及从归档文件中提取文件
AS	=gas              # GNU 的汇编程序
LD	=gld              # GNU 的连接程序
LDFLAGS	=-s -x        # 连接程序所有的参数, -s 输出文件中省略所有符号信息. -x 删除所有局部符号.
CC	=gcc              # GUN C语言编译器
CFLAGS	=-Wall -O -fstrength-reduce -fomit-frame-pointer -fcombine-regs \
	-finline-functions -mstring-insns -nostdinc -I../include

	# C编译程序选项. -Wall 显示所有的警告信息; -0 优化选项,优化代码长度和执行时间;
	# -fstrength-reduce 优化循环执行代码,排除重复变量; -fomit-frame-pointer 省略保存不必要的框架指针;
	# -fcombine-regs 合并寄存器,减少寄存器的使用; -finline-functions 将所有简单短信的函数代码嵌入调用程序中;
	# -mstring-insns Linus 自己添加的优化选项,以后不在使用
	# -nostdinc -I../include 不使用默认路径中的包含文件,而使用这里指定目录中的(../include)
CPP	=gcc -E -nostdinc -I../include
# c前处理选项. -E 只运行C前处理,对所有指定的C程序进行预处理并将处理结果输出到标准输出设备或指定的输出文件中;
# -nostdinc -I../include 同前.

# 下面的规则指示 make 利用下面的命令将所有的.c文件编译生成.s汇编程序. 该规则的命令指使 gcc 采用 CFLAGS 所指定的选项
# 对 C 代码编译后不进行汇编就停止(-S),从而产生与输入的各个C文件对应的汇编代码文件. 默认情况下所产生的汇编程序文件名
# 是原 C 文件名去掉.c加上.s后缀. -o 表示其后是输出文件的名称. 其中 $*.s(或$@)是自动目标变量, 
# $< 代表第一个先决条件, 这里即是符合条件*.c的文件.

.c.s:
	$(CC) $(CFLAGS) \
	-S -o $*.s $<

# 下面规则表示将所有.s汇编程序文件编译成.o目标文件. 22行是实现该操作的具体命令.
.s.o:
	$(AS) -c -o $*.o $<
.c.o:                             # 类似上面, *.c文件->*.o目标文件. 不进行连接.
	$(CC) $(CFLAGS) \         
	-c -o $*.o $<

OBJS  = sched.o system_call.o traps.o asm.o fork.o \   # 定义目标文件变量 OBJS
	panic.o printk.o vsprintf.o sys.o exit.o \
	signal.o mktime.o

kernel.o: $(OBJS)                 # 在有了先决条件 OBJS后使用下面的命令连接成目标 kernel.o 
	$(LD) -r -o kernel.o $(OBJS)
	sync

# 下面的规则用于清理工作. 当执行 make clean 时, 就会执行下面的命令,去除所有编译连接生成的文件.
# 'rm'是文件删除命令, 选项 -f 含义是忽略不存在的文件, 并且不会显示删除信息.

# for i in *.c;do rm -f `basename $$i .c`.s;done
# 这段Shell脚本的含义是批量删除当前目录下所有扩展名为 .c 的C语言源文件对应的汇编文件（扩展名为 .s 的文件）。让我解释一下这段脚本的每一部分：
# for i in *.c;：这是一个for循环，用于遍历当前目录下所有以 .c 结尾的文件。*.c 是通配符，用于匹配当前目录下所有以 .c 结尾的文件名，并将它们逐个赋值给变量 i。
# do：do 关键字标志着循环体的开始。
# rm -f basename $$i .c.s;：这是循环体的内容，它执行以下操作：
# basename $$i .c：basename 命令用于从文件路径中提取文件名部分，而 $$i 是循环变量的值，表示当前遍历到的文件名。.c 表示删除文件名中的 .c 扩展名。
# 结果是一个不包含扩展名的文件名。
# `...`：这是命令替换，它会将 basename 命令的输出结果作为参数传递给 rm -f 命令。
# .s：在 `...` 后面，添加了 .s 扩展名，以构成汇编文件的文件名。
# rm -f：这是一个删除文件的命令，-f 参数表示强制删除，即使文件不存在也不会报错。
# done：done 关键字标志着循环体的结束。
clean:
	rm -f core *.o *.a tmp_make keyboard.s
	for i in *.c;do rm -f `basename $$i .c`.s;done
	(cd chr_drv; make clean)       # 进入 chr_drv/目录;执行该目录 Makefile中的clean规则
	(cd blk_drv; make clean)
	(cd math; make clean)

# 下面的目标或规则用于检查各文件之间的依赖关系. 方法如下:
# 使用字符串编辑程序 sed 对 Makefile 文件(这里即是自己)进行处理,输出为删除Makefile文件中'### Dependencies'行后面所有的行,
# 并生成 tmp_make 临时文件(43行的作用). 然后对 kernel/目录下的每一个 C 文件执行 gcc 预处理操作. 
# -M 标志告诉预处理程序输出描述每个目标文件相关性的规则,并且这些规则符合make语法.
# 对于每一个源文件,预处理程序输出一个make规则,其结果形式是相应源程序文件的目标文件名加上其依赖关系--该源文件中包含的所有头
# 文件列表. 把预处理结果都添加到临时文件 tmp_make 中, 然后将该临时文件复制成新的 Makefile 文件.


# 这段Shell脚本的主要作用是生成一份包含C语言源文件依赖关系的 Makefile 规则，并将这些规则追加到一个名为 tmp_make 的文件中。让我逐步解释这段脚本的每一部分：
# (for i in *.c;：这是一个子shell（subshell），它用于遍历当前目录下所有以 .c 结尾的C语言源文件。*.c 是通配符，用于匹配当前目录下所有以 .c 结尾的文件。
# do：do 关键字标志着循环体的开始。
# echo -n `echo $$i | sed 's,.c,.s,'`" "：这部分用于输出当前源文件的名字（不包括扩展名 .c）和一个空格。具体操作如下：
# $$i：这是循环变量的值，表示当前遍历到的C语言源文件的文件名。
# echo $$i | sed 's,\.c,\.s,'：这是一个管道命令，它将当前文件名中的 .c 扩展名替换为 .s 扩展名，然后输出。
# echo -n：-n 选项表示不输出换行符，因此只输出文件名和一个空格。
# $(CPP) -M $$i;：这是一个用于生成依赖关系的命令。它通过 $(CPP)（预处理器）对当前C语言源文件进行预处理，并输出其依赖关系。-M 选项告诉预处理器生成依赖关系，
# 而 $$i 表示当前的C语言源文件。
# done：done 关键字标志着循环体的结束。
# >> tmp_make：这部分将循环体的输出追加到名为 tmp_make 的文件中，而不是覆盖文件内容。这个文件将包含生成的依赖关系规则。
# 综合起来，这个Shell脚本的作用是遍历当前目录下所有以 .c 结尾的C语言源文件，为每个源文件生成一个依赖关系规则，并将这些规则追加到 tmp_make 文件中。
# 这些规则通常用于Makefile中，用于构建和编译C语言程序时，以确保正确处理文件依赖性。这是一个自动化构建系统的一部分。


dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in *.c;do echo -n `echo $$i | sed 's,\.c,\.s,'`" "; \
		$(CPP) -M $$i;done) >> tmp_make
	cp tmp_make Makefile
	(cd chr_drv; make dep)
	(cd blk_drv; make dep)

### Dependencies:
exit.s exit.o : exit.c ../include/errno.h ../include/signal.h \
  ../include/sys/types.h ../include/sys/wait.h ../include/linux/sched.h \
  ../include/linux/head.h ../include/linux/fs.h ../include/linux/mm.h \
  ../include/linux/kernel.h ../include/linux/tty.h ../include/termios.h \
  ../include/asm/segment.h 
fork.s fork.o : fork.c ../include/errno.h ../include/linux/sched.h \
  ../include/linux/head.h ../include/linux/fs.h ../include/sys/types.h \
  ../include/linux/mm.h ../include/signal.h ../include/linux/kernel.h \
  ../include/asm/segment.h ../include/asm/system.h 
mktime.s mktime.o : mktime.c ../include/time.h 
panic.s panic.o : panic.c ../include/linux/kernel.h ../include/linux/sched.h \
  ../include/linux/head.h ../include/linux/fs.h ../include/sys/types.h \
  ../include/linux/mm.h ../include/signal.h 
printk.s printk.o : printk.c ../include/stdarg.h ../include/stddef.h \
  ../include/linux/kernel.h 
sched.s sched.o : sched.c ../include/linux/sched.h ../include/linux/head.h \
  ../include/linux/fs.h ../include/sys/types.h ../include/linux/mm.h \
  ../include/signal.h ../include/linux/kernel.h ../include/linux/sys.h \
  ../include/linux/fdreg.h ../include/asm/system.h ../include/asm/io.h \
  ../include/asm/segment.h 
signal.s signal.o : signal.c ../include/linux/sched.h ../include/linux/head.h \
  ../include/linux/fs.h ../include/sys/types.h ../include/linux/mm.h \
  ../include/signal.h ../include/linux/kernel.h ../include/asm/segment.h 
sys.s sys.o : sys.c ../include/errno.h ../include/linux/sched.h \
  ../include/linux/head.h ../include/linux/fs.h ../include/sys/types.h \
  ../include/linux/mm.h ../include/signal.h ../include/linux/tty.h \
  ../include/termios.h ../include/linux/kernel.h ../include/asm/segment.h \
  ../include/sys/times.h ../include/sys/utsname.h 
traps.s traps.o : traps.c ../include/string.h ../include/linux/head.h \
  ../include/linux/sched.h ../include/linux/fs.h ../include/sys/types.h \
  ../include/linux/mm.h ../include/signal.h ../include/linux/kernel.h \
  ../include/asm/system.h ../include/asm/segment.h ../include/asm/io.h 
vsprintf.s vsprintf.o : vsprintf.c ../include/stdarg.h ../include/string.h 
