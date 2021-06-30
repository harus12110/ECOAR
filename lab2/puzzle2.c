#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

#pragma pack(push, 1)

typedef struct
{
	unsigned short bfType;	// 0x4D42
	unsigned long  bfSize;	// file size in bytes
	unsigned short bfReserved1;
	unsigned short bfReserved2;
	unsigned long  bfOffBits;	// offset of pixel data
	unsigned long  biSize;		// header size (bitmap info size)
	long  biWidth;			// image width
	long  biHeight;			// image height
	short biPlanes;			// bitmap planes (== 3)
	short biBitCount;		// bit count of a pixel (== 24)
	unsigned long  biCompression;	// should be 0 (no compression)
	unsigned long  biSizeImage;		// image size (not file size!)
	long biXPelsPerMeter;			// horizontal resolution
	long biYPelsPerMeter;			// vertical resolution
	unsigned long  biClrUsed;		// not imoprtant for RGB images
	unsigned long  biClrImportant;	// not imoprtant for RGB images
} RGBbmpHdr;

#pragma pack(pop)

typedef struct
{
	unsigned int width, height;
	unsigned int linebytes;
	unsigned char* pImg;
	RGBbmpHdr *pHeader;
} imgInfo;

imgInfo* allocImgInfo()
{
	imgInfo* retv = malloc(sizeof(imgInfo));
	if (retv != NULL)
	{
		retv->width = 0;
		retv->height = 0;
		retv->linebytes = 0;
		retv->pImg = NULL;
		retv->pHeader = NULL;
	}
	return retv;
}

void* freeImgInfo(imgInfo* toFree)
{
	if (toFree != NULL)
	{
		if (toFree->pImg != NULL)
			free(toFree->pImg);
		if (toFree->pHeader != NULL)
			free(toFree->pHeader);
		free(toFree);
	}
	return NULL;
}

void* freeResources(FILE* pFile, imgInfo* toFree)
{
	if (pFile != NULL)
		fclose(pFile);
	return freeImgInfo(toFree);
}

imgInfo* readBMP(const char* fname)
{
	imgInfo* pInfo = 0;
	FILE* fbmp = 0;

	if ((pInfo = allocImgInfo()) == NULL)
		return NULL;

	if ((fbmp = fopen(fname, "rb")) == NULL)
		return freeResources(fbmp, pInfo);  // cannot open file

	if ((pInfo->pHeader = malloc(sizeof(RGBbmpHdr))) == NULL ||
		fread((void *)pInfo->pHeader, sizeof(RGBbmpHdr), 1, fbmp) != 1)
		return freeResources(fbmp, pInfo);

	// several checks - quite restrictive and only for RGB files
	if (pInfo->pHeader->bfType != 0x4D42 || pInfo->pHeader->biPlanes != 1 ||
		pInfo->pHeader->biBitCount != 24 || pInfo->pHeader->biCompression != 0)
		return (imgInfo*) freeResources(fbmp, pInfo);

	if ((pInfo->pImg = malloc(pInfo->pHeader->biSizeImage)) == NULL ||
		fread((void *)pInfo->pImg, 1, pInfo->pHeader->biSizeImage, fbmp) != pInfo->pHeader->biSizeImage)
		return (imgInfo*) freeResources(fbmp, pInfo);

	if (pInfo->pHeader->biWidth != 320){
		printf("ERROR: Width of the %s file is not 320 but %d\n", fname, pInfo->pHeader->biWidth);
		return (imgInfo*) freeResources(fbmp, pInfo);
	}

	if (pInfo->pHeader->biHeight != 240){
		printf("ERROR: Height of the %s file is not 240 but %d\n", fname, pInfo->pHeader->biHeight);
		return (imgInfo*) freeResources(fbmp, pInfo);
	}

	fclose(fbmp);
	pInfo->width = pInfo->pHeader->biWidth;
	pInfo->height = pInfo->pHeader->biHeight;
	pInfo->linebytes = pInfo->pHeader->biSizeImage / pInfo->pHeader->biHeight;
	return pInfo;
}

int saveBMP(const imgInfo* pInfo, const char* fname)
{
	FILE * fbmp;
	if ((fbmp = fopen(fname, "wb")) == NULL)
		return -1;  // cannot open file for writing

	if (fwrite(pInfo->pHeader, sizeof(RGBbmpHdr), 1, fbmp) != 1  ||
		fwrite(pInfo->pImg, 1, pInfo->pHeader->biSizeImage, fbmp) != pInfo->pHeader->biSizeImage)
	{
		fclose(fbmp);  // cannot write header or image
		return -2;
	}

	fclose(fbmp);
	return 0;
}

