require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveConfiguration::Base do
  before(:each) do
    @configuration = ActiveConfiguration::Base.new
  end

  it "should setup a sort option" do
    @configuration.instance_eval do
      option :sort do
        default 'alphabetical'
      end
    end

    @configuration.options[:sort].should_not be_blank
  end
end