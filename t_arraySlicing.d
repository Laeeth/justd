void main()
{
    const x = [1, 2, 3, 4];

    // const x4 = x[0 .. -$*3];
    // const x4 = x[-1 .. 1];
    // const x4 = x[-1 .. $*3];
    // const x4 = x[0 .. 3*$];
    // const x5 = x[0 ..- $*3];
    // const x4 = x[$ .. $*3];
    // const x1 = x[1 + $ .. $ + 1];
    // const x3 = x[$ - 1 .. $];

    static assert(!__traits(compiles, { const E = x[0 .. -$*3]; }));
    static assert(!__traits(compiles, { const E = x[0 .. -3*$]; }));
    static assert(!__traits(compiles, { const E = x[0 .. $*-3]; }));

    static assert(!__traits(compiles, { const E = x[-1 .. 0]; }));
    static assert(!__traits(compiles, { const E = x[0 .. -$]; }));
    static assert(!__traits(compiles, { const E = x[-1 .. $]; }));
    static assert(!__traits(compiles, { const E = x[$     .. $*3]; }));
    static assert(!__traits(compiles, { const E = x[$     .. 3*$]; }));
    static assert(!__traits(compiles, { const E = x[$     .. 1 + $]; }));
    static assert(!__traits(compiles, { const E = x[$     .. $ + 1]; }));
    static assert(!__traits(compiles, { const E = x[0     .. $ + 1]; }));
    static assert(!__traits(compiles, { const E = x[$ + 1 .. $ + 1]; }));
    static assert(!__traits(compiles, { const E = x[$*3/2 .. $/2]; }));

    const r = x[2*$/3 .. 3*$/4];
    const q = x[$*2/3 .. $*3/4];

    const f = x[0 + 0 .. $/2]; // first half
    const s = x[$/2 .. $]; // second half
    const w = x[0 .. $]; // whole
    const b = x[0 .. 0]; // beginning
    const e = x[$ .. $]; // end

    const y = x[1 - 1 .. $/2]; // first half

    const t = x[$/3 .. $/2];
    const u = x[$/(4 - 1) .. $/2];
}
