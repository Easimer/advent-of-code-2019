import algorithm
#import aocutils
import os
import tables
import strutils
import sequtils
import sugar

type
  Ingredient = tuple[name: string, quantity: int]
  Recipe = object
    producedCount: int
    ingredients: seq[Ingredient]
  Recipes = Table[string, Recipe]
  Storage = Table[string, int]

func newIngredient(s: string): Ingredient =
  let c = s.split(' ')
  result.quantity = parseInt(c[0])
  result.name = c[1]

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

func manufacture(recipes: Recipes, storage: Storage, qty: int, name: string): Storage =
  let R = recipes[name]
  debugEcho("Want " & $qty & " pieces of " & name)
  let makeRecipeCount =
      if qty mod R.producedCount != 0:
        (1 + qty div R.producedCount)
      else:
        qty div R.producedCount
  debugEcho("Need to make recipe " & $makeRecipeCount & " times to make " & $qty & " pieces of " & name)
  result = storage
  for ingr in R.ingredients:
    if ingr.name == "ORE":
      result["ORE"] -= ingr.quantity * makeRecipeCount
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
        result = manufacture(recipes, result, needToManufactureIngredient, ingr.name)
      result[ingr.name] -= ingr.quantity * makeRecipeCount
      assert result[ingr.name] >= 0
  if name in result:
    result[name] += makeRecipeCount * R.producedCount
  else:
    result[name] = makeRecipeCount * R.producedCount

proc part1(recipes: Recipes): int =
  var has: Storage
  has["ORE"] = 0
  has = manufacture(recipes, has, 1, "FUEL")
  debugEcho(has)
  -has["ORE"]

proc part2(recipes: Recipes): int = 0

when isMainModule:
  let recipes = loadRecipes(if paramCount() > 0: paramStr(1) else: "input.txt")
  echo(part1(recipes))
