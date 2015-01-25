module knet.moby;

import std.traits: isSomeString;

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
