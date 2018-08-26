#pragma once

#include "fat12.h"

void PrintImage(unsigned char *pImageBuffer);

void SeekRootDir(unsigned char *pImageBuffer);

extern FILE_HEADER FileHeaders[30];

DWORD ReadFile(unsigned char *pImageBuffer, PFILE_HEADER pFileHeader, unsigned char *outBuffer);