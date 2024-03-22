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
-- Data for Name: class_map_properties; Type: TABLE DATA; Schema: public; Owner: togodb
--

COPY public.class_map_properties (id, property, label, is_literal, created_at, updated_at) FROM stdin;
1	d2rq:dataStorage	Data storage	f	2017-04-05 07:23:51.223721	2017-04-05 07:23:51.223721
2	d2rq:class	rdf:type	f	2017-04-05 07:23:51.225386	2017-04-05 07:23:51.225386
3	d2rq:uriPattern	URI pattern	t	2017-04-05 07:23:51.226714	2017-04-05 07:23:51.226714
4	d2rq:uriColumn	URI column	t	2017-04-05 07:23:51.227827	2017-04-05 07:23:51.227827
5	d2rq:uriSqlExpression	URI SQL Expression	t	2017-04-05 07:23:51.229059	2017-04-05 07:23:51.229059
6	d2rq:bNodeIdColumns	Blank node	t	2017-04-05 07:23:51.230232	2017-04-05 07:23:51.230232
7	d2rq:constantValue	Constant value	f	2017-04-05 07:23:51.231479	2017-04-05 07:23:51.231479
8	d2rq:containsDuplicates	Contains uplicates	t	2017-04-05 07:23:51.232708	2017-04-05 07:23:51.232708
9	d2rq:additionalProperty	Additional property	f	2017-04-05 07:23:51.23403	2017-04-05 07:23:51.23403
10	d2rq:condition	Condition	t	2017-04-05 07:23:51.235203	2017-04-05 07:23:51.235203
11	d2rq:classDefinitionLabel	rdfs:label	t	2017-04-05 07:23:51.236471	2017-04-05 07:23:51.236471
12	d2rq:classDefinitionComment	rdfs:comment	t	2017-04-05 07:23:51.237886	2017-04-05 07:23:51.237886
13	d2rq:additionalClassDefinitionProperty	Additional class definition property	f	2017-04-05 07:23:51.239132	2017-04-05 07:23:51.239132
14	d2rq:valueMaxLength	Max length of value	t	2017-04-05 07:23:51.240417	2017-04-05 07:23:51.240417
15	d2rq:valueRegex	Regular expression of value	t	2017-04-05 07:23:51.241738	2017-04-05 07:23:51.241738
16	d2rq:valueContains	Value contains	t	2017-04-05 07:23:51.243102	2017-04-05 07:23:51.243102
17	d2rq:translateWith	Translate with	t	2017-04-05 07:23:51.2443	2017-04-05 07:23:51.2443
18	d2rq:join	Join	t	2017-04-05 07:23:51.245457	2017-04-05 07:23:51.245457
19	d2rq:alias	Alias	t	2017-04-05 07:23:51.246644	2017-04-05 07:23:51.246644
\.


--
-- Name: class_map_properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: togodb
--

SELECT pg_catalog.setval('public.class_map_properties_id_seq', 19, true);


--
-- PostgreSQL database dump complete
--

