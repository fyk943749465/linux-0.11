/*
 *  linux/kernel/system_call.s
 *
 *  (C) 1991  Linus Torvalds
 *  ϵͳ���ó���
 *	
 *	ʵ���� Linux ϵͳ���� (int 0x80) �Ľӿڴ������,ʵ�ʵĴ�����̰����ڸ�ϵͳ����
 *  ��Ӧ�� C ���Դ�������,��Щ�������ֲ�������Linux�ں˴�����.
 *
 */

/*
 *  system_call.s  contains the system-call low-level handling routines.
 * This also contains the timer-interrupt handler, as some of the code is
 * the same. The hd- and flopppy-interrupts are also here.
 *
 * NOTE: This code handles signal-recognition, which happens every time
 * after a timer-interrupt and after each system call. Ordinary interrupts
 * don't handle signal-recognition, as that would clutter them up totally
 * unnecessarily.
 *
 * Stack layout in 'ret_from_system_call':
 *
 *	 0(%esp) - %eax
 *	 4(%esp) - %ebx
 *	 8(%esp) - %ecx
 *	 C(%esp) - %edx
 *	10(%esp) - %fs
 *	14(%esp) - %es
 *	18(%esp) - %ds
 *	1C(%esp) - %eip
 *	20(%esp) - %cs
 *	24(%esp) - %eflags
 *	28(%esp) - %oldesp
 *	2C(%esp) - %oldss
 */

/*
 * system_call.s �ļ�����ϵͳ����(system_call)�ײ㴦���ӳ���. ������Щ����Ƚ�����,����ͬʱ 
 * Ҳ����ʱ���жϴ���(timer-interrupt)���. Ӳ�̺����̵��жϴ������Ҳ������.
 * 
 * ע��: ��δ��봦���ź�(signal)ʶ��,��ÿ��ʱ���жϺ�ϵͳ����֮�󶼻����ʶ��.һ���ж��ź�
 * ���������ź�ʶ��, ��Ϊ���ϵͳ��ɻ���.
 * 
 * ��ϵͳ���÷���(ret_from_system_call)ʱ��ջ�����ݼ����� 24-35��
 */

SIG_CHLD	= 17             # ���� SIG_CHLD �ź�(�ӽ���ֹͣ�����)

EAX		= 0x00               # ��ջ�и����Ĵ�����ƫ��λ��
EBX		= 0x04
ECX		= 0x08
EDX		= 0x0C
FS		= 0x10
ES		= 0x14
DS		= 0x18
EIP		= 0x1C
CS		= 0x20
EFLAGS		= 0x24
OLDESP		= 0x28           # ������Ȩ���仯ʱ
OLDSS		= 0x2C

# ������Щ������ṹ(task_struct)�б�����ƫ��ֵ,�μ�include/linux/sched.h 
state	= 0		# these are offsets into the task-struct.  # ����״̬��
counter	= 4         # ��������ʱ�����(�ݼ�)(�δ���),����ʱ��Ƭ
priority = 8        # ����������. ����ʼ����ʱ counter=priority,Խ��������ʱ��Խ��
signal	= 12        # �ź�λͼ,ÿ������λ����һ���ź�,�ź�ֵ=λƫ��ֵ+1 
sigaction = 16		# MUST be 16 (=len of sigaction)   // sigaction �ṹ���ȱ�����16�ֽ�
				    # �ź�ִ�����Խṹ�����ƫ��ֵ,��Ӧ�źŽ�Ҫִ�еĲ����ͱ�־��Ϣ
blocked = (33*16)   # �������ź�λͼ��ƫ����

# ���¶����� sigaction �ṹ�е�ƫ����, �μ� include/signal.h
# offsets within sigaction
sa_handler = 0              # �źŴ�����̵ľ��(������)
sa_mask = 4                 # �ź���������
sa_flags = 8                # �źż�
sa_restorer = 12            # �ָ�����ָ��, �μ� kernel/signal.c

nr_system_calls = 72        # Linux 0.11 ���ں��е�ϵͳ��������

/*
 * Ok, I get parallel printer interrupts while using the floppy for some
 * strange reason. Urgel. Now I just ignore them.
 */

/*
 * ����,��ʹ������ʱ���ռ����˲��д�ӡ���ж�,�����.��,���ڲ�����.
 *
 */
# ������ڵ�
.globl _system_call,_sys_fork,_timer_interrupt,_sys_execve
.globl _hd_interrupt,_floppy_interrupt,_parallel_interrupt
.globl _device_not_available, _coprocessor_error

