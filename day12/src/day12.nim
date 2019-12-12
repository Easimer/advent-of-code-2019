import strutils
import sets
import sugar
import sequtils
import math

type
  Planet = object
    pos: (int, int, int)
    vel: (int, int, int)

func pot(p: Planet): int = abs(p.pos[0]) + abs(p.pos[1]) + abs(p.pos[2])
func kin(p: Planet): int = abs(p.vel[0]) + abs(p.vel[1]) + abs(p.vel[2])
func tot(p: Planet): int = pot(p) * kin(p)

template applyGravityAxis(planet0, planet1: var Planet, i: int) = 
  if planet0.pos[i] < planet1.pos[i]:
    planet0.vel[i] += 1
    planet1.vel[i] -= 1
  elif planet0.pos[i] > planet1.pos[i]:
    planet0.vel[i] -= 1
    planet1.vel[i] += 1


func simulate(state: seq[Planet]): seq[Planet] =
  var S: HashSet[int]
  var planets = state

  for i in 0 .. planets.high():
    S.incl(i)
    for j in 0 .. planets.high():
      if not (j in S):
        applyGravityAxis(planets[i], planets[j], 0)
        applyGravityAxis(planets[i], planets[j], 1)
        applyGravityAxis(planets[i], planets[j], 2)

  for i in 0 .. planets.high():
    planets[i].pos[0] += planets[i].vel[0]
    planets[i].pos[1] += planets[i].vel[1]
    planets[i].pos[2] += planets[i].vel[2]

  result = planets

proc readInput(path: string): seq[Planet] =
  var f = open(path)
  defer: close(f)

  for line in f.lines():
    let repl = line.replace("<", "").replace(">", "")
    let coords = repl.split(", ")
    var P: Planet
    
    let x = coords[0].split("=")[1]
    P.pos[0] = parseInt(x)
    let y = coords[1].split("=")[1]
    P.pos[1] = parseInt(y)
    let z = coords[2].split("=")[1]
    P.pos[2] = parseInt(z)
    result.add(P)

template cycle(planets: seq[Planet], dim: int): int =
  let posInit = planets.map(p => p.pos[dim])
  let velInit = planets.map(p => p.vel[dim])

  var state = planets
  var steps = 1
  state = simulate(state)
  while state.map(p => p.pos[dim]) != posInit or state.map(p => p.vel[dim]) != velInit:
    steps += 1
    state = simulate(state)
  
  steps

when isMainModule:
  var planets = readInput("input.txt")
  echo(planets)
  let initial = planets

  for i in countup(0, 999):
    var newState = simulate(planets)
    echo(i)
    echo(planets)
    planets = newState
  
  var res = 0
  for planet in planets:
    res += tot(planet)
  echo(res)

  let cycleX = cycle(initial, 0)
  let cycleY = cycle(initial, 1)
  let cycleZ = cycle(initial, 2)
  echo(lcm(lcm(cycleX, cycleY), cycleZ))
