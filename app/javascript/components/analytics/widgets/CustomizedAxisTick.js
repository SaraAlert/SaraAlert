import React from 'react';
import { PropTypes } from 'prop-types';
import { Text } from 'recharts';

class CustomizedAxisTick extends React.Component {
  constructor(props) {
    super(props);
  }
  render() {
    const { x, y, payload } = this.props;
    return (
      <Text x={x} y={y} width={65} textAnchor="middle" verticalAnchor="start" style={{ fontSize: '.8rem' }}>
        {payload.value}
      </Text>
    );
  }
}
CustomizedAxisTick.propTypes = {
  x: PropTypes.number,
  y: PropTypes.number,
  payload: PropTypes.object, // top, right, bottom, left
};
export default CustomizedAxisTick;
