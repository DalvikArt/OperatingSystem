#include <stdio.h>
#include <unistd.h>

#include "fat12.h"
#include "utils.h"

int main(int argc,char *argv[])
{
    if(argc != 2)
    {
        printf("Usage: %s ImageFile\n", argv[0]);
        return 1;
    }

    // open image file
    FILE *pImageFile = fopen(argv[1], "rb");

    if(pImageFile == NULL)
    {
        puts("Read image file failed!");
        return 1;
    }

    // get file size
    fseek(pImageFile,0,SEEK_END);
    long lFileSize = ftell(pImageFile);

    printf("Image size: %ld\n",lFileSize);

    // alloc buffer
    unsigned char *pImageBuffer = (unsigned char *)malloc(lFileSize);

    if(pImageBuffer == NULL)
    {
        puts("Memmory alloc failed!");
        return 1;
    }

    // set file pointer to the beginning
    fseek(pImageFile,0,SEEK_SET);

    // read the whole image file into memmory
    long lReadResult = fread(pImageBuffer,1,lFileSize,pImageFile);

    printf("Read size: %ld\n",lReadResult);

    if(lReadResult != lFileSize)
    {
        puts("Read file error!");
        free(pImageBuffer);
        fclose(pImageFile);
        return 1;
    }

    // finish reading, close file
    fclose(pImageFile);

    // print FAT12 structure
    PrintImage(pImageBuffer);

    // seek files of root directory
    SeekRootDir(pImageBuffer);

    // file read buffer
    unsigned char outBuffer[2048];

    // read file 0
    DWORD fileSize = ReadFile(pImageBuffer, &FileHeaders[0], outBuffer);

    printf("File size: %u, file content: \n%s",fileSize, outBuffer);

    return 0;
}