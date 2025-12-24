module core_model
    import riscv_pkg::*;
(
    input  logic            clk,
    input  logic            rstn,
    output logic [XLEN-1:0] pc_o,
    output logic [XLEN-1:0] instr_o,
    output logic [     4:0] reg_addr_o,
    output logic [XLEN-1:0] reg_data_o,
    output logic            update_o,
    output logic [XLEN-1:0] memory_read_addr_o,
    output logic [XLEN-1:0] memory_write_addr_o,
    output logic [XLEN-1:0] memory_write_data_o,
    output logic            memory_read_enable_o,
    output logic            memory_write_enable_o,
    output logic            register_file_write_enable_o,
    output operation_e      operation_o
);

/////////////////////////////////////////////////////////////////////////FETCH AŞAMASI//////////////////////////////////////////////////////////////////////////

    //Procram_Counter_Change_Comb
    logic [XLEN-1:0] pc_d_fetch;
    
    always_comb begin : program_counter_change_comb
        if(jump_pc_valid_d_execute)
            pc_d_fetch = jump_pc_d_execute;
        else
            pc_d_fetch = pc_q_fetch + 4;
    end

    //Program_Counter_Change_FF
    logic [XLEN-1:0] pc_q_fetch;
    logic            update_q_fetch;

    always_ff @(posedge clk or negedge rstn) begin : program_counter_change_ff
        if(!rstn) begin
            pc_q_fetch <= 'h8000_0000;
            update_q_fetch <= 0;
        end
        else if(is_Stall_PC_FF) begin
            pc_q_fetch <= pc_q_fetch;
            update_q_fetch <= update_q_fetch;
        end
        else begin
            pc_q_fetch <= pc_d_fetch;
            update_q_fetch <= 1;
        end
    end

    //Instruction_Read_Comb
    logic [31:0] instruction_memory [MEM_SIZE-1:0]; // Intruction memory tanımı
    //initial $readmemh("./riscv-tests/div_rem/verification_output/div_rem_pure.hex", instruction_memory, 0, MEM_SIZE);
    initial $readmemh("instruction.hex", instruction_memory, 0, MEM_SIZE); // script için instruction yükleme


    logic [XLEN-1:0] instr_d_fetch;

    always_comb begin : instruction_read_comb
        instr_d_fetch = instruction_memory[pc_q_fetch[$clog2(MEM_SIZE*4) - 1 : 2]];
    end

    // IF/ID Register
    logic [XLEN-1:0] instr_q_fetch;
    logic [XLEN-1:0] pc_q_fetch_to_decode;
    logic            update_q_fetch_to_decode;

    always_ff @(posedge clk or negedge rstn) begin : IF_ID_REGISTER
        if(!rstn || is_Flush_IF_ID_Register) begin
            instr_q_fetch <= 0;
            pc_q_fetch_to_decode <= 0;
            update_q_fetch_to_decode <= 0;
        end
        else if(is_Stall_IF_ID_Register) begin
            instr_q_fetch <= instr_q_fetch;
            pc_q_fetch_to_decode <= pc_q_fetch_to_decode;
            update_q_fetch_to_decode <= update_q_fetch_to_decode;
        end
        else begin
            instr_q_fetch <= instr_d_fetch;
            pc_q_fetch_to_decode <= pc_q_fetch;
            update_q_fetch_to_decode <= update_q_fetch;
        end
    end

