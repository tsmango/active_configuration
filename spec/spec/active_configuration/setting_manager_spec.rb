require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveConfiguration::SettingManager do
  before(:each) do
    class Category < ActiveRecord::Base
      configure do
        option :sort do
          default  'alphabetical'
          restrict 'alphabetical', 'manual'
        end

        option :price_filter do
          format    'float'
          modifiers 'eq', 'lt', 'gt', 'lte', 'gte'
          multiple  true
        end

        option :limit do
          format :fixnum
        end

        option :deleted do
          default false
          format  :boolean
        end
      end
    end

    @category = Category.create(:name => 'Vinyl')
  end

  describe "reading settings from the #settings method " do
    it "should respond to #settings.sort" do
      @category.settings.respond_to?(:sort).should be_true
    end

    it "should return an ActiveConfiguration::SettingProxy from #settings.sort" do
      @category.settings.sort.class.name.should eq('ActiveConfiguration::SettingProxy')
    end

    it "should respond to #settings.price_filter" do
      @category.settings.respond_to?(:price_filter).should be_true
    end

    it "should return an ActiveConfiguration::SettingProxy from #settings.price_filter" do
      @category.settings.price_filter.class.name.should eq('ActiveConfiguration::SettingProxy')
    end

    it "should respond to #settings.limit" do
      @category.settings.respond_to?(:limit).should be_true
    end

    it "should return an ActiveConfiguration::SettingProxy from #settings.limit" do
      @category.settings.limit.class.name.should eq('ActiveConfiguration::SettingProxy')
    end

    it "should respond to #settings.deleted" do
      @category.settings.respond_to?(:deleted).should be_true
    end

    it "should return an ActiveConfiguration::SettingProxy from #settings.deleted" do
      @category.settings.deleted.class.name.should eq('ActiveConfiguration::SettingProxy')
    end

    it "should not respond to #settings.dne because the 'dne' option does not exist" do
      @category.respond_to?(:dne).should be_false
    end

    it "should raise a NoMethodError when attempting to read a setting that this model isn't configured for" do
      lambda {
        @category.setting.dne
      }.should raise_error(NoMethodError)
    end
  end
end