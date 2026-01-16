#include <bits/stdc++.h>
using namespace std;

int dfs(int u, int p, vector<vector<int>>& adj, vector<int>& depth){
    depth[u] = 0;
    for(int v : adj[u]){
        if(v == p) continue;
        depth[u] = max(depth[u], dfs(v, u, adj, depth) + 1);
    }
    return depth[u];
}

int main(){
    cin >> n;
    vector<vector<int>> adj(n);
    for(int i = 0; i < n; i++){
        int u, v;
        cin >> u >> v;
        u--, v--;
        adj[u].push_back(v);
        adj[v].push_back(u);
    }

    
}