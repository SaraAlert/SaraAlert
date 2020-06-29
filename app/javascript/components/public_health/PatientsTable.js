import React from 'react';
import { Badge, Card, Nav, TabContent } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

import InfoTooltip from '../util/InfoTooltip';

class PatientsTable extends React.Component {
  constructor(props) {
    super(props);
    this.handleTabSelect = this.handleTabSelect.bind(this);
    this.state = {
      tab: props.tabs[0],
    };
  }

  componentDidMount() {
    const savedTabName = localStorage.getItem(`${this.props.workflow}Tab`);
    if (savedTabName === null || !this.props.tabs.map(tab => tab.name).includes(savedTabName)) {
      localStorage.setItem(`${this.props.workflow}Tab`, this.props.tabs[0].name);
    } else {
      this.handleTabSelect(savedTabName);
    }
  }

  handleTabSelect(tabName) {
    this.setState({ tab: this.props.tabs.filter(tab => tab.name === tabName)[0] }, () => {
      localStorage.setItem(`${this.props.workflow}Tab`, tabName);
    });
  }

  render() {
    return (
      <div className="mx-2 pb-4">
        <Nav variant="tabs" activeKey={this.state.tab.name}>
          {this.props.tabs.map(tab => {
            return (
              <Nav.Item key={tab.name} className={tab.name === 'all' ? 'ml-auto' : ''}>
                <Nav.Link eventKey={tab.name} onSelect={this.handleTabSelect}>
                  {tab.label}{' '}
                  <Badge variant={tab.variant} className="badge-larger-font">
                    {tab.total}
                  </Badge>
                </Nav.Link>
              </Nav.Item>
            );
          })}
        </Nav>
        <TabContent>
          <Card>
            <div className="lead px-4 pt-4 pb-3 mb-2">
              {this.state.tab.description} You are currently in the <u>{this.props.workflow}</u> workflow.
              {this.state.tab.tooltip && <InfoTooltip tooltipTextKey={this.state.tab.tooltip} location="right"></InfoTooltip>}
            </div>
          </Card>
        </TabContent>
      </div>
    );
  }
}

PatientsTable.propTypes = {
  workflow: PropTypes.oneOf(['exposure', 'isolation']),
  tabs: PropTypes.array,
};

export default PatientsTable;
