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
! setup.s ����� BIOS �л�ȡϵͳ����,������Щ���ݷŵ�ϵͳ�ڴ���ʵ��ط�.
! ��ʱ setup.s �� system �Ѿ��� bootsect ��������ص��ڴ���.
!
! ��δ���ѯ�� bios �й��ڴ�/����/��������,������Щ�����ŵ�һ��"��ȫ��"�ط�:0x90000 - 0x901FF,
! Ҳ��ԭ�� bootsect ����������ڵĵط�,Ȼ���ڱ�����鸲�ǵ�֮ǰ,�ɱ���ģʽ�� System ��ȡ

! NOTE! These had better be the same as in bootsect.s!
! ע��,������Щ������ú� bootsect.s �е���ͬ!

INITSEG  = 0x9000	! we move boot here - out of the way          ! ԭ�� bootsect �����Ķ�
SYSSEG   = 0x1000	! system loaded at 0x10000 (65536).           ! system �� 0x10000(64k)��
SETUPSEG = 0x9020	! this is the current segment                 ! ���������ڵĶε�ַ

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
! ok, ���������̹��̶�����,���ڽ����λ�ñ����Ա����ʹ��.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax                             ! ��ds�ó�#INITSEG(0x9000).���Ѿ���bootsect���������ù�,����������setup����,linus������Ҫ����������һ��.
	mov	ah,#0x03	! read cursor pos     ! BIOS �ж� 0x10 �Ķ���깦�ܺ� ah = 0x03
	xor	bh,bh                             ! ����: bh = ҳ��
	int	0x10		! save it in known place, con_init fetches   ! 0x10 �ж�
	mov	[0],dx		! it from 0x90000.    ! ���кŴ���� ds:0 ��

										!	�� x86 �ܹ��ļ�����ϣ�ʹ�� 0x10 �ж�������BIOS��Basic Input/Output System���Ĺ��ܣ�
										!   ���� ah �Ĵ�����ֵΪ 0x03 ���ڲ�ѯ���λ�á�
										!	������ԣ��� ah ��ֵΪ 0x03 ʱ��int 0x10 �жϻ᷵��������Ϣ��
										!	ah �Ĵ����а��� 0x03����ʾ���ܺţ����ڲ�ѯ���λ�á�
										!	bh �Ĵ����а�����ǰ����ҳ�루page number����ͨ��Ϊ0��
										!	cx �Ĵ����а�����ǰ���������꣨Y���꣩����0��ʼ����ֵ��
										!	dh �Ĵ����а�����ǰ���������꣨X���꣩����0��ʼ����ֵ��
										!	��ˣ�����ִ�� int 0x10 �жϲ����� ah �Ĵ�����ֵΪ 0x03 ��
										!   �����ͨ����ȡ bh��cx �� dh �Ĵ�������ȡ��ǰ�ı�ģʽ�µĹ��λ����Ϣ��

! Get memory size (extended mem, kB)
						   ! ����3��ȡ��չ�ڴ�Ĵ�Сֵ(KB).�ǵ����ж� 0x15,���ܺ� ah=0x88
						   ! ����: ax = ��0x100000 (1M) ����ʼ����չ�ڴ��С(KB).
						   ! ��������CF��λ, ax = ������

	mov	ah,#0x88
	int	0x15
	mov	[2],ax             ! ����չ�ڴ���ֵ����� 0x90002 ��(1����,��2���ֽ�) ,���0x15���жϲ�ѯʧ��,ax�Ĵ����ĵ��ֽ�al�а����������

! Get video-card data:
						   ! �����������ȡ��ʾ����ǰ��ʾģʽ. ���� BIOS �ж� 0x10,���ܺ� ah=0x0f 
						   ! ����: ah = �ַ�����, al = ��ʾģʽ, bh = ��ǰ��ʾҳ
						   ! 0x90004(1�ֽڴ�ŵ�ǰҳ), 0x90006 ��ʾģʽ  0x90007 �ַ����� 

	mov	ah,#0x0f		
	int	0x10
	mov	[4],bx		! bh = display page                      ! ��ŵ�ǰҳ
	mov	[6],ax		! al = video mode, ah = window width     ! �����ʾģʽ���ַ�����

