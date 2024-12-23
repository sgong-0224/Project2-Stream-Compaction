#include <cuda.h>
#include <cuda_runtime.h>
#include "common.h"
#include "naive.h"

namespace StreamCompaction {
    namespace Naive {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }
        // TODO: __global__
        __global__ void kernNaiveScan(int n, int offset, int* odata, const int* idata)
        {
            int idx = threadIdx.x + blockIdx.x * blockDim.x;
            if (idx >= n)
                return;
            odata[idx] = idata[idx];
            if (idx >= offset)
                odata[idx] += idata[idx - offset];
        }
        __global__ void kernShift(int n, int* odata, const int* idata)
        {
            int idx = threadIdx.x + blockIdx.x * blockDim.x;
            if (idx >= n)
                return;
            odata[idx] = idx == 0 ? 0 : idata[idx - 1];
        }
        /**
         * Performs prefix-sum (aka scan) on idata, storing the result into odata.
         */
        void scan(int n, int *odata, const int *idata) {
            int* dev_idata;
            int* dev_odata;
            cudaMalloc((void**)&dev_idata, n * sizeof(int));
            cudaMalloc((void**)&dev_odata, n * sizeof(int));
            cudaMemcpy(dev_idata, idata, n * sizeof(int), cudaMemcpyHostToDevice);
            cudaDeviceProp prop;
            cudaGetDeviceProperties(&prop, 0);

            int minBlockSize = prop.warpSize, maxBlockSize = prop.maxThreadsPerBlock, SMCount = prop.multiProcessorCount;
            int blockSize = std::max(minBlockSize, std::min(n, maxBlockSize));
            int gridSize = (int)ceil((float)(n + blockSize - 1) / (float)blockSize);

            int max_d = ilog2ceil(n);
            timer().startGpuTimer();
            // TODO
            for (int d = 0; d < max_d; ++d) {
                kernNaiveScan <<<gridSize, blockSize>>>(n, 1<<d, dev_odata, dev_idata);
                std::swap(dev_idata, dev_odata);
            }
            kernShift <<<gridSize, blockSize >>> (n, dev_odata, dev_idata);
            timer().endGpuTimer();

            cudaMemcpy(odata, dev_odata, n * sizeof(int), cudaMemcpyDeviceToHost);
            cudaFree(dev_idata);
            cudaFree(dev_odata);
        }
    }
}
