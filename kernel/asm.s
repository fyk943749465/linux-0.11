/*
 *  linux/kernel/asm.s
 *
 *  (C) 1991  Linus Torvalds
 *   Ӳ���жϳ���
 *   ���ڴ���ϵͳӲ���쳣��������ж�,
 */

/*
 * asm.s contains the low-level code for most hardware faults.
 * page_exception is handled by the mm, so that isn't here. This
 * file also handles (hopefully) fpu-exceptions due to TS-bit, as
 * the fpu must be properly saved/resored. This hasn't been tested.
 */

/*
 * asm.s �����а����󲿷ֵ�Ӳ������(�����)����ĵײ�δ���. ҳ�쳣�����ڴ������� mm �����, ���Բ�������.
 * �˳��򻹴���(ϣ��������) ���� TS-λ����ɵ� fpu �쳣,
 * ��Ϊ fpu ������ȷ�ؽ��б���/�ָ�����, ��Щ��û�в��Թ�.
 */

 # �������ļ���Ҫ�漰�� Intel �������ж� int0 -- int16 �Ĵ���(int17-int31�������ʹ��).
 # ������һЩȫ�ֺ�����������,��ԭ���� traps.c ��˵��

.globl _divide_error,_debug,_nmi,_int3,_overflow,_bounds,_invalid_op
.globl _double_fault,_coprocessor_segment_overrun
.globl _invalid_TSS,_segment_not_present,_stack_segment
.globl _general_protection,_coprocessor_error,_irq13,_reserved

# int0 �����Ǳ�0������(divide_error)�������. ���'_divide_error'ʵ������C���Ժ��� divide_error()�����������ģ���Ӧ������.
# '_do_divide_error'������traps.c��
# ����Ҫ���,������ж�,����Ϊ�û�ִ̬�й����з����˴���, �����Ҫ�����жϳ�����.
# �ڵ����жϳ���֮ǰ,��Ҫ�ȱ����ֳ�,Ȼ���л����ں�̬��,�����ں�̬�ĺ���.
# �����ں�̬�ĺ���ʱ,��Ҫ��������ַ��ջ,����������ջ,���ܹ�����.
_divide_error:
	pushl $_do_divide_error       # ���Ƚ���Ҫ���õĺ�����ַ��ջ.��γ���ĳ����Ϊ0.
no_error_code:                    # �������޳���Ŵ������ڴ�
# xchg1 %eax, (%esp) ����� :
# ��ϵͳ���÷���ʱ������ϵͳ�ں���Ҫ�����û�̬��ִ���ֳ����� ss��esp��eflags��cs �� eip �Ĵ�����ֵ�����Ա���ϵͳ����
# ִ����Ϻ��ܹ������û�̬������ִ���û�������Щ�Ĵ����������û������״̬��ʹ���ں˿���׼ȷ�ػ�ԭ�û������ִ���ֳ���
# �����������ں�̬�У��ں���Ҫִ����Ӧ��ϵͳ���÷������̡�Ϊ�˵�����Щ�������̣�ͨ���Ὣ������ַ���������̵���ڵ�ַ��
# �洢��ĳ���Ĵ����У���ͨ���� eax �Ĵ������ں�ͨ����������ַ���� eax �У����Է���ط��ʺ�ִ��ϵͳ���÷������̡�
# ���� xchgl ָ���ʵ���������ڽ���������������ֵ������������£�����Ŀ���ǽ�ջ��Ԫ�أ���������ַ���� eax �Ĵ����е�ֵ
# ���н�����������Ϊϵͳ���÷������̵ķ���ֵͨ����洢�� eax �Ĵ����С�ͨ������������ϵͳ���÷������̵ĵ�ַ�����ص� 
# eax �Ĵ����У������ں˿������ɵ�ִ����Ӧ��ϵͳ���÷������̣������ڷ�������ִ����Ϻ󣬽�������ص� eax �Ĵ����С�
# ��֮������ eax �Ĵ�����ջ��Ԫ�ص�ֵ��Ϊ��ȷ���ں˿���˳���ص���ϵͳ���÷������̣�����ִ����Ϻ󽫽�����ظ��û�����
# ���ǲ���ϵͳ�ڽ���ϵͳ����ʱ��һ�ֳ���������
	xchgl %eax,(%esp)             # _do_divide_error �ĵ�ַ -> eax, eax ��������ջ  �����ǵ�ֵ���ำ���Է���
								  # ����������ڲ�ʹ�ö���Ĵ���������½�������������ֵ��
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %edi
	pushl %esi
	pushl %ebp
	push %ds                       # 16λ�ĶμĴ�����ջ��ҲҪռ��4���ֽ�
	push %es
	push %fs
	pushl $0		# "error code" #����������ջ
	lea 44(%esp),%edx              # lea 44(%esp), %edx ��x86��������е�һ��ָ����ĺ����ǽ�ջָ�� %esp ����ƫ��44���ֽڵ�λ�õ���Ч��ַ���ص��Ĵ��� %edx �С�
	pushl %edx
	movl $0x10,%edx                # �ں˴������ݶ�ѡ���
	mov %dx,%ds
	mov %dx,%es
	mov %dx,%fs        # �����ϵ� * �ű�ʾ�Ǿ��Ե��ò�����, �����ָ�� PC �޹�
	call *%eax         # ���� C ���� do_divide_error() 
	addl $8,%esp       # �ö�ջָ������ָ��Ĵ���fs��ջ�� 
					   # addl $8, %esp ��x86��������е�һ��ָ����ĺ����ǽ�ջָ�� %esp ��ֵ����8���ֽڣ�ͨ�������ͷ�ջ�ϵ��ڴ�ռ䣬
					   # �Ա��ں�������ʱ����ֲ������ͺ���������ʹ�õ�ջ�ռ䡣
	pop %fs
	pop %es
	pop %ds
	popl %ebp
	popl %esi
	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax          # ����ԭ�� eax �е�����
	iret

