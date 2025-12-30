# Integrity Constraints

## Reference Integrity Constraints

|FOREIGN KEY|->|REFERENCE|DELETE ACTION|
|-|-|-|-|
|**PRODUCT**.product_type_id|->|**PRODUCT_TYPE**.product_type_id|ON DELETE RESTRICT|
|**PRODUCT_MARKET**.sku|->|**PRODUCT**.sku|ON DELETE CASCADE|
|**PRODUCT_MARKET**.market_id|->|**MARKET**.market_id|ON DELETE RESTRICT|
|**PRODUCT_MARKET**.plug_type_id|->|**PLUG_TYPE**.plug_type_id|ON DELETE RESTRICT|
|**PRODUCT_MARKET**.energy_class_id|->|**ENRGY_CLASS**.energy_class_id|ON DELETE RESTRICT|
|**COMPONENT**.unit_id|->|**UNIT**.unit_id|ON DELETE RESTRICT|
|**COMPONENT**.sub_category_id|->|**COMPONENT_SUBCATEGORY**.sub_category_id|ON DELETE RESTRICT|
|**COMPONENT_RELATION**.parent_stock_number|->|**COMPONENT**.stock_number|ON DELETE RESTRICT|
|**COMPONENT_RELATION**.child_stock_number|->|**COMPONENT**.stock_number|ON DELETE RESTRICT|
|**COMPONENT_RELATION**.unit_id|->|**UNIT**.unit_id|ON DELETE RESTRICT|
|**COMPONENT_CATEGORY**.group_id|->|**COMPONENT_GROUP**.group_id|ON DELETE RESTRICT|
|**COMPONENT_SUBCATEGORY**.category_id|->|**COMPONENT_CATEGORY**.category_id|ON DELETE RESTRICT|
|**PRODUCT_COMPONENT**.sku|->|**PRODUCT**.sku|ON DELETE CASCADE|
|**PRODUCT_COMPONENT**.stock_number|->|**COMPONENT**.stock_number|ON DELETE RESTRICT|
|**PRODUCT_COMPONENT**.unit_id|->|**UNIT**.unit_id|ON DELETE RESTRICT|
|**PRODUCTION_LINE_PRODUCT**.prod_line_id|->|**PRODUCTION_LINE**.prod_line_id|ON DELETE CASCADE|
|**PRODUCTION_LINE_PRODUCT**.sku|->|**PRODUCT**.sku|ON DELETE CASCADE|
|**CUSTOMER**.market_id|->|**MARKET**.market_id|ON DELETE RESTRICT|
|**ORDER**.customer_id|->|**CUSTOMER**.customer_id|ON DELETE RESTRICT|
|**ORDER_PRODUCT**.order_id|->|**ORDER**.order_id|ON DELETE CASCADE|
|**ORDER_PRODUCT**.sku|->|**PRODUCT**.sku|ON DELETE RESTRICT|
|**TRANSPORTATION**.transportation_type_id|->|**TRANSPORTATION_TYPE**.transportation_type_id|ON DELETE RESTRICT|
|**TRANSPORTATION**.destination_market_id|->|**MARKET**.market_id|ON DELETE RESTRICT|
|**TRANSPORTATION**.order_id|->|**ORDER**.order_id|ON DELETE CASCADE|


## Domain Constraints

### PRODUCT
* PRODUCT.sku -> CHAR(10) NOT NULL, only digits
* PRODUCT.volume > 0
### COMPONENT
* COMPONENT.stock_number -> CHAR(10) NOT NULL, only digits
### COMPONENT_RELATION
* COMPONENT_RELATION.quantity > 0
### PRODUCT_COMPONENT
* PRODUCT_COMPONENT.quantity > 0
### PRODUCTION_LINE
* PRODUCTION_LINE.capacity_par_day > 0
### ORDER
* ORDER.status -> ('NEW', 'APPROVED', 'SHIPPED', 'CANCELLED')
* ORDER.order_date <= CURRENT DATE
### ORDER_PRODUCT
* ORDER_PRODUCT.quantity > 0
### TRANSPORTATION_TYPE
* TRANSPORTATION_TYPE.capacity > 0
### TRANSPORTATION
* TRANSPORTATION.status -> ('NEW', 'APPROVED', 'SHIPPED', 'CANCELLED')
* ORDER.planned_date >= CURRENT DATE


## Semantic Integrity Constraints
* Each component belongs to exactly one Group/Category/Subcategory  combination
* No infinite loops in component hierarchy, no component can be parent or child component of itself.
* A product can be assigned only to compatible production lines
* An order must contain at least one order item
