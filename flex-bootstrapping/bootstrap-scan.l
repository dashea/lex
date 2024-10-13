/* scan.l - scanner for flex input -*-C-*- */

%{
/*  Copyright (c) 1990 The Regents of the University of California. */
/*  All rights reserved. */

/*  This code is derived from software contributed to Berkeley by */
/*  Vern Paxson. */

/*  The United States Government has rights in this work pursuant */
/*  to contract no. DE-AC03-76SF00098 between the United States */
/*  Department of Energy and the University of California. */

/*  This file is part of flex. */

/*  Redistribution and use in source and binary forms, with or without */
/*  modification, are permitted provided that the following conditions */
/*  are met: */

/*  1. Redistributions of source code must retain the above copyright */
/*     notice, this list of conditions and the following disclaimer. */
/*  2. Redistributions in binary form must reproduce the above copyright */
/*     notice, this list of conditions and the following disclaimer in the */
/*     documentation and/or other materials provided with the distribution. */

/*  Neither the name of the University nor the names of its contributors */
/*  may be used to endorse or promote products derived from this software */
/*  without specific prior written permission. */

/*  THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR */
/*  IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED */
/*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR */
/*  PURPOSE. */

#include "flexdef.h"
#include "parse.h"
extern bool tablesverify, tablesext;
extern int trlcontxt; /* Set in  parse.y for each rule. */
extern const char *escaped_qstart, *escaped_qend;

#define M4QSTART "[""["
#define M4QEND "]""]"

#define ESCAPED_QSTART "[" M4QEND M4QSTART "[" M4QEND M4QSTART
#define ESCAPED_QEND M4QEND "]" M4QSTART M4QEND "]" M4QSTART

#define ACTION_ECHO add_action( yytext )
#define ACTION_IFDEF(def, should_define) \
	{ \
	if ( should_define ) \
		action_define( def, 1 ); \
	}

#define ACTION_ECHO_QSTART add_action (ESCAPED_QSTART)
#define ACTION_ECHO_QEND   add_action (ESCAPED_QEND)

#define ACTION_M4_IFDEF(def, should_define) \
    do{ \
        if ( should_define ) \
            buf_m4_define( &m4defs_buf, def, NULL);\
        else \
            buf_m4_undefine( &m4defs_buf, def);\
    } while(0)

#define MARK_END_OF_PROLOG mark_prolog();

#define YY_DECL \
	int flexscan(void)

#define RETURNCHAR \
	yylval = (unsigned char) yytext[0]; \
	return CHAR;

#define RETURNNAME \
	if(yyleng < MAXLINE) \
         { \
	strncpy( nmstr, yytext, sizeof(nmstr) ); \
	return NAME; \
	 } \
	else \
	 do { \
	   synerr(_("Input line too long\n")); \
	   FLEX_EXIT(EXIT_FAILURE);  \
	 } while (0)

#define PUT_BACK_STRING(str, start) \
	{ size_t i = strlen( str );	\
	  while ( i > start )		\
	    unput((str)[--i]);		\
	}

#define CHECK_REJECT(str) \
	if ( all_upper( str ) ) \
		reject = true;

#define CHECK_YYMORE(str) \
	if ( all_lower( str ) ) \
		yymore_used = true;

#define YY_USER_INIT \
	if ( getenv("POSIXLY_CORRECT") ) \
		posix_compat = true;

#define START_CODEBLOCK(x,state) do { \
    /* Emit the needed line directive... */\
    if (indented_code == false) { \
        linenum++; \
        line_directive_out(NULL, 1); \
    } \
    add_action(M4QSTART); \
    BEGIN((state)); \
    if ((indented_code = x)) ACTION_ECHO; \
} while(0)

#define END_CODEBLOCK(state) do { \
    BEGIN((state)); \
    add_action(M4QEND); \
    if (!indented_code) line_directive_out(NULL, 0);\
} while (0)

static int bracelevel, didadef, indented_code;
static int doing_rule_action = false;
static int option_sense;

int doing_codeblock = false;
int brace_depth=0, brace_start_line=0;
char nmdef[MAXLINE];

%}

%s SECT2 SECT2PROLOG SECT2FIRSTCHAR SECT3 CODEBLOCK_INITIAL CODEBLOCK_SECT2PROLOG PICKUPDEF SC CARETISBOL NUM QUOTE
%s FIRSTCCL CCL ACTION RECOVER COMMENT ACTION_STRING
%s OPTION CODEBLOCK_MATCH_BRACE
%s GROUP_WITH_PARAMS
%s GROUP_MINUS_PARAMS
%s EXTENDED_COMMENT
%s COMMENT_DISCARD CODE_COMMENT
%s SECT3_NOESCAPE
%s CHARACTER_CONSTANT

%a 8192
%e 8192
%k 8192
%n 8192
%o 8192
%p 8192

WS		[ \t]+
OPTWS		[ \t]*
NOT_WS		[^ \t\r\n]

NL		\r?\n

NAME		([A-Za-z_][A-Za-z0-9_-]*)
NOT_NAME	[^A-Za-z_*\n]+

