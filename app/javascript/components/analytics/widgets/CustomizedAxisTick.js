import React from 'react';
import { PropTypes } from 'prop-types';
import { Text } from 'recharts';
// The purpose of this file is to provide a customized axis for the recharts bar-graphs.
// By default, the library selects x-axis values for each bar. If they are too long,
// the library seemingly randomly selects to show some and not others. This can make it
// look like certain values are missing (when they are just hidden).
// Obviously, that's not desirable behavior. This component can be used as a tick
// for the XAxis. It essentially text-wraps all bar-values so they are all shown, and none
// are hidden.
class CustomizedAxisTick extends React.Component {
  constructor(props) {
    super(props);
  }
  render() {
    const { x, y, payload } = this.props;
    return (
      <Text x={x} y={y} width={65} textAnchor="middle" verticalAnchor="start" className="recharts-custom-tick">
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
