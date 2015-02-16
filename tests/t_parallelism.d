import std.algorithm, std.parallelism, std.range, std.datetime, std.stdio;

void test1 () {
    immutable n = 100_000_000;
    immutable delta = 1.0 / n;

    auto piTerm(int i) {
        immutable x = (i - 0.5) * delta;
        return delta / (1.0 + x*x);
    }

    auto terms = n.iota.map!piTerm; // numbers
    StopWatch sw;

    sw.reset();
    sw.start();
    immutable pi = 4.0*taskPool.reduce!"a+b"(terms);
    sw.stop();
    immutable ms = sw.peek().msecs;
    writeln(pi, " took ", ms, "[ms]");

    sw.reset();
    sw.start();
    immutable pi_ = 4.0*std.algorithm.reduce!"a+b"(terms);
    sw.stop();
    immutable ms_ = sw.peek().msecs;
    writeln(pi_, " took ", ms_, "[ms]");

    writeln("Speedup ", cast(real)ms_ / ms);
}

auto square(T)(T i) @safe pure nothrow { return i*i; }

void test2 () {
    immutable n = 100_000_000;
    immutable delta = 1.0 / n;

    auto terms = n.iota.map!square; // numbers
    StopWatch sw;

    sw.reset();
    sw.start();
    immutable pi = 4.0*taskPool.reduce!"a+b"(terms);
    sw.stop();
    immutable ms = sw.peek().msecs;
    writeln(pi, " took ", ms, "[ms]");

    sw.reset();
    sw.start();
    immutable pi_ = 4.0*std.algorithm.reduce!"a+b"(terms);
    sw.stop();
    immutable ms_ = sw.peek().msecs;
    writeln(pi_, " took ", ms_, "[ms]");

    writeln("Speedup ", cast(real)ms_ / ms);
}

void main () {
    test1();
    test2();
}
