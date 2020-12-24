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
    axios.get('/jurisdictions/paths').then(response => {
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
        />
        <PatientsTable
          authenticity_token={this.props.authenticity_token}
          jurisdiction_paths={this.state.jurisdiction_paths}
          workflow={this.props.workflow}
          jurisdiction={this.props.jurisdiction}
          tabs={this.props.tabs}
          monitoring_reasons={this.props.monitoring_reasons}
          setQuery={query => this.setState({ query })}
          setFilteredMonitoreesCount={current_monitorees_count => this.setState({ current_monitorees_count })}
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
  custom_export_options: PropTypes.object,
  monitoring_reasons: PropTypes.array,
};

export default Workflow;
