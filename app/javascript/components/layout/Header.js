import _ from 'lodash';
import React from 'react';
import { PropTypes } from 'prop-types';
import { Navbar, Nav, Form } from 'react-bootstrap';

class Header extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      activeKey: this.getActiveTabKey(),
    };
  }

  /**
   * Finds the "activeKey" for the nav bar based on current path.
   */
  getActiveTabKey = () => {
    // Active tab should still be the tab for the monitoring dashboards when viewing the isolation workflow
    if (window.location.pathname === `${window.BASE_PATH}/public_health/isolation`) {
      return `${window.BASE_PATH}/public_health`;
    }
    return window.location.pathname;
  };

  render() {
    return (
      <React.Fragment>
        <Navbar bg={this.props.show_demo_warning ? 'danger' : 'primary'} variant="dark" expand="lg" className={this.props.show_demo_warning ? '' : 'mb-3'}>
          <Navbar.Brand className="header-brand-text" href={`${window.BASE_PATH}/${this.props.report_mode ? '' : this.props.root}`}>
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
                  {this.props.current_user?.email} (
                  {this.props.current_user?.role
                    ?.split('_')
                    ?.map(_.capitalize)
                    ?.join(' ')}
                  )
                </Navbar.Text>
                <a className="white-border-right"></a>
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
                    <a className="dropdown-item" href="https://saraalert.org/public-health/guides/" target="_blank" rel="noreferrer">
                      <i className="fas fa-book fa-fw"></i> User Guides
                    </a>
                    <a className="dropdown-item" href="https://virtualcommunities.naccho.org/saraalertforum/home" target="_blank" rel="noreferrer">
                      <i className="fas fa-comments fa-fw"></i> User Forum
                    </a>
                    <a className="dropdown-item" href="https://saraalert.org/contact-us/" target="_blank" rel="noreferrer">
                      <i className="fas fa-envelope-open-text fa-fw"></i> Contact Us
                    </a>
                  </div>
                </div>
                <a className="white-border-right"></a>
                {this.props.current_user?.is_usa_admin && (
                  <React.Fragment>
                    <Nav.Link className="text-white py-0" href={`${window.BASE_PATH}/oauth/applications`}>
                      <i className="fas fa-share-alt fa-fw mr-2"></i>API
                    </Nav.Link>
                    <a className="white-border-right"></a>
                    <Nav.Link className="text-white py-0" href={`${window.BASE_PATH}/sidekiq`}>
                      <i className="fas fa-hourglass fa-fw mr-2"></i>Jobs
                    </Nav.Link>
                    <a className="white-border-right"></a>
                  </React.Fragment>
                )}
                <Nav.Link className="text-white py-0" href={`${window.BASE_PATH}/users/sign_out`} data-method="DELETE">
                  <i className="fas fa-sign-out-alt fa-fw mr-2"></i>Logout
                </Nav.Link>
              </Form>
            </React.Fragment>
          )}
        </Navbar>
        {this.props.show_demo_warning && (
          <Navbar bg="warning" variant="dark" expand="lg" className="mb-3">
            This system is for demonstration use only, please do not provide any personal identifying information other than business contact data that may be
            required for testing.
          </Navbar>
        )}
      </React.Fragment>
    );
  }
}

Header.propTypes = {
  report_mode: PropTypes.bool,
  version: PropTypes.string,
  show_demo_warning: PropTypes.bool,
  root: PropTypes.string,
  current_user: PropTypes.object,
};

export default Header;
