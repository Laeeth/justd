/** Porter stemming algorithm */
module stemming;

import std.algorithm: endsWith, canFind;
import std.range: empty;
import std.traits: isSomeString;

import predicates: of;
import grammars: isEnglishVowel, isSwedishVowel, isSwedishConsonant, isEnglishConsonant;
import skip_ex: skipOverBack;

public class Stemmer(S) if (isSomeString!S)
{
    /**
     * In stem(p,i,j), p is a char pointer, and the string to be stemmed
     * is from p[i] to p[j] inclusive. Typically i is zero and j is the
     * offset to the last character of a string, (p[j+1] == '\0'). The
     * stemmer adjusts the characters p[i] ... p[j] and returns the new
     * end-point of the string, k. Stemming never increases word length, so
     * i <= k <= j. To turn the stemmer into a module, declare 'stem' as
     * extern, and delete the remainder of this file.
     */
    public S stem(S p)
    {
        _b = p;
        _k = p.length - 1;
        _k0 = 0;

        /** strings of length 1 or 2 don't go through the stemming process,
         * although no mention is made of this in the published
         * algorithm. Remove the line to match the published algorithm.
         */
        if (_k <= _k0 + 1)
            return _b;

        step1ab();
        step1c();
        step2();
        step3();
        step4();
        step5();
        return _b[_k0 .. _k + 1];

    }

private:
    S _b;			// buffer for the word
    ptrdiff_t _k = 0;
    ptrdiff_t _k0 = 0;
    ptrdiff_t _j = 0;       // offset within the string

    /**
     * cons returns true, if b[i] is a consonant
     */
    bool isConsonant(ptrdiff_t i)
    {
        if (_b[i].isEnglishVowel)
            return false;
        if (_b[i] == 'y')
        {
            if (i == _k0)
            {
                return true;
            }
            else
            {
                return !isConsonant(i - 1);
            }
        }
        return true;
    }

    /** Return the number of consonant sequences between k0 and j.
     * if c is a consonant sequence and v a vowel sequence, and <..>
     * indicates arbitrary presence,
     *
     * <c><v>       gives 0
     * <c>vc<v>     gives 1
     * <c>vcvc<v>   gives 2
     * <c>vcvcvc<v> gives 3
     *
     */
    size_t m()
    {
        ptrdiff_t n = 0;
        ptrdiff_t i = _k0;

        while (true)
        {
            if (i > _j)
            {
                return n;
            }
            if (!isConsonant(i))
            {
                break;
            }
            i++;
        }
        i++;
        while (true)
        {
            while (true)
            {
                if (i > _j)
                {
                    return n;
                }
                if (isConsonant(i))
                {
                    break;
                }
                i++;
            }
            i++;
            n++;
            while (true)
            {
                if (i > _j)
                {
                    return n;
                }
                if (!isConsonant(i))
                {
                    break;
                }
                i++;
            }
            i++;
        }
    }

    /** Returns true if k0...j contains a vowel. */
    bool hasVowelInStem()
    {
        for (ptrdiff_t i = _k0; i < _j + 1; i++)
        {
            if (!isConsonant(i))
                return true;
        }
        return false;
    }

    /** Returns true if j, j-1 contains a double consonant
     */
    bool doublec(ptrdiff_t j)
    {
        if (j < (_k0 + 1))
            return false;
        if (_b[j] != _b[j-1])
            return false;
        return isConsonant(j);
    }

    /** Returns true if i-2,i-1,i has the form consonant - vowel - consonant
     * and also if the second c is not w,x or y. this is used when trying to
     * restore an e at the end of a short  e.g.
     *
     *    cav(e), lov(e), hop(e), crim(e), but
     *    snow, box, tray.
     *
     */
    bool cvc(ptrdiff_t i)
    {
        if (i < (_k0 + 2) || !isConsonant(i) || isConsonant(i-1) || !isConsonant(i-2))
            return false;
        if (_b[i] == 'w' || _b[i] == 'x' || _b[i] == 'y')
            return false;
        return true;
    }

