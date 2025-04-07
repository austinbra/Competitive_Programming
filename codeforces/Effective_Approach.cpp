#include <iostream>
#include <vector>
using namespace std;

int main(){
    int n;
    cin >> n;
    vector<int> arr(n + 1);
    vector<int> position(n + 1);
    for (int i = 1; i <= n; i++) {
        cin >> arr[i];
        position[arr[i]] = i;
    }
    int m;
    cin >> m;
    vector<int> search(m);
    for (int i = 0; i < m; i++) {
        cin >> search[i];
    }

    long long vasya = 0, petya = 0;
    for (int i = 0; i < m; i++) {
        int pos = position[search[i]];
        vasya += pos;
        petya += n - pos + 1;
    }

    cout << vasya << " " << petya << endl;
    return 0;

}