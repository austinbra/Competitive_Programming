#include <bits/stdc++.h>
using namespace std;

int main(){
    int n, m, x, y;
    cin >> n >> m >> x >> y;
    vector<string> grid(n);
    for (int i = 0; i < n; i++)
        cin >> grid[i];

    vector<int> white(m, 0);

    for (int col = 0; col < m; col++) {
        for (int row = 0; row < n; row++) {
            if (grid[row][col] == '#')
                white[col]++;
        }
    }

    vector<int> prefixWhite(m + 1, 0);  //repaint cost for columns 0 to i-1
    for (int i = 0; i < m; ++i)
        prefixWhite[i + 1] = prefixWhite[i] + white[i];


    const int big = INT_MAX / 2;
    vector<vector<int>> dp (m+1,vector<int>(2,big));//0 = white; 1 = balck
    dp[0][0] = dp[0][1] = 0;

    for(int col = 1; col <= m; col++){
        for(int width = x; width <= y; width++){
            int start = col - width;
            if(start < 0) break;

            int whiteCost = prefixWhite[col] - prefixWhite[start];
            int blackCost = (n * width) - (prefixWhite[col] - prefixWhite[start]);

            dp[col][0] = min(dp[col][0], dp[start][1] + whiteCost);//cost of all prior alternating blocks plus the current temporary block (white)
            dp[col][1] = min(dp[col][1], dp[start][0] + blackCost);//same but the current temporary block is black

        }
    }
    cout << min(dp[m][0], dp[m][1]) << endl;
    return 0;
}