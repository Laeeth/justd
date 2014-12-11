/*
  UFCS: Unifor Call Syntax
  IFTI: Implicit Function Template Instantiation
  AA: Associative Array
*/

/** Solar System */
enum SolarSystem
{
    solo_star,
    binary_stars,
    eclipsing_binary,
    giant_star
}
/* TODO: HABITABLE CLASS M PLANETS:0	HABITABLE CLASS M PLANETS:1	HABITABLE CLASS M PLANETS:TWO OR MORE */

/** Planetary Classification */
enum PlanetaryClassification
{
    planetoid_moon,
    classD = planetoid_moon,

    pressure_dome,
    classK = pressure_dome,

    vegetation,
    classL = vegetation,

    earth,
    classM = earth,
}

enum Map
{
    pangea,
    continents,
    archipelagos, islands = archipelagos
}

enum Climate
{
    cold, hot, dry, wet
}

enum Topography
{
    mountain, plain, valley, swamp,
    trench, beach, coast, river, delta,
    ocean, bay, lake, pond,
}

alias TopographyProbs = double[Topography]; // AA

enum Life
{
    flora, fauna, creatures_with_iq
}

alias LifeProbs = double[Life]; // AA

enum Society
{
    clan, village, city, metropolis
}

enum Nation
{
    zero, one, two, multi
}

enum Technology
{
    gathering_hunting,
    material_processing,
    synthetic,
    biology
}

enum Religion
{
    elements, polytheism, montheism, philosophic
}

enum Government
{
    dictatorship, monarchy, republic, police_military_state
}

enum Law_And_Order
{
    restrictions, punishment, preventing_system, rehabilitation
}

enum ResourceDistribution
{
    healthcare, education, infrastructure, military
}

enum TradingSystem
{
    business, currency, natural_resources, technical_resources
}

enum ArchitectureFunction
{
    defensive, offensive, maintenance, construction
}

enum ArchitectureAesthetics
{
    power, education, navigation, art_style
}

enum LocalBusinessAndFacilities
{
    product, service, social
}

enum PlacesOfGathering
{
    public_, private_, educational, entertainment
}

/*  */
/* DAY CYCLE	GRAVITY	ATMOSPHERE	FLOOD AND TIDE */

/* enum PlanetSpecificatoins */
/* { */
/*     day_cycle, */
/* } */

import std.stdio, std.range, std.algorithm, std.string, std.conv, std.random, std.traits, std.typetuple;

void input(T)(ref T x,
              ref Random gen,
              string typeName = [])
{
    enum N = T.stringof;
    if (typeName.empty)
        typeName = N;

    write("$ Enter ", typeName,  " (empty to randomize): ");
    stdout.flush; // prompt

    auto line = readln();
    auto fixedLine = line.strip;
    if (fixedLine.empty) // UFCS
    {
        static if (isFloatingPoint!T)
        {
            x = uniform01!T(gen);
        }
        else
        {
            x = uniform!T(gen); // IFTI
        }
        writeln("> Randomized ", typeName, " to ", x);
    }
    else
    {
        x = fixedLine.to!T;
        writeln("> You entered ", fixedLine, " which was decode to ", x);
    }
}

import etc.linux.memoryerror;

int main(string[] args)
{
    auto ran = Random(unpredictableSeed);

    SolarSystem solarSystem;
    input(solarSystem, ran);

    PlanetaryClassification planetaryClassification;
    input(planetaryClassification, ran);

    Map map;
    input(map, ran);

    Climate climate;
    input(climate, ran);

    /* uint dayCycle; */
    /* input(dayCycle); */

    /* TODO functionize */
    TopographyProbs topographyProbs;
    foreach (key; EnumMembers!Topography) // TODO deduce key type from TopographyProbs
    {
        double prob;
        input(prob, ran, key.to!string);
        topographyProbs[key] = prob;
    }

    /* TODO functionize */
    LifeProbs lifeProbs;
    foreach (key; EnumMembers!Life) // TODO deduce key type from LifeProbs
    {
        double prob;
        input(prob, ran, key.to!string);
        lifeProbs[key] = prob;
    }

    foreach (type; TypeTuple!(Society,
                              Nation,
                              Technology,
                              Religion,
                              Government,
                              Law_And_Order,
                              ResourceDistribution,
                              TradingSystem,
                              ArchitectureFunction,
                              ArchitectureAesthetics,
                              LocalBusinessAndFacilities,
                              PlacesOfGathering))
    {
        enum code = "{" ~ type.stringof ~ " society; input(society, ran);" ~ "}";
        mixin(code);
    }

    return 0;
}

