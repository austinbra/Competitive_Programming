using namespace std;
#include <iostream>
# include <vector>
# include <string>
#include <sstream>


int main(){
    string str;
    cin >> str;
    
    vector<char> words;
    string output = "";
    
    string extract = "WUB";

    for(char curr : str){
        words.push_back(curr);
        int n = words.size();
        if (n >= 3){
            ostringstream temp;
            temp << words[n - 3] << words[n - 2] << words[n - 1];
            string result = temp.str();
            if (extract == result){
                words.pop_back();
                words.pop_back();
                words.pop_back();
                if (!words.empty()){
                    for (char c : words){
                        output += c;
                    }
                    words.clear();
                    output += " ";
                }
            }
        }
    }
    if (words.size() > 0){
        for (char c : words){
            output += c;
            words.pop_back();
        }
    }
    cout << output;
}
