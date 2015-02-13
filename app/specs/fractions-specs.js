var Fraction = require('../scripts/fractions');

describe("A fraction:", function() {

  var f = function(n,d){return new Fraction(n,d)};

  it("can't have a denominator of 0", function() {
    expect(function(){f(1, 0);}).toThrow();
    expect(function(){f(1, -0);}).toThrow();
  });

  it("is represented with a slash between the numerator and the denominator if the denominator is != 1 and != 0", function() {
    expect(f(1, 2).toString()).toBe("1/2");
    expect(f(-1, 2).toString()).toBe("-1/2");
    expect(f(1, -2).toString()).toBe("-1/2");
    expect(f(-1, -2).toString()).toBe("1/2");
  });

  it("is represented simply as the numerator if the denominator is 1 or not provided", function() {
    expect(f(17, 1).toString()).toBe("17");
    expect(f(-17, 1).toString()).toBe("-17");
    expect(f(17, -1).toString()).toBe("-17");
    expect(f(-17, -1).toString()).toBe("17");
    expect(f(21).toString()).toBe("21");
    expect(f(-21).toString()).toBe("-21");
    expect(f(0).toString()).toBe("0");
    expect(f(-0).toString()).toBe("0");
  });

  it("is equal to equivalent fractions (which indicates that it's stored in simplified form)", function() {
    expect(f(10, 20)).toEqual(f(1, 2));
    expect(f(20, 10)).toEqual(f(2));
    expect(f(10, 20)).toEqual(f(56, 112));
    expect(f(1, -2)).toEqual(f(-1, 2));
    expect(f(-1, -2)).toEqual(f(1, 2));
  });

  it("is represented in simplified form", function() {
    expect(f(56, 112).toString()).toBe("1/2");
  });

  it("can have its float value calculated", function() {
    expect(f(1, 2).toFloat()).toBe(0.5);
    expect(f(13).toFloat()).toBe(13);
  });

  it("can be negated", function() {
    expect(Fraction.minus(f(1, 2))).toEqual(f(-1, 2));
    expect(Fraction.minus(f(-1, 2))).toEqual(f(1, 2));
  });

  it("can participate in operations with other fractions", function() {
    expect(Fraction.add(f(1, 2), f(1, 3))).toEqual(f(5, 6));
    expect(Fraction.mul(f(1, 2), f(1, 3))).toEqual(f(1, 6));
    expect(Fraction.div(f(1, 2), f(1, 3))).toEqual(f(3, 2));
    expect(function(){Fraction.div(f(1, 2), f(0));}).toThrow();
  });

});
