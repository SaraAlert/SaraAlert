import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, InputGroup, OverlayTrigger, Tooltip } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

class JurisdictionFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      jurisdiction_path: props.jurisdiction_paths[props.jurisdiction] || '',
    };
  }

  handleJurisdictionChange = jurisdiction_path => {
    this.setState({ jurisdiction_path }, () => {
      const jurisdiction = Object.keys(this.props.jurisdiction_paths).find(id => this.props.jurisdiction_paths[parseInt(id)] === jurisdiction_path);
      if (jurisdiction) {
        this.props.onJurisdictionChange(parseInt(jurisdiction));
      }
    });
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
          defaultValue={this.props.jurisdiction_paths[this.props.jurisdiction] || ''}
          onChange={event => this.handleJurisdictionChange(event?.target?.value)}
        />
        <datalist id="jurisdiction_paths">
          {Object.entries(this.props.jurisdiction_paths).map(([id, path]) => {
            return (
              <option value={path} key={id}>
                {path}
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
