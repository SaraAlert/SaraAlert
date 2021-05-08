import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert } from 'react-bootstrap';
import { Beforeunload } from 'react-beforeunload';

import axios from 'axios';

class Viewers extends React.Component {
  constructor(props) {
    super(props);
  }

  onUnload = () => {
    axios.post(window.BASE_PATH + `/patients/${this.props.patient_id}/on_unload`);
  };

  render() {
    return (
      <React.Fragment>
        {this.props.viewers?.length > 0 && (
          <Alert className="mx-2 text-truncate" key="multiple-warning" id="multiple-warning" variant="info">
            {this.props.viewers?.length === 1 ? 'Another user' : 'Multiple users'} currently have this monitoree record open: {this.props.viewers?.join(', ')}
          </Alert>
        )}
        <Beforeunload onBeforeunload={() => this.onUnload()} />
      </React.Fragment>
    );
  }
}

Viewers.propTypes = {
  patient_id: PropTypes.number,
  viewers: PropTypes.array,
};

export default Viewers;
