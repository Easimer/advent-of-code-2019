import cpuinfo
import threadpool
import json

type
  WorkIndexRange* = tuple[first: int, last: int]
  WorkerFunc [TIn, TOut] = (proc(work: openArray[TIn], first: int, last: int): TOut)
  AOCResults* = object
    output1: string
    output2: string
    unitTime: string
    timePreprocess: float
    isTimeCombined: bool
    timePart1: float
    timePart2: float

proc init*[TTP, TT1, TT2](R: var AOCResults, output1: string, output2: string, timePreprocess: TTP, timePart1: TT1, timePart2: TT2, isTimeCombined: bool = false) =
  R.output1 = output1
  R.output2 = output2
  R.timePreprocess = float(timePreprocess)
  R.timePart1 = float(timePart1)
  R.timePart2 = float(timePart2)
  R.unitTime = "us"
  R.isTimeCombined = isTimeCombined

proc distributeWorkIndices(numCPU: int, totalLoad: int, idxCPU: int): WorkIndexRange {.noSideEffect.} =
  let coreLoad = totalLoad div numCPU
  if idxCPU < numCPU - 1:
    result = (idxCPU * coreLoad, idxCPU * coreLoad + coreLoad - 1)
  else:
    result = (idxCPU * coreLoad, idxCPU * coreLoad + coreLoad + (totalLoad mod numCPU) - 1)

proc workerProxy[TIn, TOut](worker: (proc(work: seq[TIn], first: int, last: int): TOut), work: seq[TIn], first: int, last: int): TOut =
  result = worker(work, first, last)

proc workerProxy[TIn, TOut](worker: (proc(work: TIn, first: int, last: int): TOut), work: TIn, first: int, last: int): TOut =
  result = worker(work, first, last)

proc distributeWork*[TIn, TOut](procWorker: (proc(work: seq[TIn], first: int, last: int): TOut), work: seq[TIn]): seq[TOut] =
  let numCPU = if countProcessors() > 0: countProcessors() else: 2
  let totalLoad = len(work)
  var futures: seq[FlowVar[TOut]]
  for i in 0 .. numCPU - 1:
    let indices = distributeWorkIndices(numCPU, totalLoad, i)
    futures.add(spawn workerProxy(procWorker, work, indices.first, indices.last))

  for future in futures:
    result.add(^future)

proc distributeWork*[TIn, TOut](procWorker: (proc(work: TIn, first: int, last: int): TOut), work: TIn, first: int, last: int): seq[TOut] =
  let numCPU = if countProcessors() > 0: countProcessors() else: 2
  let totalLoad = last - first
  var futures: seq[FlowVar[TOut]]
  for i in 0 .. numCPU - 1:
    let indices = distributeWorkIndices(numCPU, totalLoad, i)
    futures.add(spawn workerProxy(procWorker, work, first + indices.first, first + indices.last))

  for future in futures:
    result.add(^future)

proc printResults*(results: AOCResults) {.deprecated.} =
  echo(%*results)

func echo*(results: AOCResults) =
  debugEcho(%*results)

func minp*[T](a: openArray[T]): int =
  ## Finds the place of the minimum
  result = 0
  for i in 1 .. a.high():
    if a[i] < a[result]:
      result = i

func maxp*[T](a: openArray[T]): int =
  ## Finds the place of the maximum
  result = 0
  for i in 1 .. a.high():
    if a[i] < a[result]:
      result = i

func count*[T](arr: openArray[T], pred: proc(x: T): bool): int =
  ## Returns the number of elements for which `pred` holds.
  for elem in arr:
    if pred(elem):
      result += 1

func all*[T](arr: openArray[T], pred: proc(x: T): bool): bool =
  for elem in arr:
    if not pred(elem):
      return false
  return true

func any*[T](arr: openArray[T], pred: proc(x: T): bool): bool =
  for elem in arr:
    if pred(elem):
      return true
  return false

func contains*[T](arr: openArray[T], value: T): bool =
  for elem in arr:
    if elem == value: return true
  return false

func min*[T](arr: openArray[T]): T =
  ## Finds the value of the minimum
  var idx = 0
  for i in 1 .. arr.high():
    if arr[i] < arr[idx]:
      idx = i
  result = arr[idx]

func max*[T](arr: openArray[T]): T =
  ## Finds the value of the maximum
  var idx = 0
  for i in 1 .. arr.high():
    if arr[i] > arr[idx]:
      idx = i
  result = arr[idx]

iterator where*[T](arr: openArray[T], pred: proc(x: T): bool): T =
  for i in arr.low() .. arr.high():
    if pred(arr[i]):
      yield arr[i]