/* GUILDS & UNIONS */
/* MEMBERSHIP	ORGANIZATIONAL STRUCTRE	HIDDEN	WELL-KNOWN */
/* SERVICE	PRODUCTION	POLITICAL	POWER */

/* NATIONAL APPROACH */
/* MILITARISTIC	TRADE	DIPLOMATIC */

/* NATIONAL ALLIGNMENT */
/* FRIENDLY	NEUTRAL	HOSTILE */

/* NATIONAL PRIDE */
/* DOMINATE	SUBMISSIVE	NEUTRAL */

/* STATE OF NATION */
/* FLOORISHING & BOOMING		TIME OF CRISIS */

/* INTERNAL CONFLICT */
/* CIVIL-WAR	MILITARY COUPE	CORPORATIONAL WAR	CONTIMATION */

/* EXTERNAL CONFLICT */
/* INVASION	POLITICAL	ECONOMICAL	CULTURAL */

/* POSITIVE OUTCOME */
/* LAND GAIN	RESOURCES	TECHNOLOGY	CULTURAL */
/* ECONOMICAL	PEOPLE	DIPLOMATIC	POLITICAL */

/* NEGATIVE OUTCOME */
/* LAND LOSS	RESOURCE LOSS	SCIENTIFIC SETBACK	CHANGE OF CULTURAL */
/* ECONOMICAL CRISIS	DEATH & DISEASE	DIPLOMATIC SETBACK	POLITICAL CRISIS */

/* SOCIAL DYNAMICS */
/* DIVERSED	TOLERANT	UNDIVERSIFIED */

/* SOCIAL CLASS */
/* HIGH SOCIETY	MIDDLE CLASS		POOR */

/* IMPORTANT CUSTOM & HOLIDAYS */
/* RELGIOUS	HISTORICAL	POLITICAL	ENTERTAINMENT */
/* NATIONAL	REGIONAL	LOCAL	FAMILY */

/* EDUCATIONAL SYSTEM */
/* PUBLIC EDUCATION SYSTEM	PRIVATE EDUCATION SYSTEM	COMBINATIONAL	SELECTIVE */
/* WORD OF MOUTH	BOOKS	INSTITUTES	SCHOOLS */

/* GENERAL LEVEL OF EDUCATIONAL */
/* NON-EXISTENT	ILLITERATE	LITERATE	PRE-SCHOOL */
/* ELEMANTARY	HIGHER	SPECIALISTS	SCIENTISTS */

/* "EXEPCTIONAL POWERS" */
/* NON-EXISTENT	VERY RARE	UNCOMMON	COMMON / FREQUENT */

/* LEGAL STATUS OF "POWERS" */
/* ILLEGAL		RESTRICTED OF USE	ALLOWED */

/* INSUTIONS / SCHOOLS OF "POWERS" */
/* NON-EXISTENT	VERY RARE	UNCOMMON	COMMON / FREQUENT */

/* GENERAL ATTITUDE TOWARDS "POWERS" */
/* DESPISED	TREATED WITH SUSPICION	NEUTRAL	ADMIRATION */

/* IMPORTANT LEADERS */
/* POLITICAL	ECONOMICAL	MILITARISTIC	ENTERTAINMENT */
/* RELIGIOUS	SOCIAL	DIPLOMATIC	GUILDS & UNIONS */

/* ALLIES & ENEMIES */
/* NATION	TRADE	POLITICAL	CORPORTATION */

/* MEANS OF COMMUNICATION */
/* BODY LANGUAGE	VERBAL	MENTAL	BINARY CODE */

/* HISTORICAL MILESTONES */
/* SOCIAL	SCIENTIFIC	RELIGIOUS	WARFARE */
