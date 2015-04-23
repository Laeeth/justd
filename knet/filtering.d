module knet.filtering;

import std.algorithm.searching: canFind;
import knet.base;

@safe pure nothrow @nogc:

bool matches(const Lang[] langs, Lang lang)
{
    return (langs.empty ||
            langs.canFind(lang));
}

bool matches(const Origin[] origins, Origin origin)
{
    return (origins.empty ||
            origins.canFind(origin));
}

bool matches(const Role[] roles, Role role)
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

bool matches(const Sense[] senses, Sense sense,
             bool uniquely = true,
             Lang lang = Lang.unknown,
             bool capitalized = false)
{
    foreach (sense_; senses)
    {
        import knet.senses: specializes;
        if (sense == sense_ ||
            sense.specializes(sense_, uniquely, lang, capitalized)) // TODO functionize
        {
            return true;
        }
    }
    return senses.empty;
}

/** Node Filter.
    Filters out Nodes
    - in languages $(D langs)
    - of senses $(D senses)
    - read from origins $(D origins).
 */
struct NodeFilter
{
    @safe pure nothrow:

    // TODO may be wanted to include Lang.unknown and Sense.unknown in some future

    this(Lang[] langs,
         Sense[] senses = [],
         Origin[] origins = [])
    {
        this.langs = langs.filter!(lang => lang != Lang.unknown).array;
        this.senses = senses.filter!(sense => sense != Sense.unknown).array;
        this.origins = origins.filter!(origin => origin != Origin.unknown).array;
    }

    this(Lang[] langs,
         Origin[] origins = [])
    {
        this.langs = langs.filter!(lang => lang != Lang.unknown).array;
        this.origins = origins.filter!(origin => origin != Origin.unknown).array;
    }

    this(Sense[] senses,
         Origin[] origins)
    {
        this.senses = senses.filter!(sense => sense != Sense.unknown).array;
        this.origins = origins.filter!(origin => origin != Origin.unknown).array;
    }

    this(Sense[] senses)   { this.senses = senses.filter!(sense => sense != Sense.unknown).array; }
    this(Origin[] origins) { this.origins = origins.filter!(origin => origin != Origin.unknown).array; }

    bool matches(Lang lang,
                 Sense sense) const @nogc
    {
        return (langs.matches(lang) &&
                senses.matches(sense));
    }

    bool matches(Lang lang,
                 Sense sense,
                 Origin origin) const @nogc
    {
        return (langs.matches(lang) &&
                senses.matches(sense) &&
                origins.matches(origin));
    }

    bool matches(in Node node) const @nogc
    {
        return matches(node.lemma.lang,
                       node.lemma.sense,
                       node.origin);
    }

    Lang[] langs;
    Sense[] senses;
    Origin[] origins;
}

/** Node-Link-Step (Traversal) Filter.
 */
struct StepFilter
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

    bool matches(Lang lang,
                 Sense sense) const @nogc
    {
        return (langs.matches(lang) &&
                senses.matches(sense));
    }

    bool matches(Lang lang,
                 Sense sense,
                 Role role,
                 Origin origin) const @nogc
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
