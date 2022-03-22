import React from 'react';
import { shallow } from 'enzyme';
import { Nav, Navbar } from 'react-bootstrap';
import Header from '../../components/layout/Header';
import { mockUser1 } from '../mocks/mockUsers';

const helpLinks = {
  user_guides: 'https://www.sara.org/user-guides',
  user_forum: 'https://www.sara.org/user-forum',
  contact_us: 'https://www.sara.org/contact-us',
};

const bannerMessage = 'This is a test banner message.';
const version = '123';

/**
 * If additionalProps undefiend, the Header component is rendered with the default props included below
 * If any props are defined in additional props, they overwrite whatever the default value was set as
 */
function getWrapper(additionalProps) {
  return shallow(<Header report_mode={false} version={version} show_demo_warning_background={false} banner_message="" current_user={mockUser1} help_links={helpLinks} {...additionalProps} />);
}

function getMainNav(wrapper) {
  return wrapper.find(Navbar).find({ bg: 'primary' });
}

describe('Header', () => {
  it('Properly renders all main components', () => {
    mockUser1.role = 'fake_role';
    const wrapper = getWrapper({ current_user: mockUser1 });
    const mainNav = getMainNav(wrapper);
    expect(mainNav.exists()).toBe(true);
    expect(mainNav.find(Navbar.Brand).exists()).toBe(true);
    expect(mainNav.find(Navbar.Brand).text()).toContain(`Sara Alert${version}`);
    expect(mainNav.find(Navbar.Text).exists()).toBe(true);
    expect(mainNav.find(Navbar.Text).text()).toContain(`${mockUser1.email} (Fake Role)`);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/users/sign_out` })
        .exists()
    ).toBe(true);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/users/sign_out` })
        .text()
    ).toEqual('Logout');
    expect(mainNav.find(Nav.Link).find({ id: 'helpMenuButton' }).exists()).toBe(true);
    expect(mainNav.find(Nav.Link).children().find('i').exists()).toBe(true);
    expect(mainNav.find('.dropdown-menu').exists()).toBe(true);
    expect(mainNav.find({ children: 'Enroller Dashboard' }).exists()).toBe(false);
    expect(mainNav.find({ children: 'Monitoring Dashboards' }).exists()).toBe(false);
    expect(mainNav.find({ children: 'Admin Panel' }).exists()).toBe(false);
    expect(mainNav.find({ children: 'Analytics' }).exists()).toBe(false);
    expect(mainNav.find({ children: 'API' }).exists()).toBe(false);
    expect(mainNav.find({ children: 'Jobs' }).exists()).toBe(false);
    expect(wrapper.find(Navbar).find({ bg: 'warning' }).exists()).toBe(false);
  });

  it('Properly renders Enroller Dashboard tab', () => {
    mockUser1.can_see_enroller_dashboard_tab = true;
    const wrapper = getWrapper({ current_user: mockUser1 });
    const mainNav = getMainNav(wrapper);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/patients` })
        .exists()
    ).toBe(true);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/patients` })
        .text()
    ).toEqual('Enroller Dashboard');
  });

  it('Properly renders Analytics tab', () => {
    mockUser1.can_see_analytics_tab = true;
    const wrapper = getWrapper({ current_user: mockUser1 });
    const mainNav = getMainNav(wrapper);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/analytics` })
        .exists()
    ).toBe(true);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/analytics` })
        .text()
    ).toEqual('Analytics');
  });

  it('Properly renders Monitoring Dashboards tab', () => {
    mockUser1.can_see_monitoring_dashboards_tab = true;
    const wrapper = getWrapper({ current_user: mockUser1 });
    const mainNav = getMainNav(wrapper);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/public_health` })
        .exists()
    ).toBe(true);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/public_health` })
        .text()
    ).toEqual('Monitoring Dashboards');
  });

  it('Properly renders USA admin tabs', () => {
    mockUser1.is_usa_admin = true;
    const wrapper = getWrapper({ current_user: mockUser1 });
    const mainNav = getMainNav(wrapper);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/oauth/applications` })
        .exists()
    ).toBe(true);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/oauth/applications` })
        .text()
    ).toEqual('API');
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/sidekiq` })
        .exists()
    ).toBe(true);
    expect(
      mainNav
        .find(Nav.Link)
        .find({ href: `${window.BASE_PATH}/sidekiq` })
        .text()
    ).toEqual('Jobs');
  });

  it('Shows help link menu with all help links', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(3);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual(helpLinks.user_guides);
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual(helpLinks.user_forum);
    expect(wrapper.find('.dropdown-item').find('a').at(2).prop('href')).toEqual(helpLinks.contact_us);
  });

  it('Shows help link menu with only two help links', () => {
    const wrapper = getWrapper({ help_links: { user_guides: null, user_forum: helpLinks.user_forum, contact_us: helpLinks.contact_us } });
    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(2);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual(helpLinks.user_forum);
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual(helpLinks.contact_us);
  });

  it('Hides help link menu when all help links are null', () => {
    const wrapper = getWrapper({ help_links: { user_guides: null, user_forum: '', contact_us: null } });
    expect(wrapper.find('.dropdown-menu').exists()).toBe(false);
  });

  it('Displays a banner message if defined', () => {
    const wrapper = getWrapper({ banner_message: bannerMessage });
    expect(wrapper.find(Navbar).find({ bg: 'warning' }).exists()).toBe(true);
    expect(wrapper.find(Navbar).find({ bg: 'warning' }).text()).toEqual(bannerMessage);
  });
});
