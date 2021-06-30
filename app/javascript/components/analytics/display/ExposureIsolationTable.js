import React from 'react';
import { PropTypes } from 'prop-types';
import InfoTooltip from '../../util/InfoTooltip';

class ExposureIsolationTable extends React.Component {
  render() {
    return (
      <React.Fragment>
        <div className="analytics-table-header">
          {this.props.title}
          {this.props.tooltipKey && (
            <span className="h6 text-left">
              <InfoTooltip tooltipTextKey={this.props.tooltipKey} location="right"></InfoTooltip>
            </span>
          )}
        </div>
        <table className="analytics-table text-right">
          <thead>
            <tr className="header">
              <th></th>
              <th>Exposure</th>
              <th>Isolation</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {this.props.data.map((row, r_index) => (
              <tr key={`row${r_index}`} className={r_index % 2 ? 'row-striped-light' : 'row-striped-dark'}>
                <td className="text-left header">{this.props.rowHeaders[r_index]}</td>
                {row.map((cell, c_index) => (
                  <td key={`cell${c_index}`} className={c_index === 2 ? 'total-column' : ''}>
                    {cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </React.Fragment>
    );
  }
}

ExposureIsolationTable.propTypes = {
  title: PropTypes.string,
  rowHeaders: PropTypes.array,
  data: PropTypes.array,
};

export default ExposureIsolationTable;
