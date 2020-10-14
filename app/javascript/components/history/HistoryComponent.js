import React from 'react';
import _ from 'lodash';
import { PropTypes } from 'prop-types';
import { Card, Row } from 'react-bootstrap';
import Pagination from 'jw-react-pagination';
import Select from 'react-select';
import axios from 'axios';

import History from './History';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class HistoryComponent extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: false,
      comment: '',
      filters: { typeFilters: [], creatorFilters: [] },
      filteredHistories: this.props.histories,
      pageOfHistories: [],
    };

    this.handleTextChange = this.handleTextChange.bind(this);
    this.onChangePage = this.onChangePage.bind(this);
    this.submit = this.submit.bind(this);
  }

  handleTextChange(event) {
    this.setState({ comment: event.target.value });
  }

  onChangePage(pageOfHistories) {
    this.setState({ pageOfHistories });
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/histories', {
          patient_id: this.props.patient_id,
          comment: this.state.comment,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  filterHistories = () => {
    let filteredHistories = [...this.props.histories];
    if (this.state.filters.typeFilters.length !== 0) {
      filteredHistories = filteredHistories.filter(history => {
        return this.state.filters.typeFilters.includes(history.history_type);
      });
    }
    if (this.state.filters.creatorFilters.length !== 0) {
      filteredHistories = filteredHistories.filter(history => {
        return this.state.filters.creatorFilters.includes(history.created_by);
      });
    }
    this.setState({
      filteredHistories,
    });
  };

  handleFilterChange = (inputValue, filterCategory) => {
    let filters = this.state.filters;
    let selectedFilters = [];
    if (Array.isArray(inputValue) && inputValue.length) {
      selectedFilters = inputValue.map(x => x.value);
    }
    if (filterCategory == 'History Type') {
      filters.typeFilters = selectedFilters;
    } else if (filterCategory == 'History Creator') {
      filters.creatorFilters = selectedFilters;
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

  handleTypeFilterChange = inputValue => this.handleFilterChange(inputValue, 'History Type');

  handleCreatorFilterChange = inputValue => this.handleFilterChange(inputValue, 'History Creator');

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
    const historyCreators = [
      {
        label: 'History Creator',
        options: _.uniq(this.props.histories.map(x => x.created_by)).map(x => {
          return { value: x, label: x };
        }),
      },
    ];

    return (
      <React.Fragment>
        <Card className="mx-2 mt-3 mb-4 card-square">
          <Card.Header>
            <div className="d-flex flex-row align-items-center">
              <h5 className="float-left flex-grow-1 mb-0">
                <span>History </span>
                <InfoTooltip tooltipTextKey="history" location="right"></InfoTooltip>
              </h5>
            </div>
          </Card.Header>
          <Card.Body className="py-0 px-1">
            <Row className="mx-3 mt-3 justify-content-end">
              <Select
                closeMenuOnSelect={false}
                isMulti
                name="Filters"
                options={filterOptions}
                className="basic-multi-select w-25"
                classNamePrefix="select"
                placeholder="Filter by Type"
                theme={theme => ({
                  ...theme,
                  borderRadius: 0,
                })}
                onChange={this.handleTypeFilterChange}
              />
              <Select
                closeMenuOnSelect={false}
                isMulti
                name="Creator Filters"
                options={historyCreators}
                className="basic-multi-select w-25 pl-1"
                classNamePrefix="select"
                placeholder="Filter by Creator"
                theme={theme => ({
                  ...theme,
                  borderRadius: 0,
                })}
                onChange={this.handleCreatorFilterChange}
              />
            </Row>
            {historiesArray}
            <Row className="mx-3 mt-3 justify-content-end">
              <Pagination pageSize={5} maxPages={5} items={this.state.filteredHistories} onChangePage={this.onChangePage} />
            </Row>
            <Card className="mb-4 mt-4 mx-3 card-square shadow-sm">
              <Card.Header>Add Comment</Card.Header>
              <Card.Body>
                <textarea
                  id="comment"
                  name="comment"
                  className="form-control"
                  style={{ resize: 'none' }}
                  rows="3"
                  placeholder="enter comment here..."
                  value={this.state.comment}
                  onChange={this.handleTextChange}
                />
                <button
                  className="mt-3 btn btn-primary btn-square float-right"
                  disabled={this.state.loading || this.state.comment === ''}
                  onClick={this.submit}>
                  <i className="fas fa-comment-dots"></i> Add Comment
                </button>
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