// this and the copy_segment functions are working implementations on which the assembly code is based 
void copy_segment(imgInfo* pImg1, imgInfo* pImg2, unsigned int input_row, unsigned int input_column, unsigned int output_row, unsigned int output_column){

	// get address of both pointer to 0, 0 coordinates
	unsigned char *input_pointer = pImg1->pImg;
	unsigned char *output_pointer = pImg2->pImg;
	
	// input pointer is the one connected to x1, x2
	// add to the input pointer address (3-input_row)*bytesPerRowSegment 76800
	input_pointer += (3-input_row)*76800;
	// and add (input_column-1)*bytesPerColumnSegment 240
	input_pointer += (input_column-1)*240;

	// output pointer is the one connected to i, j
	// add to the output pointer address (3-output_row)*bytesPerRowSegment 76800
	output_pointer += (3-output_row)*76800;
	// and add (output_column-1)*bytesPerColumnSegment 240
	output_pointer += (output_column-1)*240;

	for(unsigned int k = 0; k < 80; k++){
		for(unsigned int l = 0; l < 240; l++){
			*output_pointer = *input_pointer;
			input_pointer++;
			output_pointer++;
		}
		input_pointer += 720;
		output_pointer += 720;
	}

}

void copy_segments(imgInfo* pImg1, imgInfo* pImg2, unsigned int order_array[24]){

	unsigned int x1, x2;
	// loop over order_array
	for(unsigned int i = 1; i <= 3; i++){
		for(unsigned int j = 1; j <= 4; j++){
			x1 = order_array[8*(i-1) + 2*(j-1)];
			x2 = order_array[8*(i-1) + 2*(j-1) + 1];
			copy_segment(pImg1, pImg2, x1, x2, i, j);
		}
	}

}

int check_array(unsigned int order_array[24]){

	int i;
	int h1, h2;
	for(i = 1; i <= 12; i++){

		h1 = order_array[2*(i-1)];
		h2 = order_array[2*(i-1) + 1];

		if(h1 != 1 && h1 != 2 && h1 != 3){
			printf("ERROR: One of the order_array entries does not contain a valid number.\n");
			printf("Please check the entry with the index %d\n", 2*(i-1));
			return 1;
		}

		if(h2 != 1 && h2 != 2 && h2 != 3 && h2 != 4){
			printf("ERROR: One of the order_array entries does not contain a valid number.\n");
			printf("Please check the entry with the index %d\n", 2*(i-1) + 1);
			return 1;
		}

	}

	return 0;

}

int write_array(unsigned int order_array[24]){

	char str[25];
	printf("Please enter the order in the format 'number1number2number3...'. NO SPACES!!!\nFor instance 111213142122232431323334.\n");
	gets(str);
	int length = strlen(str);
	if(length != 24){
		printf("checkString error: Incorrect input string. String too long or too short\n");
		return 1;
	}

	int i;
	for(i = 1; i <= 12; i++){
		order_array[2*(i-1)] = str[2*(i-1)] - '0';
		order_array[2*(i-1) + 1] = str[2*(i-1) + 1] - '0';
	}

	return 0;

}

extern void assembler_copy_segments(imgInfo* pImg1, imgInfo* pImg2, unsigned int order_array[24]);

int main(int argc, char* argv[])
{
	imgInfo* pInfo1;
	imgInfo* pInfo2;

	if (sizeof(RGBbmpHdr) != 54)
	{
		printf("Check compilation options so as RGBbmpHdr struct size is 54 bytes.\n");
		return 1;
	}
	if ((pInfo1 = readBMP("source.bmp")) == NULL)
	{
		printf("Error reading source file (probably).\n");
		return 2;
	}
	if ((pInfo2 = readBMP("dest.bmp")) == NULL)
	{
		printf("Error reading destination file (probably).\n");
		return 2;
	}

	int check = 0;

	// please uncomment one array from the list below to use for testing
	// the requirement for all pairs of numbers to be used only once has been ditched
	// please remember that numbers come in a pair of two, the ones in an even index element describing
	// the row number, and ones in even index elements describing the column number

	unsigned int order_array[24] = {1, 2, 3, 4, 3, 2, 1, 4, 2, 4, 2, 3, 2, 2, 3, 1, 2, 1, 1, 3, 1, 1, 3, 3};
	//unsigned int order_array[24] = {1, 1, 1, 1, 3, 2, 1, 4, 2, 4, 2, 3, 2, 2, 3, 1, 2, 1, 1, 3, 1, 1, 3, 3};
	//unsigned int order_array[24] = {3, 4, 3, 3, 3, 2, 3, 1, 2, 4, 2, 3, 2, 2, 2, 1, 1, 4, 1, 3, 1, 2, 1, 1};
	//unsigned int order_array[24] = {1, 1, 2, 1, 3, 1, 1, 4, 1, 2, 2, 2, 3, 2, 2, 4, 1, 3, 2, 3, 3, 3, 3, 4};
	
	// or if you want to write the order manually please uncomment the next two lines
	//unsigned int order_array[24];
	//check = write_array(order_array);
	if(check == 1){
		freeResources(NULL, pInfo1);
		freeResources(NULL, pInfo2);
		printf("write_array function error");
		return 3;
	}

	check = check_array(order_array);
	if(check == 1){
		freeResources(NULL, pInfo1);
		freeResources(NULL, pInfo2);
		printf("check_array function error");
		return 3;
	}

	// uncomment if you want to see a working c implementation
	//copy_segments(pInfo1, pInfo2, order_array);

	// external function call
	assembler_copy_segments(pInfo1, pInfo2, order_array);

	saveBMP(pInfo2, "dest.bmp");
	freeResources(NULL, pInfo1);
	freeResources(NULL, pInfo2);
	return 0;
}