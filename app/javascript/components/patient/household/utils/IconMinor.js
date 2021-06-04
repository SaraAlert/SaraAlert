import React from 'react';
import PropTypes from 'prop-types';
import ReactTooltip from 'react-tooltip';

class IconMinor extends React.Component {
  render() {
    return (
      <React.Fragment>
        <span data-for={`${this.props.patientId}-is-minor`} data-tip="" className={this.props.customClass}>
          <i className="fas fa-child" />
        </span>
        <ReactTooltip id={`${this.props.patientId}-is-minor`} multiline={true} place="right" type="dark" effect="solid">
          <span>Monitoree is under 18</span>
        </ReactTooltip>
      </React.Fragment>
    );
  }
}

IconMinor.propTypes = {
  patientId: PropTypes.string,
  customClass: PropTypes.string,
};

export default IconMinor;
