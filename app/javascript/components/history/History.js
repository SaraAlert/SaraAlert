import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';

import { formatTimestamp } from '../../utils/DateTime';
import moment from 'moment-timezone';
import { time_ago_in_words } from './helpers';

const history = ({ history }) => {
  return (
    <Card className="card-square mt-4 mx-3 shadow-sm">
      <Card.Header>
        <b>{history.created_by}</b>, {time_ago_in_words(moment(history.created_at).toDate())} ago ({formatTimestamp(history.created_at)})
        <span className="float-right">
          <div className="badge-padding h5">
            <span className="badge badge-secondary">{history.history_type}</span>
          </div>
        </span>
      </Card.Header>
      <Card.Body>
        <Card.Text>{history.comment}</Card.Text>
      </Card.Body>
    </Card>
  );
};

history.propTypes = {
  history: PropTypes.object,
};

export default history;
