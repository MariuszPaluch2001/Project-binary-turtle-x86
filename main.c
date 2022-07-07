#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>

typedef struct  {
    char r;
    char g;
    char b;
} Color;

struct TurtleContextStruct{
	int x_pos; 	// 0
	int y_pos;	// 4
	short pen_state; // 8
	short direction; // 10
	Color act_color; // 12
};

extern "C" int exec_turtle_cmd(unsigned char *dest_bitmap, unsigned char *command, struct TurtleContextStruct *tc);
#pragma pack(push, 1)
typedef struct {
	uint16_t bfType; 
	uint32_t  bfSize; 
	uint16_t bfReserved1; 
	uint16_t bfReserved2; 
	uint32_t  bfOffBits; 
	uint32_t  biSize; 
	int32_t  biWidth; 
	int32_t  biHeight; 
	int16_t biPlanes; 
	int16_t biBitCount; 
	uint32_t  biCompression; 
	uint32_t  biSizeImage; 
	int32_t biXPelsPerMeter; 
	int32_t biYPelsPerMeter; 
	uint32_t  biClrUsed; 
	uint32_t  biClrImportant;
	uint32_t  RGBQuad_0;
	uint32_t  RGBQuad_1;
} bmpHdr;
#pragma pack(pop)

typedef struct {
	unsigned char *pImg;
	int width;
	int height;
} imgInfo;

unsigned char * read_commend(FILE *fp){
	int buf1;
	int buf2;
	unsigned char * char_buf = (unsigned char*) malloc(4);
	if (fread(&buf1, 1, 2, fp) != 2)
		return NULL;
	buf1 = ((buf1 & 0x00FF) << 8 | ((buf1 & 0xFF00) >> 8));
	memcpy(char_buf, &buf1, sizeof(buf1));
	if (buf1 % 4 == 3){
		if (fread(&buf2, 1, 2, fp) != 2){
			return NULL;
		}
		buf2 = ((buf2 & 0x00FF) << 8 | ((buf2 & 0xFF00) >> 8));
		memcpy(char_buf + 2, &buf2, 2);
	}
	return char_buf;
}

int write_to_bmp(FILE * fp, unsigned char * bitmap){
	int byts;
	if(fwrite(bitmap, *(int*) (bitmap + 2), 1, fp) != 1)
	{
		fprintf(stderr,"Couldn't write pixel array to bmp!\n");
		return -1;
	}
	return 1;
}

unsigned char * prepare_bitmap(bmpHdr * header){
	   unsigned char * bitmap = (unsigned char *) malloc(header->bfSize);
	   memset(bitmap, 255, header->bfSize);
	   memcpy(bitmap, header, sizeof(*header));
	   return bitmap;
}

			  
int main(int argc, char * argv []) {
   char* numb1;
   char* numb2;
   size_t size = 0;
   int result;
   FILE* file_comm;
   FILE* output_file;
   FILE* size_file;
   int height;
   int width;
   unsigned char * buffor;
   
   if ((size_file = fopen("dir_inputs/config.txt", "rb+")) == 0)
  	return -1;
   if ((file_comm = fopen("dir_inputs/input.bin", "rb+")) == 0)
  	return -1;
   if ((output_file = fopen("output/output.bmp", "w+")) == 0)
   	return -1;
   getline(&numb1, &size, size_file);
   width = atoi(numb1);
   getline(&numb2, &size, size_file);
   height = atoi(numb2);
   bmpHdr header ={
   	0x4D42,
	((int) (((24*width  + 31)/ 32) * 4)*height) +  62,
	0,
	0,
	62,
	40,
	width,
	height,
	1,
	24,
	0,
	0,
	(int) ((24*width  + 31)/ 32) * 4,
	height * 3,
	0,
	0,
   };
   fclose(size_file);
   struct TurtleContextStruct ts = {
	0,
	0,
	1,
	0,
	{0,0,0}
   };
   unsigned char * bitmap = prepare_bitmap(&header);
   buffor = read_commend(file_comm);
   while (buffor != NULL)
   {
   	printf("%02x%02x%02x%02x\n", *(buffor ),*(buffor + 1),*(buffor + 2),*(buffor + 3));
   	result = exec_turtle_cmd(bitmap, buffor, &ts);
   	if  (result == 1){
   		printf("Position beside bitmap border!\n");
   	}
   	else if ( result == 2){
   		printf("Move beside bitmap border!\n");
   	}
   	printf("X: %d\n", ts.x_pos);
   	printf("Y: %d\n", ts.y_pos);
   	printf("Pen state: %d\n", ts.pen_state);
   	printf("Direction: %d\n", ts.direction);
   	printf("R: %04x\n", ts.act_color.r);
   	printf("G: %04x\n", ts.act_color.g);
   	printf("B: %04x\n", ts.act_color.b);
   	free(buffor);
   	buffor = read_commend(file_comm);
   }
   
   write_to_bmp(output_file, bitmap);
   fclose(output_file);
   fclose(file_comm);
   free(bitmap);
   
   return 0;
}
