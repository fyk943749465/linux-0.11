/*
 *  linux/kernel/printk.c
 *
 *  (C) 1991  Linus Torvalds
 * ͨ�ó���
 * �ں�ר�õ���Ϣ��ʾ����
 */

/*
 * When in kernel-mode, we cannot use printf, as fs is liable to
 * point to 'interesting' things. Make a printf with fs-saving, and
 * all is well.
 */
/* 
 * printk()���ں���ʹ�õĴ�ӡ(��ʾ)����,������C��׼�������е�print()��ͬ.���±�д��ôһ������ 
 * ��ԭ�������ں��в���ʹ��ר�����û�ģʽ�� fs �μĴ���, ��Ҫ���ȱ�����. printk()��������ʹ�� 
 * svprintf() �Բ������и�ʽ������, Ȼ���ڱ����� fs �μĴ���������� ���� tty_write������Ϣ��ӡ��ʾ
 */

/* 
 * �������ں�ģʽʱ, ���ǲ���ʹ�� printf,��Ϊ�Ĵ���fsָ������������Ȥ�ĵط�.
 * �Լ�����һ�� printf����ʹ��ǰ����fs,һ�оͽ����.
 */
#include <stdarg.h>   //��׼����ͷ�ļ�.�Ժ����ʽ������������б�. ��Ҫ˵����һ������(va_list)��������(va_start,va_arg��va_end),
                      // ����vsprintf,vprintf,vfprintf����
#include <stddef.h>   // ��춨��ͷ�ļ�. ������ NULL, offsetof(TYPE,MEMBER)

#include <linux/kernel.h>  // �ں�ͷ�ļ�. ����һЩ�ں˳��ú�����ԭ�ζ���

static char buf[1024];

// ����ú��� vsprintf() �� linux/kernel/vsprintf.c��
extern int vsprintf(char * buf, const char * fmt, va_list args);

// �ں�ʹ�õ���ʾ����
int printk(const char *fmt, ...)
{
	va_list args;                  // va_list ��һ�����ڷ��ʿɱ�����б�Ĺ���.��ͨ����һ��ָ��������ַ�ָ������
	int i;

	va_start(args, fmt);           // ʹ��va_start������ʼ��va_list�仯args,�Ա�����ɷ��ʿɱ�����б�.fmt�ǿɱ�����б��ǰһ����֪����,
								   // ������ȷ�������б����ʼλ��
	i=vsprintf(buf,fmt,args);      // ʹ�ø�ʽ��fmt�������б�args�����buf��.
								   // ����ֵ i ��������ַ����ĳ���
	va_end(args);                  // ʹ�ú�va_end������va_list����args,���ͷ���ɱ�����б���ص���Դ.ͨ������ʹ����ɱ�����б��ı�Ҫ����,
								   // �Ա�֤��Դ��ȷ�ͷ�
	__asm__("push %%fs\n\t"        // ���� fs
		"push %%ds\n\t"
		"pop %%fs\n\t"             // �� fs = ds
		"pushl %0\n\t"             // ���ַ�������ѹ���ջ(���������ջ�ǵ��ò���)
		"pushl $_buf\n\t"          // �� buf �ĵ�ַѹ���ջ
		"pushl $0\n\t"             // ����ֵ 0 ѹ���ջ, ��ͨ����channel
		"call _tty_write\n\t"      // ���� tty_write ����
		"addl $8,%%esp\n\t"        // ����(����)������ջ����(buf,channel)
		"popl %0\n\t"              // �����ַ�������ֵ,��Ϊ����ֵ
		"pop %%fs"                 // �ָ�ԭfs�Ĵ���
		::"r" (i):"ax","cx","dx"); // ֪ͨ������, �Ĵ���ax,cx,dxֵ�����Ѿ��ı�
	return i;                      // �����ַ�������
}
