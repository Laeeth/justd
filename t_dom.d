#!/usr/bin/rdmd

import arsd.dom;
import std.net.curl;
import std.stdio;

pragma(lib, "curl");

void main()
{
    auto document = new Document(cast(string)get("http://www.google.com"));
    foreach (a; document.querySelectorAll("a[href]"))
        writeln(a.href);
}
