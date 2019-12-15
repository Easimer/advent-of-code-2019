import tables
import aocutils/intcode
import aocutils/intcode/internal

type
  BreakpointKind* = enum Function, Data
  Breakpoint* = object
    case kind*: BreakpointKind
      of Function:
        pc*: int
      of Data:
        address: int
        read*, write*: bool
  
  DebuggerFlag* {.size: sizeof(cint).} = enum
    SingleStep,
    BreakOnInput,

  Debugger* = object
    flags*: set[DebuggerFlag]
    breakpoints*: seq[Breakpoint]
    mem*: Memory

    state*: InterpreterResult
    
const DebuggerDefaultFlags* = {SingleStep, BreakOnInput}

func resetDebugger*(dbg: var Debugger, mem: Memory) =
  dbg.flags = DebuggerDefaultFlags
  dbg.breakpoints = @[]
  dbg.mem = mem

func strArg*(mode, arg, base: int): string =
  case mode:
    of 0: '[' & $arg & ']'
    of 1: $arg
    of 2: '[' & $arg & " + " & $base & "]"
    else: '?' & $arg & '?' & " mode = " & $mode

func annotation*(instr: DecodedInstruction, pc: int, dbg: Debugger): string =
  let L = len(instr[0])

  result = "/* "
  if L > 0: result &= $instr[0]
  if L > 1: result &= ' ' & $dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
  if L > 2: result &= ' ' & $dbgFetch(dbg.mem, instr[2], pc, 2, dbg.state.base)
  if L > 3: result &= ' ' & $dbgFetch(dbg.mem, instr[3], pc, 3, dbg.state.base)
  result &= " */"

func disassemble*(instr: DecodedInstruction, pc: int, dbg: Debugger): string =
  let L = len(instr[0])
  if L > 0: result = $instr[0]
  if L > 1: result &= ' ' & strArg(instr[1], dbg.mem[pc + 1], dbg.state.base)
  if L > 2: result &= ' ' & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base)
  if L > 3: result &= ' ' & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)