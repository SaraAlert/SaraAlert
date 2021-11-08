import React from 'react';
import PropTypes from 'prop-types';
import { OverlayTrigger, Tooltip } from 'react-bootstrap';
import DatePicker from 'react-datepicker';
import moment from 'moment-timezone';
import _ from 'lodash';
import { formatTimestamp } from '../../utils/DateTime';
import DateTimeInput from './DateTimeInput';

class DateInput extends React.Component {
  constructor(props) {
    super(props);
    this.datePickerRef = React.createRef();
    this.state = {
      currentDate: props.date || null,
      lastValidDate: props.date || null,
    };
  }

  /**
   * Called only when date value is changed
   * This happens both when a date is clicked in the datepicker AND when the user types a complete valid date
   */
  handleDateChange = date => {
    const momentDate = date && (this.props.showTime ? formatTimestamp(moment(date)) : moment(date).format('YYYY-MM-DD'));
    this.datePickerRef.current.setOpen(false);
    this.setState({ currentDate: momentDate });
    if (this.dateIsValidAndNotEmpty(date)) {
      this.setState({ lastValidDate: this.props.showTime ? date : momentDate });
      this.props.onChange(this.props.showTime ? date : momentDate);
    } else if (!this.props.required) {
      this.props.onChange(this.props.showTime ? date : momentDate);
    }
  };

  /**
   * Called when typing into the date input
   * This fires everytime a character is added or deleted in the input
   */
  handleRawChange = event => {
    this.datePickerRef.current.setOpen(true);
    this.setState({ currentDate: event.target.value });
  };

  /**
   * Called when the date input goes out of focus.
   * This will happen when the user leaves the form input (i.e. clicks out of the datepicker)
   */
  handleOnBlur = () => {
    const currentDate = this.state.currentDate && moment(this.state.currentDate).format('YYYY-MM-DD');
    // if date is not valid when clicking out of the date input
    if (!this.dateIsValidAndNotEmpty(currentDate)) {
      // change back to the last valid date or today if the field should revert to the last valid date
      if (this.props.replaceBlank) {
        const date = this.state.lastValidDate || moment().format('YYYY-MM-DD');
        this.props.onChange(date);
        // clear the date if field should be empty on invalid
      } else if (this.props.clearInvalid) {
        this.clearDate();
      }
    }
  };

  /**
   * Called when any key on the key board is pressed.
   * This will call the onBlur function only if the enter key is pressed
   * This is to prevent entering an invalid date being overwritten by the user pressing the enter key
   */
  handleKeyDown = event => {
    if (event.keyCode === 13) {
      this.handleOnBlur();
    }
  };

  /**
   * Returns false if date is null, undefined, invalid or falls outside the min/max date range
   * Returns true otherwise
   */
  dateIsValidAndNotEmpty = date => {
    const isNotNull = !_.isNil(date);
    const isValid = moment(date, 'YYYY-MM-DD').isValid();
    const isInRange = moment(this.props.minDate).isSameOrBefore(moment(date)) && moment(this.props.maxDate).isSameOrAfter(moment(date));
    return isNotNull && isValid && isInRange;
  };

  /**
   * Clears the selected date in parent component and closes the datepicker
   */
  clearDate = () => {
    this.props.onChange(null);
    this.datePickerRef.current.setOpen(false);
    this.setState({ currentDate: null });
  };

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
              selected={this.props.date && (this.props.showTime ? moment(this.state.lastValidDate).toDate() : moment(this.props.date, 'YYYY-MM-DD').toDate())}
              minDate={this.props.minDate && moment(this.props.minDate, 'YYYY-MM-DD').toDate()}
              maxDate={this.props.maxDate && moment(this.props.maxDate, 'YYYY-MM-DD').toDate()}
              popperPlacement={this.props.placement || 'auto'}
              placeholderText="mm/dd/yyyy"
              ref={this.datePickerRef}
              onChange={this.handleDateChange}
              onChangeRaw={this.handleRawChange}
              onBlur={this.handleOnBlur}
              onKeyDown={this.handleKeyDown}
              className={this.props.customClass}
              dateFormat={this.props.showTime ? 'MM/dd/yyyy HH:mm' : 'MM/dd/yyyy'}
              showTimeInput={this.props.showTime}
              customInput={
                <DateTimeInput
                  onChange={this.handleDateChange}
                  showTime={this.props.showTime}
                  customClass={this.props.customClass}
                  isInvalid={this.props.isInvalid}
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
  date: function (props) {
    if (props.date && !moment(props.date, 'YYYY-MM-DD').isValid()) {
      return new Error('Invalid prop `date` supplied to `DateInput`, `date` must be a valid date string in the `YYYY-MM-DD` format.');
    }
  },
  minDate: function (props) {
    if (props.minDate && !moment(props.minDate, 'YYYY-MM-DD').isValid()) {
      return new Error('Invalid prop `minDate` supplied to `DateInput`, `date` must be a valid date string in the `YYYY-MM-DD` format.');
    }
  },
  maxDate: function (props) {
    if (props.maxDate && !moment(props.maxDate, 'YYYY-MM-DD').isValid()) {
      return new Error('Invalid prop `maxDate` supplied to `DateInput`, `date` must be a valid date string in the `YYYY-MM-DD` format.');
    }
  },
  onChange: PropTypes.func.isRequired,
  placement: PropTypes.oneOf(['top', 'bottom', 'left', 'right', 'auto']),
  required: PropTypes.bool,
  isInvalid: PropTypes.bool,
  isClearable: PropTypes.bool,
  replaceBlank: PropTypes.bool,
  clearInvalid: PropTypes.bool,
  customClass: PropTypes.string,
  ariaLabel: PropTypes.string,
  disabled: PropTypes.bool,
  tooltipText: PropTypes.string,
  tooltipKey: PropTypes.string,
  tooltipPlacement: PropTypes.oneOf(['top', 'bottom', 'left', 'right', 'auto']),
  showTime: PropTypes.bool,
};

export default DateInput;
