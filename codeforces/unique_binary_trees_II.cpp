struct TreeNode {
     int val;
     TreeNode *left;
     TreeNode *right;
     TreeNode() : val(0), left(nullptr), right(nullptr) {}
     TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
     TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
};
 
//Given an integer n, return all the structurally unique BST's (binary search trees), which has exactly n nodes of unique values from 1 to n. 
//Return the answer in any order.


using namespace std;
#include <iostream>
# include <vector>
# include <algorithm>

class Solution {
    map<pair<int,int>, vector<TreeNode*>> memo;

public:
    vector<TreeNode*> generateTrees(int n) {
        memo.clear();
        return bst(1, n);
    }

    vector<TreeNode*> bst(int low, int high) {
        if (low > high) return {nullptr};

        pair<int,int> key = {low, high};
        if (memo.count(key)) return memo[key];

        vector<TreeNode*> out;

        for (int root = low; root <= high; root++) {
            vector<TreeNode*> left = bst(low, root - 1);
            vector<TreeNode*> right = bst(root + 1, high);

            for (TreeNode* L : left) {
                for (TreeNode* R : right) {
                    out.push_back(new TreeNode(root, L, R));
                }
            }
        }

        memo[key] = out;
        return out;
    }
};