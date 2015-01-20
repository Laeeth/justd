module roles;

import std.bitmanip: bitfields;
public import rels;

struct Role
{
    @safe @nogc pure nothrow:
    this(Rel rel = Rel.any,
         bool reversion = false,
         bool negation = false)
    {
        this.rel = rel;
        this.reversion = reversion;
        this.negation = negation;
    }
    this(string role)
    {
        this.reversion = false;
        this.negation = false;
        switch (role) with (Rel)
        {
            case `isA`: this.rel = isA; break;

            case `antonym`:
            case `antonymFor`: this.rel = antonymFor; break;

            case `meronym`:
                this.rel = partOf; break;

            case `memberOf`:
                this.rel = memberOf; break;

            case `partOf`:
                this.rel = partOf; break;

            case `wholeOf`:
            case `holonym`:
                this.rel = partOf; this.reversion = true; break;

            case `hypernym`:
                this.rel = isA; this.reversion = true; break;

            case `instanceHypernym`:
            case `instanceHypernymOf`:
                this.rel = instanceHypernymOf; break;

            case `hyponym`:
                this.rel = isA; break;

            case `instanceHyponym`:
            case `instanceHyponymOf`:
                this.rel = instanceHyponymOf; break;

            case `canBe`: this.rel = isA; break;

            case `cause`:
            case `causes`:
                this.rel = causes; break;

            case `entail`:
            case `entails`:
                this.rel = causes; this.reversion = true; break;

            default:
                this.rel = relatedTo;
                // assert(false, `Unexpected role `);
                break;
        }
    }
    Rel rel;
    mixin(bitfields!(bool, "reversion", 1,
                     bool, "negation", 1,
                     uint, "pad", 6));
}
