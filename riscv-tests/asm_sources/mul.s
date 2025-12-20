.global _start

_start:
    nop
_init:
    nop

main:
    # ==========================================
    # TEST 1: Temel Pozitif Çarpma (3 * 7)
    # Beklenen: x3 = 21 (0x00000015)
    # Amaç: Basic Shift-Add döngüsü çalışıyor mu?
    # ==========================================
    li x1, 3
    li x2, 7
    mul x3, x1, x2
    
    # ==========================================
    # TEST 2: Negatif Çarpma (3 * -2)
    # Beklenen: x4 = -6 (0xFFFFFFFA)
    # Amaç: İşaret düzeltme (2's complement) mantığı doğru mu?
    # ==========================================
    li x1, 3
    li x2, -2
    mul x4, x1, x2

    # ==========================================
    # TEST 3: Büyük Sayı ve Üst Bit (MULH)
    # İşlem:  0x40000000 (Büyük Pozitif) * 4
    # Gerçek Sonuç: 0x100000000 (33 bitlik sayı)
    # Beklenen (MUL):  x5 = 0 (Alt 32 bit taştı ve 0 oldu)
    # Beklenen (MULH): x6 = 1 (Üst 32 bit 1 oldu)
    # ==========================================
    li x1, 0x40000000
    li x2, 4
    mul  x5, x1, x2
    mulh x6, x1, x2

    # ==========================================
    # TEST 4: En Zor Test - Signed x Unsigned (MULHSU)
    # İşlem: -1 (Signed) * 2 (Unsigned)
    # Matematik: -1 * 2 = -2 
    # 64-bit Hex karşılığı: 0xFFFFFFFF_FFFFFFFE
    # Beklenen (MUL):    x7 = -2 (0xFFFFFFFE)
    # Beklenen (MULHSU): x8 = -1 (0xFFFFFFFF) -> Üst kısım işaretle dolmalı
    # ==========================================
    li x1, -1       # 0xFFFFFFFF
    li x2, 2
    mul    x7, x1, x2
    mulhsu x8, x1, x2

    # ==========================================
    # TEST 5: Unsigned x Unsigned (MULHU)
    # İşlem: 0xFFFFFFFF (Max Unsigned) * 2
    # Matematik: (2^32 - 1) * 2 = 2^33 - 2
    # Hex: 0x1_FFFFFFFE
    # Beklenen (MULHU): x9 = 1
    # ==========================================
    li x1, -1      # Unsigned olarak Max Value
    li x2, 2
    mulhu x9, x1, x2

test_end:
    j test_end