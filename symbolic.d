#!/usr/bin/env rdmd-dev-module

/**
   Symbolic Regular Expressions and Predicate Logic.

   Syntax is similar to Emacs' sregex, rx.

   Copyright: Per Nordlöw 2014-.
   License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
   Authors: $(WEB Per Nordlöw)

   TODO
   Overload operators || (or), && (and), ! (not),

   TODO
   Variables are either
   - _ (ignore)
   - _"x", _"y", etc
   - _'x', _'y'
   - _!0, _!1, ..., _!(n-1)

   infer(rel!"desire"(_!"x", _!"y") &&
         rel!"madeOf"(_!"z", _!"y"),
         rel!"desire"(_!"x", _!"z"))

   TODO Support variables of specific types and inference using predicate logic:
        infer(and(fact(var!'x', rel'desire', var!'y'),
                  fact(var!'z', opt(rel'madeOf',
                              rel'instanceOf'), var!'y'))),
              pred(var!'x', rel'desire', var!'z'
              ))

   TODO Make returns from factory functions immutable.
   TODO Reuse return patterns from Lit
 */
module symbolic;

import std.algorithm: find, all, map, reduce, min, max;
import std.range: empty;
import std.string: representation;
import find_ex: findAcronymAt, FindContext;
import dbg;
import bitset;

/** Base Pattern.
 */
class Patt
{
    @safe pure nothrow:

    /** Match $(D this) with $(D haystack) at Offset $(D soff).
     Returns: Matched slice or [] if not match.
    */
    final auto ref matchU(in ubyte[] haystack, size_t soff = 0) const
    {
        const hit = atU(haystack, soff);
        return hit != hit.max ? haystack[0..hit] : [];
    }
    final auto ref match(in string haystack, size_t soff = 0) const
    {
        return matchU(haystack.representation, soff);
    }

    Seq opBinary(string op)(Patt rhs) if (op == "~") // template can't be overridden
    {
        return opCatImpl(rhs);
    }
    Seq opCatImpl(Patt rhs) // can be overridden
    {
        return seq(this, rhs);
    }

    Alt opBinary(string op)(Patt rhs) if (op == "|") // template can't be overridden
    {
        return opAltImpl(rhs);
    }
    Alt opAltImpl(Patt rhs) // can be overridden
    {
        return alt(this, rhs);
    }

    final size_t at(in string haystack, size_t soff = 0) const
    // TODO Activate this
    /* out (hit) { */
    /*     assert((!hit) || hit >= minLength); // TODO Is this needed? */
    /* } */
    /* body */
    {
        return atU(haystack.representation, soff);
    }
    size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        assert(false);
    }

    /** Find $(D this) in $(D haystack) at Offset $(D soff). */
    final const(ubyte[]) findAt(in string haystack, size_t soff = 0) const
    {
        return findAtU(haystack.representation, soff);
    }

    /** Find $(D this) in $(D haystack) at Offset $(D soff). */
    const(ubyte[]) findAtU(in ubyte[] haystack, size_t soff = 0) const
    {
        auto i = soff;
        while (i < haystack.length) // while bytes left at i
        {
            if (haystack.length - i < minLength)  // and bytes left to find pattern
            {
                return [];
            }
            const hit = atU(haystack, i);
            if (hit != size_t.max) // hit at i
            {
                return haystack[i..i + hit];
            }
            i++;
        }
        // debug dln("i:", i, ", haystack.length:", haystack.length, ", minLength:", minLength, ", atU(haystack,i):", atU(haystack,i));
        return [];
    }

    @property:
    size_t minLength() const { return maxLength; } /// Returns: minimum possible instance length.
    size_t maxLength() const { assert(false); } /// Returns: maximum possible instance length.

    bool isFixed() const { assert(false); } /// Returns: true if all possible instances have same length.
    bool isConstant() const { return false; } /// Returns: true if all possible instances have same length.

    final bool isVariable() const { return !isFixed; } /// Returns: true if all possible instances have different length.
    const(ubyte[]) getConstant() const { return []; } /// Returns: data if literal otherwise empty array.

    protected Patt _parent; /// Parenting (Super) Pattern.
    bool greedy = false; // Scan as far as possible if true
}

/** Literal Pattern with Cached Binary Byte Histogram.
 */
class Lit : Patt
{
    @safe pure nothrow:

