import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Table } from 'react-bootstrap';

class CommonExposureCohortsTable extends React.Component {
  render() {
    return (
      <Table borderless hover size={this.props.size || 'lg'}>
        <thead>
          <tr>
            <th>Cohort Type</th>
            <th>Cohort Name/Description</th>
            <th>Cohort Location</th>
            {this.props.isEditable && (
              <React.Fragment>
                <th></th>
                <th></th>
              </React.Fragment>
            )}
          </tr>
          {this.props.common_exposure_cohorts.map((cohort, index) => {
            return (
              <tr key={index} id={`common-exposure-cohort-${index}`}>
                <td>{cohort.cohort_type}</td>
                <td>{cohort.cohort_name}</td>
                <td>{cohort.cohort_location}</td>
                {this.props.isEditable && (
                  <React.Fragment>
                    <td>
                      <Button
                        id={`common-exposure-cohort-edit-button-${index}`}
                        variant="link"
                        className="icon-btn-primary float-left p-0"
                        onClick={() => this.props.onEditCohort(index)}
                        aria-label={`Edit Common Exposure Cohort ${index + 1} Button`}>
                        <i className="fas fa-edit"></i>
                      </Button>
                    </td>
                    <td>
                      <Button
                        id={`common-exposure-cohort-delete-button-${index}`}
                        variant="link"
                        className="icon-btn-primary float-left p-0"
                        onClick={() => this.props.onDeleteCohort(index)}
                        aria-label={`Delete Common Exposure Cohort ${index + 1} Button`}>
                        <i className="fas fa-trash"></i>
                      </Button>
                    </td>
                  </React.Fragment>
                )}
              </tr>
            );
          })}
        </thead>
      </Table>
    );
  }
}

CommonExposureCohortsTable.propTypes = {
  common_exposure_cohorts: PropTypes.array,
  size: PropTypes.oneOf(['sm', 'lg']),
  isEditable: PropTypes.bool,
  onEditCohort: PropTypes.func,
  onDeleteCohort: PropTypes.func,
};

export default CommonExposureCohortsTable;
