## Unit Specs

To run the unit specs:

    rspec spec

## Integration Specs

First you'll need to copy the following files:

    enom.example.yml -> enom.yml 
    opensrs.example.yml -> opensrs.yml
    test-data.example.yml -> test-data.yml

Once you've copied these files replace all of the values with ones that make sense for your environment.

To run the Enom integration specs:

    rspec -I spec-integration spec-integration/registrar/enom

Or, to run the OpenSRS integration specs:

    rspec -I spec-integration spec-integration/registrar/opensrs
