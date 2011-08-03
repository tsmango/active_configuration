require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveRecord::Configuration do
  describe "a correctly configured model " do
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
    end
    
    context "#configuration" do
      it "should respond to #configuration" do
        Category.respond_to?(:configuration).should be_true
      end
      
      it "should have a default value of alphabetical on the sort option" do
        Category.configuration.options[:sort].default_value.should eq('alphabetical')
      end
      
      it "should have allowed values of alphabetical and manual on the sort option" do
        Category.configuration.options[:sort].allowed_values.should =~ ['alphabetical', 'manual']
      end
      
      it "should have an allowed format of float on the price_filter option" do
        Category.configuration.options[:price_filter].allowed_format.should eq('float')
      end
      
      it "should have allowed modifiers of eq, lt, gt, lte and gte on the price_filter option" do
        Category.configuration.options[:price_filter].allowed_modifiers.should =~ ['eq', 'lt', 'gt', 'lte', 'gte']
      end
      
      it "should treat the price_filter option has a multiple option" do
        Category.configuration.options[:price_filter].allow_multiple.should be_true
      end
      
      it "should have an allowed format of fixnum on the limit option" do
        Category.configuration.options[:limit].allowed_format.should eq('fixnum')
      end
      
      it "should have an allowed format of boolean on the deleted option" do
        Category.configuration.options[:deleted].allowed_format.should eq('boolean')
      end
    end
    
    context "#active_configuration_settings " do
      before(:each) do
        @category = Category.create(:name => 'Vinyl')
      end
      
      it "should respond to #active_configuration_settings" do
        @category.respond_to?(:active_configuration_settings).should be_true
      end
      
      it "should have an empty array of active_configuration_settings" do
        @category.active_configuration_settings.all.should =~ []
      end
      
      it "should contain instances of ActiveConfiguration::Setting when not empty" do
        @category.active_configuration_settings.create(:key => 'sort', :value => 'manual')
        @category.active_configuration_settings.first.class.name.should eq('ActiveConfiguration::Setting')
      end
    end
    
    context "#settings " do
      before(:each) do
        @category = Category.create(:name => 'Vinyl')
      end
      
      it "should respond to #settings" do
        @category.respond_to?(:settings).should be_true
      end
      
      it "should return an ActiveConfiguration::SettingManager from #settings" do
        @category.settings.class.name.should eq('ActiveConfiguration::SettingManager')
      end
    end
  end
  
  describe "allowed configuration options " do
    it "should allow true for the multiple option" do
      class Category < ActiveRecord::Base
        configure do
          option :price_filter do
            multiple true
          end
        end
      end
      
      Category.configuration.options[:price_filter].allow_multiple.should be_true
    end
    
    it "should allow false for the multiple option" do
      class Category < ActiveRecord::Base
        configure do
          option :sort do
            multiple false
          end
        end
      end
      
      Category.configuration.options[:sort].allow_multiple.should be_false
    end
    
    it "should allow a string format" do
      class Category < ActiveRecord::Base
        configure do
          option :sort do
            format 'string'
          end
        end
      end
      
      Category.configuration.options[:sort].allowed_format.should eq('string')
    end
    
    it "should allow a fixnum format" do
      class Category < ActiveRecord::Base
        configure do
          option :limit do
            format 'fixnum'
          end
        end
      end
      
      Category.configuration.options[:limit].allowed_format.should eq('fixnum')
    end
    
    it "should allow a float format" do
      class Category < ActiveRecord::Base
        configure do
          option :price_filter do
            format 'float'
          end
        end
      end
      
      Category.configuration.options[:price_filter].allowed_format.should eq('float')
    end
    
    it "should allow a boolean format" do
      class Category < ActiveRecord::Base
        configure do
          option :deleted do
            format 'boolean'
          end
        end
      end
      
      Category.configuration.options[:deleted].allowed_format.should eq('boolean')
    end
    
    it "should allow a email format" do
      class Category < ActiveRecord::Base
        configure do
          option :support_email do
            format 'email'
          end
        end
      end
      
      Category.configuration.options[:support_email].allowed_format.should eq('email')
    end
    
    it "should allow a url format" do
      class Category < ActiveRecord::Base
        configure do
          option :support_url do
            format 'url'
          end
        end
      end
      
      Category.configuration.options[:support_url].allowed_format.should eq('url')
    end
    
    it "should allow a regular expression format" do
      class Category < ActiveRecord::Base
        configure do
          option :support_url do
            format /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
          end
        end
      end
      
      Category.configuration.options[:support_url].allowed_format.class.name.should eq('Regexp')
    end
  end
  
  describe "an incorrectly configured model " do
    it "should raise an ActiveConfiguration::Error when the default value given doesn't appear in the list of restricted values" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :sort do
              default  'alphabetical'
              restrict 'manual'
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise an ActiveConfiguration::Error when a String is given for the multiple option" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :price_filter do
              multiple 'true'
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise an ActiveConfiguration::Error when a Fixnum is given for the multiple option" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :price_filter do
              multiple 1
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise an ActiveConfiguration::Error when nil is given for the multiple option" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :price_filter do
              multiple nil
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise an ActiveConfiguration::Error when both a default value is given and the multiple option is set to true" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :price_filter do
              default  10.00
              multiple true
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should raise an ActiveConfiguration::Error if an unapproved format is specified" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :price_filter do
              format :currency
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
  end
  
  describe "an unconfigured model " do
    before(:each) do
      class Product < ActiveRecord::Base; end
    end
    
    it "should not respond to #configuration" do
      Product.respond_to?(:configuration).should be_false
    end
    
    it "should not respond to #active_configuration_settings" do
      Product.new.respond_to?(:active_configuration_settings).should be_false
    end
    
    it "should not respond to #settings" do
      Product.new.respond_to?(:settings).should be_false
    end
  end
end