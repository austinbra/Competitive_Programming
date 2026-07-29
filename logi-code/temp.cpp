#include <vector>
#include <algorithm>
#include <unordered_map>
#include <numeric>
int longestSubarrayWithXorK(const std::vector<int>& nums, int k){
    int best = 0;
    int prefix = 0;
    std::unordered_map<int,int> m;
    m[0] = -1;
    
    for (int i = 1; i < nums.size(); i++){
        prefix ^= nums[i];
        int needed = prefix ^ k;
        auto it = m.find(needed);
        if (it != m.end()) {
            best = std::max(best, i - it->second);
        }
        if (m.find(prefix) == m.end()){
            m[prefix] = i;
        }
    }
    return best;
}

int minSwapsToGroupOnesCircular(const std::vector<int>& nums) {
    int n = nums.size();

    if (n == 0)
        return 0;

    int ones = std::accumulate(nums.begin(), nums.end(), 0);
    if (ones <= 1)
        return 0;

    int zeros = 0;
    int windowSize = ones;

    for (int i = 0; i < windowSize; ++i) {
        if (nums[i] == 0)
            ++zeros;
    }
    int best = zeros;

    for (int i = 1; i < n; ++i) {
        int leftPrev = i - 1;
        int right = (i + windowSize - 1) % n;

        if (nums[leftPrev] == 0)
            --zeros;

        if (nums[right] == 0)
            ++zeros;

        best = std::min(best, zeros);
    }

    return best;
}