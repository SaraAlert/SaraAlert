import React from 'react';
import PropTypes from 'prop-types';
import DatePicker from 'react-datepicker';
import MaskedInput from 'react-text-mask';
import moment from 'moment';

class DateInput extends React.Component {
  constructor(props) {
    super(props);
    this.datePickerRef = React.createRef();
    this.handleRawChange = this.handleRawChange.bind(this);
    this.handleDateChange = this.handleDateChange.bind(this);
    this.clearDate = this.clearDate.bind(this);
  }

  handleDateChange(date) {
    this.props.onChange(date && moment(date).format('YYYY-MM-DD'));
    this.datePickerRef.current.setOpen(false);
  }

  handleRawChange(event) {
    if (event.target.value) {
      this.datePickerRef.current.setOpen(true);
    }
  }

  clearDate() {
    event.preventDefault();
    this.props.onChange(null);
    this.datePickerRef.current.setOpen(false);
  }

  render() {
    return (
      <div className="date-input">
        <i className="fas fa-calendar date-input__calendar_icon"></i>
        {this.props.isClearable && this.props.date && (
          <button className={`close ${this.props.isInvalid ? 'date-input__clear-btn-invalid' : 'date-input__clear-btn'}`} onClick={this.clearDate}>
            <i className="fas fa-times"></i>
          </button>
        )}
        <DatePicker
          id={this.props.id}
          selected={this.props.date && moment(this.props.date, 'YYYY-MM-DD').toDate()}
          onChange={this.handleDateChange}
          popperPlacement={this.props.placement || 'auto'}
          placeholderText="mm/dd/yyyy"
          ref={this.datePickerRef}
          onChangeRaw={this.handleRawChange}
          customInput={
            <MaskedInput
              mask={[/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/]}
              keepCharPositions
              className={`date-input__input react-datepicker-ignore-onclickoutside form-control form-control-lg ${this.props.isInvalid ? 'is-invalid' : ''}`}
            />
          }
        />
      </div>
    );
  }
}

DateInput.propTypes = {
  id: PropTypes.string,
  date: function(props) {
    if (props.date && !moment(props.date, 'YYYY-MM-DD').isValid()) {
      return new Error('Invalid prop `date` supplied to `DateInput`, `date` must be a valid date string in the `YYYY-MM-DD` format.');
    }
  },
  onChange: PropTypes.func.isRequired,
  placement: PropTypes.oneOf(['top', 'bottom', 'left', 'right', 'auto']),
  isInvalid: PropTypes.bool,
  isClearable: PropTypes.bool,
};

export default DateInput;
