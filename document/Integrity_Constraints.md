# Integrity Constraints

## Reference Integrity Constraints

* PRODUCT.product_type_id -> PRODUCT_TYPE.product_type_id
* PRODUCT_MARKET.sku -> PRODUCT.sku
* PRODUCT_MARKET.market_id -> MARKET.market_id
* PRODUCT_MARKET.plug_type_id -> PLUG_TYPE.plug_type_id
* PRODUCT_MARKET.energy_class_id -> ENRGY_CLASS.energy_class_id
* COMPONENT.unit_id -> UNIT.unit_id
* COMPONENT.sub_category_id -> COMPONENT_SUBCATEGORY.sub_category_id
* COMPONENT_RELATION.parent_stock_number -> COMPONENT.stock_number
* COMPONENT_RELATION.child_stock_number -> COMPONENT.stock_number
* COMPONENT_RELATION.unit_id -> UNIT.unit_id
* COMPONENT_CATEGORY.group_id -> COMPONENT_GROUP.group_id
* COMPONENT_SUBCATEGORY.category_id -> COMPONENT_CATEGORY.category_id
* PRODUCT_COMPONENT.sku -> PRODUCT.sku
* PRODUCT_COMPONENT.stock_number-> COMPONENT.stock_number
* PRODUCT_COMPONENT.unit_id-> UNIT.unit_id
* PRODUCTION_LINE_PRODUCT.prod_line_id -> PRODUCTION_LINE.prod_line_id
* PRODUCTION_LINE_PRODUCT.sku -> PRODUCT.sku
* CUSTOMER.market_id -> MARKET.market_id
* ORDER.customer_id -> CUSTOMER.customer_id
* ORDER_PRODUCT.order_id -> ORDER.order_id
* ORDER_PRODUCT.sku -> PRODUCT.sku
* TRANSPORTATION.transportation_type_id -> TRANSPORTATION_TYPE.transportation_type_id
* TRANSPORTATION.destination_market_id -> MARKET.market_id
* TRANSPORTATION.order_id -> ORDER.order_id

## Domain Constraints
## Semantic Integrity Constraints

