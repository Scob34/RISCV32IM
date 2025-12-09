OUTPUT_ARCH( "riscv" )
ENTRY( _start )

SECTIONS
{
  /* 1. Kod Bölümü: Spike'ın başlangıç adresi */
  . = 0x80000000;
  
  .text : {
    *(.text.init)   /* Önce başlangıç kodları */
    *(.text)        /* Sonra diğer kodlar */
  }

  /* Kod ile veri arasına hizalama koyalım */
  . = ALIGN(16);

  /* 2. Read-Only Data (Sabitler, stringler) */
  .rodata : { 
    *(.rodata) 
  }

  . = ALIGN(16);

  /* 3. Data (Yazılabilir veriler) */
  .data : { 
    *(.data) 
  }

  /* 4. BSS (Sıfırlanmış veriler - C kodu için şarttır) */
  .bss : { 
    *(.bss) 
  }

  /* Kodun bittiği yeri işaretle */
  _end = .;
}
