#include <bits/stdc++.h>
using namespace std;


int main(){
    int cases;
    cin >> cases;
    int largest;
    while(cases--){
        int l;
        cin >> l;
        int a, b;
        cin >> a >> b;
        set<int> seen;
        seen.insert(a);
        largest = a;

        while(seen.find((a+b) % l) == seen.end()){ 
            int na = (a + b) % l;

            seen.insert(na);
            largest = max(largest, na);
            a = na;
        }
        cout << largest << "\n";
    }
}