!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.                   SYS_SIZE��Ҫ���صĽ���(16�ֽ�Ϊ1��).0x3000 ��Ϊ 0x30000 �ֽ� = 196kb,���ڵ�ǰ�İ汾�Ѿ��㹻��.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux
!
SYSSIZE = 0x3000     ! ָ�������Ӻ� system ģ��Ĵ�С. ���������һ�����Ĭ��ֵ
!
!	bootsect.s		(C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves           bootsect.s �� bios �����ӳ�������� 0x7c00(31kb)��,�����Լ��ƶ�����ַ0x90000(576kb)��,����ת������
! iself out of the way to address 0x90000, and jumps there.
!
! It then loads 'setup' directly after itself (0x90200), and the system            ��Ȼ��ʹ��bios�жϽ�'setup'ֱ�Ӽ��ص��Լ��ĺ���(0x90200)(576.5kb),����system���ص���ַ0x10000��
! at 0x10000, using BIOS interrupts. 
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no          ע��!Ŀǰ���ں�ϵͳ��󳤶�����Ϊ(8*65536)(512k)�ֽ�,��ʹʵ�ڽ�����ҲӦ��ûʲô�����.�����������ּ�
! problem, even in the future. I want to keep it simple. This 512 kB               ����.����512k������ں˳���Ӧ���㹻��,��������û����minix��һ���������������ٻ���
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
!
! The loader has been made as simple as possible, and continuos                    ���س����Ѿ����Ĺ�����,���Գ����Ķ�����������ѭ��.ֻ���ֹ�����.ֻҪ����,ͨ���쳣��ȡ���е�����,
! read errors will result in a unbreakable loop. Reboot by hand. It                ���ع��̿������ĸ���
! loads pretty fast by getting whole sectors at a time whenever possible.

.globl begtext, begdata, begbss, endtext, enddata, endbss                          ! ������6��ȫ�ֱ�ʶ��
.text                 ! �ı���
begtext:              
.data                 ! ���ݶ�
begdata:
.bss                  ! δ��ʼ�����ݶ�(Block Started by Symbol)
begbss:
.text

SETUPLEN = 4				! nr of setup-sectors                          ! setup�����������ֵ(setup�����С��ռ�õ�����)
BOOTSEG  = 0x07c0			! original address of boot-sector              ! bootsect ��ԭʼ��ַ(�Ƕε�ַ),��CPU�ӵ��,BIOS�����0�ŵ�0����1������ȡ������bootsect������ڴ˴���
INITSEG  = 0x9000			! we move boot here - out of the way           ! ����bootsect�����ֽ��ƶ������ڴ�λ��
SETUPSEG = 0x9020			! setup starts here                            ! ��0�ŵ�0����2������ʼ��ȡ4��������, ��ȡ��setup����,������ڴ�����λ��,���ƶ����bootsect����֮��
SYSSEG   = 0x1000			! system loaded at 0x10000 (65536).            ! system ģ����ص��� 0x10000(64kb)��
ENDSEG   = SYSSEG + SYSSIZE		! where to stop loading                    ! ֹͣ���صĶε�ַ

! ROOT_DEV:	0x000 - same type of floppy as boot.                ! ���ļ�ϵͳ�豸ʹ�����������豸
!		0x301 - first partition on first drive etc              ! ��1��Ӳ�̵ĵ�1������
ROOT_DEV = 0x306            ! ָ�����ļ�ϵͳ�豸�ǵ�2��Ӳ�̵ĵ�1������.
							! ���� Linux ��ʽ��Ӳ��������ʽ,����ֵ�ĺ�������:
							! �豸�� = ���豸�� * 256 + ���豸��(Ҳ��dev_no = (major<<8) + minor)
							! ���豸��: 1-�ڴ�,2-����,3-Ӳ��,4-ttyx,5-tty,6-���п�,7-�������ܵ�
							! 0x300 - /dev/hd0   -  ����������1��Ӳ��
							! 0x301 - /dev/hd1   -  ��1��Ӳ�̵ĵ�1������
							! ...
							! 0x304 - /dev/hd4   -  ��1��Ӳ�̵ĵ�4������
							! 0x305 - /dev/hd5   -  ����������2��Ӳ��
							! 0x306 - /dev/hd6   -  ��2��Ӳ�̵ĵ�1������
							! ...
						    ! 0x306 - /dev/hd9   -  ��2��Ӳ�̵ĵ�4������
							! �� linux �ں�0.95�汾���Ѿ�ʹ����������ͬ������������

entry start          ! ��֪���ӳ���,����� start ��ſ�ʼִ��.
start:               ! ������(bootsect)��Ŀǰ��0x7C00(31KB)�ƶ���0x9000(576KB)��,��256��(512�ֽ�),Ȼ����ת���ƶ���Ĵ����go��Ŵ�ִ��,�����������һ�����
	mov	ax,#BOOTSEG        ! ��ds�μĴ�����Ϊ0x7C0
	mov	ds,ax
	mov	ax,#INITSEG
	mov	es,ax              ! ��es�μĴ�����Ϊ0x9000
	mov	cx,#256            ! �ƶ�����ֵ 256��
	sub	si,si              ! Դ��ַ  ds:si = 0x7C00:0x0000
	sub	di,di              ! Ŀ���ַes:di = 0x9000:0x0000
	rep                    ! �ظ�ִ��,ֱ�� cx = 0
	movw                   ! �ƶ�1����
	jmpi	go,INITSEG     ! ��ת��INITSEGָ���Ķε�ַ,go���ָ����ƫ�Ƶ�ַ��,����ִ��,������޸�CS�Լ�IP�Ĵ�����ֵ
go:	mov	ax,cs              ! �����￪ʼ,�Ѿ��ڶε�ַ 0x9000 ����ʼִ����, ����Ĵ������ڶε�ַ 0x7c0 ��ִ�е�
	mov	ds,ax              ! �� ds,es��ss���ó��ƶ���������ڵĶδ�(0x9000).���ڳ������ж�ջ����(push,pop,call),��˱������ö�ջ
	mov	es,ax
! put stack at 0x9ff00.
	mov	ss,ax			   ! ����ջָ�� SS:SP ָ�� 0x9ff00(�� 0x9000:0xff00)��
	mov	sp,#0xFF00		! arbitrary value >>512
							!���ڴ�����ƶ�����,����Ҫ�������ö�ջ�ε�λ��. SP ֻҪָ��Զ���� 512 ƫ��(����ַ0x90200)��������.��Ϊ
							!��0x90200 ��ַ��ʼ����Ҫ���� setup ����,����ʱ setup �����ԼΪ 4 ������,��� sp Ҫָ����� (0x200 + 0x200*4 + ��ջ��С) ��

! load the setup-sectors directly after the bootblock.   ! �� bootsect ����������ż��� setup ģ��Ĵ�������
! Note that 'es' is already set up.                      ! ע�� es �Ѿ����ú���(���ƶ�����ʱ,es�Ѿ�ָ��Ŀ�Ķε�ַ��0x9000)

load_setup:
	mov	dx,#0x0000		! drive 0, head 0               DH=0x00 ����ָ����ͷ�� DL��ʾӲ�������� 0x80��ʾ��Ӳ�� 0x81��ʾ��Ӳ��
	mov	cx,#0x0002		! sector 2, track 0             CH=0x00 ��ʾ�����     CL=0x02 ��ʾ������
	mov	bx,#0x0200		! address = 512, in INITSEG     es:bx=0x9000:0x0200 = 0x90200 ��������0�ŵ�2���������ݶ�ȡ���ڴ�0x90200��,��ȡ4������
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors  AH=0x02 ��ʾ������     AL=0x04 ��ʾ��ȡ����������
	int	0x13			! read it                       0x13 ���ж�,����ʼ��Ӳ�����ڴ������, 13���ж�ͨ����Ӱ���־�Ĵ����� CFλ��ZFλ.��13���ж�02���ܱ�ʾ������,��ô��������Ľ��Ϊ0,��ZF��1,������0
	jnc	ok_load_setup		! ok - continue             juc��ʾ��λ��־λFC=0,�������ת; 13���жϵ��µ�: CF=0��ʾ�жϳ���ִ����ȷ; CF=1��ʾ�жϳ���ִ�г�����
	mov	dx,#0x0000
	mov	ax,#0x0000		! reset the diskette            ��λ����  AH=0x00 ��λ����������
	int	0x13                                            !13���ж�ִ��, AH=0x00 ��λ����  ִ�� 13���жϵĸ�λ����,��λ����
	j	load_setup

ok_load_setup:
						! ����bios�ж� int 0x13 ��setupģ��Ӵ��̵�2��������ʼ���� 0x90200��ʼ��,����ȡ4������.���������,��λ������,������,û����·.

						! ���ܺţ�ͨ������ CPU �Ĵ��� AH ��ֵ��ָ������Ĺ��ܡ���ͬ�Ĺ��ܺŴ���ͬ�Ĳ��������ȡ������д�����������Ӳ�̴����Եȡ�
						! ������һЩ�����Ĺ��ܺţ�
						! AH=0x00����λ����������
						! AH=0x02����ȡ����
						! AH=0x03��д������
						! AH=0x08����ȡ���̲���

						! int 0x13 ��ʹ�÷�������:

						!  ��ȡ��������
						!  ah = 0x02 ��ȡ��������     al = ��Ҫ��������������
						!  ch = �ŵ�(����)�ŵĵ�8λ   cl = ��ʼ���� ��6λ(0-5),�ŵ��� ��2λ(6-7)
                        !  dh = ��ͷ��;               dl = ��������(�����Ӳ����λ7Ҫ��λ)
						!  es:bx ָ�����ݻ�����; �����ȡ������ CF(Carry Flag ��λ��־λ) ��־��λ;

						!  ȡ��������������
						!  ah = 0x08 ȡ�������������� dl = ��������(�����Ӳ����Ҫ��λ7λ1)
					    !  ������Ϣ:
						!  �����ȡ���̲�������, ���� ah = ״̬��
                        !  ah = 0, al = 0, bl = ����������(AT/PS2)
						!  ch = ���ŵ��ŵĵ�8λ  cl = ÿ�ŵ����������(λ0-5),���ŵ��ŵĸ�2λ(λ6-7)				
						!  dh = ����ͷ��         dl = ����������
						!  es:di ���̴��̲����б�

						! 13���жϣ�int 0x13��ͨ����Ӱ���־�Ĵ������ر���Carry��־λ��CF����ZF��Zero Flag����־λ��������һЩ�����������
						! Carry��־λ��CF����
						!   ���int 0x13ִ�гɹ���CFͨ���ᱻ���㣨����Ϊ0������ʾ����û�д����ʧ�ܡ�
						!   ���int 0x13ִ��ʧ�ܣ�CFͨ���ᱻ����Ϊ1����ʾ�����˴���
						! Zero Flag��ZF����
						!   ZF��־λͨ�����ڱ�ʾ�����Ľ���Ƿ�Ϊ�㡣����int 0x13�жϣ�ZF������ͨ��ȡ����ִ�еľ��������
						!   ���磬���ʹ��int 0x13����ȡ�������������ҳɹ���ȡ�����ݣ���ôZF���ܻᱻ���㣬��Ϊ��ȡ�����ݲ����㡣
						!   ���ʹ��int 0x13��ִ��ĳ���������������Ľ��Ϊ�㣬��ôZF���ܻᱻ����Ϊ1����ʾ���Ϊ�㡣
						! ��֮��int 0x13�ж�ͨ����ʹ�ñ�־�Ĵ�����CF��ZF��ָʾ�����ĳɹ���ʧ�ܣ��Լ���������ԡ�����Ա���Ը���
						! ��Щ��־λ��״̬�����д�����Ͳ���������жϡ�����ı�־λ���ú��������ݾ����int 0x13�ӹ��ܺ;��������������ͬ��
						! ��ˣ���ʹ��int 0x13�ж�ʱ��ͨ����Ҫ������ص��ĵ����ֲᣬ���˽�ÿ���ӹ��ܵı�־�Ĵ���״̬���塣
! Get disk drive parameters, specifically nr of sectors/track

	mov	dl,#0x00
	mov	ax,#0x0800		! AH=8 is get drive parameters  AH=8 ��ʾ��ȡ���̲���
	int	0x13            ! 13���ж� 8���ӹ���,��ȡ���̲���   
	mov	ch,#0x00        ! 0����
	seg cs              ! ��ʾ��һ�����Ĳ������� cs �μĴ�����ָ�Ķ���
	mov	sectors,cx      ! ����ÿ�ŵ�������
	mov	ax,#INITSEG
	mov	es,ax           ! ��Ϊ�����ж�int 0x13 ȡ���̲����ĵ��� es ��ֵ, ���������޸Ļ���

! Print some inane message    ! ��ʾһЩ��Ϣ('Loding system ...' �س�����,��24���ַ�)

						! 10���ж�˵��: ���ڿ��ƺͲ����ı�ģʽ��ͼ��ģʽ���ı���ͼ��������������������������ʾӲ�����н������Ӷ�ʵ����Ļ�ϵ��ı���ͼ�ε���ʾ�Ͳ�����
						! int 0x10 �жϵ�ʹ��ͨ���漰 AH �Ĵ�����AL �Ĵ����Լ������Ĵ������ڴ�λ�ã����幦��ȡ���� AH �Ĵ����е�ֵ��
						! AH �Ĵ�������ָ����ͬ���ӹ��ܡ�������һЩ������ int 0x10 �ж��ӹ��ܺ����ǵ����ã�

						! �ı�ģʽ�����
						! AH=0x0E�����ı�ģʽ����ʾ�ַ���ʹ�� AL �Ĵ�����ָ��Ҫ��ʾ���ַ���BH �Ĵ�����ָ����ʾ��ҳ�棬BL �Ĵ�����ָ���ַ�����ɫ��

						! �����ƣ�
						! AH=0x02�����ù��λ�á�ʹ�� BH �Ĵ�����ָ����ʾ��ҳ�棬DH �Ĵ�����ָ���кţ�DL �Ĵ�����ָ���кš�

						! ��ȡ���λ�ã�
						! AH=0x03����ȡ����λ�á����صĹ��λ�ô洢�� BH �Ĵ�����ҳ�ţ���DH �Ĵ������кţ���DL �Ĵ������кţ��С�

						! ͼ��ģʽ������
						! AH=0x00������ͼ��ģʽ��
						! AH=0x01�������ı�ģʽ��
						! AH=0x05����ȡ��ǰ����ʾҳ��
						! AH=0x06�����õ�ǰ����ʾҳ��
						! AH=0x0D����ͼ��ģʽ�»������ص㡣

						! �������ܣ�
						! AH=0x07��������Ļ��

									!�ı�ģʽ�����
									!AH=0x0E�����ı�ģʽ����ʾ�ַ���
									!AH=0x13��д���ַ������ƶ���ꡣ

									!�����ƣ�
									! AH=0x02�����ù��λ�á�
									! AH=0x03����ȡ���λ�á�
									! AH=0x06�����õ�ǰ����ʾҳ��
									! AH=0x07��������Ļ��

									!ͼ��ģʽ������
									! AH=0x00������ͼ��ģʽ��
									! AH=0x01�������ı�ģʽ��
									! AH=0x0D����ͼ��ģʽ�»������ص㡣
									! AH=0x0F����ȡ��ǰ��ͼ��ģʽ��

									!�������ܣ�
									! AH=0x05����ȡ��ǰ����ʾҳ��
									! AH=0x0A�������ı�ģʽ�����״��
									! AH=0x0B����ȡ�ı�ģʽ�����״��
									
									!�ı�ģʽ��� (AH=0x0E)��
									! AL=0x00���ڹ��λ����ʾ�ַ���
									! AL=0x01���ڹ��λ����ʾ�ַ��������ֹ��λ�ò��䡣

									!������ (AH=0x02)��
									! AL=0x00�����������Ϊ���ɼ���
									! AL=0x01�����������Ϊ�ɼ���
									! AL=0x02����ȡ���λ�á�
									! AL=0x03�����ù��λ�á�

									! ͼ��ģʽ���� (AH=0x00 �� AH=0x01)��

									! ��Щ����ͨ�����漰 AL �Ĵ���������ʹ�� AL �Ĵ�����ָ��Ҫ���õ�ͼ��ģʽ���ı�ģʽ�ı�š�
									! �������� (AH=0x05��AH=0x0A��AH=0x0B)��
									! ��Щ����Ҳͨ�����漰 AL �Ĵ���������ʹ�� AL �Ĵ�����ָ������������������ʾҳ�š������״�ȡ�

	mov	ah,#0x03		! read cursor pos     ! ah=0x03  ��ȡ���λ��
	xor	bh,bh                                 ! bh=0x0    
	int	0x10                                  ! 10���ж�
	
	mov	cx,#24                                              ! ����Ҫ��ʾ���ַ��������� 24 ���ַ�
														    !                            7     6 5 4  3     2 1 0
	mov	bx,#0x0007		! page 0, attribute 7 (normal)      ! bh �洢ҳ  bl �洢�ַ����� BL    R G B  I     R G B
															!						     ��˸  ����   ����  ǰ��
	mov	bp,#msg1                                            ! ָ��Ҫ��ʾ���ַ���
	mov	ax,#0x1301		! write string, move cursor         ! д�ַ������ƶ����
	int	0x10

! ok, we've written the message, now
! we want to load the system (at 0x10000)                   ! ���ڿ�ʼ�� system ģ����ص� 64 KB ��

	mov	ax,#SYSSEG                            ! SYSSEG=0x1000 ϵͳ�ε�ַ  es = system �ε�ַ
	mov	es,ax		! segment of 0x010000     
	call	read_it                           ! ��ȡ������ system ģ��, es Ϊ�������
	call	kill_motor 

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.

	seg cs
	mov	ax,root_dev
	cmp	ax,#0
	jne	root_defined
	seg cs
	mov	bx,sectors
	mov	ax,#0x0208		! /dev/ps0 - 1.2Mb
	cmp	bx,#15
	je	root_defined
	mov	ax,#0x021c		! /dev/PS0 - 1.44Mb
	cmp	bx,#18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:

	jmpi	0,SETUPSEG

! This routine loads the system at address 0x10000, making sure
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can.
!
! in:	es - starting address segment (normally 0x1000)
!
sread:	.word 1+SETUPLEN	! sectors read of current track
head:	.word 0			! current head
track:	.word 0			! current track

read_it: 
						! ���������ֵ,�����϶�������ݱ�������λ���ڴ��ַ 64KB �ı߽翪ʼ��,���������ѭ��
						! �� bx �Ĵ���,���ڱ�ʾ��ǰ���ڴ�����ݵĿ�ʼλ��
	mov ax,es
	test ax,#0x0fff     ! test ָ���ִ�й�������:      ִ�н���� 0,  ����Ϊ: 0x1000 & 0x0fff = 0x0000   
						! 1. �� operand1 �� operand2 ��λ���������,���������������ʱ�Ĵ�����
						! 2. ���±�־�Ĵ�����ֵ,�ر����������־λ ZF, ������Ϊ0,��ZF��Ϊ1,����Ϊ0. ��һ�����ǵ�zf=1
						! 3. ���·��ű�־λSF,���ݽ�������λ������(����������λ���ø��Ƶ���־�Ĵ���SFλ)
						! test ָ��ͨ������ִ��λ������߼������,������ĳЩλ�Ƿ����û����,���߲��ԼĴ������ڴ�λ���е�ĳЩλ��״̬
						! ��ͨ����������״ָ��(JZ��JNZ)һ��ʹ��,���ݽ�������Ƴ��������
die:	jne die			! es must be at 64kB boundary   ! �������Ժ�����,testָ������Ϊ0,�������ת,��������ѭ��.  
						! Ҫʹ�����ﲻ������ѭ��, ��ôtest ָ���ִ�н������Ϊ0. ��ζ��, ax��ֵ��es��ֵ ������ 0x1000 ��������,. ������ 0x1000 0x2000 0x3000��
	    xor bx,bx		! bx is starting address within segment   ! �� bx ֵָ 0x0000
rp_read:
						! �ж��Ƿ��Ѿ�����ȫ������.�Ƚϵ�ǰ�������Ƿ����ϵͳ����ĩ�������Ķ�(#ENDSEG),������Ǿ���ת�� ok1_read ��Ŵ�����������,�����˳�
	mov ax,es
	cmp ax,#ENDSEG		! have we loaded all yet?  ! �Ƿ��Ѿ���ȡ����ĩ��
	jb ok1_read         ! ���С�ڶ�ĩ�˵�ַ,����ת; ��ζ�� system ������뻹δ����
	ret                 ! ���̷���,ret ָ��ʵ�ֶ���ת��. ���޸�ip�Ĵ�����ֵ,�ó��򷵻ص��õĵط�. ջ��ָ��sp��ֵҲ�ᷢ���仯.��Ϊԭ��������ջ�е�ip��ֵ��ջ��.
ok1_read:
						! �������֤��ǰ�ŵ���Ҫ��ȡ������,����ax�Ĵ�����
						! ���ݵ�ǰ�ŵ���δ��ȡ���������Լ����������ֽڿ�ʼƫ��λ��,�������ȫ����ȡ��Щδ�����������ֽ������Ƿ��
						! ���� 64KB �γ�������. ���ᳬ��,����ݴ˴�����ܶ�ȡ���ֽ���(64kB - ����ƫ��λ��),������˴���Ҫ��ȡ��������.
						! һ�������Ĵ�Сͨ���� 512�ֽ�(B) 
	seg cs
	mov ax,sectors      ! ȡÿ�ŵ���������
	sub ax,sread        ! ��ȥ��ǰ�ŵ��Ѿ���ȡ��������
	mov cx,ax           ! δ�����������洢�� cx ��
	shl cx,#9           ! ÿ�������Ĵ�С�� 512 �ֽ�,���,����9λ,�൱�ڳ��� 512,���δ�����ֽ���
	add cx,bx           ! cx = cx + bx (����ƫ��ֵ,��һ��bxΪ0) = �˴ζ�������,���ڹ�������ֽ���
	jnc ok2_read        ! add ָ��Ľ��,û�з�����λ, ����ת�� ok2_read (��˼û�г���64KB) ,��ȡ����
						! ��Ϊcx��16λ�Ĵ���, ���ֵ�ܱ�ʾ 65535,��+1 ��65536(64KB),��������addָ��½�λ,��ͱ�ʾcx�в��ܱ�ʾ��ô���ֵ, Ҳ�ͱ�ʾ�����˶οռ��С(64KB)
	je ok2_read         ! add ָ����Ϊ0,�������ת,(��ʾ����� add ָ��ִ���е����˽�λ,���Ǹպ�Ҫ��ȡ 64KB ��С������) ��ôҲ������.
	xor ax,ax			! �����ϴ˴ν����ŵ�������δ������������,������һ���οռ��С(64KB)
	sub ax,bx			! ������������ܶ�ȡ���ֽ���(64KB-���ڶ�ƫ��λ��),��ת������Ҫ��ȡ����������
	shr ax,#9           ! ���ƶ�,�൱�ڳ��� 512,�õ�����������
ok2_read:
						! 
	call read_track
	mov cx,ax
	add ax,sread
	seg cs
	cmp ax,sectors
	jne ok3_read
	mov ax,#1
	sub ax,head
	jne ok4_read
	inc track
ok4_read:
	mov head,ax
	xor ax,ax
ok3_read:
	mov sread,ax
	shl cx,#9
	add bx,cx
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read

read_track:
	push ax
	push bx
	push cx
	push dx
	mov dx,track
	mov cx,sread
	inc cx
	mov ch,dl
	mov dx,head
	mov dh,dl
	mov dl,#0
	and dx,#0x0100
	mov ah,#2
	int 0x13
	jc bad_rt
	pop dx
	pop cx
	pop bx
	pop ax
	ret
bad_rt:	mov ax,#0
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track

/*
 * This procedure turns off the floppy drive motor, so
 * that we enter the kernel in a known state, and
 * don't have to worry about it later.
 */
kill_motor:
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
