import React from 'react';
import PropTypes from 'prop-types';
import MaskedInput from 'react-text-mask';

const DATE_MASK = [/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/];
const DATETIME_MASK = [/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/, ' ', /\d/, /\d/, ':', /\d/, /\d/, ' '];

class DateTimeInput extends React.Component {
  handleChange = e => {
    // This is a workaround due to a bug where the input doesn't let a user highlight the entire date/time value and then delete.
    // In that case, the input value will be empty string, which causes an error in the parent DatePicker component.
    if (!e.target.value && this.props.showTime) {
      // This string is what we _should_ get with a blank value and the DATETIME_MASK
      e.target.value = `__/__/____ __:__`;
      // Reset the cursor to the beginning of the input
      e.target.selectionStart = 0;
      e.target.selectionEnd = 0;
    }
    this.props.onChange(e);
  };

  render() {
    return (
      <div>
        <MaskedInput
          mask={this.props.showTime ? DATETIME_MASK : DATE_MASK}
          keepCharPositions
          aria-label={this.props.ariaLabel || 'Date Input'}
          onChange={this.handleChange}
          placeholder={this.props.placeholder}
          value={this.props.value}
          id={this.props.id}
          onClick={this.props.onClick}
          style={this.props.showTime && { width: '160px' }}
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
