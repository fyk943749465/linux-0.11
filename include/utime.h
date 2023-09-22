/*�û�ʱ��ͷ�ļ�,�����˷��ʺ��޸�ʱ��ṹ�Լ�utime()ԭ��*/
#ifndef _UTIME_H
#define _UTIME_H

#include <sys/types.h>	/* I know - shouldn't do this, but .. */

struct utimbuf {         // �ļ�����/�޸Ľṹ
	time_t actime;       // �ļ�����ʱ��,��1970.1.1:0:0:0 ��ʼ������
	time_t modtime;      // �ļ��޸�ʱ��,��1970.1.1:0:0:0 ��ʼ������
};

extern int utime(const char *filename, struct utimbuf *times);

#endif
