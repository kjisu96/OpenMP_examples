#include <stdio.h>
#include <omp.h>

int main(int argc, const char *argv[])
{
	int x = 0;

	printf("main area x : %d \n", x);

#pragma omp parallel
	{
			int x;
			if( omp_get_thread_num() == 0 ) x = 1;
			else x = 2;

			printf("Num %d thread area x : %d \n", omp_get_thread_num(), x);
	}

	printf("main area x : %d \n", x);

    return 0;
}