# �����ϵͳ���ú�
.align 2                          # �ڴ� 4 �ֽڶ���
bad_sys_call:
	movl $-1,%eax                 # eax ����-1,�˳��ж�
	iret

# ����ִ�е��ȳ������. ���ȳ��� schedule��(kernel/sched.c)
.align 2
reschedule:
    # ����ָ��������ǽ� ret_from_sys_call ��ַ����ջ�У��Ա���ϵͳ����ִ����ɺ��ܹ���ȷ���ص��û��ռ䡣
    # ��ϵͳ���ô���Ĺ����У��ں˻��ڶ�ջ�б���һЩ״̬��Ϣ���������ϵͳ����ʱʹ�������ַ�����ص��û������У�����ִ���û�����Ĵ��롣
	pushl $ret_from_sys_call       # �� ret_from_sys_call �ĵ�ַ��ջ(101��)
	jmp _schedule                  # ��sched.c�ж���

# int 0x80 -- linux ϵͳ������ڵ�(�����ж� int 0x80, eax ��ʱ���ú�)
.align 2
_system_call:
	cmpl $nr_system_calls-1,%eax   # ���ú����������Χ�Ļ�����eax����-1���˳�
	ja bad_sys_call                # ��������˺Ϸ���ϵͳ���ú�,0-71, ��ϵͳ����ֱ���˳�
	push %ds                       # ����ԭ�μĴ���ֵ
	push %es
	push %fs
	pushl %edx            # ebx, ecx, edx �з�������Ŷ�Ǹ�������Ӧ��C���Ժ����ĵ��ò���
	pushl %ecx		# push %ebx,%ecx,%edx as parameters
	pushl %ebx		# to the system call
	movl $0x10,%edx		# set up ds,es to kernel space
	mov %dx,%ds         # ds, esָ���ں����ݶ�(ȫ���������������ݶ�������)
	mov %dx,%es
	movl $0x17,%edx		# fs points to local data space
	mov %dx,%fs         # fsָ��ֲ����ݶ�(�ֲ��������������ݶ�������)

# �������������ĺ�����:���õ�ַ = _sys_call_table + %eax * 4 
# ��Ӧ��C�����е� sys_call_table��include/linux/sys.h��,���ж�����һ������72��
# ϵͳ����C�������ĵ�ַ�����.
	call _sys_call_table(,%eax,4)
	pushl %eax                       # ϵͳ���õķ���ֵ��ջ
	movl _current,%eax               # ȡ��ǰ����(����)���ݽṹ��ַ -> eax (_current�ǵ�ǰ����,��sched.c�ж���)

# ����鿴��ǰ���������״̬.������ھ���״̬(state������0)��ȥִ�е��ȳ���
	cmpl $0,state(%eax)		# state       # ��Ȼ����״̬��0�Ƚ�
	jne reschedule                        # �����ǰ����״̬������0,��ִ�� reschedule, ����c���Ե� schedule()����
	cmpl $0,counter(%eax)		# counter # ����ʱ��Ƭ��0�Ƚ�
	je reschedule                         # ��������ʱ��Ƭ������,����� schedule()

