import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, InputGroup, OverlayTrigger, Tooltip } from 'react-bootstrap';
import _ from 'lodash';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

class JurisdictionFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      sorted_jurisdiction_paths: [],
      jurisdiction_path: props.jurisdiction_paths[props.jurisdiction] || '',
      jurisdiction_input: props.jurisdiction_paths[props.jurisdiction] || '',
    };
  }

  static getDerivedStateFromProps(nextProps) {
    return {
      sorted_jurisdiction_paths: _.values(nextProps.jurisdiction_paths).sort((a, b) => a.localeCompare(b)),
    };
  }

  // This update is necessary since sticky settings are loaded after this component is constructed
  componentDidUpdate() {
    if (this.state.jurisdiction_path !== this.props.jurisdiction_paths[this.props.jurisdiction]) {
      this.setState({ jurisdiction_path: this.props.jurisdiction_paths[this.props.jurisdiction] });
      this.setState({ jurisdiction_input: this.props.jurisdiction_paths[this.props.jurisdiction] });
    }
  }

  // Handle changes to jurisdiction_path and jurisdiction_input separately so that the user can backspace into the form input
  handleJurisdictionChange = event => {
    const value = event.target.value;
    const jurisdiction = Object.keys(this.props.jurisdiction_paths).find(id => this.props.jurisdiction_paths[parseInt(id)] === event.target.value);

    this.setState({ jurisdiction_input: value });

    if (jurisdiction) {
      this.setState({ jurisdiction_path: value }, () => {
        this.props.onJurisdictionChange(parseInt(jurisdiction));
      });
    }
  };

  handleScopeChange = scope => {
    this.props.onScopeChange(scope);
  };

  render() {
    return (
      <InputGroup size="sm">
        <InputGroup.Prepend>
          <InputGroup.Text className="rounded-0">
            <FontAwesomeIcon icon="map-marked-alt" />
            <span className="ml-1">{this.props.label || 'Jurisdiction'}</span>
          </InputGroup.Text>
        </InputGroup.Prepend>
        <Form.Control
          id="jurisdiction_path"
          aria-label="Jurisdiction Filter"
          type="text"
          autoComplete="off"
          list="jurisdiction_paths"
          value={this.state.jurisdiction_input}
          onChange={this.handleJurisdictionChange}
        />
        <datalist id="jurisdiction_paths">
          {this.state.sorted_jurisdiction_paths.map((jurisdiction, index) => {
            return (
              <option value={jurisdiction} key={index}>
                {jurisdiction}
              </option>
            );
          })}
        </datalist>
        <React.Fragment>
          <OverlayTrigger overlay={<Tooltip>Include Sub-Jurisdictions</Tooltip>}>
            <Button
              id="allJurisdictions"
              size="sm"
              variant={this.props.scope === 'all' ? 'primary' : 'outline-secondary'}
              style={{ outline: 'none', boxShadow: 'none' }}
              onClick={() => this.handleScopeChange('all')}>
              All
            </Button>
          </OverlayTrigger>
          <OverlayTrigger overlay={<Tooltip>Exclude Sub-Jurisdictions</Tooltip>}>
            <Button
              id="exactJurisdiction"
              size="sm"
              variant={this.props.scope === 'exact' ? 'primary' : 'outline-secondary'}
              style={{ outline: 'none', boxShadow: 'none' }}
              onClick={() => this.handleScopeChange('exact')}>
              Exact
            </Button>
          </OverlayTrigger>
        </React.Fragment>
      </InputGroup>
    );
  }
}

JurisdictionFilter.propTypes = {
  label: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  jurisdiction: PropTypes.number,
  scope: PropTypes.string,
  onJurisdictionChange: PropTypes.func,
  onScopeChange: PropTypes.func,
};

export default JurisdictionFilter;
