require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveConfiguration::Base do
  before(:each) do
    @configuration = ActiveConfiguration::Base.new
  end
  
  context "#instance_eval" do
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
    
    it "should reject any default value that doesn't appear in a given list of restricted values" do
      lambda {
        @configuration.instance_eval do
          option :sort do
            default  'alphabetical'
            restrict 'manual'
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
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
        option :containment_rule_price do
          format 'float'
        end
      end
      
      @configuration.options[:containment_rule_price].allowed_format.should eq('float')
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
    
    it "should reject a format that isn't supported" do
      lambda {
        @configuration.instance_eval do
          option :support_url do
            format 'invalid_format'
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should accept one modifier" do
      @configuration.instance_eval do
        option :containment_rule_price do
          modifiers 'eq'
        end
      end
      
      @configuration.options[:containment_rule_price].allowed_modifiers.should =~ ['eq']
    end
    
    it "should accept many modifiers" do
      @configuration.instance_eval do
        option :containment_rule_price do
          modifiers 'eq', 'lt', 'gt', 'lte', 'gte'
        end
      end
      
      @configuration.options[:containment_rule_price].allowed_modifiers.should =~ ['eq', 'lt', 'gt', 'lte', 'gte']
    end
    
    it "should accept true for the multiple option" do
      @configuration.instance_eval do
        option :containment_rule_price do
          multiple true
        end
      end
      
      @configuration.options[:containment_rule_price].allow_multiple.should be_true
    end
    
    it "should accept false for the multiple option" do
      @configuration.instance_eval do
        option :containment_rule_price do
          multiple false
        end
      end
      
      @configuration.options[:containment_rule_price].allow_multiple.should be_false
    end
    
    it "should reject a string for the multiple option" do
      lambda {
        @configuration.instance_eval do
          option :containment_rule_price do
            multiple 'true'
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should reject an int for the multiple option" do
      lambda {
        @configuration.instance_eval do
          option :containment_rule_price do
            multiple 1
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should reject nil for the multiple option" do
      lambda {
        @configuration.instance_eval do
          option :containment_rule_price do
            multiple nil
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should reject a default value when the multiple option is true" do
      lambda {
        @configuration.instance_eval do
          option :containment_rule_price do
            default  '25.00'
            multiple true
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
  end
end