    this(string bytes_) { assert(!bytes_.empty); this(bytes_.representation); }
    this(ubyte ch) { this._bytes ~= ch; }
    this(ubyte[] bytes_) { this._bytes = bytes_; }
    this(immutable ubyte[] bytes_) { this._bytes = bytes_.dup; }

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        const l = _bytes.length;
        return (soff + l <= haystack.length && // fits in haystack and
                _bytes[] == haystack[soff..soff + l]) ? l : size_t.max; // same contents
    }

    override const(ubyte[]) findAtU(in ubyte[] haystack, size_t soff = 0) const
    {
        return haystack[soff..$].find(_bytes); // reuse std.algorithm: find!
    }

    @property:

    override size_t maxLength() const { return _bytes.length; }
    override bool isFixed() const { return true; }
    override bool isConstant() const { return true; }
    override const(ubyte[]) getConstant() const { return _bytes; }

    @property auto ref bytes() const { return _bytes; }
    private ubyte[] _bytes;
    alias _bytes this;

    alias BitSet!(2^^ubyte.sizeof) SinglesHist;

    /// Get (Cached) (Binary) Histogram over single elements contained in this $(D Lit).
    SinglesHist singlesHist()
    {
        if (!_bytes.empty &&
            _singlesHist.allZero)
        {
            foreach (b; _bytes)
            {
                _singlesHist[b] = true;
            }
        }
        return _singlesHist;
    }
    private SinglesHist _singlesHist;
}

auto lit(Args...)(Args args) @safe pure nothrow { return new Lit(args); } // instantiator

@safe pure nothrow unittest
{
    immutable ab = "ab";
    assert(lit('b').at("ab", 1) == 1);
    const a = lit('a');
    import dbg: dln;

    const ac = lit("ac");
    assert(ac.match("ac"));
    assert(ac.match("ac").length == 2);
    assert(!ac.match("ca"));
    assert(ac.match("ca") == []);

    assert(a.isFixed);
    assert(a.isConstant);
    assert(a.at(ab) == 1);
    assert(lit(ab).at("a") == size_t.max);
    assert(lit(ab).at("b") == size_t.max);

    assert(a.findAt("cba") == cast(immutable ubyte[])"a");
    assert(a.findAt("ba") == cast(immutable ubyte[])"a");
    assert(a.findAt("a") == cast(immutable ubyte[])"a");
    assert(a.findAt("") == []);
    assert(a.findAt("b") == []);
    assert(ac.findAt("__ac") == cast(immutable ubyte[])"ac");
    assert(a.findAt("b").length == 0);

    auto xyz = lit("xyz");
}

/** Word/Symbol Acronym Pattern.
 */
class Acronym : Patt
{
    @safe pure nothrow:

    this(string bytes_, FindContext ctx = FindContext.inSymbol)
    {
        assert(!bytes_.empty);
        this(bytes_.representation, ctx);
    }

    this(ubyte ch) { this._acros ~= ch; }
    this(ubyte[] bytes_, FindContext ctx = FindContext.inSymbol)
    {
        this._acros = bytes_;
        this._ctx = ctx;
    }
    this(immutable ubyte[] bytes_, FindContext ctx = FindContext.inSymbol)
    {
        this._acros = bytes_.dup;
        this._ctx = ctx;
    }

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        auto offs = new size_t[_acros.length]; // hit offsets
        size_t a = 0;         // acronym index
        foreach(s, ub; haystack[soff..$])  // for each element in source
        {
            import std.ascii: isAlpha;

            // Check context
            final switch (_ctx)
            {
            case FindContext.inWord:
            case FindContext.asWord:
                if (!ub.isAlpha) { return size_t.max; } break;
            case FindContext.inSymbol:
            case FindContext.asSymbol:
                if (!ub.isAlpha && ub != '_') { return size_t.max; } break;
            }

            if (_acros[a] == ub)
            {
                offs[a] = s + soff; // store hit offset
                a++; // advance acronym
                if (a == _acros.length) // if complete acronym found
                {
                    return s + 1;             // return its length
                }
            }
        }
        return size_t.max; // no hit
    }

    template Tuple(E...) { alias E Tuple; }

    override const(ubyte[]) findAtU(in ubyte[] haystack, size_t soff = 0) const {
        import std.string: CaseSensitive;
        return haystack.findAcronymAt(_acros, _ctx, CaseSensitive.yes, soff)[0];
    }

    @property:
    override size_t minLength() const { return _acros.length; }
    override size_t maxLength() const { return size_t.max; }
    override bool isFixed() const { return false; }
    override bool isConstant() const { return false; }
    private ubyte[] _acros;
    FindContext _ctx;
}