/////////////////////////////////////////////////////////////////////////DECODE AŞAMASI/////////////////////////////////////////////////////////////////////////

    //=========================================================== INPUTLAR ================================================
    logic [XLEN-1:0] instr_d_decode;
    assign instr_d_decode = instr_q_fetch;

    logic [XLEN-1:0] pc_d_decode;
    assign pc_d_decode = pc_q_fetch_to_decode;

    logic            update_d_decode;
    assign update_d_decode = update_q_fetch_to_decode;

    //==================================================== INTERNAL DEĞİŞKENLER ============================================
    logic [XLEN-1:0] imm_data_d_decode;

    logic [     4:0] shamt_data_d_decode;
    assign shamt_data_d_decode = instr_d_decode[24:20];

    logic            register_file_write_enable_d_decode;
    logic            data_memory_write_enable_d_decode;
    logic            data_memory_read_enable_d_decode;
    
    logic [     4:0] rd_d_decode;
    assign rd_d_decode = instr_d_decode[11:7];

    logic [     4:0] rs1_addr_d_decode;
    assign rs1_addr_d_decode = instr_d_decode[19:15];

    logic [     4:0] rs2_addr_d_decode;
    assign rs2_addr_d_decode = instr_d_decode[24:20];

    logic [XLEN-1:0] rs1_data_d_decode;

    logic [XLEN-1:0] rs2_data_d_decode;

    operation_e operation_d_decode;


    //================================================== ID/IEX REGISTER OUTPUTS =============================================
    logic [XLEN-1:0] instr_q_decode;
    logic [XLEN-1:0] pc_q_decode;
    logic            update_q_decode;

    logic [XLEN-1:0] imm_data_q_decode;
    logic [     4:0] shamt_data_q_decode;

    logic            register_file_write_enable_q_decode;
    logic            data_memory_write_enable_q_decode;
    logic            data_memory_read_enable_q_decode;

    logic [     4:0] rd_q_decode;

    logic [     4:0] rs1_addr_q_decode;
    logic [     4:0] rs2_addr_q_decode;

    logic [XLEN-1:0] rs1_data_q_decode;
    logic [XLEN-1:0] rs2_data_q_decode;

    operation_e operation_q_decode;

    //======================================= CONTROL SİNYELLERİ, IMMEDIATE DEĞERİ ATAMALARI ===================================
    always_comb begin : DECODE_BLOCK
        imm_data_d_decode = 0;

        register_file_write_enable_d_decode = 0;
        data_memory_write_enable_d_decode = 0;
        data_memory_read_enable_d_decode = 0;

        operation_d_decode = OPERATION_UNKNOWN;

        case(instr_d_decode[6:0])
            OpcodeLui: begin
                imm_data_d_decode = get_u_type_imm(instr_d_decode);
                operation_d_decode = LUI;
                register_file_write_enable_d_decode = 1;    
            end
            OpcodeAuipc: begin
                imm_data_d_decode = get_u_type_imm(instr_d_decode);
                operation_d_decode = AUIPC;
                register_file_write_enable_d_decode = 1;
            end
            OpcodeJal: begin
                imm_data_d_decode = get_j_type_imm(instr_d_decode);
                operation_d_decode = JAL;
                register_file_write_enable_d_decode = 1;
            end
            OpcodeJalr: begin
                imm_data_d_decode = get_i_type_imm(instr_d_decode);
                operation_d_decode = JALR;
                register_file_write_enable_d_decode = 1;
            end
            OpcodeBranch: begin
                imm_data_d_decode = get_b_type_imm(instr_d_decode);
                case(instr_d_decode[14:12])
                    F3_BEQ:  operation_d_decode = BEQ;
                    F3_BNE:  operation_d_decode = BNE;
                    F3_BLT:  operation_d_decode = BLT;
                    F3_BGE:  operation_d_decode = BGE;
                    F3_BLTU: operation_d_decode = BLTU;
                    F3_BGEU: operation_d_decode = BGEU;
                    default: ;
                endcase
            end
            OpcodeLoad: begin
                imm_data_d_decode = get_i_type_imm(instr_d_decode);
                register_file_write_enable_d_decode = 1;
                data_memory_read_enable_d_decode = 1;
                case(instr_d_decode[14:12])
                    F3_LB:  operation_d_decode = LB;
                    F3_LH:  operation_d_decode = LH;
                    F3_LW:  operation_d_decode = LW;
                    F3_LBU: operation_d_decode = LBU;
                    F3_LHU: operation_d_decode = LHU;
                    default: ;
                endcase
            end
            OpcodeStore: begin
                imm_data_d_decode = get_s_type_imm(instr_d_decode);
                data_memory_write_enable_d_decode = 1;
                case(instr_d_decode[14:12])
                    F3_SB: operation_d_decode = SB;
                    F3_SH: operation_d_decode = SH;
                    F3_SW: operation_d_decode = SW;
                    default: ;
                endcase
            end
            OpcodeOpImm_Zbb: begin
                register_file_write_enable_d_decode = 1;
                imm_data_d_decode = get_i_type_imm(instr_d_decode);
                case(instr_d_decode[14:12])
                    F3_SLLI_ZBB: begin
                        case(instr_d_decode[31:25])
                            F7_ZBB: begin
                                case(instr_d_decode[24:20])
                                    F5_CLZ:  operation_d_decode = CLZ;
                                    F5_CPOP: operation_d_decode = CPOP;
                                    F5_CTZ:  operation_d_decode = CTZ;
                                    default: ;
                                endcase
                            end
                            F7_SLLI: operation_d_decode = SLLI;

                            default: ;
                        endcase
                    end
                    F3_ADDI:  operation_d_decode = ADDI;
                    F3_SLTI:  operation_d_decode = SLTI;
                    F3_SLTIU: operation_d_decode = SLTIU;
                    F3_XORI:  operation_d_decode = XORI;
                    F3_ORI:   operation_d_decode = ORI;
                    F3_ANDI:  operation_d_decode = ANDI;
                    F3_SRLI_SRAI: begin
                        case(instr_d_decode[31:25])
                            F7_SRLI: operation_d_decode = SRLI;
                            F7_SRAI: operation_d_decode = SRAI;
                            default: ;
                        endcase
                    end

                    default:;
                endcase
            end
            OpcodeOp_Mext: begin
                register_file_write_enable_d_decode = 1;

                case(instr_d_decode[31:25])
                    F7_R_TYPE: begin
                        case(instr_d_decode[14:12])
                            F3_ADD_SUB: operation_d_decode = ADD;
                            F3_SLL:  operation_d_decode = SLL;
                            F3_SLT:  operation_d_decode = SLT;
                            F3_SLTU: operation_d_decode = SLTU;
                            F3_XOR:  operation_d_decode = XOR;
                            F3_SRL_SRA: operation_d_decode = SRL;
                            F3_OR:   operation_d_decode = OR;
                            F3_AND:  operation_d_decode = AND;
                        endcase
                    end
                    F7_SUB_SRA: begin
                        case(instr_d_decode[14:12])
                            F3_ADD_SUB: operation_d_decode = SUB;
                            F3_SRL_SRA: operation_d_decode = SRA;
                            default: ;
                        endcase
                    end
                    F7_MEXT: begin
                        case(instr_d_decode[14:12])
                            F3_MUL: operation_d_decode = MUL;
                            F3_MULH: operation_d_decode = MULH;
                            F3_MULHSU: operation_d_decode = MULHSU;
                            F3_MULHU: operation_d_decode = MULHU;
                            F3_DIV: operation_d_decode = DIV;
                            F3_DIVU: operation_d_decode = DIVU;
                            F3_REM: operation_d_decode = REM;
                            F3_REMU: operation_d_decode = REMU;
                        endcase
                    end
                    default: ;
                endcase                
            end
            default: ;
        endcase
    end

    //====================================================== REGISTER FILE ================================================

    logic [XLEN-1:0] register_file [31:0];
    assign rs1_data_d_decode =(register_file_write_enable_d_writeback && (rd_d_writeback != 0) && (rd_d_writeback == rs1_addr_d_decode)) ? rd_data_d_writeback : register_file[rs1_addr_d_decode];
    assign rs2_data_d_decode =(register_file_write_enable_d_writeback && (rd_d_writeback != 0) && (rd_d_writeback == rs2_addr_d_decode)) ? rd_data_d_writeback : register_file[rs2_addr_d_decode];

    always_ff @(posedge clk or negedge rstn) begin : REGISTER_FILE_WRITEBACK
        if(!rstn) begin
            for(int i = 0; i <32; i++) begin
                register_file[i] <= 0;
            end
        end
        else if(register_file_write_enable_d_writeback && (rd_d_writeback != 0))
            register_file[rd_d_writeback] <= rd_data_d_writeback;
    end

    //=====================================================  ID/IEX REGISTER ================================================

    always_ff @(posedge clk or negedge rstn) begin : ID_IEX_REGISTER
        if(!rstn || is_Flush_ID_IEX_Register) begin
            instr_q_decode <= 0;
            pc_q_decode <= 0;
            update_q_decode <= 0;
            
            imm_data_q_decode <= 0;
            shamt_data_q_decode <= 0;

            register_file_write_enable_q_decode <= 0;
            data_memory_write_enable_q_decode <= 0;
            data_memory_read_enable_q_decode <= 0;

            rd_q_decode <= 0;

            rs1_addr_q_decode <= 0;
            rs2_addr_q_decode <= 0;

            rs1_data_q_decode <= 0;
            rs2_data_q_decode <= 0;

            operation_q_decode <= OPERATION_UNKNOWN;
        end
        else if(is_Stall_ID_IEX_Register) begin
            instr_q_decode <= instr_q_decode;
            pc_q_decode <= pc_q_decode;
            update_q_decode <= update_q_decode;

            imm_data_q_decode <= imm_data_q_decode;
            shamt_data_q_decode <= shamt_data_q_decode;

            register_file_write_enable_q_decode <= register_file_write_enable_q_decode;
            data_memory_write_enable_q_decode <= data_memory_write_enable_q_decode;
            data_memory_read_enable_q_decode <= data_memory_read_enable_q_decode;

            rd_q_decode <= rd_q_decode;

            rs1_addr_q_decode <= rs1_addr_q_decode;
            rs2_addr_q_decode <= rs2_addr_q_decode;

            rs1_data_q_decode <= rs1_data_q_decode;
            rs2_data_q_decode <= rs2_data_q_decode;

            operation_q_decode <= operation_q_decode;
        end
        else begin
            instr_q_decode <= instr_d_decode;
            pc_q_decode <= pc_d_decode;
            update_q_decode <= update_d_decode;

            imm_data_q_decode <= imm_data_d_decode;
            shamt_data_q_decode <= shamt_data_d_decode;

            register_file_write_enable_q_decode <= register_file_write_enable_d_decode;
            data_memory_write_enable_q_decode <= data_memory_write_enable_d_decode;
            data_memory_read_enable_q_decode <= data_memory_read_enable_d_decode;

            rd_q_decode <= rd_d_decode;

            rs1_addr_q_decode <= rs1_addr_d_decode;
            rs2_addr_q_decode <= rs2_addr_d_decode;

            rs1_data_q_decode <= rs1_data_d_decode;
            rs2_data_q_decode <= rs2_data_d_decode;

            operation_q_decode <= operation_d_decode;
        end
    end

