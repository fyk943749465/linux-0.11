#
# if you want the ram-disk device, define this to be the
# size in blocks.
#
RAMDISK = #-DRAMDISK=512

AS86	=as86 -0 -a                # 8086  �������������,����Ĳ�������ֱ���
LD86	=ld86 -0                   # -0 ���� 8086 Ŀ�����; -a ������ gas �� gld ���ּ��ݵĴ���(gas �� gld �� gun �������������)

AS	=gas                           # GUN �Ļ������������
LD	=gld
LDFLAGS	=-s -x -M                  # GUN ������ gld ����ʱ�õ���ѡ��: ������: -s ����ļ���ʡ�����еķ�����Ϣ -x ɾ�����еľֲ����� -M �ڱ�׼����豸�ϴ�ӡ����ӳ��
								   # �����ӳ��������һ���ڴ��ַӳ��,�����г��˳����ת�뵽�ڴ��е�λ����Ϣ.����������������Ϣ:
								   # 1. Ŀ���ļ���������Ϣӳ�䵽�ڴ��е�λ��
								   # 2. ����������η���
								   # 3. �����а����������ļ���Ա�������õķ���
CC	=gcc $(RAMDISK)                # gcc �� GNU C ���������.����UNIX��Ľű��������,�����ö���ı�ʶ��ʱ,��Ҫǰ����� $���Ų���������ס��ʶ��
CFLAGS	=-Wall -O -fstrength-reduce -fomit-frame-pointer \
-fcombine-regs -mstring-insns      # gcc ��ѡ��.ǰһ������ \ ���ű�ʾ��һ��������. ѡ���:-Wall ��ӡ���о�����Ϣ; -0 �Դ�������Ż� -fstrength-reduce �Ż�ѭ����� -mstring-insns ��linus ��ѧϰgcc������ʱΪgcc���ӵ�ѡ��,����gcc-1.40
                                   # �ڸ��ƽṹ�Ȳ���ʱʹ�� 386 cpu���ַ���ָ��,����ȥ��
CPP	=cpp -nostdinc -Iinclude       # cpp �� gcc��Ԥ������.-nostdinc -Iinclude �ĺ����ǲ�Ҫ������׼��ͷ�ļ�Ŀ¼�е��ļ�,����ʹ��-Iѡ��ָ����Ŀ¼�������ڵ�ǰĿ¼�������ļ�

#
# ROOT_DEV specifies the default root-device when making the image.
# This can be either FLOPPY, /dev/xxxx or empty, in which case the
# default of /dev/hd6 is used by 'build'.
#
ROOT_DEV=/dev/hd6                  # ROOT_DEV ָ���ڴ����ڴ�ӳ���ļ�ʱ��ʹ�õ�Ĭ�ϸ��ļ�ϵͳ���ڵ��豸,�����������,/dev/xxxx���߸ɴ����.
								   # ����ʱ build ����(��tools/Ŀ¼��)��ʹ��Ĭ��ֵ/dev/hd6

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o    # kernelĿ¼,mmĿ¼��fsĿ¼��������Ŀ������ļ�.Ϊ�˷����ʾ���ｫ������ ARCHIVES(�鵵�ļ�)��ʶ����ʾ
DRIVERS =kernel/blk_drv/blk_drv.a kernel/chr_drv/chr_drv.a  #����ַ��豸���ļ�. .a��ʾ���ļ��ǹ鵵�ļ�,Ҳ������������ִ�ж����ƴ����ӳ��򼯺ϵĿ��ļ�,
                                                            #ͨ������ GNU��ar��������.ar��GUN�Ķ������ļ��������,���ڴ���\�޸��Լ��ӹ鵵�ļ��г�ȡ�ļ�
MATH	=kernel/math/math.a        # ��ѧ������ļ�         
LIBS	=lib/lib.a                 # ��lib/Ŀ¼�е��ļ����������ɵ�ͨ�ÿ��ļ�

