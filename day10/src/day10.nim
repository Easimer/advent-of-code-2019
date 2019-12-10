import os
import sets
import tables
import heapqueue
import math
import json

type
  Field = seq[seq[bool]]
  Point = (int, int)

iterator asteroidPoints(f: Field): Point =
  var y = 0
  for line in f:
    var x = 0
    for b in line:
      if b:
        yield (x, y)
      x += 1
    y += 1

func hasLineOfSight(p0: Point, p1: Point, f: Field): bool =
  let dx = float(p1[0] - p0[0])
  let dy = float(p1[1] - p0[1])
    
  #debugEcho("LOS BETWEEN " & $p0 & " AND " & $p1)
  if dx != 0 and dy != 0:
    for p in asteroidPoints(f):
      if p != p0 and p != p1:
        let tx = float(p[0] - p0[0]) / dx
        let ty = float(p[1] - p0[1]) / dy

        #debugEcho((p0, p1, p, (dx, dy), (tx, ty)))
        if abs(ty - tx) < 0.000000000001:
          if (tx > 0 and tx < 1):
            #debugEcho("NOT")
            return false
  elif dx == 0:
    for p in asteroidPoints(f):
      if p != p0 and p != p1 and p[0] == p0[0]:
        let ty = float(p[1] - p0[1]) / dy

        #debugEcho((p0, p1, p, (dx, dy), (NaN, ty)))
        if (ty > 0 and ty < 1):
          #debugEcho("NOT")
          return false
  elif dy == 0:
    for p in asteroidPoints(f):
      if p != p0 and p != p1 and p[1] == p0[1]:
        let tx = float(p[0] - p0[0]) / dx

        #debugEcho((p0, p1, p, (dx, dy), (tx, NaN)))
        if (tx > 0 and tx < 1):
          #debugEcho("NOT")
          return false

  #debugEcho("YES")
  return true

proc loadInput(path: string): Field =
  var f = open(path)
  defer: close(f)

  while not f.endOfFile():
    let line = f.readLine()
    var fieldLine: seq[bool]
    for ch in line:
      fieldLine.add(ch == '#')
    result.add(fieldLine)

func part1(f: Field, station: var Point): int =
  var S: HashSet[(Point, Point)]
  var M: Table[Point, int]
  for aster0 in asteroidPoints(f):
    M[aster0] = 0
    #debugEcho("==============")
    #debugEcho(aster0)
    for aster1 in asteroidPoints(f):
      if aster0 != aster1:
        #debugEcho(aster1)
        if (aster0, aster1) in S or (aster1, aster0) in S:
          M[aster0] += 1
        else:
          if hasLineOfSight(aster0, aster1, f):
            M[aster0] += 1
            S.incl((aster0, aster1))
  
  var max = 0
  for aster, N in M:
    #debugEcho(aster, N)
    if N > max:
      max = N
      station = aster
  result = max

type AsteroidAndAngle = object
  asteroid: Point
  angle: float

func `<`(lhs, rhs: AsteroidAndAngle): bool = lhs.angle < rhs.angle

func countTrues(a: seq[seq[bool]]): int =
  for i in a:
    for b in i:
      if b: result += 1

func part2(f: Field, station: Point): int =
  var state = f
  #debugEcho("STATION " & $station)
  var i = 0
  while countTrues(state) > 1:
    #debugEcho("NEW RUN")
    var visible: HeapQueue[AsteroidAndAngle]
    for asteroid in asteroidPoints(state):
      if asteroid != station:
        if hasLineOfSight(station, asteroid, state):
          let dy = float(asteroid[1] - station[1])
          let dx = float(asteroid[0] - station[0])
          var angle = arctan2(dy, dx) + (math.PI / 2.0)
          while angle < 0:
            angle += 2 * math.PI

          let AAA = AsteroidAndAngle(asteroid: asteroid, angle: angle)
          visible.push(AAA)
    
    while len(visible) > 0:
      let next = visible.pop()
      #debugEcho("Next: " & $next)
      state[next.asteroid[1]][next.asteroid[0]] = false
      i += 1
      if i == 200:
        return next.asteroid[0] * 100 + next.asteroid[1]
    #debugEcho(state)
    

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  let field = loadInput(inputPath)
  var station: Point
  echo(%*{"output1": $part1(field, station), "output2": $part2(field, station)})