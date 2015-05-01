### global MathJax,jQuery,require ###

$ = jQuery

$ ->
  $calculator = $ '#calculator'
  $output = $ '#output'
  $decimal = $ '#decimal'
  $buffer = $ '#buffer' # buffer for MathJax
  $parsed = $ '#parsed' # for debugging

  adjustCss = ->
    # adjust mathjax generated styles
    $ '.MathJax_Display'
      .css 'margin', '0'
      .css 'text-align', 'right'

  adjustParens = (n) ->
    return if n is 0
    # gray out added closing parenthesis
    parens = $ '#output .MathJax_Display span'
      .filter (i, s) -> $(s).text() is ')'
    $ parens[-n..-1]
      .addClass 'dimmed'

  adjustPlaceholders = () ->
    $ '#output .MathJax_Display span'
      .filter (i, s) -> $(s).text() is '□' # in TeX this is \Box
      .addClass 'dimmed'

  adjustFraction = () ->
    fraction = $ '#output .MathJax_Display span'
      .filter (i, s) -> $(s).text() is '□' # in TeX this is \Box
      .last()
      .parent()
      .parent()
      .addClass 'dimmed'
    fraction
      .children "span"
      .filter (i, s) -> $(s).text().match /\d+/
      .css 'color', '#333' # this is normal MathJax's color

  output = (tex, info) ->
    $decimal.text if info?.decimal? then info.decimal else ''
    MathJax.Hub.Queue ->
      $parsed.text tex
      $buffer.text "$$#{tex}$$"
      MathJax.Hub.Typeset $buffer.get(), ->
        $output.html $buffer.html() if $parsed.text() is tex
        adjustCss()
        adjustParens info?.incomplete?.parens or 0
        if info?.incomplete?.symbols > 0
          adjustFraction()
        else
          adjustPlaceholders()

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