@safe pure nothrow
{
    auto inwac(Args...)(Args args) { return new Acronym(args, FindContext.inWord); } // word acronym
    auto insac(Args...)(Args args) { return new Acronym(args, FindContext.inSymbol); } // symbol acronym
    auto aswac(Args...)(Args args) { return new Acronym(args, FindContext.asWord); } // word acronym
    auto assac(Args...)(Args args) { return new Acronym(args, FindContext.asSymbol); } // symbol acronym
}

@safe pure nothrow unittest
{
    assert(inwac("a").at("a") == 1);
    assert(inwac("ab").at("ab") == 2);
    assert(inwac("ab").at("a") == size_t.max);
    assert(inwac("abc").at("abc") == 3);
    assert(inwac("abc").at("aabbcc") == 5);
    assert(inwac("abc").at("aaaabbcc") == 7);
    assert(inwac("fpn").at("fopen") == 5);
}

/** Any Byte.
 */
class Any : Patt
{
    @safe pure nothrow:
    this() {}

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        return soff < haystack.length ? 1 : size_t.max;
    }

    @property:
    override size_t maxLength() const { return 1; }
    override bool isFixed() const { return true; }
    override bool isConstant() const { return false; }
}

auto any(Args...)(Args args) { return new Any(args); } // instantiator

/** Abstract Super Pattern.
 */
abstract class SPatt : Patt
{
    @safe pure nothrow:

    this(Patt[] subs_) { this._subs = subs_; }

    this(Args...)(Args subs_)
    {
        import std.traits: isAssignable;
        foreach (sub; subs_)
        {
            alias Sub = typeof(sub);

            // TODO functionize to patternFromBuiltinType() or to!Patt
            static if (is(Sub == string) ||
                       is(Sub == char))
            {
                _subs ~= new Lit(sub);
            }
            else
            {
                _subs ~= sub;
            }
            sub._parent = this;
        }
    }

    protected Patt[] _subs;
}

/** Sequence of Patterns.
 */
class Seq : SPatt
{
    @safe pure nothrow:

    this(Patt[] subs_) { super(subs_); }
    this(Args...)(Args subs_) { super(subs_); }

    @property auto ref inout (Patt[]) elms() inout { return super._subs; }

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        assert(!elms.empty); // TODO Move to in contract?
        const c = getConstant;
        if (!c.empty)
        {
            return (soff + c.length <= haystack.length &&   // if equal size and
                    c[] == haystack[soff..soff + c.length]); // equal contents
        }
        size_t sum = 0;
        size_t off = soff;
        foreach (ix, sub; elms) // TODO Reuse std.algorithm instead?
        {
            size_t hit = sub.atU(haystack, off);
            if (hit == size_t.max) { sum = hit; break; } // if any miss skip
            sum += hit;
            off += hit;
        }
        return sum;
    }

    @property:
    override size_t maxLength() const { assert(false); }
    override bool isFixed() const { return _subs.all!(a => a.isFixed); }
    override bool isConstant() const { return _subs.all!(a => a.isConstant); }
    override const(ubyte[]) getConstant() const { return []; }
}

auto seq(Args...)(Args args) @safe pure nothrow { return new Seq(args); } // instantiator

@safe pure nothrow unittest
{
    const s = seq(lit("al"),
                  lit("pha"));
    const t = lit("al") ~ lit("pha");
    assert(s !is t);

    immutable haystack = "alpha";
    assert(s.isFixed);
    assert(s.isConstant);
    assert(s.at(haystack));
    const al = seq(lit("a"),
                   lit("l"));
    assert(al.at("a") == size_t.max);
}

/** Alternative of Patterns in $(D ALTS).
 */
class Alt : SPatt
{
    @safe pure nothrow:

    this(Patt[] subs_) { super(subs_); }
    this(Args...)(Args subs_) { super(subs_); }

    size_t atIx(in string haystack, size_t soff, out size_t alt_hix) const
    {
        return atU(haystack.representation, soff, alt_hix);
    }

    @property auto ref inout (Patt[]) alts() inout { return super._subs; }

