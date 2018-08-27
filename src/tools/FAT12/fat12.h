#pragma once

#define BYTE    unsigned char
#define WORD    unsigned short
#define DWORD   unsigned int

#define BOOT_START_ADDR 0x7c00

typedef struct _FAT12_HEADER FAT12_HEADER;
typedef struct _FAT12_HEADER *PFAT12_HEADER;

struct _FAT12_HEADER {
    BYTE    JmpCode[3];
    BYTE    BS_OEMName[8];
    WORD    BPB_BytesPerSec;
    BYTE    BPB_SecPerClus;
    WORD    BPB_RsvdSecCnt;
    BYTE    BPB_NumFATs;
    WORD    BPB_RootEntCnt;
    WORD    BPB_TotSec16;
    BYTE    BPB_Media;
    WORD    BPB_FATSz16;
    WORD    BPB_SecPerTrk;
    WORD    BPB_NumHeads;
    DWORD   BPB_HiddSec;
    DWORD   BPB_TotSec32;
    BYTE    BS_DrvNum;
    BYTE    BS_Reserved1;
    BYTE    BS_BootSig;
    DWORD   BS_VolID;
    BYTE    BS_VolLab[11];
    BYTE    BS_FileSysType[8];
}__attribute__((packed)) _FAT12_HEADER;

typedef struct _FILE_HEADER FILE_HEADER;
typedef struct _FILE_HEADER *PFILE_HEADER;

struct _FILE_HEADER {
    BYTE    DIR_Name[11];
    BYTE    DIR_Attr;
    BYTE    Reserved[10];
    WORD    DIR_WrtTime;
    WORD    DIR_WrtDate;
    WORD    DIR_FstClus;
    DWORD   DIR_FileSize;
}__attribute__((packed)) _FILE_HEADER;