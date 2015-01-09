#!/usr/bin/rdmd

import arsd.dom;
import std.net.curl;
import std.stdio;

void main() {
    auto document = new Document(cast(string)
                                 get("http://www.stroustrup.com/C++.html"));
    foreach(a; document.querySelectorAll("a[href]"))
        writeln(a.href);
}
