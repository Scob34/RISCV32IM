.global _start

_start:
    nop
_init:
    nop

main:
    li  x1,0x80001000   # base address değeri olarak belirledik, bu adrese göre yazma okuma yapıcaz adresler çakışmasın diye.

test_signed_unsigned:

    li  x5,-1 # x5 register'ına 0xFFFFFFFF yazdık.
    sb  x5,0(x1) # x1 register'ı içerisindeki base adres değeri üzerine 0 offsetini ekleyerek yani adresin kendisine x5 register'ı içindeki veriyi yazdık.

    lb  x6,0(x1) # x1 register'ı içindeki base adres değerinin kendisini kullanarak load yaptık ve veriyi x6'ya yükledik.  x6 = 0xFFFFFFFF olmalı.
    lbu x7,0(x1) # x7 = 0x000000FF olmalı çünkü lbu unsigned olduğu için veriyi 0 ile genişletir. lb veriyi işaret biti ile genişletiyor.
test_little_endian_write_read:

    li x11,0x11223344
    sw x11,4(x1) # x11 register'ı içerisindeki veriyi base address + offset(4) adresine yazdık yani 4 byte ilerledik 1 satır atlamış olduk, dizinin 2. elemanı gibi düşünelim.
                 # dikkat edelim, yazma işlemi little-endian yani sağdan sola doğru yapılır bu durumda adrese veri 44 33 22 11 şeklinde yerleşir.

    lb x12,4(x1) # x12 = 0x44 olmalı
    lb x13,5(x1) # x13 = 0x33 olmalı
    lb x14,6(x1) # x14 = 0x22 olmalı
    lb x15,7(x1) # x15 = 0x11 olmalı

test_parca_parca_yazma:

    li x20,0xAA
    sb x20,16(x1) 

    li x21,0xBB
    sb x21,17(x1)

    li x22,0xCC
    sb x22,18(x1)

    li x23,0xDD
    sb x23,19(x1)

    lw x24,16(x1) # beklenen değer 0xDDCCBBAA # little-endian'da bu şekilde olur, adres satırının en büyük byte'ı en erken okunur.

test_end:
    j test_end
