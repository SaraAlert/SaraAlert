import React from 'react';
import { Card } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import History from './History';

class HistoryComponent extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    const historyArray = this.props.histories.map(history => <History key={history.id} history={history} />);

    return (
      <React.Fragment>
        <Card className="mx-2 mt-3 mb-4 card-square">
          <Card.Header>
            <h5>History</h5>
          </Card.Header>
          <Card.Body>
            {historyArray}
            <Card className="mb-4 mt-4 mx-3 card-square shadow-sm">
              <Card.Header>Add Comment</Card.Header>
              <Card.Body>
                <form action="/histories" method="post">
                  <input type="hidden" name="authenticity_token" value={this.props.authenticity_token} />
                  <input name="patient_id" type="hidden" value={this.props.patient_id} />
                  <textarea id="comment" name="comment" className="form-control" style={{ resize: 'none' }} rows="3" placeholder="enter comment here..." />
                  <button type="submit" className="mt-3 btn btn-primary btn-square float-right">
                    <i className="fas fa-comment-dots"></i> Add Comment
                  </button>
                </form>
              </Card.Body>
            </Card>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

HistoryComponent.propTypes = {
  patient_id: PropTypes.number,
  histories: PropTypes.array,
  authenticity_token: PropTypes.string,
};

export default HistoryComponent;
