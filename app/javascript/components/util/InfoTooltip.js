import React from 'react';
import { PropTypes } from 'prop-types';
import ReactTooltip from 'react-tooltip';

// When adding a new tooltip in the UI create an entry in this object, and pass in the entry `key` as props
const TOOLTIP_TEXT = {
  // MONITOREE DETAILS
  preferredContactTime: (
    <div>
      The monitoree will be sent a reminder as soon as they move to non-reporting. If monitorees home address state is left blank, the Eastern time zone is used
      for preferred contact time by default. If preferred contact time is left blank, reminders will be sent during the afternoon contact times listed below.
    </div>
  ),

  lastDateOfExposure: <div> Used by the system to automatically calculate the monitoring period. </div>,

  primaryLanguage: (
    <div>
      <i>Primary Language</i> is used to determine the translations for what the monitoree sees/hears. If a language is not fully supported, a warning to users
      will appear.
    </div>
  ),

  secondaryLanguage: (
    <div>
      <i>Secondary Language</i> is not used to determine which language the system sends messages to the monitoree in. Information in this field can be used to
      inform interpretation needs.
    </div>
  ),

  sexAtBirth: (
    <div>
      This is the monitoree&apos;s legal sex, sometimes referred to as biological sex. Ask the monitoree &quot;What sex was originally listed on your birth
      certificate?&quot;
    </div>
  ),

  sexualOrientation: (
    <div>
      Allows collection of information to help address potential health disparities and identify any specific health care needs. Describes who the person is
      attracted to. Assure the monitoree that the information will be kept confidential. Ask the monitoree &quot;Do you think of yourself as...&quot; and
      provide the options for sexual orientation that are listed.
    </div>
  ),

  genderIdentity: (
    <div>
      Allows collection of information to help address potential health disparities and identify any specific health care needs. Relates to a person’s internal
      sense of their gender. Assure the monitoree that the information will be kept confidential. Ask the monitoree &quot;What gender do you identify
      with...&quot; and provide the options for gender identity that are listed.
    </div>
  ),

  // MONITORING ACTIONS
  monitoringStatus: (
    <div>
      If set to{' '}
      <i>
        <b>Actively Monitoring</b>
      </i>
      , the system moves the record to the appropriate line list based on reporting history and latest public health actions. The system will send daily report
      reminders if the record is not on the <i>Records Requiring Review</i> (isolation) line list. If set to{' '}
      <i>
        <b>Not Monitoring</b>
      </i>
      , the system moves the record to the <i>Closed</i> line list and stops sending daily reminders.
    </div>
  ),

  exposureRiskAssessment: (
    <div>
      Used to prioritize responses to symptomatic and non-reporting individuals. This element does not impact the type or frequency of messages sent by the
      system to monitorees.
    </div>
  ),

  monitoringPlan: (
    <div>
      Used to prioritize responses to symptomatic and non-reporting individuals in the exposure workflow. This element does not impact the type or frequency of
      messages sent by the system to monitorees.
    </div>
  ),

  caseStatus: (
    <div>
      Used to move records into the appropriate workflow after investigating a report of symptoms. If <i>confirmed</i> or <i>probable</i> is selected, the user
      is prompted to choose between moving the record to the isolation workflow or to end monitoring. If the user selects another case status, the record will
      be returned to the appropriate exposure monitoring line list.
    </div>
  ),

  latestPublicHealthAction: (
    <div>
      Selecting any option other than <i>none</i> moves record from the symptomatic line list to the Person Under Investigation (PUI) line list in the exposure
      workflow. To move a record off the PUI line list, update <i>Case Status</i> based on the findings of the investigation.
    </div>
  ),

  assignedUser: (
    <div> Used to identify the user or group within a jurisdiction responsible for monitoring a monitoree (Values: 1-9999 for each jurisdiction). </div>
  ),

  assignedJurisdiction: (
    <div>
      This controls which users have access to records. Users can access records associated with their assigned jurisdiction and records assigned to any
      jurisdictions below theirs in the jurisdictional hierarchy defined by each agency before onboarding.
    </div>
  ),

  // REPORTS
  symptomOnset: (
    <div>
      {' '}
      Used by the system to determine if the non-test based recovery definition in the isolation monitoring workflow has been met. This field is auto-populated
      with the date of the earliest symptomatic report in the system unless a user enters an earlier date.{' '}
    </div>
  ),

  endOfMonitoring: (
    <div>
      Calculated by the system based on Last Date of Exposure
      <div>
        <i>Only relevent for Exposure Workflow</i>
      </div>
    </div>
  ),

  // REQUIRES REVIEW RECOVERY LOGIC
  asymptomaticNonTestBased: (
    <div>At least 10 days have passed since the specimen collection date of a positive laboratory test and the monitoree has never reported symptoms.</div>
  ),

  symptomaticNonTestBased: (
    <div>
      At least 10 days have passed since the symptom onset date and at least 24 hours have passed since the case last reported “Yes” for fever or use of
      fever-reducing medicine to the system. The system does not collect information on severity of symptoms. Public health will need to validate if other
      symptoms have improved.
    </div>
  ),

  testBased: (
    <div>
      Two negative laboratory results have been documented and at least 24 hours have passed since the case last reported “Yes” for fever or use of
      fever-reducing medicine to the system. The system does not validate the type of test, time between specimen collection, or if the tests were consecutive.
      Public health will need to validate that the test results meet the latest guidance prior to discontinuing isolation. The system does not collect
      information on severity of symptoms. Public health will also need to validate if other symptoms have improved.
    </div>
  ),

  // LAB RESULTS
  labResults: (
    <div>
      Lab Results are used in the isolation workflow to determine if a case might meet the test-based or asymptomatic non-test based recovery definitions.
    </div>
  ),

  closeContacts: (
    <div>
      Close Contacts can be added whenever a user does not have the information required to complete enrollment of the contact into the exposure workflow. A
      user must complete enrollment of any Close Contact before the system will start to send daily notifications to that individual.
    </div>
  ),

  // HISTORY
  history: (
    <div>
      Use to view past changes made by users and a log of system contact attempts. Comments can be added to this section to document information not captured
      elsewhere.
    </div>
  ),

  // EXPOSURE WORKFLOW LINE LIST DEFINITIONS
  exposure_symptomatic: (
    <div>
      Monitorees on this list require public health follow-up to determine if disease is suspected. Follow-up should be based on current guidelines and
      available resources.
    </div>
  ),

  exposure_nonReporting: (
    <div>
      Monitorees on this list require public health follow-up to collect missing symptom report(s). Follow-up with these monitorees should be based on current
      guidelines and available resources.
    </div>
  ),

  exposure_asymptomatic: <div>Monitorees on this list do not require public health follow-up unless otherwise indicated.</div>,

  exposure_under_investigation: (
    <div>
      A ‘Latest Public Health Action’ other than “None” has been documented in the monitoree’s record. Monitorees on this list do not receive daily reminder
      notifications because they are already being contacted by public health.
    </div>
  ),

  exposure_closed: (
    <div>
      Monitorees on this list do not receive daily reminder notifications. Records on this list are accessible by users until the expected purge date. Your
      local administrator receives a weekly email notification about records eligible for purge and will coordinate with a public health user to export records
      for local retention before purge (if necessary).
    </div>
  ),

  // ISOLATION WORKFLOW LINE LIST DEFINITIONS
  isolation_recordsRequiringReview: (
    <div>
      These cases meet one of the recovery definitions and require review by public health to validate that it is safe to discontinue isolation. The recovery
      definition logic has been designed to be sensitive; as a result, cases that do not meet requirements for recovery may appear. To view which recovery
      definition was met, open the record and view the reports section. Follow-up with these cases should be based on current guidelines and available
      resources.
    </div>
  ),

  isolation_nonReporting: (
    <div>
      Monitorees on this list require public health follow-up to collect missing symptom report(s). Follow-up with these cases should be based on current
      guidelines and available resources.
    </div>
  ),

  isolation_reporting: <div>Monitorees on this list do not require public health follow-up unless otherwise indicated.</div>,

  isolation_closed: (
    <div>
      Cases on this list do not receive notifications. Records on this list are accessible by users until the expected purge date. Your local administrator
      receives a weekly email notification about records eligible for purge and will coordinate with a public health user to export records for local retention
      before purge (if necessary).
    </div>
  ),

  // CLOSED TABLE HEADERS
  purgeDate: (
    <div>
      {' '}
      In order to minimize the amount of identifiable information stored on the production servers, Sara Alert will purge identifiers in records for which there
      have been no updates for a defined time period, provided that monitoree is no longer being actively monitored. An update includes any action on the
      record, including adding comments or updating any fields. Local administrators are sent weekly email reminders about records that meet this definition.
      See User Guide for list of fields that are not purged for use in the analytics summary.{' '}
    </div>
  ),
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
        <span data-testid="info_tooltip" data-for={this.customID} data-tip="" className="ml-1">
          <i className="fas fa-question-circle px-0"></i>
        </span>
        <ReactTooltip id={this.customID} multiline={true} place={this.props.location} type="dark" effect="solid" className="tooltip-container">
          <span data-testid="info_tooltip_text">{TOOLTIP_TEXT[this.props.tooltipTextKey]}</span>
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