.c.s:                              # make ��ʽ����ʽ��׺����.����ִ��make���������������е� .c�ļ���������.s������,':'��ʾ�����Ǹù��������.
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -S -o $*.s $<    # ָʹ�� gcc ����ǰ�� CFLAGS ��ָ����ѡ���Լ���ʹ�� include/Ŀ¼�е�ͷ�ļ�,���ʵ��ı���󲻽��л���ֹͣ(-S),�Ӷ�����
	                                     # ������ĸ��� C �ļ���Ӧ�Ļ��������ʽ�Ĵ����ļ�.Ĭ��������������Ļ������ļ���ԭC�ļ���ȥ��.c������.s��׺.-o ��ʾ���������ļ���
										 # ��ʽ.����$*.s(��$@)���Զ�Ŀ�����,$<�����һ���Ⱦ�����,���Ｔ�Ƿ������� *.c �ļ�
.s.o:                                    # ��ʾ�����е�.s�������ļ������.oĿ���ļ�.��һ����ʵ�ָò����ľ�������
	$(AS) -c -o $*.o $<                  # ʹ��gas������������������.oĿ���ļ�.-c ��ʾֵ�������,�����������Ӳ���
.c.o:                                    # ��������, *.c �ļ� -> *.oĿ���ļ�
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -c -o $*.o $<    # ʹ�� gccc �� C �����ļ������Ŀ���ļ���������

all:	Image                            # all ��ʾ���� Makefile ��֪�����Ŀ��. ���Ｔ�� image �ļ�

Image: boot/bootsect boot/setup tools/system tools/build                   # ˵��Ŀ��(Image�ļ�) ���ɷֺź����4��Ԫ�ز���,�ֱ��� boot/ Ŀ¼�е� bootsect �� setup,tools/Ŀ¼�е�system��build�ļ�
	tools/build boot/bootsect boot/setup tools/system $(ROOT_DEV) > Image  
	sync                                 # ��������ִ�е�����,��һ�б�ʾʹ��toolsĿ¼�µ�build���߳���(�����˵���������)��bootsect\setup��system�ļ� 
	                                     # ��$(ROOT_DEV) Ϊ���ļ�ϵͳ�豸��װ���ں�ӳ���ļ� Image. �ڶ��е� syncͬ����������ʹ�������������д�̲����³�����
disk: Image                              # ��ʾdisk ���Ŀ��Ҫ�� Image ����
	dd bs=8192 if=Image of=/dev/PS0      # dd Ϊ unix��׼����:����һ���ļ�,����ѡ�����ת���͸�ʽ��.bs=��ʾһ�ζ�/д���ֽ��� if=��ʾ������ļ� of=��ʾ��������ļ�
										 # �����/dev/PS0 ��ָ��һ������������(�豸�ļ�)
tools/build: tools/build.c               # �� tools Ŀ¼�µ� build.c ��������ִ�г��� build.
	$(CC) $(CFLAGS) \
	-o tools/build tools/build.c         # ��������ִ�г��� build ������

boot/head.o: boot/head.s                 # �������������.s.o ��������head.o Ŀ���ļ� 

tools/system:	boot/head.o init/main.o \
		$(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)      # ��ʾ tools Ŀ¼�е� system �ļ�Ҫ�ɷֺ��ұ����е�Ԫ������
	$(LD) $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	$(DRIVERS) \
	$(MATH) \
	$(LIBS) \
	-o tools/system > System.map                    # ���� system ������. ���� > System.map ��ʾ gld ��Ҫ������ӳ���ض������� System.map�ļ���
													# ���� System.map �ļ����û��μ�ע�ͺ��˵��

kernel/math/math.a:                                 # ��ѧЭ�������ļ� math.a ����һ���ϵ�����ʵ��.
	(cd kernel/math; make)                          # ���� kernel/math/ Ŀ¼,���� make ���߳���.

kernel/blk_drv/blk_drv.a:                           # ���豸�����ļ� blk_drv.a
	(cd kernel/blk_drv; make)

kernel/chr_drv/chr_drv.a:                           # �ַ��豸�����ļ� chr_drv.a
	(cd kernel/chr_drv; make)

kernel/kernel.o:                                    # �ں�Ŀ��ģ��
	(cd kernel; make)

mm/mm.o:                                            # �ڴ����ģ��
	(cd mm; make)

fs/fs.o:                                            # �ļ�ϵͳĿ��ģ��
	(cd fs; make)

lib/lib.a:                                          # �⺯��
	(cd lib; make)