///////////////////////////////////////////////////////////////////////EXECUTE AŞAMASI//////////////////////////////////////////////////////////////////////////

    //=================================================== INPUTLAR ===========================================================

    logic [XLEN-1:0] instr_d_execute;
    assign instr_d_execute = instr_q_decode;

    logic [XLEN-1:0] pc_d_execute;
    assign pc_d_execute = pc_q_decode;

    logic            update_d_execute;
    assign update_d_execute = update_q_decode;

    logic [XLEN-1:0] imm_data_d_execute;
    assign imm_data_d_execute = imm_data_q_decode;

    logic [     4:0] shamt_data_d_execute;
    assign shamt_data_d_execute = shamt_data_q_decode;

    logic            register_file_write_enable_d_execute;
    assign register_file_write_enable_d_execute = register_file_write_enable_q_decode;

    logic            data_memory_write_enable_d_execute;
    assign data_memory_write_enable_d_execute = data_memory_write_enable_q_decode;

    logic            data_memory_read_enable_d_execute;
    assign data_memory_read_enable_d_execute = data_memory_read_enable_q_decode;

    logic [     4:0] rd_d_execute;
    assign rd_d_execute = rd_q_decode;

    logic [     4:0] rs1_addr_d_execute;
    assign rs1_addr_d_execute = rs1_addr_q_decode;

    logic [     4:0] rs2_addr_d_execute;
    assign rs2_addr_d_execute = rs2_addr_q_decode;
    
    operation_e operation_d_execute;
    assign operation_d_execute = operation_q_decode;

    logic [XLEN-1:0] rs1_data_d_execute;
    always_comb begin : forwarding_rs1

        if(is_forward_rs1 == NO_FORWARD)
            rs1_data_d_execute = rs1_data_q_decode;
        else if(is_forward_rs1 == FORWARD_MEMORY)
            rs1_data_d_execute = rd_data_d_memory;
        else if(is_forward_rs1 == FORWARD_WRITEBACK)
            rs1_data_d_execute = rd_data_d_writeback;
        else
            rs1_data_d_execute = 0; // beklenmedik durum
    end

    logic [XLEN-1:0] rs2_data_d_execute;
    always_comb begin : forwarding_rs2
        if(is_forward_rs2 == NO_FORWARD)
            rs2_data_d_execute = rs2_data_q_decode;
        else if(is_forward_rs2 == FORWARD_MEMORY)
            rs2_data_d_execute = rd_data_d_memory;
        else if(is_forward_rs2 == FORWARD_WRITEBACK)
            rs2_data_d_execute = rd_data_d_writeback;
        else
            rs2_data_d_execute = 0; // beklenmedik durum
    end

    //======================================================= INTERNAL DEĞİŞKENLER ===============================================

    logic jump_pc_valid_d_execute;
    logic [XLEN-1:0] jump_pc_d_execute;

    logic [XLEN-1:0] rd_data_d_execute;

    logic [XLEN-1:0] data_memory_write_data_d_execute;
    assign data_memory_write_data_d_execute = rs2_data_d_execute;

    logic [XLEN-1:0] data_memory_write_address_d_execute;
    assign data_memory_write_address_d_execute = rs1_data_d_execute + imm_data_d_execute;

    logic [XLEN-1:0] data_memory_read_address_d_execute;
    assign data_memory_read_address_d_execute = rs1_data_d_execute + imm_data_d_execute;

    //============================================================= OUTPUTLAR ======================================================

    logic [XLEN-1:0] instr_q_execute;
    logic [XLEN-1:0] pc_q_execute;
    logic            update_q_execute;

    logic            register_file_write_enable_q_execute;
    logic            data_memory_write_enable_q_execute;
    logic            data_memory_read_enable_q_execute;

    logic [     4:0] rd_q_execute;

    operation_e operation_q_execute;

    logic [XLEN-1:0] rd_data_q_execute;

    logic [XLEN-1:0] data_memory_write_data_q_execute;
    logic [XLEN-1:0] data_memory_write_address_q_execute;
    logic [XLEN-1:0] data_memory_read_address_q_execute;

    //========================================================== EXECUTE BLOCK ====================================================

    logic [XLEN-1:0] alu_result_d_execute;

    always_comb begin : ALU_BLOCK
        jump_pc_valid_d_execute = 0;
        jump_pc_d_execute = 0;
        alu_result_d_execute = 0;

        case(operation_d_execute)
            LUI:   alu_result_d_execute = imm_data_d_execute;
            AUIPC: alu_result_d_execute = pc_d_execute + imm_data_d_execute;
            JAL: begin
                alu_result_d_execute = pc_d_execute + 4;
                jump_pc_valid_d_execute = 1;
                jump_pc_d_execute = pc_d_execute + imm_data_d_execute;
            end
            JALR: begin
                alu_result_d_execute = pc_d_execute + 4;
                jump_pc_valid_d_execute = 1;
                jump_pc_d_execute = (rs1_data_d_execute + imm_data_d_execute) & ~1;
            end
            BEQ: begin
                if(rs1_data_d_execute == rs2_data_d_execute) begin
                    jump_pc_valid_d_execute = 1;
                    jump_pc_d_execute = pc_d_execute + imm_data_d_execute;
                end
            end
            BNE: begin
                if(rs1_data_d_execute != rs2_data_d_execute) begin
                    jump_pc_valid_d_execute = 1;
                    jump_pc_d_execute = pc_d_execute + imm_data_d_execute;
                end
            end
            BLT: begin
                if($signed(rs1_data_d_execute) < $signed(rs2_data_d_execute)) begin
                    jump_pc_valid_d_execute = 1;
                    jump_pc_d_execute = pc_d_execute + imm_data_d_execute;
                end
            end
            BGE: begin
                if($signed(rs1_data_d_execute) >= $signed(rs2_data_d_execute)) begin
                    jump_pc_valid_d_execute = 1;
                    jump_pc_d_execute = pc_d_execute + imm_data_d_execute;
                end
            end
            BLTU: begin
                if(rs1_data_d_execute < rs2_data_d_execute) begin
                    jump_pc_valid_d_execute = 1;
                    jump_pc_d_execute = pc_d_execute + imm_data_d_execute;
                end
            end
            BGEU: begin
                if(rs1_data_d_execute >= rs2_data_d_execute) begin
                    jump_pc_valid_d_execute = 1;
                    jump_pc_d_execute = pc_d_execute + imm_data_d_execute;
                end
            end
            ADDI:  alu_result_d_execute = $signed(rs1_data_d_execute) + $signed(imm_data_d_execute);
            SLTI:  if($signed(rs1_data_d_execute) < $signed(imm_data_d_execute)) alu_result_d_execute = 1;
            SLTIU: if(rs1_data_d_execute < imm_data_d_execute) alu_result_d_execute = 1;
            XORI:  alu_result_d_execute = rs1_data_d_execute ^ imm_data_d_execute;
            ORI:   alu_result_d_execute = rs1_data_d_execute | imm_data_d_execute;
            ANDI:  alu_result_d_execute = rs1_data_d_execute & imm_data_d_execute;
            SLLI:  alu_result_d_execute = rs1_data_d_execute << shamt_data_d_execute;
            SRLI:  alu_result_d_execute = rs1_data_d_execute >> shamt_data_d_execute;
            SRAI:  alu_result_d_execute = $signed(rs1_data_d_execute) >>> shamt_data_d_execute;
            ADD:   alu_result_d_execute = $signed(rs1_data_d_execute) + $signed(rs2_data_d_execute);
            SUB:   alu_result_d_execute = $signed(rs1_data_d_execute) - $signed(rs2_data_d_execute);
            SLL:   alu_result_d_execute = rs1_data_d_execute << rs2_data_d_execute[4:0];
            SLT:   if($signed(rs1_data_d_execute) < $signed(rs2_data_d_execute)) alu_result_d_execute = 1;
            SLTU:  if(rs1_data_d_execute < rs2_data_d_execute) alu_result_d_execute = 1;
            XOR:   alu_result_d_execute = rs1_data_d_execute ^ rs2_data_d_execute;
            SRL:   alu_result_d_execute = rs1_data_d_execute >> rs2_data_d_execute[4:0];
            SRA:   alu_result_d_execute = $signed(rs1_data_d_execute) >>> rs2_data_d_execute[4:0];
            OR:    alu_result_d_execute = rs1_data_d_execute | rs2_data_d_execute;
            AND:   alu_result_d_execute = rs1_data_d_execute & rs2_data_d_execute;
            CLZ:   alu_result_d_execute = clz_function(rs1_data_d_execute);
            CPOP:  alu_result_d_execute = cpop_function(rs1_data_d_execute);
            CTZ:   alu_result_d_execute = ctz_function(rs1_data_d_execute);
            default: ;
        endcase
    end

    //========================================================== M-EXTENSION UNIT ==================================================

    logic [XLEN-1:0] multiplicand_dividend; // çarpılan / bölünen
    assign multiplicand_dividend = rs1_data_d_execute;

    logic [XLEN-1:0] multiplier_divisor; // çarpan / bölen
    assign multiplier_divisor = rs2_data_d_execute;

    logic is_MEXT_op;
    assign is_MEXT_op = (operation_d_execute == MUL || operation_d_execute == MULH || operation_d_execute == MULHSU || operation_d_execute == MULHU ||
                         operation_d_execute == DIV || operation_d_execute == DIVU || operation_d_execute == REM || operation_d_execute == REMU);

    logic is_DIV_op;
    assign is_DIV_op = (operation_d_execute == DIV || operation_d_execute == DIVU || operation_d_execute == REM || operation_d_execute == REMU);

    //**************************************** SIGN_FIND_BLOCK ***********************************

    logic sign_multiplicand_dividend;
    logic sign_multiplier_divisor;

    always_comb begin : SIGN_FIND
        sign_multiplicand_dividend = 0;
        sign_multiplier_divisor = 0;
        if(is_MEXT_op) begin
            case(operation_d_execute)
                MUL, MULH, DIV, REM: begin
                    if(multiplicand_dividend[XLEN-1] == 1)
                        sign_multiplicand_dividend = 1;
                    if(multiplier_divisor[XLEN-1] == 1)
                        sign_multiplier_divisor = 1;
                end
                MULHSU: begin
                    if(multiplicand_dividend[XLEN-1] == 1)
                        sign_multiplicand_dividend = 1;
                end
                default: ;
            endcase
        end
    end

    //***************************************** NEXT_STATE_FSM **************************************

    Mext_State_enum MEXT_state;
    Mext_State_enum MEXT_next_state;
    logic is_busy_d_execute;

    always_comb begin: NEXT_STATE_FSM
        MEXT_next_state = MEXT_state;
        is_busy_d_execute = 0;

        case(MEXT_state)
            IDLE: begin
                if(is_MEXT_op) begin
                    if(is_DIV_op && (multiplier_divisor == 0)) begin   // sıfıra bölme durumu
                        MEXT_next_state = DONE;
                        is_busy_d_execute = 1;
                    end
                    else if(is_DIV_op && multiplicand_dividend == 32'h8000_0000 && multiplier_divisor == 32'hFFFF_FFFF) begin
                        MEXT_next_state = DONE;
                        is_busy_d_execute = 1;
                    end
                    else if(is_DIV_op && (multiplicand_dividend == 0)) begin // bölünenin 0 olduğu durum
                        MEXT_next_state = DONE;
                        is_busy_d_execute = 1;
                    end
                    else if(!is_DIV_op && (multiplier_divisor == 0 || multiplicand_dividend == 0)) begin // çarpan veya çarpılanın 0 olduğu durum
                        MEXT_next_state = DONE;
                        is_busy_d_execute = 1;
                    end
                    else begin // normal durum
                        MEXT_next_state = BUSY;
                        is_busy_d_execute = 1;
                    end
                end
                else begin
                    MEXT_next_state = IDLE;
                end
            end
            BUSY: begin
                MEXT_next_state = (counter == 0) ? DONE : BUSY;
                is_busy_d_execute = 1;
            end
            DONE: begin
                MEXT_next_state = IDLE;
                is_busy_d_execute = 0;
            end
            default: MEXT_next_state = IDLE;
        endcase
    end

    //************************************ NEXT_VALUE_LOGIC *****************************************

    logic [XLEN*2 -1:0] product_register_next;
    logic [XLEN-1:0] multiplicand_divisor_register_next;
    logic [XLEN:0] sum_sub_temp; // 33 bitlik geçici toplama,çıkarma değişkeni. Taşma bitini kaybetmemek için bunu kullanıcaz.

    always_comb begin : NEXT_VALUE_LOGIC
        product_register_next = product_register;
        multiplicand_divisor_register_next = multiplicand_divisor_register;
        sum_sub_temp = 0;

        case(MEXT_state)
            IDLE: begin
                if(is_MEXT_op) begin
                    if(is_DIV_op && (multiplier_divisor == 0)) begin  // sıfıra bölme durumu
                        product_register_next = {multiplicand_dividend, 32'hFFFF_FFFF};
                    end
                    else if(is_DIV_op && multiplicand_dividend == 32'h8000_0000 && multiplier_divisor == 32'hFFFF_FFFF) begin
                        product_register_next = {32'h0000_0000, multiplicand_dividend}; // Overflow durumu, -2^31 / -1 = +2^31 olmalı ama değer 32 bite sığmaz.
                    end
                    else if(is_DIV_op && (multiplicand_dividend == 0)) begin  // bölünenin 0 olduğu durum
                        product_register_next = 0;
                    end
                    else if (is_DIV_op) begin  // normal bölme durumu
                        multiplicand_divisor_register_next = (sign_multiplier_divisor) ? (~multiplier_divisor + 1) : multiplier_divisor;
                        product_register_next[XLEN-1:0] = (sign_multiplicand_dividend) ? (~multiplicand_dividend + 1) : multiplicand_dividend;
                        product_register_next[XLEN*2 -1:XLEN] = 0;
                    end
                    else if(!is_DIV_op && (multiplier_divisor == 0 || multiplicand_dividend == 0)) begin // çarpan veya çarpılanın 0 olduğu durum
                        product_register_next = 0;
                    end
                    else  begin  // normal çarpma durumu
                        multiplicand_divisor_register_next = (sign_multiplicand_dividend) ? (~multiplicand_dividend + 1) : multiplicand_dividend;
                        product_register_next[XLEN -1:0] = (sign_multiplier_divisor) ? (~multiplier_divisor + 1) : multiplier_divisor;
                        product_register_next[XLEN*2 -1:XLEN] = 0;
                    end
                end
            end
            BUSY: begin
                if(counter > 0) begin
                    if(is_DIV_op) begin
                        sum_sub_temp = {1'b0,product_register[XLEN*2-2:XLEN-1]} - {1'b0, multiplicand_divisor_register};
                        product_register_next = (sum_sub_temp[XLEN] == 1) ? product_register << 1 : {sum_sub_temp[XLEN-1:0], product_register[XLEN-2:0], 1'b1};
                    end
                    else begin
                        sum_sub_temp = {1'b0, product_register[XLEN*2-1:XLEN]} + (product_register[0] ? {1'b0,multiplicand_divisor_register} : 0);
                        product_register_next = (product_register[0] == 1) ? {sum_sub_temp, product_register[XLEN-1:1]} : product_register >> 1;
                    end
                end
            end
            DONE: begin
                product_register_next = 0;
                multiplicand_divisor_register_next = 0;
            end
            UNKNOWN_MEXT_STATE: begin
                product_register_next = 64'hDEAD_DEAD_DEAD_DEAD;
                multiplicand_divisor_register_next = 32'hDEAD_DEAD;
            end
        endcase
    end

    //*************************************** RESULT_REGISTER ***************************************

    logic [XLEN*2 -1:0] product_register; // 64 bit sonuç registerı
    logic [XLEN-1:0] multiplicand_divisor_register; // çarpılan / bölen register
    logic [5:0] counter;
    logic sign_multiplicand_dividend_register;
    logic sign_multiplier_divisor_register;
    

    always_ff @(posedge clk or negedge rstn) begin: RESULT_REGISTER
        if(!rstn) begin
            MEXT_state <= IDLE;
            product_register <= 0;
            counter <= XLEN;
            multiplicand_divisor_register <= 0;
            sign_multiplicand_dividend_register <= 0;
            sign_multiplier_divisor_register <= 0;
        end
        else begin
            MEXT_state <= MEXT_next_state;
            product_register <= product_register_next;
            multiplicand_divisor_register <= multiplicand_divisor_register_next;
            counter <= (MEXT_state == BUSY && counter > 0) ? counter - 1 : XLEN;
            sign_multiplicand_dividend_register <= (MEXT_state == IDLE) ? sign_multiplicand_dividend : sign_multiplicand_dividend_register;
            sign_multiplier_divisor_register <= (MEXT_state == IDLE) ? sign_multiplier_divisor : sign_multiplier_divisor_register;
        end
    end

    //************************************** FINAL_RESULT_CALCULATION ********************************

    logic [XLEN*2 -1:0] final_result;

    always_comb begin: PRODUCT_FINAL_CALCULATION
        final_result = 0;
        if(is_DIV_op) begin
            final_result[XLEN-1:0] = (sign_multiplicand_dividend_register ^ sign_multiplier_divisor_register) ? (~product_register[XLEN-1:0] + 1) : product_register[XLEN-1:0];
            final_result[XLEN*2-1:XLEN] = (sign_multiplicand_dividend_register) ? (~product_register[XLEN*2-1:XLEN] + 1) : product_register[XLEN*2-1:XLEN];
        end
        else
            final_result = (sign_multiplier_divisor_register ^ sign_multiplicand_dividend_register) ? (~product_register + 1) : product_register;
    end

    //*************************************** MEXT RESULT SEÇİMİ ***************************************

    logic [XLEN-1:0] mext_result_d_execute;

    always_comb begin: MEXT_RESULT_SECIM_DEVRESI
        mext_result_d_execute = 0;
        case(operation_d_execute)
            MUL:   mext_result_d_execute = final_result[XLEN-1:0];
            MULH:  mext_result_d_execute = final_result[XLEN*2-1:XLEN];
            MULHSU:mext_result_d_execute = final_result[XLEN*2-1:XLEN];
            MULHU: mext_result_d_execute = final_result[XLEN*2-1:XLEN];
            DIV:   mext_result_d_execute = final_result[XLEN-1:0];
            DIVU:  mext_result_d_execute = final_result[XLEN-1:0];
            REM:   mext_result_d_execute = final_result[XLEN*2-1:XLEN];
            REMU:  mext_result_d_execute = final_result[XLEN*2-1:XLEN];
            default: ;
        endcase
    end

    //===========================================EX/MEM REGISTER İÇİN RD_DATA SEÇİMİ ==============================================
    
    assign rd_data_d_execute = (is_MEXT_op) ? mext_result_d_execute : alu_result_d_execute;

    //======================================================= EX/MEM REGISTER ======================================================

    always_ff @(posedge clk or negedge rstn) begin : EX_MEM_REGISTER
        if(!rstn || is_Flush_EX_MEM_Register) begin
            instr_q_execute <= 0;
            pc_q_execute <= 0;
            update_q_execute <= 0;
            register_file_write_enable_q_execute <= 0;
            data_memory_write_enable_q_execute <= 0;
            data_memory_read_enable_q_execute <= 0;
            rd_q_execute <= 0;
            operation_q_execute <= OPERATION_UNKNOWN;
            rd_data_q_execute <= 0;
            data_memory_write_data_q_execute <= 0;
            data_memory_write_address_q_execute <= 0;
            data_memory_read_address_q_execute <= 0;
        end
        else begin
            instr_q_execute <= instr_d_execute;
            pc_q_execute <= pc_d_execute;
            update_q_execute <= update_d_execute;
            register_file_write_enable_q_execute <= register_file_write_enable_d_execute;
            data_memory_write_enable_q_execute <= data_memory_write_enable_d_execute;
            data_memory_read_enable_q_execute <= data_memory_read_enable_d_execute;
            rd_q_execute <= rd_d_execute;
            operation_q_execute <= operation_d_execute;
            rd_data_q_execute <= rd_data_d_execute;
            data_memory_write_data_q_execute <= data_memory_write_data_d_execute;
            data_memory_write_address_q_execute <= data_memory_write_address_d_execute;
            data_memory_read_address_q_execute <= data_memory_read_address_d_execute;
        end
    end

/////////////////////////////////////////////////////////////////////////MEMORY AŞAMASI/////////////////////////////////////////////////////////////////////////

    //===================================================== INPUTLAR =====================================================
    logic [XLEN-1:0] pc_d_memory;
    assign pc_d_memory = pc_q_execute;

    logic [XLEN-1:0] instr_d_memory;
    assign instr_d_memory = instr_q_execute;

    logic            update_d_memory;
    assign update_d_memory = update_q_execute;

    logic            register_file_write_enable_d_memory;
    assign register_file_write_enable_d_memory = register_file_write_enable_q_execute;

    logic            data_memory_write_enable_d_memory;
    assign data_memory_write_enable_d_memory = data_memory_write_enable_q_execute;

    logic            data_memory_read_enable_d_memory;
    assign data_memory_read_enable_d_memory = data_memory_read_enable_q_execute;

    logic [     4:0] rd_d_memory;
    assign rd_d_memory = rd_q_execute;

    operation_e operation_d_memory;
    assign operation_d_memory = operation_q_execute;

    logic [XLEN-1:0] rd_data_d_memory;
    assign rd_data_d_memory = data_memory_read_enable_d_memory ? data_memory_read_data_d_memory : rd_data_q_execute;

    logic [XLEN-1:0] data_memory_write_data_d_memory;
    assign data_memory_write_data_d_memory = data_memory_write_data_q_execute;

    logic [XLEN-1:0] data_memory_write_address_d_memory;
    assign data_memory_write_address_d_memory = data_memory_write_address_q_execute;

    logic [XLEN-1:0] data_memory_read_address_d_memory;
    assign data_memory_read_address_d_memory = data_memory_read_address_q_execute;

    //=================================================== INTERNAL DEĞİŞKENLER =============================================
    logic [XLEN-1:0] data_memory_read_data_d_memory;

    // OUTPUTLAR

    logic [XLEN-1:0] pc_q_memory;
    logic [XLEN-1:0] instr_q_memory;
    logic            update_q_memory;

    logic            register_file_write_enable_q_memory;
    logic            data_memory_write_enable_q_memory;
    logic            data_memory_read_enable_q_memory;

    logic [     4:0] rd_q_memory;

    operation_e operation_q_memory;

    logic [XLEN-1:0] rd_data_q_memory;

    logic [XLEN-1:0] data_memory_write_data_q_memory;
    logic [XLEN-1:0] data_memory_write_address_q_memory;
    logic [XLEN-1:0] data_memory_read_address_q_memory;

    //===================================================== DATA MEMORY ======================================================

    logic [31:0] data_memory [MEM_SIZE-1:0];

    always_ff @(posedge clk or negedge rstn) begin : STORE_BLOCK
        if(!rstn)
            ;
        else if(data_memory_write_enable_d_memory) begin
            case(operation_d_memory)
                SB:
                    case(data_memory_write_address_d_memory[1:0])
                        2'b00: data_memory[data_memory_write_address_d_memory[$clog2(MEM_SIZE)+1:2]][7:0]   <= data_memory_write_data_d_memory[7:0];
                        2'b01: data_memory[data_memory_write_address_d_memory[$clog2(MEM_SIZE)+1:2]][15:8]  <= data_memory_write_data_d_memory[7:0];
                        2'b10: data_memory[data_memory_write_address_d_memory >> 2][23:16] <= data_memory_write_data_d_memory[7:0];
                        2'b11: data_memory[data_memory_write_address_d_memory >> 2][31:24] <= data_memory_write_data_d_memory[7:0];
                    endcase
                SH:
                    case(data_memory_write_address_d_memory[1])
                        1'b0: data_memory[data_memory_write_address_d_memory >> 2][15:0] <= data_memory_write_data_d_memory[15:0];
                        1'b1: data_memory[data_memory_write_address_d_memory[$clog2(MEM_SIZE)+1:2]][31:16] <= data_memory_write_data_d_memory[15:0];
                    endcase
                SW: data_memory[data_memory_write_address_d_memory[$clog2(MEM_SIZE)+1:2]] <= data_memory_write_data_d_memory;
                //  data_memory[data_memory_write_address_d_memory >> 2] <= data_memory_write_data_d_memory; şeklinde de olur.
                default: ;
            endcase
        end
    end

    // yukarıda data memory'den okuma yapılırken adres hesaplama bazı örneklerde ">> 2" ile bazılarında ise "[$clog2(MEM_SIZE)+1:2]" ile yaptım
    // bunun sebebi iki örneği de görmek ve sonrasında unutmamak için. $clog2 dinamik olarak parametre oluşturmak gerektiğinde daha kullanışlı.
    // diğer türlü >> 2 kullanımı daha pratik.

    //========================================= LOAD BLOCK İÇİN ADRES HESAPLAMASI ===============================================

    localparam DATA_MEMORY_READ_ADDRESS_WIDTH = $clog2(MEM_SIZE);   
    logic [DATA_MEMORY_READ_ADDRESS_WIDTH-1:0] addr_index;
    assign addr_index = data_memory_read_address_d_memory[DATA_MEMORY_READ_ADDRESS_WIDTH+1:2];

    always_comb begin : LOAD_BLOCK
        data_memory_read_data_d_memory = 0;
        
        case(operation_d_memory)
            LB:
                case(data_memory_read_address_d_memory[1:0])
                    2'b00: data_memory_read_data_d_memory = {{24{data_memory[addr_index][7]}}, data_memory[addr_index][7:0]};
                    2'b01: data_memory_read_data_d_memory = {{24{data_memory[addr_index][15]}}, data_memory[addr_index][15:8]};
                    2'b10: data_memory_read_data_d_memory = {{24{data_memory[addr_index][23]}}, data_memory[addr_index][23:16]};
                    2'b11: data_memory_read_data_d_memory = {{24{data_memory[addr_index][31]}}, data_memory[addr_index][31:24]};
                endcase
            LH:
                case(data_memory_read_address_d_memory[1])
                    1'b0: data_memory_read_data_d_memory = {{16{data_memory[addr_index][15]}}, data_memory[addr_index][15:0]};
                    1'b1: data_memory_read_data_d_memory = {{16{data_memory[addr_index][31]}}, data_memory[addr_index][31:16]};
                endcase
            LW:  data_memory_read_data_d_memory = data_memory[addr_index];
            LBU:
                case(data_memory_read_address_d_memory[1:0])
                    2'b00: data_memory_read_data_d_memory = {24'b0, data_memory[addr_index][7:0]};
                    2'b01: data_memory_read_data_d_memory = {24'b0, data_memory[addr_index][15:8]};
                    2'b10: data_memory_read_data_d_memory = {24'b0, data_memory[addr_index][23:16]};
                    2'b11: data_memory_read_data_d_memory = {24'b0, data_memory[addr_index][31:24]};
                endcase
            LHU:
                case(data_memory_read_address_d_memory[1])
                    1'b0: data_memory_read_data_d_memory = {16'b0, data_memory[addr_index][15:0]};
                    1'b1: data_memory_read_data_d_memory = {16'b0, data_memory[addr_index][31:16]};
                endcase
            default: ;
        endcase
    end

    //===================================================== MEM/WRITEBACK REGISTER =====================================================

    always_ff @(posedge clk or negedge rstn) begin : MEM_WRITEBACK_REGISTER
        if(!rstn) begin
            pc_q_memory <= 0;
            instr_q_memory <= 0;
            update_q_memory <= 0;

            register_file_write_enable_q_memory <= 0;
            data_memory_write_enable_q_memory <= 0;
            data_memory_read_enable_q_memory <= 0;

            rd_q_memory <= 0;

            operation_q_memory <= OPERATION_UNKNOWN;

            rd_data_q_memory <= 0;

            data_memory_write_data_q_memory <= 0;
            data_memory_write_address_q_memory <= 0;
            data_memory_read_address_q_memory <= 0;
        end
        else begin
            pc_q_memory <= pc_d_memory;
            instr_q_memory <= instr_d_memory;
            update_q_memory <= update_d_memory;

            register_file_write_enable_q_memory <= register_file_write_enable_d_memory;
            data_memory_write_enable_q_memory <= data_memory_write_enable_d_memory;
            data_memory_read_enable_q_memory <= data_memory_read_enable_d_memory;

            rd_q_memory <= rd_d_memory;

            operation_q_memory <= operation_d_memory;

            rd_data_q_memory <= rd_data_d_memory;

            data_memory_write_data_q_memory <= data_memory_write_data_d_memory;
            data_memory_write_address_q_memory <= data_memory_write_address_d_memory;
            data_memory_read_address_q_memory <= data_memory_read_address_d_memory;
        end
    end

