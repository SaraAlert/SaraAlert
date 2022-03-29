import React from 'react';
import _ from 'lodash';
import { shallow } from 'enzyme';
import { Nav, Navbar } from 'react-bootstrap';
import Header from '../../components/layout/Header';
import { mockUser1, mockUser2 } from '../mocks/mockUsers';

const helpLinks = {
  user_guides: 'https://www.sara.org/user-guides',
  user_forum: 'https://www.sara.org/user-forum',
  contact_us: 'https://www.sara.org/contact-us',
};
const version = '123';

/**
 * If additionalProps undefiend, the Header component is rendered with the default props included below
 * If any props are defined in additional props, they overwrite whatever the default value was set as
 */
function getWrapper(additionalProps) {
  return shallow(<Header report_mode={false} version={version} show_demo_warning_background={false} banner_message="" current_user={mockUser1} help_links={helpLinks} {...additionalProps} />);
}

describe('Header', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper({ current_user: mockUser1 });
    const primaryNav = wrapper.find(Navbar).find('.primary-nav');
    expect(primaryNav.exists()).toBe(true);
    expect(primaryNav.find(Navbar.Brand).exists()).toBe(true);
    expect(primaryNav.find(Navbar.Brand).text()).toContain(`Sara Alert${version}`);
    expect(primaryNav.find(Navbar.Text).exists()).toBe(true);
    expect(primaryNav.find(Navbar.Text).text()).toContain(`${mockUser1.email} (${_.startCase(mockUser1.role)})`);
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/users/sign_out` })
        .exists()
    ).toBe(true);
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/users/sign_out` })
        .text()
    ).toEqual('Logout');
    expect(primaryNav.find(Nav.Link).find({ id: 'helpMenuButton' }).exists()).toBe(true);
    expect(primaryNav.find(Nav.Link).children().find('i').exists()).toBe(true);
    expect(primaryNav.find('.dropdown-menu').exists()).toBe(true);
    expect(primaryNav.find('.enroller-tab').exists()).toBe(false);
    expect(primaryNav.find('.monitoring-tab').exists()).toBe(false);
    expect(primaryNav.find('.admin-panel-tab').exists()).toBe(false);
    expect(primaryNav.find('.analytics-tab').exists()).toBe(false);
    expect(primaryNav.find('.api-tab').exists()).toBe(false);
    expect(primaryNav.find('.jobs-tab').exists()).toBe(false);
    expect(wrapper.find(Navbar).find('.banner-message').exists()).toBe(false);
  });

  it('Shows "Enroller Dashboard" tab when user. can_see_enroller_dashboard_tab', () => {
    const wrapper = getWrapper({ current_user: mockUser2 });
    const primaryNav = wrapper.find(Navbar).find('.primary-nav');
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/patients` })
        .exists()
    ).toBe(true);
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/patients` })
        .text()
    ).toEqual('Enroller Dashboard');
  });

  it('Shows "Analytics" tab when user. can_see_analytics_tab', () => {
    const wrapper = getWrapper({ current_user: mockUser2 });
    const primaryNav = wrapper.find(Navbar).find('.primary-nav');
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/analytics` })
        .exists()
    ).toBe(true);
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/analytics` })
        .text()
    ).toEqual('Analytics');
  });

  it('Shows "Monitoring Dashboards" tabs when user. can_see_monitoring_dashboards_tab', () => {
    const wrapper = getWrapper({ current_user: mockUser2 });
    const primaryNav = wrapper.find(Navbar).find('.primary-nav');
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/public_health` })
        .exists()
    ).toBe(true);
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/public_health` })
        .text()
    ).toEqual('Monitoring Dashboards');
  });

  it('Shows "API" and "Jobs" when user.  is_usa_admin', () => {
    const wrapper = getWrapper({ current_user: mockUser2 });
    const primaryNav = wrapper.find(Navbar).find('.primary-nav');
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/oauth/applications` })
        .exists()
    ).toBe(true);
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/oauth/applications` })
        .text()
    ).toEqual('API');
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/sidekiq` })
        .exists()
    ).toBe(true);
    expect(
      primaryNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/sidekiq` })
        .text()
    ).toEqual('Jobs');
  });

  it('Properly updates the active link based on the activeKey', () => {
    const wrapper = getWrapper({ current_user: mockUser2 });
    const keys = ['/patients', '/public_health', '/admin', '/analytics'];
    keys.forEach(key => {
      wrapper.setState({ activeKey: key });
      expect(wrapper.find(Navbar).find('.primary-nav').find(Nav.Link).find('.nav-link-active').prop('href')).toContain(key);
    });
  });

  it('Properly renders the help link menu with all help links', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(3);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual(helpLinks.user_guides);
    expect(wrapper.find('.dropdown-item').find('a').at(0).text()).toContain('User Guides');
    expect(wrapper.find('.dropdown-item').find('a').at(0).find('i').find('.fa-book').exists()).toBe(true);
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual(helpLinks.user_forum);
    expect(wrapper.find('.dropdown-item').find('a').at(1).text()).toContain('User Forum');
    expect(wrapper.find('.dropdown-item').find('a').at(1).find('i').find('.fa-comments').exists()).toBe(true);
    expect(wrapper.find('.dropdown-item').find('a').at(2).prop('href')).toEqual(helpLinks.contact_us);
    expect(wrapper.find('.dropdown-item').find('a').at(2).text()).toContain('Contact Us');
    expect(wrapper.find('.dropdown-item').find('a').at(2).find('i').find('.fa-envelope-open-text').exists()).toBe(true);
  });

  it('Properly renders the help link menu with only two help links', () => {
    const wrapper = getWrapper({ help_links: { user_guides: null, user_forum: helpLinks.user_forum, contact_us: helpLinks.contact_us } });
    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(2);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual(helpLinks.user_forum);
    expect(wrapper.find('.dropdown-item').find('a').at(0).text()).toContain('User Forum');
    expect(wrapper.find('.dropdown-item').find('a').at(0).find('i').find('.fa-comments').exists()).toBe(true);
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual(helpLinks.contact_us);
    expect(wrapper.find('.dropdown-item').find('a').at(1).text()).toContain('Contact Us');
    expect(wrapper.find('.dropdown-item').find('a').at(1).find('i').find('.fa-envelope-open-text').exists()).toBe(true);
  });

  it('Hides help link menu when all help links are null', () => {
    const wrapper = getWrapper({ help_links: { user_guides: null, user_forum: '', contact_us: null } });
    expect(wrapper.find('.dropdown-menu').exists()).toBe(false);
  });

  it('Properly renders a banner message if defined', () => {
    const bannerMessage = 'This is a test banner message.';
    const wrapper = getWrapper({ banner_message: bannerMessage });
    expect(wrapper.find(Navbar).find('.banner-message').exists()).toBe(true);
    expect(wrapper.find(Navbar).find('.banner-message').text()).toEqual(bannerMessage);
  });
});
