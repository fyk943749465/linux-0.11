/*
 *  linux/kernel/traps.c
 *
 *  (C) 1991  Linus Torvalds
 * Ӳ���жϳ���
 * ��Ӳ���쳣��ʵ�ʴ������,����ĺ����ᱻ asm.s�е��жϵ���
 */

/*
 * 'Traps.c' handles hardware traps and faults after we have saved some
 * state in 'asm.s'. Currently mostly a debugging-aid, will be extended
 * to mainly kill the offending process (probably by giving it a signal,
 * but possibly by killing it outright if necessary).
 */
/* 
 * �ڳ��� asm.s�б�����һЩ״̬��,��������������Ӳ������͹���.Ŀǰ��Ҫ���ڵ���Ŀ��,
 * �Ժ���չ����ɱ�����𻵵Ľ���(��Ҫʱͨ������һ���ź�,�������ҪҲ��ֱ��ɱ��)
 */
#include <string.h>       // �ַ��� ͷ�ļ�. ��Ҫ������һЩ�й��ַ���������Ƕ�뺯��.

#include <linux/head.h>   // head ͷ�ļ�, �����˶��������ļ򵥽ṹ,�ͼ���ѡ�������
#include <linux/sched.h>  // ���ȳ���ͷ�ļ�,����������ṹtask_struct,��ʼ����0������,
                          // ����һЩ�й��������������úͻ�ȡ��Ƕ��ʽ��ຯ�������
#include <linux/kernel.h> // �ں�ͷ�ļ�,����һЩ���ó��ú�����ԭ�ζ���.
#include <asm/system.h>   // ϵͳͷ�ļ�.���������û��޸�������/�ж��ŵ�Ƕ��ʽ����.
#include <asm/segment.h>  // �β���ͷ�ļ�.�������йضμĴ���������Ƕ��ʽ��ຯ��.
#include <asm/io.h>       // ����/���ͷ�ļ�.����Ӳ���˿�����/����������.

// ������䶨��������Ƕ��ʽ������亯��. �й�Ƕ��ʽ���Ļ����﷨���б���μ���¼.
// ȡ�� seg �еĵ�ַ addr ����һ���ֽ�.
// ��Բ������ס��������(�������е����)������Ϊ���ʽʹ��,��������__res�������

// ��δ�����һ�κ궨�壬�����������ڻ��Ƕ�루inline assembly����Ŀ�ģ�������Ҫ�����Ǵ�ָ�����ڴ��ַ�ж�ȡһ���ֽڣ������ظ��ֽڵ�ֵ��
// ���ҽ���һ����δ���ĸ������֣�
// #define get_seg_byte(seg, addr)������һ���궨�壬������һ����Ϊ get_seg_byte �ĺ꣬�������������� seg �� addr��
// register char __res; ������������һ���Ĵ������� __res�����ڴ洢��ȡ���ֽ�ֵ��
// __asm__()���������������﷨��������C��C++������Ƕ����ָ�
// "push %%fs;mov %%ax,%%fs;movb %%fs:%2,%%al;pop %%fs"�������������Ļ��ָ��֡���ִ�����²�����
// push % %fs�����μĴ��� fs �ĵ�ǰֵѹ��ջ��
// mov % %ax, %% fs����16λͨ�üĴ��� ax ��ֵ���ص��μĴ��� fs �У�����Ϊ������һ���µĶμĴ���ֵ��ͨ��������ָ�����ݶΡ�
// movb%% fs: % 2, %% al�����ڴ��ַ % 2 ����ȡһ���ֽڣ�8λ�������ݣ��洢��ͨ�üĴ��� al �С� % 2 ���ں�����д��ݵ� addr ������
// pop % %fs����֮ǰѹ��ջ�� fs �Ĵ�����ֵ�������ָ�ԭʼ״̬��
// : "=a" (__res) : "0" (seg), "m" (*(addr))�������������Ĳ��������֣�ָ�������������������Լ�ʹ�õļĴ���Լ�������庬�����£�
//	"=a" (__res)����ͨ�üĴ��� al ��ֵ��Ϊ�������������������洢������ __res �С�
//	"0" (seg)����������� seg ��ֵ������ͨ�üĴ��� ax �С�
//	"m" (*(addr))����ʾҪ��ȡ���ڴ��ַ�� addr��ʹ�ü��Ѱַ��ʽ��
//	__res; ����󣬺귵�ر��� __res ��ֵ�����Ǵ��ڴ��ж�ȡ���ֽ�ֵ��
//	�ۺ�����������궨��������Ǵ�ָ�����ڴ��ַ�ж�ȡһ���ֽڣ������䷵�ء���ִ��֮ǰ����ʹ��������������öμĴ��� fs ��ֵ���Ա�ָ�����ݶΣ�
// Ȼ��Ӹö��ж�ȡһ���ֽڵ����ݣ���󽫶μĴ��� fs �ָ���ԭʼ״̬�������������C��C++�����з����ִ�����ֲ����������ر�д�����Ļ����롣
/*
�޶��ַ�		����							�޶��ַ�	����
a				ʹ�üĴ���eax					m			ʹ���ڴ��ַ
b				ʹ�üĴ���ebx					o			ʹ���ڴ��ַ�����Լ�ƫ��ֵ
m��o��V��p		ʹ�üĴ���ecx					I			ʹ�ó���0~31 ������
g��X			�Ĵ������ڴ�					J			ʹ�ó���0~63 ������
I��J��N��i��n	������							K			ʹ�ó���0~255������
D				ʹ��edi							L			ʹ�ó���0~65535 ������
q				ʹ�ö�̬�����ֽ�
				��Ѱַ�Ĵ���
				��eax��ebx��ecx��edx��			M			ʹ�ó���0~3 ������
r				ʹ�����⶯̬����ļĴ���		N			ʹ��1�ֽڳ�����0~255��������
g				ʹ��ͨ����Ч�ĵ�ַ����
			   ��eax��ebx��ecx��edx���ڴ������	O			ʹ�ó���0~31 ������
A				ʹ��eax��edx���ϣ�64λ��		i			������
c               ʹ�üĴ��� ecx
d               ʹ�üĴ��� edx 
S               ʹ�� esi
*/