/////////////////////////////////////////////////////////////////////////////WRITEBACK AŞAMASI//////////////////////////////////////////////////////////////////////////

    //INPUTLAR
    logic [XLEN-1:0] pc_d_writeback;
    assign pc_d_writeback = pc_q_memory;

    logic [XLEN-1:0] instr_d_writeback;
    assign instr_d_writeback = instr_q_memory;

    logic            update_d_writeback;
    assign update_d_writeback = update_q_memory;

    logic            register_file_write_enable_d_writeback;
    assign register_file_write_enable_d_writeback = register_file_write_enable_q_memory;

    logic            data_memory_write_enable_d_writeback;
    assign data_memory_write_enable_d_writeback = data_memory_write_enable_q_memory;

    logic            data_memory_read_enable_d_writeback;
    assign data_memory_read_enable_d_writeback = data_memory_read_enable_q_memory;

    logic [     4:0] rd_d_writeback;
    assign rd_d_writeback = rd_q_memory;

    operation_e operation_d_writeback;
    assign operation_d_writeback = operation_q_memory;

    logic [XLEN-1:0] rd_data_d_writeback;
    assign rd_data_d_writeback = rd_data_q_memory;

    logic [XLEN-1:0] data_memory_write_data_d_writeback;
    assign data_memory_write_data_d_writeback = data_memory_write_data_q_memory;

    logic [XLEN-1:0] data_memory_write_address_d_writeback;
    assign data_memory_write_address_d_writeback = data_memory_write_address_q_memory;

    logic [XLEN-1:0] data_memory_read_address_d_writeback;
    assign data_memory_read_address_d_writeback = data_memory_read_address_q_memory;

