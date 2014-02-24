#!/usr/bin/env rdmd-dev-module

import dbg: dln;
import std.typecons: Tuple, tuple;
import msgpack;

string typestringof(T)(T a) @safe pure nothrow { return T.stringof; }

version = print;

/** Diretory Kind.
 */
class C {
    this() {}
    this(string a,
         string b) {
        this._a = a;
        this._b = b;
    }
    this(Unpacker)(ref Unpacker unpacker) {
        version(print) dln("this(", unpacker, ")");
        fromMsgpack(msgpack.Unpacker(unpacker));
    }
    void toMsgpack(Packer)(ref Packer packer) const {
        version(print) dln("toMsgpack(", packer.typestringof, ")");
        packer.beginArray(this.tupleof.length);
        packer.pack(this.tupleof);
    }
    void fromMsgpack(Unpacker)(auto ref Unpacker unpacker) {
        unpacker.beginArray();
        unpacker.unpack(this.tupleof);
    }

    string _a;
    string _b;
}

/* reference case */
unittest {
    auto k = tuple("a", "b");
    const data = k.pack;
    version(print) dln("tuple: ", data);
    typeof(k) k_; data.unpack(k_);
    assert(k == k_);
    version(print) dln("");
}

/* pack null class */
unittest {
    C k;
    const data = k.pack;
    version(print) dln("C-data: ", data);
    /* auto k_ = new C(); data.unpack(k_); */
    /* version(print) dln("C-restored: ", k_); */
    /* assert(k.tupleof == k_.tupleof); */
    /* version(print) dln(""); */
}

/* construct and then unpack */
unittest {
    const k = new C("a", "b");
    const data = k.pack;
    version(print) dln("C-data: ", data);
    auto k_ = new C(); data.unpack(k_);
    version(print) dln("C-restored: ", k_);
    assert(k.tupleof == k_.tupleof);
    version(print) dln("");
}

import std.range: Appender;

/* constructed unpack */
unittest {
    const k = new C("a", "b");
    const data = k.pack;
    version(print) dln("C-data: ", data);
    auto k_ = new C(data);
    version(print) dln("C-restored: ", k_);
    assert(k.tupleof == k_.tupleof);
    version(print) dln("");
}

unittest {
    int x;
    auto bytes = x.pack;
    version(print) dln(bytes);
    auto x_ = bytes.unpack!int;
    assert(x == x_);
    version(print) dln(x_);
}

unittest {
    immutable x = [1, 2, 3, 4, 5, 6, 7, 8, 127, 128, 8, 9, 10, 11, 12];
    auto bytes = x.pack;
    version(print) dln(bytes);
}

unittest {
    immutable x = [1,256, 1,256, 1,256, 1,256, 1,256, 1,256, 1,256];
    auto bytes = x.pack;
    version(print) dln(bytes);
}
