%{
    #include <stdlib.h>
    #include <string.h>
    #include "tht.h"
    #include "y.tab.h"

    void yyerror(char *s);
    int lineno = 0;
%}

ID      [a-zA-Z][a-z0-9A-Z_]*
EXPO    [Ee][-+]?[0-9]+

%%
"#".*   /* Single-line comment */

[0-9]+|[0-9]+"."[0-9]*{EXPO}?|"."?[0-9]+{EXPO}? {
    printf("Number - %s\n",yytext);
    yylval.dValue = atof(yytext);
    return NUMBER;
}

\"[^"\n]*["\n] {
    yylval.sValue = strdup(yytext+1);
    if (yylval.sValue[yyleng-2] != '"')
        yyerror("Improperly Terminated String");
    else {
        yylval.sValue[yyleng-2] = 0;
        return STRING;
    }
}

";" {

    printf("Delimeter ;\n");
    return *yytext;
}

[-()<>=+*/%^,;:{}] {
    return *yytext;
}

">="    {printf("Operator - %s\n",yytext); return GE; }
"<="    {printf("Operator - %s\n",yytext); return LE; }
"!="    {printf("Operator - %s\n",yytext); return NE; }
"and"   {printf("Operator - %s\n",yytext); return AND; }
"or"    {printf("Operator - %s\n",yytext); return OR; }
"not"   {printf("Operator - %s\n",yytext); return NOT; }

"print" {printf("Keyword - %s\n",yytext); return PRINT;}
"exit"  {printf("Keyword - %s\n",yytext); return EXIT;}

{ID} {
    printf("ID - %s\n");
    yylval.vName = strdup(yytext);
    return EXIT;
}

[ \t]

\n { ++lineno; }

. {
    printf("Unknown character!\n");
    // yyerror("Unknown character\n");
    // exit(1);
}
%%

int yywrap(void) {
    return 1;
}

void yyerror(char *s) {
    fprintf(stdout, "line %d: %s\n", lineno, s);
}