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
-- Data for Name: property_bridge_types; Type: TABLE DATA; Schema: public; Owner: togodb
--

COPY public.property_bridge_types (id, symbol, created_at, updated_at) FROM stdin;
1	column	2017-04-05 07:23:51.295768	2017-04-05 07:23:51.295768
2	label	2017-04-05 07:23:51.297279	2017-04-05 07:23:51.297279
3	bnode	2017-04-05 07:23:51.29844	2017-04-05 07:23:51.29844
\.


--
-- Name: property_bridge_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: togodb
--

SELECT pg_catalog.setval('public.property_bridge_types_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

