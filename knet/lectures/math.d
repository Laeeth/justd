module knet.lectures.math;

import knet.base;

void learnMath(Graph graph)
{
    const origin = Origin.manual;

    graph.connect(graph.store(`π`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.translationOf),
                  graph.store(`pi`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                  origin, 1.0);
    graph.connect(graph.store(`e`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.translationOf),
                  graph.store(`e`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                  origin, 1.0);

    /// http://www.geom.uiuc.edu/~huberty/math5337/groupe/digits.html
    graph.connect(graph.store(`π`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.definedAs),
                  graph.store(`3.14159265358979323846264338327950288419716939937510`,
                              Lang.math, Sense.decimal, origin),
                  origin, 1.0);

    graph.connect(graph.store(`e`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.definedAs),
                  graph.store(`2.71828182845904523536028747135266249775724709369995`,
                              Lang.math, Sense.decimal, origin),
                  origin, 1.0);

    graph.learnMto1(Lang.en, [`quaternary`, `quinary`, `senary`, `octal`,
                              `decimal`, `duodecimal`, `vigesimal`,
                              `quadrovigesimal`, `duotrigesimal`, `sexagesimal`, `octogesimal`],
                    Role(Rel.hasProperty, true), `counting system`, Sense.adjective, Sense.noun, 1.0);

    graph.learnQuantifiers();

    graph.learnNumerals();
}

/// Learn Quantifiers.
void learnQuantifiers(Graph graph)
{
    const origin = Origin.manual;

    enum words = [`all`, `any`, `both`, `each`, `enough`, `every`,
                  `few`, `a few`, `fewer`, `fewest`
                  `little`, `a little`, `less`,
                  `lots of`, `a lot of,`
                  `many`, `more`, `no`, `none`, `several`, `some`];

    foreach (word; words)
    {
        graph.connect(graph.store(word, Lang.en, Sense.quantifier, origin),
                      Role(Rel.instanceOf),
                      graph.store(`quantifier`, Lang.en, Sense.integer, origin),
                      origin, 1.0);
    }
}

/// Learn Numerals (Groupings/Aggregates) (MÄngdmått)
void learnNumerals(Graph graph)
{
    graph.learnRomanLatinNumerals();

    const origin = Origin.manual;

    graph.connect(graph.store(`single`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`1`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`pair`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`2`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`duo`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`2`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`triple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`3`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`quadruple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`4`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`quintuple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`5`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`sextuple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`6`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`septuple`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`7`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    // Greek Numbering
    // TODO Also Latin?
    graph.connect(graph.store(`tetra`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`4`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`penta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`5`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hexa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`6`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hepta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`7`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`octa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`8`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`nona`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`9`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`deca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`10`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hendeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`11`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`dodeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`12`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`trideca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`13`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`tetradeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`14`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`pentadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`15`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hexadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`16`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`heptadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`17`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`octadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`18`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`enneadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`19`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`icosa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`20`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.learnEnglishOrdinalShorthands();
    graph.learnSwedishOrdinalShorthands();

    // Aggregate
    graph.connect(graph.store(`dozen`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`12`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`baker's dozen`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`13`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`tjog`, Lang.sv, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`20`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`flak`, Lang.sv, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`24`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`skock`, Lang.sv, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`60`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    graph.connectMto1(graph.store([`dussin`, `tolft`], Lang.sv, Sense.numeral, origin),
                      Role(Rel.definedAs),
                      graph.store(`12`, Lang.math, Sense.integer, origin),
                      origin, 1.0);

    graph.connect(graph.store(`gross`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`144`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
    graph.connect(graph.store(`gross`, Lang.sv, Sense.numeral, origin), // TODO Support [Lang.en, Lang.sv]
                  Role(Rel.definedAs),
                  graph.store(`144`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    graph.connect(graph.store(`small gross`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`120`, Lang.math, Sense.integer, origin),
                  origin, 1.0);

    graph.connect(graph.store(`great gross`, Lang.en, Sense.numeral, origin),
                  Role(Rel.definedAs),
                  graph.store(`1728`, Lang.math, Sense.integer, origin),
                  origin, 1.0);
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
        graph.connect(graph.store(pair[0], Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                      graph.store(pair[1], Lang.math, Sense.integer, origin), origin, 1.0);
    }

    graph.connect(graph.store(`ūnus`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                  graph.store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`ūna`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                  graph.store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`ūnum`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                  graph.store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`duo`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                  graph.store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`duae`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                  graph.store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`duo`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                  graph.store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`trēs`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                  graph.store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`trēs`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                  graph.store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`tria`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                  graph.store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`quattuor`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`4`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`quīnque`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`5`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`sex`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`6`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`septem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`7`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`octō`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`8`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`novem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`9`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`decem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`10`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`quīnquāgintā`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`Centum`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`Quīngentī`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`100`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`Mīlle`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                  graph.store(`500`, Lang.math, Sense.integer, origin), origin, 1.0);
}

/** Learn English Ordinal Number Shorthands.
 */
void learnEnglishOrdinalShorthands(Graph graph)
{
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
        graph.connect(graph.store(abbr, Lang.en, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.store(ordinal, Lang.en, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
        graph.connect(graph.store(abbr[0 .. $-2] ~ `:` ~ abbr[$-2 .. $],
                                  Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.store(ordinal,
                                  Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 0.5);
    }
}

/** Learn Swedish Ordinal Shorthands.
 */
void learnSwedishOrdinalShorthands(Graph graph)
{
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
        graph.connect(graph.store(pair[0], Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                      graph.store(pair[1], Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
    }
}
