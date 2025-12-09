.global _start

_start:
    nop
_init:
    nop

main:
    li x20,3  # iç döngü sınırı 
    li x21,2  # dış döngü sınırı

    li x10,0 # iç döngü sayacı (j)
    li x11,0 # dış döngü sayacı (i)
    li x12,0 # toplam değeri(başlangıçta sıfır)

    li x30,0 # hata sayacı olarak kullanıcaz.

outer_loop:
    li x10,0 # iç döngü sayacı(j) dış döngü başlangıcında her seferinde sıfırlanır.

    inner_loop:
        addi x12,x12,1 # her döngüde +1 ekliyoruz toplama
        addi x10,x10,1 # iç döngü sayacını her defasın 1 artırıyoruz j++
        bne  x10,x20,inner_loop
        
        addi x30,x30,1 # iç döngü bitmeden buraya inmemesi lazım, nop enjekte ederek kaç defa buraya girmiş onu ölçücez.

    addi x11,x11,1 # dış döngü sayacını her defasında 1 artırıyoruz i++
    bne  x11,x21,outer_loop

    addi x30,x30,1 # dış döngü tamamen bitmeden buraya inmemesi lazım nop sayısını ölçerek doğruluğu kontrol edicez yine.

test_end:
    # son durumda x30 = 3 olmalı düşük ya da fazlaysa flush mekanizması hatalı.
    j test_end