    /** Get Length of hit at index soff in haystack or size_t.max if none.
     */
    size_t atU(in ubyte[] haystack, size_t soff, out size_t alt_hix) const
    {
        assert(!alts.empty);    // TODO Move to in contract?
        size_t hit = 0;
        size_t off = soff;
        foreach (ix, sub; alts)  // TODO Reuse std.algorithm instead?
        {
            hit = sub.atU(haystack[off..$]);                     // match alternative
            if (hit != size_t.max) { alt_hix = ix; break; } // if any hit were done
        }
        return hit;
    }
    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        size_t alt_hix;
        return atU(haystack, soff, alt_hix);
    }

    /** Find $(D this) in $(D haystack) at Offset $(D soff).
        TODO Add findAt() and detect case when all alternatives full isConstant
        (cached them) and use variadic version of std.algorithm:find.
    */
    override const(ubyte[]) findAtU(in ubyte[] haystack, size_t soff = 0) const
    {
        assert(!alts.empty);    // TODO Move to in contract?
        if        (alts.length == 1)
        {
            return alts[0].findAtU(haystack, soff); // recurse to it
        }
        else if (alts.length == 2)
        {
            const a0 = alts[0].getConstant;
            const a1 = alts[1].getConstant;
            if (!a0.empty &&
                !a1.empty)
            {
                auto hit = find(haystack[soff..$], a0, a1); // Use: second argument to return alt_hix
                return hit[0];
            }
        }
        else if (alts.length == 3)
        {
            const a0 = alts[0].getConstant;
            const a1 = alts[1].getConstant;
            const a2 = alts[2].getConstant;
            if (!a0.empty &&
                !a1.empty &&
                !a2.empty)
            {
                auto hit = find(haystack[soff..$], a0, a1, a2); // Use: second argument to return alt_hix
                return hit[0];
            }
        }
        else if (alts.length == 4)
        {
            const a0 = alts[0].getConstant;
            const a1 = alts[1].getConstant;
            const a2 = alts[2].getConstant;
            const a3 = alts[3].getConstant;
            if (!a0.empty &&
                !a1.empty &&
                !a2.empty &&
                !a3.empty)
            {
                auto hit = find(haystack[soff..$], a0, a1, a2, a3); // Use: second argument to return alt_hix
                return hit[0];
            }
        }
        else if (alts.length == 5)
        {
            const a0 = alts[0].getConstant;
            const a1 = alts[1].getConstant;
            const a2 = alts[2].getConstant;
            const a3 = alts[3].getConstant;
            const a4 = alts[4].getConstant;
            if (!a0.empty &&
                !a1.empty &&
                !a2.empty &&
                !a3.empty &&
                !a4.empty)
            {
                auto hit = find(haystack[soff..$], a0, a1, a2, a3, a4); // Use: second argument to return alt_hix
                return hit[0];
            }
        }
        return super.findAtU(haystack, soff); // revert to base case
    }

    @property:
    override size_t minLength() const { return reduce!min(size_t.max,
                                                          _subs.map!(a => a.minLength)); }
    override size_t maxLength() const { return reduce!max(size_t.min,
                                                          _subs.map!(a => a.maxLength)); }
    override bool isFixed() const
    {
        // TODO Merge these loops using tuple algorithm.
        auto mins = _subs.map!(a => a.minLength);
        auto maxs = _subs.map!(a => a.maxLength);
        import predicates: allEqual;
        return (mins.allEqual &&
                maxs.allEqual);
    }
    override bool isConstant() const
    {
        if (_subs.length == 0)
        {
            return true;
        }
        else if (_subs.length == 1)
        {
            import std.range: front;
            return _subs.front.isConstant;
        }
        else
        {
            return false;       // TODO Maybe handle case when _subs are different.
        }
    }
}

auto alt(Args...)(Args args) @safe pure nothrow { return new Alt(args); } // instantiator

