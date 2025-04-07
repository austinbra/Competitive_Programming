#include <bits/stdc++.h>
using namespace std;

#include <bits/stdc++.h>
using namespace std;

int main(){
    int num_people;
    map<int, int> r;
    r[25] = 0;
    r[50] = 0;
    cin >> num_people;
    int ruples = 0;
    for (int i = 0; i < num_people; i++){
        cin >> ruples;
        //cout << ruples << " " << r[25] << " " << r[50] << endl;
        if (ruples == 100){
            if (r[25] >= 1 && r[50] >= 1){
                r[25] -= 1;
                r[50] -= 1;
            }
            else if (r[25] >= 3){
                r[25] -= 3;
            }
            else{
                cout << "NO" << endl;
                return 0;
            }
        }
        else if (ruples == 50){
            if (r[25] >= 1) r[25] -= 1;
            else{
                cout << "NO" << endl;
                return 0;
            }

        }
        r[ruples] += 1;
    }
    cout << "YES" << endl;
    return 0;
}