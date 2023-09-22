/*�ļ�״̬ͷ�ļ�,�����ļ����ļ�ϵͳ״̬�ṹstat{}�ͳ���*/
#ifndef _SYS_STAT_H
#define _SYS_STAT_H

#include <sys/types.h>

struct stat {              // �ļ�״̬�ṹ
	dev_t	st_dev;        // �����ļ����豸��
	ino_t	st_ino;        // �ļ� i �ڵ��
	umode_t	st_mode;       // �ļ�����
	nlink_t	st_nlink;      // ָ���ļ���������
	uid_t	st_uid;        // �ļ����û�(��ʶ)��
	gid_t	st_gid;        // �ļ������
	dev_t	st_rdev;       // �豸��(����ļ���������ַ��ļ�����ļ�)
	off_t	st_size;       // �ļ���С(�ֽ���)(����ļ��ǳ����ļ�)
	time_t	st_atime;      // �ϴ�(���)����ʱ��
	time_t	st_mtime;      // ����޸�ʱ��
	time_t	st_ctime;      // ���ڵ��޸�ʱ��
};

#define S_IFMT  00170000
#define S_IFREG  0100000
#define S_IFBLK  0060000
#define S_IFDIR  0040000
#define S_IFCHR  0020000
#define S_IFIFO  0010000
#define S_ISUID  0004000
#define S_ISGID  0002000
#define S_ISVTX  0001000

#define S_ISREG(m)	(((m) & S_IFMT) == S_IFREG)
#define S_ISDIR(m)	(((m) & S_IFMT) == S_IFDIR)
#define S_ISCHR(m)	(((m) & S_IFMT) == S_IFCHR)
#define S_ISBLK(m)	(((m) & S_IFMT) == S_IFBLK)
#define S_ISFIFO(m)	(((m) & S_IFMT) == S_IFIFO)

#define S_IRWXU 00700
#define S_IRUSR 00400
#define S_IWUSR 00200
#define S_IXUSR 00100

#define S_IRWXG 00070
#define S_IRGRP 00040
#define S_IWGRP 00020
#define S_IXGRP 00010

#define S_IRWXO 00007
#define S_IROTH 00004
#define S_IWOTH 00002
#define S_IXOTH 00001

extern int chmod(const char *_path, mode_t mode);
extern int fstat(int fildes, struct stat *stat_buf);
extern int mkdir(const char *_path, mode_t mode);
extern int mkfifo(const char *_path, mode_t mode);
extern int stat(const char *filename, struct stat *stat_buf);
extern mode_t umask(mode_t mask);

#endif
