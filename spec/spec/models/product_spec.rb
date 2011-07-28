require File.dirname(__FILE__) + '/../spec_helper'

# This is an example of a model not configured for use with ActiveConfiguration.
# 
describe Product do
  it "should not respond to #active_configuration" do
    Product.respond_to?(:active_configuration).should be_false
  end
  
  it "should not respond to #settings" do
    Product.respond_to?(:settings).should be_false
  end
end