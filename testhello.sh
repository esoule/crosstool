#!/bin/sh
set -ex

cd $PREFIX
mkdir tmp
cd tmp

# Test the C compiler

cat > hello.c <<_eof_
#include <stdio.h>
int main() { printf("Hello, world!\n"); return 0; }
_eof_

$PREFIX/bin/$TARGET-gcc -static hello.c -o $TARGET-hello-static
$PREFIX/bin/$TARGET-gcc hello.c -o $TARGET-hello

# Test the C++ compiler.
# Link statically, to maximize chances the program will run on any random target.

cat > hello2.cc <<_eof_
#include <iostream>
int main() { std::cout << "Hello, c++!\n"; return 0; }
_eof_

$PREFIX/bin/$TARGET-g++ -static hello2.cc -o $TARGET-hello2-static
$PREFIX/bin/$TARGET-g++ hello2.cc -o $TARGET-hello2

