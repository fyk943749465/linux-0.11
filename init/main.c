/*
 *  linux/init/main.c
 *
 *  (C) 1991  Linus Torvalds
 * 
 * ����ִ���ں˳�ʼ������,Ȼ���ƶ����û�ģʽ�����½���,���ڿ���̨�豸������shell����.
 * �������ȸ����ڴ�Ķ��ٶԻ������ڴ��������з���,�����������Ҫʹ��������,���ڻ�����
 * �ڴ����ҲΪ�����¿ռ�.֮��ͽ�������Ӳ���ĳ�ʼ������,�����˹�������һ������(task0),
 * ���������ж������־.��ִ�дӺ���̬���û�̬֮��,ϵͳ��һ�ε��ô������̺���fork(),����
 * ��һ����������init()�Ľ���,�ڸ��ӽ�����,ϵͳ�����п���̨��������,����������һ���ӽ�����������shell����.
 */

/* Linuxϵͳ���ú͵��ÿ⺯�������ֲ�ͬ�ķ�ʽ�����������ϵͳ�ں˽��н�����ִ�и��ֲ���������֮�����Ҫ�������ڵ��õĲ�κ�ִ�з�ʽ��
 * ϵͳ���ã�System Calls����
 * ��Σ�ϵͳ����λ�ڲ���ϵͳ�ں˺��û��ռ����֮�䣬���ڲ���ϵͳ��һ���֡������ṩ��һ���û����������ϵͳ�ں˽���ͨ�ź��������ı�׼�ӿڡ�
 * Ȩ�ޣ�ϵͳ����ͨ�����и��ߵ�Ȩ�޼�����˿���ִ����Ȩ�����������ļ�ϵͳ���ʡ����̹�������ͨ�ŵȡ��û�����ͨ��ϵͳ���ýӿ������ں���ִ����Щ������
 * ���ܿ����������漰���û��ռ��л����ں˿ռ���������л���ϵͳ����ͨ�����нϸߵ����ܿ�������ˣ�����ͨ������ִ����Ҫ����ϵͳ�ĺ��Ĺ��ܵ�����
 * ʾ����һЩ������ϵͳ���ð��� open��read��write��fork��exec��kill �ȡ���Щ����ֱ�������ϵͳ�ں˽���ͨ�ţ�ִ���ļ����������̹����źŴ���Ȳ�����
 * ���ÿ⺯����Calling Library Functions����
 * ��Σ��⺯�������û��ռ�ĳ������ʵ�ֵĺ����������ṩ��һ���װ�õĹ��ܺͷ���ͨ��������ϵͳ����֮�ϡ���Щ�����Ը߼�����ķ�ʽ�ṩ�˶�ϵͳ���ܵķ��ʡ�
 * Ȩ�ޣ��⺯��ͨ�����û��ռ������У���Ȩ���������û������Ȩ�ޡ������޷�ִ����Ȩ������������ͨ������ϵͳ������ί�в���ϵͳ��ִ����Щ������
 * ���ܿ��������ڿ⺯��ͨ�����û��ռ����У����ǵ����ܿ����ϵͣ���Ϊ����Ҫ�����û��ռ���ں˿ռ�֮����������л���
 * ʾ������׼C�⣨�� glibc����������ೣ�õĿ⺯�������� printf��malloc��strlen��strcpy �ȡ���Щ������װ�˵ײ��ϵͳ���ã��ṩ�˸��߼���Ľӿڡ�
 * ��֮��ϵͳ���ú͵��ÿ⺯��֮�����Ҫ��ͬ�������Ρ�Ȩ�޺����ܿ�����ϵͳ�������û�����ֱ�������ϵͳ�ں˽����ĵײ�ӿڣ��ṩ�˶�ϵͳ��Դ�͹��ܵ�ֱ�ӷ��ʡ�
 * �����ÿ⺯�������û��ռ���ʵ�ֵĸ߼�����ӿڣ�����ͨ��������ϵͳ����֮�ϣ��ṩ�˸���ݺ����õĹ��ܡ�ͨ����������Ա����ѡʹ�ÿ⺯����������Ҫִ����Ȩ������ֱ��
 * ���ں˽��н���ʱ�Ż�ʹ��ϵͳ���á�
 */