@safe pure nothrow unittest
{
    immutable a_b = alt(lit("a"),
                        lit("b"));

    immutable a__b = (lit("a") |
                      lit("b"));

    assert(a_b.isFixed);
    assert(!a_b.isConstant);
    assert(a_b.at("a"));
    assert(a_b.at("b"));
    assert(a_b.at("c") == size_t.max);

    size_t hix = size_t.max;
    a_b.atIx("a", 0, hix); assert(hix == 0);
    a_b.atIx("b", 0, hix); assert(hix == 1);

    /* assert(alt().at("a") == size_t.max); */
    /* assert(alt().at("") == size_t.max); */

    immutable a = alt(lit("a"));
    immutable aa = alt(lit("aa"));
    assert(aa.isConstant);

    immutable aa_bb = alt(lit("aa"),
                          lit("bb"));
    assert(aa_bb.isFixed);
    assert(aa_bb.minLength == 2);
    assert(aa_bb.maxLength == 2);

    immutable a_bb = alt(lit("a"),
                         lit("bb"));
    assert(!a_bb.isFixed);
    assert(a_bb.minLength == 1);
    assert(a_bb.maxLength == 2);

    const string _aa = "_aa";
    assert(aa_bb.findAt(_aa) == cast(immutable ubyte[])"aa");
    assert(aa_bb.findAt(_aa).ptr - (cast(immutable ubyte[])_aa).ptr == 1);

    const string _bb = "_bb";
    assert(aa_bb.findAt(_bb) == cast(immutable ubyte[])"bb");
    assert(aa_bb.findAt(_bb).ptr - (cast(immutable ubyte[])_bb).ptr == 1);

    assert(a.findAt("b") == []);
    assert(aa.findAt("cc") == []);
    assert(aa_bb.findAt("cc") == []);
    assert(aa_bb.findAt("") == []);
}

class Space : Patt
{
    @safe pure nothrow:

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        import std.ascii: isWhite;
        return soff < haystack.length && isWhite(haystack[soff]) ? 1 : size_t.max;
    }

    @property:
    override size_t maxLength() const { return 1; }
    override bool isFixed() const { return true; }
    override bool isConstant() const { return false; }
}

auto ws() @safe pure nothrow { return new Space(); } // instantiator

@safe pure nothrow unittest
{
    assert(ws().at(" ") == 1);
    assert(ws().at("\t") == 1);
    assert(ws().at("\n") == 1);
}

/** Abstract Singleton Super Pattern.
 */
abstract class SPatt1 : Patt
{
    @safe pure nothrow:

    this(Patt sub)
    {
        this.sub = sub;
        sub._parent = this;
    }
    protected Patt sub;
}

/** Optional Sub Pattern $(D count) times.
 */
class Opt : SPatt1
{
    @safe pure nothrow:

    this(Patt sub) { super(sub); }

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        assert(soff <= haystack.length); // include equality because haystack might be empty and size zero
        const hit = sub.atU(haystack[soff..$]);
        return hit == size_t.max ? 0 : hit;
    }

    @property:
    override size_t minLength() const { return 0; }
    override size_t maxLength() const { return sub.maxLength; }
    override bool isFixed() const { return false; }
    override bool isConstant() const { return false; }
}

auto opt(Args...)(Args args) { return new Opt(args); } // optional

@safe pure nothrow unittest
{
    assert(opt(lit("a")).at("b") == 0);
    assert(opt(lit("a")).at("a") == 1);
}

/** Repetition Sub Pattern $(D count) times.
 */
class Rep : SPatt1
{
    @safe pure nothrow:

    this(Patt sub, size_t count) in { assert(count >= 2); }
    body
    {
        super(sub);
        this.countReq = count;
        this.countOpt = 0;
    }

    this(Patt sub, size_t countMin, size_t countMax) in { assert(countMin <= countMax); }
    body
    {
        super(sub);
        this.countReq = countMin;
        this.countOpt = countMax - countMin;
    }

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        size_t sum = 0;
        size_t off = soff;
        /* mandatory */
        foreach (ix; 0..countReq)  // TODO Reuse std.algorithm instead?
        {
            size_t hit = sub.atU(haystack[off..$]);
            if (hit == size_t.max) { return hit; } // if any miss skip
            off += hit;
            sum += hit;
        }
        /* optional part */
        foreach (ix; countReq..countReq + countOpt) // TODO Reuse std.algorithm instead?
        {
            size_t hit = sub.atU(haystack[off..$]);
            if (hit == size_t.max) { break; } // if any miss just break
            off += hit;
            sum += hit;
        }
        return sum;
    }

    @property:
    override size_t minLength() const { return countReq*sub.maxLength; }
    override size_t maxLength() const { return (countReq + countOpt)*sub.maxLength; }
    override bool isFixed() const { return minLength == maxLength && sub.isFixed; }
    override bool isConstant() const { return minLength == maxLength && sub.isConstant; }

    // invariant { assert(countReq); }
    size_t countReq; // Required.
    size_t countOpt; // Optional.
}

