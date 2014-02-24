#!/usr/bin/env rdmd-dev-module

void main(string[] args) {
    void a() {
        b();
    }
    void b() {
    }
}
