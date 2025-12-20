module tb ();
    import riscv_pkg::*;
    //logic [riscv_pkg::XLEN-1:0] addr;
    //logic [riscv_pkg::XLEN-1:0] data;
    logic [riscv_pkg::XLEN-1:0] pc;
    logic                       update;
    logic                       clk;
    logic                       rstn;
    logic [riscv_pkg::XLEN-1:0] instr;
    logic [                4:0] reg_addr;
    logic [riscv_pkg::XLEN-1:0] reg_data;
    logic [riscv_pkg::XLEN-1:0] mem_write_data;
    logic [riscv_pkg::XLEN-1:0] mem_read_addr;
    logic [riscv_pkg::XLEN-1:0] mem_write_addr;
    logic                       mem_write_enable;
    logic                       mem_read_enable;
    logic                       reg_file_write_enable;
    riscv_pkg:: operation_e     operation;

    //test.log ile pc.log karşılaştırması yaparken daha rahat edebilmek için instr, reg_addr ve reg_data'yı ekledik ki program counter(pc) yanında bunları da
    //ekrana basalım ve test.log ile aynı formatta olsun.
    core_model i_core_model (
        .clk(clk),
        .rstn(rstn),
        .pc_o(pc),
        .update_o(update),
        .instr_o(instr),
        .reg_addr_o(reg_addr),
        .reg_data_o(reg_data),
        .memory_read_addr_o(mem_read_addr),
        .memory_write_addr_o(mem_write_addr),
        .memory_write_data_o(mem_write_data),
        .memory_read_enable_o(mem_read_enable),
        .memory_write_enable_o(mem_write_enable),
        .register_file_write_enable_o(reg_file_write_enable),
        .operation_o(operation)
    );

// CLOCK SİNYALİ ÜRETİMİ
    initial begin
        clk = 0;
        forever #1 clk = ~clk;     //her 1 ns de clock sinyali değişiyor
    end


// İŞLEMCİ RESETLENMEİ VE SİMÜLASYONUN BİTMESİ
    initial begin
        rstn = 0; // işlemci resetleniyor
        #20;
        rstn = 1; // 20 birim saniye sonra işlemci resetten çıkıyor ve çalışmaya başlıyor.

        #10000; // 10000 birim saniye bekliyoruz, eğer sonsuz döngüye girersek simülasyon bir süre sonra kendiliğinden bitsin.
        $display("-------------------------------------------------------------");
        $display("Simulation timed out and forced to stop!");
        $display("-------------------------------------------------------------");
        $finish;
    end

// SONSUZ DÖNGÜ DEDEKTÖRÜ
    always @(posedge clk) begin
        if (rstn && (instr == 32'h0000006f)) begin // Eğer 32'h0000006f komutu ile karşılaşırsak programın sonunda sonsuz döngüye girmişiz demektir.
             // Simülasyonun log dosyasını tam yazması için çok kısa bekledik
            //#1; 
            $display("-------------------------------------------------------------");
            $display("SUCCESS: Test End Reached (PC: 0x%h)", pc);
            $display("-------------------------------------------------------------");
            $finish;
        end
    end

// LOGLAMA İŞLEMLERİ

    always_comb begin
        if(pc == 32'h80000000) begin
            $display("0x%8h (0x%8h) ", pc, instr);
        end
    end
    always @(posedge clk) begin
        if (rstn && update && (pc != 0)) begin

            // A) MEMORY WRITE (STORE) LOGLARI
            if(mem_write_enable) begin
                case(operation)
                    SW: $display("0x%8h (0x%8h) mem 0x%8h 0x%8h", pc, instr, mem_write_addr, mem_write_data);
                    SH: $display("0x%8h (0x%8h) mem 0x%8h 0x%4h", pc, instr, mem_write_addr, mem_write_data[15:0]);
                    SB: $display("0x%8h (0x%8h) mem 0x%8h 0x%2h", pc, instr, mem_write_addr, mem_write_data[7:0]);
                    default: ;
                endcase
            end
            
            // B) MEMORY READ (LOAD) LOGLARI
            else if (mem_read_enable && (reg_addr != 0)) begin
                // Tek haneli registerlar için hizalama (x1  vs x10)
                if(reg_addr < 10)
                    $display("0x%8h (0x%8h) x%0d  0x%8h mem 0x%8h", pc, instr, reg_addr, reg_data, mem_read_addr);
                else
                    $display("0x%8h (0x%8h) x%0d 0x%8h mem 0x%8h", pc, instr, reg_addr, reg_data, mem_read_addr);
            end
            
            // C) NORMAL ALU/BRANCH LOGLARI
            else begin
                // Yazma yapmıyorsa (Branch/Nop vs.) veya x0'a yazıyorsa sadece PC ve Instr bas
                if(reg_addr == 0 || !reg_file_write_enable)
                    $display("0x%8h (0x%8h) ", pc, instr);
                else begin
                    if(reg_addr < 10)
                        $display("0x%8h (0x%8h) x%0d  0x%8h", pc, instr, reg_addr, reg_data);
                    else
                        $display("0x%8h (0x%8h) x%0d 0x%8h", pc, instr, reg_addr, reg_data);
                end
            end
        end
    end

// DUMP FILE ÜRETİMİ
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0,tb);
    end

// CPI HESAPLAMA
    longint total_cycles; // toplam geçen döngü sayısı yani zaman
    longint committed_instructions; // gerçekten tamamlanan yani flush olmayan talimat sayısı

    always @(posedge clk) begin
        if (!rstn) begin 
            total_cycles <= 0;
            committed_instructions <= 0;
        end 
        else begin
            // Toplam Döngü Sayacı, her döngüde artar
            total_cycles <= total_cycles + 1; 

            // Tamamlanan Talimat Sayacı, sadece update sinyali aktif ve pc 0 değilse artar
            if (update && (pc != 0)) begin
                committed_instructions <= committed_instructions + 1;
            end
        end
    end

    // Simülasyon sonunda CPI değerini hesaplayıp yazdırma
    final begin
        real cpi;
        cpi = real'(total_cycles) / real'(committed_instructions);
        $display("-------------------------------------------------------------");
        if(committed_instructions > 0) begin
            $display("Total Cycles: %0d", total_cycles);
            $display("Committed Instructions: %0d", committed_instructions);
            $display("CPI: %0.4f", cpi);
        end
        else begin
            $display("HATA: Hiçbir Komut Tamamlanamadı!");
            $display("Total Cycles: %0d", total_cycles);
        end
        $display("-------------------------------------------------------------");
    end


endmodule
