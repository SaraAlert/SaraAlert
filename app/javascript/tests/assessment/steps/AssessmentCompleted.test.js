import React from 'react'
import { shallow } from 'enzyme';
import { Card, Form } from 'react-bootstrap';
import AssessmentCompleted from '../../../components/assessment/steps/AssessmentCompleted.js'
import { mockTranslations } from '../../mocks/mockTranslations'

const contact = {
  email: 'email@example.com',
  phone: '1111111111',
  webpage: 'somewebpage.com'
}

function getWrapper(language, contactInfo) {
  return shallow(<AssessmentCompleted lang={language} translations={mockTranslations} contact_info={contactInfo} />);
}

describe('AssessmentCompleted', () => {
  it('Properly renders all main components in English', () => {
    const language = 'en';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[language]['web']['title']);
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[language]['web']['thank-you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction1'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction2'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction3'])).toBeTruthy();
  });

  it('Properly renders all main components in Spanish', () => {
    const language = 'es';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[language]['web']['title']);
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[language]['web']['thank-you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction1'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction2'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction3'])).toBeTruthy();
  });

  it('Properly renders all main components in Spanish (Puerto Rican)', () => {
    const language = 'es-PR';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[language]['web']['title']);
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[language]['web']['thank-you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction1'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction2'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction3'])).toBeTruthy();
  });

  it('Properly renders all main components in French', () => {
    const language = 'fr';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[language]['web']['title']);
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[language]['web']['thank-you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction1'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction2'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction3'])).toBeTruthy();
  });

  it('Properly renders all main components in Somali', () => {
    const language = 'so';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[language]['web']['title']);
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[language]['web']['thank-you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction1'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction2'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['instruction3'])).toBeTruthy();
  });

  it('Properly renders email contact information', () => {
    const language = 'en';
    const wrapper = getWrapper(language, { email: 'email@example.com' });
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['email'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').hasClass('fa-envelope')).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').text()).toEqual(' email@example.com');
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').prop('href')).toEqual('mailto:email@example.com');
  });

  it('Properly renders phone contact information', () => {
    const language = 'en';
    const wrapper = getWrapper(language, { phone: '1111111111' });
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['phone'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').hasClass('fa-phone')).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').text()).toEqual(' 1111111111');
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').prop('href')).toEqual('tel:1111111111');
  });

  it('Properly renders webpage contact information', () => {
    const language = 'en';
    const wrapper = getWrapper(language, { webpage: 'somewebpage.com' });
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['webpage'])).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').hasClass('fa-desktop')).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').text()).toEqual(' somewebpage.com');
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').prop('href')).toEqual('somewebpage.com');
  });

  it('Hides contact information when none is provided', () => {
    const language = 'en';
    const wrapper = getWrapper(language, {});
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['email'])).toBeFalsy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['phone'])).toBeFalsy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text().includes(mockTranslations[language]['web']['webpage'])).toBeFalsy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBeFalsy();
  });
});