    /** Return true if k0,...k endsWith with the string s.
     */
    bool endsWith(S)(S s) if (isSomeString!S)
    {
        const len = s.length;

        if (s[len - 1] != _b[_k])
            return false;
        if (len > (_k - _k0 + 1))
            return false;

        const a = _k - len + 1;
        const b = _k + 1;

        if (_b[a..b] != s)
        {
            return false;
        }
        _j = _k - len;

        return true;
    }

    /** Sets (j+1),...k to the characters in the string s, readjusting k. */
    void setto(S)(S s) if (isSomeString!S)
    {
        _b = _b[0.._j+1] ~ s ~ _b[_j + s.length + 1 .. _b.length];
        _k = _j + s.length;
    }

    /** Used further down. */
    void r(S)(S s) if (isSomeString!S)
    {
        if (m() > 0)
            setto(s);
    }

    /** Gets rid of plurals and -ed or -ing. e.g. */
    void step1ab()
    {
        if (_b[_k] == 's')
        {
            if (endsWith("sses"))
            {
                _k = _k - 2;
            }
            else if (endsWith("ies"))
            {
                setto("i");
            }
            else if (_b[_k - 1] != 's')
            {
                _k--;
            }
        }
        if (endsWith("eed"))
        {
            if (m() > 0)
                _k--;
        }
        else if ((endsWith("ed") || endsWith("ing")) && hasVowelInStem())
        {
            _k = _j;
            if (endsWith("at"))
            {
                setto("ate");
            }
            else if (endsWith("bl"))
            {
                setto("ble");
            }
            else if (endsWith("iz"))
            {
                setto("ize");
            }
            else if (doublec(_k))
            {
                _k--;
                if (_b[_k] == 'l' || _b[_k] == 's' || _b[_k] == 'z')
                    _k++;
            }
            else if (m() == 1 && cvc(_k))
            {
                setto("e");
            }
        }
    }

    /**
     * step1c() turns terminal y to i when there is another vowel in the stem.
     */
    void step1c()
    {
        if (endsWith("y") && hasVowelInStem())
        {
            _b = _b[0.._k] ~ 'i' ~ _b[_k+1 .. _b.length];
        }
    }

    /**
     * step2() maps double suffices to single ones.
     * so -ization (= -ize plus -ation) maps to -ize etc. note that the
     * string before the suffix must give m() > 0.*
     */
    void step2()
    {
        if (_b[_k - 1] == 'a')
        {
            if (endsWith("ational"))
                r("ate");
            else if (endsWith("tional"))
                r("tion");
        }
        else if (_b[_k - 1] == 'c')
        {
            if (endsWith("enci"))
                r("ence");
            else if (endsWith("anci"))
                r("ance");
        }
        else if (_b[_k - 1] == 'e')
        {
            if (endsWith("izer"))
                r("ize");
        }
        else if (_b[_k - 1] == 'l')
        {
            if (endsWith("bli"))
                r("ble");
            /* --DEPARTURE--
             * To match the published algorithm, replace this phrase with
             * if (endsWith("abli"))
             *	   r("able");
             */
            else if (endsWith("alli"))
                r("al");
            else if (endsWith("entli"))
                r("ent");
            else if (endsWith("eli"))
                r("e");
            else if (endsWith("ousli"))
                r("ous");
        }
        else if (_b[_k - 1] == 'o')
        {
            if (endsWith("ization"))
                r("ize");
            else if (endsWith("ation") || endsWith("ator"))
                r("ate");
        }
        else if (_b[_k - 1] == 's')
        {
            if (endsWith("alism"))
                r("al");
            else if (endsWith("iveness"))
                r("ive");
            else if (endsWith("fulness"))
                r("ful");
            else if (endsWith("ousness"))
                r("ous");
        }
        else if (_b[_k - 1] == 't')
        {
            if (endsWith("aliti"))
                r("al");
            else if (endsWith("iviti"))
                r("ive");
            else if (endsWith("biliti"))
                r("ble");
        }
        else if (_b[_k - 1] == 'g')
        {
            /**
             * --DEPARTURE--
             * To match the published algorithm, delete this phrase
             */
            if (endsWith("logi"))
                r("log");
        }
    }

