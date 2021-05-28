import React from 'react';
import PropTypes from 'prop-types';
import ReactTooltip from 'react-tooltip';

class BadgeHoH extends React.Component {
  render() {
    return (
      <React.Fragment>
        <span data-for={`${this.props.patientId}-is-minor`} data-tip="" className={this.props.customClass}>
          <i className="fas fa-child" />
        </span>
        <ReactTooltip id={`${this.props.patientId}-is-minor`} multiline={true} place={this.props.location} type="dark" effect="solid">
          <span>Monitoree is a minor</span>
        </ReactTooltip>
      </React.Fragment>
    );
  }
}

BadgeHoH.propTypes = {
  patientId: PropTypes.string,
  customClass: PropTypes.string,
  location: PropTypes.string,
};

export default BadgeHoH;
