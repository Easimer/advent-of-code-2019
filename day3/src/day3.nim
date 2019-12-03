import aocutils
import options
import os
import strutils
import times

type
  Point[T] = object
    x: T
    y: T
  LineSegment[T] = object
    p0: Point[T]
    p1: Point[T]

  IntersectionPoint[T] = object
    P: Point[T]
    stepSum: T

func newPoint[T](x, y: T): Point[T] =
  result.x = x
  result.y = y

func newIntersectionPoint[T](P: Point[T], stepSum: T): IntersectionPoint[T] =
  result.P = P
  result.stepSum = stepSum

func isOrigin[T](p: Point[T]): bool = p.x == 0 and p.y == 0

func `+`[T](l, r: Point[T]): Point[T] =
  result.x = l.x + r.x
  result.y = l.y + r.y

func manhattan[T](p0: Point[T], p1: Point[T]): T = abs(p1.x - p0.x) + abs(p1.y - p0.y)

func newSegment[T](s, e: Point[T]): LineSegment[T] =
  result.p0 = s
  result.p1 = e

proc intersect[T](l0: LineSegment[T], l1: LineSegment[T], step0: T, step1: T): Option[IntersectionPoint[T]] =
  let p0_x = float l0.p0.x
  let p0_y = float l0.p0.y
  let p1_x = float l0.p1.x
  let p1_y = float l0.p1.y
  let p2_x = float l1.p0.x
  let p2_y = float l1.p0.y
  let p3_x = float l1.p1.x
  let p3_y = float l1.p1.y

  let s1_x = p1_x - p0_x
  let s1_y = p1_y - p0_y
  let s2_x = p3_x - p2_x
  let s2_y = p3_y - p2_y

  let det = -s2_x * s1_y + s1_x * s2_y

  if abs(det) > 0.01:
    let s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y)
    let t = ( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y)

    if s >= 0 and s <= 1 and t >= 0 and t <= 1:
      #echo((det, s, t, p0_x + t * s1_x, p0_y + t * s1_y, l0, l1))
      let P = newPoint(T(p0_x + t * s1_x), T(p0_y + t * s1_y))
      let seg0dist = manhattan(P, l0.p0)
      let seg1dist = manhattan(P, l1.p0)
      result = some(newIntersectionPoint(P, step0 + seg0dist + step1 + seg1dist))

func cmdToDirection(cmd: string): Point[int] =
  let D = cmd.substr(1)
  case cmd[0]:
    of 'U':
      result = newPoint(0, parseInt(D))
    of 'D':
      result = newPoint(0, -parseInt(D))
    of 'L':
      result = newPoint(-parseInt(D), 0)
    of 'R':
      result = newPoint(parseInt(D), 0)
    else:
      raise newException(ValueError, "Invalid direction " & cmd[0])

iterator lineFromFile[T](f: var File): LineSegment[T] =
  let line = f.readLine()
  var pCur: Point[T]
  for cmd in line.split(','):
    let dir = cmdToDirection(cmd)
    let next = pCur + dir
    yield newSegment(pCur, next)
    pCur = next

iterator intersectionPoints[T](lhs, rhs: seq[LineSegment[T]]): IntersectionPoint[T] =
  var step0 = 0
  for seg0 in lhs:
    var step1 = 0
    for seg1 in rhs:
      let P = intersect(seg0, seg1, step0, step1)
      if isSome(P):
        yield get(P)
      step1 += manhattan(seg1.p0, seg1.p1)
    step0 += manhattan(seg0.p0, seg0.p1)

when isMainModule:
  let parseStart = getTime()
  ###
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var f: File = open(inputPath)
  
  var wire0: seq[LineSegment[int]]
  var wire1: seq[LineSegment[int]]

  # Read wire 0
  for line in lineFromFile[int](f):
    wire0.add(line)
  # Read wire 1
  for line in lineFromFile[int](f):
    wire1.add(line)
  f.close()
  ###
  let parseEnd = getTime()

  let combinedStart = getTime()
  ###
  var closestPoint: Point[int]
  var closestPointSteps: Point[int]
  var closestDist = int.high()
  var closestSteps = int.high()

  for XP in intersectionPoints[int](wire0, wire1):
    let stepP = XP.stepSum
    let distP = XP.P.x + XP.P.y

    if not isOrigin(XP.P):
      if stepP < closestSteps:
        closestSteps = stepP
        closestPointSteps = XP.P
      
      if distP < closestDist:
        closestDist = distP
        closestPoint = XP.P
  ###
  let combinedEnd = getTime()

  let output1 = $closestDist
  let output2 = $closestSteps
  
  var R: AOCResults
  R.init(output1, output2, float inMicroseconds(parseEnd - parseStart), float inMicroseconds(combinedEnd - combinedStart), float inMicroseconds(combinedEnd - combinedStart), true)
  printResults(R)
