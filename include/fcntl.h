/* 文件控制头文件, 用于文件及其描述符的操作控制常数符号的定义*/
#ifndef _FCNTL_H
#define _FCNTL_H

#include <sys/types.h>

/* open/fcntl - NOCTTY, NDELAY isn't implemented yet */
#define O_ACCMODE	00003
#define O_RDONLY	   00
#define O_WRONLY	   01
#define O_RDWR		   02
#define O_CREAT		00100	/* not fcntl */
#define O_EXCL		00200	/* not fcntl */
#define O_NOCTTY	00400	/* not fcntl */
#define O_TRUNC		01000	/* not fcntl */
#define O_APPEND	02000
#define O_NONBLOCK	04000	/* not fcntl */
#define O_NDELAY	O_NONBLOCK

/* Defines for fcntl-commands. Note that currently
 * locking isn't supported, and other things aren't really
 * tested.
 */
#define F_DUPFD		0	/* dup */
#define F_GETFD		1	/* get f_flags */
#define F_SETFD		2	/* set f_flags */
#define F_GETFL		3	/* more flags (cloexec) */
#define F_SETFL		4
#define F_GETLK		5	/* not implemented */
#define F_SETLK		6
#define F_SETLKW	7

/* for F_[GET|SET]FL */
#define FD_CLOEXEC	1	/* actually anything with low bit set goes */

/* Ok, these are locking features, and aren't implemented at any
 * level. POSIX wants them.
 */
#define F_RDLCK		0
#define F_WRLCK		1
#define F_UNLCK		2

/* Once again - not implemented, but ... */         // 文件锁定操作数据结构
struct flock {
	short l_type;                        // 锁定类型(F_RDLCK,F_WRLCK,F_UNLCK)
	short l_whence;						 // 开始偏移(SEEK_SET,SEEK_CUR或SEEK_END)
	off_t l_start;						 // 阻塞锁定的开始处.相对偏移(字节数)
	off_t l_len;						 // 阻塞锁定的大小;如果是0则回到文件末尾
	pid_t l_pid;                         // 加锁的进程id
};

extern int creat(const char * filename,mode_t mode);
extern int fcntl(int fildes,int cmd, ...);
extern int open(const char * filename, int flags, ...);

#endif
