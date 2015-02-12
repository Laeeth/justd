module knet.lectures.verbs;

import std.stdio: writeln;

import knet.base;

void learnVerbs(Graph graph)
{
    writeln(`Reading Verbs ...`);
    graph.learnSwedishRegularVerbs();
    graph.learnSwedishIrregularVerbs();
    graph.learnEnglishVerbs();
    graph.learnVerbReversions();
}

void learnEnglishVerbs(Graph graph)
{
    writeln(`Reading English Verbs ...`);
    graph.learnEnglishIrregularVerbs();
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/verbs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `verb`, Sense.verb, Sense.noun, 1.0);
}

/** Learn English Irregular Verbs.
    TODO Move to irregular_verb.txt in format: bewas,werebeen
    TODO Merge with http://www.enchantedlearning.com/wordlist/irregularverbs.shtml
*/
void learnEnglishIrregularVerbs(Graph graph)
{
    writeln(`Reading English Irregular Verbs ...`);
    /* base form	past simple	past participle	3rd person singular	present participle / gerund */
    graph.learnEnglishIrregularVerb(`alight`, [`alit`, `alighted`], [`alit`, `alighted`]); // alights	alighting
    graph.learnEnglishIrregularVerb(`arise`, `arose`, `arisen`); // arises	arising
    graph.learnEnglishIrregularVerb(`awake`, `awoke`, `awoken`); // awakes	awaking
    graph.learnEnglishIrregularVerb(`be`, [`was`, `were`], `been`); // is	being
    graph.learnEnglishIrregularVerb(`bear`, `bore`, [`born`, `borne`]); // bears	bearing
    graph.learnEnglishIrregularVerb(`beat`, `beat`, `beaten`); // beats	beating
    graph.learnEnglishIrregularVerb(`become`, `became`, `become`); // becomes	becoming
    graph.learnEnglishIrregularVerb(`begin`, `began`, `begun`); // begins	beginning
    graph.learnEnglishIrregularVerb(`behold`, `beheld`, `beheld`); // beholds	beholding
    graph.learnEnglishIrregularVerb(`bend`, `bent`, `bent`); // bends	bending
    graph.learnEnglishIrregularVerb(`bet`, `bet`, `bet`); // bets	betting
    graph.learnEnglishIrregularVerb(`bid`, `bade`, `bidden`); // bids	bidding
    graph.learnEnglishIrregularVerb(`bid`, `bid`, `bid`); // bids	bidding
    graph.learnEnglishIrregularVerb(`bind`, `bound`, `bound`); // binds	binding
    graph.learnEnglishIrregularVerb(`bite`, `bit`, `bitten`); // bites	biting
    graph.learnEnglishIrregularVerb(`bleed`, `bled`, `bled`); // bleeds	bleeding
    graph.learnEnglishIrregularVerb(`blow`, `blew`, `blown`); // blows	blowing
    graph.learnEnglishIrregularVerb(`break`, `broke`, `broken`); // breaks	breaking
    graph.learnEnglishIrregularVerb(`breed`, `bred`, `bred`); // breeds	breeding
    graph.learnEnglishIrregularVerb(`bring`, `brought`, `brought`); // brings	bringing
    graph.learnEnglishIrregularVerb(`broadcast`, [`broadcast`, `broadcasted`], [`broadcast`, `broadcasted`]); // broadcasts	broadcasting
    graph.learnEnglishIrregularVerb(`build`, `built`, `built`); // builds	building
    graph.learnEnglishIrregularVerb(`burn`, [`burnt`, `burned`], [`burnt`, `burned`]); // burns	burning
    graph.learnEnglishIrregularVerb(`burst`, `burst`, `burst`); // bursts	bursting
    graph.learnEnglishIrregularVerb(`bust`, `bust`, `bust`); // busts	busting
    graph.learnEnglishIrregularVerb(`buy`, `bought`, `bought`); // buys	buying
    graph.learnEnglishIrregularVerb(`cast`, `cast`, `cast`); // casts	casting
    graph.learnEnglishIrregularVerb(`catch`, `caught`, `caught`); // catches	catching
    graph.learnEnglishIrregularVerb(`choose`, `chose`, `chosen`); // chooses	choosing
    graph.learnEnglishIrregularVerb(`clap`, [`clapped`, `clapt`], [`clapped`, `clapt`]); // claps	clapping
    graph.learnEnglishIrregularVerb(`cling`, `clung`, `clung`); // clings	clinging
    graph.learnEnglishIrregularVerb(`clothe`, [`clad`, `clothed`], [`clad`, `clothed`]); // clothes	clothing
    graph.learnEnglishIrregularVerb(`come`, `came`, `come`); // comes	coming
    graph.learnEnglishIrregularVerb(`cost`, `cost`, `cost`); // costs	costing
    graph.learnEnglishIrregularVerb(`creep`, `crept`, `crept`); // creeps	creeping
    graph.learnEnglishIrregularVerb(`cut`, `cut`, `cut`); // cuts	cutting
    graph.learnEnglishIrregularVerb(`dare`, [`dared`, `durst`], `dared`); // dares	daring
    graph.learnEnglishIrregularVerb(`deal`, `dealt`, `dealt`); // deals	dealing
    graph.learnEnglishIrregularVerb(`dig`, `dug`, `dug`); // digs	digging
    graph.learnEnglishIrregularVerb(`dive`, [`dived`, `dove`], `dived`); // dives	diving
    graph.learnEnglishIrregularVerb(`do`, `did`, `done`); // does	doing
    graph.learnEnglishIrregularVerb(`draw`, `drew`, `drawn`); // draws	drawing
    graph.learnEnglishIrregularVerb(`dream`, [`dreamt`, `dreamed`], [`dreamt`, `dreamed`]); // dreams	dreaming
    graph.learnEnglishIrregularVerb(`drink`, `drank`, `drunk`); // drinks	drinking
    graph.learnEnglishIrregularVerb(`drive`, `drove`, `driven`); // drives	driving
    graph.learnEnglishIrregularVerb(`dwell`, `dwelt`, `dwelt`); // dwells	dwelling
    graph.learnEnglishIrregularVerb(`eat`, `ate`, `eaten`); // eats	eating
    graph.learnEnglishIrregularVerb(`fall`, `fell`, `fallen`); // falls	falling
    graph.learnEnglishIrregularVerb(`feed`, `fed`, `fed`); // feeds	feeding
    graph.learnEnglishIrregularVerb(`feel`, `felt`, `felt`); // feels	feeling
    graph.learnEnglishIrregularVerb(`fight`, `fought`, `fought`); // fights	fighting
    graph.learnEnglishIrregularVerb(`find`, `found`, `found`); // finds	finding
    graph.learnEnglishIrregularVerb(`fit`, [`fit`, `fitted`], [`fit`, `fitted`]); // fits	fitting
    graph.learnEnglishIrregularVerb(`flee`, `fled`, `fled`); // flees	fleeing
    graph.learnEnglishIrregularVerb(`fling`, `flung`, `flung`); // flings	flinging
    graph.learnEnglishIrregularVerb(`fly`, `flew`, `flown`); // flies	flying
    graph.learnEnglishIrregularVerb(`forbid`, [`forbade`, `forbad`], `forbidden`); // forbids	forbidding
    graph.learnEnglishIrregularVerb(`forecast`, [`forecast`, `forecasted`], [`forecast`, `forecasted`]); // forecasts	forecasting
    graph.learnEnglishIrregularVerb(`foresee`, `foresaw`, `foreseen`); // foresees	foreseeing
    graph.learnEnglishIrregularVerb(`foretell`, `foretold`, `foretold`); // foretells	foretelling
    graph.learnEnglishIrregularVerb(`forget`, `forgot`, `forgotten`); // forgets	foregetting
    graph.learnEnglishIrregularVerb(`forgive`, `forgave`, `forgiven`); // forgives	forgiving
    graph.learnEnglishIrregularVerb(`forsake`, `forsook`, `forsaken`); // forsakes	forsaking
    graph.learnEnglishIrregularVerb(`freeze`, `froze`, `frozen`); // freezes	freezing
    graph.learnEnglishIrregularVerb(`frostbite`, `frostbit`, `frostbitten`); // frostbites	frostbiting
    graph.learnEnglishIrregularVerb(`get`, `got`, [`got`, `gotten`]); // gets	getting
    graph.learnEnglishIrregularVerb(`give`, `gave`, `given`); // gives	giving
    graph.learnEnglishIrregularVerb(`go`, `went`, [`gone`, `been`]); // goes	going
    graph.learnEnglishIrregularVerb(`grind`, `ground`, `ground`); // grinds	grinding
    graph.learnEnglishIrregularVerb(`grow`, `grew`, `grown`); // grows	growing
    graph.learnEnglishIrregularVerb(`handwrite`, `handwrote`, `handwritten`); // handwrites	handwriting
    graph.learnEnglishIrregularVerb(`hang`, [`hung`, `hanged`], [`hung`, `hanged`]); // hangs	hanging
    graph.learnEnglishIrregularVerb(`have`, `had`, `had`); // has	having
    graph.learnEnglishIrregularVerb(`hear`, `heard`, `heard`); // hears	hearing
    graph.learnEnglishIrregularVerb(`hide`, `hid`, `hidden`); // hides	hiding
    graph.learnEnglishIrregularVerb(`hit`, `hit`, `hit`); // hits	hitting
    graph.learnEnglishIrregularVerb(`hold`, `held`, `held`); // holds	holding
    graph.learnEnglishIrregularVerb(`hurt`, `hurt`, `hurt`); // hurts	hurting
    graph.learnEnglishIrregularVerb(`inlay`, `inlaid`, `inlaid`); // inlays	inlaying
    graph.learnEnglishIrregularVerb(`input`, [`input`, `inputted`], [`input`, `inputted`]); // inputs	inputting
    graph.learnEnglishIrregularVerb(`interlay`, `interlaid`, `interlaid`); // interlays	interlaying
    graph.learnEnglishIrregularVerb(`keep`, `kept`, `kept`); // keeps	keeping
    graph.learnEnglishIrregularVerb(`kneel`, [`knelt`, `kneeled`], [`knelt`, `kneeled`]); // kneels	kneeling
    graph.learnEnglishIrregularVerb(`knit`, [`knit`, `knitted`], [`knit`, `knitted`]); // knits	knitting
    graph.learnEnglishIrregularVerb(`know`, `knew`, `known`); // knows	knowing
    graph.learnEnglishIrregularVerb(`lay`, `laid`, `laid`); // lays	laying
    graph.learnEnglishIrregularVerb(`lead`, `led`, `led`); // leads	leading
    graph.learnEnglishIrregularVerb(`lean`, [`leant`, `leaned`], [`leant`, `leaned`]); // leans	leaning
    graph.learnEnglishIrregularVerb(`leap`, [`leapt`, `leaped`], [`leapt`, `leaped`]); // leaps	leaping
    graph.learnEnglishIrregularVerb(`learn`, [`learnt`, `learned`], [`learnt`, `learned`]); // learns	learning
    graph.learnEnglishIrregularVerb(`leave`, `left`, `left`); // leaves	leaving
    graph.learnEnglishIrregularVerb(`lend`, `lent`, `lent`); // lends	lending
    graph.learnEnglishIrregularVerb(`let`, `let`, `let`); // lets	letting
    graph.learnEnglishIrregularVerb(`lie`, `lay`, `lain`); // lies	lying
    graph.learnEnglishIrregularVerb(`light`, `lit`, `lit`); // lights	lighting
    graph.learnEnglishIrregularVerb(`lose`, `lost`, `lost`); // loses	losing
    graph.learnEnglishIrregularVerb(`make`, `made`, `made`); // makes	making
    graph.learnEnglishIrregularVerb(`mean`, `meant`, `meant`); // means	meaning
    graph.learnEnglishIrregularVerb(`meet`, `met`, `met`); // meets	meeting
    graph.learnEnglishIrregularVerb(`melt`, `melted`, [`molten`, `melted`]); // melts	melting
    graph.learnEnglishIrregularVerb(`mislead`, `misled`, `misled`); // misleads	misleading
    graph.learnEnglishIrregularVerb(`mistake`, `mistook`, `mistaken`); // mistakes	mistaking
    graph.learnEnglishIrregularVerb(`misunderstand`, `misunderstood`, `misunderstood`); // misunderstands	misunderstanding
    graph.learnEnglishIrregularVerb(`miswed`, [`miswed`, `miswedded`], [`miswed`, `miswedded`]); // misweds	miswedding
    graph.learnEnglishIrregularVerb(`mow`, `mowed`, `mown`); // mows	mowing
    graph.learnEnglishIrregularVerb(`overdraw`, `overdrew`, `overdrawn`); // overdraws	overdrawing
    graph.learnEnglishIrregularVerb(`overhear`, `overheard`, `overheard`); // overhears	overhearing
    graph.learnEnglishIrregularVerb(`overtake`, `overtook`, `overtaken`); // overtakes	overtaking
    graph.learnEnglishIrregularVerb(`partake`, `partook`, `partaken`);
    graph.learnEnglishIrregularVerb(`pay`, `paid`, `paid`); // pays	paying
    graph.learnEnglishIrregularVerb(`preset`, `preset`, `preset`); // presets	presetting
    graph.learnEnglishIrregularVerb(`prove`, `proved`, [`proven`, `proved`]); // proves	proving
    graph.learnEnglishIrregularVerb(`put`, `put`, `put`); // puts	putting
    graph.learnEnglishIrregularVerb(`quit`, `quit`, `quit`); // quits	quitting
    graph.learnEnglishIrregularVerb(`re-prove`, `re-proved`, `re-proven/re-proved`); // re-proves	re-proving
    graph.learnEnglishIrregularVerb(`read`, `read`, `read`); // reads	reading
    graph.learnEnglishIrregularVerb(`rend`, `rent`, `rent`);
    graph.learnEnglishIrregularVerb(`rid`, [`rid`, `ridded`], [`rid`, `ridded`]); // rids	ridding
    graph.learnEnglishIrregularVerb(`ride`, `rode`, `ridden`); // rides	riding
    graph.learnEnglishIrregularVerb(`ring`, `rang`, `rung`); // rings	ringing
    graph.learnEnglishIrregularVerb(`rise`, `rose`, `risen`); // rises	rising
    graph.learnEnglishIrregularVerb(`rive`, `rived`, [`riven`, `rived`]); // rives	riving
    graph.learnEnglishIrregularVerb(`run`, `ran`, `run`); // runs	running
    graph.learnEnglishIrregularVerb(`saw`, `sawed`, [`sawn`, `sawed`]); // saws	sawing
    graph.learnEnglishIrregularVerb(`say`, `said`, `said`); // says	saying
    graph.learnEnglishIrregularVerb(`see`, `saw`, `seen`); // sees	seeing
    graph.learnEnglishIrregularVerb(`seek`, `sought`, `sought`); // seeks	seeking
    graph.learnEnglishIrregularVerb(`sell`, `sold`, `sold`); // sells	selling
    graph.learnEnglishIrregularVerb(`send`, `sent`, `sent`); // sends	sending
    graph.learnEnglishIrregularVerb(`set`, `set`, `set`); // sets	setting
    graph.learnEnglishIrregularVerb(`sew`, `sewed`, [`sewn`, `sewed`]); // sews	sewing
    graph.learnEnglishIrregularVerb(`shake`, `shook`, `shaken`); // shakes	shaking
    graph.learnEnglishIrregularVerb(`shave`, `shaved`, [`shaven`, `shaved`]); // shaves	shaving
    graph.learnEnglishIrregularVerb(`shear`, [`shore`, `sheared`], [`shorn`, `sheared`]); // shears	shearing
    graph.learnEnglishIrregularVerb(`shed`, `shed`, `shed`); // sheds	shedding
    graph.learnEnglishIrregularVerb(`shine`, `shone`, `shone`); // shines	shining
    graph.learnEnglishIrregularVerb(`shoe`, `shod`, `shod`); // shoes	shoeing
    graph.learnEnglishIrregularVerb(`shoot`, `shot`, `shot`); // shoots	shooting
    graph.learnEnglishIrregularVerb(`show`, `showed`, `shown`); // shows	showing
    graph.learnEnglishIrregularVerb(`shrink`, `shrank`, `shrunk`); // shrinks	shrinking
    graph.learnEnglishIrregularVerb(`shut`, `shut`, `shut`); // shuts	shutting
    graph.learnEnglishIrregularVerb(`sing`, `sang`, `sung`); // sings	singing
    graph.learnEnglishIrregularVerb(`sink`, `sank`, `sunk`); // sinks	sinking
    graph.learnEnglishIrregularVerb(`sit`, `sat`, `sat`); // sits	sitting
    graph.learnEnglishIrregularVerb(`slay`, `slew`, `slain`); // slays	slaying
    graph.learnEnglishIrregularVerb(`sleep`, `slept`, `slept`); // sleeps	sleeping
    graph.learnEnglishIrregularVerb(`slide`, `slid`, [`slid`, `slidden`]); // slides	sliding
    graph.learnEnglishIrregularVerb(`sling`, `slung`, `slung`); // slings	slinging
    graph.learnEnglishIrregularVerb(`slink`, `slunk`, `slunk`); // slinks	slinking
    graph.learnEnglishIrregularVerb(`slit`, `slit`, `slit`); // slits	slitting
    graph.learnEnglishIrregularVerb(`smell`, [`smelt`, `smelled`], [`smelt`, `smelled`]); // smells	smelling
    graph.learnEnglishIrregularVerb(`sneak`, [`sneaked`, `snuck`], [`sneaked`, `snuck`]); // sneaks	sneaking
    graph.learnEnglishIrregularVerb(`soothsay`, `soothsaid`, `soothsaid`); // soothsays	soothsaying
    graph.learnEnglishIrregularVerb(`sow`, `sowed`, `sown`); // sows	sowing
    graph.learnEnglishIrregularVerb(`speak`, `spoke`, `spoken`); // speaks	speaking
    graph.learnEnglishIrregularVerb(`speed`, [`sped`, `speeded`], [`sped`, `speeded`]); // speeds	speeding
    graph.learnEnglishIrregularVerb(`spell`, [`spelt`, `spelled`], [`spelt`, `spelled`]); // spells	spelling
    graph.learnEnglishIrregularVerb(`spend`, `spent`, `spent`); // spends	spending
    graph.learnEnglishIrregularVerb(`spill`, [`spilt`, `spilled`], [`spilt`, `spilled`]); // spills	spilling
    graph.learnEnglishIrregularVerb(`spin`, [`span`, `spun`], `spun`); // spins	spinning
    graph.learnEnglishIrregularVerb(`spit`, [`spat`, `spit`], [`spat`, `spit`]); // spits	spitting
    graph.learnEnglishIrregularVerb(`split`, `split`, `split`); // splits	splitting
    graph.learnEnglishIrregularVerb(`spoil`, [`spoilt`, `spoiled`], [`spoilt`, `spoiled`]); // spoils	spoiling
    graph.learnEnglishIrregularVerb(`spread`, `spread`, `spread`); // spreads	spreading
    graph.learnEnglishIrregularVerb(`spring`, `sprang`, `sprung`); // springs	springing
    graph.learnEnglishIrregularVerb(`stand`, `stood`, `stood`); // stands	standing
    graph.learnEnglishIrregularVerb(`steal`, `stole`, `stolen`); // steals	stealing
    graph.learnEnglishIrregularVerb(`stick`, `stuck`, `stuck`); // sticks	sticking
    graph.learnEnglishIrregularVerb(`sting`, `stung`, `stung`); // stings	stinging
    graph.learnEnglishIrregularVerb(`stink`, `stank`, `stunk`); // stinks	stinking
    graph.learnEnglishIrregularVerb(`stride`, [`strode`, `strided`], `stridden`); // strides	striding
    graph.learnEnglishIrregularVerb(`strike`, `struck`, [`struck`, `stricken`]); // strikes	striking
    graph.learnEnglishIrregularVerb(`string`, `strung`, `strung`); // strings	stringing
    graph.learnEnglishIrregularVerb(`strip`, [`stript`, `stripped`], [`stript`, `stripped`]); // strips	stripping
    graph.learnEnglishIrregularVerb(`strive`, `strove`, `striven`); // strives	striving
    graph.learnEnglishIrregularVerb(`sublet`, `sublet`, `sublet`); // sublets	subletting
    graph.learnEnglishIrregularVerb(`sunburn`, [`sunburned`, `sunburnt`], [`sunburned`, `sunburnt`]); // sunburns	sunburning
    graph.learnEnglishIrregularVerb(`swear`, `swore`, `sworn`); // swears	swearing
    graph.learnEnglishIrregularVerb(`sweat`, [`sweat`, `sweated`], [`sweat`, `sweated`]); // sweats	sweating
    graph.learnEnglishIrregularVerb(`sweep`, [`swept`, `sweeped`], [`swept`, `sweeped`]); // sweeps	sweeping
    graph.learnEnglishIrregularVerb(`swell`, `swelled`, `swollen`); // swells	swelling
    graph.learnEnglishIrregularVerb(`swim`, `swam`, `swum`); // swims	swimming
    graph.learnEnglishIrregularVerb(`swing`, `swung`, `swung`); // swings	swinging
    graph.learnEnglishIrregularVerb(`take`, `took`, `taken`); // takes	taking
    graph.learnEnglishIrregularVerb(`teach`, `taught`, `taught`); // teaches	teaching
    graph.learnEnglishIrregularVerb(`tear`, `tore`, `torn`); // tears	tearing
    graph.learnEnglishIrregularVerb(`tell`, `told`, `told`); // tells	telling
    graph.learnEnglishIrregularVerb(`think`, `thought`, `thought`); // thinks	thinking
    graph.learnEnglishIrregularVerb(`thrive`, [`throve`, `thrived`], [`thriven`, `thrived`]); // thrives	thriving
    graph.learnEnglishIrregularVerb(`throw`, `threw`, `thrown`); // throws	throwing
    graph.learnEnglishIrregularVerb(`thrust`, `thrust`, `thrust`); // thrusts	thrusting
    graph.learnEnglishIrregularVerb(`tread`, `trod`, [`trodden`, `trod`]); // treads	treading
    graph.learnEnglishIrregularVerb(`undergo`, `underwent`, `undergone`); // undergoes	undergoing
    graph.learnEnglishIrregularVerb(`understand`, `understood`, `understood`); // understands	understanding
    graph.learnEnglishIrregularVerb(`undertake`, `undertook`, `undertaken`); // undertakes	undertaking
    graph.learnEnglishIrregularVerb(`upsell`, `upsold`, `upsold`); // upsells	upselling
    graph.learnEnglishIrregularVerb(`upset`, `upset`, `upset`); // upsets	upsetting
    graph.learnEnglishIrregularVerb(`vex`, [`vext`, `vexed`], [`vext`, `vexed`]); // vexes	vexing
    graph.learnEnglishIrregularVerb(`wake`, `woke`, `woken`); // wakes	waking
    graph.learnEnglishIrregularVerb(`wear`, `wore`, `worn`); // wears	wearing
    graph.learnEnglishIrregularVerb(`weave`, `wove`, `woven`); // weaves	weaving
    graph.learnEnglishIrregularVerb(`wed`, [`wed`, `wedded`], [`wed`, `wedded`]); // weds	wedding
    graph.learnEnglishIrregularVerb(`weep`, `wept`, `wept`); // weeps	weeping
    graph.learnEnglishIrregularVerb(`wend`, [`wended`, `went`], [`wended`, `went`]); // wends	wending
    graph.learnEnglishIrregularVerb(`wet`, [`wet`, `wetted`], [`wet`, `wetted`]); // wets	wetting
    graph.learnEnglishIrregularVerb(`win`, `won`, `won`); // wins	winning
    graph.learnEnglishIrregularVerb(`wind`, `wound`, `wound`); // winds	winding
    graph.learnEnglishIrregularVerb(`withdraw`, `withdrew`, `withdrawn`); // withdraws	withdrawing
    graph.learnEnglishIrregularVerb(`withhold`, `withheld`, `withheld`); // withholds	withholding
    graph.learnEnglishIrregularVerb(`withstand`, `withstood`, `withstood`); // withstands	withstanding
    graph.learnEnglishIrregularVerb(`wring`, `wrung`, `wrung`); // wrings	wringing
    graph.learnEnglishIrregularVerb(`write`, `wrote`, `written`); // writes	writing
    graph.learnEnglishIrregularVerb(`zinc`, [`zinced`, `zincked`], [`zinced`, `zincked`]); // zincs/zincks	zincking
    graph.learnEnglishIrregularVerb(`abide`, [`abode`, `abided`], [`abode`, `abided`, `abidden`]); // abides	abiding
}

