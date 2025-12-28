# System Analysis & Descriptions

## Desriptions & Concepts

A home appliances company named Beko plans to migrate its product and component management data from SAP to a PostgreSQL based product management database system. The objective of this project is to design and implement a reliable, stable, and well structured relational database that will manage product definitions, component hierarchies, production planning, and logistics operations. The database is intended to replace SAP for product master data and bill of materials (BOM) tracking, while ensuring data consistency, scalability, and compliance with business rules.

This company has a wide range of diferent models varying from French Door to Larder refrigerators where they are differentiated by their SKU(Stock Keeping Unit). This SKU is a 10 digit number and acts as ID of the product. A product is defined by its physical and technical characteristics such as model name, volume, color, and refrigerator type. Each refrigerator can be a different type available in the market like prviously mentioned French Door, Larder, Freezer, Double Door etc. Products are planned to be sold in multiple countries and regions, and therefore must comply with regional regulations, including plug type and energy efficiency class. These regulatory attributes may vary depending on the target market.

Each product has hundreds of components and its crucial for mass production to keep track of the product trees. Product trees are consist of all the components a product has like a binary tree. Just like SKU numbers, components have their uniqe identifier named stock number. This is similar to SKU and is a 10 digit number. Components may be composed of other smaller components so a parent-child relationship for components must be kept. Each component can have multiple child components varying in types, quantities and units, and the hierarchy depth increases as the tree grows. The same component can be reused across different products and different parent components. Components can be used in different models and parent components for example both french door and larder type refrigerators can have fans but these fans can be mounted on to different parent components. From largest components like compressor to the tiniest component like a single bolt must be registered correct.

Components can have Group/Category/Sub-Category hierarchy meaning a component can be assigned to a single combination of Group/Category/Sub-Category. These Group/Category/Sub-Category are used to categorize components an example to this is evaporator fans. Fans can belong to "DC FAN" Sub Category under the Category "FAN" which is under the Group "Outer Cooling". Each Group can have multiple Category and each Category can have multiple Sub-Category assigned to them. This categorization is used in the production lines for efficient and fast filtering.

Once products and components are registered to the database system they must be registered for production as well. The company operates on 5 production lines each having different capabilities and capasities. As a result, not every product can be manufactured on every production line.
The database must include of which products are compatible with which production lines. This is used to sustain a safe and stable production planning and capacity management.

Eventually, these products are planned to be sold different customers from different countries. The company assures its customers in terms of logistic so transportation must be handled by the company whether its by maritime, railway or roadway transportation.

### Main Database Tasks

The database system must support the following tasks:

    * Registration and management of products and their technical attributes
    * Management of component hierarchies and product trees (BOM)
    * Classification of components using Group, Category, and Sub-Category
    * Assignment of products to compatible production lines
    * Management of customers and their orders
    * Planning and tracking of product transportation


## Entity-Relationship (E/R) Diagram


## Relational Models

    * PRODUCT()
    * COMPONENT()
    * COMPONENT_RELATION()
    * COMPONENT_GROUP()
    * COMPONENT_CATEGORY()
    * COMPONENT_SUBCATEGORY()
    * PRODUCTION_LINE()
    * CUSTOMER()
    * ORDER()
    * TRANSPORTATION()
    * TRANSPORTATION_TYPE()




## Integrity Constraints
### Reference Integrity Constraints
### Domain Constraints
### Semantic Integrity Constraints

ENTITIES
PRODUCT:
    - model
    - sku
    - country
    - plug type
    - energy_class
    - volume
    - color
    - type

COMPONENT:
    - stock_number
    - description
    - parent_component
    - unit
    - group
    - category
    - sub_category

COMPONENT GROUP:
    - name

COMPONENT CATEGORY:
    - name
    - group

COMPONENT SUB CATEGORY:
    - name
    - category

COMPONENT RELATION:
    - component
    - parent_component
    - quantity
    - level

PRODUCTION LINE:
    - capacity
    - available_models

CUSTOMER:
    - name
    - quantity
    - country
    - available_transportation_methods

TRANSPORTATION:
    - num_of_units
    - destination
    - type

TRANSPORTATION TYPE:
    - name
    - capacity


