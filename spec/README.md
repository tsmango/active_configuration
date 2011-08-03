# Testing Environment

This bundled rails application is required for testing the various aspects of 
ActiveConfiguration and how it works with ActiveRecord models.

To run these specs, move to the root directory of active_configuration 
which is located at ../ and do the following:

> bundle install --path=vendor/bundles --binstubs
> bin/rspec spec

This will run all specs within this directory, which are only in ../spec/spec.