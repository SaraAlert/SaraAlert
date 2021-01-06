import React from 'react';
import PropTypes from 'prop-types';
import { OverlayTrigger, Tooltip } from 'react-bootstrap';
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
        <i
          className={`fas fa-calendar ${
            this.props.customClass?.includes('sm')
              ? 'date-input__calendar_icon_sm'
              : this.props.customClass?.includes('md')
              ? 'date-input__calendar_icon_md'
              : 'date-input__calendar_icon_lg'
          }`}></i>
        {this.props.isClearable && this.props.date && (
          <button
            className={`close ${
              this.props.isInvalid
                ? `date-input__clear-btn-invalid_${this.props.customClass?.includes('sm') ? 'sm' : this.props.customClass?.includes('md') ? 'md' : 'lg'}`
                : `date-input__clear-btn_${this.props.customClass?.includes('sm') ? 'sm' : this.props.customClass?.includes('md') ? 'md' : 'lg'}`
            }`}
            onClick={this.clearDate}
            disabled={this.props.disabled}
            aria-label="Clear Date Input">
            <i className="fas fa-times"></i>
          </button>
        )}
        <OverlayTrigger
          key={this.props.tooltipKey || ''}
          placement={this.props.tooltipPlacement || 'auto'}
          overlay={<Tooltip style={this.props.tooltipText ? {} : { display: 'none' }}>{this.props.tooltipText}</Tooltip>}>
          <div>
            <DatePicker
              id={this.props.id}
              selected={this.props.date && moment(this.props.date, 'YYYY-MM-DD').toDate()}
              minDate={this.props.minDate && moment(this.props.minDate, 'YYYY-MM-DD').toDate()}
              maxDate={this.props.maxDate && moment(this.props.maxDate, 'YYYY-MM-DD').toDate()}
              onChange={this.handleDateChange}
              popperPlacement={this.props.placement || 'auto'}
              placeholderText="mm/dd/yyyy"
              ref={this.datePickerRef}
              onChangeRaw={this.handleRawChange}
              className={this.props.customClass}
              customInput={
                <MaskedInput
                  mask={[/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/]}
                  keepCharPositions
                  aria-label={this.props.ariaLabel || 'Date Input'}
                  className={`${
                    this.props.customClass?.includes('sm')
                      ? 'date-input__input_sm'
                      : this.props.customClass?.includes('md')
                      ? 'date-input__input_md'
                      : 'date-input__input_lg'
                  } react-datepicker-ignore-onclickoutside form-control ${this.props.customClass} ${this.props.isInvalid ? ' is-invalid' : ''}`}
                />
              }
              disabled={this.props.disabled}
            />
          </div>
        </OverlayTrigger>
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
  minDate: function(props) {
    if (props.date && !moment(props.date, 'YYYY-MM-DD').isValid()) {
      return new Error('Invalid prop `minDate` supplied to `DateInput`, `date` must be a valid date string in the `YYYY-MM-DD` format.');
    }
  },
  maxDate: function(props) {
    if (props.date && !moment(props.date, 'YYYY-MM-DD').isValid()) {
      return new Error('Invalid prop `maxDate` supplied to `DateInput`, `date` must be a valid date string in the `YYYY-MM-DD` format.');
    }
  },
  onChange: PropTypes.func.isRequired,
  placement: PropTypes.oneOf(['top', 'bottom', 'left', 'right', 'auto']),
  isInvalid: PropTypes.bool,
  isClearable: PropTypes.bool,
  customClass: PropTypes.string,
  ariaLabel: PropTypes.string,
  disabled: PropTypes.bool,
  tooltipText: PropTypes.string,
  tooltipKey: PropTypes.string,
  tooltipPlacement: PropTypes.oneOf(['top', 'bottom', 'left', 'right', 'auto']),
};

export default DateInput;