# ������δ���ִ�д�ϵͳ����C�������غ�,���ź�������ʶ����.
ret_from_sys_call:
    
	# �����б�ǰ�����ͷ��ǳ�ʼ������task0,������򲻱ض�������ź�������Ĵ���,ֱ�ӷ���
	movl _current,%eax		# task[0] cannot have signals
	cmpl _task,%eax         # _task ��Ӧ c�����е� task[] ����,ֱ������task�൱������task[0], ��ǰ������task[0]�Ƚ�
	je 3f                   # �����ǰ������task[0],����ǰ��ת�� 3 ��Ŵ�
	
	# ͨ����ԭ���ó������ѡ����ļ�����жϵ��ó����ͷ����ں�����(��������1). �����ֱ���˳��ж�
    # ���������ͨ��������Ҫ�����ź����Ĵ���. ����Ƚ�ѡ����Ƿ�Ϊ��ͨ�û�����ε�ѡ��� 0x000f (RPL=3, �ֲ���, ��һ����(�����))
    # �����������ת�˳��жϳ���.
	cmpw $0x0f,CS(%esp)		# was old code segment supervisor ?
	jne 3f

	# ���ԭ��ջ��ѡ�����Ϊ0x17(Ҳ��ԭ��ջ�����û����ݶ���),��Ҳ�˳�.
	cmpw $0x17,OLDSS(%esp)		# was stack segment = 0x17 ?
	jne 3f

	# ������δ������;������ȡ��ǰ����ṹ�е��ź�λͼ(32λ,ÿλ����1���ź�),Ȼ��������ṹ�е��ź�����(����)��,������������ź�λ,
    # ȡ����ֵ��С���ź�ֵ,�ٰ�ԭ�ź�λͼ�и��źŶ�Ӧ��λ��λ(��0),��󽫸��ź�ֵ��Ϊ����֮һ����do_signal()
    # do_signal() ��(kernel/signal.c)��, ���������13����ջ����Ϣ.
	movl signal(%eax),%ebx        # ȡ�ź�λͼ->ebx, ÿ1λ����1���ź�,��32���ź�
	movl blocked(%eax),%ecx       # ȡ����(����)�ź�λͼ ->ecx
	notl %ecx                     # ÿλȡ��
	andl %ebx,%ecx                # �����ɵ��ź�λͼ
	bsfl %ecx,%ecx                # �ӵ�λ(λ0)��ʼɨ��λͼ,���Ƿ���1��λ, ����,��ecx������Ϊ��ƫ��ֵ(���ڼ�λ0-31)
	je 3f                         # ���û���ź�,����ǰ��ת�˳�
	btrl %ecx,%ebx                # ��λ���ź�(ebx����ԭsignalλͼ)
	movl %ebx,signal(%eax)        # ���±���signal λͼ��Ϣ -> current-signal. 
	incl %ecx                     # ���ź���תΪ��1��ʼ����(1-32)
	pushl %ecx                    # ���ź�ֵ��ջ,��Ϊ����do_signal�Ĳ���֮һ
	call _do_signal               # ���� C �����źŴ������(kernel/signal.c)
	popl %eax                     # �����ź�ֵ
3:	popl %eax
	popl %ebx
	popl %ecx
	popl %edx
	pop %fs
	pop %es
	pop %ds
	iret


# int16 -- ������δ��봦��Э�����������ĳ����ź�.��תִ��C����math_error()
# (kernel/math/math_emulate.c) ���غ���ת�� ret_from_sys_call ������ִ��.
.align 2
_coprocessor_error:
	push %ds
	push %es
	push %fs
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl %eax
	movl $0x10,%eax           # ds,es��Ϊָ���ں����ݶ�
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax           # fs ��Ϊָ��ֲ����ݶ�(�����������ݶ�)
	mov %ax,%fs
	pushl $ret_from_sys_call  # ��������÷��صĵ�ַ��ջ
	jmp _math_error           # ִ�� C ���� math_error() (kernel/math/math_emulate.c)


