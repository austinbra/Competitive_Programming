using namespace std;
#include <iostream>
# include <vector>
# include <algorithm>

//Given a string containing digits from 2-9 inclusive, return all possible letter combinations that the number could represent. Return the answer in any order.

//A mapping of digits to letters (just like on the telephone buttons) is given below. Note that 1 does not map to any letters.



class Solution {
public:
    vector<string> ans;
    vector<string> mp = {"", "", "abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"};

    vector<string> letterCombinations(string digits) {
        if (digits.empty()) return {};

        string curr;
        curr.reserve(digits.size());

        backtrack(0, curr, digits);
        return ans;
    }

    void backtrack(int i, string& curr, const string& digits) {
        if (i == digits.size()) {
            ans.push_back(curr);
            return;
        }
        string letters = mp[digits[i] - '0'];
        for (char c : letters) {
            curr.push_back(c);
            backtrack(i + 1, curr, digits);
            curr.pop_back();
        }
    }
};