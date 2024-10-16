#ifndef _LDEFS_H_
#define _LDEFS_H_

# include <stdio.h>
#ifndef PP
# define PP 1
#endif

# ifdef unix

# define CWIDTH 7
# define CMASK 0177
# define ASCII 1
# endif

# ifdef gcos
# define CWIDTH 9
# define CMASK 0777
# define ASCII 1
# endif

# ifdef ibm
# define CWIDTH 8
# define CMASK 0377
# define EBCDIC 1
# endif

# ifdef ASCII
# define NCH 128
# endif

# ifdef EBCDIC
# define NCH 256
# endif


/* Used for both the size of pushc (the unpush array) and the maximum size of packed character classes.
 * Packed character class size can be overridden with %k, the size of pushc cannot */
#ifndef TOKENSIZE
# define TOKENSIZE 1000
#endif

/* Size of def and subs arrays, not configurable */
#ifndef DEFSIZE
# define DEFSIZE 40
#endif

/* Size of dchar array, not configurable */
#ifndef DEFCHAR
# define DEFCHAR 1000
#endif

/* Size of schar array, not configurable */
#ifndef STARTCHAR
# define STARTCHAR 100
#endif

/* Size of sname array, not configurable */
#ifndef STARTSIZE
# define STARTSIZE 256
#endif

/* Size of ccl array, not configurable */
#ifndef CCLSIZE
# define CCLSIZE 1000
#endif

/* Locations of the driver files */
#if (unix || ibm)
#ifndef CNAME_PATH
#define CNAME_PATH "/usr/lib/lex/ncform"
#endif

#ifndef RATNAME_PATH
#define RATNAME_PATH "/usr/lib/lex/nrform"
#endif
#endif

#ifdef gcos
#ifndef CNAME_PATH
#define CNAME_PATH "pounce/lexcform"
#endif

#ifndef RATNAME_PATH
#define RATNAME_PATH "pounce/lexrform"
#endif
#endif


/* All of these values are configurable at runtime:
 * TREESIZE %e
 * NTRANS %a
 * NSTATES %n
 * MAXPOS %p
 * NOUTPUT %o
 */
# ifdef SMALL
# define TREESIZE 600
# define NTRANS 1500
# define NSTATES 300
# define MAXPOS 1500
# define NOUTPUT 1500
# endif

# ifndef SMALL
# define TREESIZE 1000
# define NSTATES 500
# define MAXPOS 2500
# define NTRANS 2000
# define NOUTPUT 3000
# endif

/* Size of extra array, not configurable */
#ifndef NACTIONS
# define NACTIONS 100
#endif

# define RCCL NCH+90
# define RNCCL NCH+91
# define RSTR NCH+92
# define RSCON NCH+93
# define RNEWE NCH+94
# define FINAL NCH+95
# define RNULLS NCH+96
# define RCAT NCH+97
# define STAR NCH+98
# define PLUS NCH+99
# define QUEST NCH+100
# define DIV NCH+101
# define BAR NCH+102
# define CARAT NCH+103
# define S1FINAL NCH+104
# define S2FINAL NCH+105

# define DEFSECTION 1
# define RULESECTION 2
# define ENDSECTION 5
# define TRUE 1
# define FALSE 0

# define PC 1
# define PS 1

# ifdef DEBUG
# define LINESIZE 110
extern int yydebug;
extern int debug;		/* 1 = on */
extern int charc;
# endif

# ifndef DEBUG
# define freturn(s) s
# else
int freturn(int);
# endif

extern int sargc;
extern char **sargv;
extern char buf[520];
extern int ratfor;		/* 1 = ratfor, 0 = C */
extern int yyline;		/* line number of file */
extern int sect;
extern int eof;
extern int lgatflg;
extern int divflg;
extern int funcflag;
extern int pflag;
extern int casecount;
extern int chset;	/* 1 = char set modified */
extern FILE *fin, *fout, *fother, *errorf;
extern int fptr;
extern char *ratname, *cname;
extern int prev;	/* previous input character */
extern int pres;	/* present input character */
extern int peek;	/* next input character */
extern int *name;
extern int *left;
extern int *right;
extern int *parent;
extern char **treestrs;
extern char *nullstr;
extern int tptr;
extern char pushc[TOKENSIZE];
extern char *pushptr;
extern char slist[STARTSIZE];
extern char *slptr;
extern char **def, **subs, *dchar;
extern char **sname, *schar;
extern char *ccl;
extern char *ccptr;
extern char *dp, *sp;
extern int dptr, sptr;
extern char *bptr;		/* store input position */
extern char *tmpstat;
extern int count;
extern int **foll;
extern int *nxtpos;
extern int *positions;
extern int *gotof;
extern int *nexts;
extern char *nchar;
extern int **state;
extern int *sfall;		/* fallback state num */
extern char *cpackflg;		/* true if state has been character packed */
extern int *atable, aptr;
extern int nptr;
extern char symbol[NCH];
extern char cindex[NCH];
extern int xstate;
extern int stnum;
extern int ctable[];
extern int ZCH;
extern int ccount;
extern char match[NCH];
extern char extra[NACTIONS];
extern char *pcptr, *pchar;
extern int pchlen;
extern int nstates, maxpos;
extern int yytop;
extern int report;
extern int ntrans, treesize, outsize;
extern long rcount;
extern int optim;
extern int *verify, *advance, *stoff;
extern int scon;
extern char *psave;

extern int yyparse(void);
extern void yyerror(char *s);

extern int lineno;

#endif /* _LDEFS_H_ */
