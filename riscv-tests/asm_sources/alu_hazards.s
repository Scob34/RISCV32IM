.global _start

_start:
    nop
_init:
    nop

main:
    li x1, 10       # Test değeri 1
    li x2, 20       # Test değeri 2
    li x3, 5        # Shift miktarı vb.
    
# SENARYO 1 MEMORY AŞAMASINDAN EXECUTE AŞAMASINA FORWARD
    
    add x4, x1, x2  # x4 = 10 + 20 = 30 (Bu komut EX'teyken...)
    sub x5, x4, x3  # x5 = 30 - 5 = 25  (...bu komut ID'den yeni çıktı)
                    # Hazard Unit, x4'ün değerini x4 Register File'a yazılmadan
                    # havada yakalayıp sub işlemine vermeli.

# SENARYO 2 WB AŞAMASINDAN EXECUTE AŞAMASINA FORWARD

    add x6, x1, x1  # x6 = 20
    nop             # Araya bir boşluk (veya alakasız komut)
    xor x7, x6, x2  # x6 burada kullanılacak.
                    # x6 şu an MEM/WB sınırında, x7 ise EX aşamasında.

# SENARYO 3 RS1 RS2 AYNI ANDA BAĞIMLI
    addi x8, x0, 100 # x8 = 100
    add  x9, x8, x8  # x9 = 100 + 100 = 200
                     # Burada hem rs1 (x8) hem rs2 (x8) bir önceki komuta bağımlı!
                     # Forwarding Unit'in iki bacağı da (ForwardA ve ForwardB) aktif olmalı.

# SENARYO 4
    or   x10, x4, x5 # x4 ve x5 yukarılardan geliyor (Uzak mesafe testi)
    andi x11, x10, 0x0FF # x10'a bağımlı yani memory aşamasından forwarding
    
    slli x12, x11, 2 # x11'e bağımlı yani memory aşamasından forwarding lazım
    add  x13, x12, x11 # x12 ve x11'e bağımlı yani hem wb aşamasından hem memory aşamasından forwarding lazım

test_end:
    j test_end