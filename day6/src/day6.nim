import aocutils
import os
import sets
import strutils
import tables
import times

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

proc loadOrbits(): seq[Orbit] =
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var f = open(inputPath)
  defer: f.close()
  for line in f.lines():
    let rawOrbit = line.split(')')
    result.add(newOrbit(rawOrbit[1], rawOrbit[0]))

func countIndirectOrbits(body: int, M: OrbitMap): int =
  assert body in M
  var orbited = M[body]
  while orbited in M:
    orbited = M[orbited]
    result += 1

func pathFromToAnyIn(f: int, C: HashSet[int], M: OrbitMap): seq[int] =
  var nextBody = M[f]
  while nextBody in M and not (nextBody in C):
    result.add(nextBody)
    nextBody = M[nextBody]
  result.add(nextBody)

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

  let pathYouToMain = pathFromToAnyIn(BODY_YOU, setCom, M)
  let pathSanToMain = pathFromToAnyIn(BODY_SAN, setCom, M)

  # Sub one because both lists contain the first common point, then
  # sub another one because we need the number of the edges
  len(pathYouToMain) + len(pathSanToMain) - 2

when isMainModule:
  let parseStart = getTime()
  let orbits = loadOrbits()
  let orbitMap = OrbitMap(toTable(orbits))
  let parseEnd = getTime()

  let part1Start = getTime()
  let directOrbits = len(orbits)
  var indirectOrbits = 0
  for k, v in orbitMap:
    indirectOrbits += countIndirectOrbits(k, orbitMap)
  let output1 = $(directOrbits + indirectOrbits)
  let part1End = getTime()

  let part2Start = getTime()
  let output2 = $part2(orbitMap)
  let part2End = getTime()

  var R: AOCResults
  R.init(output1, output2, float inMicroseconds(parseEnd - parseStart), float inMicroseconds(part1End - part1Start), float inMicroseconds(part2End - part2Start))
  printResults(R)

