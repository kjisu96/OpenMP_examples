#include <stdio.h>
#include <omp.h>
#include <math.h>
#include <stdlib.h>

void CalcSQRT(double *Data, int size) {
		int i;
		for(i = 0; i < size; i++) {
				Data[i] = sqrt(Data[i]);
		}
}

void CalcLOG(double *Data, int size) {
		int i;
		for(i = 0; i < size; i++) {
				Data[i] = log(Data[i]);
		}
}

int main(int argc, const char *argv[])
{
	const int MAX = 10;
	double *Data1, *Data2;
	Data1 = (double *)malloc(sizeof(double)*MAX);
	Data2 = (double *)malloc(sizeof(double)*MAX);

	int i = 0;

	for(i = 0; i < MAX; i++) {
		Data1[i] = i+1;
		Data2[i] = i+1;
	}

#pragma omp parallel
{
#pragma omp sections
	{
#pragma omp section
		CalcSQRT(Data1, MAX);
#pragma omp section
		CalcLOG(Data2, MAX);
	}
}

	printf("Data1 : %f, %f, %f, %f, %f \n",
					Data1[0], Data1[1], Data1[2], Data1[3], Data1[4]);
	printf("Data2 : %f, %f, %f, %f, %f \n",
					Data2[0], Data2[1], Data2[2], Data2[3], Data2[4]);

	free(Data1);
	free(Data2);

    return 0;
}
