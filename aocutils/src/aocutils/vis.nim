import gifwriter

type
  Anim* = object
    gif: Gif
    buffer: seq[Color]
    width, height, mag: int


proc newAnim*(path: string, width, height: int, scale = 1, colors = 256, fps = 24.0f): Anim =
  result.buffer = newSeq[Color](scale * scale * width * height)
  result.gif = newGif(path, scale * width, scale * height, fps, colors)
  result.mag = scale
  result.width = width
  result.height = height

proc close*(a: Anim) =
  close(a.gif)

func setPixel*(a: var Anim, x, y: int, c: Color) =
  for yoff in 0 .. a.mag - 1:
    let rowOffset = (y * a.mag + yoff) * a.mag * a.width
    for xoff in 0 .. a.mag - 1:
      a.buffer[rowOffset + a.mag * x + xoff] = c

func step*(a: var Anim) =
  a.gif.write(a.buffer)

func `[]=`*(a: var Anim, pos: (int, int), c: Color) = setPixel(a, pos[0], pos[1], c)