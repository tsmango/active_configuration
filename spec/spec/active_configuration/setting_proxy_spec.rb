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
    it "should contain a Hash as the representation of the sort setting" do
      @category.settings[:sort].class.name.should eq('Hash')
    end

    it "should return the default value for the sort option" do
      @category.settings[:sort][:value].should eq('alphabetical')
    end

    it "should return the overridden value for the sort option" do
      @category.active_configuration_settings.create(:key => 'sort', :value => 'manual')
      @category.settings[:sort][:value].should eq('manual')
    end

    it "should return the overridden modifier for the sort option" do
      @category.active_configuration_settings.create(:key => 'sort', :value => 'manual', :modifier => 'asc')
      @category.settings[:sort][:modifier].should eq('asc')
    end

    it "should return a String for the sort option" do
      @category.settings[:sort][:value] = 'manual'
      @category.settings[:sort][:value].class.name.should eq('String')
    end

    it "should return a Fixnum for the limit option" do
      @category.settings[:limit][:value] = 25
      @category.settings[:limit][:value].class.name.should eq('Fixnum')
    end

    it "should return a TrueClass when deleted is set to true" do
      @category.settings[:deleted][:value] = true
      @category.settings[:deleted][:value].class.name.should eq('TrueClass')
    end

    it "should return a FalseClass when deleted is set to false" do
      @category.settings[:deleted][:value] = false
      @category.settings[:deleted][:value].class.name.should eq('FalseClass')
    end
  end

  describe "reading from a multiple option " do
    it "should contain an Array as the representation of the price_filter setting" do
      @category.settings[:price_filter].class.name.should eq('Array')
    end

    it "should return all values and modifiers that have been set" do
      @category.active_configuration_settings.create(:key => 'price_filter', :modifier => 'gt',  :value => 10.00)
      @category.active_configuration_settings.create(:key => 'price_filter', :modifier => 'lte', :value => 25.00)
      @category.settings[:price_filter].should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
    end
  end

  context "#replace" do
    describe "replacing a non-multiple option " do
      before(:each) do
        @category.settings[:sort] = {:value => 'manual'}
        @proxy = @category.settings.settings[:sort]
      end

      it "should accept replacement of both the value and modifier" do
        @proxy.replace({:value => 'alphabetical', :modifier => 'asc'})
        @category.settings[:sort][:modifier].should eq('asc')
        @category.settings[:sort][:value].should    eq('alphabetical')
      end

      it "should revert to default values when replaced with nil" do
        @proxy.replace(nil)
        @category.settings[:sort][:modifier].should be_nil
        @category.settings[:sort][:value].should    eq('alphabetical')
      end

      it "should raise an ArgumentError when not replaced with a Hash" do
        lambda {
          @proxy.replace([{:value => 'alphabetical'}, {:value => 'manual'}])
        }.should raise_error(ArgumentError)

        lambda {
          @proxy.replace('invalid')
        }.should raise_error(ArgumentError)
      end
    end

    describe "replacing a multiple option " do
      before(:each) do
        @category.settings[:price_filter] = {:modifier => 'lte', :value => 25.00}
        @proxy = @category.settings.settings[:price_filter]
      end

      it "should accept replacement of a modifier and value as a single hashes" do
        @proxy.replace({:modifier => 'gt', :value => 10.00})
        @category.settings[:price_filter].should =~ [{:modifier => 'gt', :value => 10.00}]
      end

      it "should accept replacement of modifiers and values as an array of hashes" do
        @proxy.replace([{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}])
        @category.settings[:price_filter].should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
      end

      it "should remove all modifiers and values when replaced with nil" do
        @proxy.replace(nil)
        @category.settings[:price_filter].should =~ []
      end

      it "should raise an ArgumentError when not replaced with a Hash or an Array" do
        lambda {
          @proxy.replace('invalid')
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "validation errors are generated and stored within the proxy's model" do
    before(:each) do
      @category.settings[:sort]
      @category.settings[:price_filter]
      @category.settings[:limit]
      @category.settings[:deleted]

      @sort_proxy         = @category.settings.settings[:sort]
      @price_filter_proxy = @category.settings.settings[:price_filter]
      @limit_proxy        = @category.settings.settings[:limit]
      @deleted_proxy      = @category.settings.settings[:deleted]
    end

    it "should generate an error if the value doesn't appear in the list of restricted values" do
      @category.settings[:sort][:value] = 'dne'
      @sort_proxy.validate
      @category.errors[:settings].size.should > 0
    end

    it "should generate an error if the price_filter's option is set to something other than a float" do
      @category.settings[:price_filter] = {:value => 'Ten Dollars'}
      @price_filter_proxy.validate
      @category.errors[:settings].size.should > 0
    end

    it "should generate an error if the limit option is set to something other than a fixnum" do
      @category.settings[:limit][:value] = 'Ten'
      @limit_proxy.validate
      @category.errors[:settings].size.should > 0
    end

    it "should generate an error if the deleted option is set to something other than a boolean" do
      @category.settings[:deleted][:value] = 'yes'
      @deleted_proxy.validate
      @category.errors[:settings].size.should > 0
    end
  end

  context "#save" do
    describe "updating a non-multiple option " do
      it "should allow updating the sort option to manual" do
        @category.settings[:sort] = {:value => 'manual'}
        @category.save
        @category.settings[:sort][:value].should eq('manual')
      end

      it "should allow updating the limit option to 10" do
        @category.settings[:limit] = {:value => 10}
        @category.save
        @category.settings[:limit][:value].should eq(10)
      end

      it "should forget an assigned value after reloading the model without saving" do
        @category.settings[:sort] = {:value => 'manual'}
        @category.reload
        @category.settings[:sort][:value].should eq('alphabetical')
      end

      it "should still contain the correct value after saving and reloading the model" do
        @category.settings[:sort] = {:value => 'manual'}
        @category.save
        @category.reload
        @category.settings[:sort][:value].should eq('manual')
      end

      it "should update category's set of errors when attempting to update the sort option to a value that doesn't appear in the list of restricted values" do
        @category.settings[:sort][:value] = 'dne'
        @category.save
        @category.errors[:settings].size.should > 0
      end

      it "should return false when attempting to save a model when the sort option doesn't appear in the list of restricted values" do
        @category.settings[:sort][:value] = 'dne'
        @category.save.should be_false
      end

      it "should update category's set of errors when attempting to update the limit option to something other than a fixnum" do
         @category.settings[:limit][:value] = 'Ten'
         @category.save
         @category.errors[:settings].size.should > 0
      end

      it "should return false when attempting to save a model when the limit option is set to something other than a fixnum" do
        @category.settings[:limit][:value] = 'Ten'
        @category.save.should be_false
      end

      it "should update category's set of errors when attempting to update the deleted option to something other than a boolean" do
         @category.settings[:deleted][:value] = 'yes'
         @category.save
         @category.errors[:settings].size.should > 0
      end

      it "should return false when attempting to save a model when the deleted option is set to something other than a boolean" do
        @category.settings[:deleted][:value] = 'yes'
        @category.save.should be_false
      end

      it "should raise an ArgumentError when attemping to set a non-multiple option with multiple values" do
        lambda {
          @category.settings[:sort] = [{:value => 'alphabetical'}, {:value => 'manual'}]
        }.should raise_error(ArgumentError)
      end
    end

    describe "updating a multiple option " do
      it "should allow adding price_filter settings for gt:10.00 and lte:25.00" do
        @category.settings[:price_filter] = [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte',  :value => 25.00}]
        @category.save
        @category.settings[:price_filter].should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
      end

      it "should forget the assigned values to the price_filter settings after reloading the model without saving" do
        @category.settings[:price_filter] = [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte',  :value => 25.00}]
        @category.reload
        @category.settings[:price_filter].should =~ []
      end

      it "should still contain the correct price_filter settings after saving and reloading the model" do
        @category.settings[:price_filter] = [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte',  :value => 25.00}]
        @category.save
        @category.reload
        @category.settings[:price_filter].should =~ [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
      end

      it "should update category's set of errors when attempting to set a modifier that doesn't appear in the list of allowed modifiers" do
        @category.settings[:price_filter] = {:modifier => 'dne', :value => 10.00}
        @category.save
        @category.errors[:settings].size.should > 0
      end

      it "should return false when attempting to save a model when the a modifier that doesn't appear in the list of allowed modifiers" do
        @category.settings[:price_filter] = {:modifier => 'dne', :value => 10.00}
        @category.save.should be_false
      end

      it "should update category's set of errors when attempting to set a value that isn't a float" do
        @category.settings[:price_filter] = {:modifier => 'gt', :value => 'Ten'}
        @category.save
        @category.errors[:settings].size.should > 0
      end

      it "should return false when attempting to save a model when thevalue that isn't a float" do
        @category.settings[:price_filter] = {:modifier => 'gt', :value => 'Ten'}
        @category.save.should be_false
      end
    end
  end
end