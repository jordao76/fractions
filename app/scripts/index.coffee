### global MathJax,jQuery,require ###

$ = jQuery
Parser = require './fractions-parser'

$ ->
  $input = $ '#input'
  $output = $ '#output'
  $buffer = $ '#buffer'
  $parsed = $ '#parsed'
  $decimal = $ '#decimal'

  output = (s) ->
    MathJax.Hub.Queue ->
      $parsed.text s
      $buffer.text "`#{s}`"
      MathJax.Hub.Typeset $buffer.get(), ->
        $output.html $buffer.html() if $parsed.text() == s

  last = null

  butFirstClear = ->
    $decimal.text ''
    output ''
    last = ''

  process = ->
    exp = $input.val()
    return butFirstClear() if !exp.trim()
    if exp != last
      parsed = Parser.parse exp
      output parsed.render()
      $decimal.text ''
      last = exp

  calc = ->
    exp = $input.val()
    return butFirstClear() if !exp.trim()
    parsed = Parser.parse exp
    result = parsed.calc()
    output parsed.render result
    if !result.error
      $decimal.text result.toFloat()
      $input.val last = result.toString()

  $input
    .keyup (e) -> calc() if e.which == 13 # <ENTER>
    .on 'input propertychange', process
    .focus()
