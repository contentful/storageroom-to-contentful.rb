Storageroom to Contentful
=================

## Description
This script helps user to download all data from StorageRoom application (one per time) to save as JSON files and import collections and entries to the Contentful platform.

## Installation
```
$ bundle install
```

## Usage
Note that you need to specify your ```ACCOUNT_ID```, ```APPLICATION_API_KEY```, ```ACCESS_TOKEN```, ```ORGANIZATION_ID``` in ```credentials.yaml``` file.
Your access token can be found at [CMA - documentation](https://www.contentful.com/developers/documentation/content-management-api/#getting-started)

##Step 1:

Download all data from Storageroom and save locally as JSON file to make proposal for Contentful content types.
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
Value of "input_type" attribute must belongs to list of available field types on Contentful.

#### Select
Storageroom has a field type which is not directly referred to Contentful as the ```select``` type.
As a equivalent can be treated as a Symbol.
To create a single ```Symbol``` you must change ```input_type``` to ```Symbol```

Example:
```
                "name": "Symbols",
                "identifier": "symbol_tag",
                "input_type": "Symbol",
```
#### Array
Storageroom has a field type which is not directly referred to Contentful as the ```Array``` type.
As a equivalent can be treated as a Symbols.
To create a multiple ```Symbols``` you must change ```input_type``` to ```Array``` and add an additional parameter:
```"link": "Symbol"```

#### Locale
* Entry in Contetnful can be localized.
When importing Entry of Storagroom to Contentful, some entry may have attribute named as 'locale'.
If the value of this attribute will not be the same as the ```code``` of locale in Contentful, create entry fails.

Example:
```
                "name": "Symbols",
                "identifier": "symbol_tag",
                "input_type": "Array",
                "link": "Symbol"
```

##Association

 ```
    1. OneAssociationField (To-One)
    2. ManyAssociationField (To-Many)
 ```
#### OneAssociationField (To-One)

To create an ```Entry``` or ```Asset``` Link type, we must change ```input_type``` to ```Asset``` or ```Entry```.

#### ManyAssociationField (To-Many)

* Entries

To create an multiple ```Entries``` Link type, we must change ```"link_type"``` to ```Array``` and add an additional parameter:
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

##Step 2:

After modify files with collections, select action '2' from the menu.
Enter the name of the new space on Contentful and import collections as content types.

##Step 3:

If the collection has a field of type 'Symbol', the value of the entry must be strings.

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
To convert the data as a String, select action 3 from the menu.

##Step 4:
To import all entries from JSON files to Contentful platform,  select action 4 from the menu.

##Script execution:

```
$ ruby 'lib/script.rb'
```