import strutils

proc calculateFuel(M: int): int =
  result = 0
  var F = (M div 3) - 2
  while F > 0:
    result += F
    F = (F div 3) - 2

template `->`(lhs: untyped, rhs: untyped): untyped =
  calculateFuel(lhs) == rhs

when isMainModule:
  var
    f: File
    line: string
    sum: int = 0

  doAssert(14 -> 2)
  doAssert(1969 -> 966)
  doAssert(100756 -> 50346)

  if open(f, "day1.txt"):
    while f.readLine(line):
      sum += calculateFuel(parseInt(line))

    echo(sum)
  else:
    echo("IO error")