SCNAME		{NAME}

ESCSEQ		(\\([^\n]|[0-7]{1,3}|x[A-Fa-f0-9]{1,2}))

FIRST_CCL_CHAR	([^\\\n]|{ESCSEQ})
CCL_CHAR	([^\\\n\]]|{ESCSEQ})
CCL_EXPR	("[:"^?[A-Za-z]+":]")

LEXOPT		[aceknopr]

M4QSTART    "[""["
M4QEND      "]""]"

%%


<INITIAL>^{WS}		START_CODEBLOCK(true,CODEBLOCK_INITIAL);
<INITIAL>^"/*"		{ add_action("/*[""["); BEGIN( COMMENT ); }
<INITIAL>^"%s"{NAME}?	return SCDECL;
<INITIAL>^"%x"{NAME}?	return XSCDECL;
<INITIAL>^"%{".*{NL}	START_CODEBLOCK(false,CODEBLOCK_INITIAL);
<INITIAL>^"%top"[ \t]*"{"[ \t]*{NL}    {
                brace_start_line = linenum;
                ++linenum;
                buf_linedir( &top_buf, infilename?infilename:"<stdin>", linenum);
                brace_depth = 1;
                BEGIN(CODEBLOCK_MATCH_BRACE);
            }

<INITIAL>^"%top".*   synerr( _("malformed '%top' directive") );

<INITIAL>{WS}		;

<INITIAL>^"%%".*	{
			sectnum = 2;
			bracelevel = 0;
			mark_defs1();
			line_directive_out(NULL, 1);
			BEGIN(SECT2PROLOG);
			return SECTEND;
			}

<INITIAL>^"%pointer".*{NL}		{ yytext_is_array = false; ++linenum; }
<INITIAL>^"%array".*{NL}		{ yytext_is_array = true; ++linenum; }

<INITIAL>^"%option"	{ BEGIN(OPTION); return TOK_OPTION; }

<INITIAL>^"%"{LEXOPT}{OPTWS}[0-9]*{OPTWS}{NL}	++linenum;
<INITIAL>^"%"{LEXOPT}{WS}.*{NL}	++linenum;

<INITIAL>^"%"[^sxaceknopr{}].*	synerr( _( "unrecognized '%' directive" ) );

<INITIAL>^{NAME}	{
			if(yyleng < MAXLINE)
        		 {
			strncpy( nmstr, yytext, sizeof(nmstr) );
			 }
			else
			 {
			   synerr( _("Definition name too long\n"));
			   FLEX_EXIT(EXIT_FAILURE);
			 }

			didadef = false;
			BEGIN(PICKUPDEF);
			}

<INITIAL>{SCNAME}	RETURNNAME;
<INITIAL>^{OPTWS}{NL}	++linenum;
<INITIAL>{OPTWS}{NL}	{ ACTION_ECHO; ++linenum; /* maybe end of comment line */ }


<COMMENT,CODE_COMMENT>[^\[\]\*\n]*  ACTION_ECHO;
<COMMENT,CODE_COMMENT>.           ACTION_ECHO;

<COMMENT,CODE_COMMENT>{NL}	    { ++linenum; ACTION_ECHO; }
<COMMENT>"*/"	    { add_action("*/]""]"); BEGIN(INITIAL); }
<CODE_COMMENT>"*/"        { ACTION_ECHO; BEGIN(ACTION); }

<COMMENT_DISCARD>"*/"		BEGIN(SECT2);
<COMMENT_DISCARD>"*"         ;
<COMMENT_DISCARD>[^*\n]      ;
<COMMENT_DISCARD>{NL}	    ++linenum;

<EXTENDED_COMMENT>")"         BEGIN(SECT2);
<EXTENDED_COMMENT>[^\n\)]+      ;
<EXTENDED_COMMENT>{NL}        ++linenum;

<ACTION,CODEBLOCK_INITIAL,CODEBLOCK_SECT2PROLOG,ACTION_STRING,CHARACTER_CONSTANT,COMMENT,CODE_COMMENT>{M4QSTART}   ACTION_ECHO_QSTART;
<ACTION,CODEBLOCK_INITIAL,CODEBLOCK_SECT2PROLOG,ACTION_STRING,CHARACTER_CONSTANT,COMMENT,CODE_COMMENT>{M4QEND}     ACTION_ECHO_QEND;

<CODEBLOCK_INITIAL>^"%}".*{NL}	{ ++linenum; END_CODEBLOCK(INITIAL); }
<CODEBLOCK_SECT2PROLOG>^"%}".*{NL}	{ ++linenum; END_CODEBLOCK(SECT2PROLOG); }
<CODEBLOCK_INITIAL,CODEBLOCK_SECT2PROLOG>[^\n%\[\]]*  ACTION_ECHO;
<CODEBLOCK_INITIAL,CODEBLOCK_SECT2PROLOG>.		ACTION_ECHO;
<CODEBLOCK_INITIAL>{NL}					{
			++linenum;
			ACTION_ECHO;
			if ( indented_code ) END_CODEBLOCK(INITIAL);
                        }
