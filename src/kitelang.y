%{
#include "../src/ast.hpp"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <algorithm>
extern int yylex(); extern FILE *yyin; extern int yylineno;
void yyerror(const char *s) { fprintf(stderr, "KiteLang syntax error at line %d: %s\n", yylineno, s); }
Node *root;
static Node* bin(const char* op, Node*x, Node*y) { Node*n=new Node(N_BIN,op); n->a=x;n->b=y;return n; }
static Node* id(const char*s) { return new Node(N_ID,s); }
static Node* block(Node*x) { Node*n=new Node(N_BLOCK); if(x)n->kids=x->kids; return n; }
%}
%union { Node* node; char* str; }
%token <str> ID
%token <node> NUMBER
%token INT FLOAT BOOL VOID PECHA WARNA DHEEL DOR PALTA RETURN PRINT ARROW EQ NE LE GE AND OR
%type <node> program functions function type params param block stmts stmt decl decl_items decl_item expr args initlist
%left OR
%left AND
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/' '%'
%right UMINUS '!'
%start program
%%
program: functions { root=new Node(N_PROGRAM); root->kids=$1->kids; $$=root; };
functions: /* empty */ { $$=new Node(N_BLOCK); } | functions function { $1->kids.push_back($2); $$=$1; };
function: type ID '(' params ')' block { $$=new Node(N_FUNC,$2); $$->type=$1->type; $$->kids=$4->kids; $$->a=$6; free($2); };
type: INT { $$=new Node(N_ID,"int");$$->type="int"; } | FLOAT { $$=new Node(N_ID,"float");$$->type="float"; } | BOOL { $$=new Node(N_ID,"bool");$$->type="bool"; } | VOID { $$=new Node(N_ID,"void");$$->type="void"; };
params: /* empty */ { $$=new Node(N_BLOCK); } | param { $$=new Node(N_BLOCK);$$->kids.push_back($1); } | params ',' param { $1->kids.push_back($3);$$=$1; };
param: type ID { $$=new Node(N_DECL,$2);$$->type=$1->type;free($2); } | type ID '[' ']' { $$=new Node(N_DECL,$2);$$->type=$1->type;$$->size=-1;free($2); };
block: '{' stmts '}' { $$=block($2); };
stmts: /* empty */ { $$=new Node(N_BLOCK); } | stmts stmt { $1->kids.push_back($2);$$=$1; };
stmt: decl ';' { $$=$1; } | expr ';' { $$=$1; } | RETURN expr ';' { $$=new Node(N_RETURN);$$->a=$2; }
 | PRINT '(' expr ')' ';' { $$=new Node(N_PRINT);$$->a=$3; }
 | PALTA '(' expr ',' expr ')' ';' { $$=new Node(N_SWAP);$$->a=$3;$$->b=$5; }
 | PECHA '(' expr ')' stmt { $$=new Node(N_IF);$$->a=$3;$$->b=$5; } | PECHA '(' expr ')' stmt WARNA stmt { $$=new Node(N_IF);$$->a=$3;$$->b=$5;$$->c=$7; }
 | DHEEL '(' expr ')' stmt { $$=new Node(N_WHILE);$$->a=$3;$$->b=$5; }
 | DOR '(' ID ':' expr ARROW expr ')' stmt { $$=new Node(N_DOR,$3);$$->a=$5;$$->b=$7;$$->c=$9;free($3); }
 | block { $$=$1; };
