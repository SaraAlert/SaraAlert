import _ from 'lodash';
import React from 'react';
import { PropTypes } from 'prop-types';
import { Navbar, Nav, Form } from 'react-bootstrap';
import axios from 'axios';
import { toast } from 'react-toastify';

class Header extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      activeKey: this.getActiveTabKey(),
    };
    // The following axios configuration is to ensure our XHR request are responded to with an appropriate 401,
    // and to handle that response by navigating to the log-in page.
    axios.defaults.headers.common['Accept'] = 'application/json';
    axios.interceptors.response.use(
      response => {
        return response;
      },
      error => {
        if (error?.response?.status === 401) {
          toast.error('Your session expired. Please sign in again to continue.', {
            autoClose: 1500,
            position: toast.POSITION.TOP_CENTER,
            onClose: () => {
              location.reload();
            },
          });
        } else {
          return Promise.reject(error);
        }
      }
    );
  }

  /**
   * Finds the "activeKey" for the nav bar based on current path.
   */
  getActiveTabKey = () => {
    // Active tab should still be the tab for the monitoring dashboards when viewing the isolation workflow
    if (window.location.pathname.includes('/public_health/')) {
      return `${window.BASE_PATH}/public_health`;
    }
    return window.location.pathname;
  };

  render() {
    return (
      <React.Fragment>
        <Navbar
          bg={this.props.show_demo_warning_background ? 'danger' : 'primary'}
          variant="dark"
          expand="lg"
          className={this.props.banner_message ? '' : 'mb-3'}>
          <Navbar.Brand className="header-brand-text" href={`${window.BASE_PATH}/`}>
            Sara Alert<small className="nav-version ml-1">{this.props.version}</small>
          </Navbar.Brand>
          {this.props.current_user && (
            <React.Fragment>
              <Nav className="mr-auto" activeKey={this.state.activeKey}>
                {this.props.current_user?.can_see_enroller_dashboard_tab && (
                  <Nav.Link
                    className={`${this.state.activeKey === '/patients' ? 'nav-link-active' : 'nav-link-inactive'} py-0 ml-3`}
                    href={`${window.BASE_PATH}/patients`}>
                    <i className="fas fa-table fa-fw mr-2"></i>Enroller Dashboard
                  </Nav.Link>
                )}
                {this.props.current_user?.can_see_monitoring_dashboards_tab && (
                  <Nav.Link
                    className={`${this.state.activeKey === '/public_health' ? 'nav-link-active' : 'nav-link-inactive'} py-0 ml-3`}
                    href={`${window.BASE_PATH}/public_health`}>
                    <i className="fas fa-table fa-fw mr-2"></i>Monitoring Dashboards
                  </Nav.Link>
                )}
                {this.props.current_user?.can_see_admin_panel_tab && (
                  <Nav.Link
                    className={`${this.state.activeKey === '/admin' ? 'nav-link-active' : 'nav-link-inactive'} py-0 ml-3`}
                    href={`${window.BASE_PATH}/admin`}>
                    <i className="fas fa-user-cog fa-fw mr-2"></i>Admin Panel
                  </Nav.Link>
                )}
                {this.props.current_user?.can_see_analytics_tab && (
                  <Nav.Link
                    className={`${this.state.activeKey === '/analytics' ? 'nav-link-active' : 'nav-link-inactive'} py-0 ml-3`}
                    href={`${window.BASE_PATH}/analytics`}>
                    <i className="fas fa-chart-pie fa-fw mr-2"></i>Analytics
                  </Nav.Link>
                )}
              </Nav>
              <Form inline className="ml-auto">
                <Navbar.Text className="text-white py-0 px-3">
                  <i className="fas fa-user fa-fw mr-2"></i>
                  {this.props.current_user?.email} ({this.props.current_user?.role?.split('_')?.map(_.capitalize)?.join(' ')})
                </Navbar.Text>
                <a className="w-border-right"></a>
                {Object.values(this.props.help_links).some(x => x) && (
                  <React.Fragment>
                    <div className="dropdown">
                      <Nav.Link
                        className="text-white py-0"
                        id="helpMenuButton"
                        href="#"
                        data-toggle="dropdown"
                        aria-haspopup="true"
                        aria-expanded="false"
                        aria-label="Help">
                        <i className="fas fa-question-circle fa-fw"></i>
                      </Nav.Link>
                      <div className="dropdown-menu dropdown-menu-right" aria-labelledby="helpMenuButton">
                        {!_.isNil(this.props.help_links.user_guides) && (
                          <a className="dropdown-item" href={this.props.help_links.user_guides} target="_blank" rel="noreferrer">
                            <i className="fas fa-book fa-fw"></i> User Guides
                          </a>
                        )}
                        {!_.isNil(this.props.help_links.user_forum) && (
                          <a className="dropdown-item" href={this.props.help_links.user_forum} target="_blank" rel="noreferrer">
                            <i className="fas fa-comments fa-fw"></i> User Forum
                          </a>
                        )}
                        {!_.isNil(this.props.help_links.contact_us) && (
                          <a className="dropdown-item" href={this.props.help_links.contact_us} target="_blank" rel="noreferrer">
                            <i className="fas fa-envelope-open-text fa-fw"></i> Contact Us
                          </a>
                        )}
                      </div>
                    </div>
                    <a className="w-border-right"></a>
                  </React.Fragment>
                )}
                {this.props.current_user?.is_usa_admin && (
                  <React.Fragment>
                    <Nav.Link className="text-white py-0" href={`${window.BASE_PATH}/oauth/applications`}>
                      <i className="fas fa-share-alt fa-fw mr-2"></i>API
                    </Nav.Link>
                    <a className="w-border-right"></a>
                    <Nav.Link className="text-white py-0" href={`${window.BASE_PATH}/sidekiq`}>
                      <i className="fas fa-hourglass fa-fw mr-2"></i>Jobs
                    </Nav.Link>
                    <a className="w-border-right"></a>
                  </React.Fragment>
                )}
                <Nav.Link className="text-white py-0" href={`${window.BASE_PATH}/users/sign_out`} data-method="DELETE">
                  <i className="fas fa-sign-out-alt fa-fw mr-2"></i>Logout
                </Nav.Link>
              </Form>
            </React.Fragment>
          )}
        </Navbar>
        {this.props.banner_message && (
          <Navbar bg="warning" variant="dark" expand="lg" className="mb-3">
            {this.props.banner_message}
          </Navbar>
        )}
      </React.Fragment>
    );
  }
}

Header.propTypes = {
  report_mode: PropTypes.bool,
  version: PropTypes.string,
  show_demo_warning_background: PropTypes.bool,
  banner_message: PropTypes.string,
  current_user: PropTypes.object,
  help_links: PropTypes.object,
};

export default Header;
