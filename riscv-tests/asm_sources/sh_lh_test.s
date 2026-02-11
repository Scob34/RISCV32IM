.global _start

_start:
    nop
_init:
    nop

main:
    li  x1, 0x80001000   # base address

############# SH (Store Halfword) TESTLERİ #############

test_sh_basic:
    li  x5, 0x1234
    sh  x5, 0(x1)        # 0x1234 halfword yaz
    lh  x6, 0(x1)        # x6 = 0x00001234

test_sh_negative:
    li  x5, 0xFFFF8765   # negatif değer (-30875)
    sh  x5, 2(x1)        # alt 16 bit = 0x8765 yaz
    lh  x7, 2(x1)        # x7 = 0xFFFF8765 (sign-extended)
    lhu x8, 2(x1)        # x8 = 0x00008765 (zero-extended)

test_sh_offset:
    li  x5, 0xABCD
    sh  x5, 4(x1)        # offset 4'e yaz
    lhu x9, 4(x1)        # x9 = 0x0000ABCD

test_sh_upper_half:
    li  x5, 0x5678
    sh  x5, 6(x1)        # üst halfword pozisyonuna yaz (offset 6 = word offset 4, upper half)
    lhu x10, 6(x1)       # x10 = 0x00005678

############# LH (Load Halfword Signed) TESTLERİ #############

test_lh_sign_extend:
    li  x5, 0x7FFF       # en büyük pozitif halfword
    sh  x5, 8(x1)
    lh  x11, 8(x1)       # x11 = 0x00007FFF (pozitif, sign extend)

    li  x5, 0x8000       # en küçük negatif halfword
    sh  x5, 10(x1)
    lh  x12, 10(x1)      # x12 = 0xFFFF8000 (negatif, sign extend)
    lhu x13, 10(x1)      # x13 = 0x00008000 (unsigned, zero extend)

############# SW ile yazıp SH/LH ile okuma #############

test_mixed_access:
    li  x5, 0xDEADBEEF
    sw  x5, 12(x1)       # tam word yaz
    lh  x14, 12(x1)      # alt halfword: 0xBEEF -> sign extend -> 0xFFFFBEEF
    lh  x15, 14(x1)      # üst halfword: 0xDEAD -> sign extend -> 0xFFFFDEAD
    lhu x16, 12(x1)      # alt halfword: 0xBEEF -> zero extend -> 0x0000BEEF
    lhu x17, 14(x1)      # üst halfword: 0xDEAD -> zero extend -> 0x0000DEAD

test_end:
    j test_end
