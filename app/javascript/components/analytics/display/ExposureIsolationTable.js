import React from 'react';
import { PropTypes } from 'prop-types';
// import InfoTooltip from '../../util/InfoTooltip';

class ExposureIsolationTable extends React.Component {
  render() {
    return (
      <React.Fragment>
        <div className="analytics-table-header">{this.props.title}</div>
        <table className="analytics-table text-right">
          <thead>
            <tr className="header">
              <th></th>
              <th>Exposure</th>
              <th>Isolation</th>
              <th>TOTAL</th>
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

{
  /* <div className="text-left mt-3 mb-n1 h4"> Country of Exposure </div>
          <table className="analytics-table">
            <thead>
              <tr>
                <th className="py-0"></th>
                {WORKFLOWS.map((header, index) => (
                  <th key={index} className="font-weight-bold">
                    {' '}
                    <u>{_.upperCase(header)}</u>{' '}
                  </th>
                ))}
                <th>Total</th>
              </tr>
            </thead>
            {this.COUNTRY_HEADERS.map((val, index2) => (
              <tbody key={`workflow-table-${index2}`}>
                <tr className={index2 % 2 ? '' : 'row-striped-dark'}>
                  <td className="font-weight-bold"> {val} </td>
                  {this.countryData[Number(index2)].map((data, subIndex2) => (
                    <td key={subIndex2}> {data} </td>
                  ))}
                </tr>
              </tbody>
            ))}
          </table> */
}
