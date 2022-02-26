import React from 'react';
import { PropTypes } from 'prop-types';
import PublicHealthHeader from './PublicHealthHeader';
import PatientsTable from '../patient/PatientsTable';

class PublicHealthDashboard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      query: {},
      current_monitorees_count: 0,
    };
  }

  render() {
    return (
      <React.Fragment>
        <PublicHealthHeader
          authenticity_token={this.props.authenticity_token}
          all_assigned_users={this.props.all_assigned_users}
          jurisdiction_paths={this.props.jurisdiction_paths}
          workflow={this.props.workflow}
          jurisdiction={this.props.jurisdiction}
          tabs={this.props.tabs}
          abilities={this.props.abilities}
          query={this.state.query}
          current_monitorees_count={this.state.current_monitorees_count}
          custom_export_options={this.props.custom_export_options}
          vaccine_standards={this.props.vaccine_standards}
        />
        <PatientsTable
          authenticity_token={this.props.authenticity_token}
          jurisdiction_paths={this.props.jurisdiction_paths}
          all_assigned_users={this.props.all_assigned_users}
          workflow={this.props.workflow}
          jurisdiction={this.props.jurisdiction}
          tabs={this.props.tabs}
          default_tab={this.props.default_tab}
          monitoring_reasons={this.props.monitoring_reasons}
          setQuery={query => this.setState({ query })}
          setFilteredMonitoreesCount={current_monitorees_count => this.setState({ current_monitorees_count })}
          vaccine_standards={this.props.vaccine_standards}
        />
      </React.Fragment>
    );
  }
}

PublicHealthDashboard.propTypes = {
  authenticity_token: PropTypes.string,
  abilities: PropTypes.object,
  jurisdiction: PropTypes.object,
  workflow: PropTypes.string,
  tabs: PropTypes.object,
  default_tab: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  all_assigned_users: PropTypes.array,
  custom_export_options: PropTypes.object,
  monitoring_reasons: PropTypes.array,
  vaccine_standards: PropTypes.object,
};

export default PublicHealthDashboard;