! check for EGA/VGA and some config parameters
					! �����ʾ��ʽ(EGA/VGA)��ȡ����
					! ���� BIOS �ж� 0x10, ��������ѡ�� - ȡ��ʽ��Ϣ
					! ���ܺ�: ah = 0x12, bl = 0x10
					! ����: bh = ��ʾ״̬ (0x00 - ��ɫģʽ, I/O �˿�=0x3dX)
					!                     (0x01 - ��ɫģʽ, I/O �˿�=0x3bX)
					! bl = ��װ����ʾ�ڴ�
					! (0x00 64k, 0x01 128k, 0x02 192k, 0x03 256k)
					! cx = ��ʾ�����Բ���

					! �� x86 �ܹ��ļ�����У�0x10 �ж����ڷ��� BIOS��Basic Input/Output System���Ĺ��ܡ�
					! �� ah �Ĵ�����ֵΪ 0x12 ʱ����ʾҪ��ѯVGA��Video Graphics Array����SVGA��Super VGA����ʾģʽ��Ϣ��
					! ������ԣ���� ah �Ĵ�����ֵΪ 0x12������ bl �Ĵ�����ֵΪ 0x10�����ʾ��ѯ��ǰVGA��SVGA��ʾģʽ����Ϣ�����ص���Ϣͨ��������
					! ah �Ĵ�����ֵ����ʾ�����Ƿ�ɹ�������ɹ���ah �Ĵ�����ֵΪ 0x12������Ϊ����ֵ����ʾ����
					! al �Ĵ�����ֵ����ʾ��ǰ��VGA��SVGA��ʾģʽ��š�
					! �����Ĵ�����ֵ�����ݲ�ͬ��BIOSʵ�ֺ�Ӳ����������ܻ����������ʾģʽ����Ϣ����ֱ��ʡ���ɫ��ȵȡ�
					! ͨ����ѯ��ǰ��ʾģʽ����Ϣ���������˽⵱ǰ�������ͼ����ʾ���ã�����ڱ�д��ͼ����ʾ��صĳ���������ʾ���÷ǳ����á�

	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax      ! �ڴ浥Ԫ 0x90008 ��ʾ�жϲ�����״̬
	mov	[10],bx     ! �ڴ浥Ԫ 0x9000A = ��װ����ʾ�ڴ� / 0x9000B = ��ʾ״̬(��ɫ/��ɫ)
	mov	[12],cx     ! �ڴ浥Ԫ 0x9000C = ��ʾ�����Բ���


		! Ӳ�̲�����Hard Disk Parameter Table���Ǹ��˼������PC���Ļ�������/���ϵͳ��BIOS���е�һ�����ݽṹ�����ڴ洢����Ӳ�̣�ͨ���ǹ�̬Ӳ�̻��еӲ�̣�
		! �Ļ�����Ϣ�Ͳ�������Щ��Ϣ����Ӳ�̵����������νṹ���ŵ�������������ÿ�ŵ��������ȡ�
		! �����ڵĸ��˼����ϵͳ�У�BIOS�������������м��Ӳ�̲���ȡӲ�̲��������˽�Ӳ�̵����Ժ����á���Щ��������BIOS�Ͳ���ϵͳ��˵������Ҫ�ģ�
		! ��Ϊ���Ǿ����������ȷ�ط��ʺ͹���Ӳ���ϵ����ݡ�
		! ���� int 0x41 �ж�����λ�ô��Ӳ�̲�����������������ȷ�ġ���һЩPC BIOSʵ���У��ر������ڵ�PCϵͳ�У�int 0x41 �ж�����λ�ñ��������
		! ��һ��Ӳ�̵Ļ�����������������������Ӳ�̵ļ�����Ϣ�����ͷ������������ÿ�ŵ��������ȡ�����ϵͳ��Ӧ�ó������ʹ����Щ��������ȷ�ط���Ӳ���ϵ����ݡ�
		! ��ע�⣬���ַ����ǱȽϹ��ϵ��������ִ�����ϵͳ��Ӳ��ͨ��ʹ�ø����ӵķ�ʽ������Ӳ�̣���������������BIOS�е�Ӳ�̲���������һЩ�ɵ�PCϵͳ�У�
		! ��Ȼ���ܻ�ʹ�����ַ�ʽ������Ӳ����Ϣ����ͬ��BIOS�Ͳ���ϵͳ���ܻ��в�ͬ��ʵ�ַ�ʽ����˾���������ܻ�������ͬ��

! Get hd0 data
					! ȡ��һ��Ӳ�̵���Ϣ(����Ӳ�̲�����)
					! ��1��Ӳ�̲�������׵�ַ��Ȼ���ж����� 0x41������ֵ! ����2��Ӳ�̲���������ŵ�1����ĺ���,�ж�����0x46������ֵҲָ�����2��Ӳ�̵Ĳ������׵�ַ.
					! ��ĳ����� 16 ���ֽ�(0x10). �������γ���ֱ��� BIOS �й�����Ӳ�̵Ĳ�����, 0x90080 ����ŵ�1��Ӳ�̵ı�, 0x90090����ŵ�2��Ӳ�̵ı�.
	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x41] ! �ڻ�������У�lds ָ�����ڽ�һ��ָ�����ڴ��ַ�����ݼ��ص�һ���μĴ����У�ͬʱ���õ�ַ�Ķ�ѡ���Ӽ��ص�ָ����ͨ�üĴ����С�
					! x86 32λģʽ��,һ���ж�����ռ4�ֽڵĴ洢�ռ�, ����������ȡ 0x41�ж������� �ε�ַ��ƫ�Ƶ�ַ.
					! ��x86�ܹ��ļ����ϵͳ�У�0x41 ��Ӧ���ж�����ͨ������ϵͳ���ã�System Call����ϵͳ������һ�ֻ��ƣ�
					! �����û��ռ��Ӧ�ó����������ϵͳ�ں��ṩ�ض��ķ�����ܡ���Щ��������ļ����������̹�������ͨ�ŵȡ�
					! �����ϵͳ���ú͹��ܻ������ϵͳ���죬��ͨ�������ɲ���ϵͳ�ṩ����ͨ���ж���������0x41 ���Ա���Ϊһ��ʾ���ж���������ʾһ���ض���ϵͳ���á�
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0080  ! �����Ŀ�ĵ�ַ 0x9000:0x0080 -> es:di 
	mov	cx,#0x10    ! ѭ������ 16��  �� ds:si ָ��� 16 �ֽڴ���� es:di
	rep              
	movsb

