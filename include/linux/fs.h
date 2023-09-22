/*�ļ�ϵͳͷ�ļ�.�����ļ���ṹ*/
/*
 * This file has definitions for some important file table
 * structures etc.
 */

#ifndef _FS_H
#define _FS_H

#include <sys/types.h>

/* devices are as follows: (same as minix, so we can use the minix
 * file system. These are major numbers.)
 *
 * 0 - unused (nodev)
 * 1 - /dev/mem
 * 2 - /dev/fd
 * 3 - /dev/hd
 * 4 - /dev/ttyx
 * 5 - /dev/tty
 * 6 - /dev/lp
 * 7 - unnamed pipes
 */

#define IS_SEEKABLE(x) ((x)>=1 && (x)<=3)

#define READ 0
#define WRITE 1
#define READA 2		/* read-ahead - don't pause */
#define WRITEA 3	/* "write-ahead" - silly, but somewhat useful */

void buffer_init(long buffer_end);

#define MAJOR(a) (((unsigned)(a))>>8)
#define MINOR(a) ((a)&0xff)

#define NAME_LEN 14
#define ROOT_INO 1

#define I_MAP_SLOTS 8
#define Z_MAP_SLOTS 8
#define SUPER_MAGIC 0x137F

#define NR_OPEN 20
#define NR_INODE 32
#define NR_FILE 64
#define NR_SUPER 8
#define NR_HASH 307
#define NR_BUFFERS nr_buffers
#define BLOCK_SIZE 1024
#define BLOCK_SIZE_BITS 10
#ifndef NULL
#define NULL ((void *) 0)
#endif

#define INODES_PER_BLOCK ((BLOCK_SIZE)/(sizeof (struct d_inode)))
#define DIR_ENTRIES_PER_BLOCK ((BLOCK_SIZE)/(sizeof (struct dir_entry)))

#define PIPE_HEAD(inode) ((inode).i_zone[0])
#define PIPE_TAIL(inode) ((inode).i_zone[1])
#define PIPE_SIZE(inode) ((PIPE_HEAD(inode)-PIPE_TAIL(inode))&(PAGE_SIZE-1))
#define PIPE_EMPTY(inode) (PIPE_HEAD(inode)==PIPE_TAIL(inode))
#define PIPE_FULL(inode) (PIPE_SIZE(inode)==(PAGE_SIZE-1))
#define INC_PIPE(head) \
__asm__("incl %0\n\tandl $4095,%0"::"m" (head))

typedef char buffer_block[BLOCK_SIZE];

struct buffer_head {      // ������ͷ���ݽṹ
	char * b_data;			/* pointer to data block (1024 bytes) */   // ָ�����ݿ��ָ��(���ݿ�Ϊ1024�ֽ�)
	unsigned long b_blocknr;	/* block number */                     // ���
	unsigned short b_dev;		/* device (0 = free) */                // ����Դ���豸��(0��ʾδ��)
	unsigned char b_uptodate;                                          // ���±�־:��ʾ�����Ƿ����
	unsigned char b_dirt;		/* 0-clean,1-dirty */                  // �޸ı�־: 0-δ�޸�,1-���޸�
	unsigned char b_count;		/* users using this block */           // ʹ�ø����ݿ���û���
	unsigned char b_lock;		/* 0 - ok, 1 -locked */                // �������Ƿ�����,0-δ����;1-������.
	struct task_struct * b_wait;                  // ָ��ȴ��û���������������
	struct buffer_head * b_prev;                  // ǰһ��(���ĸ�ָ�����ڻ������Ĺ���)
	struct buffer_head * b_next;                  // ��һ��
	struct buffer_head * b_prev_free;             // ǰһ���п�
	struct buffer_head * b_next_free;             // ��һ���п�
};

struct d_inode {      // �����ϵ������ڵ�ṹ
	unsigned short i_mode;          // �ļ����ͺ�����(rwxλ)
	unsigned short i_uid;           // �û�id(�ļ�ӵ���߱�ʶ��)
	unsigned long i_size;           // �ļ���С(�ֽ���)
	unsigned long i_time;           // �ļ��޸�ʱ��(��1970.1.1.0����,��)
	unsigned char i_gid;            // �� id(�ļ�ӵ�������ڵ���)
	unsigned char i_nlinks;         // �ļ�Ŀ¼��������
	unsigned short i_zone[9];       // ֱ��(0-6),���(7)��˫�ؼ��(8)�߼����,zone��������˼,����������λ��߼���
};

