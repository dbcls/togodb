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
-- Data for Name: property_bridge_properties; Type: TABLE DATA; Schema: public; Owner: togodb
--

COPY public.property_bridge_properties (id, property, label, is_literal, created_at, updated_at) FROM stdin;
1	d2rq:belongsToClassMap	Belongs to class map	f	2017-04-05 07:23:51.253378	2017-04-05 07:23:51.253378
2	d2rq:property	Property	f	2017-04-05 07:23:51.255659	2017-04-05 07:23:51.255659
3	d2rq:dynamicProperty	Dynamic property	t	2017-04-05 07:23:51.257029	2017-04-05 07:23:51.257029
4	d2rq:column	Literal column	t	2017-04-05 07:23:51.2585	2017-04-05 07:23:51.2585
5	d2rq:pattern	Literal pattern	t	2017-04-05 07:23:51.259758	2017-04-05 07:23:51.259758
6	d2rq:sqlExpression	Literal SQL Expression	t	2017-04-05 07:23:51.261074	2017-04-05 07:23:51.261074
7	d2rq:uriColumn	URI column	t	2017-04-05 07:23:51.262284	2017-04-05 07:23:51.262284
8	d2rq:uriPattern	URI pattern	t	2017-04-05 07:23:51.263602	2017-04-05 07:23:51.263602
9	d2rq:uriSqlExpression	URI SQL Expression	t	2017-04-05 07:23:51.264774	2017-04-05 07:23:51.264774
10	d2rq:constantValue	Constant value	t	2017-04-05 07:23:51.26617	2017-04-05 07:23:51.26617
11	d2rq:refersToClassMap	Subject URI of object table record	f	2017-04-05 07:23:51.267467	2017-04-05 07:23:51.267467
12	d2rq:datatype	Data type	f	2017-04-05 07:23:51.268736	2017-04-05 07:23:51.268736
13	d2rq:lang	Lang	t	2017-04-05 07:23:51.270023	2017-04-05 07:23:51.270023
14	d2rq:join	Join	t	2017-04-05 07:23:51.271319	2017-04-05 07:23:51.271319
15	d2rq:alias	Alias	t	2017-04-05 07:23:51.272578	2017-04-05 07:23:51.272578
16	d2rq:condition	Condition	t	2017-04-05 07:23:51.27376	2017-04-05 07:23:51.27376
17	d2rq:translateWith	Translate with	t	2017-04-05 07:23:51.275094	2017-04-05 07:23:51.275094
18	d2rq:valueMaxLength	Max length of value	t	2017-04-05 07:23:51.276422	2017-04-05 07:23:51.276422
19	d2rq:valueContains	Value contains	t	2017-04-05 07:23:51.277651	2017-04-05 07:23:51.277651
20	d2rq:valueRegex	Regular expression of value	t	2017-04-05 07:23:51.278995	2017-04-05 07:23:51.278995
21	d2rq:propertyDefinitionLabel	rdfs:label	t	2017-04-05 07:23:51.280293	2017-04-05 07:23:51.280293
22	d2rq:propertyDefinitionComment	rdfs:comment	t	2017-04-05 07:23:51.281583	2017-04-05 07:23:51.281583
23	d2rq:additionalPropertyDefinitionProperty	Additional property definition property	f	2017-04-05 07:23:51.282774	2017-04-05 07:23:51.282774
24	d2rq:limit	Limit	t	2017-04-05 07:23:51.284092	2017-04-05 07:23:51.284092
25	d2rq:limitInverse	Limit inverse	t	2017-04-05 07:23:51.285339	2017-04-05 07:23:51.285339
26	d2rq:orderAsc	Order asc	t	2017-04-05 07:23:51.286603	2017-04-05 07:23:51.286603
27	d2rq:orderDesc	Order desc	t	2017-04-05 07:23:51.287868	2017-04-05 07:23:51.287868
\.


--
-- Name: property_bridge_properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: togodb
--

SELECT pg_catalog.setval('public.property_bridge_properties_id_seq', 27, true);


--
-- PostgreSQL database dump complete
--

