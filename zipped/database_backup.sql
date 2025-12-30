--
-- PostgreSQL database dump
--

\restrict Js38W0wQoOyiZMd1lJy19SF5J3yTTt46r0dJNQ71dNkW1UuhII0Wbm8zQ1whLRr

-- Dumped from database version 15.15
-- Dumped by pg_dump version 15.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_check_component_cycle(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_check_component_cycle() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_has_cycle BOOLEAN;
BEGIN
    -- Check if adding this relation would create a cycle
    -- A cycle exists if the child is already an ancestor of the parent
    WITH RECURSIVE component_ancestors AS (
        -- Base case: direct parents of the NEW parent
        SELECT parent_stock_number, child_stock_number, 1 AS depth
        FROM COMPONENT_RELATION
        WHERE child_stock_number = NEW.parent_stock_number

        UNION ALL

        -- Recursive case: ancestors of ancestors
        SELECT cr.parent_stock_number, cr.child_stock_number, ca.depth + 1
        FROM COMPONENT_RELATION cr
        JOIN component_ancestors ca ON cr.child_stock_number = ca.parent_stock_number
        WHERE ca.depth < 100  -- Prevent infinite recursion
    )
    SELECT EXISTS(
        SELECT 1 FROM component_ancestors
        WHERE parent_stock_number = NEW.child_stock_number
    ) INTO v_has_cycle;

    IF v_has_cycle THEN
        RAISE EXCEPTION 'Cannot create component relation: This would create a circular reference. Component % cannot be both ancestor and descendant of component %.',
            NEW.child_stock_number, NEW.parent_stock_number;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_check_component_cycle() OWNER TO postgres;

--
-- Name: sp_delete_component(character); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_delete_component(IN p_stock_number character)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_parent_count INTEGER;
    v_child_count INTEGER;
    v_product_count INTEGER;
    v_component_exists BOOLEAN;
BEGIN
    -- Check if component exists
    SELECT EXISTS(SELECT 1 FROM COMPONENT WHERE stock_number = p_stock_number) INTO v_component_exists;

    IF NOT v_component_exists THEN
        RAISE EXCEPTION 'Component % does not exist.', p_stock_number;
    END IF;

    -- Check if component is used as a parent in any relation
    SELECT COUNT(*) INTO v_parent_count
    FROM COMPONENT_RELATION
    WHERE parent_stock_number = p_stock_number;

    -- Check if component is used as a child in any relation
    SELECT COUNT(*) INTO v_child_count
    FROM COMPONENT_RELATION
    WHERE child_stock_number = p_stock_number;

    -- Check if component is assigned to any product
    SELECT COUNT(*) INTO v_product_count
    FROM PRODUCT_COMPONENT
    WHERE stock_number = p_stock_number;

    -- Prevent deletion if dependencies exist
    IF v_parent_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete component %. It has % child components.', p_stock_number, v_parent_count;
    END IF;

    IF v_child_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete component %. It is used as a child in % relations.', p_stock_number, v_child_count;
    END IF;

    IF v_product_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete component %. It is assigned to % products.', p_stock_number, v_product_count;
    END IF;

    -- Safe to delete
    DELETE FROM COMPONENT WHERE stock_number = p_stock_number;

    RAISE NOTICE 'Component % successfully deleted.', p_stock_number;
END;
$$;


ALTER PROCEDURE public.sp_delete_component(IN p_stock_number character) OWNER TO postgres;

--
-- Name: sp_insert_product(character, character varying, integer, numeric, character varying, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_insert_product(IN p_sku character, IN p_model character varying, IN p_product_type_id integer, IN p_volume numeric, IN p_color character varying, IN p_market_id integer, IN p_plug_type_id integer, IN p_energy_class_id integer)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    -- Validate SKU format (10 digits)
    IF p_sku !~ '^[0-9]{10}$' THEN
        RAISE EXCEPTION 'Invalid SKU format. Must be exactly 10 digits.';
    END IF;

    -- Insert the product
    INSERT INTO PRODUCT (sku, model, product_type_id, volume, color)
    VALUES (p_sku, p_model, p_product_type_id, p_volume, p_color);

    -- Assign product to market
    INSERT INTO PRODUCT_MARKET (sku, market_id, plug_type_id, energy_class_id)
    VALUES (p_sku, p_market_id, p_plug_type_id, p_energy_class_id);

    RAISE NOTICE 'Product % successfully created and assigned to market %', p_sku, p_market_id;
END;
$_$;


ALTER PROCEDURE public.sp_insert_product(IN p_sku character, IN p_model character varying, IN p_product_type_id integer, IN p_volume numeric, IN p_color character varying, IN p_market_id integer, IN p_plug_type_id integer, IN p_energy_class_id integer) OWNER TO postgres;

--
-- Name: sp_update_order_status(integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_update_order_status(IN p_order_id integer, IN p_new_status character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_status VARCHAR(50);
    v_order_exists BOOLEAN;
BEGIN
    -- Check if order exists
    SELECT EXISTS(SELECT 1 FROM "ORDER" WHERE order_id = p_order_id) INTO v_order_exists;

    IF NOT v_order_exists THEN
        RAISE EXCEPTION 'Order % does not exist.', p_order_id;
    END IF;

    -- Get current status
    SELECT status INTO v_current_status FROM "ORDER" WHERE order_id = p_order_id;

    -- Validate status transition
    IF v_current_status = 'CANCELLED' THEN
        RAISE EXCEPTION 'Cannot update status of a cancelled order.';
    END IF;

    IF v_current_status = 'SHIPPED' AND p_new_status != 'CANCELLED' THEN
        RAISE EXCEPTION 'Shipped orders can only be cancelled.';
    END IF;

    -- Update the status
    UPDATE "ORDER"
    SET status = p_new_status
    WHERE order_id = p_order_id;

    RAISE NOTICE 'Order % status updated from % to %', p_order_id, v_current_status, p_new_status;
END;
$$;


ALTER PROCEDURE public.sp_update_order_status(IN p_order_id integer, IN p_new_status character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ORDER; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ORDER" (
    order_id integer NOT NULL,
    customer_id integer NOT NULL,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(50) NOT NULL,
    CONSTRAINT order_date_not_future CHECK ((order_date <= CURRENT_DATE)),
    CONSTRAINT order_status_valid CHECK (((status)::text = ANY ((ARRAY['NEW'::character varying, 'APPROVED'::character varying, 'SHIPPED'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public."ORDER" OWNER TO postgres;

--
-- Name: ORDER_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ORDER_order_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."ORDER_order_id_seq" OWNER TO postgres;

--
-- Name: ORDER_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ORDER_order_id_seq" OWNED BY public."ORDER".order_id;


--
-- Name: component; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component (
    stock_number character(10) NOT NULL,
    description text NOT NULL,
    unit_id integer NOT NULL,
    sub_category_id integer NOT NULL,
    CONSTRAINT stock_number_format CHECK ((stock_number ~ '^[0-9]{10}$'::text))
);


ALTER TABLE public.component OWNER TO postgres;

--
-- Name: component_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component_category (
    category_id integer NOT NULL,
    name character varying(100) NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.component_category OWNER TO postgres;

--
-- Name: component_category_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.component_category_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.component_category_category_id_seq OWNER TO postgres;

--
-- Name: component_category_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.component_category_category_id_seq OWNED BY public.component_category.category_id;


--
-- Name: component_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component_group (
    group_id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.component_group OWNER TO postgres;

--
-- Name: component_group_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.component_group_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.component_group_group_id_seq OWNER TO postgres;

--
-- Name: component_group_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.component_group_group_id_seq OWNED BY public.component_group.group_id;


--
-- Name: component_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component_relation (
    parent_stock_number character(10) NOT NULL,
    child_stock_number character(10) NOT NULL,
    quantity numeric(10,3) NOT NULL,
    unit_id integer NOT NULL,
    CONSTRAINT no_self_reference CHECK ((parent_stock_number <> child_stock_number)),
    CONSTRAINT quantity_positive CHECK ((quantity > (0)::numeric))
);


ALTER TABLE public.component_relation OWNER TO postgres;

--
-- Name: component_subcategory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component_subcategory (
    sub_category_id integer NOT NULL,
    name character varying(100) NOT NULL,
    category_id integer NOT NULL
);


ALTER TABLE public.component_subcategory OWNER TO postgres;

--
-- Name: component_subcategory_sub_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.component_subcategory_sub_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.component_subcategory_sub_category_id_seq OWNER TO postgres;

--
-- Name: component_subcategory_sub_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.component_subcategory_sub_category_id_seq OWNED BY public.component_subcategory.sub_category_id;


--
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer (
    customer_id integer NOT NULL,
    name character varying(200) NOT NULL,
    market_id integer NOT NULL
);


ALTER TABLE public.customer OWNER TO postgres;

--
-- Name: customer_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_customer_id_seq OWNER TO postgres;

--
-- Name: customer_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_customer_id_seq OWNED BY public.customer.customer_id;


--
-- Name: energy_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.energy_class (
    energy_class_id integer NOT NULL,
    name character varying(10) NOT NULL
);


ALTER TABLE public.energy_class OWNER TO postgres;

--
-- Name: energy_class_energy_class_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.energy_class_energy_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.energy_class_energy_class_id_seq OWNER TO postgres;

--
-- Name: energy_class_energy_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.energy_class_energy_class_id_seq OWNED BY public.energy_class.energy_class_id;


--
-- Name: market; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.market (
    market_id integer NOT NULL,
    country character varying(100) NOT NULL,
    region character varying(100) NOT NULL
);


ALTER TABLE public.market OWNER TO postgres;

--
-- Name: market_market_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.market_market_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.market_market_id_seq OWNER TO postgres;

--
-- Name: market_market_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.market_market_id_seq OWNED BY public.market.market_id;


--
-- Name: order_product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_product (
    order_id integer NOT NULL,
    sku character(10) NOT NULL,
    quantity integer NOT NULL,
    CONSTRAINT op_quantity_positive CHECK ((quantity > 0))
);


ALTER TABLE public.order_product OWNER TO postgres;

--
-- Name: plug_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plug_type (
    plug_type_id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.plug_type OWNER TO postgres;

--
-- Name: plug_type_plug_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.plug_type_plug_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.plug_type_plug_type_id_seq OWNER TO postgres;

--
-- Name: plug_type_plug_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.plug_type_plug_type_id_seq OWNED BY public.plug_type.plug_type_id;


--
-- Name: product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product (
    sku character(10) NOT NULL,
    model character varying(100) NOT NULL,
    product_type_id integer NOT NULL,
    volume numeric(10,2),
    color character varying(50),
    CONSTRAINT product_volume_positive CHECK ((volume > (0)::numeric)),
    CONSTRAINT sku_format CHECK ((sku ~ '^[0-9]{10}$'::text))
);


ALTER TABLE public.product OWNER TO postgres;

--
-- Name: product_component; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_component (
    sku character(10) NOT NULL,
    stock_number character(10) NOT NULL,
    quantity numeric(10,3) NOT NULL,
    unit_id integer NOT NULL,
    CONSTRAINT pc_quantity_positive CHECK ((quantity > (0)::numeric))
);


ALTER TABLE public.product_component OWNER TO postgres;

--
-- Name: product_market; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_market (
    sku character(10) NOT NULL,
    market_id integer NOT NULL,
    plug_type_id integer NOT NULL,
    energy_class_id integer NOT NULL
);


ALTER TABLE public.product_market OWNER TO postgres;

--
-- Name: product_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_type (
    product_type_id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.product_type OWNER TO postgres;

--
-- Name: product_type_product_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_type_product_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_type_product_type_id_seq OWNER TO postgres;

--
-- Name: product_type_product_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_type_product_type_id_seq OWNED BY public.product_type.product_type_id;


--
-- Name: production_line; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.production_line (
    prod_line_id integer NOT NULL,
    name character varying(100) NOT NULL,
    capacity_per_day integer NOT NULL,
    CONSTRAINT capacity_positive CHECK ((capacity_per_day > 0))
);


ALTER TABLE public.production_line OWNER TO postgres;

--
-- Name: production_line_prod_line_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.production_line_prod_line_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.production_line_prod_line_id_seq OWNER TO postgres;

--
-- Name: production_line_prod_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.production_line_prod_line_id_seq OWNED BY public.production_line.prod_line_id;


--
-- Name: production_line_product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.production_line_product (
    prod_line_id integer NOT NULL,
    sku character(10) NOT NULL
);


ALTER TABLE public.production_line_product OWNER TO postgres;

--
-- Name: transportation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transportation (
    transportation_id integer NOT NULL,
    transportation_type_id integer NOT NULL,
    destination_market_id integer NOT NULL,
    order_id integer NOT NULL,
    planned_date date NOT NULL,
    status character varying(50) NOT NULL,
    CONSTRAINT planned_date_not_past CHECK ((planned_date >= CURRENT_DATE)),
    CONSTRAINT transportation_status_valid CHECK (((status)::text = ANY ((ARRAY['NEW'::character varying, 'APPROVED'::character varying, 'SHIPPED'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public.transportation OWNER TO postgres;

--
-- Name: transportation_transportation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transportation_transportation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transportation_transportation_id_seq OWNER TO postgres;

--
-- Name: transportation_transportation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transportation_transportation_id_seq OWNED BY public.transportation.transportation_id;


--
-- Name: transportation_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transportation_type (
    transportation_type_id integer NOT NULL,
    name character varying(50) NOT NULL,
    capacity integer NOT NULL,
    CONSTRAINT transportation_capacity_positive CHECK ((capacity > 0))
);


ALTER TABLE public.transportation_type OWNER TO postgres;

--
-- Name: transportation_type_transportation_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transportation_type_transportation_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transportation_type_transportation_type_id_seq OWNER TO postgres;

--
-- Name: transportation_type_transportation_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transportation_type_transportation_type_id_seq OWNED BY public.transportation_type.transportation_type_id;


--
-- Name: unit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unit (
    unit_id integer NOT NULL,
    name character varying(50) NOT NULL,
    symbol character varying(10) NOT NULL
);


ALTER TABLE public.unit OWNER TO postgres;

--
-- Name: unit_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.unit_unit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.unit_unit_id_seq OWNER TO postgres;

--
-- Name: unit_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.unit_unit_id_seq OWNED BY public.unit.unit_id;


--
-- Name: vw_complete_order_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_complete_order_details AS
 SELECT o.order_id,
    o.order_date,
    o.status AS order_status,
    c.customer_id,
    c.name AS customer_name,
    m.market_id,
    m.country AS customer_country,
    m.region AS customer_region,
    op.sku,
    p.model AS product_model,
    pt.name AS product_type,
    p.volume AS product_volume,
    p.color AS product_color,
    op.quantity AS ordered_quantity
   FROM (((((public."ORDER" o
     JOIN public.customer c ON ((o.customer_id = c.customer_id)))
     JOIN public.market m ON ((c.market_id = m.market_id)))
     JOIN public.order_product op ON ((o.order_id = op.order_id)))
     JOIN public.product p ON ((op.sku = p.sku)))
     JOIN public.product_type pt ON ((p.product_type_id = pt.product_type_id)));


ALTER TABLE public.vw_complete_order_details OWNER TO postgres;

--
-- Name: ORDER order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ORDER" ALTER COLUMN order_id SET DEFAULT nextval('public."ORDER_order_id_seq"'::regclass);


--
-- Name: component_category category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_category ALTER COLUMN category_id SET DEFAULT nextval('public.component_category_category_id_seq'::regclass);


--
-- Name: component_group group_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_group ALTER COLUMN group_id SET DEFAULT nextval('public.component_group_group_id_seq'::regclass);


--
-- Name: component_subcategory sub_category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_subcategory ALTER COLUMN sub_category_id SET DEFAULT nextval('public.component_subcategory_sub_category_id_seq'::regclass);


--
-- Name: customer customer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer ALTER COLUMN customer_id SET DEFAULT nextval('public.customer_customer_id_seq'::regclass);


--
-- Name: energy_class energy_class_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.energy_class ALTER COLUMN energy_class_id SET DEFAULT nextval('public.energy_class_energy_class_id_seq'::regclass);


--
-- Name: market market_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.market ALTER COLUMN market_id SET DEFAULT nextval('public.market_market_id_seq'::regclass);


--
-- Name: plug_type plug_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plug_type ALTER COLUMN plug_type_id SET DEFAULT nextval('public.plug_type_plug_type_id_seq'::regclass);


--
-- Name: product_type product_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_type ALTER COLUMN product_type_id SET DEFAULT nextval('public.product_type_product_type_id_seq'::regclass);


--
-- Name: production_line prod_line_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_line ALTER COLUMN prod_line_id SET DEFAULT nextval('public.production_line_prod_line_id_seq'::regclass);


--
-- Name: transportation transportation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation ALTER COLUMN transportation_id SET DEFAULT nextval('public.transportation_transportation_id_seq'::regclass);


--
-- Name: transportation_type transportation_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation_type ALTER COLUMN transportation_type_id SET DEFAULT nextval('public.transportation_type_transportation_type_id_seq'::regclass);


--
-- Name: unit unit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit ALTER COLUMN unit_id SET DEFAULT nextval('public.unit_unit_id_seq'::regclass);


--
-- Data for Name: ORDER; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ORDER" (order_id, customer_id, order_date, status) FROM stdin;
1	1	2025-12-30	APPROVED
\.


--
-- Data for Name: component; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component (stock_number, description, unit_id, sub_category_id) FROM stdin;
\.


--
-- Data for Name: component_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component_category (category_id, name, group_id) FROM stdin;
1	Compressor	1
2	Fan	1
3	Motor	2
\.


--
-- Data for Name: component_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component_group (group_id, name) FROM stdin;
1	Cooling System
2	Electrical
3	Structural
4	Insulation
\.


--
-- Data for Name: component_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component_relation (parent_stock_number, child_stock_number, quantity, unit_id) FROM stdin;
\.


--
-- Data for Name: component_subcategory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component_subcategory (sub_category_id, name, category_id) FROM stdin;
1	DC Fan	2
2	AC Fan	2
3	Inverter Compressor	1
\.


--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer (customer_id, name, market_id) FROM stdin;
1	Test Customer	1
\.


--
-- Data for Name: energy_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.energy_class (energy_class_id, name) FROM stdin;
1	A+++
2	A++
3	A+
4	A
5	B
6	C
\.


--
-- Data for Name: market; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.market (market_id, country, region) FROM stdin;
1	Turkey	Europe
2	Germany	Europe
3	France	Europe
4	USA	North America
5	UK	Europe
\.


--
-- Data for Name: order_product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_product (order_id, sku, quantity) FROM stdin;
1	1234567890	5
\.


--
-- Data for Name: plug_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.plug_type (plug_type_id, name) FROM stdin;
1	Type C (EU)
2	Type G (UK)
3	Type A (US)
4	Type F (Schuko)
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product (sku, model, product_type_id, volume, color) FROM stdin;
1234567890	Test French Door 500L	1	500.00	Silver
\.


--
-- Data for Name: product_component; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_component (sku, stock_number, quantity, unit_id) FROM stdin;
\.


--
-- Data for Name: product_market; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_market (sku, market_id, plug_type_id, energy_class_id) FROM stdin;
1234567890	1	1	1
\.


--
-- Data for Name: product_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_type (product_type_id, name) FROM stdin;
1	French Door
2	Larder
3	Double Door
4	Freezer
5	Side by Side
\.


--
-- Data for Name: production_line; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.production_line (prod_line_id, name, capacity_per_day) FROM stdin;
1	Line A - French Door	100
2	Line B - Standard	150
3	Line C - Freezer	120
4	Line D - Premium	80
5	Line E - Compact	200
\.


--
-- Data for Name: production_line_product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.production_line_product (prod_line_id, sku) FROM stdin;
\.


--
-- Data for Name: transportation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transportation (transportation_id, transportation_type_id, destination_market_id, order_id, planned_date, status) FROM stdin;
\.


--
-- Data for Name: transportation_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transportation_type (transportation_type_id, name, capacity) FROM stdin;
1	Maritime	1000
2	Railway	500
3	Roadway	100
4	Airway	50
\.


--
-- Data for Name: unit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.unit (unit_id, name, symbol) FROM stdin;
1	Piece	pcs
2	Kilogram	kg
3	Meter	m
4	Liter	L
\.


--
-- Name: ORDER_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ORDER_order_id_seq"', 1, true);


--
-- Name: component_category_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.component_category_category_id_seq', 3, true);


--
-- Name: component_group_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.component_group_group_id_seq', 4, true);


--
-- Name: component_subcategory_sub_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.component_subcategory_sub_category_id_seq', 3, true);


--
-- Name: customer_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_customer_id_seq', 1, true);


--
-- Name: energy_class_energy_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.energy_class_energy_class_id_seq', 6, true);


--
-- Name: market_market_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.market_market_id_seq', 5, true);


--
-- Name: plug_type_plug_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.plug_type_plug_type_id_seq', 4, true);


--
-- Name: product_type_product_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_type_product_type_id_seq', 5, true);


--
-- Name: production_line_prod_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.production_line_prod_line_id_seq', 5, true);


--
-- Name: transportation_transportation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transportation_transportation_id_seq', 1, false);


--
-- Name: transportation_type_transportation_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transportation_type_transportation_type_id_seq', 4, true);


--
-- Name: unit_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.unit_unit_id_seq', 4, true);


--
-- Name: ORDER ORDER_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "ORDER_pkey" PRIMARY KEY (order_id);


--
-- Name: component_category component_category_name_group_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_category
    ADD CONSTRAINT component_category_name_group_id_key UNIQUE (name, group_id);


--
-- Name: component_category component_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_category
    ADD CONSTRAINT component_category_pkey PRIMARY KEY (category_id);


--
-- Name: component_group component_group_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_group
    ADD CONSTRAINT component_group_name_key UNIQUE (name);


--
-- Name: component_group component_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_group
    ADD CONSTRAINT component_group_pkey PRIMARY KEY (group_id);


--
-- Name: component component_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component
    ADD CONSTRAINT component_pkey PRIMARY KEY (stock_number);


--
-- Name: component_relation component_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_relation
    ADD CONSTRAINT component_relation_pkey PRIMARY KEY (parent_stock_number, child_stock_number);


--
-- Name: component_subcategory component_subcategory_name_category_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_subcategory
    ADD CONSTRAINT component_subcategory_name_category_id_key UNIQUE (name, category_id);


--
-- Name: component_subcategory component_subcategory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_subcategory
    ADD CONSTRAINT component_subcategory_pkey PRIMARY KEY (sub_category_id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- Name: energy_class energy_class_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.energy_class
    ADD CONSTRAINT energy_class_name_key UNIQUE (name);


--
-- Name: energy_class energy_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.energy_class
    ADD CONSTRAINT energy_class_pkey PRIMARY KEY (energy_class_id);


--
-- Name: market market_country_region_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.market
    ADD CONSTRAINT market_country_region_key UNIQUE (country, region);


--
-- Name: market market_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.market
    ADD CONSTRAINT market_pkey PRIMARY KEY (market_id);


--
-- Name: order_product order_product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_product
    ADD CONSTRAINT order_product_pkey PRIMARY KEY (order_id, sku);


--
-- Name: plug_type plug_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plug_type
    ADD CONSTRAINT plug_type_name_key UNIQUE (name);


--
-- Name: plug_type plug_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plug_type
    ADD CONSTRAINT plug_type_pkey PRIMARY KEY (plug_type_id);


--
-- Name: product_component product_component_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_component
    ADD CONSTRAINT product_component_pkey PRIMARY KEY (sku, stock_number);


--
-- Name: product_market product_market_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_market
    ADD CONSTRAINT product_market_pkey PRIMARY KEY (sku, market_id);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (sku);


--
-- Name: product_type product_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_type
    ADD CONSTRAINT product_type_name_key UNIQUE (name);


--
-- Name: product_type product_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_type
    ADD CONSTRAINT product_type_pkey PRIMARY KEY (product_type_id);


--
-- Name: production_line production_line_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_line
    ADD CONSTRAINT production_line_name_key UNIQUE (name);


--
-- Name: production_line production_line_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_line
    ADD CONSTRAINT production_line_pkey PRIMARY KEY (prod_line_id);


--
-- Name: production_line_product production_line_product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_line_product
    ADD CONSTRAINT production_line_product_pkey PRIMARY KEY (prod_line_id, sku);


--
-- Name: transportation transportation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation
    ADD CONSTRAINT transportation_pkey PRIMARY KEY (transportation_id);


--
-- Name: transportation_type transportation_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation_type
    ADD CONSTRAINT transportation_type_name_key UNIQUE (name);


--
-- Name: transportation_type transportation_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation_type
    ADD CONSTRAINT transportation_type_pkey PRIMARY KEY (transportation_type_id);


--
-- Name: unit unit_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit
    ADD CONSTRAINT unit_name_key UNIQUE (name);


--
-- Name: unit unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit
    ADD CONSTRAINT unit_pkey PRIMARY KEY (unit_id);


--
-- Name: idx_component_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_component_category ON public.component_subcategory USING btree (category_id);


--
-- Name: idx_component_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_component_group ON public.component_category USING btree (group_id);


--
-- Name: idx_component_relation_child; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_component_relation_child ON public.component_relation USING btree (child_stock_number);


--
-- Name: idx_component_relation_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_component_relation_parent ON public.component_relation USING btree (parent_stock_number);


--
-- Name: idx_component_subcategory; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_component_subcategory ON public.component USING btree (sub_category_id);


--
-- Name: idx_customer_market; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_customer_market ON public.customer USING btree (market_id);


--
-- Name: idx_order_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_customer ON public."ORDER" USING btree (customer_id);


--
-- Name: idx_order_customer_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_customer_status ON public."ORDER" USING btree (customer_id, status);


--
-- Name: idx_order_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_date ON public."ORDER" USING btree (order_date);


--
-- Name: idx_order_date_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_date_status ON public."ORDER" USING btree (order_date, status);


--
-- Name: idx_order_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_status ON public."ORDER" USING btree (status);


--
-- Name: idx_product_model; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_model ON public.product USING btree (model);


--
-- Name: idx_product_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_type ON public.product USING btree (product_type_id);


--
-- Name: idx_transportation_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transportation_date ON public.transportation USING btree (planned_date);


--
-- Name: idx_transportation_market; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transportation_market ON public.transportation USING btree (destination_market_id);


--
-- Name: idx_transportation_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transportation_order ON public.transportation USING btree (order_id);


--
-- Name: idx_transportation_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transportation_status ON public.transportation USING btree (status);


--
-- Name: idx_transportation_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transportation_type ON public.transportation USING btree (transportation_type_id);


--
-- Name: component_relation trg_prevent_component_cycle; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_component_cycle BEFORE INSERT OR UPDATE ON public.component_relation FOR EACH ROW EXECUTE FUNCTION public.fn_check_component_cycle();


--
-- Name: component_category fk_category_group; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_category
    ADD CONSTRAINT fk_category_group FOREIGN KEY (group_id) REFERENCES public.component_group(group_id) ON DELETE RESTRICT;


--
-- Name: component_relation fk_component_relation_child; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_relation
    ADD CONSTRAINT fk_component_relation_child FOREIGN KEY (child_stock_number) REFERENCES public.component(stock_number) ON DELETE RESTRICT;


--
-- Name: component_relation fk_component_relation_parent; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_relation
    ADD CONSTRAINT fk_component_relation_parent FOREIGN KEY (parent_stock_number) REFERENCES public.component(stock_number) ON DELETE RESTRICT;


--
-- Name: component_relation fk_component_relation_unit; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_relation
    ADD CONSTRAINT fk_component_relation_unit FOREIGN KEY (unit_id) REFERENCES public.unit(unit_id) ON DELETE RESTRICT;


--
-- Name: component fk_component_subcategory; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component
    ADD CONSTRAINT fk_component_subcategory FOREIGN KEY (sub_category_id) REFERENCES public.component_subcategory(sub_category_id) ON DELETE RESTRICT;


--
-- Name: component fk_component_unit; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component
    ADD CONSTRAINT fk_component_unit FOREIGN KEY (unit_id) REFERENCES public.unit(unit_id) ON DELETE RESTRICT;


--
-- Name: customer fk_customer_market; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT fk_customer_market FOREIGN KEY (market_id) REFERENCES public.market(market_id) ON DELETE RESTRICT;


--
-- Name: ORDER fk_order_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id) ON DELETE RESTRICT;


--
-- Name: order_product fk_order_product_order; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_product
    ADD CONSTRAINT fk_order_product_order FOREIGN KEY (order_id) REFERENCES public."ORDER"(order_id) ON DELETE CASCADE;


--
-- Name: order_product fk_order_product_sku; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_product
    ADD CONSTRAINT fk_order_product_sku FOREIGN KEY (sku) REFERENCES public.product(sku) ON DELETE RESTRICT;


--
-- Name: production_line_product fk_prod_line_product_line; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_line_product
    ADD CONSTRAINT fk_prod_line_product_line FOREIGN KEY (prod_line_id) REFERENCES public.production_line(prod_line_id) ON DELETE CASCADE;


--
-- Name: production_line_product fk_prod_line_product_sku; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_line_product
    ADD CONSTRAINT fk_prod_line_product_sku FOREIGN KEY (sku) REFERENCES public.product(sku) ON DELETE CASCADE;


--
-- Name: product_component fk_product_component_sku; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_component
    ADD CONSTRAINT fk_product_component_sku FOREIGN KEY (sku) REFERENCES public.product(sku) ON DELETE CASCADE;


--
-- Name: product_component fk_product_component_stock; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_component
    ADD CONSTRAINT fk_product_component_stock FOREIGN KEY (stock_number) REFERENCES public.component(stock_number) ON DELETE RESTRICT;


--
-- Name: product_component fk_product_component_unit; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_component
    ADD CONSTRAINT fk_product_component_unit FOREIGN KEY (unit_id) REFERENCES public.unit(unit_id) ON DELETE RESTRICT;


--
-- Name: product_market fk_product_market_energy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_market
    ADD CONSTRAINT fk_product_market_energy FOREIGN KEY (energy_class_id) REFERENCES public.energy_class(energy_class_id) ON DELETE RESTRICT;


--
-- Name: product_market fk_product_market_market; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_market
    ADD CONSTRAINT fk_product_market_market FOREIGN KEY (market_id) REFERENCES public.market(market_id) ON DELETE RESTRICT;


--
-- Name: product_market fk_product_market_plug; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_market
    ADD CONSTRAINT fk_product_market_plug FOREIGN KEY (plug_type_id) REFERENCES public.plug_type(plug_type_id) ON DELETE RESTRICT;


--
-- Name: product_market fk_product_market_sku; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_market
    ADD CONSTRAINT fk_product_market_sku FOREIGN KEY (sku) REFERENCES public.product(sku) ON DELETE CASCADE;


--
-- Name: product fk_product_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT fk_product_type FOREIGN KEY (product_type_id) REFERENCES public.product_type(product_type_id) ON DELETE RESTRICT;


--
-- Name: component_subcategory fk_subcategory_category; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_subcategory
    ADD CONSTRAINT fk_subcategory_category FOREIGN KEY (category_id) REFERENCES public.component_category(category_id) ON DELETE RESTRICT;


--
-- Name: transportation fk_transportation_market; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation
    ADD CONSTRAINT fk_transportation_market FOREIGN KEY (destination_market_id) REFERENCES public.market(market_id) ON DELETE RESTRICT;


--
-- Name: transportation fk_transportation_order; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation
    ADD CONSTRAINT fk_transportation_order FOREIGN KEY (order_id) REFERENCES public."ORDER"(order_id) ON DELETE CASCADE;


--
-- Name: transportation fk_transportation_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportation
    ADD CONSTRAINT fk_transportation_type FOREIGN KEY (transportation_type_id) REFERENCES public.transportation_type(transportation_type_id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict Js38W0wQoOyiZMd1lJy19SF5J3yTTt46r0dJNQ71dNkW1UuhII0Wbm8zQ1whLRr

