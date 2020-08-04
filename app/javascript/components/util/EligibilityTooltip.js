import React from 'react';
import { PropTypes } from 'prop-types';
import ReactTooltip from 'react-tooltip';
import moment from 'moment-timezone';

class EligibilityTooltip extends React.Component {
  constructor(props) {
    super(props);
  }

  formatTimestamp(timestamp) {
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('MM/DD/YYYY HH:mm z') : '';
  }

  formatEligibility(eligibility, id) {
    if (eligibility.eligible) {
      return (
        <React.Fragment>
          <span data-for={`re${id}`} data-tip="">
            {this.props.inline && <i className="fa-fw fas fa-bell"></i>}
            {!this.props.inline && (
              <div className="text-center ml-0">
                <i className="fa-fw fas fa-bell"></i>
              </div>
            )}
          </span>
          <ReactTooltip id={`re${id}`} multiline={true} type="dark" effect="solid" className="tooltip-container">
            <div>
              <p className="lead mb-0">Eligible for notifications:</p>
              <span>{eligibility.messages[0].message}</span>
            </div>
          </ReactTooltip>
        </React.Fragment>
      );
    } else if (eligibility.reported) {
      return (
        <React.Fragment>
          <span data-for={`re${id}`} data-tip="">
            {this.props.inline && <i className="fa-fw fas fa-check"></i>}
            {!this.props.inline && (
              <div className="text-center ml-0">
                <i className="fa-fw fas fa-check"></i>
              </div>
            )}
          </span>
          <ReactTooltip id={`re${id}`} multiline={true} type="dark" effect="solid" className="tooltip-container">
            <div>
              <p className="lead mb-0">Already reported today:</p>
              <ul className="pl-3 mb-0">
                {eligibility.messages.map((m, index) => (
                  <li className="mb-0" key={`rei${id}${index}`}>
                    {m.message}
                    {m.datetime ? ` (${this.formatTimestamp(m.datetime)})` : ''}
                  </li>
                ))}
              </ul>
            </div>
          </ReactTooltip>
        </React.Fragment>
      );
    } else if (eligibility.sent) {
      return (
        <React.Fragment>
          <span data-for={`re${id}`} data-tip="">
            {this.props.inline && <i className="fa-fw fas fa-comment-dots"></i>}
            {!this.props.inline && (
              <div className="text-center ml-0">
                <i className="fa-fw fas fa-comment-dots"></i>
              </div>
            )}
          </span>
          <ReactTooltip id={`re${id}`} multiline={true} type="dark" effect="solid" className="tooltip-container">
            <div>
              <p className="lead mb-0">Already sent a daily report:</p>
              <ul className="pl-3 mb-0">
                {eligibility.messages.map((m, index) => (
                  <li className="mb-0" key={`rei${id}${index}`}>
                    {m.message}
                    {m.datetime ? ` (${this.formatTimestamp(m.datetime)})` : ''}
                  </li>
                ))}
              </ul>
            </div>
          </ReactTooltip>
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          <span data-for={`re${id}`} data-tip="">
            {this.props.inline && <i className="fa-fw fas fa-bell-slash"></i>}
            {!this.props.inline && (
              <div className="text-center ml-0">
                <i className="fa-fw fas fa-bell-slash"></i>
              </div>
            )}
          </span>
          <ReactTooltip id={`re${id}`} multiline={true} type="dark" effect="solid" className="tooltip-container">
            <div>
              <p className="lead mb-0">Not eligible for notifications:</p>
              <ul className="pl-3 mb-0">
                {eligibility.messages.map((m, index) => (
                  <li className="mb-0" key={`rei${id}${index}`}>
                    {m.message}
                    {m.datetime ? ` (${this.formatTimestamp(m.datetime)})` : ''}
                  </li>
                ))}
              </ul>
            </div>
          </ReactTooltip>
        </React.Fragment>
      );
    }
  }

  render() {
    return <React.Fragment>{this.formatEligibility(this.props.report_eligibility, this.props.id)}</React.Fragment>;
  }
}

EligibilityTooltip.propTypes = {
  report_eligibility: PropTypes.object,
  id: PropTypes.string,
  inline: PropTypes.bool,
};

export default EligibilityTooltip;
