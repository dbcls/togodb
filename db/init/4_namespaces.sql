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
-- Data for Name: namespaces; Type: TABLE DATA; Schema: public; Owner: togodb
--

COPY public.namespaces (id, prefix, uri, is_default, created_at, updated_at) FROM stdin;
1	map	#	t	2017-04-05 07:23:51.2039	2017-04-05 07:23:51.2039
2	d2rq	http://www.wiwiss.fu-berlin.de/suhl/bizer/D2RQ/0.1#	t	2017-04-05 07:23:51.20588	2017-04-05 07:23:51.20588
3	jdbc	http://d2rq.org/terms/jdbc/	t	2017-04-05 07:23:51.207163	2017-04-05 07:23:51.207163
4	xsd	http://www.w3.org/2001/XMLSchema#	t	2017-04-05 07:23:51.208378	2017-04-05 07:23:51.208378
5	rdf	http://www.w3.org/1999/02/22-rdf-syntax-ns#	t	2017-04-05 07:23:51.209643	2017-04-05 07:23:51.209643
6	rdfs	http://www.w3.org/2000/01/rdf-schema#	t	2017-04-05 07:23:51.210922	2017-04-05 07:23:51.210922
7	dc	http://purl.org/dc/elements/1.1/	t	2017-04-05 07:23:51.212309	2017-04-05 07:23:51.212309
8	dcterms	http://purl.org/dc/terms/	t	2017-04-05 07:23:51.213611	2017-04-05 07:23:51.213611
9	foaf	http://xmlns.com/foaf/0.1/	t	2017-04-05 07:23:51.21478	2017-04-05 07:23:51.21478
10	skos	http://www.w3.org/2004/02/skos/core#	t	2017-04-05 07:23:51.216	2017-04-05 07:23:51.216
11	owl	http://www.w3.org/2002/07/owl#	t	2017-04-05 07:23:51.21721	2017-04-05 07:23:51.21721
\.


--
-- Name: namespaces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: togodb
--

SELECT pg_catalog.setval('public.namespaces_id_seq', 11, true);


--
-- PostgreSQL database dump complete
--

