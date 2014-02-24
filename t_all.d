#!/usr/bin/rdmd

/**
 * \file t_d.d
 * \brief
 */

import std.stdio;
import std.complex;

/** Show Arguments \p f and \p r.
 * Bugs: Support lazy evaluation of f and r so we can do xx.stringof
 */
void show(F, R...)(F f, R r) {
    writeln(__FILE__, ":", __LINE__, ": " , f, ":", r);
}

class C {
    this(int x) { this.x = x; }
private:
    int x = 12;
};

struct S {
    this(int x) { this.x = x; }
private:
    int x = 12;
};

struct T {
    int x = 12;
};

void test_enum_as_index() {
    enum E { x,y,z }
    int[E] a = [ E.x:1, E.y:2, E.z:3 ];
    writeln(a[E.x]);
    writeln(a[E.y]);
    writeln(a[E.z]);
    // this gives range violation
    // writeln(a[cast(E)(E.z+1)]);
}

void use_array(const int[4] x)
{
    writeln(x.stringof, ": ", x);
}

void shown(T)(const lazy T x)
{
    writeln(x.stringof, x());
}

struct Tuple(Args...) { Args args_; }

Tuple!(Args) tuple(Args...) (Args args) {
    return typeof(return)(args);
}

auto f(int x)  {
    writeln(x);
}

void main(string[] args)
{
    string x = "";
    if (x) {
        writeln(x);
    }
    auto c = new C(12);
    auto s = S(12);
    T t = {x:12};

    enum E { x,y,z }
    auto w = E.init+30;
    writeln(w);

    test_enum_as_index();

    immutable x5 = [1, 2, 3, 4, 5];
    use_array(x5[0..4]);               // should work

    auto xx = ["1", "2"];
    show(xx.stringof, xx);

    auto cm = complex(3.0, 4.0);
    writeln(cm);

    // Value Range Propagation
    immutable int int_ = 255 + 1;
    writeln("int_:", int_);
    immutable ubyte_ = cast(ubyte)int_;
    writeln("ubyte_:", ubyte_);

    immutable x_ = 2;
    writeln("power: ", x_^^8);

    writeln([1, ]);

    auto y = tuple(1,3.14,"foo");
    writeln(y);

    immutable int m22[2][2] = [1, 2, 3, 4];
    writeln(m22);

    immutable int m22_[2][2] = [[1, 2], [3, 4]];
    writeln(m22_);

    import std.range;

    writeln(iota(10));

    if (auto x__ = 1) {
        x__++;
    }

    writeln(1 || 2);
    writeln(1 && 2);
}

unittest {

}
