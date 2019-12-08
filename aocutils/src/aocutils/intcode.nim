import options
import sequtils
import strutils
import intcode/internal

type
  InterpreterResult* = object
    nextPC*: int
    halt*: bool
    output*: Option[int]
    consumedInput*: bool
  
template `$>`(address: untyped): untyped = memory[address]
template `$>>`(address: untyped): untyped = $> $> address
template `@`(argIdx: int): int =
  ## Gets an argument value, taking into account the argument mode.
  ## argIdx==1 returns the first argument, argIdx==2 the second and so on.
  case instr[argIdx]:
    of 0: $>> (pc + argIdx)
    of 1: $> (pc + argIdx)
    else: raise newException(ValueError, "Invalid mode " & $instr[argIdx])

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
      result.consumedInput = true
    of OUT:
      result.output = some($>>(pc + 1))
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
      $>>(pc + 3) = int(@1 < @2)
    of EQ:
      $>>(pc + 3) = int(@1 == @2)
  result.nextPC += incPC(instr.opcode)
  if not result.halt: assert(result.nextPC != pc, "Program counter has not been modified! PC=" & $pc & " OP=" & $instr.opcode & " Invalid opcode or spinning?")

proc readProgramFromPath*(path: string): seq[int] =
  var f = open(path)
  defer: close(f)
  result = f.readLine().split(',').map(proc(x: string): int = parseInt(x))