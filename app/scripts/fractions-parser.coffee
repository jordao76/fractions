### global module,require ###

module.exports = ((fraction, parser) ->
  'use strict'

  addMissingType = (ast) ->
    # replace last number with a 'missing' type

    recur = (o) ->
      if o.arg
        if o.arg.length
          return recur(o.arg[o.arg.length - 1])
        else if o.type != 'num'
          return recur(o.arg)
      o

    last = recur(ast)
    if last.arg == -1
      last.type = 'minus'
      last.arg = type: 'missing'
    else
      last.type = 'missing'
      delete last.arg
    return

  parse = (exp, aNumberWasAdded) ->
    try
      ast = parser.parse(exp)
      if aNumberWasAdded
        addMissingType ast
      return ast
    catch error
      return tryParseExpressionWithError(exp, error)
    return

  tryParseExpressionWithError = (exp, error) ->
    # try to create a valid expression
    newExp = exp
    aNumberWasAdded = false
    # if it ends with a non-number, see if adding a number works
    if newExp.match(/\D+$/)
      newExp += '1'
      aNumberWasAdded = true
    # balance close parenthesis
    openParens = (newExp.match(/\(/g) or []).length
    closeParens = (newExp.match(/\)/g) or []).length
    while openParens-- > closeParens
      newExp += ')'
    if exp != newExp
      return parse(newExp, aNumberWasAdded)
    # couldn't "fix" the expression
    { error: error.message }

  interpret = (ast, interpreter) ->
    if !ast
      return interpreter.nil()
    if ast.error
      return interpreter.error(ast.error)

    recur = (o) ->
      interpreter[o.type] o.arg, recur

    interpreter.post recur(ast)

  # calculate AST result

  calc = (ast) ->
    try
      f = fraction
      return interpret(ast,
        missing: ->
          throw new Error('incomplete expression')
          return
        nil: ->
          ''
        error: ->
          ''
        num: (n) ->
          f.create n
        add: (a, recur) ->
          a.map(recur).reduce (p, e) ->
            f.add p, e
        minus: (e, recur) ->
          f.minus recur(e)
        mul: (a, recur) ->
          a.map(recur).reduce (p, e) ->
            f.mul p, e
        over: (a, recur) ->
          if a.length == 2
            return f.div(recur(a[0]), recur(a[1]))
          # do pair-wise association,
          # e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) / (3 / 4) / 5"
          pairs = a.map(recur).reduce(((p, e) ->
            last = p[p.length - 1]
            if last.length < 2
              last.push e
            else
              p.push [ e ]
            p
          ), [ [] ])
          pairs.map((e) ->
            f.div e[0], e[1] or f.create(1)
          ).reduce (p, e) ->
            f.div p, e
        exp: (e, recur) ->
          recur e
        post: (r) ->
          r
      )
    catch e
      return { error: e.message }
    return

  # render AST as AsciiMath
  placeholder = ''

  render = (ast, result) ->
    rendered = interpret(ast,
      missing: ->
        placeholder
      nil: ->
        ''
      error: ->
        'bb"Error"'
      num: (n) ->
        '' + n
      add: (a, recur) ->
        a.map(recur).reduce (p, e) ->
          p + '+' + e
      minus: (e, recur) ->
        '-' + recur(e)
      mul: (a, recur) ->
        a.map(recur).reduce (p, e) ->
          p + 'xx' + e
      over: (a, recur) ->
        # do pair-wise association,
        # e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) -: (3 / 4) -: 5"
        curr = ''

        op = ->
          curr = if curr == '/' then '-:' else '/'

        a.map(recur).reduce (p, e) ->
          p + op() + e
      exp: (e, recur) ->
        '(' + recur(e) + ')'
      post: (s) ->
        s.replace(/\+-/g, '-').replace /--/g, '+'
    )
    if result
      if result.error
        rendered += ' = bb"' + result.error + '"'
      else
        rendered += ' = ' + result
    rendered

  Parsed = (ast) ->
    @ast = ast
    return

  Parsed.prototype =
    calc: ->
      calc @ast
    render: (result) ->
      render @ast, result
  {
    parse: (e) ->
      new Parsed(parse(e))
    placeholder: placeholder
  }
)(require('./fractions'), require('./fractions-peg-parser'))
