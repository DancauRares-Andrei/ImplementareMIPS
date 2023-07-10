module InstructionMemory (
    input clk,
    input wire [31:0] pc,
    output reg [31:0] instruction,
    output reg [5:0] opcode,
    output reg [4:0] rs,
    output reg [4:0] rt,
    output reg [4:0] rd,
    output reg [4:0] shamt,
    output reg [5:0] funct,
    output reg [15:0] immediate,
    output reg [25:0] address
);

  reg [8:0] memory[0:95];

    initial begin
        $readmemh("instructions.hex", memory);
    end

  always @(pc) begin
        instruction = {memory[pc][7:0], memory[pc+1][7:0], memory[pc+2][7:0], memory[pc+3][7:0]};
        opcode = instruction[31:26];
        rs = instruction[25:21];
        rt = instruction[20:16];
        rd = instruction[15:11];
        shamt = instruction[10:6];
        funct = instruction[5:0];
        immediate = instruction[15:0];
        address = instruction[25:0];
    end

endmodule

module ControlUnit (
    input clk,
    input reset,
    input wire [31:0] pc,
    input [5:0] opcode,
    input [4:0] rs,
    input [4:0] rt,
    input [4:0] rd,
    input [4:0] shamt,
    input [5:0] funct,
    input [15:0] immediate,
    input [25:0] address,
    output reg Jump,
    output reg Branch,  
    output reg [31:0] jumpAddress,
    output reg [31:0] branchAddress,
  output reg [31:0] result
);
    reg [31:0] registers [0:31];
  reg [31:0] dataMemory[0:1023];
  reg [31:0] regtest;
    initial begin
        // Inițializarea registrilor cu 0
        for (int i = 0; i <= 31; i = i + 1)
          registers[i] = 0;
       for (int i = 0; i <= 1023; i = i + 1)
            dataMemory[i] = 32'h0000_0000;
   
    end

  always @(posedge clk) begin
   // $display("pc = %h",opcode);
    if(!reset)
        // Identificarea tipului de instrucțiune
      case (opcode)
            6'b000000: // Tip R
                begin
                    Jump = 0;
                    Branch = 0;
                  case (funct)
                        6'b100000: // add
                          begin
                          registers[rd]=registers[rs]+registers[rt];
                          result=registers[rd];
                          end                      
                    	6'b100100: //and
                          begin
                          registers[rd]=registers[rs]&registers[rt];
                          result=registers[rd];
                          end
                    	6'b001000://jr
                          begin
                            Jump=1;
                            jumpAddress=registers[rt];
                          end
                    	6'b100111://nor
                          begin
                            registers[rd]=!(registers[rs]|registers[rt]);
                          result=registers[rd];
                          end
                    	6'b100101://or
                          begin
                            registers[rd]=registers[rs]|registers[rt];
                          result=registers[rd];
                          end                   	
                    	6'b101010://slt
                          begin
                            registers[rd]=(registers[rs] < registers[rt]) ? 1 : 0;
                          result=registers[rd];
                          end
                    	6'b000000://sll
                          begin
                            registers[rd]=registers[rt]<<shamt;
                          result=registers[rd];
                          end
                    	6'b000010://srl
                          begin
                            registers[rd]=registers[rt]>>shamt;
                          result=registers[rd];
                          end                  	
                    6'b100010: // sub
                          begin
                          registers[rd]=registers[rs]-registers[rt];
                          result=registers[rd];
                          end
                        default: // Altele
                            result = 0; // Nedefinit
                    endcase
                end
        6'b001000: // addi
                begin
                    Jump = 0;
                    Branch = 0;
                    registers[rt] = registers[rs] + {{16{immediate[15]}}, immediate};
                  result=registers[rt];
                end
        6'b001100: // andi
              begin
                  Jump = 0;
                  Branch = 0;
                  registers[rt] = registers[rs] & {16'b0, immediate};
                  result = registers[rt];
              end

        6'b001111: // lui
              begin
                  Jump = 0;
                  Branch = 0;
                  registers[rt] = {immediate, 16'b0};
                  result = registers[rt];
              end     
            6'b100011: // lw
                begin
                    Jump = 0;
                    Branch = 0;
                  registers[rt]=dataMemory[registers[rs]+{{16{immediate[15]}}, immediate}];
                  result=registers[rt];
                end
        	6'b001101: // ori
                begin
                    Jump = 0;
                    Branch = 0;
                    registers[rt] = registers[rs] | {16'b0, immediate};
                    result = registers[rt];
                end

            6'b101011: // sw
                begin                 
                    Jump = 0;
                    Branch = 0;
                  dataMemory[registers[rs]+immediate]=registers[rt];
                  result=dataMemory[registers[rs]+immediate];
                end
            6'b000100: // beq
                begin
                  Jump = 0;                              
                  if(registers[rs] == registers[rt])begin
                    branchAddress = { {14{immediate[15]}}, immediate, 2'b00 };
                  	Branch=1;
                    result=branchAddress;
                  end
                  else begin
                    Branch=0;
                    result=registers[rs];
                  end
                end
            6'b000101: // bne
                begin
                  Jump = 0;                              
                  if(registers[rs] != registers[rt])begin
                    branchAddress = { {14{immediate[15]}}, immediate, 2'b00 };
                  	Branch=1;
                    result=branchAddress;
                  end
                  else begin
                    Branch=0;
                    result=0;
                  end
                end
            6'b000010: // j
                begin
                    Jump = 1;
                    Branch = 0;
                  jumpAddress = {pc[31:28], address, 2'b00};
				  result=jumpAddress;
                end
            6'b000011: // jal
                begin
                    Jump = 1;
                    Branch = 0;
                    registers[31]=pc;
                  jumpAddress = {pc[31:28], address, 2'b00};
				  result=jumpAddress;
                end
        	6'b111111: //instructiune de reset intern
              begin
                for (int i = 0; i <= 31; i = i + 1)
                  registers[i] = 0;
               for (int i = 0; i <= 1023; i = i + 1)
                    dataMemory[i] = 32'h0000_0000;
        		Branch=0;
        		Jump=1;
        		jumpAddress=0;
              end
            default: // Instructiuni nesuportate
                begin
                    Jump = 0;
                    Branch = 0;
                end
        endcase
    else
      begin
        result<=0;
         Jump = 0;
        Branch=0;
        for (int i = 0; i <= 31; i = i + 1)
          registers[i] = 0;
       for (int i = 0; i <= 1023; i = i + 1)
            dataMemory[i] = 32'h0000_0000;
    end
  end

endmodule

module PC (
    input wire clk,
    input wire reset,
    input wire Jump,
    input wire Branch,
    input wire [31:0] jumpAddress,
    input wire [31:0] branchAddress,
    output reg [31:0] pcOut
);
  initial begin
    pcOut = 32'hFFFFFFFC; // Initializare cu -4
  end
  always @(negedge clk) begin
        if (reset) begin
            pcOut <= 32'hFFFFFFFC; // Initializare cu -4
        end
    else if (Branch) begin
            pcOut <= pcOut+4+branchAddress; // Sărim la adresa specificată de branchAddress dacă zero
        end
        else if (Jump) begin
            pcOut <= jumpAddress; // Sărim la adresa specificată de jumpAddress
        end
    else begin
            pcOut <= pcOut + 8'b0000_0100; // Incrementarea PC-ului cu 4
        end
    end
endmodule

module MIPSProcessor (
    input wire clk,
    input wire reset,
  output wire [31:0] result
);
    // Semnale pentru modulele interne
  wire [31:0] pcOut;
  wire [5:0] opcode;
  wire [4:0] shamt;
  wire [5:0] funct;
  wire [15:0] immediate;
  wire [25:0] address;
    wire [4:0] rs, rt, rd;
    wire Jump, Branch;
    wire [31:0] jumpAddress, branchAddress;
	
    // Modulul de control
    ControlUnit controlUnit(
      .reset(reset),
      .clk(clk),
    .pc(pcOut),
    .opcode(opcode),
    .rs(rs),
    .rt(rt),
    .rd(rd),
    .shamt(shamt),
    .funct(funct),
    .immediate(immediate),
    .address(address),
    .Jump(Jump),
    .Branch(Branch),
    .jumpAddress(jumpAddress),
    .branchAddress(branchAddress),
      .result(result)
);

    // Memoria de instrucțiuni
    InstructionMemory instructionMemory(
     .clk(clk), 
        .pc(pcOut),
        .opcode(opcode),
    .rs(rs),
    .rt(rt),
    .rd(rd),
    .shamt(shamt),
    .funct(funct),
    .immediate(immediate),
    .address(address)
    );


    // Modulul PC
    PC pc(
        .clk(clk),
        .reset(reset),
        .Jump(Jump),
        .Branch(Branch),
      .pcOut(pcOut),
      .jumpAddress(jumpAddress),
        .branchAddress(branchAddress)
    );
  
endmodule

