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
          jurisdiction_paths={this.props.jurisdiction_paths}
          advanced_filter_options={this.props.advanced_filter_options}
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
          jurisdiction_paths={this.props.jurisdiction_paths}
          workflow={this.props.workflow}
          jurisdiction={this.props.jurisdiction}
          tabs={this.props.tabs}
          default_tab={this.props.default_tab}
          monitoring_reasons={this.props.monitoring_reasons}
          advanced_filter_options={this.props.advanced_filter_options}
          setQuery={query => this.setState({ query })}
          setFilteredMonitoreesCount={current_monitorees_count => this.setState({ current_monitorees_count })}
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
  advanced_filter_options: PropTypes.array,
  custom_export_options: PropTypes.object,
  monitoring_reasons: PropTypes.array,
};

export default PublicHealthDashboard;
