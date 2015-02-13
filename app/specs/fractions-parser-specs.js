var Parser = require('../scripts/fractions-parser');

describe("Parser:", function() {

  var p = function(e){return Parser.parse(e)};

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

  // TODO: precedence rules

  // TODO: failure scenarios, partial parsing

});
