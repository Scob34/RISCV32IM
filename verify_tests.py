import os
import subprocess
import shutil
import sys
import glob
import time

# ==============================================================================
# AYARLAR
# ==============================================================================
ROOT_DIR = os.getcwd()
OBJ_DIR_EXE = "./obj_dir/Vtb"          
TESTS_ROOT_DIR = "riscv-tests"         
OUTPUT_DIR = "my_outputs"        
WAVE_DIR   = "my_waveforms"      
TB_INPUT_FILE = "instruction.hex"
DEFAULT_VCD_NAME = "dump.vcd"    

# Terminal Renkleri
class Colors:
    HEADER = '\033[95m'
    OKGREEN = '\033[92m'
    FAIL = '\033[91m'
    RESET = '\033[0m'

# ==============================================================================
# YARDIMCI FONKSİYONLAR
# ==============================================================================

def get_clean_trace_for_compare(lines):
    """
    Hafızadaki karşılaştırma için temizlik yapar.
    Dosyadaki veriye DOKUNMAZ.
    """
    cleaned = []
    for line in lines:
        stripped = line.strip()
        
        # SUCCESS veya $finish gördüğümüz an okumayı kesiyoruz.
        if "SUCCESS: Test End Reached" in line:
            break
        if "Verilog $finish" in line:
            break

        # Sadece hex adresle (0x...) başlayan satırları al
        if stripped.startswith("0x"):
            cleaned.append(stripped)
            
    return cleaned

def compile_project():
    """
    Projeyi derler ve derleme çıktısını (stdout) string olarak döndürür.
    Böylece bu çıktıyı log dosyalarının tepesine ekleyebiliriz.
    """
    print(f"{Colors.HEADER}[INFO] Proje Derleniyor...{Colors.RESET}")
    
    # capture_output=True ile hem stdout hem stderr'i yakalıyoruz
    result = subprocess.run(["make", "build"], capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"{Colors.FAIL}[ERROR] Derleme Hatası!{Colors.RESET}")
        print(result.stderr)
        sys.exit(1)
        
    print(f"{Colors.OKGREEN}[OK] Derleme Başarılı.{Colors.RESET}\n")
    
    # Hem standart çıktıyı hem de hata çıktısını birleştirip döndür
    return result.stdout + "\n" + result.stderr

def find_test_files():
    """Test dosyalarını bulur."""
    search_pattern = os.path.join(TESTS_ROOT_DIR, "*", "verification_output", "*_pure.hex")
    return sorted(glob.glob(search_pattern))

def save_waveform(test_name):
    """Waveform dosyasını taşır."""
    destination = os.path.join(WAVE_DIR, f"{test_name}.vcd")
    
    if os.path.exists(destination):
        os.remove(destination)

    if os.path.exists(DEFAULT_VCD_NAME):
        #time.sleep(0.1) 
        shutil.move(DEFAULT_VCD_NAME, destination)

def run_single_test(hex_path, build_log):
    base_name = os.path.basename(hex_path).replace("_pure.hex", "")
    dir_path = os.path.dirname(hex_path)
    golden_path = os.path.join(dir_path, f"{base_name}_golden.log")
    
    my_log_path = os.path.join(OUTPUT_DIR, f"{base_name}.log")

    if not os.path.exists(golden_path):
        print(f"{base_name:20} : {Colors.FAIL}SKIP (Golden Yok){Colors.RESET}")
        return False

    # 1. HEX Kopyala
    shutil.copy(hex_path, TB_INPUT_FILE)

    # 2. Simülasyonu Çalıştır
    try:
        result = subprocess.run([OBJ_DIR_EXE], capture_output=True, text=True, timeout=10)
        raw_output_str = result.stdout
        raw_output_lines = raw_output_str.splitlines()
        
        if result.stderr:
            raw_output_str += "\n--- STDERR ---\n" + result.stderr

    except subprocess.TimeoutExpired:
        # Timeout durumunda bile logu yazalım
        with open(my_log_path, "w") as f:
            f.write(build_log) # Önce build logunu yaz
            f.write("-" * 60 + "\n")
            f.write(f"TEST RUN: {base_name}\n")
            f.write("-" * 60 + "\n")
            f.write("\n[TIMEOUT] Simulation took too long!\n")
            
        print(f"{base_name:20} : {Colors.FAIL}TIMEOUT{Colors.RESET}")
        save_waveform(base_name)
        return False

    # 3. HAM ÇIKTIYI DOSYAYA YAZ (Build Log + Sim Log)
    with open(my_log_path, "w") as f:
        # A. En tepeye Derleme (Make) çıktılarını koyuyoruz
        f.write(build_log)
        
        # B. Araya bir ayraç koyuyoruz (Okunabilirlik için, istersen kaldır)
        f.write("\n" + "="*60 + "\n")
        f.write(f" SIMULATION OUTPUT FOR: {base_name}")
        f.write("\n" + "="*60 + "\n")
        
        # C. Simülasyon çıktılarını (Warning, Trace, Success) ekliyoruz
        f.write(raw_output_str)

    # 4. Waveform Kaydet
    save_waveform(base_name)

    # 5. KARŞILAŞTIRMA
    with open(golden_path, 'r') as f:
        gold_raw_lines = f.readlines()

    my_trace = get_clean_trace_for_compare(raw_output_lines)
    gold_trace = get_clean_trace_for_compare(gold_raw_lines)

    if my_trace == gold_trace:
        print(f"{base_name:20} : {Colors.OKGREEN}PASS{Colors.RESET}")
        return True
    else:
        print(f"{base_name:20} : {Colors.FAIL}FAIL{Colors.RESET} -> (Log: {base_name}.log | Wave: {base_name}.vcd)")
        return False

# ==============================================================================
# MAIN
# ==============================================================================
def main():
    if os.path.exists(OUTPUT_DIR): shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR)

    if os.path.exists(WAVE_DIR): shutil.rmtree(WAVE_DIR)
    os.makedirs(WAVE_DIR)

    if os.path.exists(DEFAULT_VCD_NAME): os.remove(DEFAULT_VCD_NAME)

    # 1. Projeyi Derle ve Logunu Sakla
    build_log_content = compile_project()

    tests = find_test_files()
    
    if not tests:
        print("Test dosyası bulunamadı!")
        return

    print(f"{'TEST NAME':20} : STATUS")
    print("-" * 30)

    passed_count = 0
    for test_hex in tests:
        # run_single_test'e build logunu da gönderiyoruz
        if run_single_test(test_hex, build_log_content):
            passed_count += 1
            
    if os.path.exists(TB_INPUT_FILE):
        os.remove(TB_INPUT_FILE)

    print("-" * 30)
    if passed_count == len(tests):
        print(f"{Colors.OKGREEN}TÜM TESTLER GEÇTİ ({passed_count}/{len(tests)}){Colors.RESET}")
    else:
        print(f"{Colors.FAIL}{len(tests) - passed_count} TEST BAŞARISIZ!{Colors.RESET}")
        print(f"Loglar: '{OUTPUT_DIR}' | Waveformlar: '{WAVE_DIR}' klasöründe.")

if __name__ == "__main__":
    main()
