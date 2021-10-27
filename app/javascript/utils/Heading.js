import React from 'react';

// The Heading element below throws a false-positive for prop-types validation
/* eslint-disable-next-line react/prop-types */
const Heading = ({ level, children, ...props }) => {
  return React.createElement(`h${Math.min(level, 6)}`, props, children);
};

export { Heading };
