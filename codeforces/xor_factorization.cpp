#include <bits/stdc++.h>
using namespace std;

void solve() {
    int n, k;
    cin >> n >> k;

    if (k % 2 == 1) {
        // Case Odd: Print n, k times
        for (int i = 0; i < k; i++) {
            cout << n << " ";
        }
        cout << "\n";
    } else {
        
    }
    cout << "\n";
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