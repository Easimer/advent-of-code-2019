import options
import sequtils
import strutils

type
  InterpreterResult* = object
    nextPC*: int
    halt*: bool
    output*: Option[int]
  
  Opcode = enum
    ADD = 1, MUL = 2, IN = 3, OUT = 4, JNZ = 5, JZ = 6,
    LT = 7, EQ = 8,
    HLT = 99
  
  DecodedInstruction = tuple[opcode: Opcode, mode0, mode1, mode2: int]

template `$>`(address: untyped): untyped = memory[address]
template `$>>`(address: untyped): untyped = $> $> address

func decodeInstruction(instr: int): DecodedInstruction =
  ## Decodes the instruction, returning the opcode and the argument modes.
  result.opcode = Opcode(instr mod 100)
  result.mode0 = instr div 100
  result.mode1 = result.mode0 div 10
  result.mode0 = result.mode0 mod 10
  result.mode2 = result.mode1 div 10
  result.mode1 = result.mode1 mod 10
  result.mode2 = result.mode2 mod 10

assert decodeInstruction(    1) == (ADD, 0, 0, 0)
assert decodeInstruction(  101) == (ADD, 1, 0, 0)
assert decodeInstruction( 1001) == (ADD, 0, 1, 0)
assert decodeInstruction( 1101) == (ADD, 1, 1, 0)
assert decodeInstruction(10001) == (ADD, 0, 0, 1)
assert decodeInstruction(10101) == (ADD, 1, 0, 1)
assert decodeInstruction(11001) == (ADD, 0, 1, 1)
assert decodeInstruction(11101) == (ADD, 1, 1, 1)

template `@`(argIdx: int): int =
  ## Gets an argument value, taking into account the argument mode.
  ## argIdx==1 returns the first argument, argIdx==2 the second and so on.
  case instr[argIdx]:
    of 0: $>> (pc + argIdx)
    of 1: $> (pc + argIdx)
    else: raise newException(ValueError, "Invalid mode " & $instr[argIdx])

template incPC(op: Opcode): int =
  ## Returns the PC offset for opcodes with fixed offset
  case op:
    of ADD: 4
    of MUL: 4
    of LT: 4
    of EQ: 4
    of IN: 2
    of OUT: 2
    else: 0

template nextPC(value: untyped): untyped =
  ## Sets the program counter
  result.nextPC = value

func executeInstruction*(inp, pc: int, memory: var seq[int]): InterpreterResult =
  result.nextPC = pc
  let instr = decodeInstruction($>(pc + 0))
  case instr.opcode:
    of ADD:
      $>>(pc + 3) = @1 + @2
    of MUL:
      $>>(pc + 3) = @1 * @2
    of IN:
      $>>(pc + 1) = inp
    of OUT:
      result.output = some($>>(pc + 1))
    of HLT:
      result.halt = true
    of JNZ:
      if @1 != 0:
        nextPC(@2)
      else:
        nextPC(pc + 3)
    of JZ:
      if @1 == 0:
        nextPC(@2)
      else:
        nextPC(pc + 3)
    of LT:
      if @1 < @2:
        $>>(pc + 3) = 1
      else:
        $>>(pc + 3) = 0
    of EQ:
      if @1 == @2:
        $>>(pc + 3) = 1
      else:
        $>>(pc + 3) = 0
  result.nextPC += incPC(instr.opcode)
  if not result.halt: assert(result.nextPC != pc, "Program counter has not been modified! PC=" & $pc & " OP=" & $instr.opcode & " Invalid opcode or spinning?")

proc readProgramFromPath*(path: string): seq[int] =
  var f = open(path)
  defer: close(f)
  result = f.readLine().split(',').map(proc(x: string): int = parseInt(x))