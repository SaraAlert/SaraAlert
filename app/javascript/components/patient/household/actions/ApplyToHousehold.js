import React from 'react';
import { PropTypes } from 'prop-types';
import { Form } from 'react-bootstrap';
import HouseholdMemberTable from '../HouseholdMemberTable';

class ApplyToHousehold extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      applyToHousehold: false,
    };
  }

  /**
   * Handles change of apply to household radio buttons. Shows child table based on selection.
   * @param {SyntheticEvent} event - Event when the search input changes
   */
  handleChange = event => {
    let applyToHousehold = event.target.id === 'apply_to_household_yes';
    this.setState({ applyToHousehold }, () => {
      this.props.handleApplyHouseholdChange(applyToHousehold);
    });
  };

  render() {
    return (
      <React.Fragment>
        <p className="mb-2">Apply this change to:</p>
        <Form.Group>
          <Form.Check
            type="radio"
            name="apply_to_household"
            id="apply_to_household_no"
            label="This monitoree only"
            onChange={this.handleChange}
            checked={!this.state.applyToHousehold}
          />
          <Form.Check
            type="radio"
            name="apply_to_household"
            id="apply_to_household_yes"
            label="This monitoree and selected household members"
            onChange={this.handleChange}
            checked={this.state.applyToHousehold}
          />
        </Form.Group>
        {this.state.applyToHousehold && (
          <HouseholdMemberTable
            household_members={this.props.household_members}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            isSelectable={true}
            handleApplyHouseholdChange={this.props.handleApplyHouseholdChange}
            handleApplyHouseholdIdsChange={this.props.handleApplyHouseholdIdsChange}
            workflow={this.props.workflow}
            continuous_exposure_enabled={this.props.continuous_exposure_enabled}
          />
        )}
      </React.Fragment>
    );
  }
}

ApplyToHousehold.propTypes = {
  household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  handleApplyHouseholdChange: PropTypes.func,
  handleApplyHouseholdIdsChange: PropTypes.func,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default ApplyToHousehold;
