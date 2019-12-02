import os
import bignum
import threadpool
import cpuinfo
import aocutils
import times
#import nimprof

type
  WorkerResult {.shallow.} = seq[Int]
  WorkerResultFlow = FlowVar[WorkerResult]
  InputList {.shallow.} = seq[string]
  IndexRange = tuple[first: int, last: int]

let NUM_CPU = if countProcessors() > 0: countProcessors() else: 2

proc calculateFuel(M: string): (Int, Int) {.noSideEffect.} =
  var sum = newInt()
  let three = newInt(3)
  let two = newInt(2)
  let zero = newInt(0)
  let I = (newInt(M) div three) - two
  var F = I
  while F > zero:
    {.unroll: 8.}
    sum += F
    F = (F div three) - two
  result = (I, sum)

proc worker(work: InputList, first: int, last: int): seq[Int] =
  var sum1 = newInt()
  var sum2 = newInt()

  for i in first .. last:
    let res = calculateFuel(work[i])
    sum1 += res[0]
    sum2 += res[1]
  result = @[sum1, sum2]

when isMainModule:
  var
    f: File
    line: string
    sum1: Int = newInt()
    sum2: Int = newInt()

  let inputPath = if paramCount() > 0: paramStr(1) else: "day1.txt"

  let parseStart = cpuTime()
  if open(f, inputPath):
    var inputString: InputList
    while f.readLine(line):
      inputString.add(line)
    let parseEnd = cpuTime()

    let combinedStart = cpuTime()
    let res = distributeWork(worker, inputString)

    for r in res:
      sum1 += r[0]
      sum2 += r[1]
    
    let combinedEnd = cpuTime()

    var R: AOCResults
    R.init($sum1, $sum2, (parseEnd - parseStart) * 1000 * 1000, (combinedEnd - combinedStart) * 1000 * 1000, (combinedEnd - combinedStart) * 1000 * 1000, true)
    printResults(R)
  else:
    echo("IO error")

