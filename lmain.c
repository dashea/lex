#include <stdlib.h>

#ifdef DEBUG
#include <signal.h>
#endif

#include "ldefs.h"
#include "header.h"
#include "sub1.h"
#include "sub2.h"

	/* lex [-[drcyvntf]] [file] ... [file] */

	/* Copyright 1976, Bell Telephone Laboratories, Inc.,
	    written by Eric Schmidt, August 27, 1976   */

static void get1core(void);
static void free1core(void);
static void get2core(void);
static void free2core(void);
static void get3core(void);

#ifdef DEBUG
static void free3core(void);
#endif

#ifdef DEBUG
static void buserr(int signal);
static void segviol(int signal);
#endif

int main(int argc,char **argv)
  {
	register int i;
# ifdef DEBUG
	signal(SIGBUS,buserr);
	signal(SIGSEGV,segviol);
# endif
	while (argc > 1 && argv[1][0] == '-' ){
		i = 0;
		while(argv[1][++i]){
			switch (argv[1][i]){
# ifdef DEBUG
				case 'd': debug++; break;
				case 'y': yydebug = TRUE; break;
# endif
				case 'r': case 'R':
					ratfor=TRUE; break;
				case 'c': case 'C':
					ratfor=FALSE; break;
				case 't': case 'T':
					fout = stdout;
					errorf = stderr;
					break;
				case 'v': case 'V':
					report = 1;
					break;
				case 'f': case 'F':
					optim = FALSE;
					break;
				case 'n': case 'N':
					report = 0;
					break;
				default:
					warning("Unknown option %c",argv[1][i]);
				}
			}
		argc--;
		argv++;
		}
	sargc = argc;
	sargv = argv;
	if (argc > 1){
		fin = fopen(argv[++fptr], "r");		/* open argv[1] */
		sargc--;
		sargv++;
		}
	else fin = stdin;
	if(fin == NULL)
		error ("Can't read input file %s",argc>1?argv[1]:"standard input");
	gch();
		/* may be gotten: def, subs, sname, schar, ccl, dchar */
	get1core();
		/* may be gotten: name, left, right, nullstr, parent */
	scopy("INITIAL",sp);
	sname[0] = sp;
	sp += slength("INITIAL") + 1;
	sname[1] = 0;
	if(yyparse()) exit(1);	/* error return code */
		/* may be disposed of: def, subs, dchar */
	free1core();
		/* may be gotten: tmpstat, foll, positions, gotof, nexts, nchar, state, atable, sfall, cpackflg */
	get2core();
	ptail();
	mkmatch();
# ifdef DEBUG
	if(debug) pccl();
# endif
	sect  = ENDSECTION;
	if(tptr>0)cfoll(tptr-1);
# ifdef DEBUG
	if(debug)pfoll();
# endif
	cgoto();
# ifdef DEBUG
	if(debug){
		printf("Print %d states:\n",stnum+1);
		for(i=0;i<=stnum;i++)stprt(i);
		}
# endif
		/* may be disposed of: positions, tmpstat, foll, state, name, left, right, parent, ccl, schar, sname */
		/* may be gotten: verify, advance, stoff */
	free2core();
	get3core();
	layout();
		/* may be disposed of: verify, advance, stoff, nexts, nchar,
			gotof, atable, ccpackflg, sfall */
# ifdef DEBUG
	free3core();
# endif
	if (ZCH>NCH) cname="/usr/lib/lex/ebcform";
	fother = fopen(ratfor?ratname:cname,"r");
	if(fother == NULL)
		error("Lex driver missing, file %s",ratfor?ratname:cname);
	while ( (i=getc(fother)) != EOF)
		putc(i,fout);

	fclose(fother);
	fclose(fout);
	if(
# ifdef DEBUG
		debug   ||
# endif
			report == 1)statistics();
	fclose(stdout);
	fclose(stderr);
	exit(0);	/* success return code */
	}
static void get1core(void){
ccptr =	ccl = calloc(CCLSIZE,sizeof(*ccl));
pcptr = pchar = calloc(pchlen, sizeof(*pchar));
	def = calloc(DEFSIZE,sizeof(*def));
	subs = calloc(DEFSIZE,sizeof(*subs));
dp =	dchar = calloc(DEFCHAR,sizeof(*dchar));
	sname = calloc(STARTSIZE,sizeof(*sname));
sp = 	schar = calloc(STARTCHAR,sizeof(*schar));
	if(ccl == NULL || pchar == NULL || def == NULL || subs == NULL || dchar == NULL || sname == NULL || schar == NULL)
		error("Too little core to begin");
	}
static void free1core(void){
	free(def);
	free(subs);
	free(dchar);
	}
static void get2core(void){
	register int i;
	gotof = calloc(nstates,sizeof(*gotof));
	nexts = calloc(ntrans,sizeof(*nexts));
	nchar = calloc(ntrans,sizeof(*nchar));
	state = calloc(nstates,sizeof(*state));
	atable = calloc(nstates,sizeof(*atable));
	sfall = calloc(nstates,sizeof(*sfall));
	cpackflg = calloc(nstates,sizeof(*cpackflg));
	tmpstat = calloc(tptr+1,sizeof(*tmpstat));
	foll = calloc(tptr+1,sizeof(*foll));
nxtpos = positions = calloc(maxpos,sizeof(*positions));
	if(tmpstat == NULL || foll == NULL || positions == NULL ||
		gotof == NULL || nexts == NULL || nchar == NULL || state == NULL || atable == NULL || sfall == NULL || cpackflg == NULL )
		error("Too little core for state generation");
	for(i=0;i<=tptr;i++)foll[i] = 0;
	}
static void free2core(void){
	free(positions);
	free(tmpstat);
	free(foll);
	free(name);
	free(left);
	free(right);
	free(parent);
	free(nullstr);
	free(state);
	free(sname);
	free(schar);
	free(ccl);
	}
static void get3core(void){
	verify = calloc(outsize,sizeof(*verify));
	advance = calloc(outsize,sizeof(*advance));
	stoff = calloc(stnum+2,sizeof(*stoff));
	if(verify == NULL || advance == NULL || stoff == NULL)
		error("Too little core for final packing");
	}
# ifdef DEBUG
static void free3core(void){
	free(advance);
	free(verify);
	free(stoff);
	free(gotof);
	free(nexts);
	free(nchar);
	free(atable);
	free(sfall);
	free(cpackflg);
	}
# endif
# ifdef DEBUG
static void buserr(int signal){
	fflush(errorf);
	fflush(fout);
	fflush(stdout);
	fprintf(errorf,"Bus error\n");
	if(report == 1)statistics();
	fflush(errorf);
	}
static void segviol(int signal){
	fflush(errorf);
	fflush(fout);
	fflush(stdout);
	fprintf(errorf,"Segmentation violation\n");
	if(report == 1)statistics();
	fflush(errorf);
	}
# endif

void yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
}
