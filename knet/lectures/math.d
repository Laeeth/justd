module knet.lectures.math;

import knet.base;

void learnMath(Graph graph)
{
    const origin = Origin.manual;

    graph.connect(graph.add(`π`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.translationOf),
                  graph.add(`pi`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                  origin, 1.0);
    graph.connect(graph.add(`e`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.translationOf),
                  graph.add(`e`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                  origin, 1.0);

    /// http://www.geom.uiuc.edu/~huberty/math5337/groupe/digits.html
    graph.connect(graph.add(`π`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.definedAs),
                  graph.add(`3.14159265358979323846264338327950288419716939937510`,
                              Lang.math, Sense.decimal, origin),
                  origin, 1.0);

    graph.connect(graph.add(`e`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.definedAs),
                  graph.add(`2.71828182845904523536028747135266249775724709369995`,
                              Lang.math, Sense.decimal, origin),
                  origin, 1.0);

    graph.learnMto1(Lang.en, [`quaternary`, `quinary`, `senary`, `octal`,
                              `decimal`, `duodecimal`, `vigesimal`,
                              `quadrovigesimal`, `duotrigesimal`, `sexagesimal`, `octogesimal`],
                    Role(Rel.hasProperty, true), `counting system`, Sense.adjective, Sense.noun, 1.0);

    graph.learnEnglishQuantifiers();

    graph.learnNumerals();
}

/// Learn Quantifiers.
void learnEnglishQuantifiers(Graph graph)
{
    enum lang = Lang.en;
    enum origin = Origin.manual;

    enum quantifiers = [`all`, `any`, `both`, `each`, `enough`, `every`,
                        `few`, `a few`, `fewer`,
                        `little`, `a little`, `less`,
                        `lots of`, `a lot of,`
                        `many`, `more`, `no`, `none`, `several`, `some`];
    foreach (word; quantifiers)
    {
        graph.connect(graph.add(word, lang, Sense.quantifier, origin),
                      Role(Rel.instanceOf),
                      graph.add(`quantifier`, lang, Sense.integer, origin),
                      origin, 1.0);
    }

    enum quantifiersOfSingularNoun = [`each`, `every`, `no`];
    foreach (word; quantifiersOfSingularNoun)
    {
        graph.connect(graph.add(word, lang, Sense.quantifierOfSingularNoun, origin),
                      Role(Rel.instanceOf),
                      graph.add(`quantifier`, lang, Sense.integer, origin),
                      origin, 1.0);
    }

    enum quantifiersOfPluralNoun = [`all`, `any`, `both`, `enough`,
                                    `few`, `a few`, `fewer`,
                                    `lots of`, `a lot of,`
                                    `many`, `more`, `no`, `none`, `several`, `some`];
    foreach (word; quantifiersOfPluralNoun)
    {
        graph.connect(graph.add(word, lang, Sense.quantifierOfPluralNoun, origin),
                      Role(Rel.instanceOf),
                      graph.add(`quantifier`, lang, Sense.integer, origin),
                      origin, 1.0);
    }

    enum quantifiersOfUncountableNouns = [`all`, `any`, `enough`,
                                          `lots of`, `a lot of,`
                                          `more`, `no`, `none`, `some`];
    foreach (word; quantifiersOfUncountableNouns)
    {
        graph.connect(graph.add(word, lang, Sense.quantifierOfPluralNoun, origin),
                      Role(Rel.instanceOf),
                      graph.add(`quantifier`, lang, Sense.integer, origin),
                      origin, 1.0);
    }

}

/// Learn Numerals (Groupings/Aggregates) (MÄngdmått)
void learnNumerals(Graph graph)
{
    graph.learnRomanLatinNumerals();

    graph.learnFrenchNumerals();

    const origin = Origin.manual;

    graph.connect(graph.add(`single`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`1`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`pair`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`2`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`duo`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`2`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`triple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`3`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`quadruple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`4`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`quintuple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`5`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`sextuple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`6`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`septuple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`7`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    // Greek Numbering
    // TODO Also Latin?
    graph.connect(graph.add(`tetra`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`4`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`penta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`5`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`hexa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`6`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`hepta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`7`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`octa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`8`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`nona`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`9`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`deca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`10`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`hendeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`11`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`dodeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`12`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`trideca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`13`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`tetradeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`14`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`pentadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`15`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`hexadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`16`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`heptadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`17`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`octadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`18`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`enneadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`19`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`icosa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`20`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.learnEnglishOrdinalShorthands();
    graph.learnSwedishOrdinalShorthands();
    graph.learnSwedishOrdinalNumbers();
    graph.learnGermanOrdinalNumbers();
    graph.learnFrenchOrdinalNumbers();

    graph.learnEnglishFractions();
    graph.learnSwedishFractions();
    graph.learnFrenchFractions();

    // Aggregate
    graph.connect(graph.add(`dozen`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`12`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`baker's dozen`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`13`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`tjog`, Lang.sv, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`20`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`flak`, Lang.sv, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`24`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`skock`, Lang.sv, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`60`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    graph.connectMto1(graph.add([`dussin`, `tolft`], Lang.sv, Sense.numeral, origin),
                      Role(Rel.definedAs),
                      graph.add(`12`, Lang.math, Sense.integer, origin),
                      origin, 1.0);

    graph.connect(graph.add(`gross`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`144`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.add(`gross`, Lang.sv, Sense.numeral, origin), // TODO Support [Lang.en, Lang.sv]
                  Role(Rel.definedAs),
                  graph.add(`144`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    graph.connect(graph.add(`small gross`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`120`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    graph.connect(graph.add(`great gross`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.add(`1728`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
}

/** Learn French Numerals.
*/
void learnFrenchNumerals(Graph graph)
{
    enum lang = Lang.fr;
    enum numerals = [`zero`,
                     `un`, `duex`, `trois`, `quatre`, `cinq`,
                     `six`, `sept`, `huit`, `neuf`, `dix`,
                     `onze`, `douze`, `treize`, `quatorze`, `quinze`,
                     `seize`, `dix-sept`, `dix-huit`, `dix-neuf`,
                     `vingt`];
    enum tens = [`vingt`, `trente`, `quarante`, `cinquante`,
                 `soixante`, `soixante-dix`, `quatre-vingts`, `quatre-vingt-dix`,
                 `cent`];

    foreach (ix, ten; tens)
    {
        graph.connect(graph.add(ten, lang, Sense.numeral, Origin.manual), Role(Rel.definedAs),
                      graph.add((10*(ix + 2)).to!string, Lang.math, Sense.integer, Origin.manual), Origin.manual, 1.0);
    }

    graph.connect(graph.add(`mille`, lang, Sense.numeral, Origin.manual), Role(Rel.definedAs),
                  graph.add(`1000`, Lang.math, Sense.integer, Origin.manual), Origin.manual, 1.0);
    graph.connect(graph.add(`million`, lang, Sense.numeral, Origin.manual), Role(Rel.definedAs),
                  graph.add(`1000000`, Lang.math, Sense.integer, Origin.manual), Origin.manual, 1.0);
    graph.connect(graph.add(`milliard`, lang, Sense.numeral, Origin.manual), Role(Rel.definedAs),
                  graph.add(`1000000000`, Lang.math, Sense.integer, Origin.manual), Origin.manual, 1.0);
}

/** Learn Roman (Latin) Numerals.
    See also: https://en.wikipedia.org/wiki/Roman_numerals#Reading_Roman_numerals
*/
void learnRomanLatinNumerals(Graph graph)
{
    enum origin = Origin.manual;

    enum pairs = [tuple(`I`, `1`),
                  tuple(`V`, `5`),
                  tuple(`X`, `10`),
                  tuple(`L`, `50`),
                  tuple(`C`, `100`),
                  tuple(`D`, `500`),
                  tuple(`M`, `1000`)];
    foreach (pair; pairs)
    {
        graph.connect(graph.add(pair[0], Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                      graph.add(pair[1], Lang.math, Sense.integer, origin), origin, 1.0);
    }

    graph.connect(graph.add(`ūnus`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                  graph.add(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`ūna`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                  graph.add(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`ūnum`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                  graph.add(`1`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`duo`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                  graph.add(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`duae`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                  graph.add(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`duo`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                  graph.add(`2`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`trēs`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                  graph.add(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`trēs`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                  graph.add(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.add(`tria`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                  graph.add(`3`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`quattuor`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`4`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`quīnque`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`5`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`sex`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`6`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`septem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`7`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`octō`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`8`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`novem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`9`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`decem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`10`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`quīnquāgintā`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`Centum`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`Quīngentī`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`100`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.add(`Mīlle`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.add(`500`, Lang.math, Sense.integer, origin), origin, 1.0);
}

/** Learn English Ordinal Number Shorthands.
 */
void learnEnglishOrdinalShorthands(Graph graph)
{
    enum lang = Lang.en;
    enum pairs = [tuple(`1st`, `first`),
                  tuple(`2nd`, `second`),
                  tuple(`3rd`, `third`),
                  tuple(`4th`, `fourth`),
                  tuple(`5th`, `fifth`),
                  tuple(`6th`, `sixth`),
                  tuple(`7th`, `seventh`),
                  tuple(`8th`, `eighth`),
                  tuple(`9th`, `ninth`),
                  tuple(`10th`, `tenth`),
                  tuple(`11th`, `eleventh`),
                  tuple(`12th`, `twelfth`),
                  tuple(`13th`, `thirteenth`),
                  tuple(`14th`, `fourteenth`),
                  tuple(`15th`, `fifteenth`),
                  tuple(`16th`, `sixteenth`),
                  tuple(`17th`, `seventeenth`),
                  tuple(`18th`, `eighteenth`),
                  tuple(`19th`, `nineteenth`),
                  tuple(`20th`, `twentieth`),
                  tuple(`21th`, `twenty-first`),
                  tuple(`30th`, `thirtieth`),
                  tuple(`40th`, `fourtieth`),
                  tuple(`50th`, `fiftieth`),
                  tuple(`60th`, `sixtieth`),
                  tuple(`70th`, `seventieth`),
                  tuple(`80th`, `eightieth`),
                  tuple(`90th`, `ninetieth`),
                  tuple(`100th`, `one hundredth`),
                  tuple(`1000th`, `one thousandth`),
                  tuple(`1000000th`, `one millionth`),
                  tuple(`1000000000th`, `one billionth`)];
    foreach (pair; pairs)
    {
        const abbr = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.add(abbr, Lang.en, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal, Lang.en, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
        // variant spelling
        graph.connect(graph.add(abbr[0 .. $-2] ~ `:` ~ abbr[$-2 .. $],
                                  lang, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal,
                                  lang, Sense.numeralOrdinal, Origin.manual), Origin.manual, 0.5);
    }
}

/** Learn Swedish Ordinal Numbers.
 */
void learnSwedishOrdinalNumbers(Graph graph)
{
    enum lang = Lang.sv;
    enum pairs = [tuple(`1:a`, `första`),
                  tuple(`2:a`, `andra`),
                  tuple(`3:e`, `tredje`),
                  tuple(`4:e`, `fjärde`),
                  tuple(`5:e`, `femte`),
                  tuple(`6:e`, `sjätte`),
                  tuple(`7:e`, `sjunde`),
                  tuple(`8:e`, `åttonde`),
                  tuple(`9:e`, `nionde`),
                  tuple(`10:e`, `tionde`),
                  tuple(`11:e`, `elfte`),
                  tuple(`12:e`, `tolfte`),
                  tuple(`13:e`, `trettonde`),
                  tuple(`14:e`, `fjortonde`),
                  tuple(`15:e`, `femtonde`),
                  tuple(`16:e`, `sextonde`),
                  tuple(`17:e`, `sjuttonde`),
                  tuple(`18:e`, `artonde`),
                  tuple(`19:e`, `nittonde`),
                  tuple(`20:e`, `tjugonde`)];
    foreach (pair; pairs)
    {
        const abbr = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.add(abbr, Lang.en, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal, Lang.en, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn German Ordinal Numbers.
 */
void learnGermanOrdinalNumbers(Graph graph)
{
    enum lang = Lang.de;
    enum pairs = [tuple(`1.`, `erste`),
                  tuple(`2.`, `zweite`),
                  tuple(`3.`, `dritte`),
                  tuple(`4.`, `vierte`),
                  tuple(`5.`, `fünfte`),
                  tuple(`6.`, `sechste`),
                  tuple(`7.`, `siebte`),
                  tuple(`8.`, `achte`),
                  tuple(`9.`, `neunte`),
                  tuple(`10.`, `zehnte`),
                  tuple(`11.`, `elfte`),
                  tuple(`12.`, `zwölfte`)];
    foreach (pair; pairs)
    {
        const abbr = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.add(abbr, Lang.en, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal, Lang.en, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn French Ordinal Numbers.
 */
void learnFrenchOrdinalNumbers(Graph graph)
{
    enum lang = Lang.fr;
    enum pairs = [tuple(`1er`, `premier`),
                  tuple(`1re`, `premier`),
                  tuple(`1er`, `premiére`),
                  tuple(`1re`, `premiére`),
                  tuple(`2e`, `deuxième`),
                  tuple(`3e`, `troisième`),
                  tuple(`4e`, `quatrième`),
                  tuple(`5e`, `cinquième`),
                  tuple(`6e`, `sixième`),
                  tuple(`7e`, `septième`),
                  tuple(`8e`, `huitième`),
                  tuple(`9e`, `neuvième`),
                  tuple(`10e`, `dixième`)];
    foreach (pair; pairs)
    {
        const abbr = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.add(abbr, Lang.en, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal, Lang.en, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn English Fractions.
 */
void learnEnglishFractions(Graph graph)
{
    enum lang = Lang.en;
    enum pairs = [tuple(`1/2`, `one half`),
                  tuple(`1/3`, `one third`),
                  tuple(`1/4`, `one quarter`),
                  tuple(`1/5`, `one fifth`),
                  tuple(`1/6`, `one sixth`),
                  tuple(`1/7`, `one seventh`),
                  tuple(`1/8`, `one eighth`),
                  tuple(`1/9`, `one ninth`),
                  tuple(`1/10`, `one tenth`)];
    foreach (pair; pairs)
    {
        const fraction = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.add(fraction, Lang.math, Sense.numberRational, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal, Lang.en, Sense.numeralFraction, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn Swedish Fractions.
 */
void learnSwedishFractions(Graph graph)
{
    enum lang = Lang.sv;
    enum pairs = [tuple(`1/2`, `en halv`),
                  tuple(`1/3`, `en tredjedel`),
                  tuple(`1/4`, `en fjärdedel`),
                  tuple(`1/5`, `en femtedel`),
                  tuple(`1/6`, `en sjättedel`),
                  tuple(`1/7`, `en sjundedel`),
                  tuple(`1/8`, `en åttondedel`),
                  tuple(`1/9`, `en niondedel`),
                  tuple(`1/10`, `en tiondel`)];
    foreach (pair; pairs)
    {
        const fraction = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.add(fraction, Lang.math, Sense.numberRational, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal, Lang.en, Sense.numeralFraction, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn French Fractions.
 */
void learnFrenchFractions(Graph graph)
{
    enum lang = Lang.fr;
    enum pairs = [tuple(`1/2`, `un demi`),
                  tuple(`1/3`, `un tiers`),
                  tuple(`1/4`, `un quart`),
                  tuple(`1/5`, `un cinquième`),
                  tuple(`1/6`, `un sixième`),
                  tuple(`1/7`, `un septième`),
                  tuple(`1/8`, `un huitième`),
                  tuple(`1/9`, `un neuvième`),
                  tuple(`1/10`, `un dixième`)];
    foreach (pair; pairs)
    {
        const fraction = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.add(fraction, Lang.math, Sense.numberRational, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(ordinal, Lang.en, Sense.numeralFraction, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn Swedish Ordinal Shorthands.
 */
void learnSwedishOrdinalShorthands(Graph graph)
{
    enum lang = Lang.sv;
    enum pairs = [tuple(`1:a`, `första`),
                  tuple(`2:a`, `andra`),
                  tuple(`3:a`, `tredje`),
                  tuple(`4:e`, `fjärde`),
                  tuple(`5:e`, `femte`),
                  tuple(`6:e`, `sjätte`),
                  tuple(`7:e`, `sjunde`),
                  tuple(`8:e`, `åttonde`),
                  tuple(`9:e`, `nionde`),
                  tuple(`10:e`, `tionde`),
                  tuple(`11:e`, `elfte`),
                  tuple(`12:e`, `tolfte`),
                  tuple(`13:e`, `trettonde`),
                  tuple(`14:e`, `fjortonde`),
                  tuple(`15:e`, `femtonde`),
                  tuple(`16:e`, `sextonde`),
                  tuple(`17:e`, `sjuttonde`),
                  tuple(`18:e`, `artonde`),
                  tuple(`19:e`, `nittonde`),
                  tuple(`20:e`, `tjugonde`),
                  tuple(`21:a`, `tjugoförsta`),
                  tuple(`22:a`, `tjugoandra`),
                  tuple(`23:e`, `tjugotredje`),
                  // ..
                  tuple(`30:e`, `trettionde`),
                  tuple(`40:e`, `fyrtionde`),
                  tuple(`50:e`, `femtionde`),
                  tuple(`60:e`, `sextionde`),
                  tuple(`70:e`, `sjuttionde`),
                  tuple(`80:e`, `åttionde`),
                  tuple(`90:e`, `nittionde`),
                  tuple(`100:e`, `hundrade`),
                  tuple(`1000:e`, `tusende`),
                  tuple(`1000000:e`, `miljonte`)];
    foreach (pair; pairs)
    {
        graph.connect(graph.add(pair[0], lang, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.add(pair[1], lang, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
    }
}
