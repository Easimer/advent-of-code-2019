import algorithm
import aocutils
import json
import os
import sequtils
import sugar

const IMG_WIDTH = 25
const IMG_HEIGHT = 6

type
  Layer = array[IMG_WIDTH * IMG_HEIGHT, uint8]
  Image = seq[Layer]

proc readImage(path: string): Image =
  var f = open(path)
  defer: f.close()
  while not endOfFile(f):
    var layerIdx = 0
    var currentLayer: Layer
    while not endOfFile(f) and layerIdx < IMG_WIDTH * IMG_HEIGHT:
      let ch = f.readChar()
      if ch != '\n':
        let pix = uint8(chr(ord(ch) - ord('0')))
        currentLayer[layerIdx] = pix
        layerIdx += 1
    result.add(currentLayer)

func countPixelValue(lay: Layer, pixVal: uint8): int = lay.count(x => x == pixVal)
func numberOfZeroes(img: Image): seq[int] = img.map(l => l.countPixelValue(0))

func part1(img: Image): int =
  let min = minp(numberOfZeroes(img))
  countPixelValue(img[min], 1) * countPixelValue(img[min], 2)

func flatten(img: Image): Layer =
  result.fill(2)
  for layer in img:
    for offset in 0 .. layer.high():
      if result[offset] == 2:
        result[offset] = layer[offset]

func part2(img: Image): string =
  let F = flatten(img)
  for y in 0 .. IMG_HEIGHT - 1:
    for x in 0 .. IMG_WIDTH - 1:
      result.add:
        case F[y * IMG_WIDTH + x]:
          of 0: ' '
          of 1: '#'
          of 2: ' '
          else: '?'
    result.add('\n')

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  let img = readImage(inputPath)
  
  echo(%*{"output1": $part1(img), "output2": part2(img)})
