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
      

func chain(amps: var seq[Amplifier], input: int): int =
  let A = amplifier(amps[0], input)
  let B = amplifier(amps[1], A)
  let C = amplifier(amps[2], B)
  let D = amplifier(amps[3], C)
  amplifier(amps[4], D)

func part1(program: seq[int]): int =
  var maxThrust = 0
  var phases = toSeq(0..4)
  while true:
    var amplifiers: seq[Amplifier]
    for i in 0..4: amplifiers.add(initAmp(phases[i], program))
    let signal = chain(amplifiers, 0)
    if signal > maxThrust:
      maxThrust = signal
    if not nextPermutation(phases):
      break
  
  result = maxThrust

func part2(program: seq[int]): int =
  var maxThrust = 0
  var phases = toSeq(5..9)
  while true:
    var E = 0
    var amplifiers: seq[Amplifier]
    for i in 0..4: amplifiers.add(initAmp(phases[i], program))
    
    while not amplifiers[4].halted:
      E = chain(amplifiers, E)
    
    if E > maxThrust:
      maxThrust = E
    if not nextPermutation(phases):
      break
 
  result = maxThrust

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  let program = readProgramFromPath(inputPath)
  echo($part1(program))
  echo($part2(program))
