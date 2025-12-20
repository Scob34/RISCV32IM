import os
import glob
import subprocess
import shutil
import re

# ==========================================
# 1. TOOLCHAIN AYARLARI
# ==========================================
PREFIX = "riscv64-unknown-elf-"
AS_CMD = f"{PREFIX}as"
AS_FLAGS = ["-march=rv32im", "-mabi=ilp32"]

LD_CMD = f"{PREFIX}ld"
LD_FLAGS = ["-m", "elf32lriscv", "-T", "linker.ld"] 

OBJDUMP_CMD = f"{PREFIX}objdump"
OBJDUMP_FLAGS = ["-D", "-M", "numeric"]

NM_CMD = f"{PREFIX}nm"  # Sembol (Etiket) adreslerini okuyan araç

SPIKE_CMD = "spike"
SPIKE_FLAGS_BASE = [
    "-d", "-l", "--log-commits", 
    "-m0x7ffff000:0x20000000", "--isa=rv32im"
]

# KODUN DURACAĞI ETİKET İSMİ
EXIT_LABEL = "test_end"

# ==========================================
# 2. KLASÖR İSİMLERİ
# ==========================================
CENTRAL_SOURCE_DIR = "asm_sources"
BUILD_DIR_NAME = "build"
OUTPUT_DIR_NAME = "verification_output"

# ==========================================
# 3. YARDIMCI FONKSİYONLAR
# ==========================================

def run_cmd(cmd_list, description, stderr_file=None, stdout_file=None):
    try:
        subprocess.run(
            cmd_list, check=True, text=True,
            stdout=stdout_file, stderr=stderr_file
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"   ❌ {description} Hatası!")
        return False

def get_label_address(elf_path, label_name):
    """
    nm aracı ile elf dosyasındaki 'test_end' etiketinin adresini bulur.
    Dönen değer string formatında hex adrestir (örn: '0x80000048').
    """
    try:
        # nm komutunu çalıştır: sembolleri listele
        result = subprocess.run(
            [NM_CMD, elf_path], 
            capture_output=True, text=True, check=True
        )
        
        # Çıktıyı satır satır oku
        for line in result.stdout.splitlines():
            if label_name in line:
                parts = line.split()
                # Adres genelde ilk sütundadır
                address = "0x" + parts[0]
                return address
        return None
    except Exception as e:
        print(f"   ⚠️ Adres bulma hatası: {e}")
        return None

def create_dynamic_spike_script(script_path, stop_address):
    """Her test için özel spike scripti oluşturur."""
    # q (quit) komutu çok önemli, yoksa script donar
    content = f"until pc 0 {stop_address}\nq\n"
    with open(script_path, "w") as f:
        f.write(content)

def filter_log(input_path, output_path):
    pc_pattern = re.compile(r'core\s+\d+:\s*\d+\s*(0x[0-9a-fA-F]+)')
    clean_pattern = re.compile(r'^core\s+\d+:\s*\d+\s*')
    start_trigger = "0x80000000"
    found_start = False
    
    try:
        with open(input_path, 'r') as fin, open(output_path, 'w') as fout:
            for line in fin:
                if not found_start:
                    match = pc_pattern.search(line)
                    if match and match.group(1) == start_trigger:
                        found_start = True
                    else: continue
                fout.write(clean_pattern.sub('', line))
        return True
    except: return False

def extract_hex(input_path, output_path):
    pattern = re.compile(r'^\s*[0-9a-fA-F]+:\s+([0-9a-fA-F]{8})\s')
    try:
        with open(input_path, "r") as fin, open(output_path, "w") as fout:
            for line in fin:
                m = pattern.match(line)
                if m: fout.write(m.group(1) + "\n")
        return True
    except: return False

# ==========================================
# 4. ANA AKIŞ
# ==========================================

