### global MathJax,jQuery,require ###
# coffeelint: disable=max_line_length

$ = jQuery
Parser = require './fractions-parser'

# splices a string
splice = (str, index, count, add = '') ->
  str.slice(0, index) + add + str.slice(index + count)

# adds a value to a textbox DOM element, respecting any current selections and the cursor position
addValue = (e, add) ->
  e.value = splice e.value, e.selectionStart, e.selectionEnd - e.selectionStart, add

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
    output parsed.render result: yes
    result = parsed.calc()
    if !result.error
      $decimal.text result.toFloat()
      $input.val last = result.toString()
    $input.focus()

  $input
    .keyup (e) -> calc() if e.which == 13 # <ENTER>
    .on 'input propertychange', process
    .focus()

  $buttons = $ '.btn'
  $buttons.click (e) ->
    key = $(this).text()
    switch key
      when 'C' then $input.val key = '' # C means "clear"
      when 'x / y', '÷' then key = '/'
      when '×' then key = '*'
    if key is '=' then calc()
    else
      addValue $input.get(0), key
      process()
    $input.focus()
