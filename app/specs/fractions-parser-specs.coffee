Parser = require '../scripts/fractions-parser'

describe "Parser:", ->

  describe "parse", ->

    p = (e) -> Parser.parse(e).ast

    it "can parse singleton expressions", ->
      expect(p('2')).toEqual({ type: 'num', arg: 2 })
      expect(p('-2')).toEqual({ type: 'num', arg: -2 })

    it "can parse simple expressions", ->
      expect(p('2+3')).toEqual({
        type: 'add',
        arg: [{ type: 'num', arg: 2 }, { type: 'num', arg: 3 }]
      })
      expect(p('2-3')).toEqual({
        type: 'add',
        arg: [
          { type: 'num', arg: 2 }, 
          { type: 'minus', arg: { type: 'num', arg: 3 } }
        ]
      })
      expect(p('1*2')).toEqual({
        type: 'mul',
        arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 2 }]
      })
      expect(p('1/2')).toEqual({
        type: 'over',
        arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 2 }]
      })

    it "can parse sub-expressions", ->
      expect(p('2*(3+4)')).toEqual({
        type: 'mul',
        arg: [
          { type: 'num', arg: 2 }, 
          { type: 'exp', arg: { type: 'add', arg: [{ type: 'num', arg: 3 }, { type: 'num', arg: 4 }] } }
        ]
      })

    it "multiplication has preference over sum", ->
      expect(p('2+3*4')).toEqual({
        type: 'add',
        arg: [
          { type: 'num', arg: 2 },
          { type: 'mul', arg: [ { type: 'num', arg: 3 }, { type: 'num', arg: 4 } ] }
        ]
      })

    it "fraction has preference over multiplication", ->
      expect(p('2*3/4')).toEqual({
        type: 'mul',
        arg: [
          { type: 'num', arg: 2 },
          { type: 'over', arg: [ { type: 'num', arg: 3 }, { type: 'num', arg: 4 } ] }
        ]
      })

    it "missing term should partially parse", ->
      expect(p('2/')).toEqual({
        type: 'over',
        arg: [
          { type: 'num', arg: 2 },
          { type: 'missing' }
        ]
      })
      expect(p('(')).toEqual({
        type: 'exp',
        arg: { type: 'missing' }
      })
      expect(p('-')).toEqual({
        type: 'minus',
        arg: { type: 'missing' }
      })

    # TODO: failure scenarios

  describe "calc", ->

    c = (e) -> Parser.parse(e).calc().toString()
    ce = (e) -> Parser.parse(e).calc()

    it "calculates", ->
      expect(c('2+3*4')).toBe('14')
      expect(c('2+3*(4-5)/6')).toBe('3/2')

    it "fractions are calculated by pair, with one pair divided by the next", ->
      expect(c('2/3/4')).toBe('1/6')
      expect(c('2/3/4/5')).toBe('5/6')
      expect(c('2/(3/4)/5')).toBe('8/15')
      expect(c('2*3/4/5')).toBe('3/10')

    it "mismatched parentheses are balanced", ->
      expect(c('2+(3*4')).toBe('14')
      expect(c('2+(3*(4/(5')).toBe('22/5')
      expect(c('(2+(3*4)/(5')).toBe('22/5')

    it "missing term gives error", ->
      m = 'incomplete expression'
      expect(ce('2/')).toEqual({error: m})
      expect(ce('2/(')).toEqual({error: m})
      expect(ce('2+(3*(4/(')).toEqual({error: m})
      expect(ce('(')).toEqual({error: m})

    # TODO: failure scenarios

  describe "render", ->

    r = (e, result) -> Parser.parse(e).render(result)

    it "renders as AsciiMath, * becomes xx", ->
      expect(r('2+3*4')).toBe('2+3xx4')
      expect(r('2+3*(4-5)/6')).toBe('2+3xx(4-5)/6')

    it "fractions are matched by pair, with one pair divided by the next with the division symbol -:", ->
      expect(r('2/3/4')).toBe('2/3-:4')
      expect(r('2/3/4/5')).toBe('2/3-:4/5')
      expect(r('2/(3/4)/5')).toBe('2/(3/4)-:5')
      expect(r('2*3/4/5')).toBe('2xx3/4-:5')

    it "mismatched parentheses are balanced", ->
      expect(r('2+(3*4')).toBe('2+(3xx4)')
      expect(r('2+(3*(4/(5')).toBe('2+(3xx(4/(5)))')
      expect(r('(2+(3*4)/(5')).toBe('(2+(3xx4)/(5))')

    it "missing term renders as a place-holder", ->
      ph = Parser.placeholder
      expect(r('2/')).toBe('2/'+ph)
      expect(r('2/(')).toBe('2/('+ph+')')
      expect(r('2+(3*(4/(')).toBe('2+(3xx(4/('+ph+')))')
      expect(r('(')).toBe('('+ph+')')

    # TODO: failure scenarios