/*
 * #define __LIBRARY__ �� #include <unistd.h> һ�����ʱ��ͨ����ʾ����Ϊʹ��Linux�ں�ϵͳ���õ�Ŀ�ı�д���롣���ֱ�д����ķ�ʽ������Linux�µ�ϵͳ��̻��ں�ģ��
 * �����������Ƿֱ���������д���ĺ��壺
 * #define __LIBRARY__��
 * ����һ��Ԥ����궨��ָ�����ʶ�� __LIBRARY__ ����Ϊһ���ض���ֵ��ͨ��Ϊ 1 ����û�����þ����ֵ��
 * ����궨��ͨ�����������߱����������뽫ʹ��ϵͳ���ö�����C�⺯����ִ�в�����
 * �� __LIBRARY__ ������Ϊ����ֵʱ��ͨ����ʾ���뽫ֱ�ӵ���Linux�ں��ṩ��ϵͳ���ã�����ʹ�ñ�׼C�⺯�������ַ��������ڱ�д����ϵͳ��������ں�ģ��ʱ�ǳ����á�
 * #include <unistd.h>��
 * ����һ������ͷ�ļ���Ԥ����ָ�����ϵͳͷ�ļ� <unistd.h> ����������Դ�����С�
 * <unistd.h> ͷ�ļ��������� POSIX ��׼���ݵĺ����ͷ��ţ�ͨ������ϵͳ����̡���Щ�������� read��write��fork��exec �ȣ��������������ϵͳ���н�����ִ��ϵͳ���á�
 * ������дϵͳ������ʱ��ͨ����Ҫ����������ͷ�ļ��Է���ϵͳ���õ������ͳ�����
 * �ۺ������������д������ϱ��������ڱ�дһ��ֱ����Linux�ں˽����ĳ�������ʹ��ϵͳ���ö����Ǳ�׼C�⺯����ִ�в��������ַ�ʽ������ϵͳ��̡�
 * �ں˿�������Ҫ���ײ���Ƶ�Ӧ�ó����С��������������У�__LIBRARY__ �궨����ܻᴥ��һЩ����ı�����Ϊ����������ָ���ȷ��������ȷ��ʹ��ϵͳ���á�
 */

#define __LIBRARY__        // ����ñ���ʱΪ�˰��������� unistd.h �е���Ƕ���������Ϣ
#include <unistd.h>        // *.h ͷ�ļ����ڵ�Ĭ��Ŀ¼�� include/,���ڴ����оͲ�����ȷָ��λ��. �������unix�ı�׼ͷ�ļ�,����Ҫָ�����ڵ�Ŀ¼,����˫������ס.
						   // ��׼���ų����������ļ�.�����˸��ַ��ų���������,�������˸��ֺ���.��������� __LIBRARY__,�򻹺�ϵͳ���úź���Ƕ������syscall0()��.
#include <time.h>          // ʱ������ͷ�ļ�.��������Ҫ������ tm �ṹ��һЩ�й�ʱ��ĺ���ԭ��.

/*
 * we need this inline - forking from kernel space will result
 * in NO COPY ON WRITE (!!!), until an execve is executed. This
 * is no problem, but for the stack. This is handled by not letting
 * main() use the stack at all after fork(). Thus, no function
 * calls - which means inline code for fork too, as otherwise we
 * would use the stack upon exit from 'fork()'.
 *
 * Actually only pause and fork are needed inline, so that there
 * won't be any messing with the stack from main(), but we define
 * some others too.
 */