#define get_seg_byte(seg,addr) ({ \
register char __res; \
__asm__("push %%fs;mov %%ax,%%fs;movb %%fs:%2,%%al;pop %%fs" \
	:"=a" (__res):"0" (seg),"m" (*(addr))); \
__res;})

// ȡ�� seg �е�ַ addr ����һ������(4�ֽ�)
#define get_seg_long(seg,addr) ({ \
register unsigned long __res; \
__asm__("push %%fs;mov %%ax,%%fs;movl %%fs:%2,%%eax;pop %%fs" \
	:"=a" (__res):"0" (seg),"m" (*(addr))); \
__res;})

// ȡfs�μĴ�����ֵ(ѡ���)
#define _fs() ({ \
register unsigned short __res; \
__asm__("mov %%fs,%%ax":"=a" (__res):); \
__res;})

// ���¶���һЩ����ԭ��
int do_exit(long code);                 // �����˳�����. (kernel/exit.c)

void page_exception(void);              // ҳ�쳣.ʵ���� page_fault(mm/page.s)

// ���¶�����һЩ�жϴ������ԭ��,������(kernel/asm.s �� system_call.s)��
void divide_error(void);                  // int 0
void debug(void);                         // int 1
void nmi(void);                           // int 2
void int3(void);                          // int 3
void overflow(void);                      // int 4
void bounds(void);                        // int 5
void invalid_op(void);                    // int 6
void device_not_available(void);          // int 7
void double_fault(void);                  // int 8
void coprocessor_segment_overrun(void);   // int 9
void invalid_TSS(void);                   // int 10
void segment_not_present(void);           // int 11
void stack_segment(void);                 // int 12
void general_protection(void);            // int 13
void page_fault(void);                    // int 14
void coprocessor_error(void);             // int 16
void reserved(void);                      // int 15
void parallel_interrupt(void);            // int 39
void irq13(void);                         // int 45 Э�������жϴ���

// ���ӳ���������ӡ�����жϵ�����,�����,���ó����EIP,EFLAGS,ESP,FS�μĴ���ֵ,
// �εĻ�ַ,�εĳ���,���̺�pid,�����,10�ֽ�ָ����.�����ջ���û����ݶ�,�򻹴�ӡ16�ֽڵĶ�ջ����
static void die(char * str,long esp_ptr,long nr)
{
	long * esp = (long *) esp_ptr;
	int i;

	printk("%s: %04x\n\r",str,nr&0xffff);
	printk("EIP:\t%04x:%p\nEFLAGS:\t%p\nESP:\t%04x:%p\n",
		esp[1],esp[0],esp[2],esp[4],esp[3]);
	printk("fs: %04x\n",_fs());
	printk("base: %p, limit: %p\n",get_base(current->ldt[1]),get_limit(0x17));
	if (esp[4] == 0x17) {
		printk("Stack: ");
		for (i=0;i<4;i++)
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
		printk("\n");
	}
	str(i);
	printk("Pid: %d, process nr: %d\n\r",current->pid,0xffff & i);
	for(i=0;i<10;i++)
		printk("%02x ",0xff & get_seg_byte(esp[1],(i+(char *)esp[0])));
	printk("\n\r");
	do_exit(11);		/* play segment exception */
}

