require File.dirname(__FILE__) + '/../spec_helper'

# This is an example of a model configured for use with ActiveConfiguration.
# 
# The class is redefined here so that various configurations can be tested 
# without hardcoding the configuration in the model that lives in app/models.
# 
describe Category do
  describe "has a correct configuration and" do
    before(:each) do
      class Category < ActiveRecord::Base
        configure do
          option :sort do
            default  'alphabetical'
            restrict 'alphabetical', 'manual'
          end
          
          option :containment_rule_price do
            format    'float'
            modifiers 'eq', 'lt', 'gt', 'lte', 'gte'
            multiple  true
          end
          
          option :limit do
            format :fixnum
          end
        end
      end
    end
    
    context "#configure" do
      it "should have a default value of 'alphabetical'" do
        Category.configuration.options[:sort].default_value.should eq('alphabetical')
      end
      
      it "should have an allowed format of 'float'" do
        Category.configuration.options[:containment_rule_price].allowed_format.should eq('float')
      end
      
      it "should have many allowed modifiers" do
        Category.configuration.options[:containment_rule_price].allowed_modifiers.should =~ ['eq', 'lt', 'gt', 'lte', 'gte']
      end
      
      it "should have the allow multiple option set to true" do
        Category.configuration.options[:containment_rule_price].allow_multiple.should be_true
      end
    end
    
    context "#settings" do
      it "should respond to #settings" do
        Category.new.respond_to?(:settings).should be_true
      end
      
      it "should have an empty array of settings" do
        Category.new.settings.all.should =~ []
      end
      
      it "should have a setting" do
        Category.create(:name => 'Vinyl')
        Category.find_by_name('Vinyl').settings.create(:key => 'sort', :value => 'alphabetical')
        Category.find_by_name('Vinyl').settings.count.should eq(1)
      end
    end
    
    describe "has settings configured against options" do
      before(:each) do
        @category = Category.create(:name => 'Vinyl')
      end
      
      describe "and can be read from the #setting method" do
        it "should return the default value for the sort setting" do
          @category.setting.sort[:value].should eq('alphabetical')
        end
        
        it "should return the overridden value for the sort setting" do
          @category.settings.create(:key => 'sort', :value => 'manual')
          @category.setting.sort[:value].should eq('manual')
        end
        
        it "should return all values and modifiers for an option marked as multiple" do
          @category.settings.create(:key => 'containment_rule_price', :modifier => 'gt',  :value => 10.00)
          @category.settings.create(:key => 'containment_rule_price', :modifier => 'lte', :value => 25.00)
          @category.setting.containment_rule_price.to_a.should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
        end
      end
      
      describe "and can be set from the #setting method" do
        it "should override the default value for the sort setting with the given value" do
          @category.setting.sort[:value].should eq('alphabetical')
          @category.setting.sort.update(:value => 'manual')
          @category.setting.sort[:value].should eq('manual')
        end
        
        describe "and can handle updating options marked as multiple" do
          before(:each) do
            @category.setting.sort.update(:value => 'manual')
            @category.setting.containment_rule_price.to_a.should =~ []
            @category.setting.containment_rule_price.update(
              {:modifier => 'gt',  :value => 10.00}, 
              {:modifier => 'lte', :value => 25.00}
            )
          end
          
          it "should return the overridden value for the sort setting" do
            @category.setting.sort[:value].should eq('manual')
          end
          
          it "should handle updating values and modifiers for options marked as multiple" do
            @category.setting.containment_rule_price.to_a.should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
          end
          
          it "should have the correct values even after a reload" do
            @category.reload
            @category.setting.containment_rule_price.to_a.should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
          end

          it "should handle updating values and modifiers for options marked as multiple, many times in a row" do
            @category.setting.containment_rule_price.update(
              {:modifier => 'gt',  :value => 25.00}, 
              {:modifier => 'lte', :value => 50.00}
            )
            @category.setting.containment_rule_price.to_a.should =~ [{:modifier => 'gt', :value => 25.00}, {:modifier => 'lte', :value => 50.00}]
          end
        end
      end
      
      describe "and will reject any invalid changes" do
        it "should reject a value that doesn't appear in the list of allowed values" do
          lambda {
            @category.setting.sort.update('price-high-low')
          }.should raise_error(ActiveConfiguration::Error)
        end
        
        it "should reject a value with an improper format" do
          lambda {
            @category.setting.limit.update('Ten Products')
          }.should raise_error(ActiveConfiguration::Error)
        end
        
        it "should reject a call to #[] for an option marked as multiple" do
          lambda {
            @category.setting.containment_rule_price[:value]
          }.should raise_error(NoMethodError)
        end
        
        it "should reject a call to #to_a for an option marked as multiple" do
          lambda {
            @category.setting.sort.to_a
          }.should raise_error(NoMethodError)
        end
        
        it "should reject a call to #collect for an option marked as multiple" do
          lambda {
            @category.setting.sort.collect
          }.should raise_error(NoMethodError)
        end
        
        it "should reject a call to #each for an option marked as multiple" do
          lambda {
            @category.setting.sort.each
          }.should raise_error(NoMethodError)
        end
        
        it "should reject a call to #each_with_index for an option marked as multiple" do
          lambda {
            @category.setting.sort.each_with_index
          }.should raise_error(NoMethodError)
        end
        
        it "should reject a call to #size for an option marked as multiple" do
          lambda {
            @category.setting.sort.size
          }.should raise_error(NoMethodError)
        end
      end
    end
  end
  
  describe "has an incorrect configuration and" do
    it "should reject any default value that doesn't appear in a given list of restricted values" do
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
    
    it "should reject a string for the multiple option" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :containment_rule_price do
              multiple 'true'
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should reject an int for the multiple option" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :containment_rule_price do
              multiple 1
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
    
    it "should reject nil for the multiple option" do
      lambda {
        class Category < ActiveRecord::Base
          configure do
            option :containment_rule_price do
              multiple nil
            end
          end
        end
      }.should raise_error(ActiveConfiguration::Error)
    end
  end
end