/** Learn Swedish (Regular) Verbs.
 */
void learnSwedishRegularVerbs(Graph graph)
{
    graph.learnSwedishIrregularVerb(`kläd`, `kläda`, `kläder`, `klädde`, `klätt`);
    graph.learnSwedishIrregularVerb(`pryd`, `pryda`, `pryder`, `prydde`, `prytt`);
}

/** Learn Swedish (Irregular) Verbs.
 */
void learnSwedishIrregularVerbs(Graph graph)
{
    graph.learnSwedishIrregularVerb(`eka`, `eka`, `ekar`, `ekade`, `ekat`); // English:echo
    graph.learnSwedishIrregularVerb(`ge`, `ge`, `ger`, `gav`, `gett`);
    graph.learnSwedishIrregularVerb(`ge`, `ge`, `ger`, `gav`, `givit`);
    graph.learnSwedishIrregularVerb(`ange`, `ange`, `anger`, `angav`, `angett`);
    graph.learnSwedishIrregularVerb(`ange`, `ange`, `anger`, `angav`, `angivit`);
    graph.learnSwedishIrregularVerb(`anse`, `anse`, `anser`, `ansåg`, `ansett`);
    graph.learnSwedishIrregularVerb(`avgör`, `avgöra`, `avgör`, `avgjorde`, `avgjort`);
    graph.learnSwedishIrregularVerb(`avstå`, `avstå`, `avstår`, `avstod`, `avstått`);
    graph.learnSwedishIrregularVerb(`be`, `be`, `ber`, `bad`, `bett`);
    graph.learnSwedishIrregularVerb(`bestå`, `bestå`, `består`, `bestod`, `bestått`);
    graph.learnSwedishIrregularVerb([], [], `bör`, `borde`, `bort`);
    graph.learnSwedishIrregularVerb(`dra`, `dra`, `drar`, `drog`, `dragit`);
    graph.learnSwedishIrregularVerb([], `duga`, `duger`, `dög`, `dugit`); // TODO [`dög`, `dugde`]
    graph.learnSwedishIrregularVerb([], `duga`, `duger`, `dugde`, `dugit`);
    graph.learnSwedishIrregularVerb(`dyk`, `dyka`, `dyker`, `dök`, `dykit`); // TODO [`dök`, `dykte`]
    graph.learnSwedishIrregularVerb(`dyk`, `dyka`, `dyker`, `dykte`, `dykit`);
    graph.learnSwedishIrregularVerb(`dö`, `dö`, `dör`, `dog`, `dött`);
    graph.learnSwedishIrregularVerb(`dölj`, `dölja`, `döljer`, `dolde`, `dolt`);
    graph.learnSwedishIrregularVerb(`ersätt`, `ersätta`, `ersätter`, `ersatte`, `ersatt`);
    graph.learnSwedishIrregularVerb(`fortsätt`, `fortsätta`, `fortsätter`, `fortsatte`, `fortsatt`);
    graph.learnSwedishIrregularVerb(`framstå`, `framstå`, `framstår`, `framstod`, `framstått`);
    graph.learnSwedishIrregularVerb(`få`, `få`, `får`, `fick`, `fått`);
    graph.learnSwedishIrregularVerb(`förstå`, `förstå`, `förstår`, `förstod`, `förstått`);
    graph.learnSwedishIrregularVerb(`förutsätt`, `förutsätta`, `förutsätter`, `förutsatte`, `förutsatt`);
    graph.learnSwedishIrregularVerb(`gläd`, `glädja`, `gläder`, `gladde`, `glatt`);
    graph.learnSwedishIrregularVerb(`gå`, `gå`, `går`, `gick`, `gått`);
    graph.learnSwedishIrregularVerb(`gör`, `göra`, `gör`, `gjorde`, `gjort`);
    graph.learnSwedishIrregularVerb(`ha`, `ha`, `har`, `hade`, `haft`);
    graph.learnSwedishIrregularVerb([], `heta`, `heter`, `hette`, `hetat`);
    graph.learnSwedishIrregularVerb([], `ingå`, `ingår`, `ingick`, `ingått`);
    graph.learnSwedishIrregularVerb(`inse`, `inse`, `inser`, `insåg`, `insett`);
    graph.learnSwedishIrregularVerb(`kom`, `komma`, `kommer`, `kom`, `kommit`);
    graph.learnSwedishIrregularVerb([], `kunna`, `kan`, `kunde`, `kunnat`);
    graph.learnSwedishIrregularVerb(`le`, `le`, `ler`, `log`, `lett`);
    graph.learnSwedishIrregularVerb(`lev`, `leva`, `lever`, `levde`, `levt`);
    graph.learnSwedishIrregularVerb(`ligg`, `ligga`, `ligger`, `låg`, `legat`);
    graph.learnSwedishIrregularVerb(`lägg`, `lägga`, `lägger`, `la`, `lagt`);
    graph.learnSwedishIrregularVerb(`missförstå`, `missförstå`, `missförstår`, `missförstod`, `missförstått`);
    graph.learnSwedishIrregularVerb([], [], `måste`, `var tvungen`, `varit tvungen`);
    graph.learnSwedishIrregularVerb(`se`, `se`, `ser`, `såg`, `sett`);
    graph.learnSwedishIrregularVerb(`skilj`, `skilja`, `skiljer`, `skilde`, `skilt`);
    graph.learnSwedishIrregularVerb([], [], `ska`, `skulle`, []);
    graph.learnSwedishIrregularVerb(`smaksätt`, `smaksätta`, `smaksätter`, `smaksatte`, `smaksatt`);
    graph.learnSwedishIrregularVerb(`sov`, `sova`, `sover`, `sov`, `sovit`);
    graph.learnSwedishIrregularVerb(`sprid`, `sprida`, `sprider`, `spred`, `spridit`);
    graph.learnSwedishIrregularVerb(`stjäl`, `stjäla`, `stjäl`, `stal`, `stulit`);
    graph.learnSwedishIrregularVerb(`stå`, `stå`, `står`, `stod`, `stått`);
    graph.learnSwedishIrregularVerb(`stöd`, `stödja`, `stöder`, `stödde`, `stött`);
    graph.learnSwedishIrregularVerb(`svälj`, `svälja`, `sväljer`, `svalde`, `svalt`);
    graph.learnSwedishIrregularVerb(`säg`, `säga`, `säger`, `sa`, `sagt`);
    graph.learnSwedishIrregularVerb(`sälj`, `sälja`, `säljer`, `sålde`, `sålt`);
    graph.learnSwedishIrregularVerb(`sätt`, `sätta`, `sätter`, `satte`, `satt`);
    graph.learnSwedishIrregularVerb(`ta`, `ta`, `tar`, `tog`, `tagit`);
    graph.learnSwedishIrregularVerb(`tillsätt`, `tillsätta`, `tillsätter`, `tillsatte`, `tillsatt`);
    graph.learnSwedishIrregularVerb(`umgås`, `umgås`, `umgås`, `umgicks`, `umgåtts`);
    graph.learnSwedishIrregularVerb(`uppge`, `uppge`, `uppger`, `uppgav`, `uppgivit`);
    graph.learnSwedishIrregularVerb(`utgå`, `utgå`, `utgår`, `utgick`, `utgått`);
    graph.learnSwedishIrregularVerb(`var`, `vara`, `är`, `var`, `varit`);
    graph.learnSwedishIrregularVerb([], `veta`, `vet`, `visste`, `vetat`);
    graph.learnSwedishIrregularVerb(`vik`, `vika`, `viker`, `vek`, `vikt`);
    graph.learnSwedishIrregularVerb([], `vilja`, `vill`, `ville`, `velat`);
    graph.learnSwedishIrregularVerb(`välj`, `välja`, `väljer`, `valde`, `valt`);
    graph.learnSwedishIrregularVerb(`vänj`, `vänja`, `vänjer`, `vande`, `vant`);
    graph.learnSwedishIrregularVerb(`väx`, `växa`, `växer`, `växte`, `växt`);
    graph.learnSwedishIrregularVerb(`återge`, `återge`, `återger`, `återgav`, `återgivit`);
    graph.learnSwedishIrregularVerb(`översätt`, `översätta`, `översätter`, `översatte`, `översatt`);
    graph.learnSwedishIrregularVerb(`tyng`, `tynga`, `tynger`, `tyngde`, `tyngt`);
    graph.learnSwedishIrregularVerb(`glöm`, `glömma`, `glömmer`, `glömde`, `glömt`);
    graph.learnSwedishIrregularVerb(`förgät`, `förgäta`, `förgäter`, `förgat`, `förgätit`);

    // TODO Allow alternatives for all arguments
    static if (false)
    {
        graph.learnSwedishIrregularVerb(`ids`, `idas`, [`ids`, `ides`], `iddes`, [`itts`, `idats`]);
        graph.learnSwedishIrregularVerb(`gitt`, `gitta;1`, `gitter`, [`gitte`, `get`, `gat`], `gittat;1`);
    }

}

/// Learn Verb Reversions.
void learnVerbReversions(Graph graph)
{
    // TODO Copy all from krels.toHuman
    graph.learnVerbReversion(`is a`, `can be`, Lang.en);
    graph.learnVerbReversion(`leads to`, `can infer`, Lang.en);
    graph.learnVerbReversion(`is part of`, `contains`, Lang.en);
    graph.learnVerbReversion(`is member of`, `has member`, Lang.en);
}
