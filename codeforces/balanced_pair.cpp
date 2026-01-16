#include <bits/stdc++.h>
using namespace std;

int main() {
    int N;
    cin >> N;

    vector<int> weights(N);
    string name;
    int weight;

    for (int i = 0; i < N; ++i) {
        cin >> name >> weight;
        weights[i] = weight;
    }

    sort(weights.begin(), weights.end());

    int min_diff = INT_MAX;
    for (int i = 1; i < N; ++i) {
        min_diff = min(min_diff, weights[i] - weights[i - 1]);
    }

    cout << min_diff << endl;
    return 0;
}