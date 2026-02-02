.global _start

_start:
    nop
_init:
    nop

    # --- Temel İşaretli Bölme (Signed DIV/REM) ---
    li t0, 20           # Pay
    li t1, 3            # Payda
    div t2, t0, t1      # t2 = 6
    rem t3, t0, t1      # t3 = 2

    li t0, -20          # Negatif sayi
    div t4, t0, t1      # t4 = -6
    rem t5, t0, t1      # t5 = -2

    # --- İşaretsiz Bölme (Unsigned DIVU/REMU) ---
    li t0, 0xFFFFFFFF   # Isaretsiz olarak cok buyuk bir sayi
    li t1, 2
    divu a0, t0, t1     # a0 = 2147483647 (0x7FFFFFFF)
    remu a1, t0, t1     # a1 = 1

    # --- Corner Case 1: Sifira Bolme (Division by Zero) ---
    # RISC-V kuralina gore: x / 0 = -1, x % 0 = x
    li t0, 15
    li t1, 0
    div s0, t0, t1      # s0 = -1 (0xFFFFFFFF)
    rem s1, t0, t1      # s1 = 15

    # --- Corner Case 2: Isaretli Tasma (Signed Overflow) ---
    # En kucuk negatif sayi / -1 durumu (-2^31 / -1)
    # RISC-V kuralina gore: Sonuc yine -2^31, kalan ise 0 olur.
    li t0, 0x80000000   # -2147483648
    li t1, -1
    div s2, t0, t1      # s2 = 0x80000000 (-2147483648)
    rem s3, t0, t1      # s3 = 0

    # --- Farkli Isaretli Bolme ---
    li t0, 10
    li t1, -3
    div s4, t0, t1      # s4 = -3
    rem s5, t0, t1      # s5 = 1 (Kalan payin isaretiyle ayni olmali)

test_end:
    j test_end