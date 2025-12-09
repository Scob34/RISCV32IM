.global _start

_start:
    nop
_init:
    nop

main:
    li x10,0 # LUI Kontrol Sinyali
    li x11,0 # AUIPC Kontrol Sinyali

#/////////////////////////////////////// LUI TEST ///////////////////////////////////////////

    lui x1, 0x12345 # x1'in üst 20 bitine 0x123456 değerini ekledik, şu anda x1 register'ı 0x12345000 olmalı.
    li  x2, 0x12345000 # x2 değerine manuel olarak 0x12345000 değerini yükledik x1 ile karşılaştırıcaz.

    bne x1,x2,lui_fail # eğer eşit değillerse lui doğru çalışmamıştır ve lui_fail'e atlar.
    li x10,1 # eğer bne çalışmadıysa lui doğru çalışmıştır ve x10 register'ını 1 yaparak bunu doğruluyoruz.
    j test_auipc

lui_fail:
    li x10,2 # eğer lui fail'e atlandıysa x10 register'ını 2 yapıyoruz. 2 yapmamızın sebebi baştaki 0 değeri ile çakışma olmasın ki kesin atlandığını anlayalım.

#/////////////////////////////////////// AUIPC TEST //////////////////////////////////////////

test_auipc:

    auipc_label: # bu senaryoda pc'yi 0 offset ile toplucaz yani direkt pc'nin kendisini register'a yüklicez.

        auipc x3,0 # bu komut mevcut pc(program counter) değerini 0 offset ile toplar ve x3 register'ına yazar yani direkt pc'nin kendisi x3'e yazılır.
        la    x4,auipc_label # bu komut ile assembly tarafından hesaplanan auipc_label adresini x4'e yüklüyoruz, x3 ile karşılaştırıcaz.

        bne x3,x4,auipc_fail
    
    auipc_offset_label: # bu senaryoda ise pc'yi herhangi bir offset değeri ile toplucaz bakalım auipc toplama işini de doğru yapıyor mu?

        auipc x5,1 # burada mevcut pc değerini 0x1000(4096) ile toplayıp x5 register'ına yazdık. 1 vermemizin sebebi auipc ve lui komutlarının mantığı ile alakalı.
                   # auipc ve lui komutları verdiğimiz offset değerini "12 bit sola kaydırarak" register'a yazar. 1 verdiğimizde aslında ...1 0000 0000 0000 
                   # yapmış oluyoruz.

        la    x6,auipc_offset_label # auipc_offset_label adresinin assembly tarafından hesaplanmış halini la ile yükledik.
        li    x7,0x1000 # x7 register'ına 0x1000(4096) immediate değerini yüklüyoruz.
        add   x8,x6,x7  # x8 register'ına yüklediğimiz değer x5 register'ına auipc ile yüklediğimiz değerle karşılaştırıcaz, bakalım aynı mı

        bne x5,x8,auipc_fail # eğer eşit değillerse auipc_fail'e atlıcak bu durumda auipc doğru çalışmamış demektir.
        li  x11,1 # eğer bne komutu çalışmadıysa buraya gelir bu durumda auipc doğru çalışmıştır, x11 değerini 1 yapıyoruz.
        j test_end

    auipc_fail:
        li x11,2 # eğer buraya düştüysek auipc yanlış çalışmıştır x11 register'ını 2 yapıyoruz.

test_end:
    j test_end
