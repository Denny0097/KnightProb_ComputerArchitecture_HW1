#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>


double knightProbability(int n, int k, int row, int column){
    
    double DPtable[n][n];
    memset(DPtable, 0, sizeof(DPtable));
    DPtable[row][column] = 1;
    double Prop = 0.0;

    int moves[8][2] = {{2,1},{2,-1},{-2,1},{-2,-1},{1,2},{1,-2},{-1,2},{-1,-2}};

    double START,END;
	START = clock();
    for(int i = 0; i < k; i++){

        double TDP[n][n];          
        memset(TDP, 0, sizeof(TDP));
        
        for(int r = 0; r < n; r++){
            for(int c = 0; c < n; c++){
                for(int j = 0; j < 8; j++){
                    int moveRow = r + moves[j][0];
                    int moveCol = c + moves[j][1];
                    if(moveRow >= 0 && moveRow <= n-1 && moveCol >= 0 && moveCol <= n-1)
                        TDP[moveRow][moveCol] += DPtable[r][c]/8.0;
                }
            }    
        }
        memcpy(DPtable, TDP, sizeof(DPtable));

    }

    for (int i = 0; i < n; i++){
        for (int j = 0; j < n; j++) {
            Prop += DPtable[i][j];
        }
    }
    END = clock();
    printf("Exec Time: %lf\n",(double)clock()/CLOCKS_PER_SEC);
    printf("Comp Time: %lf\n",(END - START) / CLOCKS_PER_SEC);
    return  Prop;
}


int main() {

    int n = 3, k = 2, row = 0, column = 0;
    double result = knightProbability(n, k, row, column);
    printf("Probability: %lf\n", result);
    return 0;

}