! Get hd1 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x46]  ! ȡ�ж����� 0x46��ֵ,Ҳ�� hd1 ������ĵ�ַ -> ds:si
	mov	ax,#INITSEG  
	mov	es,ax
	mov	di,#0x0090   ! �����Ŀ�ĵ�ַ: 0x9000:0x0090 -> es:di 
	mov	cx,#0x10
	rep
	movsb

! Check that there IS a hd1 :-)
						! ���ϵͳ�Ƿ���ڵ�2��Ӳ��,������������2��������.
						! ����BIOS �жϵ��� 0x13 ��ȥ�����͹���.
						! ���ܺ� ah = 0x15 
						! ����: dl = ������(0x8X��Ӳ��, 0x80 ָ��һ��Ӳ��, 0x81 ָ�ڶ���Ӳ��)
						! ���: ah = ������; 00 --û������� CF ��λ; 01 --������,û�� change-line֧��;
						!                     02 --������(���������ƶ��豸), �� change-line ֧��; 03 -- ��Ӳ��

	mov	ax,#0x01500
	mov	dl,#0x81
	int	0x13
	jc	no_disk1        ! ����н�λ,CF=1,��ʾû�еڶ���Ӳ��
	cmp	ah,#3           ! ����Ƿ���Ӳ��
	je	is_disk1        ! �����Ӳ��,��ִ�� is_disk1
no_disk1:               ! ���û�е�2��Ӳ��,��Ե�2��Ӳ�̱�����
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	mov	ax,#0x00
	rep
	stosb               ! stosb ָ�����ڽ� AL �Ĵ����е��ֽ����ݴ洢��Ŀ���ַ�������ݷ����־λ�����������Ʋ������� es:si ��Ŀ��λ��
is_disk1:

! now we want to move to protected mode ...                  ! ���ڲ���ϵͳ�������뱣��ģʽ

	cli			! no interrupts allowed !

! ��������е� cli ָ����һ������ָ����ĺ����� "clear interrupt flag"��������жϱ�־λ��
! ���ָ�����ڽ����жϴ���������ֹCPU��Ӧ�����ж����󣬰����ⲿӲ���жϺ��ڲ��жϡ�
! ��ִ�� cli ָ��ʱ�����ὫCPU���жϱ�־λ��IF��Interrupt Flag������Ϊ 0���Ӷ������жϡ�����ζ�ţ�
! ��ʹ���ⲿ�ж�������Ӳ���жϡ�ʱ���жϵȣ���CPUҲ������Ӧ��Щ�ж�����ֱ���жϱ�־λ����������Ϊ 1��ʹ�� sti ָ��������жϴ�������
! cli �� sti ָ��ͨ���ڲ���ϵͳ�ں������ڹ����жϴ������磬�ڲ���ϵͳ�Ĺؼ��Դ�����У����ܻ�ʹ�� 
! cli ���ر��жϣ���ȷ���ٽ��������ܹ�ԭ��ִ�У������ٽ������������ʹ�� sti �����������жϡ�
! ��֮��cli ָ�����ڽ����жϴ���������ֹCPU��Ӧ�ж����󣬶� sti ָ���������������жϴ�����������CPU��Ӧ�ж�����
! ��Щָ���ڶ��������ϵͳ���ٽ��������ʵ���зǳ����á�

! first we move the system to it's rightful place

! �������ǽ� system ģ���ƶ�����ȷ��λ��. bootsect ���������ǽ� system ģ����뵽�� 0x10000(64k) ��ʼ��λ��.���ڵ�ʱ���� system ģ����󳤶Ȳ��ᳬ�� 0x80000(512k)
! Ҳ����ĩ�˲��ᳬ���ڴ��ַ 0x90000, ����bootsect �Ὣ�Լ��ƶ��� 0x90000 ��ʼ�ĵط�,���� setup ���ص����ĺ���.
! ������γ������;�ǰ����� system ģ���ƶ��� 0x00000 λ��,���Ѵ�0x10000 ��0x8ffff���ڴ����ݿ�(512k),��������ڴ�Ͷ�
! �ƶ��� 0x10000(64k)��λ��

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
