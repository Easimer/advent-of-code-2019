## Intcode internal code shared by aocutils and icdis

type
  Opcode* = enum
    ADD = 1, MUL = 2, IN = 3, OUT = 4, JNZ = 5, JZ = 6,
    LT = 7, EQ = 8,
    BASE = 9,
    HLT = 99

  #DecodedInstruction* = tuple[opcode: Opcode, mode0, mode1, mode2: int]
  DecodedInstruction* = (Opcode, int, int, int)

func decodeInstruction*(instr: int): DecodedInstruction =
  ## Decodes the instruction, returning the opcode and the argument modes.
  result[0] = Opcode(instr mod 100)
  result[1] = instr div 100
  result[2] = result[1] div 10
  result[1] = result[1] mod 10
  result[3] = result[2] div 10
  result[2] = result[2] mod 10
  result[3] = result[3] mod 10

assert decodeInstruction(    1) == (ADD, 0, 0, 0)
assert decodeInstruction(  101) == (ADD, 1, 0, 0)
assert decodeInstruction( 1001) == (ADD, 0, 1, 0)
assert decodeInstruction( 1101) == (ADD, 1, 1, 0)
assert decodeInstruction(10001) == (ADD, 0, 0, 1)
assert decodeInstruction(10101) == (ADD, 1, 0, 1)
assert decodeInstruction(11001) == (ADD, 0, 1, 1)
assert decodeInstruction(11101) == (ADD, 1, 1, 1)

template incPC*(op: Opcode): int =
  ## Returns the PC offset for opcodes with fixed offset
  case op:
    of ADD: 4
    of MUL: 4
    of LT: 4
    of EQ: 4
    of IN: 2
    of OUT: 2
    of BASE: 2
    else: 0

template len*(op: Opcode): int =
  ## Returns the length of the instruction (including the opcode)
  case op:
    of ADD: 4
    of MUL: 4
    of LT: 4
    of EQ: 4
    of IN: 2
    of OUT: 2
    of JNZ: 3
    of JZ: 3
    of HLT: 1
    of BASE: 2