decl: type decl_items { $2->type=$1->type; for(auto*x:$2->kids)x->type=$1->type; $$=$2; };
decl_items: decl_item { $$=new Node(N_BLOCK);$$->kids.push_back($1); } | decl_items ',' decl_item { $1->kids.push_back($3);$$=$1; };
decl_item: ID { $$=new Node(N_DECL,$1);free($1); } | ID '=' expr { $$=new Node(N_DECL,$1);$$->a=$3;free($1); } | ID '[' expr ']' { $$=new Node(N_DECL,$1);$$->size=-2;$$->a=$3;free($1); } | ID '[' expr ']' '=' '{' initlist '}' { $$=new Node(N_DECL,$1);$$->size=-2;$$->a=$3;$$->kids=$7->kids;free($1); };
initlist: expr { $$=new Node(N_BLOCK);$$->kids.push_back($1); } | initlist ',' expr { $1->kids.push_back($3);$$=$1; };
expr: NUMBER { $$=$1; } | ID { $$=id($1);free($1); } | ID '[' expr ']' { $$=new Node(N_INDEX,$1);$$->a=$3;free($1); }
 | ID '(' args ')' { $$=new Node(N_CALL,$1);$$->kids=$3->kids;free($1); }
 | ID '=' expr { $$=new Node(N_ASSIGN,$1);$$->a=$3;free($1); } | ID '[' expr ']' '=' expr { Node*l=new Node(N_INDEX,$1);l->a=$3;$$=new Node(N_ASSIGN);$$->a=l;$$->b=$6;free($1); }
 | expr '+' expr { $$=bin("+",$1,$3); } | expr '-' expr { $$=bin("-",$1,$3); } | expr '*' expr { $$=bin("*",$1,$3); } | expr '/' expr { $$=bin("/",$1,$3); } | expr '%' expr { $$=bin("%",$1,$3); }
 | expr '<' expr { $$=bin("<",$1,$3); } | expr '>' expr { $$=bin(">",$1,$3); } | expr LE expr { $$=bin("<=",$1,$3); } | expr GE expr { $$=bin(">=",$1,$3); } | expr EQ expr { $$=bin("==",$1,$3); } | expr NE expr { $$=bin("!=",$1,$3); } | expr AND expr { $$=bin("&&",$1,$3); } | expr OR expr { $$=bin("||",$1,$3); }
 | '-' expr %prec UMINUS { $$=bin("neg",$2,nullptr); } | '!' expr { $$=bin("!",$2,nullptr); } | '(' expr ')' { $$=$2; };
args: /* empty */ { $$=new Node(N_BLOCK); } | expr { $$=new Node(N_BLOCK);$$->kids.push_back($1); } | args ',' expr { $1->kids.push_back($3);$$=$1; };
%%

struct Val { int n=0; std::shared_ptr<std::vector<int>> arr; bool isarr()const{return (bool)arr;} };
struct Env { std::map<std::string,Val> v; Env*up=nullptr; Val& get(const std::string&s){if(v.count(s))return v[s];if(up)return up->get(s);throw std::runtime_error("undefined name: "+s);} };
struct Ret { bool yes=false; int n=0; };
std::map<std::string,Node*> funs;
static int ev(Node*x,Env&e);
static void set(Node*x,int v,Env&e) { if(x->k==N_ID)e.get(x->text).n=v; else if(x->k==N_INDEX){Val&a=e.get(x->text);(*a.arr)[ev(x->a,e)]=v;} else throw std::runtime_error("not assignable"); }
static int call(Node*x,Env&e) { auto it=funs.find(x->text);if(it==funs.end())throw std::runtime_error("unknown function: "+x->text);Node*f=it->second; if(f->kids.size()!=x->kids.size())throw std::runtime_error("wrong argument count");Env z; for(size_t i=0;i<f->kids.size();++i){Node*p=f->kids[i];if(p->size==-1){if(x->kids[i]->k!=N_ID)throw std::runtime_error("array argument must be an array name");z.v[p->text]=e.get(x->kids[i]->text);}else z.v[p->text].n=ev(x->kids[i],e);} Ret r; std::function<void(Node*,Env&,Ret&)> run;
 run=[&](Node*s,Env&q,Ret&rr){ if(!s||rr.yes)return; if(s->k==N_BLOCK){for(auto*t:s->kids)run(t,q,rr);return;} if(s->k==N_DECL){Val&v=q.v[s->text];if(s->size==-2){int n=ev(s->a,q);v.arr=std::make_shared<std::vector<int>>(n);for(size_t j=0;j<s->kids.size();j++)(*v.arr)[j]=ev(s->kids[j],q);}else v.n=s->a?ev(s->a,q):0;return;} if(s->k==N_RETURN){rr.yes=true;rr.n=ev(s->a,q);return;} if(s->k==N_PRINT){std::cout<<ev(s->a,q)<<'\n';return;} if(s->k==N_SWAP){int a=ev(s->a,q),b=ev(s->b,q);set(s->a,b,q);set(s->b,a,q);return;} if(s->k==N_IF){run(ev(s->a,q)?s->b:s->c,q,rr);return;} if(s->k==N_WHILE){while(ev(s->a,q))run(s->b,q,rr);return;} if(s->k==N_DOR){int end=ev(s->b,q);q.v[s->text].n=ev(s->a,q);while(q.get(s->text).n<=end){run(s->c,q,rr);q.get(s->text).n++;}return;} ev(s,q);}; run(f->a,z,r);return r.n; }
