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
    it "should return a Hash from #settings[:sort]" do
      @category.settings[:sort].class.name.should eq('Hash')
    end

    it "should return an Array from #settings[:price_filter]" do
      @category.settings[:price_filter].class.name.should eq('Array')
    end

    it "should return a Hash from #settings[:limit]" do
      @category.settings[:limit].class.name.should eq('Hash')
    end

    it "should return a Hash from #settings[:deleted]" do
      @category.settings[:deleted].class.name.should eq('Hash')
    end

    it "should return a NilClass from #settings[:dne] because the 'dne' option does not exist" do
      @category.settings[:dne].class.name.should eq('NilClass')
    end
  end

  describe "replacing settings from the #settings= method" do
    describe "replacing a non-multiple option " do
      before(:each) do
        @category.settings[:sort] = {:value => 'manual'}
        @category.save
      end

      it "should accept replacement of both the value and modifier" do
        @category.settings[:sort] = {:modifier => 'asc', :value => 'alphabetical'}
        @category.settings[:sort][:modifier].should eq('asc')
        @category.settings[:sort][:value].should    eq('alphabetical')
      end

      it "should revert to default values when replaced with nil" do
        @category.settings[:sort] = nil
        @category.settings[:sort][:modifier].should be_nil
        @category.settings[:sort][:value].should    eq('alphabetical')
      end

      it "should raise an ArgumentError when not replaced with a Hash" do
        lambda {
          @category.settings[:sort] = [{:value => 'alphabetical'}, {:value => 'manual'}]
        }.should raise_error(ArgumentError)

        lambda {
          @category.settings[:sort] = 'alphabetical'
        }.should raise_error(ArgumentError)
      end
    end

    describe "replacing a multiple option " do
      before(:each) do
        @category.settings[:price_filter] = [{:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00}]
        @category.save
      end

      it "should accept replacement for all values and modifiers" do
        @category.settings[:price_filter] = [{:modifier => 'gt', :value => 10.00}]
        @category.settings[:price_filter] =~ [{:modifier => 'gt', :value => 10.00}]
      end

      it "should revert modified values when replaced with nil" do
        @category.settings[:price_filter] = nil
        @category.settings[:price_filter] =~ []
      end

      it "should raise an ArgumentError when not replaced with a Hash or an Array" do
        lambda {
          @category.settings[:price_filter] = 'invalid'
        }.should raise_error(ArgumentError)
      end
    end
  end

  it "should accept updates to multiple settings at once on #write_settings" do
    @category.settings.write_settings({:sort => {:value => 'manual'}, :limit => {:value => 15}})
    @category.settings[:sort][:value].should  eq('manual')
    @category.settings[:limit][:value].should eq(15)
  end

  it "should generate errors for multiple invalid settings at once on #validate" do
    @category.settings.write_settings({:sort => {:value => 'dne'}, :limit => {:value => 'Ten'}})
    @category.settings.validate
    @category.errors[:settings].size.should > 0
  end

  it " should save modified settings on #save" do
    @category.settings[:sort][:value] = 'modifier'
    @category.settings.save
    @category.reload
    @category.settings[:sort][:value].should eq('modifier')
  end

  it "should save multiple setings at once on #update_settings" do
    @category.settings.update_settings({:sort => {:value => 'manual'}, :limit => {:value => 15}})
    @category.reload
    @category.settings[:sort][:value].should  eq('manual')
    @category.settings[:limit][:value].should eq(15)
  end

  it "should reset all requested setting modifications" do
    @category.settings.write_settings({:sort => {:value => 'manual'}, :limit => {:value => 15}})
    @category.settings.reload
    @category.settings[:sort][:value].should  eq('alphabetical')
    @category.settings[:limit][:value].should be_nil
  end
end