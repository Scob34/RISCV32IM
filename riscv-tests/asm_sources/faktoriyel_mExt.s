.global _start
_start:
    nop
_init:
    nop

.data 
dizi: .space 20         # 5 elemanlı dizi (5 * 4 byte)

.text
main:
    la   x10, dizi      # Dizinin başlangıç adresi
    addi x5, x0, 1      # Faktöriyel sonuç başlangıcı (1! = 1)
    addi x6, x0, 1      # Döngü sayacı (i = 1)
    addi x7, x0, 15     # Dış döngü sınırı 

    # Faktöriyel hesaplayan fonksiyonu çağır
    jal  x1, faktoriyel_m

    # Sonuçları kontrol etmek için tekrar yükle (Load aşaması)
    addi x6, x0, 0      # Sayacı sıfırla
    la   x10, dizi      # Adresi başa sar
    jal  x1, load_check

    j    test_end

# --- M-Extension Kullanan Fonksiyon ---
faktoriyel_m:
    # mul rd, rs1, rs2 -> x5 = x5 * x6
    mul  x5, x5, x6     # M-EXTENSION mul komutu
    
    sw   x5, 0(x10)     # Sonucu belleğe yaz
    addi x10, x10, 4    # Adresi ilerlet
    addi x6, x6, 1      # i'yi artır (1, 2, 3, 4, 5)
    blt  x6, x7, faktoriyel_m
    jalr x0, 0(x1)      # Geri dön

# --- Bellekten Geri Okuma (Doğrulama) ---
load_check:
    lw   x12, 0(x10)    # Bellekten oku (Simülatörde x12'yi izle)
    addi x10, x10, 4
    addi x6, x6, 1
    blt  x6, x7, load_check
    jalr x0, 0(x1)

test_end:
    j test_end
