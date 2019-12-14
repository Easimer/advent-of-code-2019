import algorithm
#import aocutils
import os
import tables
import strutils
import sequtils
import sugar
import hashes

const ORE = hash("ORE")
const FUEL = hash("FUEL")

type
  Name = Hash
  Ingredient = tuple[name: Name, quantity: int64]
  Recipe = object
    producedCount: int64
    ingredients: seq[Ingredient]
  Recipes = Table[Name, Recipe]
  Storage = Table[Name, int64]

func newIngredient(s: string): Ingredient =
  let c = s.split(' ')
  result.quantity = parseInt(c[0])
  result.name = hash(c[1])

proc loadRecipes(path: string): Recipes =
  var f = open(path)
  defer: close(f)
  for line in f.lines():
    let sides = line.split("=>").map(s => s.strip(trailing = true))
    let ingredients =
      sides[0].split(',')
      .map(s => newIngredient(s.strip(trailing = true)))
    let produce = newIngredient(sides[1])
    let recipe = Recipe(producedCount: produce.quantity, ingredients: ingredients)
    result.add(produce.name, recipe)

func manufacture(recipes: Recipes, result: var Storage, qty: int64, name: Name) =
  let R = recipes[name]
  let makeRecipeCount =
      if qty mod R.producedCount != 0:
        (1 + qty div R.producedCount)
      else:
        qty div R.producedCount
  for ingr in R.ingredients:
    if ingr.name == ORE:
      result[ORE] -= ingr.quantity * makeRecipeCount
    else:
      let leftover =
        if ingr.name in result:
          result[ingr.name]
        else:
          0
      let needToManufactureIngredient =
          if leftover < ingr.quantity * makeRecipeCount:
            ingr.quantity * makeRecipeCount - leftover
          else:
            0
      if needToManufactureIngredient > 0:
        manufacture(recipes, result, needToManufactureIngredient, ingr.name)
      result[ingr.name] -= ingr.quantity * makeRecipeCount
      assert result[ingr.name] >= 0
  let C = result.getOrDefault(name, 0) + makeRecipeCount * R.producedCount
  result[name] = C

func part1(recipes: Recipes): int64 =
  var has: Storage
  has[ORE] = 0
  manufacture(recipes, has, 1, FUEL)
  -has[ORE]

func part2(recipes: Recipes): int64 =
  var S: Storage
  var guess = 1000000000000 div 2
  var sign = false
  var step = 100000000

  while step > 0:
    for R, v in recipes:
      S[R] = 0
    S[ORE] = 1000000000000

    manufacture(recipes, S, guess, FUEL)

    if S[ORE] < 0:
      if sign != false:
        step = step div 10
        sign = false
      guess -= step
    elif S[ORE] > 0:
      if sign != true:
        step = step div 10
        sign = true
      guess += step
  guess
when isMainModule:
  let recipes = loadRecipes(if paramCount() > 0: paramStr(1) else: "input.txt")
  echo(part1(recipes))
  echo(part2(recipes))
