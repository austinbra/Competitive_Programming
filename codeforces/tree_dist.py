import sys
input = sys.stdin.readline
n = int(input())


adj = [[] for _ in range(n+1)]
for i in range(n):
    u, v = map(input().split())
    adj[u].append(v)
    adj[v].append(u)
dist1 = [0] * (n+1)
dist2 = [0] * (n+1)

def dfs(n, p, dist):
    for i in adj[n]:
        if i != p:
            dfs(i, n, dist)
            dist[i] = dist[n] + 1
            dist[n] = max(dist[n], dist[i])
#euler tour
#dp kth ancestor


#unfinished