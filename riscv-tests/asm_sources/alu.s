.global _start

_start:
    nop
_init:
    nop
main:
    li   x5, 5
    li   x3, 10
    li   x10, -7
    li   x2, -3

############# ADD #############

    add  x6,x5,x3    # iki pozitif sayı toplamı x6 = 5 + 10 = 15(0x0000000F)
    add  x7,x5,x2    # bir pozitif bir negatif sayı toplamı x7 = 5 + (-3) = 2(0x00000002)
    add  x8,x10,x2   # iki negatif sayı toplamı x8 = (-7) + (-3) = -10(0xFFFFFFF6)

############# SUB #############

    sub  x9,x5,x3   # iki pozitif sayı, sonuc negatif, x9 = 5 - 10 = -5(0xFFFFFFFB)
    sub  x11,x3,x5  # iki pozitif sayı, sonuc pozitif, x11 = 10 - 5 = 5
    sub  x12,x10,x2 # iki negatif sayı, sonuc negatif, x12 = -7 - (-3) = -4
    sub  x13,x2,x10 # iki negatif sayı, sonuc pozitif, x13 = -3 - (-7) = 4

######### SLL-SRL-SRA #########

    sll  x14,x5,x7  # veri logic olarak sola kaydırılır, x7 register'ı içinde 2 var veri 2 defa sola kaydırılacak, boşalan bitlere 0 gelecek.
    srl  x15,x5,x7  # veri logic olarak sağa kaydırılır, x7 register'ı içinde 2 var veri 2 defa sağa kaydırılacak, boşalan bitlere 0 gelicek
    sra  x16,x10,x7 # veri aritmetik olarak sağa kaydırılır, x7 register'ı içinde 2 var veri 2 defa sağa kaydırılacak, boşalan bitlere işaret biti gelicek.

########## SLT-SLTU ###########

    slt  x9,x5,x2   # x5 register'ı içindeki veri x2 register'ı içindeki veriden büyükse x9 register'ına 1 atanacak değilse 0 atanacak. İşarete hassasiyetlidir.
    sltu x6,x5,x3   # x5 register'ı içindeki veri x2 register'ı içindeki veriden büyükse x9 register'ına 1 atanacak değilse 0 atanacak.

######### XOR-OR-AND ##########

    xor x8,x9,x6    # 1 xor 0 = 1
    or  x13,x9,x6   # 1 or 0  = 1
    and x14,x9,x6   # 1 and 0 = 0

    j test_end

test_end:
    j test_end
