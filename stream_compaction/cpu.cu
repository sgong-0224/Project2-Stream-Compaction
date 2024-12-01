#include <cstdio>
#include "cpu.h"

#include "common.h"

namespace StreamCompaction {
    namespace CPU {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }

        /**
         * CPU scan (prefix sum).
         * For performance analysis, this is supposed to be a simple for loop.
         * (Optional) For better understanding before starting moving to GPU, you can simulate your GPU scan in this function first.
         */
        void scan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            // TODO
            odata[0] = 0;
            for (auto i = 0; i < n - 1; ++i)
                odata[i + 1] = odata[i] + idata[i];
            timer().endCpuTimer();
        }

        /**
         * CPU stream compaction without using the scan function.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithoutScan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            // TODO
            int index = 0;
            for (auto i = 0; i < n; ++i)
                if (idata[i])
                    odata[index++] = idata[i];
            timer().endCpuTimer();
            return index;
        }

        /**
         * CPU stream compaction using scan and scatter, like the parallel version.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithScan(int n, int *odata, const int *idata) {
            int* tmp_arr = new int[n];
            int* scan_arr = new int[n];
            timer().startCpuTimer();
            // TODO
            for (auto i = 0; i < n; ++i)
                tmp_arr[i] = idata[i] ? 1 : 0;
            scan(n, scan_arr, tmp_arr);
            for (auto i = 0; i < n; ++i)
                if (tmp_arr[i])
                    odata[scan_arr[i]] = idata[i];
            auto cnt = scan_arr[n - 1] + tmp_arr[n - 1];
            timer().endCpuTimer();
            delete[] tmp_arr;
            delete[] scan_arr;
            return cnt;
        }
    }
}
