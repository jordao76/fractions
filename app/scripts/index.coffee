### global MathJax,jQuery,require ###

((MathJax, $, Parser) ->
  $ ->
    $input = $('#input')
    $output = $('#output')
    $buffer = $('#buffer')
    $parsed = $('#parsed')
    $decimal = $('#decimal')

    output = (s) ->
      MathJax.Hub.Queue ->
        $parsed.text s
        $buffer.text '`' + s + '`'
        MathJax.Hub.Typeset $buffer.get(), ->
          if $parsed.text() == s
            $output.html $buffer.html()
          return
        return
      return

    last = null

    butFirstClear = ->
      $decimal.text ''
      output ''
      last = ''
      return

    process = ->
      exp = $input.val()
      if !exp.trim()
        return butFirstClear()
      if exp != last
        parsed = Parser.parse(exp)
        output parsed.render()
        $decimal.text ''
        last = exp
      return

    calc = ->
      exp = $input.val()
      if !exp.trim()
        return butFirstClear()
      parsed = Parser.parse(exp)
      result = parsed.calc()
      output parsed.render(result)
      if !result.error
        $decimal.text result.toFloat()
        $input.val last = result.toString()
      return

    $input.keyup (e) ->
      if e.which == 13
        calc()
      return
    # 13 is <ENTER>
    $input.on 'input propertychange', process
    $input.focus()
    return
  return
) MathJax, jQuery, require('./fractions-parser')
