import React from 'react';
import PropTypes from 'prop-types';
import { Badge } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';

class BadgeHOH extends React.Component {
  render() {
    return (
      <React.Fragment>
        <span data-for={`${this.props.patientId}-hoh`} data-tip="" className={this.props.customClass}>
          <Badge variant="dark">
            <span>HoH</span>
          </Badge>
        </span>
        <ReactTooltip id={`${this.props.patientId}-hoh`} multiline={true} place={this.props.location} type="dark" effect="solid" className="tooltip-container">
          <span>Monitoree is Head of Household that reports on behalf of household members</span>
        </ReactTooltip>
      </React.Fragment>
    );
  }
}

BadgeHOH.propTypes = {
  patientId: PropTypes.string,
  customClass: PropTypes.string,
  location: PropTypes.string,
};

export default BadgeHOH;
