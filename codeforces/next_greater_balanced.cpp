using namespace std;
#include <iostream>
# include <vector>
# include <algorithm>

//An integer x is numerically balanced if for every digit d in the number x, there are exactly d occurrences of that digit in x.

//Given an integer n, return the smallest numerically balanced number strictly greater than n.


class Solution {
public:
    int nextBeautifulNumber(int n) {
        static vector<int> nums = build(); //compiler skips this line after the first call

        for (int x : nums) {
            if (x > n) return x;
        }

        return -1;
    }

    vector<int> build() {
        vector<int> nums;
        vector<int> freq(10, 0);
        generate(0, freq, nums);
        sort(nums.begin(), nums.end());
        return nums;
    }

    void generate(long num, vector<int>& freq, vector<int>& nums) {
        if (num > 1224444) return;
        if (num > 0 && beautiful(freq)) {
            nums.push_back((int)num);
        }

        for (int d = 1; d <= 7; d++) {
            if (freq[d] < d) {
                freq[d]++;
                long next = num * 10 + d;

                generate(next, freq, nums);
                freq[d]--;
            }
        }
    }

    bool beautiful(const vector<int>& freq) {
        for (int d = 1; d <= 7; d++) {
            if (freq[d] != 0 && freq[d] != d) return false;
        }
        return true;
    }
};