# int7 -- �豸�����ڻ�Щ��������
# ������ƼĴ��� CR0 �� EM ��־��λ,�� CPU ִ��һ�� ESC ת��ָ��ʱ�ͻ��������ж�, �����Ϳ����л���������ж�
# �������ģ�� ESC ת��ָ��. CR0��TS��־ʱ�� CPU ִ������ת��ʱ���õ�. TS ��������ȷ��ʲôʱ��Э�������е�����(������)
# �� CPU ����ִ�е�����ƥ����. �� CPU ������һ��ת��ָ��ʱ����TS��Ϊ,�ͻ��������ж�. ��ʱ��Ӧ�ûָ��������Щ����
# ִ��״̬. �μ�(kernel/sched.c)�е�˵��. ���ж����ת�Ƶ���� ret_from_sys_call ��ִ����ȥ.
.align 2
_device_not_available:
	push %ds
	push %es
	push %fs
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl %eax
	movl $0x10,%eax             # ds,es��Ϊָ���ں����ݶ�
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax             # fs ��Ϊָ��ֲ����ݶ�(�����������ݶ�)
	mov %ax,%fs
	pushl $ret_from_sys_call    # ��������ת����õķ��ص�ַ��ջ

	# clts ָ������������ƼĴ��� CR0 �е� Task-Switched Flag��TSF��λ����ȡ�������л��ı�־��
    # ʹ����������ִ�е�ǰ���������ڲ���ϵͳ�ں˿�����ʹ�õ�һ����Ҫָ�						
	clts				# clear TS so that we can use math  (TSλ�ǵ�3λ,EMΪ��2λ, ��0��ʼ��31)
	movl %cr0,%eax
	testl $0x4,%eax			# EM (math emulation bit)

	# �������λ���ԣ���� CR0 �Ĵ����ĵ� 2 λ�Ƿ����ã��� EM λ����������Э����������ѧ���棩����� EM λ�������Ϊ0����
    # ��ִ����ת�� _math_state_restore ��ǩ����ʾ������Э���������ã�����Ҫ������ѧ���档
	je _math_state_restore
	pushl %ebp
	pushl %esi
	pushl %edi

	# "��ѧ����"��Math Emulation����һ���ڲ��߱�Ӳ��������֧�ֵ�ϵͳ��ģ�⸡��������ļ�������ĳЩ����ļ����ϵͳ�У�û��Ӳ����������������
	# ����޷�ֱ��ִ�и��������㡣Ϊ��֧�ָ��������㣬ϵͳ������Ա��Ҫʵ�ָ�������������ģ�⣬����ѧ���档
	# ��ѧ����Ļ���˼����ʹ�����������λ������ģ�⸡�������㡣������ģ�⸡�����ļӷ����������˷��������Ȼ������㣬�Լ��������������������
	# ������������NaN�������֣�������ȡ�
	# ��ѧ�����ʵ�ֿ����൱���ӣ���Ϊ�����������漰�����淶�;���Ҫ����ˣ���ѧ���������ͨ���ϵͣ�������Ҫ�����ļ�����Դ�ʹ�����ʵ�֡�
	# ��ĳЩ����£���ѧ���������Ȼ�Ǳ�Ҫ�ģ�������û��Ӳ��������֧�ֵ�Ƕ��ʽϵͳ�У�������ģ���������еĳ������и�����������Ҫ��ģ�����н��С�
	# �����ṩ�Ļ������У�����⵽���ƼĴ��� CR0 �� EM λ��λ 2��������ʱ����ζ�Ÿ�����Э����������ѧ���汻���ã������Ҫִ����Ӧ����ѧ���������
	# ֧�ָ��������㡣������� EM λ�������˵��Ӳ��������֧�ֿ��ã�����Ҫ���з��档����Ϊ����û��Ӳ��������֧�ֵ�ϵͳ��ģ�⸡���������һ�ֳ���������
	call _math_emulate
	popl %edi
	popl %esi
	popl %ebp
	ret                  # ��ת�� ret_from_sys_call ��ִ��


# int32 -- (int 0x20)ʱ���жϴ������.�ж�Ƶ�ʱ�����Ϊ 100Hz (include/linux/sched.h),
# ��ʱоƬ 8253/8254 ����(kernel/sched.c)����ʼ����. ������� jiffies ÿ10�����1.
# ��δ��뽫 jiffies ��1,���ͽ����ж�ָ���8259������,Ȼ���õ�ǰ��Ȩ����Ϊ�������� C 
# ���� do_time(long CPL). �����÷���ʱתȥ��Ⲣ�����ź�.
.align 2
_timer_interrupt:
	push %ds		# save ds,es and put kernel data space
	push %es		# into them. %fs is used by _system_call
	push %fs
	pushl %edx		# we save %eax,%ecx,%edx as gcc doesn't
	pushl %ecx		# save those across function calls. %ebx
	pushl %ebx		# is saved as we use that in ret_sys_call
	pushl %eax
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	incl _jiffies       # �ӿ�����ʼ����ĵδ���ʱ��ֵ(10ms/�δ�), ���ｫ�δ���+1

	# �ڼ����Ӳ���Ͳ���ϵͳ����EOI��End Of Interrupt����һ����д����ʾ�жϴ���Ľ����źš�EOI �ź�����֪ͨ�жϿ����������磬PIC��APIC�ȣ�
	# ������Ӳ���������������ڴ�����ж��Ѿ�������ϣ����Լ������������жϻ�����
	# EOI ͨ�����жϷ������̣�ISR��ִ����ɺ��͡�������ϵͳ��Ӳ������ĳ���ж�ʱ������ִ����Ӧ���жϴ�����򣬴�����󣬷��� EOI �źš�
	# ����źŵķ��͸����жϿ��������Խ��ж�״̬�������������ܺʹ�����һ���жϡ�
	# EOI ��ȷ��ʵ�ַ�ʽȡ�����жϿ�������Ӳ��ƽ̨����x86��ϵ�ṹ�У��������������жϿ�������8259A �ɱ���жϿ�������PIC���͸߼��ɱ���жϿ�������APIC����
	# ������������£�EOI �ķ�ʽ���ܲ�ͬ��
	# ��֮��EOI ���жϴ���Ľ����źţ�����֪ͨӲ���жϿ�������������������ǰ�ж��Ѿ�������ϣ����Լ������������жϻ�����

	# ���ڳ�ʼ���жϿ���оƬʱû�в����Զ�EOI,����������Ҫ��ָ�������Ӳ���ж�.
	movb $0x20,%al		# EOI to interrupt controller #1
	outb %al,$0x20      # ���������� OCW2 �� 0x20 �˿�

	# ���������ѡ�����ȡ����ǰ��Ȩ����(0��3)��ѹ���ջ, ��Ϊ do_timer �Ĳ���

	# movl CS(%esp), %eax ��һ�����ָ����ĺ����ǴӶ�ջ�ж�ȡλ��ջ����һ������ CS ��ƫ��������˫�֣�4�ֽڣ����ݣ����������ݼ��ص� %eax �Ĵ����С�
    # ���ָ��ľ��庬��͹���ȡ���������ģ��ر���ջ�����ݵĽṹ����;�������ָ���У�CS ͨ����һ�������ջ����ƫ���������ڷ����ض����ݻ��߿���ջ�ϵ�ĳЩ������
    # ��Ҫע����ǣ����ָ���е� CS ������һ��ռλ������ʵ�ʵ�ƫ���������ڴ���������ط������˶������㡣��ˣ�Ϊ����ȷ������ָ��ĺ��壬��Ҫ�鿴
	# ָ�������������Լ��κ���صĴ��롣
	movl CS(%esp),%eax          # CS�������ջ��esp��һ��ƫ����
	andl $3,%eax		# %eax is CPL (0 or 3, 0=supervisor)
	pushl %eax


	# do_timer(CPL)ִ�������л�,��ʱ�ȹ���,��kernel/shched.c ʵ��
	call _do_timer		# 'do_timer(long CPL)' does everything from
	addl $4,%esp		# task switching to accounting ...   ָ���µ�ջ��λ��
	jmp ret_from_sys_call    # ʱ���жϵ��÷���

