import React from 'react';
import { PropTypes } from 'prop-types';
import InfoTooltip from '../../util/InfoTooltip';

class WorkflowTable extends React.Component {
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
        <div className="table-responsive">
          <table className="analytics-table workflow-table text-right">
            <thead>
              <tr className="header">
                <th></th>
                {this.props.workflows.map((workflow, i) => (
                  <th key={i}>{workflow}</th>
                ))}
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {this.props.data.map((row, r_index) => (
                <tr key={`row${r_index}`} className={r_index % 2 ? 'row-striped-light' : 'row-striped-dark'}>
                  <td className="text-left header">{this.props.rowHeaders[parseInt(r_index)]}</td>
                  {row.map((cell, c_index) => (
                    <td key={`cell${c_index}`} className={c_index === 2 ? 'total-column' : ''}>
                      {cell}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </React.Fragment>
    );
  }
}

WorkflowTable.propTypes = {
  title: PropTypes.string,
  tooltipKey: PropTypes.string,
  workflows: PropTypes.array,
  rowHeaders: PropTypes.array,
  data: PropTypes.array,
};

WorkflowTable.defaultProps = {
  workflows: ['Exposure', 'Isolation'],
};

export default WorkflowTable;