<CODEBLOCK_SECT2PROLOG>{NL}		{
			++linenum;
			ACTION_ECHO;
			if ( indented_code ) END_CODEBLOCK(SECT2PROLOG);
			}

<CODEBLOCK_MATCH_BRACE>"}"     {
                if( --brace_depth == 0){
                    /* TODO: Matched. */
                    BEGIN(INITIAL);
                }else
                    buf_strnappend(&top_buf, yytext, yyleng);
            }

<CODEBLOCK_MATCH_BRACE>"{"     {
                brace_depth++;
                buf_strnappend(&top_buf, yytext, yyleng);
            }

<CODEBLOCK_MATCH_BRACE>{NL}    {
                ++linenum;
                buf_strnappend(&top_buf, yytext, yyleng);
            }

<CODEBLOCK_MATCH_BRACE>{M4QSTART}  { buf_strnappend(&top_buf, escaped_qstart, (int) strlen(escaped_qstart)); }
<CODEBLOCK_MATCH_BRACE>{M4QEND}    { buf_strnappend(&top_buf, escaped_qend, (int) strlen(escaped_qend)); }
<CODEBLOCK_MATCH_BRACE>([^{}\r\n\[\]]+)|[^{}\r\n]  {
       buf_strnappend(&top_buf, yytext, yyleng);
    }


<PICKUPDEF>{WS}		;

<PICKUPDEF>{NOT_WS}[^\r\n]*	{
 		        if(yyleng < MAXLINE)
 		         {
			strncpy( nmdef, yytext, sizeof(nmdef) );
 		         }
 		        else
 		         {
 		           format_synerr( _("Definition value for {%s} too long\n"), nmstr);
 		           FLEX_EXIT(EXIT_FAILURE);
			 }
			/* Skip trailing whitespace. */
			{
			    size_t i = strlen( nmdef );
			    while (i > 0 && (nmdef[i-1] == ' ' || nmdef[i-1] == '\t'))
			       --i;
			    nmdef[i] = '\0';
			}

			ndinstal( nmstr, nmdef );
			didadef = true;
			}

<PICKUPDEF>{NL}		{
			if ( ! didadef )
				synerr( _( "incomplete name definition" ) );
			BEGIN(INITIAL);
			++linenum;
			}


<OPTION>{NL}		{ ++linenum; BEGIN(INITIAL); }
<OPTION>{WS}		option_sense = true;

<OPTION>"="		return '=';

<OPTION>no		option_sense = ! option_sense;

<OPTION>7bit		csize = option_sense ? 128 : 256;
<OPTION>8bit		csize = option_sense ? 256 : 128;

<OPTION>align		long_align = option_sense;
<OPTION>always-interactive	{
			ACTION_M4_IFDEF( "M4""_YY_ALWAYS_INTERACTIVE", option_sense );
            interactive = option_sense;
			}
<OPTION>array		yytext_is_array = option_sense;
<OPTION>backup		backing_up_report = option_sense;
<OPTION>batch		interactive = ! option_sense;
<OPTION>bison-bridge     bison_bridge_lval = option_sense;
<OPTION>bison-locations  { if((bison_bridge_lloc = option_sense))
                            bison_bridge_lval = true;
                     }
<OPTION>"c++"		C_plus_plus = option_sense;
<OPTION>caseful|case-sensitive		sf_set_case_ins(!option_sense);
<OPTION>caseless|case-insensitive	sf_set_case_ins(option_sense);
<OPTION>debug		ddebug = option_sense;
<OPTION>default		spprdflt = ! option_sense;
<OPTION>ecs		useecs = option_sense;
<OPTION>fast		{
			useecs = usemecs = false;
			use_read = fullspd = true;
			}
<OPTION>full		{
			useecs = usemecs = false;
			use_read = fulltbl = true;
			}
<OPTION>input		ACTION_IFDEF("YY_NO_INPUT", ! option_sense);
<OPTION>interactive	interactive = option_sense;
<OPTION>lex-compat	lex_compat = option_sense;
<OPTION>posix-compat	posix_compat = option_sense;
<OPTION>line		gen_line_dirs = option_sense;
<OPTION>main		{
			ACTION_M4_IFDEF( "M4""_YY_MAIN", option_sense);
            /* Override yywrap */
            if( option_sense == true )
                do_yywrap = false;
			}
<OPTION>meta-ecs	usemecs = option_sense;
<OPTION>never-interactive	{
			ACTION_M4_IFDEF( "M4""_YY_NEVER_INTERACTIVE", option_sense );
            interactive = !option_sense;
			}
