import strutils

proc calculateMass(M: int): int =
  let F = (M div 3) - 2
  if F > 0:
    result = F + calculateMass(F)
  else:
    result = 0

template `->`(lhs: untyped, rhs: untyped): untyped =
  calculateMass(lhs) == rhs

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
      sum += calculateMass(parseInt(line))

    echo(sum)
  else:
    echo("IO error")

