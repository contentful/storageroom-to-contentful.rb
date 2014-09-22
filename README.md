Storageroom to Contentful
=================

## Description
This tool can be used to migrate data from [StorageRoom](http://storageroomapp.com/) to the [Contentful](https://www.contentful.com) platform.

It exports the data from StorageRoom as JSON to the local hard drive, tries to convert the data to the Contentful data types and allows to recreate the data on Contentful.


## Installation

``` bash
gem install storageroom-to-contentful
```

This will install a ```storageroom-to-contentful``` executable.

## Usage

To use the tool you need to specify your StorageRoom and Contentful credentials in a YAML file.
For example in a ```credentials.yaml``` file:

``` yaml
#Contentful
ACCESS_TOKEN: access_token
ORGANIZATION_ID: organization_id

#StorageRoom
ACCOUNT_ID: account_id
APPLICATION_API_KEY: application_key_id%
```

Your Contentful access token can be easiest created using the [Contentful Management API - documentation](https://www.contentful.com/developers/documentation/content-management-api/#getting-started)

Once you installed the Gem and created the YAML file with the credentials you can invoke the tool using:

``` bash
storageroom-to-contentful credentials.yml
```



##Step 1 - Export data from StorageRoom:
Downloads all data from StorageRoom and save locally as JSON files to make proposal for Contentful content types.
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

Each file in ```data/collections``` must be changed.
Value of "input_type" attribute must belongs to list of available field types on Contentful.

#### File & Image
File and Image are equivalent to ```Asset``` in Contentful.
To create Asset type in Contentful, you must change ```input_type``` to ```Asset```.

#### Select
StorageRoom has a field type: ```select``` which is not directly referred in Contentful.
As an equivalent it can be treated as a Symbol.
To create a single ```Symbol``` you must change ```input_type``` to ```Symbol```

Example:
```
    "name": "Symbols",
    "identifier": "symbol_tag",
    "input_type": "Symbol",
```
#### Array
StorageRoom has a field type: ```Array``` which is not directly referred in Contentful.
As n equivalent it can be treated as a ```Multiple Symbols```.
To create a multiple ```Symbols``` you must change ```input_type``` to ```Array``` and add an additional parameter:
```"link": "Symbol"```


Example:
```
    "name": "Symbols",
    "identifier": "symbol_tag",
    "input_type": "Array",
    "link": "Symbol"
```

#### Locale
Entries in Contetnful can be localized.
When importing Entry from StoragRoom to Contentful, some entry may have attribute named as 'locale'.
If the value of this attribute will not be the same as the ```code``` of locale in Contentful, create entry fails.


##Association
 ```
    1. OneAssociationField (To-One)
    2. ManyAssociationField (To-Many)
 ```

#### OneAssociationField (To-One)

To create an ```Entry``` or ```Asset``` Link type, we must change ```input_type``` to ```Asset``` or ```Entry```.

#### ManyAssociationField (To-Many)

* Entries

To create multiple ```Entries``` Link type, we must change ```"link_type"``` to ```Array``` and add an additional parameter:
```"link_type": "Entry"```

Example:
```
    "name": "Entries",
    "identifier": "entries",
    "input_type": "Array",
    "required": true,
    "unique": null,
    "link_type": "Entry"
```
##Step 2 - Convert Storageroom field types to Contentful:
To convert values of ​​input_type in each collection file (``` data/collections/ ```), select action '2' from the menu.

##Step 3 - Import collections to Contentful:
After modifying files with collections, run script again and select action '3' from the menu.
Enter the name of the new space on Contentful and import collections as content types.

##Step 4 - Convert symbol values to String:
If the collection has a field of type ```Symbol```, the value of the entry must be strings.

Example:
#### Field in Collection
```
    {
      "@type": "IntegerField",
      "name": "Price Range",
      "identifier": "price_range",
      "input_type": "Symbol",
      "required": true,
      "include_blank_choice": false,
      "choices": [
        1,
        2,
        3
      ]
    },
```
#### Entry
```
    {
      "@type": "Restaurant",
      "price_range": 2,
    }
```
To convert the data as a String, select action '4' from the menu.

##Step 5 - Import entries to Contentful:
To import all entries from JSON files to Contentful platform, select action '5' from the menu.

Each entry will be created on Contentful with the same unique ID from Storageroom.

#### [Links](https://www.contentful.com/developers/documentation/content-management-api/#links)

If Entry is linked to another Entry, it will be created with related resources with specified IDs.
Until all entries will be imported, the relationship will be invalid.

##Step 6 - Publish all entries on Contentful:
To publish all entries on Contentful, select action '6' from the menu.
In the case of an unsuccessful publication,there will be displayed error message

##Script execution:

```
$ ruby ruby bin/storageroom-to-contentful settings.yml
```
