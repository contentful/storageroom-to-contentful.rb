Storageroom to Contentful
=================

## Description
This script helps user to dump all data from StorageRoom application (one per time) to JSON files and load data to the Contentful platform.

## Installation
```
$ bundle install
```

## Usage
Note that you need to specify your account id, application API key, access token and organization id in the script.rb file (```ACCOUNT_ID```,```APPLICATION_API_KEY```,```CONTENTFUL_ACCESS_TOKEN```, ```CONTENTFUL_ORGANIZATION_ID```).
Your access token can be found at [CMA - documentation](https://www.contentful.com/developers/documentation/content-management-api/#getting-started)

Step 1:

Dump all the data from Storageroom to JSON file and make a proposal for Contentful content types.
You have to manually modify the structure of collection.

Available types of field on Contentful:
```
1. 'Symbol'
2. 'Text'
3. 'Integer'
4. 'Number'
5. 'Date'
6. 'Boolean'
7. 'Link'
8. 'Array'
9. 'Object'
10. 'Location'
```

Each file in ```'lib/data/collections'``` must be changed.
Value of "input_type" attribute must belongs to list of available field types.

To create a single field of Entry/Asset type, we must change ```input_type``` to ```Asset``` or ```Entry```
To create a multiple field of Entries/Assets type, we must change ```"link_type"``` to ```Array``` and add an additional parameter:
```"link_type": "Entry"```  or  ```"link_type": "Asset"```

Example:
```
    "name": "Entries",
    "identifier": "entries",
    "input_type": "Array",
    "required": true,
    "unique": null,
    "link_type": "Entry"
```
Script execution:

```
$ ruby 'lib/script.rb'
```