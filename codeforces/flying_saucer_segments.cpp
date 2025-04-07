using namespace std;
#include <iostream>
#include <vector>
#include <sstream>
long long modpow(long long base, long long exp, long long mod) {
    long long result = 1;
    base %= mod;
    while (exp > 0) {
        if (exp % 2)
            result = result * base % mod;
        base = base * base % mod;
        exp /= 2;
    }
    return result;
}

int main() {
    long long n, m;
    cin >> n >> m;
    long long res = (modpow(3, n, m) - 1 + m) % m;
    cout << res << endl;
    return 0;
}