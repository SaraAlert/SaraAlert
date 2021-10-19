import React from 'react';
import PropTypes from 'prop-types';
import MaskedInput from 'react-text-mask';
import moment from 'moment-timezone';

const DATE_MASK = [/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/];
const DATETIME_MASK = [/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/, ' ', /\d/, /\d/, ':', /\d/, /\d/, ' '];

class DateTimeInput extends React.Component {
  render() {
    return (
      <div>
        <MaskedInput
          mask={this.props.showTime ? DATETIME_MASK.concat(moment.tz(moment.tz.guess()).format('z').split('')) : DATE_MASK}
          keepCharPositions
          aria-label={this.props.ariaLabel || 'Date Input'}
          onChange={this.props.onChange}
          placeholder={this.props.placeholder}
          value={this.props.value}
          id={this.props.id}
          onClick={this.props.onClick}
          style={this.props.showTime && { width: '200px' }} // TODO: fix temporary hack
          className={`${
            this.props.customClass?.includes('sm')
              ? 'date-input__input_sm'
              : this.props.customClass?.includes('md')
              ? 'date-input__input_md'
              : 'date-input__input_lg'
          } react-datepicker-ignore-onclickoutside form-control ${this.props.customClass} ${this.props.isInvalid ? ' is-invalid' : ''}`}
        />
      </div>
    );
  }
}

DateTimeInput.propTypes = {
  onChange: PropTypes.func,
  onBlur: PropTypes.func,
  placeholder: PropTypes.string,
  value: PropTypes.string,
  id: PropTypes.string,
  onClick: PropTypes.func,
  showTime: PropTypes.bool,
  customClass: PropTypes.string,
  isInvalid: PropTypes.bool,
  ariaLabel: PropTypes.string,
};

export default DateTimeInput;
