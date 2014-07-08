#!/usr/bin/env rdmd-dev

import std.stdio;

class File {
    this(string name_) { name = name_; }
    string name;
}

void main(string[] args) {
    auto x = [ new File("1"), new File("2") ];
    writeln(x);

    File[] a = [ new File("1"), new File("2") ];
    a ~= new File("3");
}
