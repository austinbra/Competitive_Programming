#include <bits/stdc++.h>
using namespace std;


int main(){
    int num, types;
    cin >> num >> types;
    vector<int> v(num);
    vector<int> t(types);


    for(int i = 0; i < num; i++){
        cin >> v[i];
    }
    for(int i = 0; i < types; i++){
        t[i] = i;
    }

    for(int i = 1; i < v.size(); i++){
        if (v[i] == v[i-1]){

        }
    }
}