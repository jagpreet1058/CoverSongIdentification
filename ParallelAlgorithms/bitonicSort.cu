//x: Pointer to matrix
//N: Size of each row
//NPow2: Size of each row rounded up to nearest power of 2
__global__ void bitonicSort(float* X, int N, int NPow2)
{
    extern __shared__ float x[];
    int N2 = NPow2 >> 1;
    int offset = blockIdx.x*N;
    int k = 0;
    int i, i1, i2;
    float min, max;
    int size = 2;
    int stride;
    //Step 0: Figure out K (number of batches per block)
    int K = N2 >> 9;
    if (K == 0) {
        K = 1;
    }

    //Step 1: Copy row corresponding to this block into shared memory
    //bearing in mind that for bitonic sort there are half
    //as many threads as there are numbers in each row
    for (k = 0; k < (K << 1); k++) {
        i1 = k*N2 + threadIdx.x;
        if (i1 < N) {
            x[i1] = (float)X[offset + i1];
        }
        else if (i1 < NPow2) {
            //NOTE: Assuming all numbers are nonnegative
            //so these dummy padding values will go first
            x[i1] = -1;
        }
    }
    __syncthreads();

    //Step 2: Perform bitonic sort
    while (size < NPow2 << 1) {
        stride = size >> 1;
        while (stride > 0) {
            for (k = 0; k < K; k++) {
                i = k*N2 + threadIdx.x;
                i1 = stride*2*(i/stride) + i%stride;
                i2 = i1 + stride;
                if (x[i1] < x[i2]) {
                    min = x[i1];
                    max = x[i2];
                }
                else {
                    min = x[i2];
                    max = x[i1];
                }
                if (i/(size/2)%2 > 0) {
                    x[i1] = min;
                    x[i2] = max;
                }
                else {
                    x[i1] = max;
                    x[i2] = min;
                }
            }
            stride = stride >> 1;
            __syncthreads();
        }
        size = size << 1;
    }

    //Step 3: Copy Result Back
    for (k = 0; k < (K << 1); k++) {
        i1 = k*N2 + threadIdx.x;
        if (i1 >= N) {
            break;
        }
        X[offset + (N-i1)] = x[i1];
    }
    __syncthreads();
}


__global__ void memtest(float* X, int N, int N2, int K)
{
    extern __shared__ float x[];
    int offset = blockIdx.x*N;
    int t = threadIdx.x;

    if (t < N) {
        X[offset+t] = (float)(blockIdx.x + t);
    }

    //Step 3: Copy Result Back
    /*for (k = 0; k < 2*K; k++) {
        i1 = t*2*K+k;
        if (i1 >= N) {
            break;
        }
        X[t] = t*k;
    }*/

}