/* ������Ҫ������Щ��Ƕ��� - ���ں˿ռ䴴������(forking)������û��дʱ��ֵ(Copy on write!)
 * ֱ��ִ��һ�� execve ����.��Զ�ջ���ܴ�������. ����ķ���ʱ�� fork()����֮���� main()ʹ�� 
 * �κζ�ջ. ��˾Ͳ����к������� - ����ζ�� fork ҲҪʹ����Ƕ�Ĵ���, �������Ǿʹ�fork() �˳�ʱ��Ҫʹ�ö�ջ��. 
 * ʵ����ֻ�� pause �� fork ��Ҫʹ����Ƕ��ʽ,�Ա�֤�� main() �в���Ū�Ҷ�ջ,��������ͬʱ������������һЩ����
 */

// �����򽫻����ƶ����û�ģʽ(�л�������0)���ִ��fork(),��˱��������ں˿ռ�дʱ��������.
// ��ִ���� move_to_user_mode()֮��,�������������0�������������.������0�����д������ӽ��̵ĸ�����. ��������һ���ӽ���ʱ,����0�Ķ�ջҲ�ᱻ����.���ϣ����main.c
// ����������0�Ļ�����ʱ��Ҫ�жԶ�ջ���κβ���,����Ū�Ҷ�ջ,�Ӷ�Ҳ����Ū�������ӽ��̵Ķ�ջ.

// ���� unistd.h�е���Ƕ�����.����Ƕ������ʽ���� Linux ��ϵͳ�����ж� 0x80.���ж�������ϵͳ���õ����.�������ʵ������
// int fork() �������̵�ϵͳ����.
// syscall0 �����е�0��ʾ�޲���,1��ʾ��һ������

// static inline��
// static������ؼ����������Ʒ��ŵ������򣬽��������ڵ�ǰ���뵥Ԫ��ͨ����һ��Դ�ļ����У�ʹ��������������ʱ���������뵥Ԫ��ͻ��
// inline������ؼ��ֽ������������������չ�������������ɺ������á��������ߴ���ִ�е�Ч�ʣ���Ϊ����Ҫ���к������õĿ�����
// (int, fork) �ⲿ��ָ����ϵͳ���õķ������ͺ����ơ������ϵͳ���õķ������ͱ�ָ��Ϊ int������ϵͳ���õ������� fork��
static inline _syscall0(int, fork)
static inline _syscall0(int, pause)                 // int pause() ϵͳ����, ��ͣ���̵�ִ��,ֱ���յ�һ���ź�
static inline _syscall1(int, setup, void*, BIOS)    // int setup(void * BIOS) ϵͳ����,������ linux ��ʼ��(������������б�����)
static inline _syscall0(int, sync)                  // int sync() ϵͳ����: �����ļ�ϵͳ

// #include <linux/tty.h> ��һ��Ԥ����ָ����ڰ�����Ϊ tty.h ��Linux�ں�ͷ�ļ������ͷ�ļ�ͨ������ Linux �ں˿��������ն��豸��tty����ص�ϵͳ����̡�
// ������������һ�����ͷ�ļ����ܰ��������ݺ������ã�
// �ں����ݽṹ�ͺ꣺tty.h ���ܰ��������ڱ�ʾ�ն��豸���ں����ݽṹ����صĺꡣ��Щ���ݽṹ�ͺ�����������ն��豸���н���������Ϳ��ơ�
// ����ԭ�ͣ����ͷ�ļ����ܰ��������ն��豸������صĺ���ԭ�͡���Щ�����������ڴ򿪡��رա���ȡ��д���ն��豸�Ȳ�����
// �����ͷ��Ŷ��壺tty.h ���ܰ�����һЩ�����ͷ��Ŷ��壬���ڱ�ʾ�ն��豸�����ԡ�״̬������ѡ���Щ�����ͷ��ſ������������ն��豸�����Ի����״̬��顣
// �������ն��豸��ص���Ϣ�����⣬ͷ�ļ����ܻ������������ն��豸��ص���Ϣ�������ն��豸�����͡����ơ��ļ��������ȡ�
// ��������ݺ����ÿ����� Linux �ں˰汾�;�����;���졣ͨ����<linux / tty.h> ͷ�ļ����ڱ�д��Ҫ���ն��豸���н�����ϵͳ�����������ն˷��������ն˿��Ƴ���
// �ն���������ȡ��������Ҫ��ϸ�˽�ͷ�ļ������ݺ��÷�������鿴 Linux �ں�Դ�����е�����ĵ���ע�͡�
#include <linux/tty.h>   // ttyͷ�ļ�,�������й�tty_io,����ͨ�ŷ����Ĳ���,����.

