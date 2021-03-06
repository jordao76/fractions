# coffeelint: disable=max_line_length

Parser = require '../scripts/fractions-parser'

describe "Parser:", ->

  describe "parse ast", ->

    parse = (e) -> Parser.parse(e).ast

    it "can parse singleton expressions", ->
      expect(parse '2').toEqual { type: 'num', arg: 2 }
      expect(parse '-2').toEqual { type: 'num', arg: -2 }

    it "can parse simple expressions", ->
      expect(parse '2+3').toEqual
        type: 'add'
        arg: [{ type: 'num', arg: 2 }, { type: 'num', arg: 3 }]
      expect(parse '2-3').toEqual
        type: 'add'
        arg: [{ type: 'num', arg: 2 }, { type: 'num', arg: -3 }]
      expect(parse '1*2').toEqual
        type: 'mul'
        arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 2 }]
      expect(parse '1/2').toEqual
        type: 'over'
        arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 2 }]
      expect(parse '2÷3').toEqual
        type: 'mul'
        arg: [{ type: 'num', arg: 2 }, { type: 'div', arg: { type: 'num', arg: 3 } }]
      expect(parse '1/0').toEqual
        type: 'over'
        arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 0 }]

    it "can parse sub-expressions", ->
      expect(parse '2*(3+4)').toEqual
        type: 'mul'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'exp', arg: { type: 'add', arg: [{ type: 'num', arg: 3 }, { type: 'num', arg: 4 }] } }
        ]

    it "multiplication has preference over sum", ->
      expect(parse '2+3*4').toEqual
        type: 'add'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'mul', arg: [ { type: 'num', arg: 3 }, { type: 'num', arg: 4 } ] }
        ]

    it "fraction has preference over multiplication", ->
      expect(parse '2÷3/4').toEqual
        type: 'mul'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'div', arg: { type: 'over', arg: [ { type: 'num', arg: 3 }, { type: 'num', arg: 4 } ] } }
        ]

    it "can parse mixed fractions", ->
      expect(parse '2 3/4').toEqual
        type: 'mixed'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'num', arg: 3 }
          { type: 'num', arg: 4 }
        ]
      expect(parse '2 3/4+5 6/7').toEqual
        type: 'add'
        arg: [
          {
            type: 'mixed'
            arg: [
              { type: 'num', arg: 2 }
              { type: 'num', arg: 3 }
              { type: 'num', arg: 4 }
            ]
          }
          {
            type: 'mixed'
            arg: [
              { type: 'num', arg: 5 }
              { type: 'num', arg: 6 }
              { type: 'num', arg: 7 }
            ]
          }
        ]

    it "mismatched parentheses are balanced", ->
      expect(parse '2+(3').toEqual
        incomplete: { parens: 1 }
        type: 'add'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'exp', arg: { type: 'num', arg: 3 } }
        ]

    it "missing term should partially parse", ->
      expect(parse '2/').toEqual
        incomplete: { numbers: 1 }
        type: 'over'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'missing' }
        ]
      expect(parse '(').toEqual
        incomplete: { parens: 1, numbers: 1 }
        type: 'exp'
        arg: { type: 'missing' }
      expect(parse '-').toEqual
        incomplete: { numbers: 1 }
        type: 'minus'
        arg: { type: 'missing' }
      expect(parse '2 1/').toEqual
        incomplete: { numbers: 1 }
        type: 'mixed'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'num', arg: 1 }
          { type: 'missing' }
        ]
      expect(parse '2 1').toEqual
        incomplete: { numbers: 1, symbols: 1 }
        type: 'mixed'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'num', arg: 1 }
          { type: 'missing' }
        ]
      expect(parse '2 ').toEqual
        incomplete: { numbers: 2, symbols: 1 }
        type: 'mixed'
        arg: [
          { type: 'num', arg: 2 }
          { type: 'missing' }
          { type: 'missing' }
        ]

    it "bad input should not parse", ->
      expect(parse '123bad').toEqual
        error: 'Expected end of input but "b" found.'
      expect(parse '2/3/4').toEqual
        error: 'Expected end of input but "/" found.'

  describe "calc", ->

    calc = (e) -> Parser.parse(e).calc()
    calc_s = (e) -> calc(e).toString()

    it "calculates", ->
      expect(calc_s '1+2').toBe '3'
      expect(calc_s '2+3*4').toBe '14'
      expect(calc_s '2+3*(4-5)-2/6').toBe '-4/3'
      expect(calc_s '6 5/7').toBe '47/7'
      expect(calc_s '2÷4').toBe '1/2'

    it "mismatched parentheses are balanced", ->
      expect(calc_s '2+(3*4').toBe '14'
      expect(calc_s '2+(3*(4/5').toBe '22/5'
      expect(calc_s '(2+(3*4/5').toBe '22/5'

    it "missing term gives error", ->
      message = 'incomplete expression'
      expect(calc '2/').toEqual error: message
      expect(calc '2+(3*(4/').toEqual error: message
      expect(calc '(').toEqual error: message

    it "bad input should not calculate", ->
      expect(calc '123bad').toEqual ''
      expect(calc '2/3/4').toBe ''

    it "division by zero should not calculate", ->
      expect(calc '1/0').toEqual error: 'Division by zero!'

  describe "render", ->

    render = (e, o) -> Parser.parse(e).render(o)

    it "renders as TeX", ->
      expect(render '2/3').toBe '\\frac{2}{3}'
      expect(render '2÷3').toBe '2 \\div 3'
      expect(render '1 2/3').toBe '1 \\frac{2}{3}'
      expect(render '2-3').toBe '2 - 3'
      expect(render '2+3*4').toBe '2 + 3 \\times 4'
      expect(render '2+3*4-5/6').toBe '2 + 3 \\times 4 - \\frac{5}{6}'

    it "missing term renders as empty", ->
      expect(render '2-').toBe '2 - '
      expect(render '(').toBe '\\left( \\right)'
      expect(render '2+(3*(4/').toBe '2 + \\left( 3 \\times \\left( \\frac{4}{\\circ} \\right) \\right)'

    it "missing fraction term renders as placeholder \\circ", ->
      expect(render '2/').toBe '\\frac{2}{\\circ}'
      expect(render '1 ').toBe '1 \\frac{\\circ}{\\circ}'
      expect(render '1 1').toBe '1 \\frac{1}{\\circ}'

    it "bad input should return error on render", ->
      expect(render '123bad').toEqual error: 'Expected end of input but "b" found.'
      expect(render '').toEqual error: 'Expected expression but end of input found.'

    it "division by zero should render", ->
      expect(render '1/0').toEqual '\\frac{1}{0}'

    it "with result, simple and mixed fractions", ->
      expect(render '1/8+2/8', result: yes).toBe '\\frac{1}{8} + \\frac{2}{8} = \\frac{3}{8}'
      expect(render '7/8+2/8', result: yes).toBe '\\frac{7}{8} + \\frac{2}{8} = \\frac{9}{8} = 1 \\frac{1}{8}'
      expect(render '9/8', result: yes).toBe '\\frac{9}{8} = 1 \\frac{1}{8}'
      expect(render '1/8', result: yes).toBe '\\frac{1}{8}'
      expect(render '4/8', result: yes).toBe '\\frac{4}{8} = \\frac{1}{2}'
      expect(render '1 1/8', result: yes).toBe '1 \\frac{1}{8} = \\frac{9}{8}'

    it "render with result, errors", ->
      expect(render '4/0', result: yes).toEqual error: 'Division by zero!'
      expect(render '4/', result: yes).toEqual error: 'incomplete expression'
