import React from 'react';
import axios from 'axios';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import reportError from '../util/ReportError';

class Downloads extends React.Component {
  constructor(props) {
    super(props);
  }

  exportDownloaded = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      headers: {
        'Content-Type': 'application/json',
      },
      url: `${window.BASE_PATH}/export/downloaded`,
      data: { id: this.props.download.id },
    })
      .then(() => {
        // Maybe something like this download has been flagged for removal?
      })
      .catch(err => {
        reportError(err);
      });
  };

  render() {
    return (
      <React.Fragment>
        {this.props.error && (
          <div>
            The download link is either invalid, has expired, or the file has already been accessed. Please try exporting again. If you think you received this
            message in error, please contact the help desk.
          </div>
        )}
        {!this.props.error && (
          <div>
            <p>
              Please note that this export is one-time use only. The system will delete an export file once you&apos;ve downloaded that file. These downloads
              will be invalid if you attempt another export of this type before retrieving the file(s). Exports will not work if forwarded to another user. You
              must be logged into Sara Alert to access exports.
            </p>
            <a href={this.props.export_url} target="_blank" rel="noreferrer" onClick={this.exportDownloaded}>
              <Button className="mx-1" size="md">
                <i className="fas fa-download"></i>
                &nbsp;Download Export - {this.props.download.filename}
              </Button>
            </a>
          </div>
        )}
      </React.Fragment>
    );
  }
}

Downloads.propTypes = {
  error: PropTypes.bool,
  download: PropTypes.object,
  export_url: PropTypes.string,
  authenticity_token: PropTypes.string,
};

export default Downloads;
