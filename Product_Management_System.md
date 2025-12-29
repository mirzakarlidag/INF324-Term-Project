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

Below are the relation models for the database system.

* PRODUCT(<u>**sku**</u>, model, <span class="double-underlined">**product_type_id**</span>, volume, color)
* PRODCT_TYPE(<u>**product_type_id**</u>, name)
* MARKET(<u>**market_id**</u>, country, region)
* PLUG_TYPE(<u>**plug_type_id**</u>, name)
* ENERGY_CLASS(<u>**energy_class_id**</u>, name)
* PRODUCT_MARKET(<u>**sku, market_id**</u>, <span class="double-underlined">**sku**</span>, <span class="double-underlined">**market_id**</span>, <span class="double-underlined">**plug_type_id**</span>, <span class="double-underlined">**energy_class_id**</span>)
* COMPONENT(<u>**stock_number**</u>, description, <span class="double-underlined">**unit_id**</span>, <span class="double-underlined">**sub_category_id**</span>)
* COMPONENT_RELATION(<u>**parent_stock_number, child_stock_number**</u>, <span class="double-underlined">**parent_stock_number**</span>, <span class="double-underlined">**child_stock_number**</span>, quantity, <span class="double-underlined">**unit_id**</span>)
* COMPONENT_GROUP(<u>**group_id**</u>, name)
* COMPONENT_CATEGORY(<u>**category_id**</u>, name, <span class="double-underlined">**group_id**</span>)
* COMPONENT_SUBCATEGORY(<u>**sub_category_id**</u>, name, <span class="double-underlined">**category_id**</span>)
* UNIT(<u>**unit_id**</u>, name, symbol)
* PRODUCT_COMPONENT(<u>**sku, stock_number**</u>, <span class="double-underlined">**sku**</span>, <span class="double-underlined">**stock_number**</span>, quantity, <span class="double-underlined">**unit_id**</span>)
* PRODUCTION_LINE(<u>**prod_line_id**</u>, name, capacity_per_day)
* PRODUCTION_LINE_PRODUCT(<u>**prod_line_id, sku**</u>, <span class="double-underlined">**prod_line_id**</span>, <span class="double-underlined">**sku**</span> )
* CUSTOMER(<u>**customer_id**</u>, name, <span class="double-underlined">**market_id**</span>)
* ORDER(<u>**order_id**</u>, <span class="double-underlined">**customer_id**</span>, order_date, status)
* ORDER_PRODUCT(<u>**order_id, sku**</u>, <span class="double-underlined">**order_id**</span>, <span class="double-underlined">**sku**</span>, quantity)
* TRANSPORTATION_TYPE(<u>**transportation_type_id**</u>, name, capacity)
* TRANSPORTATION(<u>**transportation_id**</u>, <span class="double-underlined">**transportation_type_id**</span>, <span class="double-underlined">**destination_market_id**</span>, <span class="double-underlined">**order_id**</span>, planned_date, status)

**Double Underlined CSS, later will be pasted to the html before pdf coversion**
.double-underlined {
    text-decoration:underline;
    border-bottom: 1px solid #000;
}**

## Integrity Constraints
### Reference Integrity Constraints
### Domain Constraints
### Semantic Integrity Constraints

