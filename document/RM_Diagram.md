# Relational Models

Below are the relation models for the database system.

* PRODUCT(<u>**sku**</u>, model, <span class="double-underlined">**product_type_id**</span>, volume, color)
* PRODUCT_TYPE(<u>**product_type_id**</u>, name)
* MARKET(<u>**market_id**</u>, country, region)
* PLUG_TYPE(<u>**plug_type_id**</u>, name)
* ENERGY_CLASS(<u>**energy_class_id**</u>, name)
* PRODUCT_MARKET(<span class="double-underlined">**sku, market_id**</span>, <span class="double-underlined">**plug_type_id**</span>, <span class="double-underlined">**energy_class_id**</span>)
* COMPONENT(<u>**stock_number**</u>, description, <span class="double-underlined">**unit_id**</span>, <span class="double-underlined">**sub_category_id**</span>)
* COMPONENT_RELATION(<span class="double-underlined">**parent_stock_number, child_stock_number**</span>, quantity, <span class="double-underlined">**unit_id**</span>)
* COMPONENT_GROUP(<u>**group_id**</u>, name)
* COMPONENT_CATEGORY(<u>**category_id**</u>, name, <span class="double-underlined">**group_id**</span>)
* COMPONENT_SUBCATEGORY(<u>**sub_category_id**</u>, name, <span class="double-underlined">**category_id**</span>)
* UNIT(<u>**unit_id**</u>, name, symbol)
* PRODUCT_COMPONENT(<span class="double-underlined">**sku, stock_number**</span>, quantity, <span class="double-underlined">**unit_id**</span>)
* PRODUCTION_LINE(<u>**prod_line_id**</u>, name, capacity_per_day)
* PRODUCTION_LINE_PRODUCT(<span class="double-underlined">**prod_line_id, sku**</span>)
* CUSTOMER(<u>**customer_id**</u>, name, <span class="double-underlined">**market_id**</span>)
* ORDER(<u>**order_id**</u>, <span class="double-underlined">**customer_id**</span>, order_date, status)
* ORDER_PRODUCT(<span class="double-underlined">**order_id, sku**</span>, quantity)
* TRANSPORTATION_TYPE(<u>**transportation_type_id**</u>, name, capacity)
* TRANSPORTATION(<u>**transportation_id**</u>, <span class="double-underlined">**transportation_type_id**</span>, <span class="double-underlined">**destination_market_id**</span>, <span class="double-underlined">**order_id**</span>, planned_date, status)

<style>
    .double-underlined {
        text-decoration:underline;
        border-bottom: 1px solid #000;
    }
</style>