<OPTION>perf-report	performance_report += option_sense ? 1 : -1;
<OPTION>pointer		yytext_is_array = ! option_sense;
<OPTION>read		use_read = option_sense;
<OPTION>reentrant   reentrant = option_sense;
<OPTION>reject		reject_really_used = option_sense;
<OPTION>stack		ACTION_M4_IFDEF( "M4""_YY_STACK_USED", option_sense );
<OPTION>stdinit		do_stdinit = option_sense;
<OPTION>stdout		use_stdout = option_sense;
<OPTION>unistd      ACTION_IFDEF("YY_NO_UNISTD_H", ! option_sense);
<OPTION>unput		ACTION_M4_IFDEF("M4""_YY_NO_UNPUT", ! option_sense);
<OPTION>verbose		printstats = option_sense;
<OPTION>warn		nowarn = ! option_sense;
<OPTION>yylineno	{ do_yylineno = option_sense; ACTION_M4_IFDEF("M4""_YY_USE_LINENO", option_sense); }
<OPTION>yymore		yymore_really_used = option_sense;
<OPTION>yywrap      do_yywrap = option_sense;

<OPTION>yy_push_state	ACTION_M4_IFDEF("M4""_YY_NO_PUSH_STATE", ! option_sense);
<OPTION>yy_pop_state	ACTION_M4_IFDEF("M4""_YY_NO_POP_STATE", ! option_sense);
<OPTION>yy_top_state	ACTION_M4_IFDEF("M4""_YY_NO_TOP_STATE", ! option_sense);

<OPTION>yy_scan_buffer	ACTION_M4_IFDEF("M4""_YY_NO_SCAN_BUFFER", ! option_sense);
<OPTION>yy_scan_bytes	ACTION_M4_IFDEF("M4""_YY_NO_SCAN_BYTES", ! option_sense);
<OPTION>yy_scan_string	ACTION_M4_IFDEF("M4""_YY_NO_SCAN_STRING", ! option_sense);

<OPTION>yyalloc         ACTION_M4_IFDEF("M4""_YY_NO_FLEX_ALLOC", ! option_sense);
<OPTION>yyrealloc       ACTION_M4_IFDEF("M4""_YY_NO_FLEX_REALLOC", ! option_sense);
<OPTION>yyfree          ACTION_M4_IFDEF("M4""_YY_NO_FLEX_FREE", ! option_sense);

<OPTION>yyget_debug     ACTION_M4_IFDEF("M4""_YY_NO_GET_DEBUG", ! option_sense);
<OPTION>yyset_debug     ACTION_M4_IFDEF("M4""_YY_NO_SET_DEBUG", ! option_sense);
<OPTION>yyget_extra     ACTION_M4_IFDEF("M4""_YY_NO_GET_EXTRA", ! option_sense);
<OPTION>yyset_extra     ACTION_M4_IFDEF("M4""_YY_NO_SET_EXTRA", ! option_sense);
<OPTION>yyget_leng      ACTION_M4_IFDEF("M4""_YY_NO_GET_LENG", ! option_sense);
<OPTION>yyget_text      ACTION_M4_IFDEF("M4""_YY_NO_GET_TEXT", ! option_sense);
<OPTION>yyget_lineno    ACTION_M4_IFDEF("M4""_YY_NO_GET_LINENO", ! option_sense);
<OPTION>yyset_lineno    ACTION_M4_IFDEF("M4""_YY_NO_SET_LINENO", ! option_sense);
<OPTION>yyget_in        ACTION_M4_IFDEF("M4""_YY_NO_GET_IN", ! option_sense);
<OPTION>yyset_in        ACTION_M4_IFDEF("M4""_YY_NO_SET_IN", ! option_sense);
<OPTION>yyget_out       ACTION_M4_IFDEF("M4""_YY_NO_GET_OUT", ! option_sense);
<OPTION>yyset_out       ACTION_M4_IFDEF("M4""_YY_NO_SET_OUT", ! option_sense);
<OPTION>yyget_lval      ACTION_M4_IFDEF("M4""_YY_NO_GET_LVAL", ! option_sense);
<OPTION>yyset_lval      ACTION_M4_IFDEF("M4""_YY_NO_SET_LVAL", ! option_sense);
<OPTION>yyget_lloc      ACTION_M4_IFDEF("M4""_YY_NO_GET_LLOC", ! option_sense);
<OPTION>yyset_lloc      ACTION_M4_IFDEF("M4""_YY_NO_SET_LLOC", ! option_sense);

<OPTION>extra-type	return TOK_EXTRA_TYPE;
<OPTION>outfile		return TOK_OUTFILE;
<OPTION>prefix		return TOK_PREFIX;
<OPTION>yyclass		return TOK_YYCLASS;
<OPTION>header(-file)?      return TOK_HEADER_FILE;
<OPTION>tables-file         return TOK_TABLES_FILE;
<OPTION>tables-verify   {
                    tablesverify = option_sense;
                    if(!tablesext && option_sense)
                        tablesext = true;
                    }


<OPTION>\"[^"\n]*\"	{
			if(yyleng-1 < MAXLINE)
        		 {
			strncpy( nmstr, yytext + 1, sizeof(nmstr) );
			 }
			else
			 {
			   synerr( _("Option line too long\n"));
			   FLEX_EXIT(EXIT_FAILURE);
			 }
			nmstr[strlen( nmstr ) - 1] = '\0';
			return NAME;
			}

<OPTION>(([a-mo-z]|n[a-np-z])[A-Za-z\-+]*)|.	{
			format_synerr( _( "unrecognized %%option: %s" ),
				yytext );
			BEGIN(RECOVER);
			}

