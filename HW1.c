#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

// Definition of bf16_t type
typedef struct {
    uint16_t bits;
} bf16_t;

// Inline function to convert FP32 to BF16
static inline bf16_t fp32_to_bf16(float s) {
    bf16_t h;
    union {
        float f;
        uint32_t i;
    } u = {.f = s};
    if ((u.i & 0x7fffffff) > 0x7f800000) { /* NaN */
        h.bits = (u.i >> 16) | 64; /* force to quiet */
        return h;
    }
    h.bits = (u.i + (0x7fff + ((u.i >> 0x10) & 1))) >> 0x10;  // Rounding
    return h;
}

// Inline function to convert BF16 back to FP32
static inline float bf16_to_fp32(bf16_t h) {
    union {
        float f;
        uint32_t i;
    } u;
    u.i = (uint32_t)h.bits << 16;  // Move the 16-bit BF16 value to the high 16 bits
    return u.f;
}

double knightProbability(int n, int k, int row, int column) {
    // Define DPtable and TDP as arrays of bf16_t
    bf16_t DPtable[n][n];
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            DPtable[i][j].bits = 0;
        }
    }

    // Set the initial probability to 1.0 and convert to BF16
    DPtable[row][column] = fp32_to_bf16(1.0f);
    float Prop = 0.0f;

    int moves[8][2] = {{2,1},{2,-1},{-2,1},{-2,-1},{1,2},{1,-2},{-1,2},{-1,-2}};
    // double START,END;
	// START = clock();
    for (int i = 0; i < k; i++) {
        bf16_t TDP[n][n];
        for (int r = 0; r < n; r++) {
            for (int c = 0; c < n; c++) {
                TDP[r][c].bits = 0;
            }
        }

        for (int r = 0; r < n; r++) {
            for (int c = 0; c < n; c++) {
                // Use FP32 for computation
                if (DPtable[r][c].bits > 0) {

                    float prob_fp32 = bf16_to_fp32(DPtable[r][c]);
                    prob_fp32 /= 8.0f;

                    for (int j = 0; j < 8; j++) {
                        int moveRow = r + moves[j][0];
                        int moveCol = c + moves[j][1];
                        if (moveRow >= 0 && moveRow < n && moveCol >= 0 && moveCol < n) {
                            float temp_fp32 = bf16_to_fp32(TDP[moveRow][moveCol]);
                            temp_fp32 += prob_fp32;
                            TDP[moveRow][moveCol] = fp32_to_bf16(temp_fp32);
                        }
                    }
                }
            }
        }
        memcpy(DPtable, TDP, sizeof(DPtable));
    }

    // Sum up the probabilities and convert BF16 to FP32 for the final result
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            Prop += bf16_to_fp32(DPtable[i][j]);
        }
    }
    // END = clock();
    // printf("Exec Time: %lf\n",(double)clock()/CLOCKS_PER_SEC);
    // printf("Comp Time: %lf\n",(END - START) / CLOCKS_PER_SEC);
    return (double)Prop;
}

int main() {
    int n = 3, k = 2, row = 0, column = 0;
    double result = knightProbability(n, k, row, column);
    printf("Probability: %lf\n", result);
    return 0;
}


//another sol(maybe?)
/*

// assume knight is in the center of the infinited chessboard(4k+1*4k+1), 
// and restruct the real chessboard by knight's real cell on the infinited chessboard,
// store the corner cell of real cell on this chessboard in array

// 
// use tree to check all probabilty of knight's tour, 
// if knight not in the real chessboard(cell > right corner, top corner || cell <left corner, bot corner)
// target 1

// p: sum all the 1 that mean not in the real chessboard's total happen, and divide the 8^k
// return this p

*/