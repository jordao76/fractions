### global module,require ###

fraction = require './fractions'
parser = require './fractions-peg-parser'

parse = (exp) ->
  try
    parser.parse exp
  catch error
    tryParseAsIncompleteExpression exp, error

tryParseAsIncompleteExpression = (exp, error) ->

  replaceNumberWithMissing = (ast) ->
    recur = (o) ->
      if o.arg
        if o.arg.length
          if o.arg[o.arg.length - 1].type is 'missing'
            return recur o.arg[o.arg.length - 2]
          else
            return recur o.arg[o.arg.length - 1]
        else if o.type isnt 'num'
          return recur o.arg
      o
    last = recur ast
    if last.arg is -1
      last.type = 'minus'
      last.arg = type: 'missing'
    else
      last.type = 'missing'
      delete last.arg

  # try to create a valid expression
  newExp = exp

  symbolsAdded = 0
  numbersAdded = 0

  # if it ends with a non-number (except a closing parenthesis or a space),
  # see if adding a number works
  if exp.match /[^\d\)\s]+$/
    newExp += '1'
    ++numbersAdded

  # if it ends with a number following a space,
  # see if adding a denominator works
  else if exp.match /\s\d+$/
    newExp += '/1'
    ++symbolsAdded
    ++numbersAdded

  # if it ends with a space, see if adding a fraction works
  else if exp.match /\s$/
    newExp += '1/1'
    ++symbolsAdded
    numbersAdded += 2

  # balance close parenthesis
  openParens = (exp.match(/\(/g) or []).length
  closeParens = (exp.match(/\)/g) or []).length
  parensAdded = openParens - closeParens
  newExp += ')' while openParens-- > closeParens

  if exp isnt newExp
    try
      ast = parser.parse newExp
      if parensAdded > 0 or symbolsAdded > 0 or numbersAdded > 0
        ast.incomplete = {}
        ast.incomplete.parens  = parensAdded  if parensAdded  > 0 # )s added
        ast.incomplete.symbols = symbolsAdded if symbolsAdded > 0 # /s added
        ast.incomplete.numbers = numbersAdded if numbersAdded > 0 # 1s added
        replaceNumberWithMissing ast while numbersAdded-- > 0
      return ast

  # couldn't "fix" the expression
  { error: error.message }

interpret = (ast, interpreter) ->
  return null if !ast
  return interpreter.error ast.error if ast.error?
  map = (o, f) -> if o.map? then o.map f else f o
  recur = (o) ->
    if o.type is 'num' or o.type is 'missing' # leaf nodes, don't recur
      interpreter[o.type] o.arg
    else
      interpreter[o.type] (map o.arg, recur)
  interpreter.post recur ast

# calculate AST result
calc = (ast) ->
  if ast.incomplete?.numbers
    { error: 'incomplete expression' }
  else
    try
      f = fraction
      interpret ast,
        error: -> ''
        num: (n) -> f.create n
        add: (a) -> a.reduce (p, e) -> f.add p, e
        minus: (e) -> f.minus e
        mul: (a) -> a.reduce (p, e) -> f.mul p, e
        div: (e) -> f.reciprocal e
        mixed: (a) ->
          [w, n, d] = a.map (e) -> e.n
          f.mixed w, n, d
        over: (a) ->
          [n, d] = a.map (e) -> e.n
          f.create n, d
        exp: (e) -> e
        post: (r) -> r
    catch e
      { error : e.message }

# render AST as TeX
render = (ast, options) ->

  withResult = (s) ->
    result = calc(ast)
    return error: result.error if result.error?
    r = render parse result.toString()
    m = render parse result.toMixedString()
    ret = s
    ret += " = #{r}" if s isnt r
    ret += " = #{m}" if m isnt r and m isnt s
    ret

  interpret ast,
    error: (e) -> error: e
    missing: -> ''
    num: (n) -> "#{n}"
    add: (a) -> a.reduce (p, e) -> "#{p} + #{e}"
    minus: (e) -> "-#{e}"
    mul: (a) -> a.reduce (p, e) -> "#{p} \\times #{e}"
    div: (e) -> "\\div #{e}"
    mixed: (a) ->
      [w, n, d] = a
      "#{w} \\frac{#{n or '\\Box'}}{#{d or '\\Box'}}"
    over: (a) ->
      [n, d] = a
      if d? then "\\frac{#{n}}{#{d or '\\Box'}}" else n
    exp: (e) -> "\\left( #{e} \\right)"
    post: (s) ->
      s = s
        .replace /\\times \\div/g, '\\div'
        .replace /\+(\s)?-/g, '-$1'
        .replace /-(\s)?-/g, '+$1'
        .replace /\s{2,}/g, ' '
      if options?.result
        withResult s
      else
        s

class Parsed
  constructor: (@ast) ->
  calc: -> calc @ast
  render: (options) -> render @ast, options

module.exports =
  parse: (e) -> new Parsed parse e
