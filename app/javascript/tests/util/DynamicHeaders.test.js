import generateDynamicHeaders from '../../components/util/DynamicHeaders';
import _ from 'lodash';

describe('DynamicHeaders', () => {
  it('Properly returns the correct header heirarchy for incorrect values', () => {
    expect(generateDynamicHeaders()).toBeNull();
    expect(generateDynamicHeaders(null)).toBeNull();
    expect(generateDynamicHeaders(NaN)).toBeNull();
    expect(generateDynamicHeaders('-1')).toBeNull();
    expect(generateDynamicHeaders('0')).toBeNull();
    expect(generateDynamicHeaders('7')).toBeNull();
    expect(generateDynamicHeaders('bad_test123')).toBeNull();
  });

  it('Properly returns the correct header heirarchy for values 2', () => {
    let value = generateDynamicHeaders(2);
    let expectedValue = {
      one: 'h2',
      two: 'h3',
      three: 'h4',
      four: 'h5',
      five: 'h6',
      six: null,
    };
    expect(_.isEqual(value, expectedValue)).toBeTruthy();
  });

  it('Properly returns the correct header heirarchy for values 3', () => {
    let value = generateDynamicHeaders(3);
    let expectedValue = {
      one: 'h3',
      two: 'h4',
      three: 'h5',
      four: 'h6',
      five: null,
      six: null,
    };
    expect(_.isEqual(value, expectedValue)).toBeTruthy();
  });

  it('Properly returns the correct header heirarchy for values 5', () => {
    let value = generateDynamicHeaders(4);
    let expectedValue = {
      one: 'h4',
      two: 'h5',
      three: 'h6',
      four: null,
      five: null,
      six: null,
    };
    expect(_.isEqual(value, expectedValue)).toBeTruthy();
  });

  it('Properly returns the correct header heirarchy for values 4', () => {
    let value = generateDynamicHeaders(5);
    let expectedValue = {
      one: 'h5',
      two: 'h6',
      three: null,
      four: null,
      five: null,
      six: null,
    };
    expect(_.isEqual(value, expectedValue)).toBeTruthy();
  });

  it('Properly returns the correct header heirarchy for values 6', () => {
    let value = generateDynamicHeaders(6);
    let expectedValue = {
      one: 'h6',
      two: null,
      three: null,
      four: null,
      five: null,
      six: null,
    };
    expect(_.isEqual(value, expectedValue)).toBeTruthy();
  });
});