static int ev(Node*x,Env&e){if(!x)return 0; if(x->k==N_NUM)return x->num;if(x->k==N_ID)return e.get(x->text).n;if(x->k==N_INDEX){Val&a=e.get(x->text);return (*a.arr)[ev(x->a,e)];}if(x->k==N_ASSIGN){int n=ev(x->a?x->b:x->a,e); if(x->b){set(x->a,n,e);return n;}e.get(x->text).n=n;return n;}if(x->k==N_CALL)return call(x,e);if(x->k==N_BIN){int a=ev(x->a,e),b=x->b?ev(x->b,e):0;std::string o=x->text;if(o=="+")return a+b;if(o=="-")return a-b;if(o=="*")return a*b;if(o=="/")return a/b;if(o=="%")return a%b;if(o=="<")return a<b;if(o==">")return a>b;if(o=="<=")return a<=b;if(o==">=")return a>=b;if(o=="==")return a==b;if(o=="!=")return a!=b;if(o=="&&")return a&&b;if(o=="||")return a||b;if(o=="neg")return-a;return!a;}throw std::runtime_error("bad expression");}
static int interpret(){for(auto*f:root->kids)funs[f->text]=f;Node*m=funs.count("main")?funs["main"]:nullptr;if(!m)throw std::runtime_error("main function missing");return call(new Node(N_CALL,"main"),*(new Env));}