<RECOVER>.*{NL}		{ ++linenum; BEGIN(INITIAL); }


<SECT2PROLOG>^"%{".*	{ ++bracelevel; yyless( 2 );	/* eat only %{ */ }
<SECT2PROLOG>^"%}".*	{ --bracelevel; yyless( 2 );	/* eat only %} */ }

<SECT2PROLOG>^{WS} START_CODEBLOCK(true,CODEBLOCK_SECT2PROLOG);

<SECT2PROLOG>^{NOT_WS}.*	{
        /* non-indented code */
		if ( bracelevel <= 0 ) {
            /* not in %{ ... %} */
            yyless( 0 );	/* put it all back */
            mark_prolog();
            BEGIN(SECT2FIRSTCHAR);
        } else {
            START_CODEBLOCK(true,CODEBLOCK_SECT2PROLOG);
        }
    }

<SECT2PROLOG>.		ACTION_ECHO;
<SECT2PROLOG>{NL}	{ ++linenum; ACTION_ECHO; }

<SECT2>^{OPTWS}{NL}	++linenum;

<SECT2FIRSTCHAR>"<"	    {
                        /* Allow "<" to appear in (?x) patterns. */
                        if (!sf_skip_ws())
                            BEGIN(SC);
                        return '<';
                    }
<SECT2>^{OPTWS}"<"	    {
                        /* Allow "<" to appear in (?x) patterns. */
                        if (!sf_skip_ws())
                            BEGIN(SC);
                        return '<';
                    }
<SECT2FIRSTCHAR>"^"	{ BEGIN(SECT2); return '^'; }
<SECT2>^{OPTWS}"^"	return '^';
<SECT2,SECT2FIRSTCHAR>\"		{ BEGIN(QUOTE); return '"'; }
<SECT2,SECT2FIRSTCHAR>"{"[0-9]	{
                        int end_ch = yytext[yyleng-1];
                        unput(end_ch);
			BEGIN(NUM);
			if ( lex_compat || posix_compat )
				return BEGIN_REPEAT_POSIX;
			else
				return BEGIN_REPEAT_FLEX;
			}
<SECT2,SECT2FIRSTCHAR>"$"([ \t]|{NL})	{
			int end_ch;
                        int crlf = 0;
                        end_ch = yytext[yyleng-1];
                        if ((end_ch == '\n') && (yyleng > 1) && (yytext[yyleng-2] == '\r')) {
                            crlf = 1;
                        }
                        unput(end_ch);
                        if (crlf) {
                            unput('\r');
                        }
			BEGIN(SECT2);
                        return '$';
                    }
<SECT2>{WS}"|".*{NL}	{
                        if (sf_skip_ws()){
                            /* We're in the middle of a (?x: ) pattern. */
                            /* Push back everything starting at the "|" */
                            int amt = (int) (strchr (yytext, '|') - yytext);
                            yyless(amt);
                        }
                        else {
                            add_action("]""]");
                            continued_action = true;
                            ++linenum;
                            return '\n';
                        }
                    }

<SECT2>^{WS}"/*"	{

                if (sf_skip_ws()){
                    /* We're in the middle of a (?x: ) pattern. */
                    BEGIN(COMMENT_DISCARD);
                }
                else{
                    yyless( yyleng - 2 );	/* put back '/', '*' */
                    bracelevel = 0;
                    continued_action = false;
                    BEGIN(ACTION);
                }
			}

<SECT2>^{WS}		;

<SECT2>{WS}		{
            if (sf_skip_ws()){
                /* We're in the middle of a (?x: ) pattern. */
            }
            else{
                /* This rule is separate from the one below because
                 * otherwise we get variable trailing context, so
                 * we can't build the scanner using -{f,F}.
                 */
                bracelevel = 0;
                continued_action = false;
                BEGIN(ACTION);

                if ( in_rule )
                    {
                    doing_rule_action = true;
                    in_rule = false;
                    return '\n';
                    }
            }
			}

<SECT2>{OPTWS}{NL}	{
            if (sf_skip_ws()){
                /* We're in the middle of a (?x: ) pattern. */
                ++linenum;
            }
            else{
                bracelevel = 0;
                continued_action = false;
                BEGIN(ACTION);
                unput( '\n' );	/* so <ACTION> sees it */

                if ( in_rule )
                    {
                    doing_rule_action = true;
                    in_rule = false;
                    return '\n';
                    }
            }
			}

<SECT2FIRSTCHAR>"<<EOF>>" return EOF_OP;
<SECT2>^{OPTWS}"<<EOF>>" return EOF_OP;
<SECT2>"<<EOF>>"	return EOF_OP;

<SECT2FIRSTCHAR>"%%".*		{
			sectnum = 3;
			BEGIN(no_section3_escape ? SECT3_NOESCAPE : SECT3);
			outn("/* Begin user sect3 */");
			return 0; /* to stop the parser */

			}
<SECT2>^"%%".*		{
			sectnum = 3;
			BEGIN(no_section3_escape ? SECT3_NOESCAPE : SECT3);
			outn("/* Begin user sect3 */");
			return 0; /* to stop the parser */

			}