struct m_inode {      // �ڴ��е�i�ڵ�ṹ.
	unsigned short i_mode;             // �ļ����ͺ�����rwxλ
	unsigned short i_uid;              // �û�id(�ļ�ӵ���߱�ʶ��)
	unsigned long i_size;              // �ļ���С(�ֽ���)
	unsigned long i_mtime;             // �ļ��޸�ʱ��(��1970.1.1.0����,��)
	unsigned char i_gid;               // ��id(�ļ�ӵ�������ڵ���)
	unsigned char i_nlinks;            // �ļ�Ŀ¼��������
	unsigned short i_zone[9];          // ֱ��(0-6),���(7)��˫�ؼ��(8)�߼����. zone��������˼,����������λ��߼���
/* these are in memory also */
	struct task_struct * i_wait;       // �ȴ���i�ڵ�Ľ���
	unsigned long i_atime;             // ������ʱ��
	unsigned long i_ctime;             // i�ڵ������޸�ʱ��
	unsigned short i_dev;              // i�ڵ������豸��
	unsigned short i_num;              // i�ڵ��
	unsigned short i_count;            // i�ڵ㱻ʹ�õĴ���,0��ʾ��i�ڵ����
	unsigned char i_lock;              // ������־
	unsigned char i_dirt;              // ���޸�(��)��־
	unsigned char i_pipe;              // �ܵ���־
	unsigned char i_mount;             // ��װ��־
	unsigned char i_seek;              // ��Ѱ��־(lseekʱ)
	unsigned char i_update;            // ���±�־
};

struct file {          // �ļ��ṹ
	unsigned short f_mode;              // �ļ�����ģʽ(RWλ)
	unsigned short f_flags;             // �ļ��򿪺Ϳ��Ƶı�־
	unsigned short f_count;             // ��Ӧ�ļ����(�ļ�������)��
	struct m_inode * f_inode;           // ָ���Ӧi�ڵ�
	off_t f_pos;                        // �ļ�λ��(��дƫ��ֵ)
};

struct super_block {   // �ڴ��д��̳�����ṹ,�����ϵĳ�����ṹ d_super_block ֻ����ǰ8��
	unsigned short s_ninodes;           // �ڵ���
	unsigned short s_nzones;            // �߼�����
	unsigned short s_imap_blocks;       // i �ڵ�λͼ��ռ�õ����ݿ���
	unsigned short s_zmap_blocks;       // �߼���λͼ��ռ�õ����ݿ���
	unsigned short s_firstdatazone;     // ��һ�������߼����
	unsigned short s_log_zone_size;     // log(���ݿ���/�߼�����)(��2Ϊ��)
	unsigned long s_max_size;           // �ļ���󳤶�
	unsigned short s_magic;             // �ļ�ϵͳħ����
/* These are only in memory */
	struct buffer_head * s_imap[8];     // i �ڵ�λͼ�����ָ������(ռ��8��,�ɱ�ʾ64M)
	struct buffer_head * s_zmap[8];     // �߼���λͼ�����ָ������(ռ��8��)
	unsigned short s_dev;               // ���������ڵ��豸��
	struct m_inode * s_isup;            // ����װ���ļ�ϵͳ��Ŀ¼��i�ڵ�(isup-super i)
	struct m_inode * s_imount;          // ����װ���� i �ڵ�
	unsigned long s_time;               // �޸�ʱ��
	struct task_struct * s_wait;        // �ȴ��ó�����Ľ���
	unsigned char s_lock;               // ��������־
	unsigned char s_rd_only;            // ֻ����־
	unsigned char s_dirt;               // ���޸�(��)��־
};

struct d_super_block {        // ���̳�����
	unsigned short s_ninodes;
	unsigned short s_nzones;
	unsigned short s_imap_blocks;
	unsigned short s_zmap_blocks;
	unsigned short s_firstdatazone;
	unsigned short s_log_zone_size;
	unsigned long s_max_size;
	unsigned short s_magic;
};

struct dir_entry {            // �ļ�Ŀ¼��ṹ
	unsigned short inode;     // i�ڵ�
	char name[NAME_LEN];      // �ļ���
};

extern struct m_inode inode_table[NR_INODE];
extern struct file file_table[NR_FILE];
extern struct super_block super_block[NR_SUPER];
extern struct buffer_head * start_buffer;
extern int nr_buffers;

extern void check_disk_change(int dev);
extern int floppy_change(unsigned int nr);
extern int ticks_to_floppy_on(unsigned int dev);
extern void floppy_on(unsigned int dev);
extern void floppy_off(unsigned int dev);
extern void truncate(struct m_inode * inode);
extern void sync_inodes(void);
extern void wait_on(struct m_inode * inode);
extern int bmap(struct m_inode * inode,int block);
extern int create_block(struct m_inode * inode,int block);
extern struct m_inode * namei(const char * pathname);
extern int open_namei(const char * pathname, int flag, int mode,
	struct m_inode ** res_inode);
extern void iput(struct m_inode * inode);
extern struct m_inode * iget(int dev,int nr);
extern struct m_inode * get_empty_inode(void);
extern struct m_inode * get_pipe_inode(void);
extern struct buffer_head * get_hash_table(int dev, int block);
extern struct buffer_head * getblk(int dev, int block);
extern void ll_rw_block(int rw, struct buffer_head * bh);
extern void brelse(struct buffer_head * buf);
extern struct buffer_head * bread(int dev,int block);
extern void bread_page(unsigned long addr,int dev,int b[4]);
extern struct buffer_head * breada(int dev,int block,...);
extern int new_block(int dev);
extern void free_block(int dev, int block);
extern struct m_inode * new_inode(int dev);
extern void free_inode(struct m_inode * inode);
extern int sync_dev(int dev);
extern struct super_block * get_super(int dev);
extern int ROOT_DEV;

extern void mount_root(void);

#endif
