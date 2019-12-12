import os
import options
import strutils
import tables
import aocutils/intcode
import aocutils/intcode/internal

type
  BreakpointKind = enum Function, Data
  Breakpoint = object
    case kind: BreakpointKind
      of Function:
        pc: int
      of Data:
        address: int
        read, write: bool
  
  DebuggerFlag {.size: sizeof(cint).} = enum
    SingleStep,
    BreakOnInput,

  Debugger = object
    flags: set[DebuggerFlag]
    breakpoints: seq[Breakpoint]
    
const DebuggerDefaultFlags = {SingleStep, BreakOnInput}

func resetDebugger(dbg: var Debugger) =
  dbg.flags = DebuggerDefaultFlags
  dbg.breakpoints = @[]

func strArg(mode, arg: int): string =
  case mode:
    of 0: '[' & $arg & ']'
    of 1: $arg
    of 2: '[' & $arg & " + rel]"
    else: '?' & $arg & '?' & " mode = " & $mode

func `strInstr`(pc: int, mem: Memory): string =
  let instr = decodeInstruction(mem[pc])
  let L = len(instr[0])
  if L > 0: result &= $instr[0]
  if L > 1: result &= ' ' & strArg(instr[1], mem[pc + 1])
  if L > 2: result &= ' ' & strArg(instr[2], mem[pc + 2])
  if L > 3: result &= ' ' & strArg(instr[3], mem[pc + 3])

proc debugProgram(origProg: Memory) =
  var program = origProg
  var state: InterpreterResult
  var output: Option[int]
  var input = 0
  var dbg: Debugger

  resetDebugger(dbg)

  while not state.halt:
    let pcCur = state.nextPC

    if SingleStep in dbg.flags:
      stderr.write(strInstr(pcCur, program) & '\n')

      var step = false
      while not step:
        stderr.write("$ ")
        let line = stdin.readLine()
        if len(line) == 0:
          dbg.flags.incl(SingleStep)
          step = true
        else:
          case line:
            of "c":
              dbg.flags.excl(SingleStep)
              step = true
            of "s":
              dbg.flags.incl(SingleStep)
              step = true
            of "bi":
              let bi = BreakOnInput in dbg.flags
              if bi: dbg.flags.excl(BreakOnInput)
              else: dbg.flags.incl(BreakOnInput)
              stderr.write("BREAK ON INPUT = " & $(not bi) & '\n') 
            of "r":
              state.nextPC = 0
              program = origProg
              resetDebugger(dbg)
              stderr.write("VM STATE RESET, DEBUGGER STATE UNCHANGED\n")
              stderr.write(strInstr(0, program) & '\n')

    if needsInput(state, program) and (BreakOnInput in dbg.flags):
      var inputOk = false
      while not inputOk:
        stderr.write("INPUT: ")
        let line = stdin.readLine()
        try:
          input = parseInt(line)
          inputOk = true
        except ValueError:
          stderr.write("ERR\n")

    state = executeInstruction(input, state.nextPC, program, state.base)
    
    output = state.output

    if isSome(output):
      stderr.write("OUTPUT: " & $output.get() & '\n')
      stdout.write($output.get() & '\n')

when isMainModule:
  let program = readProgramFromPath(if paramCount() > 0: paramStr(1) else: "input.txt")
  debugProgram(program)


