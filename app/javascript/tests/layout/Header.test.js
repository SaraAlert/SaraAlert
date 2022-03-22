import React from 'react';
import { shallow } from 'enzyme';
import Header from '../../components/layout/Header';
import { mockUser1 } from '../mocks/mockUsers';

const helpLinks = {
  user_guides: 'https://www.sara.org/user-guides',
  user_forum: 'https://www.sara.org/user-forum',
  contact_us: 'https://www.sara.org/contact-us',
};

/**
 * If additionalProps undefiend, the Header component is rendered with the default props included below
 * If any props are defined in additional props, they overwrite whatever the default value was set as
 */
function getWrapper(additionalProps) {
  return shallow(<Header report_mode={false} show_demo_warning_background={false} banner_message="" current_user={mockUser1} help_links={helpLinks} {...additionalProps} />);
}

describe('Header', () => {
  it('Shows help link menu with all help links', () => {
    const wrapper = getWrapper();

    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(3);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual(helpLinks.user_guides);
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual(helpLinks.user_forum);
    expect(wrapper.find('.dropdown-item').find('a').at(2).prop('href')).toEqual(helpLinks.contact_us);
  });

  it('Shows help link menu with only two help links', () => {
    const wrapper = getWrapper({ help_links: { user_guides: null, user_forum: 'https://www.sara.org/user-forum', contact_us: 'https://www.sara.org/contact-us' } });

    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(2);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual('https://www.sara.org/user-forum');
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual('https://www.sara.org/contact-us');
  });

  it('Hides help link menu when all help links are null', () => {
    const wrapper = getWrapper({ help_links: { user_guides: null, user_forum: '', contact_us: null } });

    expect(wrapper.find('.dropdown-menu').exists()).toBe(false);
  });
});