# int 1 -- debug �����ж���ڵ�. �������ͬ��
_debug:
	pushl $_do_int3		# _do_debug   C����ָ����ջ
	jmp no_error_code

# int2 -- �������жϵ�����ڵ�
_nmi:
	pushl $_do_nmi
	jmp no_error_code

# int3 -- ͬ_debug
_int3:
	pushl $_do_int3
	jmp no_error_code

# int4 -- ����������ж���ڵ�.
_overflow:
	pushl $_do_overflow
	jmp no_error_code

# int5 -- �߽�������ж���ڵ�.
_bounds:
	pushl $_do_bounds
	jmp no_error_code

# int6 -- ��Ч����ָ������ж���ڵ�
_invalid_op:
	pushl $_do_invalid_op
	jmp no_error_code

# int9 -- Э�������γ��������ж���ڵ�.
_coprocessor_segment_overrun:
	pushl $_do_coprocessor_segment_overrun
	jmp no_error_code

# int 15 - ����
_reserved:
	pushl $_do_reserved
	jmp no_error_code

# int45 -- (=0x20 + 13) ��ѧЭ�������������ж�
# ��Э������ִ����һ�������Ǿͻᷢ��IRQ13�ж��ź�,��֪ͨCPU�������.
_irq13:
	pushl %eax
	xorb %al,%al        # 80387 ��ִ�м���ʱ, CPU��ȴ�����������
	outb %al,$0xF0      # ͨ��д 0xF0 �˿�, ���жϽ�����CPU��BUSY�����ź�,�����¼���80387�Ĵ�������չ��������PEREQ.
					    # �ò�����ҪʱΪ��ȷ���ڼ���ִ��80387���κ�ָ��֮ǰ,��Ӧ���ж�.
	movb $0x20,%al
	outb %al,$0x20      # �� 8259 ���жϿ���оƬ����E01(�жϽ���)�ź�.
	jmp 1f
1:	jmp 1f
1:	outb %al,$0xA0      # ���� 8259 ���жϿ���оƬ����EO1(�жϽ���)�ź�.
	popl %eax
	jmp _coprocessor_error    # _coprocessor_error ԭ���ٱ��Ľ���,�����Ѿ��ŵ���(kernel/system_call.s)

# һЩ�ж��ڵ���ʱ�����жϷ��ص�ַ֮�󽫳����ѹ���ջ, ��˷���ʱҲ��Ҫ������ŵ���.
# int8 -- ˫�������.
_double_fault:
	pushl $_do_double_fault                      # C������ַ��ջ
error_code:
	xchgl %eax,4(%esp)		# error code <-> %eax , eax ԭ����ֵ�������ڶ�ջ��
	xchgl %ebx,(%esp)		# &function <-> %ebx ,  ebx ԭ����ֵ�������ڶ�ջ��
	pushl %ecx
	pushl %edx
	pushl %edi
	pushl %esi
	pushl %ebp
	push %ds
	push %es
	push %fs
	pushl %eax			# error code   # �������ջ
	lea 44(%esp),%eax		# offset   # ���򷵻ص�ַ����ջָ��λ����ջ
	pushl %eax
	movl $0x10,%eax                    # ���ں����ݶ�ѡ���
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	call *%ebx                         # ������Ӧ��C����,���������ջ
	addl $8,%esp                       # ��ջָ������ָ��ջ�з���fs���ݵ�λ��
	pop %fs
	pop %es
	pop %ds
	popl %ebp
	popl %esi
	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	iret

# int10 -- ��Ч������״̬��
_invalid_TSS:
	pushl $_do_invalid_TSS
	jmp error_code

# int11 -- �β�����
_segment_not_present:
	pushl $_do_segment_not_present
	jmp error_code

# int12 -- ��ջ����
_stack_segment:
	pushl $_do_stack_segment
	jmp error_code

# int13 -- һ�㱣���Գ���
_general_protection:
	pushl $_do_general_protection
	jmp error_code


# int7 -- �豸������(_device_not_available)��(kernel/system_call.s)
# int14 -- ҳ����(_page_fault)��(mm/page.s)
# int16 -- Э����������(_coprocessor_error)��(kernel/system_call.s)
# ʱ���ж� int0x20 (_timer_interrupt)��(kernel/system_call.s)
# ϵͳ���� int0x80 (_system_call)��(kernel/system_call.s)