auto rep(Args...)(Args args) { return new Rep(args); } // repetition
auto zom(Args...)(Args args) { return new Rep(args, 0, size_t.max); } // zero or more
auto oom(Args...)(Args args) { return new Rep(args, 1, size_t.max); } // one or more

@safe pure nothrow unittest
{
    auto l = lit('a');

    const l5 = rep(l, 5);
    assert(l5.isConstant);
    assert(l5.at("aaaa") == size_t.max);
    assert(l5.at("aaaaa"));
    assert(l5.at("aaaaaaa"));
    assert(l5.isFixed);
    assert(l5.maxLength == 5);

    const l23 = rep(l, 2, 3);
    assert(l23.at("a") == size_t.max);
    assert(l23.at("aa") == 2);
    assert(l23.at("aaa") == 3);
    assert(l23.at("aaaa") == 3);
    assert(!l23.isConstant);
}

class Ctx : Patt
{
    enum Type
    {
        bob, /// Beginning Of \em Block/Name/File/String. @b Emacs: "\`"
        eob, /// End       Of \em Block/Name/File/String. @b Emacs: "\'"

        bol,            /// Beginning Of \em Line. @b Emacs: "^"
        eol,            /// End       Of \em Line. @b Emacs: "$"

        bos,            /// Beginning Of \em Symbol. @b Emacs: "\_<"
        eos,            /// End       Of \em Symbol. @b Emacs: "\_>"

        bow,            /// Beginning Of \em Word. @b Emacs: "\<"
        eow,            /// End       Of \em Word. @b Emacs: "\>"
    }

    @safe pure nothrow:

    this(Type type) { this.type = type; }

    override size_t atU(in ubyte[] haystack, size_t soff = 0) const
    {
        assert(soff <= haystack.length); // include equality because haystack might be empty and size zero
        bool ok = false;
        import std.ascii : isAlphaNum/* , newline */;
        final switch (type)
        {
            /* buffer */
        case Type.bob: ok = (soff == 0); break;
        case Type.eob: ok = (soff == haystack.length); break;

            /* line */
        case Type.bol: ok = (soff == 0          || (haystack[soff - 1] == 0x0d ||
                                                   haystack[soff - 1] == 0x0a)); break;
        case Type.eol: ok = (soff == haystack.length || (haystack[soff    ] == 0x0d ||
                                                   haystack[soff    ] == 0x0a)); break;

            /* symbol */
        case Type.bos: ok = ((soff == 0         || (!haystack[soff - 1].isAlphaNum &&
                                                    haystack[soff - 1] != '_')) && // TODO Make '_' language-dependent
                             (soff < haystack.length &&  haystack[soff].isAlphaNum)) ; break;
        case Type.eos: ok = ((soff == haystack.length || (!haystack[soff].isAlphaNum &&
                                                          haystack[soff] != '_')) && // TODO Make '_' language-dependent
                             (soff >= 1          &&  haystack[soff - 1].isAlphaNum)) ; break;

            /* word */
        case Type.bow: ok = ((soff == 0         || !haystack[soff - 1].isAlphaNum) &&
                             (soff < haystack.length &&  haystack[soff].isAlphaNum)) ; break;
        case Type.eow: ok = ((soff == haystack.length || !haystack[soff].isAlphaNum) &&
                             (soff >= 1          &&  haystack[soff - 1].isAlphaNum)) ; break;
        }
        return ok ? 0 : size_t.max;
    }

    @property:
    override size_t maxLength() const { return 0; }
    override bool isFixed() const { return true; }
    override bool isConstant() const { return true; }

    protected Type type;
}

Ctx bob(Args...)(Args args) { return new Ctx(args, Ctx.Type.bob); }
Ctx eob(Args...)(Args args) { return new Ctx(args, Ctx.Type.eob); }
Ctx bol(Args...)(Args args) { return new Ctx(args, Ctx.Type.bol); }
Ctx eol(Args...)(Args args) { return new Ctx(args, Ctx.Type.eol); }
Ctx bos(Args...)(Args args) { return new Ctx(args, Ctx.Type.bos); }
Ctx eos(Args...)(Args args) { return new Ctx(args, Ctx.Type.eos); }
Ctx bow(Args...)(Args args) { return new Ctx(args, Ctx.Type.bow); }
Ctx eow(Args...)(Args args) { return new Ctx(args, Ctx.Type.eow); }
Seq buf(Args...)(Args args) { return seq(bob(), args, eob()); }
Seq line(Args...)(Args args) { return seq(bol(), args, eol()); }
Seq sym(Args...)(Args args) { return seq(bos(), args, eos()); }
Seq word(Args...)(Args args) { return seq(bow(), args, eow()); }

