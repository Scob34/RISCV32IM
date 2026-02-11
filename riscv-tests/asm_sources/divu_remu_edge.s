.global _start

# ==========================================
# NEDEN div_rem.s'TEKI SIFIRA BOLME TESTI GECTI DE BU TESTTE HATA YAKALANDI?
# ==========================================
# div_rem.s'te sifira bolme testi:  DIV(15, 0)  -> bolunen POZITIF
# Bu testte sifira bolme testi:     DIV(-15, 0) -> bolunen NEGATIF
#
# Hata, SADECE bolunen negatifken ortaya cikiyor. Sebebi:
#
# Eski kodda sifira bolme shortcircuit'i su sekildeydi:
#   product_register_next = {multiplicand_dividend, 32'hFFFF_FFFF}
#
# Yani ham (isaretli) degeri dogrudan product_register'a yaziyordu.
# Ama PRODUCT_FINAL_CALCULATION blogu, sonuca isaret duzeltmesi uyguluyor:
#   bolum  = (sign_d ^ sign_r) ? ~q+1 : q
#   kalan  = (sign_d)          ? ~r+1 : r
#
# POZITIF BOLUNEN (div_rem.s, t0=15):
#   sign_d = 0 (15 pozitif), sign_r = 0 (0 pozitif)
#   product_register = {15, 0xFFFFFFFF}
#   bolum: sign_d ^ sign_r = 0, duzeltme YOK -> 0xFFFFFFFF = -1  DOGRU
#   kalan: sign_d = 0, duzeltme YOK -> 15                        DOGRU
#
# NEGATIF BOLUNEN (bu test, t0=-15 = 0xFFFFFFF1):
#   sign_d = 1 (-15 negatif), sign_r = 0 (0 pozitif)
#   product_register = {0xFFFFFFF1, 0xFFFFFFFF}
#   bolum: sign_d ^ sign_r = 1, duzeltme UYGULANIR -> ~0xFFFFFFFF+1 = 1  YANLIS! (dogru: -1)
#   kalan: sign_d = 1, duzeltme UYGULANIR -> ~0xFFFFFFF1+1 = 15          YANLIS! (dogru: -15)
#
# Kisaca: pozitif bolunende isaret duzeltmesi devre disi kaldigindan hata gizli kaldi.
# Negatif bolunende isaret duzeltmesi cift negasyon yaparak yanlis sonuc uretti.
#
# DUZELTME: Shortcircuit, isaret duzeltmesiyle uyumlu degerler saklayacak sekilde guncellendi:
#   product_register_next = {(sign_d) ? |x| : x, (sign_d) ? 1 : 0xFFFFFFFF}
#   Boylece isaret duzeltmesi dogru sekilde calisir.
# ==========================================

_start:
    nop
_init:
    nop

main:

    # ==========================================
    # TEST 1: DIVU sifira bolme
    # RISC-V Spec: DIVU(x, 0) = 2^32 - 1 = 0xFFFFFFFF
    # ==========================================
    li t0, 100
    li t1, 0
    divu t2, t0, t1      # t2 = 0xFFFFFFFF

    # ==========================================
    # TEST 2: REMU sifira bolme
    # RISC-V Spec: REMU(x, 0) = x
    # ==========================================
    remu t3, t0, t1      # t3 = 100 (0x00000064)

    # ==========================================
    # TEST 3: Signed DIV negatif sayi / 0 (ASIL HATAYI YAKALAYAN TEST)
    # RISC-V Spec: DIV(x, 0) = -1 = 0xFFFFFFFF (x negatif olsa bile)
    # div_rem.s'te bu test yoktu cunku orada bolunen pozitifti (15).
    # ==========================================
    li t0, -15
    li t1, 0
    div t4, t0, t1       # t4 = 0xFFFFFFFF (-1)

    # ==========================================
    # TEST 4: Signed REM negatif sayi % 0 (ASIL HATAYI YAKALAYAN TEST)
    # RISC-V Spec: REM(x, 0) = x
    # ==========================================
    rem t5, t0, t1       # t5 = -15 (0xFFFFFFF1)

    # ==========================================
    # TEST 5: DIVU buyuk unsigned deger / 0
    # ==========================================
    li t0, 0xFFFFFFFF
    li t1, 0
    divu a0, t0, t1      # a0 = 0xFFFFFFFF

    # ==========================================
    # TEST 6: REMU buyuk unsigned deger % 0
    # ==========================================
    remu a1, t0, t1      # a1 = 0xFFFFFFFF

    # ==========================================
    # TEST 7: DIVU 0x80000000 / 0xFFFFFFFF (unsigned bolme, overflow olmamali)
    # 0x80000000 = 2147483648, 0xFFFFFFFF = 4294967295
    # 2147483648 / 4294967295 = 0, kalan = 2147483648
    # Eski kodda is_DIV_op (DIVU dahil) isaretli tasma kontrolune giriyordu.
    # is_signed_DIV_op ile duzeltildi, sadece DIV/REM bu kontrole girer.
    # ==========================================
    li t0, 0x80000000
    li t1, -1            # 0xFFFFFFFF
    divu a2, t0, t1      # a2 = 0 (bolum)
    remu a3, t0, t1      # a3 = 0x80000000 (kalan)

test_end:
    j test_end
