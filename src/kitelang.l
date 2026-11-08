%option noyywrap yylineno nounput noinput
%{
#include "../src/ast.hpp"
#include "parser.tab.hpp"
#include <cstdlib>
#include <cstring>
%}
%%
[ \t\r]+             ;
"//"[^\n]*            ;
\n                    ;
"int"                 return INT;
"float"               return FLOAT;
"bool"                return BOOL;
"void"                return VOID;
"pecha"               return PECHA;
"warna"               return WARNA;
"dheel"               return DHEEL;
"dor"                 return DOR;
"palta"               return PALTA;
"return"              return RETURN;
"print"               return PRINT;
"true"                { yylval.node = new Node(N_NUM, 1); return NUMBER; }
"false"               { yylval.node = new Node(N_NUM, 0); return NUMBER; }
[0-9]+(\.[0-9]+)?     { yylval.node = new Node(N_NUM, atoi(yytext)); return NUMBER; }
[A-Za-z_][A-Za-z0-9_]* { yylval.str = strdup(yytext); return ID; }
"->"                  return ARROW;
"=="                  return EQ;
"!="                  return NE;
"<="                  return LE;
">="                  return GE;
"&&"                  return AND;
"||"                  return OR;
.                     return yytext[0];
%%
