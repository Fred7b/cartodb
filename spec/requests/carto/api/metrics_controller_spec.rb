# encoding utf-8

require 'spec_helper_min'
require 'support/helpers'

describe Carto::Api::MetricsController do
  include Warden::Test::Helpers
  include HelperMethods

  before(:all) do
    @user = FactoryGirl.create(:carto_user)
    login(@user)
  end

  after(:all) do
    @user.destroy
  end

  it 'should accept all existing events' do
    Carto::Tracking::Events::Event.descendants.each do |event_class|
      event = event_class.new(user_id: @user.id)

      payload = {
        name: event.name,
        properties: {
          user_id: @user.id
        }
      }

      post_json metrics_url, payload do |response|
        response.status.should eq 201
      end
    end
  end

  it 'should reject non existing events' do
    event_name = 'Everything was a lie'

    post_json metrics_url, name: event_name do |response|
      response.status.should eq 404
      response.body[:errors].should eq "Event not found: #{event_name}"
    end
  end

  describe 'security' do
    before(:all) do
      logout(@user)
      @intruder = FactoryGirl.create(:carto_user)
      login(@intruder)
    end

    after(:all) do
      logout(@intruder)
      @intruder.destroy
      login(@user)
    end

    it 'should reject unauthorized requests' do
      post_json metrics_url, name: event_name do |response|
        response.status.should eq 404
        response.body[:errors].should eq "Event not found: #{event_name}"
      end
    end
end
