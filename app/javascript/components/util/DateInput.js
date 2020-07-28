import React from 'react';
import PropTypes from 'prop-types';
import DatePicker from 'react-datepicker';
import MaskedInput from 'react-text-mask';
import moment from 'moment';

class DateInput extends React.Component {
  render() {
    return (
      <div style={{ position: 'relative' }}>
        <i className="fas fa-calendar" style={{ zIndex: '1', position: 'absolute', left: '1.25rem', top: '0.75rem', color: '#495057', fontSize: '18pt' }}></i>
        <DatePicker
          name={this.props.name}
          selected={this.props.date && moment(this.props.date, 'YYYY-MM-DD').toDate()}
          onChange={date => this.props.onChange(date && moment(date).format('YYYY-MM-DD'))}
          popperPlacement={this.props.placement || 'auto'}
          placeholderText="mm/dd/yyyy"
          customInput={
            <MaskedInput
              mask={[/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/]}
              keepCharPositions
              className="form-control form-control-lg react-datepicker-ignore-onclickoutside"
              style={{ paddingLeft: '3.375rem' }}
            />
          }
        />
      </div>
    );
  }
}

DateInput.propTypes = {
  name: PropTypes.string,
  date: function(props) {
    if (props.date && !moment(props.date, 'YYYY-MM-DD').isValid()) {
      return new Error('Invalid prop `date` supplied to `DateInput`, `date` must be a string in the `YYYY-MM-DD` format.');
    }
  },
  onChange: PropTypes.func.isRequired,
  placement: PropTypes.oneOf(['top', 'bottom', 'left', 'right', 'auto']),
};

export default DateInput;
