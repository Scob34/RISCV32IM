.global _start

_start:
    nop
_init:
    nop

main:

    # ==========================================
    # TEST 1: DIVU sıfıra bölme
    # RISC-V Spec: DIVU(x, 0) = 2^32 - 1 = 0xFFFFFFFF
    # ==========================================
    li t0, 100
    li t1, 0
    divu t2, t0, t1      # t2 = 0xFFFFFFFF

    # ==========================================
    # TEST 2: REMU sıfıra bölme
    # RISC-V Spec: REMU(x, 0) = x
    # ==========================================
    remu t3, t0, t1      # t3 = 100 (0x00000064)

    # ==========================================
    # TEST 3: Signed DIV negatif sayı / 0
    # RISC-V Spec: DIV(x, 0) = -1 = 0xFFFFFFFF (x negatif olsa bile)
    # ==========================================
    li t0, -15
    li t1, 0
    div t4, t0, t1       # t4 = 0xFFFFFFFF (-1)

    # ==========================================
    # TEST 4: Signed REM negatif sayı % 0
    # RISC-V Spec: REM(x, 0) = x
    # ==========================================
    rem t5, t0, t1       # t5 = -15 (0xFFFFFFF1)

    # ==========================================
    # TEST 5: DIVU büyük unsigned değer / 0
    # ==========================================
    li t0, 0xFFFFFFFF
    li t1, 0
    divu a0, t0, t1      # a0 = 0xFFFFFFFF

    # ==========================================
    # TEST 6: REMU büyük unsigned değer % 0
    # ==========================================
    remu a1, t0, t1      # a1 = 0xFFFFFFFF

    # ==========================================
    # TEST 7: DIVU 0x80000000 / 0xFFFFFFFF (unsigned bölme, overflow olmamalı)
    # 0x80000000 = 2147483648, 0xFFFFFFFF = 4294967295
    # 2147483648 / 4294967295 = 0, kalan = 2147483648
    # ==========================================
    li t0, 0x80000000
    li t1, -1            # 0xFFFFFFFF
    divu a2, t0, t1      # a2 = 0 (bölüm)
    remu a3, t0, t1      # a3 = 0x80000000 (kalan)

test_end:
    j test_end
