/*�����˽��������е�ʱ��ṹtms�Լ�times����ԭ��*/
#ifndef _TIMES_H
#define _TIMES_H

#include <sys/types.h>

struct tms {            // �ļ��������޸�ʱ��ṹ
	time_t tms_utime;   // �û�ʹ�õ�CPUʱ��
	time_t tms_stime;   // ϵͳ(�ں�)ʹ�õ�CPUʱ��
	time_t tms_cutime;  // ����ֹ���ӽ���ʹ�õ��û�CPUʱ��
	time_t tms_cstime;  // ����ֹ���ӽ���ʹ�õ�ϵͳCPUʱ��
};

extern time_t times(struct tms * tp);

#endif
