#!/usr/bin/rdmd

import arsd.dom;
import std.net.curl;
import std.stdio, std.algorithm;

pragma(lib, "curl");

void main() {
    auto document = new Document(cast(string)
                                 get("http://www.stroustrup.com/C++.html"));
    writeln(document.querySelectorAll("a[href]").map!(a=>a.href));
}