// ���ȳ���ͷ�ļ�,����������ṹ task_struct,��һ����ʼ���������.����һЩ�Ժ����ʽ������й��������������úͻ�ȡ��Ƕ��ʽ��ຯ������.
#include <linux/sched.h>  
#include <linux/head.h>   // headͷ�ļ�,�����˶��������ļ򵥽ṹ,�ͼ���ѡ�������
#include <asm/system.h>   // ϵͳͷ�ļ�,�Ժ����ʽ����������й����û��޸�������/�ж��ŵȵ�Ƕ��ʽ����ӳ���
#include <asm/io.h>       // ioͷ�ļ�,�Ժ��Ƕ���������ʽ�����io�˿ڲ����ĺ���

#include <stddef.h>       // ��׼����ͷ�ļ�,������ NULL, offsetof(TYPE, MEMBER)
#include <stdarg.h>       // ��׼����ͷ�ļ�.�Ժ����ʽ������������б�.��Ҫ˵����һ������(va_list)��������(va_start,va_arg��va_end),vsprintf,vprinf,vfprintf
#include <unistd.h>        
#include <fcntl.h>        // �ļ�����ͷ�ļ�.�����ļ������������Ĳ������Ƴ������ŵĶ���.
#include <sys/types.h>    // ����ͷ�ļ�.�����˻�����ϵͳ��������.

#include <linux/fs.h>     // �ļ�ϵͳͷ�ļ�.�����ļ���ṹ(file,buffer_head,m_inode��)

static char printbuf[1024];  // ��̬�ַ�������,�����ں���ʾ��Ϣ�Ļ���

extern int vsprintf();       // �͸�ʽ�������һ�ַ�����
extern void init(void);      // ����ԭ��,��ʼ��
extern void blk_dev_init(void);  // ���豸��ʼ���ӳ���
extern void chr_dev_init(void);  // �ַ��豸��ʼ��
extern void hd_init(void);       // Ӳ�̳�ʼ������
extern void floppy_init(void);   // ������ʼ������
extern void mem_init(long start, long end);      // �ڴ��ʼ��
extern long rd_init(long mem_start, int length); // �����̳�ʼ��
extern long kernel_mktime(struct tm * tm);       // ����ϵͳ��������ʱ��
extern long startup_time;                        // �ں�����ʱ��

/*
 * This is set up by the setup-routine at boot-time
 */

// ������Щ�������� setup.s ����������ʵ�����õ�
#define EXT_MEM_K (*(unsigned short *)0x90002)           // 1M�Ժ����չ�ڴ��С(KB)
#define DRIVE_INFO (*(struct drive_info *)0x90080)       // Ӳ�̲������ַ
#define ORIG_ROOT_DEV (*(unsigned short *)0x901FC)       // ���ļ�ϵͳ�����豸��

/*
 * Yeah, yeah, it's ugly, but I cannot find how to do this correctly
 * and this seems to work. I anybody has more info on the real-time
 * clock I'd be interested. Most of this was trial and error, and some
 * bios-listing reading. Urghh.
 */

// �ǰ�,�ǰ�,������γ���ܲ,�����Ҳ�֪�������ȷ��ʵ��,���Һ�������������.�����
// ����ʵʱʱ�Ӹ��������,���Һܸ���Ȥ.��Щ������̽������,�Լ�����һЩbios����,��!

