# System Analysis & Descriptions

## Desriptions & Concepts
## Entity-Relationship (E/R) Diagram
## Relational Models
## Integrity Constraints
### Reference Integrity Constraints
### Domain Constraints
### Semantic Integrity Constraints

A home appliances company named Beko plans to migrate its product and component management data from SAP to a PostgreSQL based product management database system. The objective of this project is to design and implement a reliable, stable, and well structured relational database that will manage product definitions, component hierarchies, production planning, and logistics operations. The database is intended to replace SAP for product master data and bill of materials (BOM) tracking, while ensuring data consistency, scalability, and compliance with business rules.

This company has a wide range of diferent models varying from french door to larder refrigerators where they are differentiated by their SKU(Stock Keeping Unit). This SKU is a 10 digit number and acts as ID of the product. Even changing color of the refrigerator creates a new product and this new product must have a different SKU than the referenced one. Each refrigerator can be a different type available in the market like prviously mentioned French Door, Larder, Freezer, Double Door etc. Refrigerators are planned to be sold to different countries and regions so they must be compatible with the regulations of the company such as plug type and energy efficiency. Each product has hundreds of components and its crucial for mass production to keep track of the product trees. Product trees are consist of all the components a product has like a binary tree. Just like SKU numbers, components have their uniq identifier named stock number. This is similar to SKU and is a 10 digit number. Components are made of other smaller components so there must be a parent-child relation for components. Each component can have multiple child components varying in types, quantities and units. Their level increases as the tree goes deeper. Components can be used in different models and parent components for example both french door and larder type refrigerators can have fans but these fans can be mounted on to different parent components. From largest components like compressor to the tiniest component like a single bolt must be registered correct. Components can have Group/Category/Sub-Category hierarchy meaning a component can be assigned to a single combination of Group/Category/Sub-Category. These Group/Category/Sub-Category are used to categorize components an example to this is evaporator fans. Fans can belong to "DC FAN" Sub Category under the Category "FAN" which is under the Group "Outer Cooling".

When products and components are registered to the database system they must be registered for production as well. The company 5 production lines each having different capabilities ana capasities. Thus, some models can be manufactured in a specific production line but not others.

Eventually, these products are planned to be sold different customers from different countries. The company assures its customers in terms of logistic so transportation must be handled by the company whether its by maritime, railway or roadway transportation.

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