<SECT2,SECT2FIRSTCHAR>"["({FIRST_CCL_CHAR}|{CCL_EXPR})({CCL_CHAR}|{CCL_EXPR})*	{
			int cclval;
                        BEGIN(SECT2);

			if(yyleng < MAXLINE)
        		 {
			strncpy( nmstr, yytext, sizeof(nmstr) );
			 }
			else
			 {
			   synerr( _("Input line too long\n"));
			   FLEX_EXIT(EXIT_FAILURE);
			 }

			/* Check to see if we've already encountered this
			 * ccl.
			 */
			if (0 /* <--- This "0" effectively disables the reuse of a
                   * character class (purely based on its source text).
                   * The reason it was disabled is so yacc/bison can parse
                   * ccl operations, such as ccl difference and union.
                   */
                &&  (cclval = ccllookup( nmstr )) != 0 )
				{
				if ( input() != ']' )
					synerr( _( "bad character class" ) );

				yylval = cclval;
				++cclreuse;
				return PREVCCL;
				}
			else
				{
				/* We fudge a bit.  We know that this ccl will
				 * soon be numbered as lastccl + 1 by cclinit.
				 */
				cclinstal( nmstr, lastccl + 1 );

				/* Push back everything but the leading bracket
				 * so the ccl can be rescanned.
				 */
				yyless( 1 );

				BEGIN(FIRSTCCL);
				return '[';
				}
			}
<SECT2,SECT2FIRSTCHAR>"{-}"       { BEGIN(SECT2); return CCL_OP_DIFF; }
<SECT2,SECT2FIRSTCHAR>"{+}"       { BEGIN(SECT2); return CCL_OP_UNION; }


<SECT2,SECT2FIRSTCHAR>"{"{NAME}"}"[ \f\n\r\t\013]?	 {
			char *nmdefptr;
            int end_is_ws, end_ch;
            BEGIN(SECT2);

            end_ch = yytext[yyleng-1];
            end_is_ws = end_ch != '}' ? 1 : 0;

 			if(yyleng-1 < MAXLINE)
         		 {
			strncpy( nmstr, yytext + 1, sizeof(nmstr) );
 			 }
 			else
 			 {
 			   synerr( _("Input line too long\n"));
 			   FLEX_EXIT(EXIT_FAILURE);
 			 }
nmstr[yyleng - 2 - end_is_ws] = '\0';  /* chop trailing brace */

			if ( (nmdefptr = ndlookup( nmstr )) == 0 )
				format_synerr(
					_( "undefined definition {%s}" ),
						nmstr );

			else
				{ /* push back name surrounded by ()'s */
				size_t len = strlen( nmdefptr );
                if (end_is_ws)
                    unput(end_ch);

				if ( lex_compat || nmdefptr[0] == '^' ||
				     (len > 0 && nmdefptr[len - 1] == '$')
                     || (end_is_ws && trlcontxt && !sf_skip_ws()))
					{ /* don't use ()'s after all */
					PUT_BACK_STRING(nmdefptr, 0);

					if ( nmdefptr[0] == '^' )
						BEGIN(CARETISBOL);
					}

				else
					{
					unput(')');
					PUT_BACK_STRING(nmdefptr, 0);
					unput('(');
					}
				}
			}

<SECT2,SECT2FIRSTCHAR>"/*"        {
                    if (sf_skip_ws())
                        BEGIN(COMMENT_DISCARD);
                    else{
                        /* Push back the "*" and return "/" as usual. */
                        yyless(1);
                        BEGIN(SECT2);
                        return '/';
                    }
                }

<SECT2,SECT2FIRSTCHAR>"(?#"       {
                    if (lex_compat || posix_compat){
                        /* Push back the "?#" and treat it like a normal parens. */
                        yyless(1);
                        sf_push(); 
                        BEGIN(SECT2);
                        return '(';
                    }
                    else
                        BEGIN(EXTENDED_COMMENT);
                }
<SECT2,SECT2FIRSTCHAR>"(?"        {
                    sf_push();
                    if (lex_compat || posix_compat) {
                        /* Push back the "?" and treat it like a normal parens. */
                        yyless(1);
                        BEGIN(SECT2);
                    } else
                        BEGIN(GROUP_WITH_PARAMS);
                    return '(';
                }
<SECT2,SECT2FIRSTCHAR>"("         { BEGIN(SECT2); sf_push(); return '('; }
<SECT2,SECT2FIRSTCHAR>")"         {
                    BEGIN(SECT2);
                    if (_sf_top_ix > 0) {
                        sf_pop();
                        return ')';
                    } else
                        synerr(_("unbalanced parenthesis"));
                }

<SECT2,SECT2FIRSTCHAR>[/|*+?.(){}]	{ BEGIN(SECT2); return (unsigned char) yytext[0]; }
<SECT2,SECT2FIRSTCHAR>.		{ BEGIN(SECT2); RETURNCHAR; }


