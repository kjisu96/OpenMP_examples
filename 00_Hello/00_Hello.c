#include <stdio.h>
#include <omp.h>

int main(int argc, const char *argv[])
{
    #pragma omp parallel num_threads(8) 
	{
    	printf("hello world\n");
	}

    return 0;
}
