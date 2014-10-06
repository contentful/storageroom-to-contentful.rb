StorageRoom to Contentful
=================

## Description

[StorageRoom](http://storageroomapp.com/) will be shut down on 1/1/2015. This tool can be used to:

1. migrate content from StorageRoom to the [Contentful](https://www.contentful.com) platform, which provides a similar feature set
2. export your StorageRoom content without importing it into Contentful

This tool exports the content from StorageRoom as JSON to your local hard drive. It will suggest the field types to use on Contentful and will allow you to recreate all the content on Contentful.


## Installation

``` bash
gem install storageroom-to-contentful
```

This will install a ```storageroom-to-contentful``` executable.

## Usage

To use the tool you need to specify your StorageRoom and Contentful credentials in a YAML file.
For example in a ```credentials.yml``` file:

``` yaml
#Contentful
ACCESS_TOKEN: access_token
ORGANIZATION_ID: organization_id

#StorageRoom
ACCOUNT_ID: account_id
APPLICATION_API_KEY: application_key_id
```

**Your Contentful access token can be easiest created using the [Contentful Management API - documentation](https://www.contentful.com/developers/documentation/content-management-api/#getting-started)**
The Contentful organization id can be found in your account settings.

Once you installed the Gem and created the YAML file with the credentials you can invoke the tool using:

``` bash
storageroom-to-contentful credentials.yml
```

You will be presented with a bunch of options:

```
Actions:
  1. Export data from StorageRoom to JSON files.
  2. Convert Storageroom field types to Contentful.
  3. Import collections to Contentful.
  4. Import entries to Contentful.
  5. Publish all entries on Contentful.
```



##Step 1 - Export data from StorageRoom to JSON files:

Downloads all data from StorageRoom and saves it locally as JSON files.
The data will be copied to the current working directory in a sub folder called `data`.

You either manually adjust the data types or try an automatic translation.
In either case we suggest to put the `data` directory under version control like git and commit after each change.


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

All files in ```data/collections``` must be inspected and changed.
Any occurrence of the *input_type* attribute must changed to a type that is available on Contentful.

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
StorageRoom has a field type: ```Array``` that can not directly be mapped to Contentful.
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
Entries in Contentful can be localized.
When importing Entries from StorageRoom to Contentful, some may have attributes that are named as 'locale'.
Is the value of this attribute not the same as locale ```code``` on Contentful creating the entries will fail.
You always need to create the locales on Contentful before you start the import.


##Association
 ```
    1. OneAssociationField (To-One)
    2. ManyAssociationField (To-Many)
 ```

#### OneAssociationField (To-One)

To create an ```Entry``` or ```Asset``` Link type, you must change the ```input_type``` to ```Asset``` or ```Entry```.

#### ManyAssociationField (To-Many)

* Entries

To create multiple ```Entries``` Link type, you must change the ```link_type``` to ```Array``` and add an additional parameter:
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
Once the exported StorageRoom data is transformed to be compatible with Contentful you can start the import.

Run script again and select action '3' from the menu.
Enter the name of the new space on Contentful and import the collections as content types.

## Convert symbol values to String:
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

##Step 4 - Import entries to Contentful:
To import all the entries from the exported data to the Contentful platform, select action '4' from the menu.

Each entry will be created with the same StorageRoom id.

#### [Links](https://www.contentful.com/developers/documentation/content-management-api/#links)

If two or more entries are linked the import tool will recreate those relationships.

The entries will be valid once all the required relations are created on Contentful.

##Step 5 - Publish all entries on Contentful:
To publish all entries, select action '5' from the menu.

If an entry can not be published the tool will print an error message containing the reason(eg. Invalid, ...)

##Script execution:

```
$ storageroom-to-contentful credentials.yml
```
