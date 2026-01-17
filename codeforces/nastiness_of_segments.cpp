#include <bits/stdc++.h>

struct SegmentTree{
    int n;
    std::vector<int> tree;

    SegmentTree(const std::vector<int>& arr){
        n = arr.size();
        tree.resize(4*n);
        build(arr, 1, 0, n-1);
    }

    void build(const std::vector<int>& arr, int node, int start, int end){
        if(start == end){
            tree[node] = arr[start];
            return;
        }
        int mid = (start + end) / 2;
        build(arr, 2*node, start, mid);
        build(arr, 2*node+1, mid+1, end);
        tree[node] = std::min(tree[2*node], tree[2*node+1]);
    }

    void update(int node, int start, int end, int idx, int val) {
        if(start == end){
            tree[node] = val;
            return;
        }
        int mid = (start + end) / 2;
        if(idx <= mid){
            update(2*node, start, mid, idx, val);
        } else {
            update(2*node+1, mid+1, end, idx, val);
        }
        tree[node] = std::min(tree[2*node], tree[2*node+1]);
    }

    int query(int node, int start, int end, int l, int r){
        if(r < start || end < l){
            return INT_MAX;
        }
        if(l <= start && end <= r){
            return tree[node];
        }
        int mid = (start + end) / 2;
        int left_min = query(2*node, start, mid, l, r);
        int right_min = query(2*node+1, mid+1, end, l, r);
        return std::min(left_min, right_min);
    }
    void update(int idx, int val){
        update(1, 0, n-1, idx, val);
    }
    int query(int l, int r){
        return query(1, 0, n-1, l, r);
    }
};

int main(){
    int cases;
    std::vector<int> arr;
    std::cin >> cases;
    while (cases--) {
        int length,queries;
        std::cin >> length >> queries;

        std::vector<int> nasty_set;

        std::vector<int> arr(length);
        for(auto i = 0; i < length; i++){
            std::cin >> arr[i];
        }
        SegmentTree seg_tree(arr);
        while(queries--){
            int idx;
            std::cin >> idx;
            if (idx == 1){
                int i,x;
                std::cin >> i >> x;
                seg_tree.update(i-1, x);
            }
            else{
                int l,r;
                std::cin >> l >> r;
                l--; r--;
                int nastiness = 0;
                
                int low = 0;
                int high = r-l;

                while (low <= high){
                    int mid = low + (high - low) / 2;
                    int curr_min = seg_tree.query(l, l + mid);
                    if (curr_min == mid){
                        nastiness++;
                        low = mid + 1;
                    }
                    else if (curr_min < mid) {
                        high = mid - 1;
                    } else {
                        low = mid + 1;
                    }
                }
                nasty_set.push_back(nastiness);
            }
        }
        for(auto i : nasty_set){
            std::cout << i << "\n";
        }
    }
    return 0;
}