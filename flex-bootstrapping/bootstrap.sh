#!/bin/sh -e

FLEX_VERSION="2.6.4"

# checkout the repos
git clone -b v"$FLEX_VERSION" https://github.com/westes/flex.git
git clone https://github.com/dashea/lex.git

# build lex
cd lex
make CFLAGS="-DSTARTCHAR=8192 -DNACTIONS=8192"

cd ../flex/src

# Create the scanner
../../lex/lex ../../lex/flex-bootstrapping/bootstrap-scan.l
# flex overrides the lexer function with YY_DECL, which lex is unable to use
# Just change it after the fact
sed 's/yylex/flexscan/g' lex.yy.c > scan.c
rm lex.yy.c

# Create the parser
# `yacc` is assumed to be byacc and not a link to bison
yacc -d parse.y
mv y.tab.c parse.c
mv y.tab.h parse.h

# Create skel.c
# Requires m4
./mkskel.sh . m4 "$FLEX_VERSION" > skel.c

# Create a config.h
# Most of what's created by autoconf is unnecessary for has a reasonable fallback
{ echo '#define M4 "m4"'
  echo "#define VERSION \"$FLEX_VERSION\""
  echo '#define HAVE_LIMITS_H 1'
  echo '#define HAVE_NETINET_IN_H 1'

  # Bison exposes YYSTYPE and includes a `extern YYSTYPE yylval` declaration in the generated header
  # byacc does not
  echo 'extern int yylval;'
} > config.h

gcc -DHAVE_CONFIG_H -o flex -I. \
    buf.c \
    ccl.c \
    dfa.c \
    ecs.c \
    filter.c \
    gen.c \
    main.c \
    misc.c \
    nfa.c \
    options.c \
    parse.c \
    regex.c \
    scanflags.c \
    scanopt.c \
    skel.c \
    sym.c \
    tables.c \
    tables_shared.c \
    tblcmp.c \
    yylex.c \
    scan.c \
    ../../lex/libln.a \
    -lm
