#!/usr/bin/env rustx

// See http://doc.rust-lang.org/nightly/intro.html#the-power-of-ownership

fn dangling() -> &int {
    let i = 1234;
    return &i;
}

fn add_one() -> int {
    let num = dangling();
    return *num + 1;
}

fn main() {
    add_one();
}
