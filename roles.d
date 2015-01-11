module roles;

public import rels;

struct Role
{
    @safe @nogc pure nothrow:
    this(Rel rel, bool reversion = false, bool negation = false)
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

            case `meronym`: this.rel = partOf; break;
            case `memberOf`: this.rel = memberOf; break;
            case `partOf`: this.rel = partOf; break;
            case `wholeOf`:
            case `holonym`: this.rel = partOf; this.reversion = true; break;

            case `hypernym`: this.rel = isA; this.reversion = true; break;
            case `hyponym`: this.rel = isA; break;

            case `canBe`: this.rel = isA; break;
            default:
                this.rel = relatedTo;
                // assert(false, `Unexpected role `);
                break;
        }
    }
    Rel rel;
    bool reversion;
    bool negation;
}
