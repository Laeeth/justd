module knet.filtering;

import std.algorithm.searching: canFind;
import knet.base;

bool matches(const Lang[] langs, Lang lang) @safe pure nothrow @nogc
{
    return langs.empty || langs.canFind(lang);
}

bool matches(const Origin[] origins, Origin origin) @safe pure nothrow @nogc
{
    return origins.empty || origins.canFind(origin);
}

bool matches(const Role[] roles, Role role) @safe pure nothrow @nogc
{
    foreach (role_; roles)
    {
        import knet.roles: specializes;
        if ((role.rel == role_.rel ||
             role.rel.specializes(role_.rel)) && // TODO functionize
            role.reversed == role_.reversed &&
            role.negation == role_.negation)
        {
            return true;
        }
    }
    return roles.empty;
}

bool matches(const Sense[] senses, Sense sense) @safe pure nothrow @nogc
{
    foreach (sense_; senses)
    {
        import knet.senses: specializes;
        if (sense == sense_ ||
            sense.specializes(sense_)) // TODO functionize
        {
            return true;
        }
    }
    return senses.empty;
}

/** Node/Link (Traversal) Filter.
 */
struct Filter
{
    @safe pure nothrow:

    this(Lang[] langs,
         Sense[] senses = [],
         Role[] roles = [],
         Origin[] origins = [])
    {
        // TODO may be wanted to include Lang.unknown and Sense.unknown in some future
        this.langs = langs.filter!(lang => lang != Lang.unknown).array;
        this.senses = senses.filter!(sense => sense != Sense.unknown).array;
        this.roles = roles;
        this.origins = origins.filter!(origin => origin != Origin.unknown).array;
    }

    bool matches(Lang lang, Sense sense, Role role, Origin origin) const @nogc
    {
        return (langs.matches(lang) &&
                senses.matches(sense) &&
                roles.matches(role) &&
                origins.matches(origin));
    }

    Lang[] langs;
    Sense[] senses;
    Role[] roles;
    Origin[] origins;
}
