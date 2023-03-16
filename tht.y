%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include <string.h>
    #include <time.h>
    #include <math.h>
    #include "tht.h"

    #define YYDEBUG 0

    nodeType *cond(double dValue);          /* Constant double type node */
    nodeType *cons(char *sValue);           /* Constant string type node */
    nodeType *opr(int oper, int nops, ...); /* Operator type node */
    void freeNode(nodeType *p);             /* Free the node */
    double ex(nodeType *p);                 /* Execute graph */
    int yylex(void);

    void yyerror(char *);
    double sym[SYMSIZE];        /* Symbol table */
    char vars[SYMSIZE][IDLEN];  /* Variable table: for mapping variables to symbol table */
    unsigned int seed;
%}

%union {
    double dValue;
    char *sValue;
    char *vName;
    nodeType *nPtr;
}

// double value token for number
%token <dValue> NUMBER
// string value token for strings
%token <sValue> STRING
// rest tokens
%token PRINT EXIT


// left associates with other tokens
%left AND OR
%left GE LE '=' NE '>' '<'
%left '+' '-'
%left '*' '/' '%'
%left NOT
%left '^'

// no associations
%nonassoc UMINUS

// non terminal type. nPtr is custome type to store both doubles and string
%type <nPtr> statement expression statement_list

%%
program : function { exit(0); }
        ;

function : 
         | function statement { ex($2); }
         ;

statement : ';' { $$ = opr(';', 2, NULL, NULL); }
          | expression ';' { $$ = $1; }
          | EXIT ';' { exit(0); }
          | PRINT expression ';' { $$ = opr(PRINT, 1, $2); }
          | PRINT STRING ';' { $$ = opr(PRINT, 1, cons($2)); }
          | '{' statement_list '}' { $$ = $2; }
          ;

statement_list : statement { $$ = $1; }
               | statement_list statement { $$ = opr(';', 2, $1, $2); }
               ;

expression : NUMBER { $$ = cond($1); }
           | '-' expression %prec UMINUS { $$ = opr(UMINUS, 1, $2); }
           | expression '^' expression { $$ = opr('^', 2, $1, $3); }
           | expression '+' expression { $$ = opr('+', 2, $1, $3); }
           | expression '-' expression { $$ = opr('-', 2, $1, $3); }
           | expression '*' expression { $$ = opr('*', 2, $1, $3); }
           | expression '/' expression { $$ = opr('/', 2, $1, $3); }
           | expression '%' expression { $$ = opr('%', 2, $1, $3); }
           | expression '<' expression { $$ = opr('<', 2, $1, $3); }
           | expression '>' expression { $$ = opr('>', 2, $1, $3); }
           | expression GE expression { $$ = opr(GE, 2, $1, $3); }
           | expression LE expression { $$ = opr(LE, 2, $1, $3); }
           | expression '=' expression { $$ = opr('=', 2, $1, $3); }
           | expression NE expression { $$ = opr(NE, 2, $1, $3); }
           | expression AND expression { $$ = opr(AND, 2, $1, $3); }
           | expression OR expression { $$ = opr(OR, 2, $1, $3); }
           | NOT expression { $$ = opr(NOT, 1, $2); }
           | '(' expression ')' { $$ = $2; }
           ;
%%



nodeType *cond(double dValue) {
    nodeType *p;
     
    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeCon;
    p->con.type = typeNum;
    p->con.dValue = dValue;

    return p;
}

nodeType *cons(char *sValue) {
    nodeType *p;
     
    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeCon;
    p->con.type = typeStr;
    p->con.sValue = strdup(sValue);

    return p;
}

nodeType *opr(int oper, int nops, ...) {
    va_list ap;
    nodeType *p;
     
    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
    if ((p->opr.op = malloc(nops * sizeof(nodeType *))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    
    va_start(ap, nops);
    for (int i = 0; i < nops; i++) 
        p->opr.op[i] = va_arg(ap, nodeType *);
    va_end(ap);

    return p;
}

double ex(nodeType *p) {
    if (!p) return 0;

    switch (p->type) {
        case typeCon: return p->con.dValue;
        case typeId: return sym[p->id.i];
        case typeOpr:
            switch (p->opr.oper) {
                case PRINT:
                    if (p->opr.op[0]->type == typeCon && p->opr.op[0]->con.type == typeStr) {
                        char *sValue = p->opr.op[0]->con.sValue;
                        int i, slen = strlen(sValue);
                        for (i = 0; i < slen-1; i++) {
                            if (sValue[i] == '\\' && sValue[i+1] == 'n') {
                                printf("\n");
                                i++;
                            }
                            else if (sValue[i] == '\\' && sValue[i+1] == 't') {
                                printf("\t");
                                i++;
                            }
                            else printf("%c", sValue[i]);
                        }
                        if (i == slen-1) printf("%c", sValue[i]);
                        return 0;
                    }
                    else {
                        double dValue = ex(p->opr.op[0]);
                        if (dValue == floor(dValue)) printf("%d", (int)dValue);
                        else if (dValue - floor(dValue) < 1e-6) printf("%e", dValue);
                        else printf("%lf", dValue);
                        return 0;
                    }
                case ';':
                    ex(p->opr.op[0]);
                    return ex(p->opr.op[1]);
                case UMINUS: return -ex(p->opr.op[0]);
                case '^': return pow(ex(p->opr.op[0]), ex(p->opr.op[1]));
                case '+': return ex(p->opr.op[0]) + ex(p->opr.op[1]);
                case '-': return ex(p->opr.op[0]) - ex(p->opr.op[1]);
                case '*': return ex(p->opr.op[0]) * ex(p->opr.op[1]);
                case '/': return ex(p->opr.op[0]) / ex(p->opr.op[1]);
                case '%': return (int)ex(p->opr.op[0]) % (int)ex(p->opr.op[1]);
                case '>': return ex(p->opr.op[0]) > ex(p->opr.op[1]);
                case '<': return ex(p->opr.op[0]) < ex(p->opr.op[1]);
                case GE: return ex(p->opr.op[0]) >= ex(p->opr.op[1]);
                case LE: return ex(p->opr.op[0]) <= ex(p->opr.op[1]);
                case '=': return ex(p->opr.op[0]) == ex(p->opr.op[1]);
                case NE: return ex(p->opr.op[0]) != ex(p->opr.op[1]);
                case AND: return (int)ex(p->opr.op[0]) && (int)ex(p->opr.op[1]);
                case OR: return (int)ex(p->opr.op[0]) || (int)ex(p->opr.op[1]);
                case NOT: return !(int)ex(p->opr.op[0]);
            }
    }
    return 0;
}

int main(int argc, char **argv) {
    #if YYDEBUG
        yydebug = 1;
    #endif

    seed = time(NULL);

    /* Initialize variable table */
    for (int i = 0; i < SYMSIZE; i++) strcpy(vars[i], "-1");

    if (argc < 2)
        yyparse();
    else {
        freopen(argv[1], "r", stdin);
        yyparse();
    }

    return 0;
}