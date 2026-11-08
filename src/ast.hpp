#ifndef KITELANG_AST_HPP
#define KITELANG_AST_HPP
#include <string>
#include <vector>
#include <map>
#include <memory>
enum Kind { N_NUM, N_ID, N_BIN, N_CALL, N_INDEX, N_ASSIGN, N_DECL, N_BLOCK, N_IF, N_WHILE, N_DOR, N_RETURN, N_SWAP, N_PRINT, N_FUNC, N_PROGRAM };
struct Node { Kind k; int num=0, size=0; std::string text, type; Node *a=nullptr,*b=nullptr,*c=nullptr; std::vector<Node*> kids; Node(Kind q,int n=0):k(q),num(n){} Node(Kind q,const char*s):k(q),text(s){} };
#endif
