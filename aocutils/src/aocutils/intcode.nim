import options
import sequtils
import strutils

type
  InterpreterResult* = object
    nextPC*: int
    halt*: bool
    output*: Option[int]

const ADD = 1
const MUL = 2
const IN  = 3
const OUT = 4
const JNZ = 5
const JZ  = 6
const LT  = 7
const EQ  = 8
const HLT = 99

template `$>`(address: untyped): untyped = memory[address]
template `$>>`(address: untyped): untyped = $> $> address

func decodeInstruction(instr: int): tuple[opcode, mode0, mode1, mode2: int] =
  result.opcode = instr mod 100
  result.mode0 = instr div 100
  result.mode1 = result.mode0 div 10
  result.mode0 = result.mode0 mod 10
  result.mode2 = result.mode1 div 10
  result.mode1 = result.mode1 mod 10
  result.mode2 = result.mode2 mod 10

assert decodeInstruction(    1) == (1, 0, 0, 0)
assert decodeInstruction(  101) == (1, 1, 0, 0)
assert decodeInstruction( 1001) == (1, 0, 1, 0)
assert decodeInstruction( 1101) == (1, 1, 1, 0)
assert decodeInstruction(10001) == (1, 0, 0, 1)
assert decodeInstruction(10101) == (1, 1, 0, 1)
assert decodeInstruction(11001) == (1, 0, 1, 1)
assert decodeInstruction(11101) == (1, 1, 1, 1)

template readValueMode(argIdx: int, instr: (int, int, int, int), memory: seq[int]): int =
  case instr[argIdx]:
    of 0: $> $> (pc + argIdx)
    of 1: $> (pc + argIdx)
    else: raise newException(ValueError, "Invalid mode " & $instr[argIdx])

template nextPC(value: untyped): untyped =
  result.nextPC = value

func executeInstruction*(inp, pc: int, memory: var seq[int]): InterpreterResult =
  result.halt = false
  let instr = decodeInstruction($>(pc + 0))
  case instr.opcode:
    of ADD:
      $>>(pc + 3) = readValueMode(1, instr, memory) + readValueMode(2, instr, memory)
      nextPC(pc + 4)
    of MUL:
      $>>(pc + 3) = readValueMode(1, instr, memory) * readValueMode(2, instr, memory)
      nextPC(pc + 4)
    of IN:
      $>>(pc + 1) = inp
      nextPC(pc + 2)
    of OUT:
      result.output = some($>>(pc + 1))
      nextPC(pc + 2)
    of HLT:
      result.halt = true
    of JNZ:
      if readValueMode(1, instr, memory) != 0:
        nextPC(readValueMode(2, instr, memory))
      else:
        nextPC(pc + 3)
    of JZ:
      if readValueMode(1, instr, memory) == 0:
        nextPC(readValueMode(2, instr, memory))
      else:
        nextPC(pc + 3)
    of LT:
      if readValueMode(1, instr, memory) < readValueMode(2, instr, memory):
        $>>(pc + 3) = 1
      else:
        $>>(pc + 3) = 0
      nextPC(pc + 4)
    of EQ:
      if readValueMode(1, instr, memory) == readValueMode(2, instr, memory):
        $>>(pc + 3) = 1
      else:
        $>>(pc + 3) = 0
      nextPC(pc + 4)
    else:
      raise newException(ValueError, "Unknown opcode in " & $instr)

proc readProgramFromPath*(path: string): seq[int] =
  var f = open(path)
  defer: close(f)
  result = f.readLine().split(',').map(proc(x: string): int = parseInt(x))