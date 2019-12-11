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

func executeInstruction*(inp, pc: int, memory: var Memory, base: int = 0): InterpreterResult =
  result.nextPC = pc
  result.base = base
  let instr = decodeInstruction(fetch(memory, 1, pc, 0, 0))
  case instr.opcode:
    of ADD:
      let arg0 = fetch(memory, instr.mode0, pc, 1, base)
      let arg1 = fetch(memory, instr.mode1, pc, 2, base)
      write(memory, instr.mode2, pc, 3, base, arg0 + arg1)
    of MUL:
      let arg0 = fetch(memory, instr.mode0, pc, 1, base)
      let arg1 = fetch(memory, instr.mode1, pc, 2, base)
      write(memory, instr.mode2, pc, 3, base, arg0 * arg1)
    of IN:
      write(memory, instr.mode0, pc, 1, base, inp)
      result.consumedInput = true
    of OUT:
      result.output = some(fetch(memory, instr.mode0, pc, 1, base))
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
      write(memory, instr.mode2, pc, 3, base, int(@1 < @2))
    of EQ:
      write(memory, instr.mode2, pc, 3, base, int(@1 == @2))
    of BASE:
      result.base += @1
  result.nextPC += incPC(instr.opcode)
  if not result.halt: assert(result.nextPC != pc, "Program counter has not been modified! PC=" & $pc & " OP=" & $instr.opcode & " Invalid opcode or spinning?")

proc readProgramFromPath*(path: string): Memory =
  var f = open(path)
  defer: close(f)
  for k, v in f.readLine().split(',').map(x => parseInt(x)):
    result[k] = v
