import os
import bignum
import threadpool
import cpuinfo
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

proc distribute(numCPU: int, totalLoad: int, idxCPU: int): IndexRange {.noSideEffect.} =
  let coreLoad = totalLoad div numCPU
  if idxCPU < numCPU - 1:
    result = (idxCPU * coreLoad, idxCPU * coreLoad + coreLoad - 1)
  else:
    result = (idxCPU * coreLoad, idxCPU * coreLoad + coreLoad + (totalLoad mod numCPU) - 1)

proc worker(work: InputList, N: int, idx: int): seq[Int] =
  var sum1 = newInt()
  var sum2 = newInt()
  let param = distribute(NUM_CPU, N, idx)
  for i in param.first..param.last:
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

  if open(f, inputPath):
    var inputString: InputList
    while f.readLine(line):
      inputString.add(line)

    let N = len(inputString)
    echo("Input OK")
    var res: seq[WorkerResultFlow]
    
    for i in 0..NUM_CPU-1:
      res.add(spawn worker(inputString, N, i))

    for r in res:
      let ru = ^r
      sum1 += ru[0]
      sum2 += ru[1]
    echo((sum1, sum2))
  else:
    echo("IO error")

