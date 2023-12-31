/*调度程序头文件,定义了任务结构 task_struct,初始任务0的数据,一些有关描述符参数设置和获取的嵌入式汇编函数宏语句*/
#ifndef _SCHED_H
#define _SCHED_H

#define NR_TASKS 64
#define HZ 100

#define FIRST_TASK task[0]
#define LAST_TASK task[NR_TASKS-1]

#include <linux/head.h>
#include <linux/fs.h>
#include <linux/mm.h>
#include <signal.h>

#if (NR_OPEN > 32)
#error "Currently the close-on-exec-flags are in one word, max 32 files/proc"
#endif

#define TASK_RUNNING		0
#define TASK_INTERRUPTIBLE	1
#define TASK_UNINTERRUPTIBLE	2
#define TASK_ZOMBIE		3
#define TASK_STOPPED		4

#ifndef NULL
#define NULL ((void *) 0)
#endif

extern int copy_page_tables(unsigned long from, unsigned long to, long size);
extern int free_page_tables(unsigned long from, unsigned long size);

extern void sched_init(void);
extern void schedule(void);
extern void trap_init(void);
extern void panic(const char * str);
extern int tty_write(unsigned minor,char * buf,int count);

typedef int (*fn_ptr)();

struct i387_struct {  // i387 使用的结构,这是数学协处理器使用的结构,主要用于保存进程切换时,i387的执行状态信息
	long	cwd;                   // 控制字
	long	swd;                   // 状态字
	long	twd;                   // 标记字
	long	fip;                   // 协处理器代码指针
	long	fcs;                   // 协处理器代码段寄存器
	long	foo;                   // 内存操作数的偏移位置
	long	fos;                   // 内存操作数的段值
	long	st_space[20];	/* 8*10 bytes for each FP-reg = 80 bytes */   // 8个10字节的协处理器累加
};

struct tss_struct {    // 任务状态结构  TSS是x86架构中用于任务切换和处理器状态保存的关键数据结构之一
	long	back_link;	/* 16 high bits zero */
	long	esp0;
	long	ss0;		/* 16 high bits zero */
	long	esp1;
	long	ss1;		/* 16 high bits zero */
	long	esp2;
	long	ss2;		/* 16 high bits zero */
	long	cr3;
	long	eip;
	long	eflags;
	long	eax,ecx,edx,ebx;
	long	esp;
	long	ebp;
	long	esi;
	long	edi;
	long	es;		/* 16 high bits zero */
	long	cs;		/* 16 high bits zero */
	long	ss;		/* 16 high bits zero */
	long	ds;		/* 16 high bits zero */
	long	fs;		/* 16 high bits zero */
	long	gs;		/* 16 high bits zero */
	long	ldt;		/* 16 high bits zero */
	long	trace_bitmap;	/* bits: trace 0, bitmap 16-31 */
	struct i387_struct i387;
};

struct task_struct {    // 进程[任务]数据结构,或称为进程描述符
/* these are hardcoded - don't touch */
	long state;	/* -1 unrunnable, 0 runnable, >0 stopped */           // 任务的运行状态(-1不可运行,0可运行(就绪),>0已停止).
	long counter;                                                     // 任务运行时间计数(递减)(滴答数),运行时间片
	long priority;                                                    // 运行优先数.任务开始运行时 counter=priority,越大运行越长.
	long signal;                                                      // 信号.是位图,每个比特位代表一种信号,信号值=位偏移值+1
   	struct sigaction sigaction[32];                                   // 信号执行属性结构,对应信号将要执行的操作和标志信息
	long blocked;	/* bitmap of masked signals */                    // 进程信号屏蔽码(对应信号位图)
/* various fields */ 
	int exit_code;                                                    // 任务执行停止的退出码,其父进程会取
	unsigned long start_code,end_code,end_data,brk,start_stack;       // 代码段地址 代码长度 代码长度+数据长度(字节数) 总长度(字节数) 堆栈段地址
	long pid,father,pgrp,session,leader;                              // 进程号 父进程号 父进程组号 会话号 会话首领
	unsigned short uid,euid,suid;                                     // 用户id,有效用户id,保存的用户id
	unsigned short gid,egid,sgid;                                     // 组id,有效组id,保存的组id
	long alarm;                                                       // 报警定时值(滴答数)
	long utime,stime,cutime,cstime,start_time;                        // 用户态运行时间(滴答数),系统态运行时间(滴答数),子进程用户态运行时间,子进程系统态运行时间,进程开始运行时刻
	unsigned short used_math;                                         // 标志:是否使用了协处理器
/* file system info */
	int tty;		/* -1 if no tty, so it must be signed */          // 进程使用 tty的子设备号. -1表示没有使用
	unsigned short umask;                                             // 文件创建属性屏蔽位
	struct m_inode * pwd;                                             // 当前工作目录 i 节点结构
	struct m_inode * root;                                            // 根目录 i 节点结构
	struct m_inode * executable;                                      // 执行文件 i 节点结构
	unsigned long close_on_exec;                                      // 执行时关闭文件句柄位图标志
	struct file * filp[NR_OPEN];                                      // 文件结构指针表,最多32项.表项号即是文件秒数符的值.
/* ldt for this task 0 - zero 1 - cs 2 - ds&ss */
	struct desc_struct ldt[3];                                        // 任务局部描述符表. 0-空, 1-代码段cs, 2-数据和堆栈段 ds&ss
/* tss for this task */
	struct tss_struct tss;                                            // 进程的任务状态段信息结构
};

