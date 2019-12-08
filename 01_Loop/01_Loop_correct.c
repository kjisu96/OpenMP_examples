#include <stdio.h>
#include <omp.h>
#include <math.h>
#include <stdlib.h>

int main(int argc, const char *argv[])
{
	const int MAX = 10000000;
	float *Data;
	Data = (float *)malloc(sizeof(float)*MAX);

	int i = 0;

	for(i = 0; i < MAX; i++)
		Data[i] = i;

#pragma omp parallel
	{
#pragma omp for
		for(i = 0; i < MAX; i++)
			Data[i] = sqrt(Data[i]);
	}

	printf("Data : %f, %f, %f, %f, %f \n",
					Data[0], Data[1], Data[2], Data[3], Data[4]);

	free(Data);

    return 0;
}
