# coffeelint: disable=max_line_length

describe "Calculator:", ->

  [output, decimal, error] = [null, null, null]
  calculator = (require '../scripts/calculator')
    output: (s, d = '') ->
      output = s
      decimal = d
    onError: (s) -> error = s

  after_input = (s) -> [calculator.input k for k in s]
  after_uninput = -> calculator.uninput()
  can_input = (k) -> calculator.canInput k
  clear = -> after_input 'C' # TODO: teardown (or setup creating a new calculator)

  it "starts with empty output", ->
    expect(output).toBe ''
    expect(decimal).toBe ''

  it "can take input", ->
    after_input '1+'; expect(output).toBe '1+'
    after_input '2/3'; expect(output).toBe '1+2/3'
    clear()

  it "can take input and calculate a result", ->
    after_input '1+1='
    expect(output).toBe '1+1=2'
    expect(decimal).toBe 2
    clear()

  it "can take back input", ->
    after_input '1+'; expect(output).toBe '1+'
    after_uninput(); expect(output).toBe '1'
    after_uninput(); expect(output).toBe ''
    clear()

  it "can take back input when empty", ->
    after_uninput(); expect(output).toBe ''
    clear()

  it "can chain calculations", ->
    after_input '1+1='
    after_input '+1='; expect(output).toBe '2+1=3'
    clear()

  it "clears result when chaining a number", ->
    after_input '1+1='
    after_input '42'; expect(output).toBe '42'
    clear()

  it "can be cleared", ->
    after_input '1+1=C'
    expect(output).toBe ''
    expect(decimal).toBe ''

  it "can check for valid input", ->
    expect(can_input '/').toBe no
    expect(can_input '1').toBe yes
    expect(can_input '=').toBe no
    after_input '1'
    expect(can_input '/').toBe yes
    expect(can_input '1').toBe yes
    expect(can_input '=').toBe yes
    after_input '+'
    expect(can_input '/').toBe no
    expect(can_input '1').toBe yes
    expect(can_input '=').toBe no
    clear()

  it "invalid input does not register", ->
    after_input '1+'
    expect(can_input '=').toBe no
    after_input '='; expect(output).toBe '1+'
    clear()

  it "bogus input does not register", ->
    after_input '1+asdf/1'; expect(output).toBe '1+1'
    clear()

  it "Division by zero", ->
    after_input '1/0='
    expect(output).toBe '1/0'
    expect(decimal).toBe ''
    expect(error).toBe 'Division by zero!'
    clear()
