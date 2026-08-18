using namespace std;
#include <iostream>
# include <vector>
# include <algorithm>

//Given n pairs of parentheses, write a function to generate all combinations of well-formed parentheses.

class Solution {
public:
    vector<string> ans;

    vector<string> generateParenthesis(int n) {
        string curr;
        backtrack(0, 0, n, curr);
        return ans;
    }

    void backtrack(int open, int close, int n, string& curr) {
        if (curr.size() == 2 * n) {
            ans.push_back(curr);
            return;
        }

        if (open < n) {
            curr.push_back('(');
            backtrack(open + 1, close, n, curr);
            curr.pop_back();
        }

        if (close < open) {
            curr.push_back(')');
            backtrack(open, close + 1, n, curr);
            curr.pop_back();
        }
    }
};