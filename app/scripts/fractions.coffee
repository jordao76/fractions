### global module ###

gcd = (n, d) ->
  r = 0
  until d is 0
    r = n % d
    n = d
    d = r
  Math.abs n

div0 = new Error 'Division by zero!'

class Fraction

  constructor: (n, d = 1) ->
    throw div0 if d is 0
    [n, d] = [-n, -d] if d < 0
    div = gcd n, d
    @n = n / div
    @d = d / div

  isProper: -> @n < @d

  toFloat: -> @n / @d

  toString: -> if @d is 1 then "#{@n}" else "#{@n}/#{@d}"

  toMixedString: ->
    if @isProper()
      @toString()
    else if @n % @d is 0
      "#{@n // @d}"
    else
      "#{@n // @d} #{@n % @d}/#{@d}"

  @create: (n, d) -> new Fraction n, d

  @mixed: (w, n, d) -> @create n + w*d, d

  @add: (l, r) ->
    [a, b, c, d] = [l.n, l.d, r.n, r.d]
    @create a*d + c*b, b*d

  @minus = (f) ->
    [n, d] = [f.n, f.d]
    @create -n, d

  @mul = (l, r) ->
    [a, b, c, d] = [l.n, l.d, r.n, r.d]
    @create a*c, b*d

  @div = (l, r) ->
    [a, b, c, d] = [l.n, l.d, r.n, r.d]
    @create a*d, b*c

module.exports = Fraction
