#!/usr/bin/rdmd

import arsd.dom;
import std.net.curl;
import std.stdio;

pragma(lib, "curl");

void main()
{
    const url = "http://www.google.com";
    auto document = new Document(get(url).dup);
    foreach (a; document.querySelectorAll("a[href]")) // get all anchors with href
        writeln(a.href);
}
