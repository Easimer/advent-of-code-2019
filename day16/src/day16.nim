import sequtils

iterator fftPattern(index: int, length: int): int =
  var i: range[0..3] = 0
  var c = 0
  while c < length:

    for _ in 0 .. index:
      case i:
        of 0: yield 0
        of 1: yield 1
        of 2: yield 0
        of 3: yield -1
      c += 1
      if c >= length: break
    i = (i + 1) mod 4

iterator fft(input: seq[int]): int =
  for i in 0 .. input.high():
    var o = 0
    var j = 0
    var skip = true
    for c in fftPattern(i + j, len(input) + 1):
      if not skip:
        o += c * input[j]
        #debugEcho((j, c, input[j]))
        #stderr.write($input[j] & '*' & $c & " + ")
        j += 1
      else:
        skip = false
    #let res = abs(o) mod 10
    #stderr.write(" = " & $res & '\n')
    yield abs(o) mod 10

func createIntList(s: string): seq[int] =
  for c in s:
    result.add(ord(c) - ord('0'))

iterator firstEight(input: seq[int]): int =
  let up = min(input.high(), 7)
  for i in 0 .. up:
    yield input[i]

func createString(s: seq[int]): string =
  for v in firstEight(s):
    result.add(chr(v + ord('0')))

proc hundredPhases(input: string): seq[int] =
  var l = createIntList(input)
  for i in 0 .. 99:
    l = toSeq(fft(l))
  l

proc hundredPhases(input: seq[int]): seq[int] =
  var l = input
  for i in 0 .. 99:
    echo("Phase " & $i)
    l = toSeq(fft(l))
  l

proc part1(s: string): string =
  createString(hundredPhases(s))

proc part2(s: string): string =
  var off = 0
  for i in 0 .. 7:
    off *= 10
    off += ord(s[i]) - ord('0')
  let rep = cycle(createIntList(s), 10000)
  let l = hundredPhases(rep)
  for i in off .. off + 7:
    result.add(chr(l[i] + ord('0')))

when isMainModule:
  let s = "59767332893712499303507927392492799842280949032647447943708128134759829623432979665638627748828769901459920331809324277257783559980682773005090812015194705678044494427656694450683470894204458322512685463108677297931475224644120088044241514984501801055776621459006306355191173838028818541852472766531691447716699929369254367590657434009446852446382913299030985023252085192396763168288943696868044543275244584834495762182333696287306000879305760028716584659188511036134905935090284404044065551054821920696749822628998776535580685208350672371545812292776910208462128008216282210434666822690603370151291219895209312686939242854295497457769408869210686246"
  echo(part1(s))
  echo(part2(s))

# 1 0 -1 1 0 -1 1 0 -1
