# DMD TODO

## Avoid bounds checking in slice expressions

### Cases

- `x[0 .. $]`
- `x[$/m .. $/n]` where `m >= 1` and `n >= 1`
- `x[$*p/q .. $*r/s]` where `p >= q` and `r >= s`

Note that `x[m .. n]` evaluates to null slice if `m > n`.

###  -noboundscheck

### DMD Source Symbols

- `SliceExp`
- `IndexExp::indexIsInBounds`
- `IntRange`
