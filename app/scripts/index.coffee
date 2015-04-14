### global MathJax,jQuery,require ###
# coffeelint: disable=max_line_length

$ = jQuery
Parser = require './fractions-parser'

$ ->
  $output = $ '#output'
  $input = $ '<input type=text/>' # buffer for input
  $buffer = $ '#buffer' # buffer for MathJax
  $parsed = $ '#parsed' # for debugging
  $decimal = $ '#decimal' # for debugging
  $calculator = $ '#calculator'

  input = (key) ->
    $input.val(key = '') if key is 'C' # "clear"
    if key is '='
      calc()
    else
      $input.val $input.val() + key
      process()

  checkInput = (key) ->
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

  uninput = ->
    value = $input.val()
    $input.val value[0...-1] # trim last element
    process()

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
      if parsed.ast.error?
        uninput()
      else
        output parsed.render()[0]
        $decimal.text ''
        last = exp

  calc = ->
    exp = $input.val()
    return butFirstClear() if !exp.trim()
    parsed = Parser.parse exp
    return if parsed.ast.incomplete
    [rendered, result] = parsed.render result: yes
    if !result.error
      output rendered
      $decimal.text result.toFloat()
      $input.val last = result.toString()
    else
      alert result.error

  getKey = ($b) -> $b.data('symbol') or $b.text()

  $buttons = $ '.btn'
  charCodes = $buttons.map -> (getKey $(this)).charCodeAt 0

  $calculator
    .keypress (e) ->
      key =
        if e.which is 13 # <ENTER>
          '='
        else
          (String.fromCharCode e.which).toUpperCase()
      keyCode = key.charCodeAt 0
      if (charCodes.index keyCode) isnt -1
        input key
        toggleButtons()
    .keydown (e) ->
      if e.which is 8 # <BACKSPACE>
        uninput()
        toggleButtons()
        e.preventDefault() # don't allow back navigation

  $buttons.click ->
    input getKey $(this)
    toggleButtons()

  toggleButtons = ->
    $buttons.each ->
      if checkInput getKey $(this)
        this.removeAttribute 'disabled'
      else
        this.setAttribute 'disabled', true

  toggleButtons()
  $calculator.focus()
