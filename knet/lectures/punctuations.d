module knet.lectures.punctuations;

import knet.base;

void learnPunctuation(Graph graph)
{
    const origin = Origin.manual;

    graph.connect(graph.store(`:`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`colon`,
                              Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`;`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`semicolon`,
                              Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connectMto1(graph.store([`,`, `،`, `、`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`comma`,
                                  Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMtoN(graph.store([`/`, `⁄`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store([`slash`, `stroke`, `solidus`],
                                  Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connect(graph.store(`-`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`hyphen`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`-`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`hyphen-minus`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`?`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`question mark`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`!`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`exclamation mark`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect1toM(graph.store(`.`, Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store([`full stop`, `period`], Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`’`, `'`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`apostrophe`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`‒`, `–`, `—`, `―`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`dash`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`‘’`, `“”`, `''`, `""`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`quotation marks`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`…`, `...`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`ellipsis`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connect(graph.store(`()`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`parenthesis`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`{}`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`curly braces`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connectMto1(graph.store([`[]`, `()`, `{}`, `⟨⟩`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`brackets`, Lang.en, Sense.noun, origin),
                      origin, 1.0);
}
