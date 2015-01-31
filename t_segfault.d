static immutable words = [ `zero`, `one`, `two` ];

static immutable ubyte[string] wordsAA;

static this()
{
    foreach (ubyte i, e; words) { wordsAA[e] = i; }
}
