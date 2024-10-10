#ifndef _SUB1_H_
#define _SUB1_H_

char * getl(char *p);
int space(char ch);
int digit(char c);
void error(const char *s, ...);
void warning(const char *s,...);
int sub1_index(char a,char *s);
int alpha(char c);
int printable(char c);
void lgate(void);
void scopy(char *s,char *t);
int siconv(char *t);
int slength(char *s);
int scomp(char *x,char *y);
int ctrans(char **ss);
void cclinter(int sw);
int usescape(int c);
int lookup(char *s,char **t);
int cpyact(void);
int gch(void);
int mn2(int a,int d,int c);
int mn1(int a,int d);
int mn0(int a);
void munput_str(char *p);
void munput_chr(char t);
int dupl(int n);
void allprint(char c);
void sect1dump(void);
void sect2dump(void);

#endif /* _SUB1_H_ */
