# coffeelint: disable=max_line_length

describe "Calculator:", ->

  [output, decimal, error] = [null, null, null]
  calculator = (require '../scripts/calculator')
    output: (s, d = '') ->
      output = s
      decimal = d
    onError: (s) -> error = s

  afterInput = (s) -> [calculator.input k for k in s]
  afterUninput = -> calculator.uninput()
  canInput = (k) -> calculator.canInput k

  afterEach ->
    calculator.input 'C'

  it "starts with empty output", ->
    expect(output).toBe ''
    expect(decimal).toBe ''

  it "can take input", ->
    afterInput '1+'; expect(output).toBe '1+'
    afterInput '2/3'; expect(output).toBe '1+2/3'

  it "can take input and calculate a result", ->
    afterInput '1+1='
    expect(output).toBe '1+1=2'
    expect(decimal).toBe 2

  it "can take back input", ->
    afterInput '1+'; expect(output).toBe '1+'
    afterUninput(); expect(output).toBe '1'
    afterUninput(); expect(output).toBe ''

  it "can take back input when empty", ->
    afterUninput(); expect(output).toBe ''

  it "can chain calculations", ->
    afterInput '1+1='
    afterInput '+1='; expect(output).toBe '2+1=3'

  it "clears result when chaining a number", ->
    afterInput '1+1='
    afterInput '42'; expect(output).toBe '42'

  it "can be cleared", ->
    afterInput '1+1=C'
    expect(output).toBe ''
    expect(decimal).toBe ''

  it "can check for valid input", ->
    expect(canInput '/').toBe no
    expect(canInput '1').toBe yes
    expect(canInput '=').toBe no
    afterInput '1'
    expect(canInput '/').toBe yes
    expect(canInput '1').toBe yes
    expect(canInput '=').toBe yes
    afterInput '+'
    expect(canInput '/').toBe no
    expect(canInput '1').toBe yes
    expect(canInput '=').toBe no

  it "can check for valid input for mixed fractions", ->
    expect(canInput ' ').toBe no
    afterInput '1'
    expect(canInput ' ').toBe yes
    afterInput ' '
    expect(canInput '2').toBe yes
    afterInput '2'
    expect(canInput '/').toBe yes
    afterInput '/'
    expect(canInput '3').toBe yes
    afterInput '3'
    expect(output).toBe '1 2/3'

  it "invalid input does not register", ->
    afterInput '1+'
    afterInput '='; expect(output).toBe '1+'

  it "bogus input does not register", ->
    afterInput '1+asdf/1'; expect(output).toBe '1+1'

  it "Division by zero", ->
    afterInput '1/0='
    expect(output).toBe '1/0'
    expect(decimal).toBe ''
    expect(error).toBe 'Division by zero!'