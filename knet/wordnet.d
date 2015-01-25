module knet.wordnet;

import knet.relations: Rel;
import knet.roles: Role;
import knet.senses: Sense;

Role decodeWordNetPointerSymbol(string sym, Sense sense) pure
{
    typeof(return) role;
    with (Rel)
    {
        switch (sym)
        {
            case `!`:  role = Role(antonymFor); break;
            case `@`:  role = Role(hypernymOf, true); break;
            case `@i`: role = Role(instanceHypernymOf, true); break;
            case `~`:  role = Role(hyponymOf); break;
            case `~i`: role = Role(instanceHyponymOf); break;
            case `*`:  role = Role(causes, true); break; // entailment.

            // case `#m`: role = Role(memberHolonym); break;
            // case `#s`: role = Role(substanceHolonym); break;
            // case `#p`: role = Role(partHolonym); break;
            case `%m`: role = Role(memberOf); break;
            case `%s`: role = Role(madeOf); break;
            case `%p`: role = Role(partOf); break;

            // case `=`:  role = Role(attribute); break;
            // case `+`:  role = Role(derivationallyRelatedForm); break;
            // case `;c`: role = Role(domainOfSynset); break; // TOPIC
            // case `-c`: role = Role(memberOfThisDomain); break;  // TOPIC
            // case `;r`: role = Role(domainOfSynset); break; // REGION
            // case `-r`: role = Role(memberOfThisDomain); break; // REGION
            // case `;u`: role = Role(domainOfSynset); break; // USAGE
            // case `-u`: role = Role(memberOfThisDomain); break; // USAGE

            case `>`:  role = Role(causes); break;
            // case `^`:  role = Role(alsoSee); break;
            case `$`:  role = Role(formOfVerb); break;

            case `&`:  role = Role(similarTo); break;
            case `<`:  role = Role(participleOfVerb); break;

            // case `\`:  role = Role(pertainym); break; // pertains to noun
            // case `=`:  role = Role(attribute); break;

            default:
                assert(false, `Unexpected relation type ` ~ sym);
        }
    }
    return role;
}
