import aocutils
import unittest
import sugar

suite "aocutils query functions":
  test "minp":
    let v = @[4, 3, 2, 6]
    check(minp(v) == 2)
  test "maxp":
    let v = @[4, 3, 2, 6]
    check(maxp(v) == 3)
  test "count":
    let v = @[4, 3, 2, 6]
    check(count(v, x => x mod 2 == 0) == 3)
    check(count(v, x => x mod 2 == 1) == 1)
  test "count zero array":
    let v: seq[int] = @[]
    check(count(v, x => true) == 0)
  test "all":
    let v0 = @[4, 3, 2, 6]
    let v1 = @[4, 0, 2, 6]
    check(all(v0, x => x mod 2 == 0) == true)
    check(all(v1, x => x mod 2 == 0) == false)
  test "all empty array":
    let v: seq[int] = @[]
    check(all(v, x => true) == true)
  test "any":
    let v0 = @[4, 3, 2, 6]
    let v1 = @[4, 0, 2, 6]
    check(any(v0, x => x mod 2 == 1) == true)
    check(any(v0, x => x mod 2 == 1) == false)
  test "any empty array":
    let v: seq[int] = @[]
    check(any(v, x => x == 0) == false)

  test "contains":
    let v = @[0, 1, 2, 3]
    check(contains(v, 0) == true)
    check(contains(v, 4) == false)

  test "min":
    let v = @[4, 3, 2, 6]
    check(min(v) == 2)

  test "max":
    let v = @[4, 3, 2, 6]
    check(max(v) == 6)

  test "where":
    let v = @[1, 7, 3, 9, 2]

    check(where(v, x => x mod 2 == 0) == @[2])
    check(where(v, x => x mod 2 == 1) == @[1, 7, 3, 9])

