import React from 'react';
import { PropTypes } from 'prop-types';

import PublicHealthHeader from './PublicHealthHeader';
import PatientsTable from './PatientsTable';

class Workflow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      query: {},
      filteredMonitoreesCount: 0,
    };
  }

  render() {
    return (
      <React.Fragment>
        <PublicHealthHeader
          authenticity_token={this.props.authenticity_token}
          workflow={this.props.workflow}
          abilities={this.props.abilities}
          query={this.state.query}
          filteredMonitoreesCount={this.state.filteredMonitoreesCount}
        />
        <PatientsTable
          authenticity_token={this.props.authenticity_token}
          workflow={this.props.workflow}
          jurisdiction={this.props.jurisdiction}
          tabs={this.props.tabs}
          setQuery={query => this.setState({ query })}
          setFilteredMonitoreesCount={filteredMonitoreesCount => this.setState({ filteredMonitoreesCount })}
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
};

export default Workflow;
