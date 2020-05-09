import React from 'react';
import { Card } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import History from './History';
import Select from 'react-select';
import Pagination from 'jw-react-pagination';

class HistoryComponent extends React.Component {
  constructor(props) {
    super(props);

    // bind the onChangePage method to this React component
    this.onChangePage = this.onChangePage.bind(this);

    this.state = {
      selectedFilters: [],
      filteredHistories: this.props.histories,
      pageOfHistories: [],
    };
  }

  onChangePage(pageOfHistories) {
    this.setState({ pageOfHistories });
  }

  filterHistories = () => {
    let filteredHistories = [...this.props.histories];
    if (this.state.selectedFilters.length !== 0) {
      filteredHistories = filteredHistories.filter(history => {
        return this.state.selectedFilters.includes(history.history_type);
      });
    }
    this.setState({
      filteredHistories,
    });
  };

  handleFilterChange = inputValue => {
    let selectedFilters = [];
    if (Array.isArray(inputValue) && inputValue.length) {
      selectedFilters = inputValue.map(x => x.value);
    }
    this.setState(
      {
        selectedFilters,
      },
      () => {
        this.filterHistories();
      }
    );
  };

  render() {
    const historiesArray = this.state.pageOfHistories.map(history => <History key={history.id} history={history} />);

    const filterOptions = [
      {
        label: 'History Type',
        options: [
          { value: 'Comment', label: 'Comment' },
          { value: 'Contact Attempt', label: 'Contact Attempt' },
          { value: 'Enrollment', label: 'Enrollment' },
          { value: 'Lab Result', label: 'Lab Result' },
          { value: 'Lab Result Edit', label: 'Lab Result Edit' },
          { value: 'Monitoree Data Downloaded', label: 'Monitoree Data Downloaded' },
          { value: 'Monitoring Change', label: 'Monitoring Change' },
          { value: 'Report Created', label: 'Report Created' },
          { value: 'Report Note', label: 'Report Note' },
          { value: 'Report Reminder', label: 'Report Reminder' },
          { value: 'Report Reviewed', label: 'Report Reviewed' },
          { value: 'Report Updated', label: 'Report Updated' },
          { value: 'Reports Reviewed', label: 'Reports Reviewed' },
        ],
      },
    ];

    return (
      <React.Fragment>
        <Card className="mx-2 mt-3 mb-4 card-square">
          <Card.Header>
            <div className="d-flex flex-row align-items-center">
              <h5 className="float-left flex-grow-1 mb-0">History</h5>
              <Select
                closeMenuOnSelect={false}
                isMulti
                name="Filters"
                options={filterOptions}
                className="basic-multi-select w-25 mr-3"
                classNamePrefix="select"
                placeholder="Filters"
                onChange={this.handleFilterChange}
              />
              <Pagination pageSize={2} maxPages={5} items={this.state.filteredHistories} onChangePage={this.onChangePage} />
            </div>
          </Card.Header>
          <Card.Body>
            {historiesArray}
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
