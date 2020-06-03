import React from 'react';
import { PropTypes } from 'prop-types';
import ReactTooltip from 'react-tooltip';

// When adding a new tooltip in the UI create an entry in this object, and pass in the entry `key` as props
const TOOLTIP_TEXT = {
  caseStatus: (
    <div>
      Used to move records into the appropriate workflow after investigating a report of symptoms. If <i>confirmed</i> or <i>probable</i> is selected, the user
      is prompted to choose between moving the record to the isolation workflow or to end monitoring. If the user selects another case status, the record will
      be returned to the appropriate exposure monitoring line list.
    </div>
  ),

  monitoringStatus: (
    <div>
      If set to{' '}
      <i>
        <b>Actively Monitoring</b>
      </i>
      , the system moves the record to the appropriate line list based on reporting history and latest public health actions. The system will send daily report
      reminders if the record is not on the <i>PUI</i> (exposure) or <i>Records Requiring Review</i> (isolation) line lists. If set to{' '}
      <i>
        <b>Not Monitoring</b>
      </i>
      , the system moves the record to the <i>Closed</i> line list and stops sending daily reminders.
    </div>
  ),

  latestPublicHealthAction: (
    <div>
      Selecting any option other than <i>none</i> moves record from the symptomatic line list to the Person Under Investigation (PUI) line list in the exposure
      workflow. To move a record off the PUI line list, update <i>Case Status</i> based on the findings of the investigation.
    </div>
  ),

  symptomOnset: (
    <div>
      {' '}
      Used by the system to determine if the non-test based recovery definition in the isolation monitoring workflow has been met. This field is auto-populated
      with the date of the earliest symptomatic report in the system unless a user enters an earlier date.{' '}
    </div>
  ),

  purgeDate: (
    <div>
      {' '}
      In order to minimize the amount of identifiable information stored on the production servers, Sara Alert will purge identifiers in records for which there
      have been no updates for a defined time period, provided that monitoree is no longer being actively monitored. An update includes any action on the
      record, including adding comments or updating any fields. Local administrators are sent weekly email reminders about records that meet this definition.
      See User Guide for list of fields that are not purged for use in the analytics summary.{' '}
    </div>
  ),

  lastDateOfExposure: <div> Used by the system to automatically calculate the monitoring period. </div>,

  assignedUser: <div> Used to group monitorees within a jurisdiction. (1-9999) </div>,
};

class InfoTooltip extends React.Component {
  constructor(props) {
    super(props);
    // If multiple instances of the Tooltip Exist on a page, the <ReactTooltip/> cannnot find
    // the correct instance (due to the lack of `data-for`/`id` pairs). Therefore we generate
    // custom string for each instance
    this.customID = this.makeid(this.props.tooltipTextKey.length || 10).substring(0, 6);
  }

  makeid = length => {
    let result = '';
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (let i = 0; i < length; ++i) {
      result += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    return result;
  };

  render() {
    return (
      <div style={{ display: 'inline' }}>
        <span data-for={this.customID} data-tip="" className="ml-1">
          <i className="fas fa-question-circle px-0"></i>
        </span>
        <ReactTooltip id={this.customID} multiline={true} place={this.props.location} type="dark" effect="solid" className="tooltip-container">
          <span>{TOOLTIP_TEXT[this.props.tooltipTextKey]}</span>
        </ReactTooltip>
      </div>
    );
  }
}

InfoTooltip.propTypes = {
  tooltipTextKey: PropTypes.string,
  location: PropTypes.string, // top, right, bottom, left
};

export default InfoTooltip;
