.global _start

_start:
    nop
_init:
    nop

main:
    # 20 / 4 işlemi, sonuç 5 çıkmalı
    li x5, 20
    li x6, 4
    div x7, x5, x6        # x7 = 5

    # -20 / 4 işlemi, sonuç -5 çıkmalı
    li x5, -20
    li x6, 4
    div x8, x5, x6        # x8 = -5 (0xFFFFFFFB)

    # 100 / 3 işlemi, sonuç 33 çıkmalı
    li x5, 100
    li x6, 3
    div x9, x5, x6        # x9 = 33

    # 10 % 3 kalanı bulma, sonuç 1 olmalı
    li x5, 10
    li x6, 3
    rem x10, x5, x6       # x10 = 1

    # -10 % 3 kalanı bulma, isaretli oldugu icin -1 çıkmalı
    li x5, -10
    li x6, 3
    rem x11, x5, x6       # x11 = -1

    # Sfıra bölme,  normalde hata verir ama islemcide sonuç -1 dönmeli ricv kuralalrından dolayı
    li x5, 100
    li x6, 0
    div x12, x5, x6       # x12 = -1 (0xFFFFFFFF)

    # Sıfıra bölme durumunda kalan bulma, sonuç bölünenin kendisi olmal riscv kuralları gereği.
    li x5, 55
    li x6, 0
    rem x13, x5, x6       # x13 = 55 (0x37)

    # Signed Overflow bölme, bölüm 0x80000000 olarak döner riscv kuralları gereği
    li x5, 0x80000000     # Min_Int yukledik
    li x6, -1
    div x14, x5, x6       # x14 = 0x80000000

    # Signed overflow kalan bulma, kalan 0 olarka döner riscv kuralları gereği
    rem x15, x5, x6       # x15 = 0

    # DIVU, İşaretsiz Bölme
    li x5, -2             # Aslinda 0xFFFFFFFE
    li x6, 2
    divu x16, x5, x6      # x16 = 0x7FFFFFFF (Max_Int)

    # Unsigned sıfıra bölme, bölüm 0xFFFFFFFF döner riscv kuralalrından dolayı
    li x5, 20
    li x6, 0
    divu x17, x5, x6      # x17 = 0xFFFFFFFF

test_end:
    j test_end            # simulasyon burada bitsin