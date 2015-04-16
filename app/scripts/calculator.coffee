### global module,require ###

Parser = require './fractions-parser'

# (options::{
#   output: (asciiMath::Str, decimal::Num?) -> None
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
    isRes: false
    curr: ''
    val: (v) ->
      @curr = v if v?
      @curr
    hasResult: (r = false) ->
      [old, @isRes] = [@isRes, r]
      old

  # canInput :: (key::Str) -> Bool
  canInput = (key) ->
    return true if key is 'C' # "clear"
    if key is '='
      exp = $input.val()
      parsed = Parser.parse exp
      !parsed.ast.error and !parsed.ast.incomplete
    else
      exp = $input.val() + key
      return true if !exp.trim()
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
      output parsed.render()

  calc = ->
    exp = $input.val()
    return clear() if !exp.trim()
    parsed = Parser.parse exp
    return if parsed.ast.incomplete
    rendered = parsed.render result: yes
    if !rendered.error
      result = parsed.calc()
      output rendered, result.toFloat()
      # move the result to the input
      $input.val result.toString()
      $input.hasResult true
    else
      onError rendered.error

  clear()

  { canInput: canInput, input: input, uninput: uninput }

module.exports = calculator
