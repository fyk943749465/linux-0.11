/*类型头文件,定义了基本的系统数据类型*/
#ifndef _SYS_TYPES_H
#define _SYS_TYPES_H

#ifndef _SIZE_T
#define _SIZE_T
typedef unsigned int size_t;
#endif

#ifndef _TIME_T
#define _TIME_T
typedef long time_t;
#endif

#ifndef _PTRDIFF_T
#define _PTRDIFF_T
typedef long ptrdiff_t;
#endif

#ifndef NULL
#define NULL ((void *) 0)
#endif

typedef int pid_t;
typedef unsigned short uid_t;
typedef unsigned char gid_t;
typedef unsigned short dev_t;
typedef unsigned short ino_t;
typedef unsigned short mode_t;
typedef unsigned short umode_t;
typedef unsigned char nlink_t;
typedef int daddr_t;
typedef long off_t;
typedef unsigned char u_char;
typedef unsigned short ushort;

typedef struct { int quot,rem; } div_t;
typedef struct { long quot,rem; } ldiv_t;

struct ustat {   // 文件系统参数结构,用于函数 ustat
	daddr_t f_tfree;   // 系统总空闲块数
	ino_t f_tinode;    // 总空闲 i 节点数
	char f_fname[6];   // 文件系统名称      未使用,总是返回NULL
	char f_fpack[6];   // 文件系统压缩名称  未使用,总是返回NULL
};

#endif
