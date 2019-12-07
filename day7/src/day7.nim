import algorithm
import os
import options
import sequtils
import aocutils/intcode

type Amplifier = object
  phase: int
  pc: int
  memory: seq[int]
  consumedPhase: bool
  halted: bool
  output: int

proc initAmp(phase: int, program: seq[int]): Amplifier =
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

iterator perm(s: var seq[int]): seq[int] =
  var a = s
  yield a
  while nextPermutation(a): yield a

func chain(amps: var seq[Amplifier], input: int): int =
  result = input
  for i in 0..4: result = amplifier(amps[i], result)

func part1(program: seq[int]): int =
  var maxThrust = 0
  var phases = toSeq(0..4)
  for P in perm(phases):
    var amplifiers: seq[Amplifier]
    for i in 0..4: amplifiers.add(initAmp(P[i], program))
    let signal = chain(amplifiers, 0)
    if signal > maxThrust:
      maxThrust = signal
  
  result = maxThrust

func part2(program: seq[int]): int =
  var maxThrust = 0
  var phases = toSeq(5..9)
  for P in perm(phases):
    var E = 0
    var amplifiers: seq[Amplifier]
    for i in 0..4: amplifiers.add(initAmp(P[i], program))
    
    while not amplifiers[4].halted:
      E = chain(amplifiers, E)
    
    if E > maxThrust:
      maxThrust = E
  result = maxThrust

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  let program = readProgramFromPath(inputPath)
  echo($part1(program))
  echo($part2(program))
