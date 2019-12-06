import os
import sets
import strutils
import tables

type
  Orbit = tuple[lhs, rhs: int]
  OrbitMap = Table[int, int] # X -> Y, if X orbits Y

func bodyNameToInt(bodyName: string): int = 
  for ch in bodyName:
    result = result * 256 + ord(ch)

const BODY_YOU = bodyNameToInt("YOU")
const BODY_SAN = bodyNameToInt("SAN")

func newOrbit(lhs: string, rhs: string): Orbit =
  result.lhs = bodyNameToInt(lhs)
  result.rhs = bodyNameToInt(rhs)

proc loadOrbits(f: var File): seq[Orbit] =
  for line in f.lines():
    let rawOrbit = line.split(')')
    result.add(newOrbit(rawOrbit[1], rawOrbit[0]))

func countIndirectOrbits(body: int, M: OrbitMap): int =
  assert body in M
  var orbited = M[body]
  while orbited in M:
    orbited = M[orbited]
    result += 1

func part2(M: OrbitMap): int =
  var setYou: HashSet[int] # All bodies from YOU to COM
  var setSan: HashSet[int] # All bodies from SAN to COM

  var orbited = M[BODY_YOU]
  while orbited in M:
    setYou.incl(orbited)
    orbited = M[orbited]
  orbited = M[BODY_SAN]
  while orbited in M:
    setSan.incl(orbited)
    orbited = M[orbited]
  let setCom = intersection(setYou, setSan)
  debugEcho(setCom)

  var pathYouToMain: seq[int] # Path from to you to the first point in the main orbit transfer branch
  var pathSanToMain: seq[int] # Path from to Santa to the first point in the main orbit transfer branch
  
  var nextBody = M[BODY_YOU]
  while nextBody in M and not (nextBody in setCom):
    pathYouToMain.add(nextBody)
    nextBody = M[nextBody]
  pathYouToMain.add(nextBody)

  nextBody = M[BODY_SAN]
  while nextBody in M and not (nextBody in setCom):
    pathSanToMain.add(nextBody)
    nextBody = M[nextBody]
  pathSanToMain.add(nextBody)

  #debugEcho((pathYouToMain, pathSanToMain))
  # Sub one because both lists contain the first common point, then
  # sub another one because we need the number of the edges
  len(pathYouToMain) + len(pathSanToMain) - 2

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var f = open(inputPath)
  let orbits = loadOrbits(f)
  let orbitMap = OrbitMap(toTable(orbits))

  let directOrbits = len(orbits)
  var indirectOrbits = 0
  for k, v in orbitMap:
    indirectOrbits += countIndirectOrbits(k, orbitMap)

  let output1 = $(directOrbits + indirectOrbits)
  echo(output1)
  echo(part2(orbitMap))

  f.close()
