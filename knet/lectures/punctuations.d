module knet.lectures.punctuations;

import knet.base;

void learnPunctuation(Graph graph)
{
    const origin = Origin.manual;

    graph.connect(graph.add(`:`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`colon`,
                              Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.add(`;`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`semicolon`,
                              Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connectMto1(graph.add([`,`, `،`, `、`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add(`comma`,
                                  Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMtoN(graph.add([`/`, `⁄`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add([`slash`, `stroke`, `solidus`],
                                  Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connect(graph.add(`-`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`hyphen`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.add(`-`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`hyphen-minus`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.add(`?`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`question mark`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.add(`!`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`exclamation mark`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect1toM(graph.add(`.`, Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add([`full stop`, `period`], Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.add([`’`, `'`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add(`apostrophe`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.add([`‒`, `–`, `—`, `―`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add(`dash`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.add([`‘’`, `“”`, `''`, `""`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add(`quotation marks`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.add([`…`, `...`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add(`ellipsis`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connect(graph.add(`()`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`parenthesis`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.add(`{}`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.add(`curly braces`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connectMto1(graph.add([`[]`, `()`, `{}`, `⟨⟩`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.add(`brackets`, Lang.en, Sense.noun, origin),
                      origin, 1.0);
}
