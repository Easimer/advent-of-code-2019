import os
import options
import strutils
import tables
import aocutils/intcode
import aocutils/intcode/internal
import dbg/common
import dbg/idiom

func genericDisass(instr: DecodedInstruction, pc: int, dbg: Debugger): string = disassemble(instr, pc, dbg) & '\t' & annotation(instr, pc, dbg)

func strInstr*(pc: int, dbg: Debugger): string =
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


