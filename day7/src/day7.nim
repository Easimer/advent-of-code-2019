import algorithm
import os
import options
import sequtils
import times
import aocutils
import aocutils/intcode

type Amplifier = object
  phase: int
  pc: int
  memory: Memory
  consumedPhase: bool
  halted: bool
  output: int

proc initAmp(phase: int, program: Memory): Amplifier =
  result.phase = phase
  result.memory = program

proc amplifier(state: var Amplifier, signalInput: int): int =
  ## Yields when OUT is executed
  var ires: InterpreterResult
  while not ires.halt:
    let currentInput = if state.consumedPhase: signalInput else: state.phase
    ires = executeInstruction(currentInput, state.pc, state.memory)
    state.pc = ires.nextPC
    if ires.output.isSome():
      state.output = ires.output.get()
      return state.output
    if ires.consumedInput:
      state.consumedPhase = true
  state.halted = ires.halt
  state.output

iterator perm(s: seq[int]): seq[int] =
  var a = s
  yield a
  while nextPermutation(a): yield a

func chain(amps: var seq[Amplifier], input: int): int =
  result = input
  for i in 0..4: result = amplifier(amps[i], result)

type Work = object
  program: Memory
  phasePermutations: seq[seq[int]]

proc worker1(work: Work, first, last: int): int =
  result = 0
  for i in first .. last:
    var amplifiers: seq[Amplifier]
    for j in 0..4: amplifiers.add(initAmp(work.phasePermutations[i][j], work.program))
    let signal = chain(amplifiers, 0)
    if signal > result:
      result = signal

proc worker2(work: Work, first, last: int): int =
  result = 0
  for i in first .. last:
    var E = 0
    var amplifiers: seq[Amplifier]
    for j in 0..4: amplifiers.add(initAmp(work.phasePermutations[i][j], work.program))
    
    while not amplifiers[4].halted:
      E = chain(amplifiers, E)
    
    if E > result:
      result = E

when isMainModule:
  let parseStart = getTime()
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  let P = readProgramFromPath(inputPath)
  let parseEnd = getTime()

  let part1Start = getTime()
  let output1 = $system.max(distributeWork(worker1, Work(program: P, phasePermutations: toSeq(perm(toSeq(0..4)))), 0, 120))
  let part1End = getTime()
  let part2Start = getTime()
  let output2 = $system.max(distributeWork(worker2, Work(program: P, phasePermutations: toSeq(perm(toSeq(5..9)))), 0, 120))
  let part2End = getTime()

  var R: AOCResults
  R.init(output1, output2, inMicroseconds(parseEnd - parseStart), inMicroseconds(part1End - part1Start), inMicroseconds(part2End - part2Start))
  printResults(R)
