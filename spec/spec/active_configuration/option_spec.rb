require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveConfiguration::Base do
  before(:each) do
    @configuration = ActiveConfiguration::Base.new
  end

  describe "a valid configuration " do
    it "should accept any default value when restricted values aren't given" do
      @configuration.instance_eval do
        option :sort do
          default 'alphabetical'
        end
      end

      @configuration.options[:sort].default_value.should eq('alphabetical')
    end

    it "should accept any default value that does appear in a given list of restricted values" do
      @configuration.instance_eval do
        option :sort do
          default  'alphabetical'
          restrict 'alphabetical', 'manual'
        end
      end

      @configuration.options[:sort].default_value.should eq('alphabetical')
    end

    it "should accept a string format" do
      @configuration.instance_eval do
        option :alternative_name do
          format 'string'
        end
      end

      @configuration.options[:alternative_name].allowed_format.should eq('string')
    end

    it "should accept a fixnum format" do
      @configuration.instance_eval do
        option :limit do
          format 'fixnum'
        end
      end

      @configuration.options[:limit].allowed_format.should eq('fixnum')
    end

    it "should accept a float format" do
      @configuration.instance_eval do
        option :price_filter do
          format 'float'
        end
      end

      @configuration.options[:price_filter].allowed_format.should eq('float')
    end

    it "should accept a boolean format" do
      @configuration.instance_eval do
        option :deleted do
          format 'boolean'
        end
      end

      @configuration.options[:deleted].allowed_format.should eq('boolean')
    end

    it "should accept a email format" do
      @configuration.instance_eval do
        option :support_email_address do
          format 'email'
        end
      end

      @configuration.options[:support_email_address].allowed_format.should eq('email')
    end

    it "should accept a url format" do
      @configuration.instance_eval do
        option :support_url do
          format 'url'
        end
      end

      @configuration.options[:support_url].allowed_format.should eq('url')
    end

    it "should accept a regular expression format" do
      @configuration.instance_eval do
        option :support_url do
          format /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
        end
      end

      @configuration.options[:support_url].allowed_format.is_a?(Regexp).should be_true
    end

    it "should accept one modifier" do
      @configuration.instance_eval do
        option :price_filter do
          modifiers 'eq'
        end
      end

      @configuration.options[:price_filter].allowed_modifiers.should =~ ['eq']
    end

    it "should accept many modifiers" do
      @configuration.instance_eval do
        option :price_filter do
          modifiers 'eq', 'lt', 'gt', 'lte', 'gte'
        end
      end

      @configuration.options[:price_filter].allowed_modifiers.should =~ ['eq', 'lt', 'gt', 'lte', 'gte']
    end

    it "should accept true for the multiple option" do
      @configuration.instance_eval do
        option :price_filter do
          multiple true
        end
      end

      @configuration.options[:price_filter].allow_multiple.should be_true
    end

    it "should accept false for the multiple option" do
      @configuration.instance_eval do
        option :price_filter do
          multiple false
        end
      end

      @configuration.options[:price_filter].allow_multiple.should be_false
    end
  end

  describe "an invalid configuration " do
    it "should raise an ActiveConfiguration::Error when the default value given doesn't appear in the list of restricted values" do
      lambda {
        @configuration.instance_eval do
          option :sort do
            default  'alphabetical'
            restrict 'manual'
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end

    it "should raise an ActiveConfiguration::Error when a String is given for the multiple option" do
      lambda {
        @configuration.instance_eval do
          option :price_filter do
            multiple 'true'
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end

    it "should raise an ActiveConfiguration::Error when a Fixnum is given for the multiple option" do
      lambda {
        @configuration.instance_eval do
          option :price_filter do
            multiple 1
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end

    it "should raise an ActiveConfiguration::Error when nil is given for the multiple option" do
      lambda {
        @configuration.instance_eval do
          option :price_filter do
            multiple nil
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end

    it "should raise an ActiveConfiguration::Error when both a default value is given and the multiple option is set to true" do
      lambda {
        @configuration.instance_eval do
          option :price_filter do
            default  10.00
            multiple true
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end

    it "should raise an ActiveConfiguration::Error if an unapproved format is specified" do
      lambda {
        @configuration.instance_eval do
          option :price_filter do
            format :currency
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
  end
end