import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Row } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment-timezone';
import Pagination from 'jw-react-pagination';
import Select from 'react-select';
import { cursorPointerStyle } from '../../../packs/stylesheets/ReactSelectStyling';

import History from './History';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class HistoryList extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: false,
      comment: '',
      filters: { typeFilters: [], creatorFilters: [] },
      histories: [],
      filteredHistories: [],
      displayedHistories: [],
    };

    this.creatorFilterData = [
      {
        label: 'History Creator',
        options: _.uniq(props.histories.map(x => x.created_by)).map(x => {
          return { value: x, label: x };
        }),
      },
    ];

    this.typeFilterData = [
      {
        label: 'History Type',
        options: [],
      },
    ];

    for (const historyType in this.props.history_types) {
      this.typeFilterData[0].options.push({
        value: _.startCase(historyType), // converts `monitoree_data_downloaded` to `Monitoree Data Downloaded`
        label: this.props.history_types[`${historyType}`],
      });
    }
  }

  componentDidMount() {
    const filteredHistories = this.formatHistories(this.props.histories); // props.histories must be ordered by created date, newest first
    const displayedHistories = _.clone(filteredHistories).splice(0, 5);
    this.setState({ filteredHistories, displayedHistories, histories: filteredHistories });
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  onChangePage = displayedHistories => {
    this.setState({ displayedHistories });
  };

  submit = () => {
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
  };

  formatHistories = histories => {
    return histories
      .filter(history => {
        if (history.history_type === 'Comment') {
          const latest_version = histories.find(h => history.original_comment_id === h.original_comment_id);
          return history.id === latest_version.id;
        }
        return true;
      })
      .map(history => {
        // if comment has been edited, set created at as the time the original was created and store a new variable for the time the history was edited
        // otherwise store the history object as is
        if (history.history_type === 'Comment') {
          const original_comment = histories.find(h => history.original_comment_id === h.id);
          if (history.id !== original_comment.id) {
            history.edited_at = history.created_at;
            history.created_at = original_comment.created_at;
          }
        }
        return history;
      })
      .sort((a, b) => {
        return moment.utc(b.created_at).diff(moment.utc(a.created_at));
      });
  };

  filterHistories = () => {
    let filteredHistories = [...this.state.histories];
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
      displayedHistories: filteredHistories.slice(0, 5),
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
        filters,
      },
      () => {
        this.filterHistories();
      }
    );
  };

  handleTypeFilterChange = inputValue => this.handleFilterChange(inputValue, 'History Type');

  handleCreatorFilterChange = inputValue => this.handleFilterChange(inputValue, 'History Creator');

  render() {
    return (
      <React.Fragment>
        <Card id="histories" className="mx-2 mt-3 mb-4 card-square">
          <Card.Header>
            <div className="d-flex flex-row align-items-center">
              <div className="float-left flex-grow-1 mb-0 h5">
                <span>History</span>
                <InfoTooltip tooltipTextKey="history" location="right" className="pl-1"></InfoTooltip>
              </div>
            </div>
          </Card.Header>
          <Card.Body className="py-0 px-1">
            <Row id="history-filters" className="mx-3 mt-3 justify-content-end">
              <Select
                closeMenuOnSelect={false}
                isMulti
                name="Creator Filters"
                options={this.creatorFilterData}
                className="basic-multi-select w-25 pl-1"
                classNamePrefix="select"
                placeholder="Filter by Creator"
                aria-label="History Creator Filter"
                styles={cursorPointerStyle}
                theme={theme => ({
                  ...theme,
                  borderRadius: 0,
                })}
                onChange={this.handleCreatorFilterChange}
              />
              <Select
                closeMenuOnSelect={false}
                isMulti
                name="Filters"
                options={this.typeFilterData}
                className="basic-multi-select w-25 pl-2"
                classNamePrefix="select"
                placeholder="Filter by Type"
                aria-label="History Type Filter"
                styles={cursorPointerStyle}
                theme={theme => ({
                  ...theme,
                  borderRadius: 0,
                })}
                onChange={this.handleTypeFilterChange}
              />
            </Row>
            {this.state.displayedHistories.map(history => (
              <History key={history.id} history={history} current_user={this.props.current_user} authenticity_token={this.props.authenticity_token} />
            ))}
            <Row className="mx-3 mt-3 justify-content-end">
              <Pagination pageSize={5} maxPages={5} items={this.state.filteredHistories} onChangePage={this.onChangePage} />
            </Row>
            <Card className="mb-4 mt-4 mx-3 card-square shadow-sm">
              <Card.Header>Add Comment</Card.Header>
              <Card.Body>
                <textarea
                  id="comment"
                  name="comment"
                  aria-label="Add comment input"
                  className="form-control"
                  style={{ resize: 'none' }}
                  rows="3"
                  placeholder="enter comment here..."
                  value={this.state.comment}
                  onChange={this.handleChange}
                />
                <Button
                  variant="primary"
                  className="mt-3 btn btn-square float-right"
                  disabled={this.state.loading || this.state.comment === ''}
                  onClick={this.submit}>
                  <i className="fas fa-comment-dots"></i> Add Comment
                </Button>
              </Card.Body>
            </Card>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

HistoryList.propTypes = {
  patient_id: PropTypes.number,
  current_user: PropTypes.object,
  histories: PropTypes.array,
  history_types: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default HistoryList;
