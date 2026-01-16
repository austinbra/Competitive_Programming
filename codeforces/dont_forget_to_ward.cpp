#include <bits/stdc++.h>
using namespace std;

int main() {
    int num_bushes;
    cin >> num_bushes;

    long long xmin = LLONG_MAX, xmax = LLONG_MIN;
    long long ymin = LLONG_MAX, ymax = LLONG_MIN;

    for (int i = 0; i < num_bushes; i++) {
        long long x, y;
        cin >> x >> y;
        xmin = min(xmin, x);
        xmax = max(xmax, x + 1);
        ymin = min(ymin, y);
        ymax = max(ymax, y + 1);
    }
    long long difX = xmax - xmin;
    long long difY = ymax - ymin;
    long long b = max(difY, difX);
    cout << b << endl;
    return 0;
}