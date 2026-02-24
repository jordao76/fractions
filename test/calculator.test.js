import { describe, it, expect, afterEach } from 'vitest';
import calculator from '../src/calculator.js';

describe('Calculator:', () => {
  let output = null;
  let decimal = null;
  let parens = null;
  let numbers = null;
  let symbols = null;
  let error = null;

  const calc = calculator({
    output: (s, o) => {
      output = s;
      decimal = o?.decimal ?? '';  // ?? not || so that decimal=0 is preserved
      parens = o?.incomplete?.parens || 0;
      numbers = o?.incomplete?.numbers || 0;
      symbols = o?.incomplete?.symbols || 0;
    },
    onError: (s) => { error = s; },
  });

  const afterInput = (s) => { for (const k of s) calc.input(k); };
  const afterUninput = () => calc.uninput();
  const canInput = (k) => calc.canInput(k);

  afterEach(() => {
    calc.input('C');
  });

  it('starts with empty output', () => {
    expect(output).toBe('');
    expect(decimal).toBe('');
  });

  it('can take input', () => {
    afterInput('1+'); expect(output).toBe('1 + ');
    afterInput('2/3'); expect(output).toBe('1 + \\frac{2}{3}');
  });

  it('can take input and calculate a result', () => {
    afterInput('1+1=');
    expect(output).toBe('1 + 1 = 2');
    expect(decimal).toBe(2);
  });

  it('can take back input', () => {
    afterInput('1+'); expect(output).toBe('1 + ');
    afterUninput(); expect(output).toBe('1');
    afterUninput(); expect(output).toBe('');
  });

  it('can take back input when empty', () => {
    afterUninput(); expect(output).toBe('');
  });

  it('can chain calculations', () => {
    afterInput('1+1=');
    afterInput('+1='); expect(output).toBe('2 + 1 = 3');
  });

  it('clears result when chaining a number', () => {
    afterInput('1+1=');
    afterInput('42'); expect(output).toBe('42');
  });

  it('clears result when taking input back', () => {
    afterInput('41+1=');
    afterUninput(); expect(output).toBe('');
    afterInput('62'); expect(output).toBe('62');
    afterUninput(); expect(output).toBe('6');
  });

  it('gets number of added terms', () => {
    afterInput('((');
    expect(parens).toBe(2);
  });

  it('can be cleared', () => {
    afterInput('1+1=C');
    expect(output).toBe('');
    expect(decimal).toBe('');
  });

  it('can check for valid input', () => {
    expect(canInput('/')).toBe(false);
    expect(canInput('1')).toBe(true);
    expect(canInput('=')).toBe(false);
    afterInput('1');
    expect(canInput('/')).toBe(true);
    expect(canInput('1')).toBe(true);
    expect(canInput('=')).toBe(true);
    afterInput('+');
    expect(canInput('/')).toBe(false);
    expect(canInput('1')).toBe(true);
    expect(canInput('=')).toBe(false);
  });

  it('can check for valid input for mixed fractions', () => {
    expect(canInput(' ')).toBe(false);
    afterInput('1');
    expect(canInput(' ')).toBe(true);
    afterInput(' ');
    expect(canInput('2')).toBe(true);
    afterInput('2');
    expect(canInput('/')).toBe(true);
    afterInput('/');
    expect(canInput('3')).toBe(true);
    afterInput('3');
    expect(output).toBe('1 \\frac{2}{3}');
  });

  it('can check for valid input for mixed fractions in expressions', () => {
    afterInput('(1');
    expect(canInput(' ')).toBe(true);
    afterInput(' 2/3');
    expect(output).toBe('\\left( 1 \\frac{2}{3} \\right)');
  });

  it('invalid input does not register', () => {
    afterInput('1+');
    afterInput('='); expect(output).toBe('1 + ');
  });

  it('bogus input does not register', () => {
    afterInput('1+asdf/1'); expect(output).toBe('1 + 1');
  });

  it('Division by zero via fraction notation', () => {
    afterInput('1/0=');
    expect(output).toBe('\\frac{1}{0}');
    expect(decimal).toBe('');
    expect(error).toBe('Division by zero!');
  });

  it('Division by zero via ÷ operator', () => {
    afterInput('1÷0=');
    expect(error).toBe('Division by zero!');
  });

  it('Result of zero', () => {
    afterInput('1/3-1/3=');
    expect(output).toContain('= 0');
    expect(decimal).toBe(0);
  });

  it('Zero divided by a number is zero', () => {
    afterInput('0÷3=');
    expect(output).toContain('= 0');
    expect(decimal).toBe(0);
  });

  it('Negative result', () => {
    afterInput('1-2=');
    expect(output).toBe('1 - 2 = -1');
    expect(decimal).toBe(-1);
  });

  it('Negative mixed fraction result', () => {
    afterInput('1/3-2/3=');
    expect(output).toContain('= \\frac{-1}{3}');
    expect(decimal).toBeCloseTo(-1/3);
  });
});
