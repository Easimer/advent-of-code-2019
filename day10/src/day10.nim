import os
import sets
import heapqueue
import math
import json

type
  Field = seq[seq[bool]]
  Point = (int, int)
  AsteroidAndAngle = object
    asteroid: Point
    angle: float

func `<`(lhs, rhs: AsteroidAndAngle): bool = lhs.angle < rhs.angle

iterator asteroidPoints(f: Field): Point =
  ## From an asteroid field, generate a list of points
  var y = 0
  for line in f:
    var x = 0
    for b in line:
      if b:
        yield (x, y)
      x += 1
    y += 1

func hasLineOfSight(p0: Point, p1: Point, f: Field): bool =
  ## Determines whether `p0` and `p1` can see each other
  ## in the asteroid field `f`.

  # Calculate the direction vector of the line between p0 and p1
  let dx = float(p1[0] - p0[0])
  let dy = float(p1[1] - p0[1])

  if dx != 0 and dy != 0:
    # Case 1: the `p0` - `p1` line is not parallel to neither the X or Y-axis.
    for p in asteroidPoints(f):
      # For every `p` points solve the line's parametric
      # equation for `t`: p = p0 + delta * t
      if p != p0 and p != p1:
        let tx = float(p[0] - p0[0]) / dx
        let ty = float(p[1] - p0[1]) / dy

        # If tx and ty equal then the point is somewhere on the line.
        if abs(ty - tx) < 0.000000000001:
          # If tx (or ty) is between [0; 1] then this point is obstructing
          # the way between `p0` and `p1`.
          if (tx > 0 and tx < 1):
            return false
  elif dx == 0:
    # Case 2: the `p0` - `p1` line is parallel to the X-axis.
    for p in asteroidPoints(f):
      # Equality of `p`.x and `p0`.x implies `p` is on the line.
      if p != p0 and p != p1 and p[0] == p0[0]:
        let ty = float(p[1] - p0[1]) / dy

        # If ty is between [0; 1] then this point is obstructing
        # the way between `p` and `p1`.
        if (ty > 0 and ty < 1):
          return false
  elif dy == 0:
    # Case 3: the `p0` - `p1` line is parallel to the Y-axis.
    for p in asteroidPoints(f):
      # Equality of `p`.y and `p0`.y implies `p` is on the line.
      if p != p0 and p != p1 and p[1] == p0[1]:
        let tx = float(p[0] - p0[0]) / dx

        # If tx is between [0; 1] then this point is obstructing
        # the way between `p` and `p1`.
        if (tx > 0 and tx < 1):
          return false

  # No points blocked the way.
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
  ## Calculates the maximum number of other asteroids seen by any of the asteroids.
  var S: HashSet[(Point, Point)]

  for aster0 in asteroidPoints(f):
    var seen = 0
    for aster1 in asteroidPoints(f):
      if aster0 != aster1:
        if (aster0, aster1) in S:
          seen += 1
        else:
          if hasLineOfSight(aster0, aster1, f):
            seen += 1
            S.incl((aster0, aster1))
            S.incl((aster1, aster0))
    if seen > result:
      result = seen
      station = aster0

func countTrues(a: seq[seq[bool]]): int =
  for i in a:
    for b in i:
      if b: result += 1

func part2(f: Field, station: Point): int =
  ## Vaporize all the asteroids.
  var state = f # Current state of the asteroid field
  var i = 0 # Ordinal of the current asteroid being vaporized ([1; ...[)
  while countTrues(state) > 1:
    # Priority queue of asteroids
    # Asteroids are sorted by their angle
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
      state[next.asteroid[1]][next.asteroid[0]] = false
      i += 1
      if i == 200:
        return next.asteroid[0] * 100 + next.asteroid[1]

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  let field = loadInput(inputPath)
  var station: Point
  echo(%*{"output1": $part1(field, station), "output2": $part2(field, station)})