#define CMOS_READ(addr) ({ \         // ��κ��ȡ CMOS ʵʱʱ����Ϣ
outb_p(0x80|addr,0x70); \            // 0x70 ��д�˿ں�, 0x80|addr ��Ҫ��ȡ�� CMOS �ڴ��ַ
inb_p(0x71); \                       // 0x71 �Ƕ��˿ں�
})
// �궨��. �� BCD��ת���ɶ�������ֵ
#define BCD_TO_BIN(val) ((val)=((val)&15) + ((val)>>4)*10)

// ���ӳ����ȡ COMS ʱ��,�����ÿ���ʱ��->startup_time(��).�μ�����CMOS�ڴ��б�
static void time_init(void)
{
	struct tm time;      // ʱ��ṹ tm ������ include/time.h ��

	// CMOS �ķ����ٶȺ���. Ϊ�˼�Сʱ�����,�ڶ�ȡ������ѭ�������е���ֵ��,����ʱCMOS����ֵ
	// �����˱仯,��ô�����¶�ȡ����ֵ.�����ں˾��ܰ���CMOS��ʱ����������1��֮��.
	do {
		time.tm_sec = CMOS_READ(0);       // ��ǰʱ����ֵ(����BCD��ֵ)
		time.tm_min = CMOS_READ(2);       // ��ǰ����ֵ
		time.tm_hour = CMOS_READ(4);      // ��ǰСʱֵ
		time.tm_mday = CMOS_READ(7);      // һ���еĵ�������
		time.tm_mon = CMOS_READ(8);       // ��ǰ�·�(1-12)
		time.tm_year = CMOS_READ(9);      // ��ǰ���
	} while (time.tm_sec != CMOS_READ(0));// �Ƚ��Ƿ�����һ���ڶ�ȡ��������ֵ
	BCD_TO_BIN(time.tm_sec);              // ת���ɶ�������ֵ
	BCD_TO_BIN(time.tm_min);
	BCD_TO_BIN(time.tm_hour);
	BCD_TO_BIN(time.tm_mday);
	BCD_TO_BIN(time.tm_mon);
	BCD_TO_BIN(time.tm_year);
	time.tm_mon--;                         // tm_mon ���·ݷ�Χ�� 0-11
	// ���� kernel/mktime.c �к���,�����1970-01-01 0:0:0 �𵽿������վ���������,��������ʱ��
	startup_time = kernel_mktime(&time);
}
// | �ں˳��� | ���ٻ��� | ������ | ���ڴ��� |
static long memory_end = 0;            // �������е������ڴ�����(�ֽ���)
static long buffer_memory_end = 0;     // ���ٻ�����ĩ�˵�ַ
static long main_memory_start = 0;     // ���ڴ�(�����ڷ�ҳ)��ʼ��λ��

struct drive_info { char dummy[32]; } drive_info;   // ���ڴ��Ӳ�̲�������Ϣ