    /**
     * step3() dels with -ic-, -full, -ness etc. similar strategy to step2.
     */
    void step3()
    {
        if (_b[_k] == 'e')
        {
            if      (endsWith("icate")) r("ic");
            else if (endsWith("ative")) r("");
            else if (endsWith("alize")) r("al");
        }
        else if (_b[_k] == 'i')
        {
            if (endsWith("iciti")) r("ic");
        }
        else if (_b[_k] == 'l')
        {
            if      (endsWith("ical")) r("ic");
            else if (endsWith("ful")) r("");
        }
        else if (_b[_k] == 's')
        {
            if (endsWith("ness")) r("");
        }
    }

    /**
     * step4() takes off -ant, -ence etc., in context <c>vcvc<v>.
     */
    void step4()
    {
        /* fixes bug 1 */
        if (_k == 0)
            return;
        switch (_b[_k - 1])
        {
            case 'a':
                if (endsWith("al"))
                    break;
                return;
            case 'c':
                if (endsWith("ance") || endsWith("ence"))
                    break;
                return;
            case 'e':
                if (endsWith("er"))
                    break;
                return;
            case 'i':
                if (endsWith("ic"))
                    break;
                return;
            case 'l':
                if (endsWith("able") || endsWith("ible"))
                    break;
                return;
            case 'n':
                if (endsWith("ant") || endsWith("ement") || endsWith("ment") || endsWith("ent"))
                    break;
                return;
            case 'o':
                if (endsWith("ion") && _j >= 0 && (_b[_j] == 's' || _b[_j] == 't'))
                {
                    /* _j >= 0 fixes bug 2 */
                    break;
                }
                if (endsWith("ou"))
                    break;
                return;
            case 's':
                if (endsWith("ism"))
                    break;
                return;
            case 't':
                if (endsWith("ate") || endsWith("iti"))
                    break;
                return;
            case 'u':
                if (endsWith("ous"))
                    break;
                return;
            case 'v':
                if (endsWith("ive"))
                    break;
                return;
            case 'z':
                if (endsWith("ize"))
                    break;
                return;
            default:
                return;
        }

        if (m() > 1)
            _k = _j;

    }

    /**
     * step5() removes a final -e if m() > 1, and changes -ll to -l if m() > 1.
     */
    void step5()
    {
        _j = _k;
        if (_b[_k] == 'e')
        {
            auto a = m();
            if (a > 1 || (a == 1 && !cvc(_k - 1)))
                _k--;
        }
        if (_b[_k] == 'l' && doublec(_k) && m() > 1)
            _k--;
    }
}

import assert_ex;

unittest
{
    auto stemmer = new Stemmer!string();
    assert(stemmer.stem("") == "");
    assert(stemmer.stem("x") == "x");
    assert(stemmer.stem("xyz") == "xyz");
    assert(stemmer.stem("winning") == "win");
    assert(stemmer.stem("farted") == "fart");
    assert(stemmer.stem("win") == "win");
    assert(stemmer.stem("caresses") == "caress");
    assert(stemmer.stem("ponies") == "poni");
    assert(stemmer.stem("ties") == "ti");
    assert(stemmer.stem("caress") == "caress");
    assert(stemmer.stem("cats") == "cat");
    assert(stemmer.stem("feed") == "feed");
    assert(stemmer.stem("matting") == "mat");
    assert(stemmer.stem("mating") == "mate");
    assert(stemmer.stem("meeting") == "meet");
    assert(stemmer.stem("milling") == "mill");
    assert(stemmer.stem("messing") == "mess");
    assert(stemmer.stem("meetings") == "meet");
    assert(stemmer.stem("neutralize") == "neutral");
    assert(stemmer.stem("relational") == "relat");
    assert(stemmer.stem("relational") == "relat");
    assert(stemmer.stem("intricate") == "intric");

    assert(stemmer.stem("connection") == "connect");
    assert(stemmer.stem("connective") == "connect");
    assert(stemmer.stem("connecting") == "connect");

    assert(stemmer.stem("agreed") == "agre");
    assert(stemmer.stem("disabled") == "disabl");
    assert(stemmer.stem("gentle") == "gentl");
    assert(stemmer.stem("gently") == "gentli");
    assert(stemmer.stem("served") == "serv");
    assert(stemmer.stem("competes") == "compet");

    assert(stemmer.stem("fullnessful") == "fullness");
    assert(stemmer.stem(stemmer.stem("fullnessful")) == "full");

    assert(stemmer.stem("bee") == "bee");

    assert(stemmer.stem("dogs") == "dog");
    assert(stemmer.stem("churches") == "church");
    assert(stemmer.stem("hardrock") == "hardrock");
}

