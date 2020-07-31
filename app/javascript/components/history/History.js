import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import moment from 'moment-timezone';

import { time_ago_in_words } from './helpers';

const history = ({ history }) => {
  return (
    <Card className="card-square mt-4 mx-3 shadow-sm">
      <Card.Header>
        <b>{history.created_by}</b>, {time_ago_in_words(moment(history.created_at).toDate())} ago (
        {moment
          .tz(history.created_at, 'UTC')
          .tz(moment.tz.guess())
          .format('YYYY-MM-DD HH:mm z')}
        )
        <span className="float-right">
          <h5 className="badge-padding">
            <span className="badge badge-secondary">{history.history_type}</span>
          </h5>
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
