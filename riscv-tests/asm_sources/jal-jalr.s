.global _start

_start:
    nop
_init:
    nop

main:

    li x4, 0 # JAL Kontrol sinyali
    li x5, 0 # JALR Kontrol sinyali
    li x8, 10
    li x9, 5

############ JAL(Jump And Link) ############

    jal x1, funct_add   # toplama fonksiyonuna gidiyoruz, giderken x1(return address register) register'ına mevcut pc değerini kaydediyoruz.

return_point_jal:
    li x4, 1 # jal return point'e ulaştıysak jal doğru çalışıyor.

######## JALR(Jump And Link Register) #######
    
    la x6, funct_sub # hedef fonlsiyonun adresini x6 regiter'ına yükledik, bakalım jalr ile dinamik atlama yapabiliyor muyuz test edicez.
    jalr x1,x6,0     # x6'daki adrese yani funct_sub'a atlıyoruz ve şu anki pc değerini x1 register'ına kaydediyoruz geri dönüş için.

return_point_jalr:
    li x5,1 # jalr return point'e ulaştıysak jalr doğru çalışıyor.
    j test_end

funct_add:
    add  x14,x8,x9
    jalr x0,x1,0 # jalr ile x1 register'ı içindeki kaydedilmiş pc değerine geri dönüyoruz, offset olarak 0 kullanıyoruz, mevcut pc değerini ise x0 register'ına
                 # yazıyoruz, x0 register'ına yazma yapılamadığı için aslında çöpe atıyoruz çünkü geri dönerken pc değerini kaydetmemize gerek yok.

funct_sub:
    sub x15,x8,x9
    jalr x0,x1,0

test_end:
    j test_end
