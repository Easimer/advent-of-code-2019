import options
import sequtils
import strutils
import sugar
import tables
import intcode/internal

type
  InterpreterResult* = object
    nextPC*: int
    halt*: bool
    output*: Option[int]
    consumedInput*: bool
    base*: int
  Memory* = Table[int, int]

template `?>>`(address: untyped): int = (if address in memory: memory[address] else: 0)
template `<<`(outArgIdx: int, value: untyped) = write(memory, instr[outArgIdx], pc, outArgIdx, base, value)
template `!>`(cond: untyped, val: (untyped, untyped)) = result.nextPC = (if cond: val[0] else: val[1])
template `@`(argIdx: int): int = fetch(memory, instr[argIdx], pc, argIdx, base)

func fetch(memory: Memory, mode: int, pc: int, offset: int, base: int): int =
  let addr0 = pc + offset
  case mode:
    of 0:
      ?>> fetch(memory, 1, 0, addr0, 0)
    of 1:
      ?>> addr0
    of 2:
      ?>> (fetch(memory, 1, 0, addr0, 0) + base)
    else:
      raise newException(ValueError, "Invalid mode " & $mode)

func write(memory: var Memory, mode: int, pc: int, offset: int, base: int, value: int) =
  case mode:
    of 0: memory[fetch(memory, 1, pc, offset, 0)] = value
    of 2: memory[fetch(memory, 1, pc, offset, 0) + base] = value
    else: raise newException(ValueError, "Invalid write mode " & $mode)

func executeInstruction*(inp, pc: int, memory: var Memory, base: int = 0): InterpreterResult =
  result.nextPC = pc
  result.base = base
  let instr = decodeInstruction(fetch(memory, 1, pc, 0, 0))
  case instr[0]:
    of ADD:
      3 << @1 + @2
    of MUL:
      3 << @1 * @2
    of JNZ:
      @1 != 0 !> (@2, pc + 3)
    of JZ:
      @1 == 0 !> (@2, pc + 3)
    of LT:
      3 << int(@1 < @2)
    of EQ:
      3 << int(@1 == @2)
    of BASE:
      result.base += @1
    of OUT:
      result.output = some(@1)
    of IN:
      1 << inp
      result.consumedInput = true
    of HLT: result.halt = true
  result.nextPC += incPC(instr[0])
  if not result.halt: assert(result.nextPC != pc, "Program counter has not been modified! PC=" & $pc & " OP=" & $instr[0] & " Invalid opcode or spinning?")

proc readProgramFromPath*(path: string): Memory =
  var f = open(path)
  defer: close(f)
  for k, v in f.readLine().split(',').map(x => parseInt(x)):
    result[k] = v
