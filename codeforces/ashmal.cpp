#include <bits/stdc++.h>
using namespace std;


int main(){
    int cases;
    cin >> cases;
    while(cases--){

        int n;
        cin >> n;

        vector<string> line(n);
        for (int i = 0; i < n; i++){
            cin >> line[i];
        }
        string s = line[0];

        for (int i = 1; i < n; i++){
            s = min(s + line[i], line[i] + s);
        }
        cout << s << "\n";
    }
}