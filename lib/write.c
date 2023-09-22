/*
 *  linux/lib/write.c
 *
 *  (C) 1991  Linus Torvalds
 *  Ð´ÎÄ¼þº¯Êý
 */

#define __LIBRARY__
#include <unistd.h>

_syscall3(int,write,int,fd,const char *,buf,off_t,count)
