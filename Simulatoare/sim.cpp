#include <iostream>
#include <fstream>
#include <vector>
#include <cstdint>
#include <thread>
#include <chrono>

class MIPSProcessor {
public:
    uint32_t pc;
    std::vector<uint32_t> registers;
    std::vector<uint32_t> data_memory;
    std::vector<uint32_t> memory;
    //Initializare banc de registre, RAM, ROM, registru PC
    MIPSProcessor() : pc(0), registers(32, 0), data_memory(100, 0), memory(100, 0) {
        // Reading initial memory contents from files
        std::ifstream file("instructions.mem");
        std::string hex_instruction;
        while (file >> hex_instruction) {
            uint32_t instruction = std::stoul(hex_instruction, nullptr, 16);
            memory[pc++] = instruction;
        }
        pc = 0;
    }

    void process_instruction() {
        //Procesarea instructiunilor, cate una pe rand
        uint32_t instruction = (memory[pc]<<24)|(memory[pc+1]<<16)|(memory[pc+2]<<8)|memory[pc+3];
        uint32_t opcode = instruction >> 26;
        uint32_t rs = (instruction >> 21) & 0x1F;
        uint32_t rt = (instruction >> 16) & 0x1F;
        uint32_t rd = (instruction >> 11) & 0x1F;
        uint32_t shamt = (instruction >> 6) & 0x1F;
        uint32_t funct = instruction & 0x3F;
        uint32_t immediate = instruction & 0xFFFF;
        uint32_t address = instruction & 0x3FFFFFF;

        bool jump = false;
        uint32_t jump_address = 0;

        // Identificarea tipului de instructiune si prelucrarea efectiva
        if (opcode == 0x00) {  // Tip R
            if (funct == 0x20) {  // add
                registers[rd] = (registers[rs] + registers[rt]) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rd] << std::endl;
            } else if (funct == 0x24) {  // and
                registers[rd] = (registers[rs] & registers[rt]) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rd] << std::endl;
            } else if (funct == 0x08) {  // jr
                jump = true;
                jump_address = registers[rt];
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rt] << std::endl;
            } else if (funct == 0x27) {  // nor
                registers[rd] = (~(registers[rs] | registers[rt])) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << (registers[rd] & 0x1FFFF) << std::endl;
            } else if (funct == 0x25) {  // or
                registers[rd] = (registers[rs] | registers[rt]) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rd] << std::endl;
            } else if (funct == 0x2A) {  // slt
                int32_t reg_diff = registers[rs] - registers[rt];
                registers[rd] = (reg_diff < 0) ? 1 : 0;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rd] << std::endl;
            } else if (funct == 0x00) {  // sll
                registers[rd] = (registers[rt] << shamt) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rd] << std::endl;
            } else if (funct == 0x02) {  // srl
                registers[rd] = (registers[rt] >> shamt) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rd] << std::endl;
            } else if (funct == 0x22) {  // sub
                registers[rd] = (registers[rs] - registers[rt]) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rd] << std::endl;
            } else {  // Altele
                std::cout << "PC: " << std::hex << pc << ", result: 0x0 (nesuportat)" << std::endl;
            }
        } else if (opcode == 0x08) {  // addi
            registers[rt] = (registers[rs] + immediate | ((immediate >> 15) ? 0xFFFFF000 : 0)) & 0xFFFFFFFF;
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rt] << std::endl;
        } else if (opcode == 0x0C) {  // andi
            registers[rt] = (registers[rs] & immediate) & 0xFFFFFFFF;
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rt] << std::endl;
        } else if (opcode == 0x0F) {  // lui
            registers[rt] = (immediate << 16) & 0xFFFFFFFF;
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rt] << std::endl;
        } else if (opcode == 0x23) {  // lw
            uint32_t address = registers[rs] + immediate | ((immediate >> 15) ? 0xFFFFF000 : 0);
            registers[rt] = data_memory[address];
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rt] << std::endl;
        } else if (opcode == 0x0D) {  // ori
            registers[rt] = (registers[rs] | immediate) & 0xFFFFFFFF;
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << registers[rt] << std::endl;
        } else if (opcode == 0x2B) {  // sw
            uint32_t address = registers[rs] + immediate | ((immediate >> 15) ? 0xFFFFF000 : 0);
            data_memory[address] = registers[rt];
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << data_memory[address] << std::endl;
        } else if (opcode == 0x04) {  // beq
            if (registers[rs] == registers[rt]) {
                jump = true;
                jump_address = (pc + ((immediate | ((immediate >> 15) ? 0xFFFFF000 : 0))<< 2) + 4) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << jump_address << std::endl;
            }
        } else if (opcode == 0x05) {  // bne
            if (registers[rs] != registers[rt]) {
                jump = true;
                jump_address = (pc + ((immediate | ((immediate >> 15) ? 0xFFFFF000 : 0))<< 2) + 4) & 0xFFFFFFFF;
                std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << jump_address << std::endl;
            }
        } else if (opcode == 0x02) {  // j
            jump = true;
            uint32_t reg_diff = pc + 4;
            jump_address = ((reg_diff & 0xF0000000) | (address << 2)) & 0xFFFFFFFF;
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << jump_address << std::endl;
        } else if (opcode == 0x03) {  // jal
            jump = true;
            registers[31] = (pc + 8) & 0xFFFFFFFF;
            uint32_t reg_diff = pc + 4;
            jump_address = ((reg_diff & 0xF0000000) | (address << 2)) & 0xFFFFFFFF;
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x" << std::hex << jump_address << std::endl;
        } else if (opcode == 0x3F) {  // Instructiune de reset intern
            registers = std::vector<uint32_t>(32, 0);
            data_memory = std::vector<uint32_t>(100, 0);
            jump = true;
            jump_address = 0;
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x0 (resetare)" << std::endl;
            std::cout << "\n\n";
        } else { //instructiune nesuportata
            std::cout << "PC: 0x" << std::hex << pc << ", result: 0x1FFFF (instructiune nesuportata)" << std::endl;
        }
        //Actualizare PC, in functie de tipul instructiunii
        if (jump) {
            pc = jump_address;
        }
        else{
            pc+=4;
        }
    }
};
//Echivalent testbench
int main() {
    // Create the MIPS processor instance
    MIPSProcessor processor;

    // Executarea instructiunilor, se simuleaza perioadele unui clock
    while (processor.pc < processor.memory.size()) {
        processor.process_instruction();
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    return 0;
}
