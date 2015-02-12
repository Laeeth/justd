module knet.readers.moby;

import std.stdio: writeln;
import std.traits: isSomeChar, isSomeString;
import std.array: array, replace;
import std.algorithm: joiner;
import std.conv: to;
import std.stdio: File;
import core.exception: UnicodeException;
import std.utf: UTFException;

import knet.base;

/** Decode Moby Pronounciation Code to IPA Language.
    See also: https://en.wikipedia.org/wiki/Moby_Project#Pronunciator
*/
auto decodeMobyIPA(S)(S code) if (isSomeString!S)
{
    switch (code)
    {
        case `&`: return `æ`;
        case `-`: return `ə`;
        case `@`: return `ʌ`; // both `ʌ` or `ə` are allowed
        case `[@]`: return `ɜ`; // undocumented?
        case `(@)`: return `eə`; // undocumented in Moby?
        case `@r`: return `ɜr`; // alt: `ər`
        case `A`: return `ɑː`;
        case `aI`: return `aɪ`;
        case `Ar`: return `ɑr`;
        case `AU`: return `aʊ`;
        case `b`: return `b`;
        case `d`: return `d`;
        case `D`: return `ð`;
        case `dZ`: return `dʒ`;
        case `E`: return `ɛ`;
        case `eI`: return `eɪ`;
        case `f`: return `f`;
        case `g`: return `ɡ`;
        case `h`: return `h`;
        case `hw`: return `hw`;
        case `i`: return `iː`;
        case `I`: return `ɪ`;
        case `j`: return `j`;
        case `k`: return `k`;
        case `l`: return `l`;
        case `m`: return `m`;
        case `n`: return `n`;
        case `N`: return `ŋ`;
        case `O`: return `ɔː`;
        case `Oi`: return `ɔɪ`;
        case `oU`: return `oʊ`;
        case `p`: return `p`;
        case `r`: return `r`;
        case `s`: return `s`;
        case `S`: return `ʃ`;
        case `t`: return `t`;
        case `T`: return `θ`;
        case `tS`: return `tʃ`;
        case `u`: return `uː`;
        case `U`: return `ʊ`;
        case `v`: return `v`;
        case `w`: return `w`;
        case `z`: return `z`;
        case `Z`: return `ʒ`;
        case `'`: return `'`; // primary stress on the following syllable
        case `,`: return `,`; // secondary stress on the following syllable
        default:
            // dln(`warning: `, code);
            return code.idup;
    }
}

/** Learn English Pronouncation Patterns from Moby.
    See also: https://en.wikipedia.org/wiki/Moby_Project#Hyphenator
*/
void learnMobyEnglishPronounciations(Graph graph)
{
    const path = `../knowledge/moby/pronounciation.txt`;
    writeln(`Reading Moby pronounciations from `, path, ` ...`);
    size_t lnr = 0;
    foreach (line; File(path).byLine)
    {
        auto split = line.splitter(' ');
        string expr;

        try
        {
            expr = split.front.replace(`_`, ` `).idup;
        }
        catch (UnicodeException e)
        {
            expr = split.front.idup;
            writeln(`warning: Couldn't decode Moby expression `, expr);
        }
        split.popFront;
        string ipas;

        if (!split.empty)
        {
            try
            {
                ipas = split.front
                            .splitter('_') // word separator
                            .map!(word =>
                                  word.splitter('/') // phoneme separator
                                      .map!(a => a.decodeMobyIPA)
                                      .joiner)
                            .joiner(` `)
                            .to!string;
            }
            catch (UTFException e)
            {
                ipas = split.front.idup;
                writeln(`warning: Couldn't decode Moby IPA code `, ipas);
            }
            graph.connect(graph.store(expr, Lang.en, Sense.unknown, Origin.manual), Role(Rel.translationOf),
                          graph.store(ipas, Lang.ipa, Sense.unknown, Origin.manual), Origin.manual, 1.0);
        }
        else
        {
            writeln(`warning: Split became empty for line of length `, line.length);
        }
        ++lnr;
    }
    writeln(`Read Moby pronounciations from `, path, ` having `, lnr, ` lines`);
}

/** Decode Sense of Moby Part of Speech (PoS) Code.
 */
Sense decodeSenseOfMobyPoSCode(C)(C code) if (isSomeChar!C)
{
    switch (code) with (Sense)
    {
        case 'N': return nounSingular;
        case 'p': return nounPlural;
        case 'h': return nounPhrase;
        case 'V': return verb;
        case 't': return verbTransitive;
        case 'i': return verbIntransitive;
        case 'A': return adjective;
        case 'v': return adverb;
        case 'C': return conjunction;
        case 'P': return preposition;
        case '!': return interjection;
        case 'r': return pronoun;
        case 'D': return articleDefinite;
        case 'I': return articleIndefinite;
        case 'o': return nounNominative;
        default:
            writeln(`warning: Unknown Moby Part of Speech (PoS) code character ` ~ code);
            return unknown;
    }
}

void learnMobyPoS(Graph graph)
{
    const path = `../knowledge/moby/part_of_speech.txt`;
    writeln(`Reading Moby Part of Speech (PoS) from `, path, ` ...`);
    foreach (line; File(path).byLine)
    {
        import knet.separators;
        auto split = line.splitter(roleSeparator);
        const expr = split.front.idup; split.popFront;
        foreach (sense; split.front.map!(a => a.decodeSenseOfMobyPoSCode))
        {
            graph.store(expr, Lang.en, sense, Origin.moby);
        }
    }
}
