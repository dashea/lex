#include "ldefs.h"
#include "header.h"

static void chd1(void);
static void rhd1(void);
static void chd2(void);
static void ctail(void);
static void rtail(void);

void phead1(void){
	ratfor ? rhd1() : chd1();
	}

static void chd1(void){
	fprintf(fout,"# include \"stdio.h\"\n");
        fprintf(fout,"# include <stdlib.h>\n");
	if (ZCH>NCH)
	fprintf(fout, "# define U(x) ((x)&0377)\n");
	else
	fprintf(fout, "# define U(x) x\n");
	fprintf(fout, "# define NLSTATE yyprevious=YYNEWLINE\n");
	fprintf(fout,"# define BEGIN yybgin = yysvec + 1 +\n");
	fprintf(fout,"# define INITIAL 0\n");
	fprintf(fout,"# define YYLERR yysvec\n");
	fprintf(fout,"# define YYSTATE (yyestate-yysvec-1)\n");
	if(optim)
		fprintf(fout,"# define YYOPTIM 1\n");
# ifdef DEBUG
	fprintf(fout,"# define LEXDEBUG 1\n");
# endif
	fprintf(fout,"# define YYLMAX 200\n");
	fprintf(fout,"# define output(c) putc(c,yyout)\n");
	fprintf(fout, "%s%d%s\n",
  "# define input() (((yytchar=yysptr>yysbuf?U(*--yysptr):getc(yyin))==",
	ctable['\n'],
 "?(yylineno++,yytchar):yytchar)==EOF?0:yytchar)");
	fprintf(fout,
"# define unput(c) {yytchar= (c);if(yytchar=='\\n')yylineno--;*yysptr++=yytchar;}\n");
	fprintf(fout,"# define yymore() (yymorfg=1)\n");
	fprintf(fout,"# define ECHO fprintf(yyout, \"%%s\",yytext)\n");
	fprintf(fout,"# define REJECT { nstr = yyreject(); goto yyfussy;}\n");
	fprintf(fout,"int yyleng; extern char yytext[];\n");
	fprintf(fout,"int yymorfg;\n");
	fprintf(fout,"extern char *yysptr, yysbuf[];\n");
	fprintf(fout,"int yytchar;\n");
	fprintf(fout,"FILE *yyin =NULL, *yyout =NULL;\n");
	fprintf(fout,"extern int yylineno;\n");
	fprintf(fout,"struct yysvf { \n");
	fprintf(fout,"\tstruct yywork *yystoff;\n");
	fprintf(fout,"\tstruct yysvf *yyother;\n");
	fprintf(fout,"\tint *yystops;};\n");
	fprintf(fout,"struct yysvf *yyestate;\n");
	fprintf(fout,"extern struct yysvf yysvec[], *yybgin;\n");
        fprintf(fout,"int yylex(void);\n");
        fprintf(fout,"int yylook(void);\n");
        fprintf(fout,"int yywrap(void);\n");
        fprintf(fout,"int yyback(int *,int);\n");
        fprintf(fout,"int yyinput(void);\n");
        fprintf(fout,"void yyoutput(int);\n");
        fprintf(fout,"void yyunput(int);\n");
        fprintf(fout,"int yyless(int);\n");
	}

static void rhd1(void){
	fprintf(fout,"integer function yylex(dummy)\n");
	fprintf(fout,"define YYLMAX 200\n");
	fprintf(fout,"define ECHO call yyecho(yytext,yyleng)\n");
	fprintf(fout,"define REJECT nstr = yyrjct(yytext,yyleng);goto 30998\n");
	fprintf(fout,"integer nstr,yylook,yywrap\n");
	fprintf(fout,"integer yyleng, yytext(YYLMAX)\n");
	fprintf(fout,"common /yyxel/ yyleng, yytext\n");
	fprintf(fout,"common /yyldat/ yyfnd, yymorf, yyprev, yybgin, yylsp, yylsta\n");
	fprintf(fout,"integer yyfnd, yymorf, yyprev, yybgin, yylsp, yylsta(YYLMAX)\n");
	fprintf(fout,"for(;;){\n");
	fprintf(fout,"\t30999 nstr = yylook(dummy)\n");
	fprintf(fout,"\tgoto 30998\n");
	fprintf(fout,"\t30000 k = yywrap(dummy)\n");
	fprintf(fout,"\tif(k .ne. 0){\n");
	fprintf(fout,"\tyylex=0; return; }\n");
	fprintf(fout,"\t\telse goto 30998\n");
	}

void phead2(void){
	if(!ratfor)chd2();
	}

static void chd2(void){
	fprintf(fout,"while((nstr = yylook()) >= 0)\n");
	fprintf(fout,"yyfussy: switch(nstr){\n");
	fprintf(fout,"case 0:\n");
	fprintf(fout,"if(yywrap()) return(0); break;\n");
	}

void ptail(void){
	if(!pflag)
		ratfor ? rtail() : ctail();
	pflag = 1;
	}

static void ctail(void){
	fprintf(fout,"case -1:\nbreak;\n");		/* for reject */
	fprintf(fout,"default:\n");
	fprintf(fout,"fprintf(yyout,\"bad switch yylook %%d\",nstr);\n");
	fprintf(fout,"} return(0); }\n");
	fprintf(fout,"/* end of yylex */\n");
	}

static void rtail(void){
	register int i;
	fprintf(fout,"\n30998 if(nstr .lt. 0 .or. nstr .gt. %d)goto 30999\n",casecount);
	fprintf(fout,"nstr = nstr + 1\n");
	fprintf(fout,"goto(\n");
	for(i=0; i<casecount; i++)
		fprintf(fout,"%d,\n",30000+i);
	fprintf(fout,"30999),nstr\n");
	fprintf(fout,"30997 continue\n");
	fprintf(fout,"}\nend\n");
	}
void statistics(void){
	fprintf(errorf,"%d/%d nodes(%%e), %td/%d positions(%%p), %d/%d (%%n), %ld transitions\n",
		tptr, treesize, nxtpos-positions, maxpos, stnum+1, nstates, rcount);
	fprintf(errorf, ", %td/%d packed char classes(%%k)", pcptr-pchar, pchlen);
	if(optim)fprintf(errorf,", %d/%d packed transitions(%%a)",nptr, ntrans);
	fprintf(errorf, ", %d/%d output slots(%%o)", yytop, outsize);
	putc('\n',errorf);
	}
