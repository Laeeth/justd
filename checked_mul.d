// Using inline asm for extra speed on x86
uint checked_multiply(uint x, uint y)
{
    uint result;
    version (D_InlineAsm_X86) {
        // Inline assembler "sees" D variables.
        asm { mov EAX,x ; mul EAX,y ; mov result,EAX ; jc Loverflow ; }
        return result;
    } else {
        result = x * y;
        if (!y || x <= uint.max / y) return result;
    }
  Loverflow:
    throw new Exception("multiply overflow");
}
