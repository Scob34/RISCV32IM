.global _start
_start:
    nop
_init:
    nop

.data 
dizi: .space 20 # 5 elemanlı bos dizi olusturuyoruz 20/4 byte = 5

.text
main:
    la x10, dizi # bos dizinin baslangıc adresini aldık

    addi x5,x0, 0   # faktoriyelin baslangic elemanı 
    addi x6,x0, 0   # dış dongu baslangıcı i = 0
    addi x7,x0, 5   # dış dongu sınırı 
    addi x8,x0, 1   # ic dongu baslangic toplama degeri
    addi x9,x0, 1   # ic dongu baslangic sinir degeri
    addi x11,x0, 0  # ic dongu baslangıcı j = 0

    # carpma fonksiyonuna atladık ve return adresi x1 registerına kaydettik
    jal x1, faktoriyel

    # carpma isi bittikten sonra dizinin her elemanını load edicez(ekrana basma simülasyonu)
    addi x6,x0,0   # dıs döngü baslangıcını sıfırlıyoruz
    la x10, dizi # dizinin baslangic adresini tekrar x10 registerına yüklüyoruz
    jal x1, load

    jal x0,test_end 


faktoriyel:
    addi x5,x0,0

    carpma:
        add x5,x5,x8  # baslangic degerini ic dongu toplama degeriyle topluyoruz her seferinde
        addi x11,x11,1    # ic dongu degerini 1 artırıyoruz 
        blt x11,x9, carpma # eger ic dongu sınır degerinden kücükse toplama islemine devam ediyoruz
    
    add x8,x5,x0 # baslangıc toplama degerini artırıyoruz
    addi x9,x9,1    # ic dongu sınır degerini artırıyoruz
    sw x5,0(x10) # her elemanı ayırdıgımız bellek alanına yazıyoruz 
    addi x10,x10,4   # bellek adresini her defasında +4 ilerletiyoruz(4 byte bir word)
    addi x6,x6,1    # dış dongu başlangıcını artırıyoruz
    addi x11,x0,0   # ic dongu baslangıcını her defasında sıfırlıyoruz 
    blt x6,x7,faktoriyel # dış döngü baslangıcı sınırdan küçükse devam ediyoruz 
    jalr x0,0(x1) # işimiz bittikten sonra fonksiyonu çağırdığımız adrese dönüyoruz

load:
    lw x12, 0(x10) # x12 register'ının her 4 byte'ına x10 adresindeki veriyi yüklüyoruz
    addi x10,x10,4 # dizi adresini +4 artırıyoruz
    addi x6,x6,1 # dongu sayacını 1 artırıyoruz 
    blt x6,x7,load # dıs döngü sınırına gelene kadar load işlemine devam ediyoruz
    jalr x0,0(x1) # isimiz bittikten sonra fonksiyonu çağırdığımız adrese dönüyoruz 
 
test_end:
    j test_end






