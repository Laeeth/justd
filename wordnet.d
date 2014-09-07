#!/usr/bin/env rdmd-dev-module

/** WordNet.
 */
module wordnet;

import languages: HumanLang;
import conceptnet5;

/** WordNet Semantic Relation Type Code.
    See also: conceptnet5.Relation
*/
enum Relation:ubyte
{
    unknown,
    attribute,
    causes,
    classifiedByRegion,
    classifiedByUsage,
    classifiedByTopic,
    entails,
    hyponymOf, // also called hyperonymy, hyponymy,
    instanceOf,
    memberMeronymOf,
    partMeronymOf,
    sameVerbGroupAs,
    similarTo,
    substanceMeronymOf,
    antonymOf,
    derivationallyRelated,
    pertainsTo,
    seeAlso,
}

/** Map WordNet to ConceptNet5 Semantic Relation. */
T to(T:conceptnet5.Relation)(const Relation relation)
{
    final switch (relation)
    {
        case Relation.unknown: return conceptnet5.Relation.unknown;
        case Relation.attribute: return conceptnet5.Relation.Attribute;
        case Relation.causes: return conceptnet5.Relation.Causes;
        case Relation.classifiedByRegion: return conceptnet5.Relation.HasContext;
        case Relation.classifiedByUsage: return conceptnet5.Relation.HasContext;
        case Relation.classifiedByTopic: return conceptnet5.Relation.HasContext;
        case Relation.entails: return conceptnet5.Relation.Entails;
        case Relation.hyponymOf: return conceptnet5.Relation.IsA;
        case Relation.instanceOf: return conceptnet5.Relation.InstanceOf;
        case Relation.memberMeronymOf: return conceptnet5.Relation.MemberOf;
        case Relation.partMeronymOf: return conceptnet5.Relation.PartOf;
        case Relation.sameVerbGroupAs: return conceptnet5.Relation.SimilarTo;
        case Relation.similarTo: return conceptnet5.Relation.SimilarTo;
        case Relation.substanceMeronymOf: return conceptnet5.Relation.MadeOf;
        case Relation.antonymOf: return conceptnet5.Relation.Antonym;
        case Relation.derivationallyRelated: return conceptnet5.Relation.DerivedFrom;
        case Relation.pertainsTo: return conceptnet5.Relation.PertainsTo;
        case Relation.seeAlso: return conceptnet5.Relation.RelatedTox;
    }
}

version(none)
unittest
{
    auto x = Relation.attribute;
    auto y = x.to!(conceptnet5.Relation);
    assert(y == conceptnet5.Relation.Attribute);
}
