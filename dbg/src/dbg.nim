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
    mem: Memory

    state: InterpreterResult
    
const DebuggerDefaultFlags = {SingleStep, BreakOnInput}

func resetDebugger(dbg: var Debugger, mem: Memory) =
  dbg.flags = DebuggerDefaultFlags
  dbg.breakpoints = @[]
  dbg.mem = mem

func strArg(mode, arg, base: int): string =
  case mode:
    of 0: '[' & $arg & ']'
    of 1: $arg
    of 2: '[' & $arg & " + " & $base & "]"
    else: '?' & $arg & '?' & " mode = " & $mode

func detectIdiomMove(instr: DecodedInstruction, pc: int, dbg: Debugger, res: var string): bool =
  case instr[0]:
    of ADD:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      let arg1 = dbgFetch(dbg.mem, instr[2], pc, 2, dbg.state.base)
      if arg0 == 0:
        res = "MOV " & strArg(instr[1], dbg.mem[pc + 1], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        return true
      elif arg1 == 0:
        res = "MOV " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        return true
    of MUL:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      let arg1 = dbgFetch(dbg.mem, instr[2], pc, 2, dbg.state.base)
      if arg0 == 1:
        res = "MOV " & strArg(instr[1], dbg.mem[pc + 1], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        return true
      elif arg1 == 1:
        res = "MOV " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        return true
    else:
      return false

func detectIdiomUnconditionalJmp(instr: DecodedInstruction, pc: int, dbg: Debugger, res: var string): bool =
  case instr[0]:
    of JZ:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      if arg0 == 0:
        res = "JMP " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base)
        return true
    of JNZ:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      if arg0 == 1:
        res = "JMP " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base)
        return true
    else:
      return false

func detectIdiom(instr: DecodedInstruction, pc: int, dbg: Debugger, res: var string): bool =
  if detectIdiomMove(instr, pc, dbg, res): return true
  if detectIdiomUnconditionalJmp(instr, pc, dbg, res): return true

func genericDisass(instr: DecodedInstruction, pc: int, dbg: Debugger): string =
  let L = len(instr[0])
  if L > 0: result &= $instr[0]
  if L > 1: result &= ' ' & strArg(instr[1], dbg.mem[pc + 1], dbg.state.base)
  if L > 2: result &= ' ' & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base)
  if L > 3: result &= ' ' & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)

  result &= "\t/* "
  if L > 0: result &= $instr[0]
  if L > 1: result &= ' ' & $dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
  if L > 2: result &= ' ' & $dbgFetch(dbg.mem, instr[2], pc, 2, dbg.state.base)
  if L > 3: result &= ' ' & $dbgFetch(dbg.mem, instr[3], pc, 3, dbg.state.base)
  result &= " */"

func strInstr(pc: int, dbg: Debugger): string =
  let instr = decodeInstruction(dbg.mem[pc])
  if not detectIdiom(instr, pc, dbg, result):
    result = genericDisass(instr, pc, dbg)

func shouldBreakOnPC(pc: int, dbg: Debugger): bool =
  for bp in dbg.breakpoints:
    if bp.kind == Function and pc == bp.pc:
      return true
  return false

proc debugProgram(origProg: Memory) =
  var output: Option[int]
  var input = 0
  var dbg: Debugger

  resetDebugger(dbg, origProg)

  while not dbg.state.halt:
    let pcCur = dbg.state.nextPC

    if SingleStep in dbg.flags or shouldBreakOnPC(pcCur, dbg):
      stderr.write(toHex(pcCur) & '\t' & strInstr(pcCur, dbg) & '\n')

      var step = false
      while not step:
        stderr.write("$ ")
        let line = stdin.readLine()
        if len(line) == 0:
          dbg.flags.incl(SingleStep)
          step = true
        else:
          let cmd = line.split()
          case cmd[0]:
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
              dbg.state.nextPC = 0
              resetDebugger(dbg, origProg)
              stderr.write("VM STATE RESET, DEBUGGER STATE UNCHANGED\n")
              stderr.write(strInstr(0, dbg) & '\n')
            of "break":
              if len(cmd) > 1:
                try:
                  var pc = 0
                  if len(cmd[1]) > 1 and cmd[1][0] == '0' and cmd[1][1] == 'x':
                    pc = fromHex[int](cmd[1])
                  else:
                    pc = parseInt(cmd[1])
                  let bp = Breakpoint(kind: Function, pc: pc)
                  dbg.breakpoints.add(bp)
                  stderr.write("BREAKING WHEN PC=0x" & toHex(pc) & '\n')
                except ValueError:
                  stderr.write("CAN'T SET BREAKPOINT: BAD ARGUMENT\n")
              else:
                stderr.write("CAN'T SET BREAKPOINT: NO ARGUMENT\n")

    if needsInput(dbg.state, dbg.mem) and (BreakOnInput in dbg.flags):
      var inputOk = false
      dbg.flags.incl(SingleStep)
      while not inputOk:
        stderr.write("INPUT: ")
        let line = stdin.readLine()
        try:
          input = parseInt(line)
          inputOk = true
        except ValueError:
          stderr.write("ERR\n")

    dbg.state = executeInstruction(input, dbg.state.nextPC, dbg.mem, dbg.state.base)
    
    output = dbg.state.output

    if isSome(output):
      stderr.write("OUTPUT: " & $output.get() & '\n')
      stdout.write($output.get() & '\n')

when isMainModule:
  let program = readProgramFromPath(if paramCount() > 0: paramStr(1) else: "input.txt")
  debugProgram(program)


