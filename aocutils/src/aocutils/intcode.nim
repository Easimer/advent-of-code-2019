import options
import sequtils
import strutils
import sugar
import intcode/internal

type
  InterpreterResult* = object
    nextPC*: int
    halt*: bool
    output*: Option[int]
    consumedInput*: bool
    base*: int
  
template `$>`(address: untyped): untyped = memory[address]
template `$>>`(address: untyped): untyped = $> $> address
template `@`(argIdx: int): int =
  ## Gets an argument value, taking into account the argument mode.
  ## argIdx==1 returns the first argument, argIdx==2 the second and so on.
  case instr[argIdx]:
    of 0: $>> (pc + argIdx)
    of 1: $> (pc + argIdx)
    of 2: $>($>(pc + argIdx) + base)
    else: raise newException(ValueError, "Invalid mode " & $instr[argIdx])

template nextPC(value: untyped): untyped =
  ## Sets the program counter
  result.nextPC = value

template write(memory: var seq[int], mode: int, pc: int, offset: int, base: int, value: int) =
  case mode:
    of 0: $>>(pc + offset) = value
    of 2: $>($>(pc + offset) + base) = value
    else: raise newException(ValueError, "Invalid write mode " & $mode)

func executeInstruction*(inp, pc: int, memory: var seq[int], base: int = 0): InterpreterResult =
  result.nextPC = pc
  result.base = base
  let instr = decodeInstruction($>(pc + 0))
  case instr.opcode:
    of ADD:
      write(memory, instr.mode2, pc, 3, base, @1 + @2)
    of MUL:
      write(memory, instr.mode2, pc, 3, base, @1 * @2)
    of IN:
      write(memory, instr.mode0, pc, 1, base, inp)
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
      write(memory, instr.mode2, pc, 3, base, int(@1 < @2))
    of EQ:
      write(memory, instr.mode2, pc, 3, base, int(@1 == @2))
    of BASE:
      result.base += @1
  result.nextPC += incPC(instr.opcode)
  if not result.halt: assert(result.nextPC != pc, "Program counter has not been modified! PC=" & $pc & " OP=" & $instr.opcode & " Invalid opcode or spinning?")

proc readProgramFromPath*(path: string): seq[int] =
  var f = open(path)
  defer: close(f)
  result = f.readLine().split(',').map(x => parseInt(x))

  for i in 0..10000:
    result.add(0)
