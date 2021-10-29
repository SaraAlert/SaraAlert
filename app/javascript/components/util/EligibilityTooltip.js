import React from 'react';
import { PropTypes } from 'prop-types';
import _ from 'lodash';

import { formatTimestamp } from '../../utils/DateTime';
import ReactTooltip from 'react-tooltip';

const eligibility_options = [
  { conditional: 'household', icon: 'fa-house-user', title: 'In a household:', messageCount: 1 },
  { conditional: 'eligible', icon: 'fa-comment', title: 'Eligible for notifications:', messageCount: 1 },
  { conditional: 'reported', icon: 'fa-comments', title: 'Received a report today:', messageCount: 'all' },
  { conditional: 'sent', icon: 'fa-comment-dots', title: 'Waiting for a response:', messageCount: 'all' },
  // This bottom entry is the default. If none of the `conditional` fields are truthy within props.report_eligibility, the bottom will render
  { conditional: '', icon: 'fa-comment-slash', title: 'Not eligible for notifications:', messageCount: 'all' },
];

class EligibilityTooltip extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    let activeOption = eligibility_options.find(eo => this.props.report_eligibility[`${eo.conditional}`]) || _.last(eligibility_options);
    activeOption.messages = activeOption.messageCount === 1 ? [this.props.report_eligibility.messages[0]] : this.props.report_eligibility.messages;

    return (
      <React.Fragment>
        <span key={`re-icon${this.props.id}`} data-for={`re${this.props.id}`} data-tip="">
          {this.props.inline && <i className={`fa-fw fas ${activeOption.icon}`}></i>}
          {!this.props.inline && (
            <div className="text-center ml-0">
              <i className={`fa-fw fas ${activeOption.icon}`}></i>
            </div>
          )}
        </span>
        <ReactTooltip key={`re-tooltip${this.props.id}`} id={`re${this.props.id}`} multiline={true} type="dark" effect="solid" className="tooltip-container">
          <div>
            <p className="lead mb-0">{activeOption.title}</p>
            {activeOption.messageCount === 1 ? (
              <span aria-label={activeOption.messages[0].message}>{activeOption.messages[0].message}</span>
            ) : (
              <ul className="pl-3 mb-0">
                {activeOption.messages.map((m, index) => {
                  const message = m.datetime ? `${m.message} (${formatTimestamp(m.datetime)})` : m.message;
                  return (
                    <li className="mb-0" key={`rei${this.props.id}${index}`} aria-label={message}>
                      {' '}
                      {message}{' '}
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </ReactTooltip>
      </React.Fragment>
    );
  }
}

EligibilityTooltip.propTypes = {
  report_eligibility: PropTypes.object,
  id: PropTypes.string,
  inline: PropTypes.bool,
};

export default EligibilityTooltip;
