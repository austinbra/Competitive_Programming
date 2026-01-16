#include <bits/stdc++.h>
using namespace std;


int main(){
    string animal;

    cin >> animal;
    if (static_cast<int>(animal[0]) <= 109){
        cout << "alpaca" << endl;
    }
    else cout << "zebra" << endl;
}