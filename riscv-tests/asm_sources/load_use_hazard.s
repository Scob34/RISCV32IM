.global _start

_start:
    nop
_init:
    nop

main:
    li  x1,0x80001000 # base address
    li  x5,0xaabb0000
    li  x6,0xaabbccdd

    sw  x6,0(x1) # 0x80001000 adresine ddccbbaa şeklinde yazıldı.
    lhu x4,0(x1) # ccdd x5'e yazılcak x5 = 0x0000ccdd
    add x7,x4,x5

test_end:
    j test_end