import dbg;

auto ref stemSwedish(S)(S s) if (isSomeString!S)
{
    if (s.endsWith(`n`))
    {
        {
            enum en = `en`;
            if (s.endsWith(en))
            {
                const t = s[0 .. $ - en.length];
                if (t.of(`sann`))
                    return t;
                else if (t.endsWith(`mm`, `nn`))
                    return t[0 .. $ - 1];
                return t;
            }
        }
        {
            enum ern = `ern`;
            if (s.endsWith(ern))
            {
                return s[0 .. $ - 1];
            }
        }
        {
            enum an = `an`;
            if (s.endsWith(an))
            {
                const t = s[0 .. $ - an.length];
                if (t.endsWith(`ck`, `n`))
                    return s[0 ..$ - 1];
                else if (t.length < 3)
                    return s;
                return t;
            }
        }
    }

    {
        enum na = `na`;
        if (s.endsWith(na))
        {
            if (s.of(`sina`, `dina`, `mina`))
            {
                return s[0 .. $ - 1];
            }
            const t = s[0 .. $ - na.length];
            if (!t.empty && t[0].isSwedishConsonant)
                return t;
        }
    }

    {
        enum et = `et`;
        if (s.endsWith(et))
        {
            const t = s[0 .. $ - et.length];
            if (t.length >= 3 &&
                t[$ - 3].isSwedishConsonant &&
                t[$ - 2].isSwedishConsonant &&
                t[$ - 1].isSwedishConsonant)
            {
                return s[0 .. $ - 1];
            }
            else if (t.endsWith(`ck`))
            {
                return s[0 .. $ - 1];
            }

            return t;
        }
    }

    {
        enum ar = `ar`;
        enum er = `er`;
        if (s.endsWith(ar, er))
        {
            const t = s[0 .. $ - ar.length];
            if (t.canFind!(a => a.isSwedishVowel))
                return t;
        }
    }

    {
        enum aste = `aste`;
        if (s.endsWith(aste))
        {
            const t = s[0 .. $ - aste.length];
            if (t.of(`sann`))
                return t;
            if (t.endsWith(`mm`, `nn`))
                return t[0 .. $ - 1];
            if (t.canFind!(a => a.isSwedishVowel))
                return t;
        }
    }

    {
        enum are = `are`;
        enum ast = `ast`;
        if (s.endsWith(are, ast))
        {
            const t = s[0 .. $ - are.length];
            if (t.of(`sann`))
                return t;
            if (t.endsWith(`mm`, `nn`))
                return t[0 .. $ - 1];
            if (t.canFind!(a => a.isSwedishVowel))
                return t;
        }
    }

    {
        enum iserad = `iserad`;
        if (s.endsWith(iserad))
        {
            const t = s[0 .. $ - iserad.length];
            if (!t.endsWith(`n`))
                return t;
        }
    }

    {
        enum de = `de`;
        if (s.endsWith(de))
        {
            enum ande = `ande`;
            if (s.endsWith(ande))
            {
                const t = s[0 .. $ - ande.length];
                if (t.empty)
                    return s;
                else if (t[$ - 1].isSwedishConsonant)
                    return s[0 .. $ - 3];
                return t;
            }
            if (s.of(`hade`))
                return s;
            const t = s[0 .. $ - de.length];
            return t;
        }
    }

    {
        enum ing = `ing`;
        if (s.endsWith(ing))
        {
            enum ning = `ning`;
            if (s.endsWith(ning))
            {
                const t = s[0 .. $ - ning.length];
                if (!t.endsWith(`n`) &&
                    t != `tid`)
                    return t;
            }
            return s[0 .. $ - ing.length];
        }
    }

    {
        enum llt = `llt`;
        if (s.endsWith(llt))
        {
            return s[0 .. $ - 1];
        }
    }

    return s;
}

