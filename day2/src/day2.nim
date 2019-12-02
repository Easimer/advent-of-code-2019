import tables

type
  InterpreterResult = object
    nextPC: int
    halt: bool

iterator integersFromFile(f: File): int =
  var buf = 0
  var c: char = '0'

  while not endOfFile(f):
    while not endOfFile(f) and c != ',':
      buf *= 10
      buf += (ord(c) - ord('0'))
      c = f.readChar()
    yield buf
    if not endOfFile(f):
      c = f.readChar()
    buf = 0

template `$>`(address: untyped): untyped = memory[address]
template `$>>`(address: untyped): untyped = $>($>(address))

proc executeInstruction(pc: int, memory: var seq[int]): InterpreterResult =
  result.halt = false
  case $>(pc + 0):
    of 1:
      $>>(pc + 3) = $>>(pc + 1) + $>>(pc + 2)
      result.nextPC = pc + 4
    of 2:
      $>>(pc + 3) = $>>(pc + 1) * $>>(pc + 2)
      result.nextPC = pc + 4
    of 99:
      result.halt = true
    else:
      raise newException(ValueError, "Unknown opcode " & $($>(pc + 0)))

proc runWithInitialState(noun, verb: int, origMemory: seq[int]): int =
  var pc = 0
  var program = origMemory

  program[1] = noun
  program[2] = verb

  var ires: InterpreterResult

  while not ires.halt:
    ires = executeInstruction(pc, program)
    pc = ires.nextPC
  
  result = program[0]

when isMainModule:
  var f = open("input.txt")
  var program: seq[int]
  
  for op in integersFromFile(f):
    program.add(op)
  
  echo("Part 1: " & $(runWithInitialState(12, 2, program)))

  var finished = false

  # Part 2
  for noun in 0 .. 99:
    for verb in 0 .. 99:
      if runWithInitialState(noun, verb, program) == 19690720:
        echo("Part 2: " & $(noun, verb))
        finished = true
        break
    
    if finished: break
