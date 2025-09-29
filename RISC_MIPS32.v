module pipeline_mips32 (clk1,clk2);
    input clk1,clk2;
    reg [31:0] regbank [31:0];
    reg [31:0] memory [1023:0];

    reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
    reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
    reg [31:0] EX_MEM_IR, EX_MEM_ALUout, EX_MEM_B;
    reg EX_MEM_cond;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUout, MEM_WB_LMD;

    parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011,
    SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111, LW = 6'b001000, SW = 6'b001001, 
    ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100, BNEQZ = 6'b001101, BEQZ = 6'b001110;

    parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'B010, STORE = 3'b011, 
    BRANCH = 3'b100, HALT = 3'b101;

    reg HALTED; reg BRANCH_TAKEN;

    //instruction fetch (IF) stage
    always @(posedge clk1 ) begin
        if (HALTED == 0) begin 
            if (((EX_MEM_IR[31:26] == BEQZ) & (EX_MEM_cond == 1)) |
                ((EX_MEM_IR[31:26] == BNEQZ) & EX_MEM_cond == 0)) begin
                    IF_ID_IR     <=  memory[EX_MEM_ALUout];
                    IF_ID_NPC    <=  EX_MEM_ALUout + 1;
                    PC           <=  EX_MEM_ALUout + 1;
                    BRANCH_TAKEN <=  1;
                end
            else begin
                IF_ID_IR  <=  memory[PC];
                IF_ID_NPC <=  PC + 1;
                PC        <=  PC + 1;
            end
        end
    end

    // instruction decode (ID) stage
    always @(posedge clk2 ) begin
        if (HALTED == 0) begin
            if (IF_ID_IR[25:21] == 5'b0) ID_EX_A <= 5'b0;
            else ID_EX_A <=  regbank[IF_ID_IR[25:21]];

            if (IF_ID_IR[20:16] == 5'b0) ID_EX_B <= 5'b0;
            else ID_EX_B <=  regbank[IF_ID_IR[20:16]];

            ID_EX_Imm <=  {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

            ID_EX_IR <=  IF_ID_IR;
            ID_EX_NPC <=  IF_ID_NPC;
        end
        case (IF_ID_IR[31:26])
            ADD, SUB, MUL, SLT, AND, OR :  ID_EX_type <= RR_ALU;
            ADDI, SUBI, SLTI :             ID_EX_type <= RM_ALU;
            LW :                           ID_EX_type <= LOAD;
            SW :                           ID_EX_type <= STORE;
            BEQZ, BNEQZ :                  ID_EX_type <= BRANCH; 
            HLT :                          ID_EX_type <= HALT;
            default :                      ID_EX_type <= HALT;
        endcase
    end

    // execution (EX) stage
    always @(posedge clk1 ) begin
        if (HALTED == 0) begin
            case (ID_EX_type)
                RR_ALU : begin
                    case (ID_EX_IR[31:26])
                        ADD :      EX_MEM_ALUout <= ID_EX_A + ID_EX_B;
                        SUB :      EX_MEM_ALUout <= ID_EX_A - ID_EX_B;
                        AND :      EX_MEM_ALUout <= ID_EX_A & ID_EX_B;
                        OR :       EX_MEM_ALUout <= ID_EX_A | ID_EX_B;
                        SLT :      EX_MEM_ALUout <= ID_EX_A < ID_EX_B;
                        MUL :      EX_MEM_ALUout <= ID_EX_A * ID_EX_B;
                        default :  EX_MEM_ALUout <= 32'bx;
                    endcase
                end

                RM_ALU : begin
                    case (ID_EX_IR[31:26])
                        ADDI :     EX_MEM_ALUout <= ID_EX_A + ID_EX_Imm;
                        SUBI :     EX_MEM_ALUout <= ID_EX_A - ID_EX_Imm;
                        SLTI :     EX_MEM_ALUout <= ID_EX_A < ID_EX_Imm;
                        default :  EX_MEM_ALUout <= 32'bx;
                    endcase
                end

                LOAD,STORE : begin
                    EX_MEM_ALUout <=  ID_EX_A + ID_EX_Imm;
                    EX_MEM_B      <=  ID_EX_B;
                end

                BRANCH : begin
                    EX_MEM_ALUout <=  ID_EX_NPC + ID_EX_Imm;
                    EX_MEM_cond   <=  (ID_EX_A == 0);
                end
            endcase

            EX_MEM_type <= ID_EX_type;
            EX_MEM_IR <= ID_EX_IR;
            BRANCH_TAKEN <= 1'b0;
        end
    end

    // memory (MEM) stage
    always @(posedge clk2 ) begin
        if (HALTED == 0) begin
            MEM_WB_IR   <=  EX_MEM_IR;
            MEM_WB_type <=  EX_MEM_type;

            case (EX_MEM_type)
                RR_ALU,RM_ALU : MEM_WB_ALUout <=  EX_MEM_ALUout;
                LOAD :          MEM_WB_LMD <=  memory[EX_MEM_ALUout]; 
                STORE :         if (BRANCH_TAKEN == 0) memory[EX_MEM_ALUout] <=  EX_MEM_B;
            endcase
        end
    end

    // write back (WB) state
    always @(posedge clk1 ) begin
        if (BRANCH_TAKEN == 0) begin
            case (MEM_WB_type)
                RR_ALU : regbank[MEM_WB_IR[15:11]] <=  MEM_WB_ALUout;
                RM_ALU : regbank[MEM_WB_IR[20:16]] <=  MEM_WB_ALUout;
                LOAD :   regbank[MEM_WB_IR[20:16]] <=  MEM_WB_LMD;
                HALT :   HALTED <=  1'b1;
            endcase
        end
    end
endmodule
/*
module tb1 ();
    reg clk1,clk2; integer k;
    pipeline_mips32 P(.clk1(clk1),.clk2(clk2));

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (50) begin
            #5 clk1 = 1; #5  clk1 = 0;
            #5 clk2 = 1; #5  clk2 = 0;
        end
    end

    initial begin
        for (k = 0;k<=31 ;k=k+1 ) begin
            P.regbank[k] = k;
        end
        P.memory[0]  = 32'h280a00c8;    // ADDI  R10,R0,200
        P.memory[1]  = 32'h28020001;    // ADDI  R2,R0,1
        P.memory[2]  = 32'h0e94a000;    // OR    R20,R20,R20  -- dummy instr.
        P.memory[3]  = 32'h21430000;    // LW    R3,0(R10)
        P.memory[4]  = 32'h0e94a000;    // OR    R20,R20,R20  -- dummy instr.
        P.memory[5]  = 32'h14431000;    // Loop: MUL  R2,R2,R3
        P.memory[6]  = 32'h2c630001;    // SUBI  R3,R3,1
        P.memory[7]  = 32'h0e94a000;    // OR    R20,R20,R20  -- dummy instr.
        P.memory[8]  = 32'h3460fffc;    // BNEQZ R3,Loop (i.e. -4 offset)
        P.memory[9]  = 32'h2542fffe;    // SW    R2,-2(R10)
        P.memory[10] = 32'hfc000000;    // HLT


        P.memory[200] = 7;


        P.PC = 0;
        P.HALTED = 0;
        P.BRANCH_TAKEN = 0;

        #2000
        $display("memory[200] = %d \nmemory[198] = %d", P.memory[200], P.memory[198]);
    end

    initial begin
        $dumpfile("P32.vcd");
        $dumpvars(0,tb1);
        $monitor("R2 = %d", P.regbank[2]);
        #3000 $finish;
    end
endmodule

*/