import assert_ex;

unittest
{
    assert("grenen".stemSwedish == "gren");
    assert("busen".stemSwedish == "bus");
    assert("husen".stemSwedish == "hus");
    assert("dunken".stemSwedish == "dunk");
    assert("männen".stemSwedish == "män");

    assert("skalet".stemSwedish == "skal");
    assert("karet".stemSwedish == "kar");
    assert("taket".stemSwedish == "tak");
    assert("stinget".stemSwedish == "sting");

    assert("äpplet".stemSwedish == "äpple");

    assert("jakt".stemSwedish == "jakt");

    assert("sot".stemSwedish == "sot");
    assert("sotare".stemSwedish == "sot");

    assert("klok".stemSwedish == "klok");
    assert("klokare".stemSwedish == "klok");
    assert("klokast".stemSwedish == "klok");

    assert("stark".stemSwedish == "stark");
    assert("starkare".stemSwedish == "stark");
    assert("starkast".stemSwedish == "stark");

    assert("kort".stemSwedish == "kort");
    assert("kortare".stemSwedish == "kort");
    assert("kortast".stemSwedish == "kort");

    assert("rolig".stemSwedish == "rolig");
    assert("roligare".stemSwedish == "rolig");
    assert("roligast".stemSwedish == "rolig");

    assert("dum".stemSwedish == "dum");
    assert("dummare".stemSwedish == "dum");
    assert("dummast".stemSwedish == "dum");
    assert("dummaste".stemSwedish == "dum");
    assert("senaste".stemSwedish == "sen");

    assert("sanning".stemSwedish == "sann");
    assert("sann".stemSwedish == "sann");
    assert("sannare".stemSwedish == "sann");
    assert("sannare".stemSwedish == "sann");

    assert("stare".stemSwedish == "stare");
    assert("kvast".stemSwedish == "kvast");

    assert("täcket".stemSwedish == "täcke");
    assert("räcket".stemSwedish == "räcke");

    assert("van".stemSwedish == "van");
    assert("dan".stemSwedish == "dan");
    assert("man".stemSwedish == "man");
    assert("ovan".stemSwedish == "ovan");
    assert("stan".stemSwedish == "stan");
    assert("klan".stemSwedish == "klan");

    assert("klockan".stemSwedish == "klocka");
    assert("sockan".stemSwedish == "socka");
    assert("rockan".stemSwedish == "rocka");
    assert("rock".stemSwedish == "rock");

    assert("brodern".stemSwedish == "broder");
    assert("kärnan".stemSwedish == "kärna");

    assert("skorna".stemSwedish == "skor");
    assert("kullarna".stemSwedish == "kullar");

    assert("inträffade".stemSwedish == "inträffa");
    assert("roa".stemSwedish == "roa");
    assert("roade".stemSwedish == "roa");
    assert("hade".stemSwedish == "hade");
    assert("hades".stemSwedish == "hades");

    assert("fullt".stemSwedish == "full");

    assert("kanaliserad".stemSwedish == "kanal");
    assert("roande".stemSwedish == "ro");

    assert("ande".stemSwedish == "ande");

    assert("störande".stemSwedish == "störa");
    assert("nekande".stemSwedish == "neka");
    assert("jagande".stemSwedish == "jaga");
    assert("stimulerande".stemSwedish == "stimulera");

    assert("lagar".stemSwedish == "lag");

    assert("sina".stemSwedish == "sin");
    assert("dina".stemSwedish == "din");
    assert("mina".stemSwedish == "min");

    /* assert("krya".stemSwedish == "kry"); */
    /* assert("nya".stemSwedish == "ny"); */

    /* assert("ämnar".stemSwedish == "ämna"); */
    /* assert("lämnar".stemSwedish == "lämna"); */
}

auto ref stemNorvegian(S)(S s) if (isSomeString!S)
{
    s.skipOverBack(`ede`);
    return s;
}
