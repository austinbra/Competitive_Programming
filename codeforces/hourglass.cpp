#include <bits/stdc++.h>
using namespace std;


int main(){
    int cases;
    cin >> cases;
    vector<int> results;
    while(cases--){
        int s, k, m;
        cin >> s >> k >> m;
        int remaining;
        if(s <= k){
            remaining = s - (m % k);
        }
        else{
            if ((m / k) % 2 == 0){
                remaining = s - (m % k);
            }
            else{
                remaining = k - (m % k);
            }
        }

        if (remaining < 0) remaining = 0;
        results.push_back(remaining);
    }
    for(auto res : results){
        cout << res << "\n";
    }
    return 0;
}