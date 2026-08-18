using namespace std;
#include <iostream>
# include <vector>
# include <algorithm>

//Write a program to solve a Sudoku puzzle by filling the empty cells.

//A sudoku solution must satisfy all of the following rules:

//Each of the digits 1-9 must occur exactly once in each row.
//Each of the digits 1-9 must occur exactly once in each column.
//Each of the digits 1-9 must occur exactly once in each of the 9 3x3 sub-boxes of the grid.
//The '.' character indicates empty cells.



class Solution {
public:
    bool row[9][10] = {};
    bool col[9][10] = {};
    bool box[9][10] = {};
    vector<pair<int, int>> empty;

    void solveSudoku(vector<vector<char>>& board) {
        for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
                if (board[r][c] == '.') {
                    empty.push_back({r, c});
                } else {
                    int d = board[r][c] - '0';
                    int b = getBox(r, c);

                    row[r][d] = true;
                    col[c][d] = true;
                    box[b][d] = true;
                }
            }
        }

        backtrack(board);
    }

    bool backtrack(vector<vector<char>>& board) {
        int bestIdx = -1;
        int bestCount = 10;

        // Pick the empty cell with the fewest valid choices
        for (int i = 0; i < empty.size(); i++) {
            auto [r, c] = empty[i];

            if (board[r][c] != '.') continue;

            int count = 0;
            for (int d = 1; d <= 9; d++) {
                if (canPlace(r, c, d)) count++;
            }

            if (count == 0) return false;

            if (count < bestCount) {
                bestCount = count;
                bestIdx = i;
            }
        }

        // No empty cells left
        if (bestIdx == -1) return true;

        auto [r, c] = empty[bestIdx];
        int b = getBox(r, c);

        for (int d = 1; d <= 9; d++) {
            if (!canPlace(r, c, d)) continue;

            board[r][c] = char('0' + d);
            row[r][d] = col[c][d] = box[b][d] = true;

            if (backtrack(board)) return true;

            board[r][c] = '.';
            row[r][d] = col[c][d] = box[b][d] = false;
        }

        return false;
    }

    bool canPlace(int r, int c, int d) {
        int b = getBox(r, c);
        return !row[r][d] && !col[c][d] && !box[b][d];
    }

    int getBox(int r, int c) {
        return (r / 3) * 3 + (c / 3);
    }
};