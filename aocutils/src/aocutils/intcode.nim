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

template `@`(argIdx: int): int =
  ## Gets an argument value, taking into account the argument mode.
  ## argIdx==1 returns the first argument, argIdx==2 the second and so on.
  fetch(memory, instr[argIdx], pc, argIdx, base)

template nextPC(value: untyped): untyped =
  ## Sets the program counter
  result.nextPC = value

func fetch(memory: Memory, mode: int, pc: int, offset: int, base: int): int =
  let addr0 = pc + offset
  case mode:
    of 0:
      let addr1 = fetch(memory, 1, 0, addr0, 0)
      if addr1 in memory:
        memory[addr1]
      else:
        0
    of 1:
      if addr0 in memory:
        memory[addr0]
      else:
        0
    of 2:
      let addr1 = memory[addr0] + base
      if addr1 in memory:
        memory[addr1]
      else:
        0
    else:
      raise newException(ValueError, "Invalid mode " & $mode)

func write(memory: var Memory, mode: int, pc: int, offset: int, base: int, value: int) =
  case mode:
    of 0: memory[fetch(memory, 1, pc, offset, 0)] = value
    of 2: memory[fetch(memory, 1, pc, offset, 0) + base] = value
    else: raise newException(ValueError, "Invalid write mode " & $mode)

template `<<`(outArgIdx: int, value: untyped) =
  write(memory, instr[outArgIdx], pc, outArgIdx, base, value)

func executeInstruction*(inp, pc: int, memory: var Memory, base: int = 0): InterpreterResult =
  result.nextPC = pc
  result.base = base
  let instr = decodeInstruction(fetch(memory, 1, pc, 0, 0))
  case instr[0]:
    of ADD:
      3 << @1 + @2
    of MUL:
      3 << @1 * @2
    of IN:
      1 << inp
      result.consumedInput = true
    of OUT:
      result.output = some(@1)
    of HLT:
      result.halt = true
    of JNZ:
      nextPC:
        if @1 != 0: @2
        else: pc + 3
    of JZ:
      nextPC:
        if @1 == 0: @2
        else: pc + 3
    of LT:
      3 << int(@1 < @2)
    of EQ:
      3 << int(@1 == @2)
    of BASE:
      result.base += @1
  result.nextPC += incPC(instr[0])
  if not result.halt: assert(result.nextPC != pc, "Program counter has not been modified! PC=" & $pc & " OP=" & $instr[0] & " Invalid opcode or spinning?")

proc readProgramFromPath*(path: string): Memory =
  var f = open(path)
  defer: close(f)
  for k, v in f.readLine().split(',').map(x => parseInt(x)):
    result[k] = v