<SC>{OPTWS}{NL}{OPTWS}	++linenum;
<SC>[,*]		return (unsigned char) yytext[0];
<SC>">"			{ BEGIN(SECT2); return '>'; }
<SC>">"^		{ unput('^'); BEGIN(CARETISBOL); return '>'; }
<SC>{SCNAME}		RETURNNAME;
<SC>.			{
			format_synerr( _( "bad <start condition>: %s" ),
				yytext );
			}

<CARETISBOL>"^"		{ BEGIN(SECT2); return '^'; }


<QUOTE>[^"\n]		RETURNCHAR;
<QUOTE>\"		{ BEGIN(SECT2); return '"'; }

<QUOTE>{NL}		{
			synerr( _( "missing quote" ) );
			BEGIN(SECT2);
			++linenum;
			return '"';
			}

<GROUP_WITH_PARAMS>":"     BEGIN(SECT2);
<GROUP_WITH_PARAMS>"-"     BEGIN(GROUP_MINUS_PARAMS);
<GROUP_WITH_PARAMS>i       sf_set_case_ins(1);
<GROUP_WITH_PARAMS>s       sf_set_dot_all(1);
<GROUP_WITH_PARAMS>x       sf_set_skip_ws(1);
<GROUP_MINUS_PARAMS>":"     BEGIN(SECT2);
<GROUP_MINUS_PARAMS>i       sf_set_case_ins(0);
<GROUP_MINUS_PARAMS>s       sf_set_dot_all(0);
<GROUP_MINUS_PARAMS>x       sf_set_skip_ws(0);

<FIRSTCCL>"^"[^-\]\n]	{ int end_ch = yytext[yyleng-1]; unput(end_ch); BEGIN(CCL); return '^'; }
<FIRSTCCL>"^"("-"|"]")	{ int end_ch = yytext[yyleng-1]; unput(end_ch); return '^'; }
<FIRSTCCL>.		{ BEGIN(CCL); RETURNCHAR; }

<CCL>-[^\]\n]		{ int end_ch = yytext[yyleng-1]; unput(end_ch); return '-'; }
<CCL>[^\]\n]		RETURNCHAR;
<CCL>"]"		{ BEGIN(SECT2); return ']'; }
<CCL>.|{NL}		{
			synerr( _( "bad character class" ) );
			BEGIN(SECT2);
			return ']';
			}

<FIRSTCCL,CCL>"[:alnum:]"	{ BEGIN(CCL); return CCE_ALNUM; }
<FIRSTCCL,CCL>"[:alpha:]"	{ BEGIN(CCL); return CCE_ALPHA; }
<FIRSTCCL,CCL>"[:blank:]"	{ BEGIN(CCL); return CCE_BLANK; }
<FIRSTCCL,CCL>"[:cntrl:]"	{ BEGIN(CCL); return CCE_CNTRL; }
<FIRSTCCL,CCL>"[:digit:]"	{ BEGIN(CCL); return CCE_DIGIT; }
<FIRSTCCL,CCL>"[:graph:]"	{ BEGIN(CCL); return CCE_GRAPH; }
<FIRSTCCL,CCL>"[:lower:]"	{ BEGIN(CCL); return CCE_LOWER; }
<FIRSTCCL,CCL>"[:print:]"	{ BEGIN(CCL); return CCE_PRINT; }
<FIRSTCCL,CCL>"[:punct:]"	{ BEGIN(CCL); return CCE_PUNCT; }
<FIRSTCCL,CCL>"[:space:]"	{ BEGIN(CCL); return CCE_SPACE; }
<FIRSTCCL,CCL>"[:upper:]"	{ BEGIN(CCL); return CCE_UPPER; }
<FIRSTCCL,CCL>"[:xdigit:]"	{ BEGIN(CCL); return CCE_XDIGIT; }

<FIRSTCCL,CCL>"[:^alnum:]"	{ BEGIN(CCL); return CCE_NEG_ALNUM; }
<FIRSTCCL,CCL>"[:^alpha:]"	{ BEGIN(CCL); return CCE_NEG_ALPHA; }
<FIRSTCCL,CCL>"[:^blank:]"	{ BEGIN(CCL); return CCE_NEG_BLANK; }
<FIRSTCCL,CCL>"[:^cntrl:]"	{ BEGIN(CCL); return CCE_NEG_CNTRL; }
<FIRSTCCL,CCL>"[:^digit:]"	{ BEGIN(CCL); return CCE_NEG_DIGIT; }
<FIRSTCCL,CCL>"[:^graph:]"	{ BEGIN(CCL); return CCE_NEG_GRAPH; }
<FIRSTCCL,CCL>"[:^lower:]"	{ BEGIN(CCL); return CCE_NEG_LOWER; }
<FIRSTCCL,CCL>"[:^print:]"	{ BEGIN(CCL); return CCE_NEG_PRINT; }
<FIRSTCCL,CCL>"[:^punct:]"	{ BEGIN(CCL); return CCE_NEG_PUNCT; }
<FIRSTCCL,CCL>"[:^space:]"	{ BEGIN(CCL); return CCE_NEG_SPACE; }
<FIRSTCCL,CCL>"[:^upper:]"	{ BEGIN(CCL); return CCE_NEG_UPPER; }
<FIRSTCCL,CCL>"[:^xdigit:]"	{ BEGIN(CCL); return CCE_NEG_XDIGIT; }
<FIRSTCCL,CCL>{CCL_EXPR}	{
			format_synerr(
				_( "bad character class expression: %s" ),
					yytext );
			BEGIN(CCL); return CCE_ALNUM;
			}

