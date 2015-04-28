### global module,require ###

fraction = require './fractions'
parser = require './fractions-peg-parser'

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
  if last.arg == -1
    last.type = 'minus'
    last.arg = type: 'missing'
  else
    last.type = 'missing'
    delete last.arg

parse = (exp) ->
  try
    parser.parse exp
  catch error
    tryParseAsIncompleteExpression exp, error

tryParseAsIncompleteExpression = (exp, error) ->

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

  if numParensAdded is 0 and termsAdded is 0
    # mixed numbers
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
        mixed: (a, recur) -> f.mixed a[0].arg, a[1].arg, a[2].arg
        over: (a, recur) ->
          return f.div recur(a[0]), recur(a[1]) if a.length == 2
          # do pair-wise association,
          # e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) / (3 / 4) / 5"
          pairs = a.map(recur).reduce ((p, e) ->
            last = p[p.length - 1]
            if last.length < 2 then last.push e else p.push [e]
            p
          ), [[]]
          pairs
            .map (e) -> f.div e[0], e[1] or f.create(1)
            .reduce (p, e) -> f.div p, e
        exp: (e, recur) -> recur e
        post: (r) -> r
    catch e
      { error : e.message }

# render AST as AsciiMath
render = (ast, options) ->

  withResult = (s) ->
    result = calc(ast)
    return error: result.error if result.error?
    s += "=#{result}" if s != result.toString()
    mixed = result.toMixedString()
    s += "=#{mixed}" if mixed != result.toString()
    s

  interpret ast,
    error: (e) -> error: e
    missing: -> ''
    num: (n) -> "#{n}"
    add: (a, recur) -> a.map(recur).reduce (p, e) -> "#{p}+#{e}"
    minus: (e, recur) -> "-#{recur(e)}"
    mul: (a, recur) -> a.map(recur).reduce (p, e) -> "#{p}xx#{e}"
    mixed: (a, recur) -> "#{recur a[0]} #{recur a[1]}/#{recur a[2]}"
    over: (a, recur) ->
      # do pair-wise association,
      # e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) -: (3 / 4) -: 5"
      curr = ''
      op = -> curr = if curr == '/' then '-:' else '/'
      a.map(recur).reduce (p, e) -> p + op() + e
    exp: (e, recur) -> "(#{recur(e)})"
    post: (s) ->
      s = s.replace(/\+-/g, '-').replace(/--/g, '+')
      if options?.result then withResult s else s

class Parsed
  constructor: (@ast) ->
  calc: -> calc @ast
  render: (options) -> render @ast, options

module.exports =
  parse: (e) -> new Parsed parse e
