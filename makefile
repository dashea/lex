CFLAGS = -O
all: lex libln.a

cmp:	all
	cmp lex /bin/lex
	ls -l libln.a /lib/libln.a
	rm -f *.o libln.a lex y.tab.c

cp:	all
	cp lex /bin/lex
	cp libln.a /lib
	rm -f *.o libln.a lex y.tab.c

lex: lmain.o y.tab.o sub1.o sub2.o header.o once.o
	cc lmain.o y.tab.o sub1.o sub2.o header.o once.o -o lex

smallex:
	cc -DSMALL -O lmain.c y.tab.c sub1.c sub2.c header.c once.c -o smallex

y.tab.c: parser.y header.h sub1.h
	yacc parser.y

lmain.o:lmain.c header.h ldefs.h sub1.h sub2.h
	cc -c -O lmain.c

sub1.o: sub1.c ldefs.h header.h sub1.h
	cc -c -O sub1.c

sub2.o: sub2.c ldefs.h sub1.h sub2.h
	cc -c -O sub2.c

header.o: header.c ldefs.h header.h
	cc -c -O header.c

once.o: once.c ldefs.h
	cc -c -O once.c

libln.a:
	cc -c -O lib/allprint.c lib/main.c lib/reject.c lib/yyless.c
	cc -c -O lib/yywrap.c
	rm -f libln.a
	ar rvc libln.a allprint.o main.o reject.o yyless.o yywrap.o
	rm allprint.o main.o reject.o yyless.o yywrap.o
