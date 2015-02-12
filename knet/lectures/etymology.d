module knet.lectures.etymology;

import knet.base;

/// Learn Etymologically Derived Froms.
void learnEtymologicallyDerivedFroms(Graph graph)
{
    graph.learnEtymologicallyDerivedFrom(`holiday`, Lang.en, Sense.noun,
                                         `holy day`, Lang.en, Sense.noun);
    graph.learnEtymologicallyDerivedFrom(`juletide`, Lang.en, Sense.noun,
                                         `juletid`, Lang.sv, Sense.noun);
    graph.learnEtymologicallyDerivedFrom(`smorgosbord`, Lang.en, Sense.noun,
                                         `smörgåsbord`, Lang.sv, Sense.noun);
    graph.learnEtymologicallyDerivedFrom(`förgätmigej`, Lang.sv, Sense.noun,
                                         `förgät mig ej`, Lang.sv, Sense.unknown); // TODO uppmaning
    graph.learnEtymologicallyDerivedFrom(`OK`, Lang.en, Sense.unknown,
                                         `Old Kinderhook`, Lang.en, Sense.unknown);
}
