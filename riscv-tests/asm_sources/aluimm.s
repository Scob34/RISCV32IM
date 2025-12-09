.global _start

_start:
    nop
_init:
    nop

main:
    li    x10, 554
    li    x11, 376
    li    x12, -812
    li    x13, -611
    li    x25, 1

############# ADDI #############

    addi  x1, x10, 16   # iki pozitif sayı
    addi  x2, x10, -14  # bir pozitif bir negatif sayı
    addi  x3, x12, -8   # iki negatif sayı

########## SLTI/SLTIU ##########

    slti  x4,  x10, 500  # x4 = 0 set edilmeyecek
    slti  x5,  x11, 378  # x5 = 1 set edilecek
    slti  x6,  x12, -810 # x6 = 1 set edilecek 
    slti  x7,  x13, -612 # x7 = 0 set edilmeyecek
    slti  x8,  x12, 10   # x8 = 1 set edilecek 
    sltiu x9,  x12, 10   # x9 = 0 set edilmeyecek çünkü unsigned olduğu için x12 = -812 değil aslında çok büyük bir sayı 

######### XORI/ORI/ANDI #########

    xori  x14,x11,123
    ori   x15,x10,999
    andi  x16,x11, 777

######### SLLI/SRLI/SRAI #########

    slli  x17,x10,2  # x17 = 2216
    srli  x18,x11,2  # x18 = 94
    srai  x19,x12,1  # x19 = -406 işaret korunmalı.
    slli  x20,x10,0  # x20 = 554, sayı değişmemeli
    slli  x21,x25,31 # x21 = 8'h80000000
    srai  x22,x12,0  # x22 = x12, sayı değişmemeli
    srai  x23,x12,31 # x23 = 8'hFFFFFFFF
    srli  x24,x11,31 # x24 = 32'b0
    

test_end:
    j test_end

