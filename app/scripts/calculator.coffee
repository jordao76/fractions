### global module,require ###

Parser = require './fractions-parser'

# Incomplete :: { parens::Num, numbers::Num, symbols::Num }
# OutputInfo :: { decimal::Num?, incomplete::Incomplete? }

# (options::{
#   output: (tex::Str, info::OutputInfo?) -> None
#   onError: (message::Str) -> None
# }) ->
# {
#   canInput: (key::Str) -> Bool
#   input: (key::Str) -> None
#   uninput: (None) -> None
# }
calculator = (options) ->

  {output, onError} = options

  $input =
    curr: ''
    isRes: false
    val: (v, r = false) ->
      if v?
        @curr = v
        @isRes = r
      @curr
    hasResult: ->
      @isRes

  # canInput :: (key::Str) -> Bool
  canInput = (key) ->
    return true if key is 'C' # "clear"
    if key is '='
      exp = $input.val()
      parsed = Parser.parse exp
      !parsed.ast.error and !parsed.ast.incomplete?.numbers
    else
      exp = $input.val() + key
      return true if !exp
      parsed = Parser.parse exp
      !parsed.ast.error

  # input :: (key::Str) -> None
  input = (key) ->
    $input.val(key = '') if key is 'C' # "clear"
    if key is '='
      calc()
    else
      if $input.hasResult() and key.match /\d/
        $input.val key
      else
        $input.val $input.val() + key
      process()

  # uninput :: (None) -> None
  uninput = ->
    return clear() if $input.hasResult()
    value = $input.val()
    $input.val value[0...-1] # trim last element
    process()

  clear = -> output ''

  process = ->
    exp = $input.val()
    return clear() if !exp.trim()
    parsed = Parser.parse exp
    if parsed.ast.error?
      uninput()
    else
      info = incomplete: parsed.ast.incomplete if parsed.ast.incomplete?
      output parsed.render(), info

  calc = ->
    exp = $input.val()
    return clear() if !exp.trim()
    parsed = Parser.parse exp
    return if parsed.ast.incomplete?.numbers > 0
    rendered = parsed.render result: yes
    if !rendered.error
      result = parsed.calc()
      output rendered, { decimal: result.toFloat() }
      # move the result to the input
      $input.val result.toString(), true
    else
      onError rendered.error

  clear()

  {canInput, input, uninput}

module.exports = calculator
