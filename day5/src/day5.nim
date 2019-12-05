import os
import tables
import times
import aocutils
import options
import strutils
import algorithm
import sequtils

type
  InterpreterResult = object
    nextPC: int
    halt: bool
    output: Option[int]

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

proc decodeInstruction(instr: int): tuple[opcode, mode0, mode1, mode2: int] =
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

func readValueMode(A: int, mode: int, memory: seq[int]): int =
  case mode:
    of 0: $> $> A
    of 1: $> A
    else: raise newException(ValueError, "Invalid mode " & $mode)

proc executeInstruction(inp, pc: int, memory: var seq[int]): InterpreterResult =
  result.halt = false
  let instr = decodeInstruction($>(pc + 0))
  case instr.opcode:
    of ADD: # add
      $>>(pc + 3) = readValueMode(pc + 1, instr.mode0, memory) + readValueMode(pc + 2, instr.mode1, memory)
      result.nextPC = pc + 4
    of MUL: # mul
      $>>(pc + 3) = readValueMode(pc + 1, instr.mode0, memory) * readValueMode(pc + 2, instr.mode1, memory)
      result.nextPC = pc + 4
    of IN: # in
      $>>(pc + 1) = inp
      result.nextPC = pc + 2
    of OUT: # out
      result.output = some($>>(pc + 1))
      result.nextPC = pc + 2
    of HLT: # hlt
      result.halt = true
    of JNZ:
      if readValueMode(pc + 1, instr.mode0, memory) != 0:
        result.nextPC = readValueMode(pc + 2, instr.mode1, memory)
      else:
        result.nextPC = pc + 3
    of JZ:
      if readValueMode(pc + 1, instr.mode0, memory) == 0:
        result.nextPC = readValueMode(pc + 2, instr.mode1, memory)
      else:
        result.nextPC = pc + 3
    of LT:
      if readValueMode(pc + 1, instr.mode0, memory) < readValueMode(pc + 2, instr.mode1, memory):
        $>>(pc + 3) = 1
      else:
        $>>(pc + 3) = 0
      result.nextPC = pc + 4
    of EQ:
      if readValueMode(pc + 1, instr.mode0, memory) == readValueMode(pc + 2, instr.mode1, memory):
        $>>(pc + 3) = 1
      else:
        $>>(pc + 3) = 0
      result.nextPC = pc + 4
    else:
      raise newException(ValueError, "Unknown opcode in " & $instr)

proc runProgram(inp: int, memory: seq[int]): int =
  ## Runs the program and returns the diagnostic code
  var ires: InterpreterResult
  var pc = 0
  var program = memory

  while not ires.halt:
    ires = executeInstruction(inp, pc, program)
    pc = ires.nextPC
    if ires.output.isSome():
      result = ires.output.get()
      stderr.writeLine("OUT: " & $ires.output.get())

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  
  let parseStart = getTime()
  var program = open(inputPath).readLine().split(',').map(proc(x: string): int = parseInt(x))

  let parseEnd = getTime()

  let part1Start = getTime()
  let output1 = $(runProgram(1, program))
  let part1End = getTime()

  let part2Start = getTime()
  let output2 = $(runProgram(5, program))
  let part2End = getTime()

  var R: AOCResults
  R.init(output1, output2, float inMicroseconds(parseEnd - parseStart), float inMicroseconds(part1End - part1Start), float inMicroseconds(part2End - part2Start))
  printResults(R)