# ���� sys_execve()ϵͳ����. ȡ�жϵ��ó���Ĵ���ָ����Ϊ��������C����do_execve()
.align 2
_sys_execve:

	# lea EIP(%esp), %eax ���д���ʹ���� x86 ��������е� LEA ָ��京���ǽ�ջ��ָ�� %esp �Ĵ�����ֵ��ָ��ָ�� %eip ��ӣ�Ȼ�󽫽�����ص� %eax �Ĵ����С�
    # ��Ҫע����ǣ�������������У�EIP �� ESP ����ͨ���ļĴ����������ǼĴ�������չ��ʽ��ͨ����EIP ��ָ��ָ��Ĵ�����ESP ��ջָ��Ĵ������ڻ�������У�
	# �Ĵ�������ͨ���� % ��ͷ������ %eip �� %esp��
	# ���ָ���ʵ�ʺ���ȡ���������ģ���Ϊ�ڻ�������У��Ĵ������ڴ��ַ�����Զ��ַ�ʽ�����һ��LEA ָ��ͨ��������ִ��һЩ���ӵĵ�ַ���㣬�����Ǽ򵥵ļ��ء�
    # ��ˣ�Ҫ��ȫ������ָ��ĺ��壬��Ҫ�鿴���ڳ�����������������ʹ�õģ����� EIP �� ESP �ľ���ֵ�Լ�ָ������Ĳ�����
	lea EIP(%esp),%eax
	pushl %eax
	call _do_execve
	addl $4,%esp     # ��������ʱѹ��ջ�� EIP ֵ
	ret            

# sys_fork()����,���ڴ����ӽ���,��system_call����2. ԭ���� include/linux/sys.h��.
# ���ȵ���C���� find_empty_process(),ȡ��һ�����̺�pid.�����ظ�����˵��Ŀǰ������������.
# Ȼ����� copy_process() ���ƽ���.
.align 2
_sys_fork:
	call _find_empty_process            # ���� find_empty_process() (kernel/fork.c)
	testl %eax,%eax                     # ����,Ӱ���־�Ĵ���SFλ,���ű�־λ
	js 1f                               # ������Խ��Ϊ����,����ת�����1��ִ��
	push %gs
	pushl %esi
	pushl %edi
	pushl %ebp
	pushl %eax
	call _copy_process                  # ����C������ copy_process()(kernel/fork.c)
	addl $20,%esp                       # ������������ѹջ������
1:	ret