void main(void)		/* This really IS void, no error here. */
{			/* The startup routine assumes (well, ...) this */
			// ����ȷʵ�� void,��û�д�.��startup����head.s�о������������,�μ�head.s��136��.
/*
 * Interrupts are still disabled. Do necessary setups, then
 * enable them
 */
/*  
 * ��ʱ�ж��Ա���ֹ��, �����Ҫ�����ú�ͽ��俪��
 */
	// ������δ������ڱ���:
	// ���豸�� -> ROOT_DEV;     ���ٻ���ĩ�˵�ַ -> buffer_memory_end;
	// �����ڴ��� -> memory_end; ���ڴ濪ʼ��ַ   -> main_memory_start;
 	ROOT_DEV = ORIG_ROOT_DEV;                // ROOT_DEV ������ fs/super.c 29��
 	drive_info = DRIVE_INFO;                 // ����0x90080 ����Ӳ�̲�����

	// ����궨�崴����һ���� EXT_MEM_K��
	// * (unsigned short*)0x90002 ��ʾ���ڴ��ַ 0x90002 ����ȡһ���޷��Ŷ�������16λ����������Ȼ��ͨ���궨�彫������Ϊ EXT_MEM_K��
	// �����������ǽ���ַ 0x90002 �������ݽ���Ϊһ�� unsigned short ���͵�ֵ�������丳ֵ�� EXT_MEM_K��
	// ������������һ������ memory_end ��ֵ��
	// (1 << 20) ��ʾ�� 1 ���� 20 λ������ 1 ���� 20 λ�õ� 1048576������ 1MB �Ĵ�С��
	// (EXT_MEM_K << 10) ��ʾ�� EXT_MEM_K ���� 10 λ�����ݺ궨�壬EXT_MEM_K �Ǵ��ڴ��ַ 0x90002 ��ȡ��һ��ֵ�����ｫ������ 10 λ���൱�ڽ������ 1024
	// ����Ϊ 1KB = 1024�ֽڣ���
	// ���ԣ�memory_end ��ֵ������ 1MB��1048576�ֽڣ����� EXT_MEM_K ��ֵ���� 1024�ֽڡ�
	// ��֮����δ����Ŀ���Ǽ��� memory_end ��ֵ������ EXT_MEM_K �Ǵ��ڴ��ַ 0x90002 ��ȡ��һ��16λֵ����ʾ��չ�ڴ�Ĵ�С������չ�ڴ�Ĵ�С���� 1024 �ֽں�
	// �� 1MB ��ӣ��õ��� memory_end ������ֵ��ͨ����������ϵͳ�ڴ�Ĳ�����
	memory_end = (1<<20) + (EXT_MEM_K<<10);  // �ڴ��С 1 MB �ֽ� + ��չ�ڴ�(k)*1024�ֽ�
	memory_end &= 0xfffff000;                // ���Բ��� 4Kb(1ҳ)���ڴ���
	if (memory_end > 16*1024*1024)           // ����ڴ泬�� 16Mb,��16Mb����
		memory_end = 16*1024*1024;           
	if (memory_end > 12*1024*1024)           // ����ڴ���� 12Mb,�����û�����ĩ��4Mb
		buffer_memory_end = 4*1024*1024;
	else if (memory_end > 6*1024*1024)       // ����ڴ���� 6Mb,�����û�����ĩ�� 2Mb
		buffer_memory_end = 2*1024*1024;
	else                                     // ���û�����ĩ�� 1Mb
		buffer_memory_end = 1*1024*1024;
	main_memory_start = buffer_memory_end;

// ����������ڴ�������,���ʼ��������.��ʱ���ڴ潫����. �μ�kernel/blk_drv/ramdisk.c
#ifdef RAMDISK
	main_memory_start += rd_init(main_memory_start, RAMDISK*1024);
#endif
// �������ں˽������з���ĳ�ʼ������.�Ķ�ʱ��ø��ŵ��õĳ������뿴��ȥ,��ʵ�ڿ�����ȥ,���ȷ�һ��,
// ��������һ����ʼ������.	
	mem_init(main_memory_start,memory_end);
	trap_init();     // ������(Ӳ���ж�����)��ʼ��
	blk_dev_init();  // ���豸��ʼ��
	chr_dev_init();  // �ַ��豸��ʼ��
	tty_init();      // tty ��ʼ��
	time_init();     // ���ÿ�������ʱ�� -> startup_time
	sched_init();    // ���ȳ����ʼ��(����������0��tr,ldtr)
	buffer_init(buffer_memory_end);  // ��������ʼ��,���ڴ������.
	hd_init();       // Ӳ�̳�ʼ��
	floppy_init();   // ������ʼ��
	sti();           // ���г�ʼ���������,�����ж�
	// �������ͨ���ڶ�ջ�����õĲ���,�����жϷ���ָ����������0ִ��.
	move_to_user_mode();    // �Ƶ��û�ģʽ��ִ��.
	if (!fork()) {		/* we count on this going ok */
		init();      // ���½����ӽ���(����1)��ִ��
	}
/*
 *   NOTE!!   For any other task 'pause()' would mean we have to get a
 * signal to awaken, but task0 is the sole exception (see 'schedule()')
 * as task 0 gets activated at every idle moment (when no other tasks
 * can run). For task0 'pause()' just means we go check if some other
 * task can run, and if not we return here.
 */
	// ������뿪ʼ������0���������.
/*
 * ע��!! �����κ�����������,'pause()'����ζ���Ǳ���ȴ��յ�һ���źŲŻ᷵�ؾ���״̬,������0(task0)ʱΨһ���������(�μ�schedule()),��Ϊ
 * ����0���κο���ʱ�䶼�ᱻ����(��û����������������ʱ),��˶�������0,'pause()'����ζ�����Ƿ������鿴�Ƿ������������������,���û�еĻ����Ǿͻص�����
 * һֱѭ��ִ��'pause()'.
 */
	// pause() ϵͳ����(kernel/sched.c,144)�������0ת���ɿ��жϵȴ�״̬,��ִ�е��Ⱥ���.���ǵ��Ⱥ���ֻҪ����ϵͳ��û�����������������ʱ�ͻ��л�������0,
	// ��������������0��״̬
	for(;;) pause();
}

