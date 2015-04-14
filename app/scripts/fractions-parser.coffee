### global module,require ###

fraction = require './fractions'
parser = require './fractions-peg-parser'

addMissingType = (ast) ->
  # replace last number with a 'missing' type

  recur = (o) ->
    if o.arg
      if o.arg.length
        return recur(o.arg[o.arg.length - 1])
      else if o.type != 'num'
        return recur(o.arg)
    o

  last = recur ast
  if last.arg == -1
    last.type = 'minus'
    last.arg = type: 'missing'
  else
    last.type = 'missing'
    delete last.arg

parse = (exp, aNumberWasAdded) ->
  exp = exp.trim()
  try
    ast = parser.parse(exp)
    addMissingType ast if aNumberWasAdded
    ast
  catch error
    tryParseExpressionWithError(exp, error)

tryParseExpressionWithError = (exp, error) ->

  # try to create a valid expression
  newExp = exp
  aNumberWasAdded = false

  # if it ends with a non-number, see if adding a number works
  if newExp.match /\D+$/
    newExp += '1'
    aNumberWasAdded = true

  # balance close parenthesis
  openParens = (newExp.match(/\(/g) or []).length
  closeParens = (newExp.match(/\)/g) or []).length
  newExp += ')' while openParens-- > closeParens

  return parse newExp, aNumberWasAdded if exp != newExp

  # couldn't "fix" the expression
  { error: error.message }

interpret = (ast, interpreter) ->
  return interpreter.nil() if !ast?
  return interpreter.error ast.error if ast.error?
  recur = (o) -> interpreter[o.type] o.arg, recur
  interpreter.post recur ast

# calculate AST result
calc = (ast) ->
  try
    f = fraction
    interpret ast,
      missing: -> throw new Error('incomplete expression')
      nil: -> ''
      error: -> ''
      num: (n) -> f.create n
      add: (a, recur) -> a.map(recur).reduce (p, e) -> f.add p, e
      minus: (e, recur) -> f.minus recur e
      mul: (a, recur) -> a.map(recur).reduce (p, e) -> f.mul p, e
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
    { error: e.message }

# render AST as AsciiMath
placeholder = ''
render = (ast, options) ->
  interpret ast,
    missing: -> placeholder
    nil: -> ''
    error: (e) -> ['', error: e]
    num: (n) -> "#{n}"
    add: (a, recur) -> a.map(recur).reduce (p, e) -> "#{p}+#{e}"
    minus: (e, recur) -> "-#{recur(e)}"
    mul: (a, recur) -> a.map(recur).reduce (p, e) -> "#{p}xx#{e}"
    over: (a, recur) ->
      # do pair-wise association,
      # e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) -: (3 / 4) -: 5"
      curr = ''
      op = -> curr = if curr == '/' then '-:' else '/'
      a.map(recur).reduce (p, e) -> p + op() + e
    exp: (e, recur) -> "(#{recur(e)})"
    post: (s) ->
      s = s.replace(/\+-/g, '-').replace(/--/g, '+')
      if options?.result
        result = calc(ast)
        if !result.error
          s += "=#{result}" if s != result.toString()
          mixed = result.toMixedString()
          s += "=#{mixed}" if mixed != result.toString()
      [s, result]

class Parsed
  constructor: (@ast) ->
  calc: -> calc @ast
  render: (options) -> render @ast, options

module.exports = {
  parse: (e) -> new Parsed parse e
  placeholder: placeholder
}