@safe pure nothrow unittest
{
    const bob_ = bob();
    const eob_ = eob();
    assert(bob_.at("ab") == 0);
    assert(eob_.at("ab", 2) == 0);

    const bol_ = bol();
    assert(bol_.at("ab") == 0);
    assert(bol_.at("a\nb", 2) == 0);
    assert(bol_.at("a\nb", 1) == size_t.max);

    const eol_ = eol();
    assert(eol_.at("ab", 2) == 0);
    assert(eol_.at("a\nb", 1) == 0);
    assert(eol_.at("a\nb", 2) == size_t.max);

    const bos_ = bos();
    const eos_ = eos();
    assert(bos_.at("ab") == 0);
    assert(bos_.at(" ab") == size_t.max);
    assert(eos_.at("ab", 2) == 0);
    assert(eos_.at("a_b ", 1) == size_t.max);
    assert(eos_.at("ab ", 2) == 0);

    const bow_ = bow();
    const eow_ = eow();

    assert(bow_.at("ab") == 0);
    assert(bow_.at(" ab") == size_t.max);

    assert(eow_.at("ab", 2) == 0);
    assert(eow_.at("ab ", 0) == size_t.max);

    assert(bow_.at(" ab ", 1) == 0);
    assert(bow_.at(" ab ", 0) == size_t.max);

    assert(eow_.at(" ab ", 3) == 0);
    assert(eow_.at(" ab ", 4) == size_t.max);

    auto l = lit("ab");
    auto w = word(l);
    assert(w.at("ab") == 2);
    assert(w.at("ab_c") == 2);

    auto s = sym(l);
    assert(s.at("ab") == 2);
    assert(s.at("ab_c") == size_t.max);

    assert(bob_.findAt("a") == []);
    assert(bob_.findAt("a").ptr != null);
    assert(eob_.findAt("a") == []);

    assert(bol_.findAt("a") == []);
    assert(bol_.findAt("a").ptr != null);
    assert(eol_.findAt("a") == []);

    assert(bow_.findAt("a") == []);
    assert(bow_.findAt("a").ptr != null);
    assert(eow_.findAt("a") == []);

    assert(bos_.findAt("a") == []);
    assert(bos_.findAt("a").ptr != null);
    assert(eos_.findAt("a") == []);
    // TODO This fails assert(eos_.findAt("a").ptr != null);
}

/** Keyword $(D arg). */
Seq kwd(Arg)(Arg arg) { return seq(bow(), arg, eow()); }

@safe pure nothrow unittest
{
    const str = "int";
    auto x = str.lit.kwd;

    assert(x.at(str, 0));
    /* TODO assert(!x.at(str, 1)); */

    assert(x.at(" " ~ str, 1));
    /* TODO assert(!x.at(" int", 0)); */
}

/** Create Matcher for a UNIX Shell $(LUCKY Shebang) Pattern.
    Example: #!/bin/env rdmd
    See also: https://en.wikipedia.org/wiki/Shebang_(Unix)
 */
auto ref shebangLine(Patt interpreter) @safe pure nothrow
{
    return seq(lit("#!"),
               opt(lit("/usr")),
               opt(lit("/bin/env")),
               oom(ws()),
               interpreter);
}

@safe pure nothrow unittest
{
    assert(shebangLine(lit("rdmd")).
           at("#!/bin/env rdmd") ==
           15);
    assert(shebangLine(lit("rdmd")).
           at("#!/usr/bin/env rdmd") ==
           19
        );
    assert(shebangLine(alt(lit("rdmd"),
                           lit("gdmd"))).
           at("#!/usr/bin/env rdmd-dev") ==
           19);
    const x = shebangLine(alt(lit("rdmd"),
                              lit("gdmd")));
    /* assert(x.findAt("   #!/usr/bin/env rdmd-dev")); */
}