boot/setup: boot/setup.s                          # ���￪ʼ��������ʹ�� 8086 ������������� 
	$(AS86) -o boot/setup.o boot/setup.s          # �� setup.s �ļ����б������� setup �ļ�
	$(LD86) -s -o boot/setup boot/setup.o         # -sѡ���ʾҪȥ���Ѱ��ļ��еķ�����Ϣ

boot/bootsect:	boot/bootsect.s                   # ͬ��.���� bootsect.o ����������
	$(AS86) -o boot/bootsect.o boot/bootsect.s
	$(LD86) -s -o boot/bootsect boot/bootsect.o

tmp.s:	boot/bootsect.s tools/system              # �����е���������bootsect.s ����ͷ���һ���й�system�ļ�������Ϣ.
                                                  # �������������ɺ���"SYSSIZE = system �ļ�ʵ�ʳ���"һ����Ϣ��tmp.s�ļ�,Ȼ��bootsect.s �ļ���������
												  # ȡ�� system ���ȵķ�����: ������������ ls �� system �ļ����г��б���ʾ,��grep����ȡ���б����ļ��ֽ����ֶ���Ϣ
												  # �����򱣴���tmp.s��ʱ�ļ���. cut �������ڼ����ַ���,tr����ȥ����β�Ļس���.
												  # ����:(ʵ�ʳ���+15)/16 ���ڻ����'��'��ʾ�ĳ�����Ϣ.1��=16�ֽ�.
	(echo -n "SYSSIZE = (";ls -l tools/system | grep system \
		| cut -c25-31 | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
	cat boot/bootsect.s >> tmp.s

clean:   # ��ִ�� 'make clean' ʱ,�ͻ�ִ�����������,ȥ�����б����������ɵ��ļ�.
         # rm ���ļ�ɾ������,ѡ��-f�����Ǻ��Բ����ڵ��ļ�,���Ҳ���ʾɾ����Ϣ
	rm -f Image System.map tmp_make core boot/bootsect boot/setup
	rm -f init/*.o tools/system tools/build boot/*.o
	(cd mm;make clean)
	(cd fs;make clean)
	(cd kernel;make clean)
	(cd lib;make clean)

backup: clean   # �ù�������ִ�������clean����,Ȼ���linux/ Ŀ¼����ѹ��,����backup.Zѹ���ļ�. cd.. ��ʾ�˵�linux/ ����һ��Ŀ¼
                # tar cf -linux ��ʾ�� linux/ Ŀ¼ִ��tar�鵵����. -cf��ʾ��Ҫ�����µĹ鵵�ļ� 
				# | compress - ��ʾ�� tar�����ִ��ͨ���ܵ�����('|')���ݸ�ѹ������,����ѹ����������� backup.Z�ļ�
	(cd .. ; tar cf - linux | compress - > backup.Z)
	sync        # ��ʹ�������������д�̲����´��̳�����

dep:            # ��Ŀ��͹������ڸ��ļ�֮���������ϵ.��������Щ������ϵ��Ϊ�˸�make����ȷ���Ƿ���Ҫ�ؽ�һ��Ŀ������.���統ĳ��ͷ�ļ����Ķ�����,make��ͨ�����ɵ�������ϵ,
                # ���±������ͷ�ļ��йص����� *.c �ļ�. ���巽������:
				# ʹ���ַ����༭���� sed �� Makefile �ļ�(�������Լ�) ���д���.���Ϊ ɾ�� Makefile �ļ���'###Dependencies'�к����������,������ tmp_make ��ʱ�ļ�
				# Ȼ��� init/ Ŀ¼�µ�ÿһ��C�ļ�(��ʵֻ��һ��C�ļ�,��main.c)ִ��gccԤ�������. -M ��־����Ԥ��������������ÿ��Ŀ���ļ�����ԵĹ���,������Щ�������
				# make �﷨.����ÿһ��Դ�ļ�,Ԥ����������һ��make����,������ʽ����ӦԴ�����ļ���Ŀ���ļ���������������ϵ--��Դ�ļ��а���������ͷ�ļ��б�.
				# $$i ʵ������$($i)����˼. �����$i�����ǰ���shell������ֵ. Ȼ���Ԥ����������ӵ���ʱ�ļ� tmp_make��,Ȼ�󽫸���ʱ�ļ����Ƴ��µ� Makefile �ļ�.
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
