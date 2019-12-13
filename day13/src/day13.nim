import json
import os
import options
import sugar
import tables
import gifwriter
import aocutils
import aocutils/intcode
import aocutils/vis

type
  VMState = enum OutX, OutY, OutT
  Tile = enum Empty = 0, Wall = 1, Block = 2, Paddle = 3, Ball = 4
  Point = tuple[x, y: int]

const BOARDSIZ = 48

func `+`(lhs: VMState, rhs: int): VMState =
  assert rhs == 1
  case lhs:
    of OutX: OutY
    of OutY: OutT
    of OutT: OutX

proc renderBoard(a: var Anim, board: seq[Tile], width: int) =
  for y in 0 .. width - 1:
    for x in 0 .. width - 1:
      
      let c =
        case board[y * width + x]:
          of Empty: Color(r: 0, g: 0, b: 0)
          of Wall: Color(r: 255, g: 255, b: 255)
          of Block: Color(r: 127, g: 127, b: 127)
          of Paddle: Color(r: 0, g: 255, b: 0)
          of Ball: Color(r: 255, g: 0, b: 0)
      setPixel(a, x, y, c)
  step(a)

func part1(program: Memory): int =
  var state: InterpreterResult
  var mem = program
  var ioState = OutX
  var buf: Point
  var pixels = newSeq[Tile](BOARDSIZ * BOARDSIZ)
  
  while not state.halt:
    let input = 0
    state = executeInstruction(input, state.nextPC, mem, state.base)

    if isSome(state.output):
      case ioState:
        of OutX:
          buf.x = state.output.get()
        of OutY:
          buf.y = state.output.get()
        of OutT:
          let t = state.output.get()
          pixels[buf.y * BOARDSIZ + buf.x] = Tile(t)
      ioState = ioState + 1


  for pixel in pixels:
    if pixel == Block: result += 1

func part2(program: Memory): int =
  var state: InterpreterResult
  var mem = program
  var ioState = OutX
  var buf, paddle, ball, ballDelta: Point
  var pixels = newSeq[Tile](BOARDSIZ * BOARDSIZ)
  var input = 0
  var a = newAnim("output.gif", BOARDSIZ, BOARDSIZ, scale = 4, colors = 8, fps = 60)
  defer: close(a)

  mem[0] = 2
  renderBoard(a, pixels, BOARDSIZ)

  while not state.halt:
    state = executeInstruction(input, state.nextPC, mem, state.base)

    if isSome(state.output):
      case ioState:
        of OutX:
          buf.x = state.output.get()
        of OutY:
          buf.y = state.output.get()
        of OutT:
          let o = state.output.get()
          if buf.x > -1:
            let t = Tile(o)
            pixels[buf.y * BOARDSIZ + buf.x] = t
            if t == Paddle:
              paddle.x = buf.x
              paddle.y = buf.y
              renderBoard(a, pixels, BOARDSIZ)
            elif t == Ball:
              ballDelta.x = buf.x - ball.x
              ballDelta.y = buf.y - ball.y
              ball.x = buf.x
              ball.y = buf.y
              renderBoard(a, pixels, BOARDSIZ)
          else:
            result = o
      ioState = ioState + 1

    input =
        if paddle.x < ball.x: 1
        elif ball.x < paddle.x: -1
        else: 0
  
  let blockCount = count(pixels, pix => pix == Block)
  assert blockCount == 0


when isMainModule:
  let program = readProgramFromPath(if paramCount() > 0: paramStr(1) else: "input.txt")
  echo(%*{"output1": $part1(program), "output2": $part2(program)})
