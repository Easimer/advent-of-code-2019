import tables

iterator opcodes(f: File): int =
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

proc executeInstruction(pc: int, memory: var seq[int]): bool =
  case memory[pc + 0]:
    of 1:
      #echo($memory[pc + 3] & " <- " & $memory[1] & " + " & $memory[pc + 2])
      memory[memory[pc + 3]] = memory[memory[pc + 1]] + memory[memory[pc + 2]]
    of 2:
      #echo($memory[pc + 3] & " <- " & $memory[pc + 1] & " * " & $memory[pc + 2])
      memory[memory[pc + 3]] = memory[memory[pc + 1]] * memory[memory[pc + 2]]
    of 99:
      result = true
    else:
      echo("UNKNOWN OPCODE " & $memory[0])

proc runWithInitialState(noun, verb: int, origMemory: seq[int]): int =
  var pc = 0
  var program = origMemory

  program[1] = noun
  program[2] = verb

  while not executeInstruction(pc, program):
    pc += 4
  
  result = program[0]

when isMainModule:
  var f = open("input.txt")
  var program: seq[int]
  
  for op in opcodes(f):
    program.add(op)
  
  echo("Part 1: " & $(runWithInitialState(12, 2, program)))

  var finished = false

  for noun in 0 .. 99:
    for verb in 0 .. 99:
      if runWithInitialState(noun, verb, program) == 19690720:
        echo("Part 2: " & $(noun, verb))
        finished = true
        break
    
    if finished: break
