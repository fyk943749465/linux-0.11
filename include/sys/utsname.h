/*ϵͳ���ƽṹͷ�ļ�*/
#ifndef _SYS_UTSNAME_H
#define _SYS_UTSNAME_H

#include <sys/types.h>

struct utsname {     // ϵͳ����ͷ�ļ�
	char sysname[9];    // ���汾����ϵͳ������
	char nodename[9];   // ��ʵ����ص������нڵ�����
	char release[9];    // ��ʵ�ֵĵ�ǰ���м���
	char version[9];    // ���η��еİ汾����
	char machine[9];    // ϵͳ���е�Ӳ����������
};

extern int uname(struct utsname * utsbuf);

#endif
