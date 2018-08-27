#include <stdio.h>
#include <string.h>

#include "utils.h"
#include "fat12.h"

void PrintImage(unsigned char *pImageBuffer)
{
    puts("\nStart to print image:\n");

    PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

    // calculate start address of boot program
    WORD wBootStart = BOOT_START_ADDR + pFAT12Header->JmpCode[1] + 2;
    printf("Boot start address: 0x%04x\n",wBootStart);

    char buffer[20];

    memcpy(buffer,pFAT12Header->BS_OEMName,8);
    buffer[8] = 0;

    printf("BS_OEMName:         %s\n",buffer);
    printf("BPB_BytesPerSec:    %u\n",pFAT12Header->BPB_BytesPerSec);
    printf("BPB_SecPerClus:     %u\n",pFAT12Header->BPB_SecPerClus);
    printf("BPB_RsvdSecCnt:     %u\n",pFAT12Header->BPB_RsvdSecCnt);
    printf("BPB_NumFATs:        %u\n",pFAT12Header->BPB_NumFATs);
    printf("BPB_RootEntCnt:     %u\n",pFAT12Header->BPB_RootEntCnt);
    printf("BPB_TotSec16:       %u\n",pFAT12Header->BPB_TotSec16);
    printf("BPB_Media:          0x%02x\n",pFAT12Header->BPB_Media);
    printf("BPB_FATSz16:        %u\n",pFAT12Header->BPB_FATSz16);
    printf("BPB_SecPerTrk:      %u\n",pFAT12Header->BPB_SecPerTrk);
    printf("BPB_NumHeads:       %u\n",pFAT12Header->BPB_NumHeads);
    printf("BPB_HiddSec:        %u\n",pFAT12Header->BPB_HiddSec);
    printf("BPB_TotSec32:       %u\n",pFAT12Header->BPB_TotSec32);
    printf("BS_DrvNum:          %u\n",pFAT12Header->BS_DrvNum);
    printf("BS_Reserved1:       %u\n",pFAT12Header->BS_Reserved1);
    printf("BS_BootSig:         %u\n",pFAT12Header->BS_BootSig);
    printf("BS_VolID:           %u\n",pFAT12Header->BS_VolID);

    memcpy(buffer,pFAT12Header->BS_VolLab,11);
    buffer[11] = 0;
    printf("BS_VolLab:          %s\n",buffer);

    memcpy(buffer,pFAT12Header->BS_FileSysType,8);
    buffer[11] = 0;
    printf("BS_FileSysType:     %s\n",buffer);
}

FILE_HEADER FileHeaders[30];

void SeekRootDir(unsigned char *pImageBuffer)
{
    PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

    puts("\nStart seek files of root dir:");

    DWORD wRootDirStartSec = pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16;

    printf("Start sector of root directory:    %u\n", wRootDirStartSec);

    DWORD dwRootDirStartBytes = wRootDirStartSec * pFAT12Header->BPB_BytesPerSec;
    printf("Start bytes of root directory:      %u\n",dwRootDirStartBytes);

    PFILE_HEADER pFileHeader = (PFILE_HEADER)(pImageBuffer + dwRootDirStartBytes);

    int fileNum = 1;
    while(*(BYTE *)pFileHeader)
    {
        FileHeaders[fileNum - 1] = *pFileHeader;
        
        char buffer[20];
        memcpy(buffer,pFileHeader->DIR_Name,11);
        buffer[11] = 0;

        printf("File no.            %d\n", fileNum);
        printf("File name:          %s\n", buffer);
        printf("File attributes:    0x%02x\n", pFileHeader->DIR_Attr);
        printf("First clus num:     %u\n\n", pFileHeader->DIR_FstClus);

        ++pFileHeader;
        ++fileNum;
    }
}

DWORD GetLSB(DWORD ClusOfTable, PFAT12_HEADER pFAT12Header)
{
    DWORD dwDataStartClus =  pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16 + \
                            pFAT12Header->BPB_RootEntCnt * 32 / pFAT12Header->BPB_BytesPerSec;

    return dwDataStartClus + (ClusOfTable - 2) * pFAT12Header->BPB_SecPerClus;
}

WORD GetFATNext(BYTE *FATTable, WORD CurOffset)
{
    WORD tabOff = CurOffset * 1.5;

    WORD nextOff = *(WORD *)(FATTable + tabOff);

    nextOff = nextOff % 2 == 0 ? nextOff >> 4 : nextOff & 0x0fff;

    return nextOff;
}

DWORD ReadData(unsigned char *pImageBuffer, DWORD LSB, unsigned char *outBuffer)
{
    PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

    DWORD dwReadPosBytes = LSB * pFAT12Header->BPB_BytesPerSec;

    memcpy(outBuffer, pImageBuffer + dwReadPosBytes, pFAT12Header->BPB_SecPerClus * pFAT12Header->BPB_BytesPerSec);

    return pFAT12Header->BPB_SecPerClus * pFAT12Header->BPB_BytesPerSec;
}

DWORD ReadFile(unsigned char *pImageBuffer, PFILE_HEADER pFileHeader, unsigned char *outBuffer)
{
    PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

    char nameBuffer[20];
    memcpy(nameBuffer, pFileHeader->DIR_Name, 11);
    nameBuffer[11] = 0;

    printf("The FAT chain of file %s:\n", nameBuffer);

    BYTE *pbStartOfFATTab = pImageBuffer + (pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt) * pFAT12Header->BPB_BytesPerSec;

    WORD next = pFileHeader->DIR_FstClus;
    
    DWORD readBytes = 0;
    do
    {
        printf(", 0x%03x", next);

        DWORD dwCurLSB = GetLSB(next, pFAT12Header);

        readBytes += ReadData(pImageBuffer, dwCurLSB, outBuffer + readBytes);

        next = GetFATNext(pbStartOfFATTab, next);

    }while(next <= 0xfef);

    puts("");

    return readBytes;
}