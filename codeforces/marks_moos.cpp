#include <bits/stdc++.h>
using namespace std;


int main(){
    int n;
    cin >> n;
    vector<string> moos(n);
    for(int i = 0; i < n; i++){
        cin >> moos[i];
    }
    vector<vector<string>> mel(n/8, vector<string>(8));
    int times = 0;


    for (int i = 0; i < n-7; i++){
        bool all_different = true;
        for (int a = 0; a < 8; ++a) {
            for (int b = a + 1; b < 8; ++b) {
                if (moos[i + a] == moos[i + b]) {
                    all_different = false;
                    break;
                }
            }
        }

        if (all_different) {
            for (int j = i; j < n-7; j++){
                if (mel[j] != )
            }
            times += 1;
        }
    }
}