// ������Щ��do_��ͷ�ĺ����Ƕ�Ӧ�����жϴ��������õ�C����
void do_double_fault(long esp, long error_code)
{
	die("double fault",esp,error_code);
}

void do_general_protection(long esp, long error_code)
{
	die("general protection",esp,error_code);
}

void do_divide_error(long esp, long error_code)
{
	die("divide error",esp,error_code);
}

void do_int3(long * esp, long error_code,
		long fs,long es,long ds,
		long ebp,long esi,long edi,
		long edx,long ecx,long ebx,long eax)
{
	int tr;

	__asm__("str %%ax":"=a" (tr):"0" (0));   // ȡ����Ĵ���ֵ -> tr
	printk("eax\t\tebx\t\tecx\t\tedx\n\r%8x\t%8x\t%8x\t%8x\n\r",
		eax,ebx,ecx,edx);
	printk("esi\t\tedi\t\tebp\t\tesp\n\r%8x\t%8x\t%8x\t%8x\n\r",
		esi,edi,ebp,(long) esp);
	printk("\n\rds\tes\tfs\ttr\n\r%4x\t%4x\t%4x\t%4x\n\r",
		ds,es,fs,tr);
	printk("EIP: %8x   CS: %4x  EFLAGS: %8x\n\r",esp[0],esp[1],esp[2]);
}

void do_nmi(long esp, long error_code)
{
	die("nmi",esp,error_code);
}

void do_debug(long esp, long error_code)
{
	die("debug",esp,error_code);
}

void do_overflow(long esp, long error_code)
{
	die("overflow",esp,error_code);
}

void do_bounds(long esp, long error_code)
{
	die("bounds",esp,error_code);
}

void do_invalid_op(long esp, long error_code)
{
	die("invalid operand",esp,error_code);
}

void do_device_not_available(long esp, long error_code)
{
	die("device not available",esp,error_code);
}

void do_coprocessor_segment_overrun(long esp, long error_code)
{
	die("coprocessor segment overrun",esp,error_code);
}

void do_invalid_TSS(long esp,long error_code)
{
	die("invalid TSS",esp,error_code);
}

void do_segment_not_present(long esp,long error_code)
{
	die("segment not present",esp,error_code);
}

void do_stack_segment(long esp,long error_code)
{
	die("stack segment",esp,error_code);
}

void do_coprocessor_error(long esp, long error_code)
{
	if (last_task_used_math != current)
		return;
	die("coprocessor error",esp,error_code);
}

void do_reserved(long esp, long error_code)
{
	die("reserved (15,17-47) error",esp,error_code);
}

// �������쳣(����)�жϳ����ʼ���ӳ���.�������ǵ��жϵ�����(�ж�����).
// set_trap_gate()��set_system_gate()����Ҫ��������ǰ�����õ���Ȩ��Ϊ0,������3. ���,
// �ϵ������ж�int3,����ж�overflow�ͱ߽�����ж� bounds�������κγ������.
// ��������������Ƕ��ʽ�������(include/asm/system.h)
void trap_init(void)
{
	int i;

	set_trap_gate(0,&divide_error);             // ���ó�����������ж�����ֵ.������ͬ
	set_trap_gate(1,&debug);
	set_trap_gate(2,&nmi);
	set_system_gate(3,&int3);	/* int3-5 can be called from all */
	set_system_gate(4,&overflow);
	set_system_gate(5,&bounds);
	set_trap_gate(6,&invalid_op);
	set_trap_gate(7,&device_not_available);
	set_trap_gate(8,&double_fault);
	set_trap_gate(9,&coprocessor_segment_overrun);
	set_trap_gate(10,&invalid_TSS);
	set_trap_gate(11,&segment_not_present);
	set_trap_gate(12,&stack_segment);
	set_trap_gate(13,&general_protection);
	set_trap_gate(14,&page_fault);
	set_trap_gate(15,&reserved);
	set_trap_gate(16,&coprocessor_error);

	// ���潫int17-48���������Ⱦ�����Ϊreserved,�Ժ�ÿ��Ӳ����ʼ��ʱ�����������Լ���������
	for (i=17;i<48;i++)
		set_trap_gate(i,&reserved);
	set_trap_gate(45,&irq13);              // ����Э��������������
	outb_p(inb_p(0x21)&0xfb,0x21);         // ������ 8259AоƬ�� IRQ2�ж�����
	outb(inb_p(0xA1)&0xdf,0xA1);           // ���д� 8259AоƬ�� IRQ3�ж�����
	set_trap_gate(39,&parallel_interrupt); // ���ò��пڵ�������
}
