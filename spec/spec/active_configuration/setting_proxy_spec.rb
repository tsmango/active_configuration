require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveConfiguration::SettingProxy do
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
  
  describe "reading from a non-multiple option " do
    it "should respond to #[]" do
      @category.settings.sort.respond_to?('[]').should be_true
    end
    
    it "should return the default value for the sort option" do
      @category.settings.sort[:value].should eq('alphabetical')
    end
    
    it "should return the overridden value for the sort option" do
      @category.active_configuration_settings.create(:key => 'sort', :value => 'manual')
      @category.settings.sort[:value].should eq('manual')
    end
    
    it "should return the overridden modifier for the sort option" do
      @category.active_configuration_settings.create(:key => 'sort', :value => 'manual', :modifier => 'asc')
      @category.settings.sort[:modifier].should eq('asc')
    end
    
    it "should return a String for the sort option" do
      @category.settings.sort[:value].class.name.should eq('String')
    end
    
    it "should return a Fixnum for the limit option" do
      @category.settings.limit.update(:value => 25)
      @category.settings.limit[:value].class.name.should eq('Fixnum')
    end
    
    it "should return a TrueClass when deleted is set to true" do
      @category.settings.deleted.update(:value => true)
      @category.settings.deleted[:value].class.name.should eq('TrueClass')
    end
    
    it "should return a FalseClass when deleted is set to false" do
      @category.settings.deleted.update(:value => false)
      @category.settings.deleted[:value].class.name.should eq('FalseClass')
    end
    
    it "should raise an NoMethodError if #to_a is called" do
      lambda {
        @category.settings.sort.to_a
      }.should raise_error(NoMethodError)
    end
    
    it "should raise an NoMethodError if #collect is called" do
      lambda {
        @category.settings.sort.collect
      }.should raise_error(NoMethodError)
    end
    
    it "should raise an NoMethodError if #each is called" do
      lambda {
        @category.settings.sort.each
      }.should raise_error(NoMethodError)
    end
    
    it "should raise an NoMethodError if #each_with_index is called" do
      lambda {
        @category.settings.sort.each_with_index
      }.should raise_error(NoMethodError)
    end
    
    it "should raise an NoMethodError if #size is called" do
      lambda {
        @category.settings.sort.size
      }.should raise_error(NoMethodError)
    end
  end
  
  describe "reading from a multiple option " do
    it "should respond to #to_a" do
      @category.settings.sort.respond_to?('to_a').should be_true
    end
    
    it "should respond to #collect" do
      @category.settings.sort.respond_to?('collect').should be_true
    end
    
    it "should respond to #each" do
      @category.settings.sort.respond_to?('each').should be_true
    end
    
    it "should respond to #each_with_index" do
      @category.settings.sort.respond_to?('each_with_index').should be_true
    end
    
    it "should respond to #size" do
      @category.settings.sort.respond_to?('size').should be_true
    end
    
    it "should return all values and modifiers that have been set" do
      @category.active_configuration_settings.create(:key => 'price_filter', :modifier => 'gt',  :value => 10.00)
      @category.active_configuration_settings.create(:key => 'price_filter', :modifier => 'lte', :value => 25.00)
      @category.settings.price_filter.to_a.should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
    end
    
    it "should raise a NoMethodError if #[] is called" do
      lambda {
        @category.settings.price_filter[:value]
      }.should raise_error(NoMethodError)
    end
  end
  
  describe "updating a non-multiple option " do
    it "should allow updating the sort option to manual" do
      @category.settings.sort.update(:value => 'manual')
      @category.settings.sort[:value].should eq('manual')
    end
    
    it "should allow updating the limit option to 10" do
      @category.settings.limit.update(:value => 10)
      @category.settings.limit[:value].should eq(10)
    end
    
    it "should still contain the correct value after reloading the model" do
      @category.settings.sort.update(:value => 'manual')
      @category.reload
      @category.settings.sort[:value].should eq('manual')
    end
    
    it "should raise an ActiveConfiguration::Error when attempting to update the sort option to a value that doesn't appear in the list of restricted values" do
      lambda {
        @category.settings.sort.update(:value => 'dne')
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise an ActiveConfiguration::Error when attempting to update the limit option to something other than a fixnum" do
      lambda {
        @category.settings.limit.update(:value => 'Ten')
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise an ActiveConfiguration::Error when attemping to update a non-multiple option with multiple values" do
      lambda {
        @category.settings.sort.update({:value => 'alphabetical'}, {:value => 'manual'})
      }.should raise_error(ActiveConfiguration::Error)
    end
  end
  
  describe "updating a multiple option " do
    it "should allow adding price_filter settings for gt:10.00 and lte:25.00" do
      @category.settings.price_filter.update({:modifier => 'gt', :value => 10.00}, {:modifier => 'lte',  :value => 25.00})
      @category.settings.price_filter.to_a.should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
    end
    
    it "should still contain the correct price_filter settings after reloading the model" do
      @category.settings.price_filter.update({:modifier => 'gt', :value => 10.00}, {:modifier => 'lte',  :value => 25.00})
      @category.reload
      @category.settings.price_filter.to_a.should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
    end
    
    it "should raise and ActiveConfiguration::Error when attempting to set a modifier that doesn't appear in the list of allowed modifiers" do
      lambda {
        @category.settings.price_filter.update({:modifier => 'dne', :value => 10.00})
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise and ActiveConfiguration::Error when attempting to set a value that isn't a float" do
      lambda {
        @category.settings.price_filter.update({:modifier => 'gt', :value => 'Ten'})
      }.should raise_error(ActiveConfiguration::Error)
    end
  end
end