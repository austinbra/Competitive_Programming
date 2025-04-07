using namespace std;
#include <iostream>



int main(){
    long long xa, ya, xb, yb, xc, yc;
    cin >> xa >> ya >> xb >> yb >> xc >> yc;
    long long dx1 = xb - xa;
    long long dy1 = yb - ya;
    long long dx2 = xc - xb;
    long long dy2 = yc - yb;
    long long cross = dx1 * dy2 - dy1 * dx2;
    if (cross > 0){
        cout << "LEFT" << endl;
    }
    else if (cross < 0){
        cout << "RIGHT" << endl;
    }
    else{
        cout << "TOWARDS" << endl;
    }
    return 0;
}
