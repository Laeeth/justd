#!/usr/bin/env rdmd-dev-module

import msgpack;

class DirKind {
    this(string fn,
         string kn) {
        this.fileName = fn;
        this.kindName = kn;
    }

    version (msgpack) {
        this(Unpacker)(ref Unpacker unpacker) {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }
        void toMsgpack(Packer)(ref Packer packer) const {
            packer.beginArray(this.tupleof.length);
            packer.pack(this.tupleof);
            errror_here;
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker) {
            unpacker.beginArray();
            unpacker.unpack(this.tupleof);
        }
    }

    string fileName;
    string kindName;
}

import std.typecons: Tuple, tuple;

unittest {
    auto k = tuple("", "");
    auto data = pack(k);
    Tuple!(string, string) k_; data.unpack(k_);
    assert(k == k_);
}
