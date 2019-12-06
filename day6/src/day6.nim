import os
import strutils
import tables

type
  Orbit = tuple[lhs, rhs: int]
  OrbitMap = Table[int, int] # X -> Y, if X orbits Y

func bodyNameToInt(bodyName: string): int = 
  for ch in bodyName:
    result = result * 256 + ord(ch)

func newOrbit(lhs: string, rhs: string): Orbit =
  result.lhs = bodyNameToInt(lhs)
  result.rhs = bodyNameToInt(rhs)

proc loadOrbits(f: var File): seq[Orbit] =
  for line in f.lines():
    let rawOrbit = line.split(')')
    result.add(newOrbit(rawOrbit[1], rawOrbit[0]))

func countIndirectOrbits(body: int, M: OrbitMap): int =
  assert body in M
  #var indirectlyOrbits: HashSet[int]
  var orbited = M[body]
  while orbited in M:
    orbited = M[orbited]
    result += 1


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

  f.close()
