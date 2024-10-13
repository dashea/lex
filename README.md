It's lex, everyone's favorite lexical analyzer generator!

lex was originally written by Mike Lesk and Eric Schmidt for Bell Labs.
This code was taken from Version 7 Unix as archived by [The Unix Heritage Society](http://www.tuhs.org/) and modified to build using a C compiler slightly newer than Version 7 Unix.

## y tho

I fell down a bit of a rabbit hole while investigating how to bootstrap [flex](https://github.com/westes/flex/).
flex has been the popular non-commercial implementation of lex since the 4.4 BSD days, but the scanner for flex is written in flex, creating a chicken and egg problem if you want to start from scratch.
I thought Unix necromancy was a more interesting approach than replacing scan.l with a hand-written lexer.

See [flex-bootstrapping](flex-bootstrapping/README.md) for more on my findings on compiling flex without starting with flex.

## License etc.

In 2002 Caldera issued a BSD-style license for 32/V Unix and 16-bit Unix versions 1 through 7, which also applies to the portions of operating systems that substantially derive from these versions of Unix, with the explicit exclusion of Unix System III and Unix System V.
This code is derived from the source code of Version 7 Unix and is covered by the following copyright notice:

> Copyright(C) Caldera International Inc. 2001-2002. All rights reserved.
> 
> Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
> following conditions are met:
> 
> Redistributions of source code and documentation must retain the above copyright notice, this list of conditions and the
> following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
> and the following disclaimer in the documentation and/or other materials provided with the distribution.
> 
> All advertising materials mentioning features or use of this software must display the following acknowledgement:
> 
> This product includes software developed or owned by Caldera International, Inc.
> 
> Neither the name of Caldera International, Inc. nor the names of other contributors may be used to endorse or promote
> products derived from this software without specific prior written permission.
> 
> USE OF THE SOFTWARE PROVIDED FOR UNDER THIS LICENSE BY CALDERA INTERNATIONAL, INC.
> AND CONTRIBUTORS \`\`AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
> LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
> PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CALDERA INTERNATIONAL, INC. BE LIABLE FOR
> ANY DIRECT, INDIRECT INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
> (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
> USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
> LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
> OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
> POSSIBILITY OF SUCH DAMAGE.

On the other hand, "SCO Group, Inc. v. Novell, Inc." in 2010 decided that Novell is the owner of the Unix copyrights so Caldera's license may be invalid, I don't know, I'm not a lawyer.
Maybe don't use this for anything serious.
