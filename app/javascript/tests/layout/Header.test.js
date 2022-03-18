import React from 'react';
import { shallow } from 'enzyme';
import Header from '../../components/layout/Header';
import { mockUser1 } from '../mocks/mockUsers';

let help_links = {
  user_guides: 'https://www.sara.org/user-guides',
  user_forum: 'https://www.sara.org/user-forum',
  contact_us: 'https://www.sara.org/contact-us',
};

describe('Header', () => {
  it('Shows help link menu with all help links', () => {
    const wrapper = shallow(<Header report_mode={false} show_demo_warning_background={false} banner_message="" current_user={mockUser1} help_links={help_links} />);

    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(3);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual('https://www.sara.org/user-guides');
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual('https://www.sara.org/user-forum');
    expect(wrapper.find('.dropdown-item').find('a').at(2).prop('href')).toEqual('https://www.sara.org/contact-us');
  });

  it('Shows help link menu with only two help links', () => {
    help_links.user_guides = null;

    const wrapper = shallow(<Header report_mode={false} show_demo_warning_background={false} banner_message="" current_user={mockUser1} help_links={help_links} />);

    expect(wrapper.find('.dropdown-menu').exists()).toBe(true);
    expect(wrapper.find('.dropdown-menu').children()).toHaveLength(2);
    expect(wrapper.find('.dropdown-item').find('a').at(0).prop('href')).toEqual('https://www.sara.org/user-forum');
    expect(wrapper.find('.dropdown-item').find('a').at(1).prop('href')).toEqual('https://www.sara.org/contact-us');
  });

  it('Hides help link menu when all help links are null', () => {
    Object.keys(help_links).forEach(key => (help_links[key] = null));

    const wrapper = shallow(<Header report_mode={false} show_demo_warning_background={false} banner_message="" current_user={mockUser1} help_links={help_links} />);

    expect(wrapper.find('.dropdown-menu').exists()).toBe(false);
  });
});
