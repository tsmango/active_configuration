require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveConfiguration::Base do
  before(:each) do
    @configuration = ActiveConfiguration::Base.new
  end
  
  context "#instance_eval" do
    it "should accept any default value when restricted values aren't given" do
      @configuration.instance_eval do
        option :sort do
          default :alphabetical
        end
      end
      
      @configuration.options[:sort].default_value.should eq(:alphabetical)
    end
    
    it "should accept any default value that does appear in a given list of restricted values" do
      @configuration.instance_eval do
        option :sort do
          default  :alphabetical
          restrict :alphabetical, :manual
        end
      end
      
      @configuration.options[:sort].default_value.should eq(:alphabetical)
    end
    
    it "should reject any default value that doesn't appear in a given list of restricted values" do
      lambda {
        @configuration.instance_eval do
          option :sort do
            default  :alphabetical
            restrict :manual
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should accept any format" do
      @configuration.instance_eval do
        option :containment_rule_price do
          format :float
        end
      end
      
      @configuration.options[:containment_rule_price].allowed_format.should eq(:float)
    end
    
    it "should accept one modifier" do
      @configuration.instance_eval do
        option :containment_rule_price do
          modifiers :eq
        end
      end
      
      @configuration.options[:containment_rule_price].allowed_modifiers.should =~ [:eq]
    end
    
    it "should accept many modifiers" do
      @configuration.instance_eval do
        option :containment_rule_price do
          modifiers :eq, :lt, :gt, :lte, :gte
        end
      end
      
      @configuration.options[:containment_rule_price].allowed_modifiers.should =~ [:eq, :lt, :gt, :lte, :gte]
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
  end
end