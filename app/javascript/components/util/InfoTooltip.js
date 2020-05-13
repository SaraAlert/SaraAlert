import React from 'react';
import { PropTypes } from 'prop-types';
import ReactTooltip from 'react-tooltip';

class InfoTooltip extends React.Component {
  constructor(props) {
    super(props);
    // If multiple instances of the Tooltip Exist on a page, the <ReactTooltip/> cannnot find
    // the correct instance (due to the lack of `data-for`/`id` pairs). Therefore we generate
    // custom string for each instance
    this.customID = this.makeid(this.props.tooltipText.length || 10).substring(0, 6);
  }

  makeid = length => {
    let result = '';
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (let i = 0; i < length; ++i) {
      result += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    return result;
  };

  render() {
    return (
      <div style={{ display: 'inline' }}>
        <span data-for={this.customID} data-tip="" className="ml-1">
          <i className="fas fa-question-circle"></i>
        </span>
        <ReactTooltip id={this.customID} multiline={true} place={this.props.location} type="dark" effect="solid" className="tooltip-container">
          <span>{this.props.tooltipText}</span>
        </ReactTooltip>
      </div>
    );
  }
}

InfoTooltip.propTypes = {
  tooltipText: PropTypes.oneOfType([
    PropTypes.string, // Can pass in a string (eg "some helpful info")
    PropTypes.object, // Or JSX (eg <div> some <i> helpful </i> info </div>)
  ]),
  location: PropTypes.string, // top, right, bottom, left
};

export default InfoTooltip;
