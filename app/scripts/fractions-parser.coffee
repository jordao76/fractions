### global module,require ###

fraction = require './fractions'
parser = require './fractions-peg-parser'

parse = (exp) ->
  try
    parser.parse exp
  catch error
    tryParseAsIncompleteExpression exp, error

tryParseAsIncompleteExpression = (exp, error) ->

  addMissingTerm = (ast) ->
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

  termsAdded = 0

  # if it ends with a non-number (except a closing parenthesis or a space),
  # see if adding a number works
  if newExp.match /[^\d\)\s]+$/
    newExp += '1'
    ++termsAdded

  # balance close parenthesis
  openParens = (newExp.match(/\(/g) or []).length
  closeParens = (newExp.match(/\)/g) or []).length
  numParensAdded = openParens - closeParens
  newExp += ')' while openParens-- > closeParens

    # mixed numbers
  if numParensAdded is 0 and termsAdded is 0
    # if it ends with a number, see if adding a denominator works
    if newExp.match /\d$/
      newExp += '/1'
      ++termsAdded
    # if it ends with a space, see if adding a fraction works
    if newExp.match /\s$/
      newExp += '1/1'
      termsAdded += 2

  if exp != newExp
    try
      ast = parser.parse newExp
      ast.numParensAdded = numParensAdded if numParensAdded > 0
      while termsAdded-- > 0
        ast.incomplete = true
        addMissingTerm ast
      return ast

  # couldn't "fix" the expression
  { error: error.message }

interpret = (ast, interpreter) ->
  return null if !ast
  return interpreter.error ast.error if ast.error?
  recur = (o) -> interpreter[o.type] o.arg, recur
  interpreter.post recur ast

over = (a, recur, outer, inner) ->
  # do pair-wise association,
  # e.g. "1 / 2 / 3 / 4 / 5" => "(1 `inner` 2) `outer` (3 `inner` 4) `outer` 5"
  return inner recur(a[0]), recur(a[1]) if a.length is 2
  pairs = a.map(recur).reduce ((p, e) ->
    last = p[p.length - 1]
    if last.length < 2 then last.push e else p.push [e]
    p
  ), [[]]
  pairs
    .map (e) -> inner e[0], e[1]
    .reduce (p, e) -> outer p, e

# calculate AST result
calc = (ast) ->
  if ast.incomplete?
    { error: 'incomplete expression' }
  else
    try
      f = fraction
      interpret ast,
        error: -> ''
        num: (n) -> f.create n
        add: (a, recur) -> a.map(recur).reduce (p, e) -> f.add p, e
        minus: (e, recur) -> f.minus recur e
        mul: (a, recur) -> a.map(recur).reduce (p, e) -> f.mul p, e
        div: (e, recur) -> f.reciprocal recur e
        mixed: (a, recur) ->
          [w, x, y] = a.map (e) -> (recur e).n
          f.mixed w, x, y
        over: (a, recur) ->
          div = (l, r) -> f.div l, r or f.create(1)
          over a, recur, div, div
        exp: (e, recur) -> recur e
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

  dimAddedParens = (s) ->
    if ast.numParensAdded > 0
      n = ast.numParensAdded
      l = '\\Big'.length
      i = s.length
      while n-- > 0
        i = s.lastIndexOf '\\Big', i - 1
        s = [s[0...i]..., '\\color{gray}{\\Big)}', s[i+l+1...]].join ''
    s

  interpret ast,
    error: (e) -> error: e
    missing: -> ''
    num: (n) -> "#{n}"
    add: (a, recur) -> a.map(recur).reduce (p, e) -> "#{p} + #{e}"
    minus: (e, recur) -> "-#{recur(e)}"
    mul: (a, recur) -> a.map(recur).reduce (p, e) -> "#{p} \\times #{e}"
    div: (e, recur) -> "\\div #{recur e}"
    mixed: (a, recur) ->
      [w, x, y] = a.map recur
      "#{w} \\frac{#{x or '\\Box'}}{#{y or '\\Box'}}"
    over: (a, recur) ->
      over a, recur,
        (l, r) -> "#{l} \\div #{r}",
        (l, r) -> if r? then "\\frac{#{l}}{#{r or '\\Box'}}" else l
    exp: (e, recur) -> "\\Big( #{recur(e)} \\Big)"
    post: (s) ->
      s = s
        .replace /\\times \\div/g, '\\div'
        .replace /\+(\s)?-/g, '-$1'
        .replace /-(\s)?-/g, '+$1'
        .replace /\s{2,}/g, ' '
      if options?.result
        withResult s
      else
        dimAddedParens s

class Parsed
  constructor: (@ast) ->
  calc: -> calc @ast
  render: (options) -> render @ast, options

module.exports =
  parse: (e) -> new Parsed parse e
