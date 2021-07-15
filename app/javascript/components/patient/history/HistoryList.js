import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Form, Row } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import Pagination from 'jw-react-pagination';
import Select from 'react-select';
import { bootstrapSelectTheme, cursorPointerStyle } from '../../../packs/stylesheets/ReactSelectStyling';

import History from './History';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

const MAX_COMMENT_LENGTH = 10000;

class HistoryList extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: false,
      comment: '',
      filters: { typeFilters: [], creatorFilters: [] },
      filteredHistories: this.props.histories,
      displayedHistories: this.props.histories.slice(0, 5),
    };

    this.creatorFilterData = [
      {
        label: 'History Creator',
        options: _.orderBy(_.uniq(props.histories.map(h => h[0].created_by)), x => _.toLower(x), 'asc').map(x => {
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
    this.typeFilterData[0].options = _.orderBy(this.typeFilterData[0].options, x => x.label, 'asc');
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
          location.reload();
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  filterHistories = () => {
    let filteredHistories = [...this.props.histories];
    if (this.state.filters.typeFilters.length !== 0) {
      filteredHistories = filteredHistories.filter(history_group => {
        return this.state.filters.typeFilters.includes(history_group[0].history_type);
      });
    }
    if (this.state.filters.creatorFilters.length !== 0) {
      filteredHistories = filteredHistories.filter(history_group => {
        return this.state.filters.creatorFilters.includes(history_group[0].created_by);
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
        <Card id="histories" className="mx-2 my-4 card-square">
          <Card.Header as="h1" className="patient-card-header">
            {this.props.section_label || 'History'}
            <InfoTooltip tooltipTextKey="history" location="right" className="pl-1" />
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
                theme={bootstrapSelectTheme}
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
                theme={bootstrapSelectTheme}
                onChange={this.handleTypeFilterChange}
              />
            </Row>
            <section role="list" aria-label="History Items">
              {this.state.displayedHistories.map((histories, index) => (
                <div role="listitem" key={`history-item-${index}`} aria-label={`History Entry ${index}`}>
                  <History
                    key={histories[0].id}
                    versions={histories}
                    current_user={this.props.current_user}
                    authenticity_token={this.props.authenticity_token}
                  />
                </div>
              ))}
            </section>
            <Row role="region" className="mx-3 mt-3 justify-content-end">
              <Pagination pageSize={5} maxPages={5} items={this.state.filteredHistories} onChangePage={this.onChangePage} />
            </Row>
            <Card className="mb-4 mt-4 mx-3 card-square shadow-sm">
              <Card.Header>Add Comment</Card.Header>
              <Card.Body>
                <Form.Control
                  id="comment"
                  as="textarea"
                  aria-label="Add history comment input"
                  className="form-control"
                  rows="3"
                  maxLength={MAX_COMMENT_LENGTH}
                  placeholder="enter comment here..."
                  value={this.state.comment}
                  onChange={this.handleChange}
                />
                <div className="character-limit-text">{MAX_COMMENT_LENGTH - this.state.comment.length} characters remaining</div>
                <Button
                  variant="primary"
                  className="btn btn-square float-right mt-2"
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
  section_label: PropTypes.string,
};

export default HistoryList;
