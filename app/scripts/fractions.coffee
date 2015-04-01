### global module ###

gcd = (n, d) ->
  remainder = 0
  while (d isnt 0)
    remainder = n % d
    n = d
    d = remainder
  Math.abs n

div0 = new Error 'Division by zero!'

Fraction = (n, d) ->
  throw div0 if d is 0
  d ?= 1
  [n, d] = [-n, -d] if d < 0
  div = gcd n, d
  @n = n / div
  @d = d / div

fraction = (n, d) -> new Fraction n, d

Fraction.create = (n, d) -> fraction n, d

Fraction.add = (l, r) ->
  [a, b, c, d] = [l.n, l.d, r.n, r.d]
  fraction a*d + c*b, b*d

Fraction.minus = (f) ->
  [n, d] = [f.n, f.d]
  fraction -n, d

Fraction.mul = (l, r) ->
  [a, b, c, d] = [l.n, l.d, r.n, r.d]
  fraction a*c, b*d

Fraction.div = (l, r) ->
  [a, b, c, d] = [l.n, l.d, r.n, r.d]
  fraction a*d, b*c

Fraction.prototype =
  toFloat: () -> @n / @d
  toString: () -> if @d is 1 then "#{@n}" else "#{@n}/#{@d}"

module.exports = Fraction