<NUM>[0-9]+		{
			yylval = myctoi( yytext );
			return NUMBER;
			}

<NUM>","		return ',';
<NUM>"}"		{
			BEGIN(SECT2);
			if ( lex_compat || posix_compat )
				return END_REPEAT_POSIX;
			else
				return END_REPEAT_FLEX;
			}

<NUM>.			{
			synerr( _( "bad character inside {}'s" ) );
			BEGIN(SECT2);
			return '}';
			}

<NUM>{NL}		{
			synerr( _( "missing }" ) );
			BEGIN(SECT2);
			++linenum;
			return '}';
			}


<ACTION>"/*"		{ ACTION_ECHO; BEGIN( CODE_COMMENT ); }

<CODEBLOCK_INITIAL,CODEBLOCK_SECT2PROLOG,ACTION>"reject" {
            ACTION_ECHO;
            CHECK_REJECT(yytext);
        }
<CODEBLOCK_INITIAL,CODEBLOCK_SECT2PROLOG,ACTION>"yymore" {
            ACTION_ECHO;
            CHECK_YYMORE(yytext);
        }

<ACTION>"{"		{ ACTION_ECHO; ++bracelevel; }
<ACTION>"}"		{ ACTION_ECHO; --bracelevel; }
<ACTION>[^A-Za-z_{}\"'/\n\[\]]+	ACTION_ECHO;
<ACTION>{NAME}		ACTION_ECHO;
<ACTION>"'"([^\'\\\n]|\\.)"'" ACTION_ECHO;
<ACTION>"'"             { ACTION_ECHO; BEGIN(CHARACTER_CONSTANT); }
<ACTION>\"		{ ACTION_ECHO; BEGIN(ACTION_STRING); }
<ACTION>{NL} {
                ++linenum;
                ACTION_ECHO;
                if (bracelevel <= 0) {
                   if ( doing_rule_action )
                      add_action( "\tYY_BREAK]""]\n" );

                   doing_rule_action = false;
                   BEGIN(SECT2);
                }
             }
<ACTION>.      ACTION_ECHO;

<ACTION_STRING>[^\[\]\"\\\n]+	ACTION_ECHO;
<ACTION_STRING>\"		{ ACTION_ECHO; BEGIN(ACTION); }
<CHARACTER_CONSTANT>[^\[\]\'\\\n]+  ACTION_ECHO;
<CHARACTER_CONSTANT>\'              { ACTION_ECHO; BEGIN(ACTION); }
<ACTION_STRING,CHARACTER_CONSTANT>(\\\n)*         ACTION_ECHO;
<ACTION_STRING,CHARACTER_CONSTANT>\\(\\\n)*.	ACTION_ECHO;
<ACTION_STRING,CHARACTER_CONSTANT>{NL}	{ ++linenum; ACTION_ECHO; if (bracelevel <= 0) { BEGIN(SECT2); } else { BEGIN(ACTION); } }
<ACTION_STRING,CHARACTER_CONSTANT>.	ACTION_ECHO;

<FIRSTCCL>{ESCSEQ}			{
			yylval = myesc( (unsigned char *) yytext );
			BEGIN(CCL);
			return CHAR;
}
<SECT2,QUOTE,CCL>{ESCSEQ}	{
			yylval = myesc( (unsigned char *) yytext );
			return CHAR;
			}

<SECT3>{M4QSTART}   fputs(escaped_qstart, yyout);
<SECT3>{M4QEND}     fputs(escaped_qend, yyout);
<SECT3>[^\[\]]*     ECHO;
<SECT3>[][]         ECHO;
<SECT3_NOESCAPE>{M4QSTART}  fprintf(yyout, "[""[%s]""]", escaped_qstart);
<SECT3_NOESCAPE>{M4QEND}    fprintf(yyout, "[""[%s]""]", escaped_qend);
<SECT3_NOESCAPE>[^][]*      ECHO;
<SECT3_NOESCAPE>[][]        ECHO;
.|\n			format_synerr( _( "bad character: %s" ), yytext );

%%


int yywrap(void)
	{
	if ( --num_input_files > 0 )
		{
		set_input_file( *++input_files );
		return 0;
		}

	else
		return 1;
	}


/* set_input_file - open the given file (if NULL, stdin) for scanning */

void set_input_file( char *file )
	{
	if ( file && strcmp( file, "-" ) )
		{
		infilename = xstrdup(file);
		yyin = fopen( infilename, "r" );

		if ( yyin == NULL )
			lerr( _( "can't open %s" ), file );
		}

	else
		{
		yyin = stdin;
		infilename = xstrdup("<stdin>");
		}

	linenum = 1;
	}
