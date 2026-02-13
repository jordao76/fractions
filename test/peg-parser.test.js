import { describe, it, expect } from 'vitest';
import { parse } from '../src/fractions-peg-parser.js';

describe('PEG Parser (smoke test):', () => {
  it('parses a simple number', () => {
    expect(parse('2')).toEqual({ type: 'num', arg: 2 });
  });

  it('parses an addition', () => {
    expect(parse('2+3')).toEqual({
      type: 'add',
      arg: [{ type: 'num', arg: 2 }, { type: 'num', arg: 3 }],
    });
  });

  it('parses a fraction', () => {
    expect(parse('1/2')).toEqual({
      type: 'over',
      arg: [{ type: 'num', arg: 1 }, { type: 'num', arg: 2 }],
    });
  });

  it('parses a mixed fraction', () => {
    expect(parse('2 3/4')).toEqual({
      type: 'mixed',
      arg: [
        { type: 'num', arg: 2 },
        { type: 'num', arg: 3 },
        { type: 'num', arg: 4 },
      ],
    });
  });
});
