--
-- PostgreSQL database dump
--

-- Dumped from database version 11.5
-- Dumped by pg_dump version 11.5

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
-- Name: pgpool_catalog; Type: SCHEMA; Schema: -; Owner: togodb
--

CREATE SCHEMA pgpool_catalog;


ALTER SCHEMA pgpool_catalog OWNER TO togodb;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: insert_lock; Type: TABLE; Schema: pgpool_catalog; Owner: togodb
--

CREATE TABLE pgpool_catalog.insert_lock (
    reloid oid NOT NULL
);


--
-- Name: blank_nodes; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.blank_nodes (
    id integer NOT NULL,
    work_id integer,
    class_map_id integer,
    property_bridge_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    property_bridge_ids character varying
);


ALTER TABLE public.blank_nodes OWNER TO togodb;

--
-- Name: blank_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.blank_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blank_nodes_id_seq OWNER TO togodb;

--
-- Name: blank_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.blank_nodes_id_seq OWNED BY public.blank_nodes.id;


--
-- Name: class_map_properties; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.class_map_properties (
    id integer NOT NULL,
    property character varying,
    label character varying,
    is_literal boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.class_map_properties OWNER TO togodb;

--
-- Name: class_map_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.class_map_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.class_map_properties_id_seq OWNER TO togodb;

--
-- Name: class_map_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.class_map_properties_id_seq OWNED BY public.class_map_properties.id;


--
-- Name: class_map_property_settings; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.class_map_property_settings (
    id integer NOT NULL,
    class_map_id integer,
    class_map_property_id integer,
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.class_map_property_settings OWNER TO togodb;

--
-- Name: class_map_property_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.class_map_property_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.class_map_property_settings_id_seq OWNER TO togodb;

--
-- Name: class_map_property_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.class_map_property_settings_id_seq OWNED BY public.class_map_property_settings.id;


--
-- Name: class_maps; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.class_maps (
    id integer NOT NULL,
    work_id integer,
    map_name character varying,
    table_name character varying,
    enable boolean,
    table_join_id integer,
    bnode_id integer,
    er_xpos integer,
    er_ypos integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.class_maps OWNER TO togodb;

--
-- Name: class_maps_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.class_maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.class_maps_id_seq OWNER TO togodb;

--
-- Name: class_maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.class_maps_id_seq OWNED BY public.class_maps.id;


--
-- Name: db_connections; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.db_connections (
    id integer NOT NULL,
    adapter character varying,
    host character varying,
    port integer,
    database character varying,
    username character varying,
    work_id integer,
    password text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.db_connections OWNER TO togodb;

--
-- Name: db_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.db_connections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.db_connections_id_seq OWNER TO togodb;

--
-- Name: db_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.db_connections_id_seq OWNED BY public.db_connections.id;


--
-- Name: namespace_settings; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.namespace_settings (
    id integer NOT NULL,
    work_id integer,
    namespace_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ontology text,
    original_filename character varying,
    is_ontology boolean DEFAULT false NOT NULL
);


ALTER TABLE public.namespace_settings OWNER TO togodb;

--
-- Name: namespace_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.namespace_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.namespace_settings_id_seq OWNER TO togodb;

--
-- Name: namespace_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.namespace_settings_id_seq OWNED BY public.namespace_settings.id;


--
-- Name: namespaces; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.namespaces (
    id integer NOT NULL,
    prefix character varying,
    uri character varying,
    is_default boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.namespaces OWNER TO togodb;

--
-- Name: namespaces_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.namespaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.namespaces_id_seq OWNER TO togodb;

--
-- Name: namespaces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.namespaces_id_seq OWNED BY public.namespaces.id;


--
-- Name: ontologies; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.ontologies (
    id integer NOT NULL,
    work_id integer,
    ontology text,
    file_name character varying,
    file_format character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.ontologies OWNER TO togodb;

--
-- Name: ontologies_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.ontologies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ontologies_id_seq OWNER TO togodb;

--
-- Name: ontologies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.ontologies_id_seq OWNED BY public.ontologies.id;


--
-- Name: property_bridge_properties; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.property_bridge_properties (
    id integer NOT NULL,
    property character varying,
    label character varying,
    is_literal boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.property_bridge_properties OWNER TO togodb;

--
-- Name: property_bridge_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.property_bridge_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.property_bridge_properties_id_seq OWNER TO togodb;

--
-- Name: property_bridge_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.property_bridge_properties_id_seq OWNED BY public.property_bridge_properties.id;


--
-- Name: property_bridge_property_settings; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.property_bridge_property_settings (
    id integer NOT NULL,
    property_bridge_id integer,
    property_bridge_property_id integer,
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.property_bridge_property_settings OWNER TO togodb;

--
-- Name: property_bridge_property_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.property_bridge_property_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.property_bridge_property_settings_id_seq OWNER TO togodb;

--
-- Name: property_bridge_property_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.property_bridge_property_settings_id_seq OWNED BY public.property_bridge_property_settings.id;


--
-- Name: property_bridges; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.property_bridges (
    id integer NOT NULL,
    work_id integer,
    map_name character varying,
    class_map_id integer,
    user_defined boolean,
    column_name character varying,
    enable boolean,
    property_bridge_type_id integer,
    bnode_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.property_bridges OWNER TO togodb;

--
-- Name: property_bridges_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.property_bridges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.property_bridges_id_seq OWNER TO togodb;

--
-- Name: property_bridges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.property_bridges_id_seq OWNED BY public.property_bridges.id;


--
-- Name: property_bridge_types; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.property_bridge_types (
    id integer NOT NULL,
    symbol character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.property_bridge_types OWNER TO togodb;

--
-- Name: property_bridge_types_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.property_bridge_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.property_bridge_types_id_seq OWNER TO togodb;

--
-- Name: property_bridge_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.property_bridge_types_id_seq OWNED BY public.property_bridge_types.id;


--
-- Name: property_bridge_types id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridge_types ALTER COLUMN id SET DEFAULT nextval('public.property_bridge_types_id_seq'::regclass);


--
-- Name: property_bridge_types property_bridge_types_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridge_types
    ADD CONSTRAINT property_bridge_types_pkey PRIMARY KEY (id);


--
-- Name: table_joins; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.table_joins (
    id integer NOT NULL,
    work_id integer,
    l_table_class_map_id integer,
    l_table_property_bridge_id integer,
    r_table_class_map_id integer,
    r_table_property_bridge_id integer,
    i_table_class_map_id integer,
    i_table_l_property_bridge_id integer,
    i_table_r_property_bridge_id integer,
    class_map_id integer,
    property_bridge_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.table_joins OWNER TO togodb;

--
-- Name: table_joins_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.table_joins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.table_joins_id_seq OWNER TO togodb;

--
-- Name: table_joins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.table_joins_id_seq OWNED BY public.table_joins.id;


--
-- Name: togodb_cc_mappings; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_cc_mappings (
    id integer NOT NULL,
    licence character varying(255),
    url character varying(255)
);


ALTER TABLE public.togodb_cc_mappings OWNER TO togodb;

--
-- Name: togodb_cc_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_cc_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_cc_mappings_id_seq OWNER TO togodb;

--
-- Name: togodb_cc_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_cc_mappings_id_seq OWNED BY public.togodb_cc_mappings.id;


--
-- Name: togodb_column_values; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_column_values (
    id integer NOT NULL,
    column_id integer,
    value character varying(255)
);


ALTER TABLE public.togodb_column_values OWNER TO togodb;

--
-- Name: togodb_column_values_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_column_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_column_values_id_seq OWNER TO togodb;

--
-- Name: togodb_column_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_column_values_id_seq OWNED BY public.togodb_column_values.id;


--
-- Name: togodb_columns; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_columns (
    id integer NOT NULL,
    name character varying(255),
    internal_name character varying(255),
    data_type character varying(255),
    label character varying(255),
    enabled boolean DEFAULT true,
    actions character varying(255),
    roles character varying(255),
    "position" integer,
    html_link_prefix text,
    html_link_suffix character varying(255),
    list_disp_order integer,
    show_disp_order integer,
    dl_column_order integer,
    other_type character varying(255),
    web_services character varying(255),
    num_decimal_places integer,
    comment character varying(255),
    num_integer_digits integer,
    num_fractional_digits integer,
    search_help1 text,
    search_help2 text,
    rdf_p_property_prefix character varying(255),
    rdf_p_property_term character varying(255),
    rdf_p_property character varying(255),
    rdf_o_class_prefix character varying(255),
    rdf_o_class_term character varying(255),
    rdf_o_class character varying(255),
    id_separator character varying(255),
    table_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.togodb_columns OWNER TO togodb;

--
-- Name: togodb_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_columns_id_seq OWNER TO togodb;

--
-- Name: togodb_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_columns_id_seq OWNED BY public.togodb_columns.id;


--
-- Name: togodb_creates; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_creates (
    id integer NOT NULL,
    table_id integer,
    user_id integer,
    mode character varying,
    uploded_file_path text,
    utf8_file_path text,
    file_format character varying,
    input_file_encoding character varying,
    header_line boolean,
    num_columns integer,
    sample_data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.togodb_creates OWNER TO togodb;

--
-- Name: togodb_creates_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_creates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_creates_id_seq OWNER TO togodb;

--
-- Name: togodb_creates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_creates_id_seq OWNED BY public.togodb_creates.id;


--
-- Name: togodb_data_release_histories; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_data_release_histories (
    id integer NOT NULL,
    dataset_id integer,
    released_at timestamp without time zone,
    submitted_at timestamp without time zone,
    status character varying(255),
    message text,
    search_condition text
);


ALTER TABLE public.togodb_data_release_histories OWNER TO togodb;

--
-- Name: togodb_data_release_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_data_release_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_data_release_histories_id_seq OWNER TO togodb;

--
-- Name: togodb_data_release_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_data_release_histories_id_seq OWNED BY public.togodb_data_release_histories.id;


--
-- Name: togodb_datasets; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_datasets (
    id integer NOT NULL,
    table_id integer,
    name character varying(255),
    columns text,
    all_columns boolean,
    fasta_description text,
    output_file_path character varying(255),
    fasta_seq_column_id integer,
    filter_condition text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.togodb_datasets OWNER TO togodb;

--
-- Name: togodb_datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_datasets_id_seq OWNER TO togodb;

--
-- Name: togodb_datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_datasets_id_seq OWNED BY public.togodb_datasets.id;


--
-- Name: togodb_db_metadata_dois; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_db_metadata_dois (
    id integer NOT NULL,
    doi character varying,
    db_metadata_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.togodb_db_metadata_dois OWNER TO togodb;

--
-- Name: togodb_db_metadata_dois_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_db_metadata_dois_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_db_metadata_dois_id_seq OWNER TO togodb;

--
-- Name: togodb_db_metadata_dois_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_db_metadata_dois_id_seq OWNED BY public.togodb_db_metadata_dois.id;


--
-- Name: togodb_db_metadata_pubmeds; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_db_metadata_pubmeds (
    id integer NOT NULL,
    pubmed_id integer,
    db_metadata_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.togodb_db_metadata_pubmeds OWNER TO togodb;

--
-- Name: togodb_db_metadata_pubmeds_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_db_metadata_pubmeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_db_metadata_pubmeds_id_seq OWNER TO togodb;

--
-- Name: togodb_db_metadata_pubmeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_db_metadata_pubmeds_id_seq OWNED BY public.togodb_db_metadata_pubmeds.id;


--
-- Name: togodb_db_metadatas; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_db_metadatas (
    id integer NOT NULL,
    title character varying(255),
    description text,
    creator text,
    contributor text,
    keyword text,
    creative_commons integer,
    licence text,
    language_by_select text,
    language text,
    literature_reference text,
    vocabulary text,
    item_to_dataset_relation text,
    frequency_of_change text,
    agents text,
    database_name character varying(255),
    email character varying(255),
    postal_mail text,
    established_year integer,
    conditions_of_use integer,
    scope text,
    standards text,
    taxonomic_coverage text,
    data_accessibility text,
    data_release_frequency text,
    versioning_period text,
    documentation_available text,
    user_support_options text,
    data_submission_policy text,
    relevant_publications text,
    wikipedia_url text,
    tools_available text,
    table_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    pubmed character varying(255),
    doi character varying(255),
    confirm_license boolean DEFAULT false
);


ALTER TABLE public.togodb_db_metadatas OWNER TO togodb;

--
-- Name: togodb_db_metadatas_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_db_metadatas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_db_metadatas_id_seq OWNER TO togodb;

--
-- Name: togodb_db_metadatas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_db_metadatas_id_seq OWNED BY public.togodb_db_metadatas.id;


--
-- Name: togodb_lexvo_mappings; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_lexvo_mappings (
    id integer NOT NULL,
    language character varying(255),
    uri text
);


ALTER TABLE public.togodb_lexvo_mappings OWNER TO togodb;

--
-- Name: togodb_lexvo_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_lexvo_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_lexvo_mappings_id_seq OWNER TO togodb;

--
-- Name: togodb_lexvo_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_lexvo_mappings_id_seq OWNED BY public.togodb_lexvo_mappings.id;


--
-- Name: togodb_pages; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_pages (
    id integer NOT NULL,
    table_id integer,
    header_line boolean DEFAULT false,
    header_footer_lang integer DEFAULT 1,
    multiple_language boolean DEFAULT false,
    view_css text,
    view_header text,
    view_body text,
    quickbrowse text,
    show_css text,
    show_header text,
    show_body text,
    use_show_column_order boolean DEFAULT false,
    disp_search_help boolean DEFAULT false,
    search_help_lang character varying(255) DEFAULT '1'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.togodb_pages OWNER TO togodb;

--
-- Name: togodb_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_pages_id_seq OWNER TO togodb;

--
-- Name: togodb_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_pages_id_seq OWNED BY public.togodb_pages.id;


--
-- Name: togodb_roles; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_roles (
    id integer NOT NULL,
    roles character varying(255),
    table_id integer,
    user_id integer
);


ALTER TABLE public.togodb_roles OWNER TO togodb;

--
-- Name: togodb_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_roles_id_seq OWNER TO togodb;

--
-- Name: togodb_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_roles_id_seq OWNED BY public.togodb_roles.id;


--
-- Name: togodb_settings; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_settings (
    id integer NOT NULL,
    label character varying(255),
    actions character varying(255),
    externals text,
    html_title character varying(255),
    page_header text,
    page_footer text,
    html_head text,
    per_page integer,
    table_id integer
);


ALTER TABLE public.togodb_settings OWNER TO togodb;

--
-- Name: togodb_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_settings_id_seq OWNER TO togodb;

--
-- Name: togodb_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_settings_id_seq OWNED BY public.togodb_settings.id;


--
-- Name: togodb_supplementary_files; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_supplementary_files (
    id integer NOT NULL,
    original_filename character varying,
    togodb_table_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    json_for_file_tree text
);


ALTER TABLE public.togodb_supplementary_files OWNER TO togodb;

--
-- Name: togodb_supplementary_files_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_supplementary_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_supplementary_files_id_seq OWNER TO togodb;

--
-- Name: togodb_supplementary_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_supplementary_files_id_seq OWNED BY public.togodb_supplementary_files.id;


--
-- Name: togodb_syslogs; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_syslogs (
    id integer NOT NULL,
    priority integer DEFAULT 1,
    message text,
    "group" character varying(255),
    created_at timestamp without time zone
);


ALTER TABLE public.togodb_syslogs OWNER TO togodb;

--
-- Name: togodb_syslogs_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_syslogs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_syslogs_id_seq OWNER TO togodb;

--
-- Name: togodb_syslogs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_syslogs_id_seq OWNED BY public.togodb_syslogs.id;


--
-- Name: togodb_tables; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_tables (
    id integer NOT NULL,
    name character varying(255),
    enabled boolean,
    imported boolean,
    updated_at timestamp without time zone,
    sortable boolean DEFAULT true,
    page_name character varying(255),
    dl_file_name character varying(255),
    num_records integer DEFAULT '-1'::integer,
    creator_id integer,
    record_name_col_id integer,
    sort_col_id integer,
    disable_sort boolean DEFAULT false,
    pkey_col_id integer,
    record_name character varying(255),
    confirm_licence boolean DEFAULT false,
    owl text,
    created_at timestamp without time zone,
    resource_class character varying(255),
    resource_label character varying(255),
    migrate_ver character varying(255),
    work_id integer
);


ALTER TABLE public.togodb_tables OWNER TO togodb;

--
-- Name: togodb_tables_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_tables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_tables_id_seq OWNER TO togodb;

--
-- Name: togodb_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_tables_id_seq OWNED BY public.togodb_tables.id;


--
-- Name: togodb_users; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.togodb_users (
    id integer NOT NULL,
    login character varying(255),
    password character varying(255),
    flags character varying(255),
    tables character varying(255),
    deleted boolean DEFAULT false
);


ALTER TABLE public.togodb_users OWNER TO togodb;

--
-- Name: togodb_users_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.togodb_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.togodb_users_id_seq OWNER TO togodb;

--
-- Name: togodb_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.togodb_users_id_seq OWNED BY public.togodb_users.id;


--
-- Name: turtle_generations; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.turtle_generations (
    id integer NOT NULL,
    work_id integer,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    pid integer,
    status character varying,
    path character varying,
    error_message text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.turtle_generations OWNER TO togodb;

--
-- Name: turtle_generations_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.turtle_generations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.turtle_generations_id_seq OWNER TO togodb;

--
-- Name: turtle_generations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.turtle_generations_id_seq OWNED BY public.turtle_generations.id;


--
-- Name: works; Type: TABLE; Schema: public; Owner: togodb
--

CREATE TABLE public.works (
    id integer NOT NULL,
    name character varying,
    comment text,
    base_uri character varying,
    user_id integer,
    er_data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    mapping_updated timestamp without time zone
);


ALTER TABLE public.works OWNER TO togodb;

--
-- Name: works_id_seq; Type: SEQUENCE; Schema: public; Owner: togodb
--

CREATE SEQUENCE public.works_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.works_id_seq OWNER TO togodb;

--
-- Name: works_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: togodb
--

ALTER SEQUENCE public.works_id_seq OWNED BY public.works.id;


--
-- Name: blank_nodes id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.blank_nodes ALTER COLUMN id SET DEFAULT nextval('public.blank_nodes_id_seq'::regclass);


--
-- Name: class_map_properties id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.class_map_properties ALTER COLUMN id SET DEFAULT nextval('public.class_map_properties_id_seq'::regclass);


--
-- Name: class_map_property_settings id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.class_map_property_settings ALTER COLUMN id SET DEFAULT nextval('public.class_map_property_settings_id_seq'::regclass);


--
-- Name: class_maps id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.class_maps ALTER COLUMN id SET DEFAULT nextval('public.class_maps_id_seq'::regclass);


--
-- Name: db_connections id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.db_connections ALTER COLUMN id SET DEFAULT nextval('public.db_connections_id_seq'::regclass);


--
-- Name: namespace_settings id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.namespace_settings ALTER COLUMN id SET DEFAULT nextval('public.namespace_settings_id_seq'::regclass);


--
-- Name: namespaces id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.namespaces ALTER COLUMN id SET DEFAULT nextval('public.namespaces_id_seq'::regclass);


--
-- Name: ontologies id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.ontologies ALTER COLUMN id SET DEFAULT nextval('public.ontologies_id_seq'::regclass);


--
-- Name: property_bridge_properties id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridge_properties ALTER COLUMN id SET DEFAULT nextval('public.property_bridge_properties_id_seq'::regclass);


--
-- Name: property_bridge_property_settings id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridge_property_settings ALTER COLUMN id SET DEFAULT nextval('public.property_bridge_property_settings_id_seq'::regclass);


--
-- Name: property_bridges id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridges ALTER COLUMN id SET DEFAULT nextval('public.property_bridges_id_seq'::regclass);


--
-- Name: table_joins id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.table_joins ALTER COLUMN id SET DEFAULT nextval('public.table_joins_id_seq'::regclass);


--
-- Name: togodb_cc_mappings id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_cc_mappings ALTER COLUMN id SET DEFAULT nextval('public.togodb_cc_mappings_id_seq'::regclass);


--
-- Name: togodb_column_values id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_column_values ALTER COLUMN id SET DEFAULT nextval('public.togodb_column_values_id_seq'::regclass);


--
-- Name: togodb_columns id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_columns ALTER COLUMN id SET DEFAULT nextval('public.togodb_columns_id_seq'::regclass);


--
-- Name: togodb_creates id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_creates ALTER COLUMN id SET DEFAULT nextval('public.togodb_creates_id_seq'::regclass);


--
-- Name: togodb_data_release_histories id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_data_release_histories ALTER COLUMN id SET DEFAULT nextval('public.togodb_data_release_histories_id_seq'::regclass);


--
-- Name: togodb_datasets id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_datasets ALTER COLUMN id SET DEFAULT nextval('public.togodb_datasets_id_seq'::regclass);


--
-- Name: togodb_db_metadata_dois id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_db_metadata_dois ALTER COLUMN id SET DEFAULT nextval('public.togodb_db_metadata_dois_id_seq'::regclass);


--
-- Name: togodb_db_metadata_pubmeds id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_db_metadata_pubmeds ALTER COLUMN id SET DEFAULT nextval('public.togodb_db_metadata_pubmeds_id_seq'::regclass);


--
-- Name: togodb_db_metadatas id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_db_metadatas ALTER COLUMN id SET DEFAULT nextval('public.togodb_db_metadatas_id_seq'::regclass);


--
-- Name: togodb_lexvo_mappings id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_lexvo_mappings ALTER COLUMN id SET DEFAULT nextval('public.togodb_lexvo_mappings_id_seq'::regclass);


--
-- Name: togodb_pages id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_pages ALTER COLUMN id SET DEFAULT nextval('public.togodb_pages_id_seq'::regclass);


--
-- Name: togodb_roles id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_roles ALTER COLUMN id SET DEFAULT nextval('public.togodb_roles_id_seq'::regclass);


--
-- Name: togodb_settings id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_settings ALTER COLUMN id SET DEFAULT nextval('public.togodb_settings_id_seq'::regclass);


--
-- Name: togodb_supplementary_files id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_supplementary_files ALTER COLUMN id SET DEFAULT nextval('public.togodb_supplementary_files_id_seq'::regclass);


--
-- Name: togodb_syslogs id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_syslogs ALTER COLUMN id SET DEFAULT nextval('public.togodb_syslogs_id_seq'::regclass);


--
-- Name: togodb_tables id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_tables ALTER COLUMN id SET DEFAULT nextval('public.togodb_tables_id_seq'::regclass);


--
-- Name: togodb_users id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_users ALTER COLUMN id SET DEFAULT nextval('public.togodb_users_id_seq'::regclass);


--
-- Name: turtle_generations id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.turtle_generations ALTER COLUMN id SET DEFAULT nextval('public.turtle_generations_id_seq'::regclass);


--
-- Name: works id; Type: DEFAULT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.works ALTER COLUMN id SET DEFAULT nextval('public.works_id_seq'::regclass);


--
-- Name: blank_nodes blank_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.blank_nodes
    ADD CONSTRAINT blank_nodes_pkey PRIMARY KEY (id);


--
-- Name: class_map_properties class_map_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.class_map_properties
    ADD CONSTRAINT class_map_properties_pkey PRIMARY KEY (id);


--
-- Name: class_map_property_settings class_map_property_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.class_map_property_settings
    ADD CONSTRAINT class_map_property_settings_pkey PRIMARY KEY (id);


--
-- Name: class_maps class_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.class_maps
    ADD CONSTRAINT class_maps_pkey PRIMARY KEY (id);


--
-- Name: db_connections db_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.db_connections
    ADD CONSTRAINT db_connections_pkey PRIMARY KEY (id);


--
-- Name: namespace_settings namespace_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.namespace_settings
    ADD CONSTRAINT namespace_settings_pkey PRIMARY KEY (id);


--
-- Name: namespaces namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);


--
-- Name: ontologies ontologies_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.ontologies
    ADD CONSTRAINT ontologies_pkey PRIMARY KEY (id);


--
-- Name: property_bridge_properties property_bridge_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridge_properties
    ADD CONSTRAINT property_bridge_properties_pkey PRIMARY KEY (id);


--
-- Name: property_bridge_property_settings property_bridge_property_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridge_property_settings
    ADD CONSTRAINT property_bridge_property_settings_pkey PRIMARY KEY (id);


--
-- Name: property_bridges property_bridges_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.property_bridges
    ADD CONSTRAINT property_bridges_pkey PRIMARY KEY (id);


--
-- Name: table_joins table_joins_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.table_joins
    ADD CONSTRAINT table_joins_pkey PRIMARY KEY (id);


--
-- Name: togodb_cc_mappings togodb_cc_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_cc_mappings
    ADD CONSTRAINT togodb_cc_mappings_pkey PRIMARY KEY (id);


--
-- Name: togodb_column_values togodb_column_values_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_column_values
    ADD CONSTRAINT togodb_column_values_pkey PRIMARY KEY (id);


--
-- Name: togodb_columns togodb_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_columns
    ADD CONSTRAINT togodb_columns_pkey PRIMARY KEY (id);


--
-- Name: togodb_creates togodb_creates_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_creates
    ADD CONSTRAINT togodb_creates_pkey PRIMARY KEY (id);


--
-- Name: togodb_data_release_histories togodb_data_release_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_data_release_histories
    ADD CONSTRAINT togodb_data_release_histories_pkey PRIMARY KEY (id);


--
-- Name: togodb_datasets togodb_datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_datasets
    ADD CONSTRAINT togodb_datasets_pkey PRIMARY KEY (id);


--
-- Name: togodb_db_metadata_dois togodb_db_metadata_dois_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_db_metadata_dois
    ADD CONSTRAINT togodb_db_metadata_dois_pkey PRIMARY KEY (id);


--
-- Name: togodb_db_metadata_pubmeds togodb_db_metadata_pubmeds_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_db_metadata_pubmeds
    ADD CONSTRAINT togodb_db_metadata_pubmeds_pkey PRIMARY KEY (id);


--
-- Name: togodb_db_metadatas togodb_db_metadatas_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_db_metadatas
    ADD CONSTRAINT togodb_db_metadatas_pkey PRIMARY KEY (id);


--
-- Name: togodb_db_metadatas togodb_db_metadatas_table_id_key; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_db_metadatas
    ADD CONSTRAINT togodb_db_metadatas_table_id_key UNIQUE (table_id);


--
-- Name: togodb_lexvo_mappings togodb_lexvo_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_lexvo_mappings
    ADD CONSTRAINT togodb_lexvo_mappings_pkey PRIMARY KEY (id);


--
-- Name: togodb_pages togodb_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_pages
    ADD CONSTRAINT togodb_pages_pkey PRIMARY KEY (id);


--
-- Name: togodb_pages togodb_pages_table_id_key; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_pages
    ADD CONSTRAINT togodb_pages_table_id_key UNIQUE (table_id);


--
-- Name: togodb_roles togodb_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_roles
    ADD CONSTRAINT togodb_roles_pkey PRIMARY KEY (id);


--
-- Name: togodb_roles togodb_roles_table_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_roles
    ADD CONSTRAINT togodb_roles_table_id_user_id_key UNIQUE (table_id, user_id);


--
-- Name: togodb_settings togodb_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_settings
    ADD CONSTRAINT togodb_settings_pkey PRIMARY KEY (id);


--
-- Name: togodb_supplementary_files togodb_supplementary_files_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_supplementary_files
    ADD CONSTRAINT togodb_supplementary_files_pkey PRIMARY KEY (id);


--
-- Name: togodb_supplementary_files togodb_supplementary_files_togodb_table_id_key; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_supplementary_files
    ADD CONSTRAINT togodb_supplementary_files_togodb_table_id_key UNIQUE (togodb_table_id);


--
-- Name: togodb_syslogs togodb_syslogs_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_syslogs
    ADD CONSTRAINT togodb_syslogs_pkey PRIMARY KEY (id);


--
-- Name: togodb_tables togodb_tables_name_key; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_tables
    ADD CONSTRAINT togodb_tables_name_key UNIQUE (name);


--
-- Name: togodb_tables togodb_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_tables
    ADD CONSTRAINT togodb_tables_pkey PRIMARY KEY (id);


--
-- Name: togodb_users togodb_users_login_key; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_users
    ADD CONSTRAINT togodb_users_login_key UNIQUE (login);


--
-- Name: togodb_users togodb_users_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_users
    ADD CONSTRAINT togodb_users_pkey PRIMARY KEY (id);


--
-- Name: turtle_generations turtle_generations_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.turtle_generations
    ADD CONSTRAINT turtle_generations_pkey PRIMARY KEY (id);


--
-- Name: works works_pkey; Type: CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.works
    ADD CONSTRAINT works_pkey PRIMARY KEY (id);


--
-- Name: index_togodb_supplementary_files_on_togodb_table_id; Type: INDEX; Schema: public; Owner: togodb
--

CREATE INDEX index_togodb_supplementary_files_on_togodb_table_id ON public.togodb_supplementary_files USING btree (togodb_table_id);


--
-- Name: togodb_supplementary_files fk_rails_2c6530ac55; Type: FK CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_supplementary_files
    ADD CONSTRAINT fk_rails_2c6530ac55 FOREIGN KEY (togodb_table_id) REFERENCES public.togodb_tables(id);


--
-- Name: togodb_tables togodb_tables_work_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: togodb
--

ALTER TABLE ONLY public.togodb_tables
    ADD CONSTRAINT togodb_tables_work_id_fkey FOREIGN KEY (work_id) REFERENCES public.works(id);


--
-- Name: SCHEMA pgpool_catalog; Type: ACL; Schema: -; Owner: togodb
--

GRANT USAGE ON SCHEMA pgpool_catalog TO PUBLIC;


--
-- Name: TABLE insert_lock; Type: ACL; Schema: pgpool_catalog; Owner: togodb
--

GRANT SELECT,INSERT,UPDATE ON TABLE pgpool_catalog.insert_lock TO PUBLIC;


--
-- PostgreSQL database dump complete
--

