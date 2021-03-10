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

  lastDateOfExposure: (
    <div>
      Used by the system to automatically calculate the End of Monitoring Date.
      <div>
        <i>Only relevant for Exposure Workflow</i>
      </div>
    </div>
  ),

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

  race: (
    <div>
      “Unknown” and “Refused to Answer” cannot be selected in combination with any other value for <i>Race</i>.
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
      Used to move records into the appropriate workflow.
      <ul className="mb-0">
        <li>
          {' '}
          For monitorees currently in the Exposure Workflow: Selecting Confirmed or Probable will prompt the option to move the monitoree into the Isolation
          Workflow or to end monitoring. Selecting Suspect, Unknown, or Not a Case will not change the monitoree&apos;s workflow.{' '}
        </li>
        <li>
          {' '}
          For monitorees currently in the Isolation Workflow: Selecting Suspect, Unknown, or Not a Case will move the monitoree to the exposure workflow.
          Selecting Confirmed or Probable will not change the monitoree&apos;s workflow.{' '}
        </li>
      </ul>
    </div>
  ),

  noSymptomHistory: <div>You must enter the lab result that provides evidence that this monitoree is a case.</div>,

  latestPublicHealthActionInExposure: (
    <div>
      Selecting any option other than <i>none</i> moves record from the symptomatic line list to the Person Under Investigation (PUI) line list in the exposure
      workflow. To move a record off the PUI line list, update <i>Case Status</i> based on the findings of the investigation.
    </div>
  ),

  latestPublicHealthActionInIsolation: (
    <div>
      Used to note the public health recommendation provided to a monitoree. In the isolation workflow, this element does not impact the line list on which this
      record appears.
    </div>
  ),

  assignedUser: (
    <div> Used to identify the user or group within a jurisdiction responsible for monitoring a monitoree (Values: 1-999999 for each jurisdiction). </div>
  ),

  assignedJurisdictionCanTransfer: (
    <div>
      The jurisdiction to which the monitoree is assigned. Because of the role you have been assigned, this field can be used to transfer records both within
      and outside of your assigned jurisdiction hierarchy.
    </div>
  ),

  assignedJurisdictionCannotTransfer: (
    <div>
      The jurisdiction to which the monitoree is assigned. Because of the role you have been assigned, this field can only be used to move records within your
      assigned jurisdiction hierarchy.
    </div>
  ),

  blockedSMS: (
    <div>
      The owner of this phone number has texted &quot;STOP&quot; in response to a Sara Alert text message. This means that this phone number cannot receive text
      messages from Sara Alert and should not be assigned SMS Preferred Reporting Methods unless the monitoree replies &quot;START&quot; to a Sara Alert
      message.
    </div>
  ),

  blockedSMSContactMethod: (
    <div>
      This Preferred Reporting Method is currently invalid because this phone number has blocked SMS communication with Sara Alert by texting &quot;STOP&quot;.
      To fix this issue, the monitoree may either select email or telephone as their Preferred Reporting Method or reply &quot;START&quot; to a Sara Alert
      message to unblock SMS communication.
    </div>
  ),

  continuousExposure: (
    <div>
      Allows a user to indicate that a monitoree has an ongoing exposure to one or more cases. If checked, the monitoring period will be extended indefinitely
      until unchecked or the <i>Last Date of Exposure</i> is updated.
    </div>
  ),

  // REPORTS

  exposureNeedsReviewColumn: (
    <div>
      The “Needs Review” column tells you which reports the system considers as symptomatic (red highlight). The “Review” and “Mark All As Reviewed” functions
      allow a user to tell the system not to consider that report as symptomatic. This indicates that the disease of interest is not suspected after review of
      the monitoree&apos;s symptom report(s).
      <br />
      The system will automatically generate the{' '}
      <i>
        <b>Symptom Onset</b>
      </i>{' '}
      Date as the date of the earliest symptomatic report (red highlight) that needs review unless a date has been entered by a user. Any report where “Needs
      Review” is “Yes” is considered symptomatic. To clear the symptomatic flag on a report(s), click “Review” or “Mark all as Reviewed” as appropriate.
    </div>
  ),

  exposureSymptomOnset: (
    <div>
      <b>Exposure Workflow</b>
      <br />
      <i>
        <b>Symptom Onset</b>
      </i>{' '}
      date is used by the system to determine if a record should appear on the <i>Symptomatic</i> line list. This field is auto-populated with the date of the
      earliest report flagged as symptomatic (red highlighted) in the report history table <i>unless a date has been entered by a user.</i>
      <br />A{' '}
      <i>
        <b>Symptom Onset</b>
      </i>{' '}
      date should only be entered by a user in the exposure workflow if the monitoree is under investigation for the disease of interest and the monitoree
      indicates their symptom onset date differs from what is available in the reports table. If a user entered a symptom onset date, the field will need to be
      manually cleared by a user to move the record off of the <i>Symptomatic</i> line list.
      <br />
      To clear an auto-populated{' '}
      <i>
        <b>Symptom Onset</b>
      </i>{' '}
      date, click “Review” or “Mark all as Reviewed” as appropriate. The “Review” function tells the system not to consider a report as symptomatic.{' '}
    </div>
  ),

  isolationSymptomOnset: (
    <div>
      <b>Isolation Workflow</b>
      <br />
      <i>
        <b>Symptom Onset</b>
      </i>{' '}
      date is used by the system to determine if the non-test based recovery definition has been met which determines if a record should appear on the{' '}
      <i>Records Requiring Review </i>line list. This field is auto-populated with the date of the earliest report flagged as symptomatic (red highlighted) in
      the report history table <i>unless a date has been entered by a user.</i>
      <br />
      If a record is moved from the isolation workflow to the exposure workflow (e.g., case ruled out and returned to monitoring due to exposure), the system
      will clear a user entered{' '}
      <i>
        <b>Symptom Onset</b>
      </i>{' '}
      date. This allows the system to place a monitoree on the appropriate monitoring line list in the exposure workflow based on the symptom reports received.{' '}
    </div>
  ),

  extendedIsolation: (
    <div>
      Used by the system to determine eligibility to appear on the <i>Records Requiring Review</i> line list. A case cannot appear on the{' '}
      <i>Records Requiring Review</i> line list until after the user-specified date. This field may be blank.
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

  exposure_non_reporting: (
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
  isolation_records_requiring_review: (
    <div>
      These cases meet one of the recovery definitions and require review by public health to validate that it is safe to discontinue isolation. The recovery
      definition logic has been designed to be sensitive; as a result, cases that do not meet requirements for recovery may appear. To view which recovery
      definition was met, open the record and view the reports section. Follow-up with these cases should be based on current guidelines and available
      resources.
    </div>
  ),

  isolation_non_reporting: (
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
  analyticsAgeTip: (
    <div>
      Current Age is calculated as:
      <div>Current Date - Date of Birth</div>
    </div>
  ),
};

class InfoTooltip extends React.Component {
  constructor(props) {
    super(props);
    // If multiple instances of the Tooltip Exist on a page, the <ReactTooltip/> cannnot find
    // the correct instance (due to the lack of `data-for`/`id` pairs). Therefore we generate
    // custom string for each instance
    this.customID = this.makeid(this.props.tooltipTextKey?.length || 10).substring(0, 6);
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
          {this.props.tooltipTextKey && <span>{TOOLTIP_TEXT[this.props.tooltipTextKey]}</span>}
          {!this.props.tooltipTextKey && this.props.getCustomText && <span>{this.props.getCustomText()}</span>}
        </ReactTooltip>
      </div>
    );
  }
}

InfoTooltip.propTypes = {
  tooltipTextKey: PropTypes.string,
  getCustomText: PropTypes.func,
  location: PropTypes.string, // top, right, bottom, left
};

export default InfoTooltip;