/*
 *  INIT_TASK is used to set up the first task table, touch at
 * your own risk!. Base=0, limit=0x9ffff (=640kB)
 */
#define INIT_TASK \
/* state etc */	{ 0,15,15, \
/* signals */	0,{{},},0, \
/* ec,brk... */	0,0,0,0,0,0, \
/* pid etc.. */	0,-1,0,0,0, \
/* uid etc */	0,0,0,0,0,0, \
/* alarm */	0,0,0,0,0,0, \
/* math */	0, \
/* fs info */	-1,0022,NULL,NULL,NULL,0, \
/* filp */	{NULL,}, \
	{ \
		{0,0}, \
/* ldt */	{0x9f,0xc0fa00}, \
		{0x9f,0xc0f200}, \
	}, \
/*tss*/	{0,PAGE_SIZE+(long)&init_task,0x10,0,0,0,0,(long)&pg_dir,\
	 0,0,0,0,0,0,0,0, \
	 0,0,0x17,0x17,0x17,0x17,0x17,0x17, \
	 _LDT(0),0x80000000, \
		{} \
	}, \
}

extern struct task_struct *task[NR_TASKS];
extern struct task_struct *last_task_used_math;
extern struct task_struct *current;
extern long volatile jiffies;
extern long startup_time;

#define CURRENT_TIME (startup_time+jiffies/HZ)

extern void add_timer(long jiffies, void (*fn)(void));
extern void sleep_on(struct task_struct ** p);
extern void interruptible_sleep_on(struct task_struct ** p);
extern void wake_up(struct task_struct ** p);

/*
 * Entry into gdt where to find first TSS. 0-nul, 1-cs, 2-ds, 3-syscall
 * 4-TSS0, 5-LDT0, 6-TSS1 etc ...
 */
#define FIRST_TSS_ENTRY 4
#define FIRST_LDT_ENTRY (FIRST_TSS_ENTRY+1)
#define _TSS(n) ((((unsigned long) n)<<4)+(FIRST_TSS_ENTRY<<3))
#define _LDT(n) ((((unsigned long) n)<<4)+(FIRST_LDT_ENTRY<<3))
#define ltr(n) __asm__("ltr %%ax"::"a" (_TSS(n)))
#define lldt(n) __asm__("lldt %%ax"::"a" (_LDT(n)))
#define str(n) \
__asm__("str %%ax\n\t" \
	"subl %2,%%eax\n\t" \
	"shrl $4,%%eax" \
	:"=a" (n) \
	:"a" (0),"i" (FIRST_TSS_ENTRY<<3))
/*
 *	switch_to(n) should switch tasks to task nr n, first
 * checking that n isn't the current task, in which case it does nothing.
 * This also clears the TS-flag if the task we switched to has used
 * tha math co-processor latest.
 */
#define switch_to(n) {\
struct {long a,b;} __tmp; \
__asm__("cmpl %%ecx,_current\n\t" \
	"je 1f\n\t" \
	"movw %%dx,%1\n\t" \
	"xchgl %%ecx,_current\n\t" \
	"ljmp %0\n\t" \
	"cmpl %%ecx,_last_task_used_math\n\t" \
	"jne 1f\n\t" \
	"clts\n" \
	"1:" \
	::"m" (*&__tmp.a),"m" (*&__tmp.b), \
	"d" (_TSS(n)),"c" ((long) task[n])); \
}

#define PAGE_ALIGN(n) (((n)+0xfff)&0xfffff000)

#define _set_base(addr,base) \
__asm__("movw %%dx,%0\n\t" \
	"rorl $16,%%edx\n\t" \
	"movb %%dl,%1\n\t" \
	"movb %%dh,%2" \
	::"m" (*((addr)+2)), \
	  "m" (*((addr)+4)), \
	  "m" (*((addr)+7)), \
	  "d" (base) \
	:"dx")

#define _set_limit(addr,limit) \
__asm__("movw %%dx,%0\n\t" \
	"rorl $16,%%edx\n\t" \
	"movb %1,%%dh\n\t" \
	"andb $0xf0,%%dh\n\t" \
	"orb %%dh,%%dl\n\t" \
	"movb %%dl,%1" \
	::"m" (*(addr)), \
	  "m" (*((addr)+6)), \
	  "d" (limit) \
	:"dx")

#define set_base(ldt,base) _set_base( ((char *)&(ldt)) , base )
#define set_limit(ldt,limit) _set_limit( ((char *)&(ldt)) , (limit-1)>>12 )

#define _get_base(addr) ({\
unsigned long __base; \
__asm__("movb %3,%%dh\n\t" \
	"movb %2,%%dl\n\t" \
	"shll $16,%%edx\n\t" \
	"movw %1,%%dx" \
	:"=d" (__base) \
	:"m" (*((addr)+2)), \
	 "m" (*((addr)+4)), \
	 "m" (*((addr)+7))); \
__base;})

#define get_base(ldt) _get_base( ((char *)&(ldt)) )

#define get_limit(segment) ({ \
unsigned long __limit; \
__asm__("lsll %1,%0\n\tincl %0":"=r" (__limit):"r" (segment)); \
__limit;})

#endif
