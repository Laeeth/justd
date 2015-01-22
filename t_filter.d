#!/usr/bin/env rdmd-unittest

import all;

void main(string[] args)
{
     auto s = "abcacaacba";
     s.filter!(c => c.among!('a', 'b')).writeln;

     auto t = "hello how\nare you";
     t.until!(c => c.among!('\n', '\r')).writeln;
}
