using namespace std;
#include <iostream>
# include <vector>
# include <algorithm>

int main(){
    int total_piles = 0;
    int total_queries = 0;

    cin >> total_piles;
    vector<pair<int, int>> piles(total_piles, {0,0});
    for (int i = 0; i < total_piles; i++){
        cin >> piles[i].first;
    }

    sort(piles.begin(), piles.end());
    vector<pair<int, int>> og_pile = piles;

    cin >> total_queries;
    vector<int> queries(total_queries);
    for (int i = 0; i < total_queries; i++){
        cin >> queries[i];
    }


    for (int k : queries){
        bool valid = true;
        int movements = 0;
        piles = og_pile;
        for (auto& pile : piles) {
            pile.second = 0;
        }

        
        while (valid){
            int nulls = 0;
            auto selected = make_pair(0, false);
            for (int i = 0; i < total_piles; i++){
                              
                if (piles[i].first == 0){
                    nulls++;
                }
                else{
                    if (selected.second == true && piles[i].first == selected.first){ 
                        continue;
                    }
                    
                    if(selected.second == false){
                        selected.second = true;
                        selected.first = piles[i].first;
                        piles[i].first = 0;
                        nulls++;
                    }
                    else if (selected.second == true && piles[i].second < k){
                        piles[i].second += 1;
                        piles[i].first += selected.first;
                        movements += selected.first;

                        int fix = i;
                        if (selected.second == true){
                            while(fix < total_piles - 1){
                                if (piles[fix].first > piles[fix+1].first){
                                    swap(piles[fix], piles[fix+1]);
                                }
                                fix++;
                            }
                        }


                        continue;
                    }
                }
            }
            if (nulls >= total_piles - 1) valid = false;
        }
        cout << movements << " ";
    }
    cout << endl;
}