def main():
    # Klasör yoksa oluştur
    if not os.path.exists(CENTRAL_SOURCE_DIR): os.makedirs(CENTRAL_SOURCE_DIR)
    
    # 1. Ana dizindeki .s dosyalarını bul
    files_in_root = glob.glob("*.s")
    
    # 2. asm_sources içindeki .s dosyalarını bul (Yolu tam alarak)
    files_in_subdir = glob.glob(os.path.join(CENTRAL_SOURCE_DIR, "*.s"))
    
    # Hepsini birleştir
    all_asm_files = files_in_root + files_in_subdir

    if not all_asm_files:
        print("⚠️  İşlenecek .s dosyası bulunamadı (Ana dizinde veya asm_sources içinde yok).")
        return

    cwd = os.getcwd()
    linker_script = os.path.join(cwd, "linker.ld")
    
    if not os.path.exists(linker_script):
        print("❌ HATA: 'linker.ld' dosyası ana dizinde bulunamadı!")
        return

    print(f"🚀 {len(all_asm_files)} test bulundu. Dinamik Spike Otomasyonu Başlıyor...\n")
    
    success_cnt = 0
    fail_cnt = 0

    for source_path in all_asm_files:

        # ... (filename ve test_name tanımları burada) ...
        filename = os.path.basename(source_path)
        test_name = os.path.splitext(filename)[0]

        test_root = os.path.join(cwd, test_name)
        dir_build = os.path.join(test_root, BUILD_DIR_NAME)
        path_elf = os.path.join(dir_build, f"{test_name}.elf")

        # --- AKILLI KONTROL (INCREMENTAL BUILD) ---
        # 1. Elf dosyası var mı?
        # 2. Kaynak dosya (.s), Elf dosyasından daha mı ESKİ?
        # Eğer ikisi de evetse, demek ki kod değişmemiş. Tekrar derlemeye gerek yok.
        if os.path.exists(path_elf):
            src_mtime = os.path.getmtime(source_path)
            elf_mtime = os.path.getmtime(path_elf)
            
            if src_mtime < elf_mtime:
                print(f"🔹 [{test_name}] Değişiklik yok, atlanıyor...")
                success_cnt += 1 # Başarılı sayıyoruz çünkü zaten sağlam
                continue 
        
        # Eğer buraya geldiyse ya dosya yeni ya da değiştirilmiş.
        print(f"🔹 [{test_name}] İşleniyor... (Değişiklik Algılandı)")
        
        # ... (Geri kalan kodlar aynen devam eder) ...

        # source_path artık tam yol olabilir (örn: asm_sources/beq.s)
        # Dosya adını güvenli şekilde al
        filename = os.path.basename(source_path)
        test_name = os.path.splitext(filename)[0]
        
        print(f"🔹 [{test_name}] İşleniyor...")

        # Test klasörleri ana dizinde oluşturulacak (beq/, bne/ gibi)
        test_root = os.path.join(cwd, test_name)
        dir_build = os.path.join(test_root, BUILD_DIR_NAME)
        dir_out   = os.path.join(test_root, OUTPUT_DIR_NAME)

        os.makedirs(dir_build, exist_ok=True)
        os.makedirs(dir_out, exist_ok=True)

        # Dosya Yolları
        # path_src artık source_path'ten geliyor (neredeyse oradan okur)
        path_obj      = os.path.join(dir_build, f"{test_name}.o")
        path_elf      = os.path.join(dir_build, f"{test_name}.elf")
        path_dump_raw = os.path.join(dir_build, f"{test_name}.objdump")
        path_log_raw  = os.path.join(dir_build, f"{test_name}.log")
        path_spike_scr= os.path.join(dir_build, "spike_autogen.script")
        
        path_hex      = os.path.join(dir_out, f"{test_name}_pure.hex")
        path_log_gold = os.path.join(dir_out, f"{test_name}_golden.log")
        path_dump_cpy = os.path.join(dir_out, f"{test_name}.objdump")

        # 1. ASSEMBLE (source_path kullanıyoruz)
        if not run_cmd([AS_CMD] + AS_FLAGS + ["-o", path_obj, source_path], "Assembler"):
            fail_cnt += 1; continue

        # 2. LINK
        if not run_cmd([LD_CMD] + LD_FLAGS + ["-o", path_elf, path_obj], "Linker"):
            fail_cnt += 1; continue

        # --- DİNAMİK ADRES BULMA ---
        stop_addr = get_label_address(path_elf, EXIT_LABEL)
        
        if stop_addr:
            create_dynamic_spike_script(path_spike_scr, stop_addr)
        else:
            print(f"   ⚠️  UYARI: '{EXIT_LABEL}' etiketi bulunamadı! Spike sonsuza kadar çalışabilir.")
            with open(path_spike_scr, "w") as f: pass

        # 3. OBJDUMP
        with open(path_dump_raw, "w") as f:
            if not run_cmd([OBJDUMP_CMD] + OBJDUMP_FLAGS + [path_elf], "Objdump", stdout_file=f):
                fail_cnt += 1; continue
        
        shutil.copy(path_dump_raw, path_dump_cpy)
        extract_hex(path_dump_raw, path_hex)

        # 4. SPIKE
        spike_full_cmd = [SPIKE_CMD] + SPIKE_FLAGS_BASE + \
                         [f"--debug-cmd={path_spike_scr}", path_elf]
        
        with open(path_log_raw, "w") as f:
            run_cmd(spike_full_cmd, "Spike", stderr_file=f)
        
        # 5. FİLTRELEME & TAŞIMA MANTIĞI (GÜNCELLENDİ)
        filter_log(path_log_raw, path_log_gold)
        
        # Sadece dosya ANA DİZİNDEYSE taşı. Zaten asm_sources içindeyse dokunma.
        # Kontrol: source_path içinde "asm_sources" geçiyor mu?
        if CENTRAL_SOURCE_DIR not in source_path:
            dest_src = os.path.join(CENTRAL_SOURCE_DIR, filename)
            shutil.move(source_path, dest_src)
            print(f"   ✅ Tamamlandı ve arşivlendi.")
        else:
            print(f"   ✅ Tamamlandı (Zaten arşivde).")
            
        success_cnt += 1

    print("\n" + "="*40)
    print(f"RAPOR: {success_cnt} Başarılı, {fail_cnt} Hatalı")
    print("="*40)

if __name__ == "__main__":
    main()
