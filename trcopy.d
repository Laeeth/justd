#!/usr/bin/env rdmd

void main(string[] args)
{
    import std.exception, std.file;

    enforce(args.length == 3,
            "Usage: trcopy file1 file2");

    auto tmp = args[2] ~ ".messedup";
    scope(failure)
        if (exists(tmp))
            remove(tmp);

    copy(args[1], tmp);
    rename(tmp, args[2]);       // atomic
}
