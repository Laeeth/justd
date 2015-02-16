import all;

class C
{
    float x, y;
}

struct A
{
    int i;
    C c;
}

void main(string[] args)
{
    const A a;
    static assert(__traits(compiles, { auto b = a; }));
    static assert(!__traits(compiles, { A b = a; }));
}
