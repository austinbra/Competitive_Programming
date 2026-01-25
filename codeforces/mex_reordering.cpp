#include <bits/stdc++.h>
using namespace std;


void solve() {
    int n;
    cin >> n;
    vector<int> freq(n + 2, 0);
    int x;
    for (int i = 0; i < n; i++) {
        cin >> x;
        freq[x]++;
    }
    int mex = 0;
    while (freq[mex] > 0) mex++;

    if (mex == 0) {
        cout << "NO\n";
    } else if (mex == 1) {
        cout << (freq[0] == 1 ? "YES\n" : "NO\n");
    } else {
        cout << "YES\n";
    }
}

int main() {
    cin.tie(NULL);
    int t;
    cin >> t;
    while (t--) {
        solve();
    }
    return 0;
}