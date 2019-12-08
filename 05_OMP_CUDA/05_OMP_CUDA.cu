#include<stdio.h>
#include<stdlib.h>
#include <cuda.h>
#include<omp.h>
#include <helper_functions.h>
#include <helper_cuda.h>
#include <cuda_runtime.h>

void fill_matrix(int *A, int fac, int m, int n)
{
  int i, j;

  for (i=0; i<m;i++)
  {
    for (j=0;j<n;j++)
    {
      A[i*n+j] = i+j*fac;
    }
  }
}

void print_matrix(int *A, int m, int n)
{
  int i, j;

  for (i=0; i<m;i++)
  {
    for (j=0;j<n;j++)
    {
      printf("mat[%d, %d] = %d\n", i, j, A[i*n+j]);
    }
  }
}

//CPU version of the calculations
// just the product c_ij = Aij*B_ij
void perform_operation(int *A, int *B, int *C, int m, int n)
{
  int i, j;

  for (i=0; i<m;i++)
  {
    for (j=0;j<n;j++)
    {
      C[i*n+j] = A[i*n+j]*B[i*n+j];
      //printf("C[%d, %d] = %d\n", i, j, C[i*n+j]);
    }
  }
}

//gpu version of the calculations
__global__ void perform_operation_cuda(int *A, int *B, int *C, int m, int n)
{
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  int j = blockIdx.y * blockDim.y + threadIdx.y;

  if (i<m)
  {
    if (j<n)
    {
      C[i*n+j] = A[i*n+j]*B[i*n+j];
      //printf("C[%d, %d] = %d\n", i, j, C[i*n+j]);
    }
  }
}


//do the sum of the different C matrix in order to check the results
int do_sum(int *C, int sum, int m, int n)
{
  int i, j;

  for (i=0; i<m;i++)
  {
    for (j=0;j<n;j++)
    {
      sum = sum + C[i*n+j];
    }
  }

  return sum;
}


//main test program
int main (void)
{
  int N = 3;
  int A[N*N], B[N*N], C[N*N];
  int f, nf=3, sum = 0, sum_ref = 0;
  int *A_d, *B_d, *C_d;

  dim3 dimBlock(N*N, N*N);
  dim3 dimGrid(1, 1);

  int num_gpus = 0;
  int gpuid = -1;
  unsigned int cpu_thread_id = -1;

  //initialisation matrices
  fill_matrix(A, 2, N, N);
  fill_matrix(B, 1, N, N);
  fill_matrix(C, 0, N, N);

  printf("Print A:\n");
  print_matrix(A, N, N);

  //run for checking
  for (f=0; f<nf; f++)
  {
    fill_matrix(B, f+1, N, N);
    perform_operation(A, B, C, N, N);
    sum_ref = do_sum(C, sum_ref, N, N);
  }
  printf("SUM_REF = %d\n", sum_ref);

  //end references


  //Set the threads to each GPUs
#pragma omp parallel private(num_gpus, cpu_thread_id, gpuid)
{
  cudaGetDeviceCount(&num_gpus);
  cpu_thread_id = omp_get_thread_num();
  checkCudaErrors(cudaSetDevice(cpu_thread_id % num_gpus));
  checkCudaErrors(cudaGetDevice(&gpuid));
  printf("CPU thread %d uses CUDA device %d\n", cpu_thread_id, gpuid);
}

  //Start calculation with gpu
  sum = 0;

  checkCudaErrors(cudaMalloc( (void **)&A_d, sizeof(int) * N*N)); //I want it here!!
  checkCudaErrors(cudaMemcpy( A_d, A, sizeof(int) * N*N, cudaMemcpyHostToDevice)); //I want it here!!

// We want A_d in shared not in private!!
#pragma omp parallel \
  shared(dimGrid, dimBlock, A_d, N, nf, sum) private(f, B, B_d, C_d, C)
{
  checkCudaErrors(cudaMalloc( (void **)&B_d, sizeof(int) * N*N));
  checkCudaErrors(cudaMalloc( (void **)&C_d, sizeof(int) * N*N));

  #pragma omp for reduction(+:sum)
  for (f=0; f<nf; f++)
  {
    fill_matrix(B, f+1, N, N);
    checkCudaErrors(cudaMemcpy( B_d, B, sizeof(int) * N*N, cudaMemcpyHostToDevice));
    //perform_operation(A, B, C, N, N);

    perform_operation_cuda<<<dimGrid, dimBlock>>>(A_d, B_d, C_d, N, N);
    checkCudaErrors(cudaMemcpy( C, C_d, sizeof(int) * N*N, cudaMemcpyDeviceToHost));
    sum = do_sum(C, sum, N, N);
  }
  checkCudaErrors(cudaFree(B_d));
  checkCudaErrors(cudaFree(C_d));
}
  checkCudaErrors(cudaFree(A_d));

  //check
  printf("SUM = %d\n", sum);
  printf("SUM - SUM_REF = %d\n", sum-sum_ref);
  checkCudaErrors(cudaDeviceReset());

  return 0;
}
