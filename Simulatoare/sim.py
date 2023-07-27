import time
class MIPSProcessor:
    #Initializare banc de registre, RAM, ROM, registru PC
    def __init__(self):
        self.pc = 0
        self.registers = [0] * 32
        self.data_memory = [0] * 100
        self.memory = [0] * 100

        # Incarcarea octetilor aferenti ROM-ului din fisier
        with open("instructions.mem", "r") as f:
            hex_instructions = f.read().split()
            self.memory= hex_instructions
        self.pc = 0

    def process_instruction(self):
    #Procesarea instructiunilor, cate una pe rand
        instruction = (int(self.memory[self.pc],16)<<24)+(int(self.memory[self.pc+1],16)<<16)+(int(self.memory[self.pc+2],16)<<8)+(int(self.memory[self.pc+3],16))
        opcode = instruction >> 26
        rs = (instruction >> 21) & 0x1F
        rt = (instruction >> 16) & 0x1F
        rd = (instruction >> 11) & 0x1F
        shamt = (instruction >> 6) & 0x1F
        funct = instruction & 0x3F
        immediate = instruction & 0xFFFF
        address = instruction & 0x3FFFFFF

        # Identificarea tipului de instructiune si prelucrarea efectiva
        if opcode == 0x00:  # Tip R
            jump = False
            if funct == 0x20:  # add
                self.registers[rd] = (self.registers[rs] + self.registers[rt])&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd])}")
            elif funct == 0x24:  # and
                self.registers[rd] = (self.registers[rs] & self.registers[rt])&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd])}")
            elif funct == 0x08:  # jr
                jump = True
                jump_address = self.registers[rt]
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rt])}")
            elif funct == 0x27:  # nor
                self.registers[rd] = (~(self.registers[rs] | self.registers[rt]))&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd]&0x1ffff)}")
            elif funct == 0x25:  # or
                self.registers[rd] = (self.registers[rs] | self.registers[rt])&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd])}")
            elif funct == 0x2A:  # slt
                reg_dif = self.registers[rs] - self.registers[rt]
                self.registers[rd] = 1 if reg_dif < 0 else 0
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd])}")
            elif funct == 0x00:  # sll
                self.registers[rd] = (self.registers[rt] << shamt)&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd])}")
            elif funct == 0x02:  # srl
                self.registers[rd] = (self.registers[rt] >> shamt)&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd])}")
            elif funct == 0x22:  # sub
                self.registers[rd] = (self.registers[rs] - self.registers[rt])&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rd])}")
            else:# Altele
                print(f"PC: {hex(self.pc)}, result: 0x0 (nesuportat)")  
        elif opcode == 0x08:  # addi
            jump = False
            self.registers[rt] = (self.registers[rs] + (immediate | (0xFFFFF000 if immediate >> 15 else 0)))&0xffffffff
            print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rt])}")
        elif opcode == 0x0C:  # andi
            jump = False
            self.registers[rt] = (self.registers[rs] & immediate)&0xffffffff
            print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rt])}")
        elif opcode == 0x0F:  # lui
            jump = False
            self.registers[rt] = (immediate << 16)&0xffffffff
            print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rt])}")
        elif opcode == 0x23:  # lw
            jump = False
            address = self.registers[rs] + (immediate | (0xFFFFF000 if immediate >> 15 else 0))
            self.registers[rt] = self.data_memory[address]
            print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rt])}")
        elif opcode == 0x0D:  # ori
            jump = False
            self.registers[rt] = (self.registers[rs] | immediate)&0xffffffff
            print(f"PC: {hex(self.pc)}, result: {hex(self.registers[rt])}")
        elif opcode == 0x2B:  # sw
            jump = False
            address = self.registers[rs] + (immediate | (0xFFFFF000 if immediate >> 15 else 0))
            self.data_memory[address] = self.registers[rt]
            print(f"PC: {hex(self.pc)}, result: {hex(self.data_memory[address])}")
        elif opcode == 0x04:  # beq
            jump = False
            if self.registers[rs] == self.registers[rt]:
                jump = True
                jump_address = self.pc + (((immediate | (0xFFFFF000 if immediate >> 15 else 0)) << 2) + 4)&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(jump_address)}")
        elif opcode == 0x05:  # bne
            jump = False
            if self.registers[rs] != self.registers[rt]:
                jump = True
                jump_address = self.pc + (((immediate | (0xFFFFF000 if immediate >> 15 else 0)) << 2) + 4)&0xffffffff
                print(f"PC: {hex(self.pc)}, result: {hex(jump_address)}")
        elif opcode == 0x02:  # j
            jump = True
            reg_diff = self.pc + 4
            jump_address = ((reg_diff & 0xF0000000) | (address << 2))&0xffffffff
            print(f"PC: {hex(self.pc)}, result: {hex(jump_address)}")
        elif opcode == 0x03:  # jal
            jump = True
            self.registers[31] = (self.pc + 8)&0xffffffff
            reg_diff = self.pc + 4
            jump_address = ((reg_diff & 0xF0000000) | (address << 2))&0xffffffff
            print(f"PC: {hex(self.pc)}, result: {hex(jump_address)}")
        elif opcode == 0x3F:  # Instructiune de reset intern
            self.registers = [0] * 32
            self.data_memory = [0] * 100
            jump = True
            jump_address = 0
            print(f"PC: {hex(self.pc)}, result: 0x0 (resetare)")
            print("\n\n")
        else: #instructiune nesuportata
            jump = False
            print(f"PC: {hex(self.pc)}, result: 0x1ffff (instructiune nesuportata)")
         #Actualizare PC, in functie de tipul instructiunii
        if jump:
            self.pc = jump_address
        else:
            self.pc += 4

#Echivalent testbench
if __name__ == "__main__":  
    processor = MIPSProcessor()
    #Executarea instructiunilor, se simuleaza perioadele unui clock
    while processor.pc<len(processor.memory):
        processor.process_instruction()
        time.sleep(0.1)
