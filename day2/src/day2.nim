import tables
import times
import aocutils
import options

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

type WorkDay2 = object
  program: seq[int]

proc worker(work: WorkDay2, first: int, last: int): Option[(int, int)] =
  for noun in first .. last:
    for verb in 0 .. 99:
      if runWithInitialState(noun, verb, work.program) == 19690720:
        result = some((noun, verb))
        break

proc testWorker(work: int, first: int, last: int): int = 0  

when isMainModule:
  var f = open("input.txt")
  var program: seq[int]
  
  let parseStart = cpuTime()

  for op in integersFromFile(f):
    program.add(op)
  
  let parseEnd = cpuTime()

  let part1Start = cpuTime()
  echo("Part 1: " & $(runWithInitialState(12, 2, program)))
  let part1End = cpuTime()

  var finished = false

  let part2Start = cpuTime()
  # Part 2
  #for noun in 0 .. 99:
  #  for verb in 0 .. 99:
  #    if runWithInitialState(noun, verb, program) == 19690720:
  #      echo("Part 2: " & $(noun, verb))
  #      finished = true
  #      break
    
  #  if finished: break
  
  var work: WorkDay2
  work.program = program
  let results = distributeWorkNoInput(worker, work, 0, 99)
  for result in results:
    if isSome(result):
      echo("Part 2: " & $(get(result)))
      break
  
  let part2End = cpuTime()

  echo("=====================================")
  echo("Parse\t"  & $((parseEnd - parseStart) * 1000) & " ms")
  echo("Part 1\t" & $((part1End - part1Start) * 1000) & " ms")
  echo("Part 2\t" & $((part2End - part2Start) * 1000) & " ms")