//////////////////////////////////////////////////////////////////////////////HAZARD UNIT///////////////////////////////////////////////////////////////////////////////

    //================================================= FORWARDING UNIT =================================================
    Forward_Type_enum is_forward_rs1;
    Forward_Type_enum is_forward_rs2;

    always_comb begin : FORWARDING_RS1
        is_forward_rs1 = NO_FORWARD;

        if((rs1_addr_d_execute == rd_d_memory) && (rd_d_memory != 0) && register_file_write_enable_d_memory)
            is_forward_rs1 = FORWARD_MEMORY;
        else if((rs1_addr_d_execute == rd_d_writeback) && (rd_d_writeback != 0) && register_file_write_enable_d_writeback)
            is_forward_rs1 = FORWARD_WRITEBACK;
        else ;
        
    end

    always_comb begin : FORWARDING_RS2
        is_forward_rs2 = NO_FORWARD;

        if((rs2_addr_d_execute == rd_d_memory) && (rd_d_memory != 0) && register_file_write_enable_d_memory)
            is_forward_rs2 = FORWARD_MEMORY;
        else if((rs2_addr_d_execute == rd_d_writeback) && (rd_d_writeback != 0) && register_file_write_enable_d_writeback)
            is_forward_rs2 = FORWARD_WRITEBACK;
        else ;
    end

    //================================================= FLUSH/STALL UNIT =================================================
    logic is_Flush_IF_ID_Register;
    logic is_Flush_ID_IEX_Register;

    logic is_Stall_PC_FF;
    logic is_Stall_IF_ID_Register;

    logic is_Stall_ID_IEX_Register;
    logic is_Flush_EX_MEM_Register;

    always_comb begin : FLUSH_STALL_BLOCK
        is_Flush_IF_ID_Register = 0;
        is_Flush_ID_IEX_Register = 0;
        is_Flush_EX_MEM_Register = 0;

        is_Stall_PC_FF = 0;
        is_Stall_IF_ID_Register = 0;
        is_Stall_ID_IEX_Register = 0;

        if(jump_pc_valid_d_execute) begin
            is_Flush_IF_ID_Register = 1;
            is_Flush_ID_IEX_Register = 1;
        end
        else if(((rs1_addr_d_decode == rd_d_execute) || (rs2_addr_d_decode == rd_d_execute)) && (rd_d_execute != 0) && data_memory_read_enable_d_execute) begin
            is_Flush_ID_IEX_Register = 1;

            is_Stall_PC_FF = 1;
            is_Stall_IF_ID_Register = 1;
        end
        else if(is_busy_d_execute) begin
            is_Stall_PC_FF = 1;
            is_Stall_IF_ID_Register = 1;
            is_Stall_ID_IEX_Register = 1;
            is_Flush_EX_MEM_Register = 1;
        end
    end

//////////////////////////////////////////////////////////////////////////DEBUG OUTPUTS///////////////////////////////////////////////////////////////////////////////

    assign pc_o = pc_d_writeback;
    assign instr_o = instr_d_writeback;
    assign reg_addr_o = rd_d_writeback;
    assign reg_data_o = rd_data_d_writeback;
    assign update_o = update_d_writeback;
    assign memory_read_addr_o = data_memory_read_address_d_writeback;
    assign memory_write_addr_o = data_memory_write_address_d_writeback;
    assign memory_write_data_o = data_memory_write_data_d_writeback;
    assign memory_read_enable_o = data_memory_read_enable_d_writeback;
    assign memory_write_enable_o = data_memory_write_enable_d_writeback;
    assign register_file_write_enable_o = register_file_write_enable_d_writeback;
    assign operation_o = operation_d_writeback;



endmodule
