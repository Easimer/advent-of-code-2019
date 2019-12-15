import tables
import aocutils/intcode
import aocutils/intcode/internal
import common
import strutils
import macros

type ArgIdx = range[0..3]

template formatInstruction(mnemonic: string, a0: int): untyped =
  res = mnemonic & ' ' & strArg(instr[a0], dbg.mem[pc + a0], dbg.state.base)

template formatInstruction(mnemonic: string, a0: int, a1: int): untyped =
  res = mnemonic & ' ' & strArg(instr[a0], dbg.mem[pc + a0], dbg.state.base) & ", " & strArg(instr[a1], dbg.mem[pc + a1], dbg.state.base)

func detectIdiomMove(instr: DecodedInstruction, pc: int, dbg: Debugger, res: var string): bool =
  case instr[0]:
    of ADD:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      let arg1 = dbgFetch(dbg.mem, instr[2], pc, 2, dbg.state.base)
      if arg0 == 0:
        #res = "MOV " & strArg(instr[1], dbg.mem[pc + 1], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        formatInstruction("MOV", 1, 3)
        res &= '\t' & annotation(instr, pc, dbg)
        return true
      elif arg1 == 0:
        #res = "MOV " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        formatInstruction("MOV", 2, 3)
        res &= '\t' & annotation(instr, pc, dbg)
        return true
    of MUL:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      let arg1 = dbgFetch(dbg.mem, instr[2], pc, 2, dbg.state.base)
      if arg0 == 1:
        #res = "MOV " & strArg(instr[1], dbg.mem[pc + 1], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        formatInstruction("MOV", 1, 3)
        res &= '\t' & annotation(instr, pc, dbg)
        return true
      elif arg1 == 1:
        #res = "MOV " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base) & ", " & strArg(instr[3], dbg.mem[pc + 3], dbg.state.base)
        formatInstruction("MOV", 2, 3)
        res &= '\t' & annotation(instr, pc, dbg)
        return true
    else:
      return false

func detectIdiomUnconditionalJmp(instr: DecodedInstruction, pc: int, dbg: Debugger, res: var string): bool =
  case instr[0]:
    of JZ:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      if arg0 == 0:
        #res = "JMP " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base)
        formatInstruction("JMP", 2)
        res &= '\t' & annotation(instr, pc, dbg)
        return true
    of JNZ:
      let arg0 = dbgFetch(dbg.mem, instr[1], pc, 1, dbg.state.base)
      if arg0 == 1:
        #res = "JMP " & strArg(instr[2], dbg.mem[pc + 2], dbg.state.base)
        formatInstruction("JMP", 2)
        res &= '\t' & annotation(instr, pc, dbg)
        return true
    else:
      return false

func detectIdiom*(instr: DecodedInstruction, pc: int, dbg: Debugger, res: var string): bool =
  if detectIdiomMove(instr, pc, dbg, res): return true
  if detectIdiomUnconditionalJmp(instr, pc, dbg, res): return true