// LLVM textual IR generator. It deliberately lowers KiteLang's special syntax to ordinary blocks, branches, loads and stores.
struct CG { std::ostringstream o; int t=0,l=0; std::map<std::string,std::string> vars; std::string tmp(){return "%t"+std::to_string(t++);}std::string lab(const char*s){return std::string(s)+std::to_string(l++);}
std::string ex(Node*x){
 if(x->k==N_NUM)return std::to_string(x->num);
 if(x->k==N_ID){auto z=tmp();o<<z<<" = load i32, ptr "<<vars[x->text]<<"\n";return z;}
 if(x->k==N_INDEX){auto index=ex(x->a),g=tmp(),z=tmp();o<<g<<" = getelementptr inbounds i32, ptr "<<vars[x->text]<<", i32 "<<index<<"\n"<<z<<" = load i32, ptr "<<g<<"\n";return z;}
 if(x->k==N_CALL){bool isvoid=false;for(auto*f:root->kids)if(f->text==x->text)isvoid=f->type=="void";std::vector<std::string> args;for(auto*a:x->kids)args.push_back(a->k==N_ID&&vars.count(a->text+"#arr")?"ptr "+vars[a->text]:"i32 "+ex(a));if(!isvoid){auto q=tmp();o<<q<<" = call i32 @"<<x->text<<"(";}else o<<"call void @"<<x->text<<"(";for(size_t i=0;i<args.size();i++)o<<(i?", ":"")<<args[i];o<<")\n";return isvoid?"0":("%t"+std::to_string(t-1));}
 if(x->k==N_ASSIGN){std::string z=ex(x->b?x->b:x->a);Node*lhs=x->b?x->a:new Node(N_ID,x->text.c_str());if(lhs->k==N_ID)o<<"store i32 "<<z<<", ptr "<<vars[lhs->text]<<"\n";else {auto index=ex(lhs->a),g=tmp();o<<g<<" = getelementptr inbounds i32, ptr "<<vars[lhs->text]<<", i32 "<<index<<"\nstore i32 "<<z<<", ptr "<<g<<"\n";}return z;}
 if(x->k==N_BIN){std::string a=ex(x->a),b=x->b?ex(x->b):"0",z=tmp(),op=x->text;if(op=="+")o<<z<<" = add i32 ";else if(op=="-")o<<z<<" = sub i32 ";else if(op=="*")o<<z<<" = mul i32 ";else if(op=="/")o<<z<<" = sdiv i32 ";else if(op=="%")o<<z<<" = srem i32 ";else {std::string c=(op=="<"?"slt":op==">"?"sgt":op=="<="?"sle":op==">="?"sge":op=="=="?"eq":"ne");o<<z<<" = icmp "<<c<<" i32 ";}o<<a<<", "<<b<<"\n";return z;}return "0";}
void st(Node*x){if(!x)return;if(x->k==N_BLOCK){for(auto*q:x->kids)st(q);return;}if(x->k==N_DECL){if(x->size==-2){auto p=tmp();int n=x->a->num;o<<p<<" = alloca ["<<n<<" x i32]\n";auto g=tmp();o<<g<<" = getelementptr inbounds ["<<n<<" x i32], ptr "<<p<<", i32 0, i32 0\n";vars[x->text]=g;vars[x->text+"#arr"]="1";for(size_t i=0;i<x->kids.size();i++){auto value=ex(x->kids[i]);auto e=tmp();o<<e<<" = getelementptr inbounds i32, ptr "<<g<<", i32 "<<i<<"\nstore i32 "<<value<<", ptr "<<e<<"\n";}}else{auto p=tmp();vars[x->text]=p;auto value=x->a?ex(x->a):"0";o<<p<<" = alloca i32\nstore i32 "<<value<<", ptr "<<p<<"\n";}return;}if(x->k==N_PRINT){auto v=ex(x->a);o<<"call i32 (ptr, ...) @printf(ptr @fmt, i32 "<<v<<")\n";return;}if(x->k==N_SWAP){auto a=ex(x->a),b=ex(x->b);auto store=[&](Node*q,std::string v){if(q->k==N_ID)o<<"store i32 "<<v<<", ptr "<<vars[q->text]<<"\n";else{auto ix=ex(q->a),g=tmp();o<<g<<" = getelementptr inbounds i32, ptr "<<vars[q->text]<<", i32 "<<ix<<"\nstore i32 "<<v<<", ptr "<<g<<"\n";}};store(x->a,b);store(x->b,a);return;}if(x->k==N_RETURN){auto v=ex(x->a);o<<"ret i32 "<<v<<"\n";return;}if(x->k==N_IF){auto c=ex(x->a),a=lab("then"),b=lab("else"),z=lab("endif");o<<"br i1 "<<c<<", label %"<<a<<", label %"<<(x->c?b:z)<<"\n"<<a<<":\n";st(x->b);o<<"br label %"<<z<<"\n";if(x->c){o<<b<<":\n";st(x->c);o<<"br label %"<<z<<"\n";}o<<z<<":\n";return;}if(x->k==N_WHILE){auto h=lab("while"),bo=lab("body"),z=lab("endwhile");o<<"br label %"<<h<<"\n"<<h<<":\n";auto c=ex(x->a);o<<"br i1 "<<c<<", label %"<<bo<<", label %"<<z<<"\n"<<bo<<":\n";st(x->b);o<<"br label %"<<h<<"\n"<<z<<":\n";return;}if(x->k==N_DOR){auto p=tmp();vars[x->text]=p;auto first=ex(x->a);o<<p<<" = alloca i32\nstore i32 "<<first<<", ptr "<<p<<"\n";auto end=ex(x->b),h=lab("dor"),bo=lab("dorbody"),z=lab("enddor");o<<"br label %"<<h<<"\n"<<h<<":\n";auto v=ex(new Node(N_ID,x->text.c_str())),c=tmp();o<<c<<" = icmp sle i32 "<<v<<", "<<end<<"\nbr i1 "<<c<<", label %"<<bo<<", label %"<<z<<"\n"<<bo<<":\n";st(x->c);auto n=ex(new Node(N_ID,x->text.c_str())),inc=tmp();o<<inc<<" = add i32 "<<n<<", 1\nstore i32 "<<inc<<", ptr "<<p<<"\nbr label %"<<h<<"\n"<<z<<":\n";return;}ex(x);}
};
static void emit(const char*file){std::ofstream f(file);f<<"@fmt = private constant [4 x i8] c\"%d\\0A\\00\"\ndeclare i32 @printf(ptr, ...)\n";for(auto fn:root->kids){CG g;std::ostringstream head;for(size_t i=0;i<fn->kids.size();i++){auto p=fn->kids[i];if(p->size==-1){g.vars[p->text]="%arg"+std::to_string(i);g.vars[p->text+"#arr"]="1";}else{auto q=g.tmp();g.vars[p->text]=q;head<<q<<" = alloca i32\nstore i32 %arg"<<i<<", ptr "<<q<<"\n";}}g.st(fn->a);f<<"define "<<(fn->type=="void"?"void":"i32")<<" @"<<fn->text<<"(";for(size_t i=0;i<fn->kids.size();i++){if(i)f<<", ";f<<(fn->kids[i]->size==-1?"ptr":"i32")<<" %arg"<<i;}f<<") {\nentry:\n"<<head.str()<<g.o.str();if(fn->type=="void")f<<"ret void\n";else f<<"ret i32 0\n";f<<"}\n";}}
int main(int argc,char**argv){
 if(argc<2){fprintf(stderr,"usage: %s source.kite [-o output.ll]\n",argv[0]);return 2;}
 yyin=fopen(argv[1],"r");if(!yyin){perror(argv[1]);return 2;}if(yyparse())return 1;
 try{
#ifdef MODE_INTERPRETER
 return interpret();
#else
 const char*out=(argc>=4&&std::string(argv[2])=="-o")?argv[3]:"out.ll";emit(out);std::cout<<"generated "<<out<<'\n';return 0;
#endif
 }catch(const std::exception&e){std::cerr<<"KiteLang error: "<<e.what()<<'\n';return 1;}
}