// ������ʽ����Ϣ���������׼����豸stdout(1),����ʱָ��Ļ����ʾ.����'*fmt'ָ����������õĸ�ʽ,�μ����ֱ�׼C�����鼮.���ӳ�������ʱvsprintf���ʹ�õ�һ������
// �ó���ʹ��vsprintf()����ʽ�����ַ�������printbuf������,Ȼ����write()���������������������׼�豸(1-stdout).vsprintf()������ʵ�ּ�kernel/vsprintf.c
static int printf(const char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	write(1,printbuf,i=vsprintf(printbuf, fmt, args));
	va_end(args);
	return i;
}

static char * argv_rc[] = { "/bin/sh", NULL };    // ����ִ�г���ʱ�������ַ�������
static char * envp_rc[] = { "HOME=/", NULL };     // ����ִ�г���ʱ�Ļ����ַ�������

static char * argv[] = { "-/bin/sh",NULL };      // argv[0]�е��ַ�'-'�Ǵ��ݸ�shell����sh��һ����־.ͨ��ʶ��ñ�־,sh �������Ϊ��¼ shellִ��.��ִ�й�������shell��ʾ����ִ�� sh ��̫һ��
static char * envp[] = { "HOME=/usr/root", NULL };

// �� main()���Ѿ�������ϵͳ��ʼ��,�����ڴ����,����Ӳ���豸����������.init()���������� ����0��һ�δ������ӽ���(����1)��.
// �����ȶԵ�һ����Ҫִ�еĳ���(shell)�Ļ������г�ʼ��,Ȼ����ظó���ִ��֮.
void init(void)
{
	int pid,i;
	// ����һ��ϵͳ����.���ڶ�ȡӲ�̲���������������Ϣ������������(�����ڵĻ�)�Ͱ�װ���ļ�ϵͳ�豸.�ú�������25���ϵĺ궨���,���ں�����
	// sys_setup(),��kernel/blk_drv/hd.c 71��
	setup((void *) &drive_info);
	// �����Զ�д���ʷ�ʽ���豸 "/dev/tty0",����Ӧ�ն˿���̨.
	// �������ǵ�һ�δ��ļ�����,��˲������ļ������(�ļ�������)�϶���0.�þ����unix�����ϵͳĬ�ϵĿ���̨��׼������stdin. ��������Զ���д�ķ�ʽ����
	// Ϊ�˸��Ʋ�����׼���(д)���stdout�ͱ�׼����۱�stderr.
	(void) open("/dev/tty0",O_RDWR,0);
	(void) dup(0);              // ���ƾ��,�������1�� -- stdout ��׼����豸
	(void) dup(0);              // ���ƾ��,�������2�� -- stderr ��׼��������豸

	// �����ӡ���������������ֽ���,ÿ��1024�ֽ�,
    // �Լ����ڴ��������ڴ��ֽ���.
	printf("%d buffers = %d bytes buffer space\n\r",NR_BUFFERS,
		NR_BUFFERS*BLOCK_SIZE);
	printf("Free mem: %d bytes\n\r",memory_end-main_memory_start);

	// ���� fork() ���ڴ���һ���ӽ���(����2).���ڱ��������ӽ���,fork()������0ֵ.����ԭ����(������)�򷵻��ӽ��̵Ľ��̺�pid.
	// ���������if����ڵ�����,���ӽ���ִ�е�����.���ӽ��̹ر��˾��0,��ֻ����ʽ�� /etc/rc �ļ�,��ʹ��execve()����������
	// �����滻�� /bin/sh ����(��shell����),Ȼ��ִ��/bin/sh����. ���������ͻ��������ֱ��� argv_rc��envp_rc�������.����execve()
	// ��μ� fs/exec.c����, 182��.
	// ����_exit()�˳��ǵĳ�����1-����δ���; 2--�ļ���Ŀ¼������.
	if (!(pid=fork())) {
		close(0);
		if (open("/etc/rc",O_RDONLY,0))
			_exit(1);
		execve("/bin/sh",argv_rc,envp_rc);
		_exit(2);
	}

	// ���滹�Ǹ�����(1)ִ�е����. wait()�ȴ��ӽ���ֹͣ����ֹ,����ֵӦ���ӽ��̵Ľ��̺�pid.
	// ������������Ǹ����̵ȴ��ӽ��̵Ľ���. &i �Ǵ�ŷ���״̬��Ϣ��λ��.���wait()����ֵ�������ӽ��̺�,������ȴ�.
	if (pid>0)
		while (pid != wait(&i))
			/* nothing */;

	// ���ִ�е�����,˵���ܴ������ӽ��̵�ִ����ֹͣ����ֹ��.����ѭ���������ڴ���һ���ӽ���.�������,����ʾ"��ʼ�����򴴽��ӽ���ʧ��"��Ϣ������ִ��.����
	// ���������ӽ��̽��ر�������ǰ�������ľ��(stdin,stdout,stderr),�´�һ���Ự�����ý������,Ȼ�����´� /dev/tty0 ��Ϊ stdin,�����Ƴ�stdout��stderr.
	// �ٴ�ִ��ϵͳ���ͳ���/bin/sh.�����ִ����ѡ�õĲ����ͻ���������ѡ��һ��. Ȼ�󸸽����ٴ����� wait()�ȴ�.����ӽ�����ֹͣ��ִ��.���ڱ�׼�������ʾ
	// ������Ϣ"�ӽ���pidֹͣ������,��������i",Ȼ�����������ȥ,�γ�"��"��ѭ��
	while (1) {
		if ((pid=fork())<0) {
			printf("Fork failed in init\r\n");
			continue;
		}
		if (!pid) {                               // �µ��ӽ���
			close(0);close(1);close(2);
			setsid();                             // ����һ�µĻỰ��,������˵��.
			(void) open("/dev/tty0",O_RDWR,0);
			(void) dup(0);
			(void) dup(0);
			_exit(execve("/bin/sh",argv,envp));
		}
		while (1)
			if (pid == wait(&i))
				break;
		printf("\n\rchild %d died with code %04x\n\r",pid,i);
		sync();
	}
	_exit(0);	/* NOTE! _exit, not exit() */

	// ע��! ��_exit(),����exit(). 
	// _exit()��exit()��������������ֹһ������. ����_exit()ֱ����һ��sys_exitϵͳ����, ��exit()��
	// ͨ������ͨ�⺯���е�һ������.������ִ��һЩ�������,�������ִ�и���ֹ�������,�ر����б�׼IO��,Ȼ�����sys_exit.
}
