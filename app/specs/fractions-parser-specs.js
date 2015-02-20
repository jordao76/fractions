var Parser = require('../scripts/fractions-parser');

describe("Parser:", function() {

  describe("parse", function() {

    var p = function(e){return Parser.parse(e).ast;};

    it("can parse singleton expressions", function() {
      expect(p('2')).toEqual({ type: 'num', arg: 2 });
      expect(p('-2')).toEqual({ type: 'num', arg: -2 });
    });

    it("can parse simple expressions", function() {
      expect(p('2+3')).toEqual({
        type: 'add',
        arg: [{ type: 'num', arg: 2 }, { type: 'num', arg: 3 }]
      });
      expect(p('2-3')).toEqual({
        type: 'add',
        arg: [
          { type: 'num', arg: 2 }, 
          { type: 'minus', arg: { type: 'num', arg: 3 } }
        ]
      });
      expect(p('1*2')).toEqual({
        type: 'mul',
        arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 2 }]
      });
      expect(p('1/2')).toEqual({
        type: 'over',
        arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 2 }]
      });
    });

    it("can parse sub-expressions", function() {
      expect(p('2*(3+4)')).toEqual({
        type: 'mul',
        arg: [
          { type: 'num', arg: 2 }, 
          { type: 'exp', 
            arg: { type: 'add', arg: [{ type: 'num', arg: 3 }, { type: 'num', arg: 4 }] }
          }
        ]
      });
    });

    it("multiplication has preference over sum", function() {
      expect(p('2+3*4')).toEqual({
        type: 'add',
        arg: [
          { type: 'num', arg: 2 },
          { type: 'mul', arg: [ { type: 'num', arg: 3 }, { type: 'num', arg: 4 } ] }
        ]
      });
    });

    it("fraction has preference over multiplication", function() {
      expect(p('2*3/4')).toEqual({
        type: 'mul',
        arg: [
          { type: 'num', arg: 2 },
          { type: 'over', arg: [ { type: 'num', arg: 3 }, { type: 'num', arg: 4 } ] }
        ]
      });
    });

    it("missing term should partially parse", function() {
      expect(p('2/')).toEqual({
        type: 'over',
        arg: [
          { type: 'num', arg: 2 },
          { type: 'missing' }
        ]
      });
      expect(p('(')).toEqual({
        type: 'exp',
        arg: { type: 'missing' }
      });
      expect(p('-')).toEqual({
        type: 'minus',
        arg: { type: 'missing' }
      });
    });

    // TODO: failure scenarios

  });

  describe("calc", function(){

    var c = function(e){return Parser.parse(e).calc().toString();};
    var ce = function(e){return Parser.parse(e).calc();};

    it("calculates", function() {
      expect(c('2+3*4')).toBe('14');
      expect(c('2+3*(4-5)/6')).toBe('3/2');
    });

    it("fractions are calculated by pair, with one pair divided by the next", function() {
      expect(c('2/3/4')).toBe('1/6');
      expect(c('2/3/4/5')).toBe('5/6');
      expect(c('2/(3/4)/5')).toBe('8/15');
      expect(c('2*3/4/5')).toBe('3/10');
    });

    it("mismatched parentheses are balanced", function() {
      expect(c('2+(3*4')).toBe('14');
      expect(c('2+(3*(4/(5')).toBe('22/5');
      expect(c('(2+(3*4)/(5')).toBe('22/5');
    });

    it("missing term gives error", function() {
      var m = 'incomplete expression';
      expect(ce('2/')).toEqual({error: m});
      expect(ce('2/(')).toEqual({error: m});
      expect(ce('2+(3*(4/(')).toEqual({error: m});
      expect(ce('(')).toEqual({error: m});
    });

    // TODO: failure scenarios

  });

  describe("render", function(){

    var r = function(e, result){return Parser.parse(e).render(result);};

    it("renders as AsciiMath, * becomes xx", function() {
      expect(r('2+3*4')).toBe('2+3xx4');
      expect(r('2+3*(4-5)/6')).toBe('2+3xx(4-5)/6');
    });

    it("fractions are matched by pair, with one pair divided by the next with the division symbol -:", function() {
      expect(r('2/3/4')).toBe('2/3-:4');
      expect(r('2/3/4/5')).toBe('2/3-:4/5');
      expect(r('2/(3/4)/5')).toBe('2/(3/4)-:5');
      expect(r('2*3/4/5')).toBe('2xx3/4-:5');
    });

    it("mismatched parentheses are balanced", function() {
      expect(r('2+(3*4')).toBe('2+(3xx4)');
      expect(r('2+(3*(4/(5')).toBe('2+(3xx(4/(5)))');
      expect(r('(2+(3*4)/(5')).toBe('(2+(3xx4)/(5))');
    });

    it("missing term renders as a place-holder", function() {
      var ph = Parser.placeholder;
      expect(r('2/')).toBe('2/'+ph);
      expect(r('2/(')).toBe('2/('+ph+')');
      expect(r('2+(3*(4/(')).toBe('2+(3xx(4/('+ph+')))');
      expect(r('(')).toBe('('+ph+')');
    });

    // TODO: failure scenarios

  });

});
