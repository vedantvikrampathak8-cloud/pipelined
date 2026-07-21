package riscv_pkg;
    // ALU Operations
    localparam logic [4:0] ALU_ADD = 5'd0;
    localparam logic [4:0] ALU_SUB = 5'd1;
    localparam logic [4:0] ALU_AND = 5'd2;
    localparam logic [4:0] ALU_OR = 5'd3;
    localparam logic [4:0] ALU_XOR = 5'd4;
    localparam logic [4:0] ALU_SLL = 5'd5;
    localparam logic [4:0] ALU_SRL = 5'd6;
    localparam logic [4:0] ALU_SRA = 5'd7;
    localparam logic [4:0] ALU_SLT = 5'd8;
    localparam logic [4:0] ALU_SLTU = 5'd9;
    // Opcodes
    localparam logic [6:0] OP = 7'b0110011;
    localparam logic [6:0] OP_IMM = 7'b0010011;
    localparam logic [6:0] LOAD = 7'b0000011;
    localparam logic [6:0] STORE = 7'b0100011;
    localparam logic [6:0] BRANCH = 7'b1100011;
    localparam logic [6:0] LUI = 7'b0110111;
    localparam logic [6:0] AUIPC = 7'b0010111;
    localparam logic [6:0] JAL = 7'b1101111;
    localparam logic [6:0] JALR = 7'b1100111;
    // FUNCT3
    localparam logic [2:0] FUNCT3_ADD_SUB = 3'b000;
    localparam logic [2:0] FUNCT3_SLL = 3'b001;
    localparam logic [2:0] FUNCT3_SLT = 3'b010;
    localparam logic [2:0] FUNCT3_SLTU = 3'b011;
    localparam logic [2:0] FUNCT3_XOR = 3'b100;
    localparam logic [2:0] FUNCT3_SR = 3'b101;
    localparam logic [2:0] FUNCT3_OR = 3'b110;
    localparam logic [2:0] FUNCT3_AND = 3'b111;
    //FUNCT7
    localparam logic [6:0] FUNCT7_STD = 7'b0000000;
    localparam logic [6:0] FUNCT7_SUB_SRA = 7'b0100000;
    // LOAD Instructions
    localparam logic [2:0] FUNCT3_LB  = 3'b000;
    localparam logic [2:0] FUNCT3_LH  = 3'b001;
    localparam logic [2:0] FUNCT3_LW  = 3'b010;
    localparam logic [2:0] FUNCT3_LBU = 3'b100;
    localparam logic [2:0] FUNCT3_LHU = 3'b101;
    // STORE Instructions
    localparam logic [2:0] FUNCT3_SB = 3'b000;
    localparam logic [2:0] FUNCT3_SH = 3'b001;
    localparam logic [2:0] FUNCT3_SW = 3'b010;
    // BRANCH Instructions
    localparam logic [2:0] FUNCT3_BEQ  = 3'b000;
    localparam logic [2:0] FUNCT3_BNE  = 3'b001;
    localparam logic [2:0] FUNCT3_BLT  = 3'b100;
    localparam logic [2:0] FUNCT3_BGE  = 3'b101;
    localparam logic [2:0] FUNCT3_BLTU = 3'b110;
    localparam logic [2:0] FUNCT3_BGEU = 3'b111;
    // Writeback select
    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_MEM = 2'b01;
    localparam logic [1:0] WB_PC4 = 2'b10;
    // ALU operand A select
    localparam logic [1:0] ALU_SRC_RS1    = 2'b00;
    localparam logic [1:0] ALU_SRC_PC     = 2'b01;
    localparam logic [1:0] ALU_SRC_ZERO   = 2'b10;
    localparam logic [1:0] ALU_SRC_OLD_PC = 2'b11; // multicycle-only: PC of the in-flight instruction,                        
    // ALU operand B select
    localparam logic [1:0] ALU_SRC_RS2 = 2'b00;
    localparam logic [1:0] ALU_SRC_IMM = 2'b01;
    // ALU op select 
    localparam logic [1:0] ALU_OP_ADD    = 2'b00;
    localparam logic [1:0] ALU_OP_RTYPE  = 2'b01;
    localparam logic [1:0] ALU_OP_BRANCH = 2'b10;
    localparam logic [1:0] ALU_OP_LUI    = 2'b11;

    typedef enum logic [3:0] {
    FETCH      = 4'd0,
    DECODE     = 4'd1,
    EXEC_R     = 4'd2,
    EXEC_I     = 4'd3,
    EXEC_LOAD  = 4'd4,
    EXEC_STORE = 4'd5,
    EXEC_BRANCH= 4'd6,
    EXEC_JUMP  = 4'd7,
    MEM_READ   = 4'd8,
    MEM_WRITE  = 4'd9,
    ST_WB_ALU  = 4'd10, 
    WB_LOAD    = 4'd11,
    EXEC_U     = 4'd12
    } state_t;
endpackage