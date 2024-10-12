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
	$(CC) $(LDFLAGS) lmain.o y.tab.o sub1.o sub2.o header.o once.o -o lex

smallex:
	$(CC) -DSMALL $(CFLAGS) $(LDFLAGS) lmain.c y.tab.c sub1.c sub2.c header.c once.c -o smallex

y.tab.c: parser.y header.h sub1.h
	yacc parser.y

lmain.o: lmain.c header.h ldefs.h sub1.h sub2.h
sub1.o: sub1.c ldefs.h header.h sub1.h
sub2.o: sub2.c ldefs.h sub1.h sub2.h
header.o: header.c ldefs.h header.h
once.o: once.c ldefs.h

libln.a: lib/allprint.o lib/main.o lib/reject.o lib/yyless.o lib/yywrap.o
	rm -f libln.a
	( cd lib && ar rvc ../libln.a allprint.o main.o reject.o yyless.o yywrap.o )
