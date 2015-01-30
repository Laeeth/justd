# DMD TODO

## Avoid bounds checking in slice expressions

### Cases

- `x[0 .. $]`
- `x[$/m .. $/n]` where `m >= 1` and `n >= 1`
- `x[$*p/q .. $*r/s]` where `p >= q` and `r >= s`

Note that `x[m .. n]` evaluates to null slice if `m > n`.

###  -noboundscheck

### DMD Source Symbols

- (`SliceExp::lowerIsLessThanUpper` and `SliceExp::upperIsInBounds`) infers `SliceExp::lowerIsInBounds`
- `SliceExp::upperIsInBounds`

- `IndexExp::indexIsInBounds`

- `IntRange`

### Implement foreach restrictions
- Scope::fes maybe of interest to checking foreach scope
