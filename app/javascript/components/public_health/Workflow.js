import React from 'react';
import { PropTypes } from 'prop-types';

import axios from 'axios';

import PublicHealthHeader from './PublicHealthHeader';
import PatientsTable from './PatientsTable';

class Workflow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      jurisdiction_paths: {},
      query: {},
      current_monitorees_count: 0,
    };
  }

  componentDidMount() {
    axios.get(`${window.BASE_PATH}/jurisdictions/paths`).then(response => {
      this.setState({ jurisdiction_paths: response.data.jurisdiction_paths });
    });
  }

  render() {
    return (
      <React.Fragment>
        <PublicHealthHeader
          authenticity_token={this.props.authenticity_token}
          jurisdiction_paths={this.state.jurisdiction_paths}
          workflow={this.props.workflow}
          jurisdiction={this.props.jurisdiction}
          tabs={this.props.tabs}
          abilities={this.props.abilities}
          query={this.state.query}
          current_monitorees_count={this.state.current_monitorees_count}
          custom_export_options={this.props.custom_export_options}
          available_workflows={this.props.available_workflows}
          available_line_lists={this.props.available_line_lists}
          playbook={this.props.playbook}
          header_action_buttons={this.props.header_action_buttons}
          monitoring_dashboard_buttons={this.props.monitoring_dashboard_buttons}
        />
        <PatientsTable
          authenticity_token={this.props.authenticity_token}
          jurisdiction_paths={this.state.jurisdiction_paths}
          playbook={this.props.playbook}
          workflow={this.props.workflow}
          jurisdiction={this.props.jurisdiction}
          tabs={this.props.tabs}
          default_tab={this.props.default_tab}
          monitoring_reasons={this.props.monitoring_reasons}
          setQuery={query => this.setState({ query })}
          setFilteredMonitoreesCount={current_monitorees_count => this.setState({ current_monitorees_count })}
          available_workflows={this.props.available_workflows}
        />
      </React.Fragment>
    );
  }
}

Workflow.propTypes = {
  authenticity_token: PropTypes.string,
  abilities: PropTypes.object,
  jurisdiction: PropTypes.object,
  workflow: PropTypes.string,
  tabs: PropTypes.object,
  default_tab: PropTypes.string,
  custom_export_options: PropTypes.object,
  monitoring_reasons: PropTypes.array,
  available_workflows: PropTypes.array,
  available_line_lists: PropTypes.object,
  playbook: PropTypes.string,
  header_action_buttons: PropTypes.object,
  monitoring_dashboard_buttons: PropTypes.object,
};

export default Workflow;
