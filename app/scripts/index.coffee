### global MathJax,jQuery,require ###

$ = jQuery

$ ->
  $calculator = $ '#calculator'
  $output = $ '#output'
  $decimal = $ '#decimal'
  $buffer = $ '#buffer' # buffer for MathJax
  $parsed = $ '#parsed' # for debugging

  output = (tex, decimal = '') ->
    $decimal.text decimal
    MathJax.Hub.Queue ->
      $parsed.text tex
      $buffer.text "$$#{tex}$$"
      MathJax.Hub.Typeset $buffer.get(), ->
        $output.html $buffer.html() if $parsed.text() is tex
        # adjust mathjax generated styles
        $ '.MathJax_Display'
          .css 'margin', '0'
          .css 'text-align', 'right'

  calculator = (require './calculator')
    output: output
    onError: (s) -> alert s

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
        calculator.input key
        toggleButtons()
    .keydown (e) ->
      if e.which is 8 # <BACKSPACE>
        calculator.uninput()
        toggleButtons()
        e.preventDefault() # don't allow back navigation with <BACKSPACE>

  $buttons.click ->
    calculator.input getKey $(this)
    toggleButtons()

  toggleButtons = ->
    $buttons.each ->
      if calculator.canInput getKey $(this)
        this.removeAttribute 'disabled'
      else
        this.setAttribute 'disabled', true

  toggleButtons()
  $calculator.focus()
