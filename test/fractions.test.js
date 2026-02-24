import { describe, it, expect } from 'vitest';
import { Fraction } from '../src/fractions.js';

describe('A fraction:', () => {
  const f = (n, d) => new Fraction(n, d);
  const m = (w, n, d) => Fraction.mixed(w, n, d);

  it('has a numerator and a denominator', () => {
    expect(f(1, 2).n).toBe(1);
    expect(f(1, 2).d).toBe(2);
    expect(f(-1, -2).n).toBe(1);
    expect(f(-1, -2).d).toBe(2);
    expect(f(12).n).toBe(12);
    expect(f(12).d).toBe(1);
  });

  it("can't have a denominator of 0", () => {
    expect(() => f(1, 0)).toThrow();
    expect(() => f(1, -0)).toThrow();
  });

  it('is represented with a slash between the numerator and the denominator if the denominator is != 1 and != 0', () => {
    expect(f(1, 2).toString()).toBe('1/2');
    expect(f(-1, 2).toString()).toBe('-1/2');
    expect(f(1, -2).toString()).toBe('-1/2');
    expect(f(-1, -2).toString()).toBe('1/2');
  });

  it('is represented simply as the numerator if the denominator is 1 or not provided', () => {
    expect(f(17, 1).toString()).toBe('17');
    expect(f(-17, 1).toString()).toBe('-17');
    expect(f(17, -1).toString()).toBe('-17');
    expect(f(-17, -1).toString()).toBe('17');
    expect(f(21).toString()).toBe('21');
    expect(f(-21).toString()).toBe('-21');
    expect(f(0).toString()).toBe('0');
    expect(f(-0).toString()).toBe('0');
  });

  it("is equal to equivalent fractions (which indicates that it's stored in simplified form)", () => {
    expect(f(10, 20)).toEqual(f(1, 2));
    expect(f(20, 10)).toEqual(f(2));
    expect(f(10, 20)).toEqual(f(56, 112));
    expect(f(1, -2)).toEqual(f(-1, 2));
    expect(f(-1, -2)).toEqual(f(1, 2));
  });

  it('is represented in simplified form', () => {
    expect(f(56, 112).toString()).toBe('1/2');
  });

  it('can be created from mixed numbers', () => {
    expect(m(6, 5, 7)).toEqual(f(47, 7));
    expect(m(6, 5, 7).toString()).toBe('47/7');
  });

  it('can be represented as mixed numbers', () => {
    expect(f(47, 7).isProper()).toBe(false);
    expect(f(47, 7).toMixedString()).toBe('6 5/7');
    expect(f(1, 7).isProper()).toBe(true);
    expect(f(1, 7).toMixedString()).toBe('1/7');
    expect(f(42).isProper()).toBe(false);
    expect(f(42).toMixedString()).toBe('42');
  });

  it('can have its float value calculated', () => {
    expect(f(1, 2).toFloat()).toBe(0.5);
    expect(f(13).toFloat()).toBe(13);
  });

  it('can be negated', () => {
    expect(Fraction.minus(f(1, 2))).toEqual(f(-1, 2));
    expect(Fraction.minus(f(-1, 2))).toEqual(f(1, 2));
  });

  it('can participate in operations with other fractions', () => {
    expect(Fraction.add(f(1, 2), f(1, 3))).toEqual(f(5, 6));
    expect(Fraction.mul(f(1, 2), f(1, 3))).toEqual(f(1, 6));
    expect(Fraction.div(f(1, 2), f(1, 3))).toEqual(f(3, 2));
    expect(() => Fraction.div(f(1, 2), f(0))).toThrow();
  });

  it('reciprocal', () => {
    expect(Fraction.reciprocal(f(3, 2))).toEqual(f(2, 3));
    expect(() => Fraction.reciprocal(f(0, 2))).toThrow();
  });

  it('isProper works correctly for negative fractions', () => {
    expect(f(-1, 7).isProper()).toBe(true);   // |-1| < 7
    expect(f(-7, 3).isProper()).toBe(false);  // |-7| > 3
    expect(f(-3, 3).isProper()).toBe(false);  // |-3| = 3, not strictly less
  });

  it('negative mixed numbers: -2 1/3 means -(2 + 1/3) = -7/3', () => {
    expect(m(-2, 1, 3)).toEqual(f(-7, 3));
    expect(m(-2, 1, 3).toString()).toBe('-7/3');
  });

  it('toMixedString works correctly for negative improper fractions', () => {
    expect(f(-7, 3).isProper()).toBe(false);
    expect(f(-7, 3).toMixedString()).toBe('-2 1/3');
    expect(f(-14, 3).toMixedString()).toBe('-4 2/3');
  });

  it('integer overflow: denominators exceeding MAX_SAFE_INTEGER lose precision', () => {
    // 100000001 * 100000003 = 10000000400000003 (exact, odd — not representable as double)
    // JS rounds this to 10000000400000004, introducing a spurious GCD of 200000004
    expect(100000001 * 100000003).toBeGreaterThan(Number.MAX_SAFE_INTEGER);
    // The calculation completes without throwing but the result is imprecise
    const result = Fraction.add(f(1, 100000001), f(1, 100000003));
    expect(() => result.toFloat()).not.toThrow();
    // Exact result would be 200000004/10000000400000003 (irreducible)
    // Due to overflow the result incorrectly simplifies to 1/50000001
    expect(result.n).toBe(1);
    expect(result.d).toBe(50000001);
  });
});