# int46 -- (int 0x2E) Ӳ���жϴ������,��ӦӲ���ж����� IRQ14
# ��Ӳ�̲�����ɻ����ͻᷢ�����ж��ź�.(�μ�kernel/blk_drv/hd.c)
# ������8259A�жϿ��ƴ�оƬ���ͽ���Ӳ���ж�ָ��(EOI),Ȼ��ȡ����do_hd�еĺ���ָ�����edx
# �Ĵ�����,����do_hdΪNULL,�����ж�edx����ָ���Ƿ�Ϊ��. ���Ϊ��,���edx��ֵָ��unexpected_hd_interrupt(),������ʾ������Ϣ.
# �����8259A��оƬ����EOIָ��,������edx��ָ��ָ��ĺ���:read_intr(), write_intr()��unexpected_hd_interrupt().
_hd_interrupt:
	pushl %eax
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	# ���ڳ�ʼ���жϿ���оƬʱû�в����Զ� EOI,����������Ҫ��ָ�������Ӳ���ж�.
	movb $0x20,%al
	outb %al,$0xA0		# EOI to interrupt controller #1
	jmp 1f			# give port chance to breathe
1:	jmp 1f          # ��ʱ����
1:	xorl %edx,%edx
	# xchgl ��x86��������е�ָ����ĺ�����"������exchange��������������ֵ"��������˵��xchgl ���ڽ���һ��ͨ�üĴ�����һ���ڴ�λ�û���һ���Ĵ�����ֵ��
	# xchgl ָ� operand1 �� operand2 ��ֵ���н������� operand1 ��ֵ����Ϊ�µ� operand2 ��ֵ���� operand2 ��ֵ����Ϊ�µ� operand1 ��ֵ��
	# �������������ԭ�ӵģ����ᱻ�жϣ�����ڶ��̻߳����̻���������ͬ�������Ƿǳ����õġ�
	xchgl _do_hd,%edx            # do_hd����Ϊһ������ָ��,������ֵread_intr()��write_intr()������ַ.(kernel/blk_drv/hd.c)
								 # �ŵ�edx �Ĵ�����ͽ� do_hd ָ�������Ϊ NULL
	testl %edx,%edx              # ���Ժ���ָ���Ƿ�ΪNULL
	jne 1f                       # ����,��ʹָ��ָ��C���� unexpected_hd_interrupt()
	movl $_unexpected_hd_interrupt,%edx
1:	outb %al,$0x20               # ����8259A�жϿ�����EOIָ��(����Ӳ���ж�)
	call *%edx		# "interesting" way of handling intr.   ����do_hdָ��� C ����
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

# int38 -- (int 0x26) �����������жϴ������,��ӦӲ���ж����� IRQ6
# �䴦������������Ӳ�̵Ĵ������һ��(kernel/blk_drv/floppy.c)
# ������ 8259A �жϿ�������оƬ���� EOI ָ��, ����ȡ����do_floppy�еĺ���ָ����� eax �Ĵ�����, ���� do_floppyΪNULL, 
# �����ж� eax ����ָ���Ƿ�Ϊ��. ��Ϊ��,��� eax ��ֵָ�� unexpected_floppy_interrupt(),������ʾ������Ϣ. ������ eax ָ��
# �ĺ��� : rw_interrupt, seek_interrupt, recal_interrupt, reset_interrupt �� unexpected_floppy_interrupt 
_floppy_interrupt:
	pushl %eax
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	movl $0x17,%eax
	mov %ax,%fs
	movb $0x20,%al
	outb %al,$0x20		# EOI to interrupt controller #1
	xorl %eax,%eax
	xchgl _do_floppy,%eax       # do_floppy Ϊһ����ָ��,������ֵʵ�ʴ��� C ��������, 
								# �ŵ� eax �Ĵ�����ͽ� do_floppy ָ������ÿ�.
	testl %eax,%eax             # ���Ժ���ָ���Ƿ����NULL?
	jne 1f
	movl $_unexpected_floppy_interrupt,%eax
1:	call *%eax		# "interesting" way of handling intr.  ���� do_floppy ָ��ĺ���
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

# int 39 -- (int 0x27) ���п��жϴ������, ��ӦӲ���ж������ź�IRQ7
# ���汾�ں˻�Ϊʵ��,����ֻ�Ƿ��� EOI ָ�� 
_parallel_interrupt:
	pushl %eax
	movb $0x20,%al
	outb %al,$0x20
	popl %eax
	iret
