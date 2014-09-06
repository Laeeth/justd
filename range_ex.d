#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorithm.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module range_ex;

/** Ring Buffer Container.
    See also: http://forum.dlang.org/thread/ltpaqk$2dav$1@digitalmars.com
 */
struct RingBuffer(T)
{
    private T[] _data;
    private size_t _index;
    private size_t _length;

    auto opSlice() const
    {
	return cycle(_data[0.._length]).take(_length);
    }

    @property
    auto length() { return _length; }

    this(T[] data, size_t length = 0)
    {
        enforce(data.length, "empty ring buffer is prohibited");
        enforce(length <= data.length, "buffer length shall not be more
than buffer capacity");
        _data = data;
        _index = 0;
        _length = length;
    }
}

/** Static Iota.
    TODO: Make use of staticIota when it gets available in Phobos.
*/
template siota(size_t from, size_t to) { alias siota = siotaImpl!(to-1, from); }
private template siotaImpl(size_t to, size_t now)
{
    import std.typetuple: TypeTuple;
    static if (now >= to) { alias siotaImpl = TypeTuple!(now); }
    else                  { alias siotaImpl = TypeTuple!(now, siotaImpl!(to, now+1)); }
}
