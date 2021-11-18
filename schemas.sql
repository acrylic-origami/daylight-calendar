--
-- PostgreSQL database dump
--

-- Dumped from database version 13.1
-- Dumped by pg_dump version 13.1

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
-- Name: ivlrange; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ivlrange AS RANGE (
    subtype = interval
);


ALTER TYPE public.ivlrange OWNER TO postgres;

--
-- Name: sun_day(interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sun_day(interval) RETURNS interval
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT DATE_TRUNC('hour', $1 / 12) * 12;$_$;


ALTER FUNCTION public.sun_day(interval) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: locs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locs (
    id integer NOT NULL,
    lat double precision,
    lng double precision
);


ALTER TABLE public.locs OWNER TO postgres;

--
-- Name: locs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.locs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.locs_id_seq OWNER TO postgres;

--
-- Name: locs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.locs_id_seq OWNED BY public.locs.id;


--
-- Name: suns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.suns (
    id integer NOT NULL,
    rise timestamp without time zone,
    falls tsrange,
    loc_id integer,
    year integer,
    unix_cumsum public.ivlrange,
    year_cumsum public.ivlrange
);


ALTER TABLE public.suns OWNER TO postgres;

--
-- Name: suns_corners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.suns_corners (
    id integer NOT NULL,
    rise timestamp without time zone,
    falls tsrange,
    loc_id integer,
    year integer,
    unix_cumsum public.ivlrange,
    year_cumsum public.ivlrange
);


ALTER TABLE public.suns_corners OWNER TO postgres;

--
-- Name: suns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.suns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.suns_id_seq OWNER TO postgres;

--
-- Name: suns_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.suns_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.suns_id_seq1 OWNER TO postgres;

--
-- Name: suns_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.suns_id_seq1 OWNED BY public.suns.id;


--
-- Name: unix_day_bases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unix_day_bases (
    sun_day interval NOT NULL,
    loc_id integer NOT NULL,
    base timestamp without time zone
);


ALTER TABLE public.unix_day_bases OWNER TO postgres;

--
-- Name: locs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locs ALTER COLUMN id SET DEFAULT nextval('public.locs_id_seq'::regclass);


--
-- Name: suns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.suns ALTER COLUMN id SET DEFAULT nextval('public.suns_id_seq1'::regclass);


--
-- Name: locs locs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locs
    ADD CONSTRAINT locs_pkey PRIMARY KEY (id);


--
-- Name: suns suns_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.suns
    ADD CONSTRAINT suns_pkey1 PRIMARY KEY (id);


--
-- Name: unix_day_bases unix_day_bases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unix_day_bases
    ADD CONSTRAINT unix_day_bases_pkey PRIMARY KEY (sun_day, loc_id);


--
-- Name: locs_lat_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locs_lat_idx ON public.locs USING btree (lat);


--
-- Name: locs_lng_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locs_lng_idx ON public.locs USING btree (lng);


--
-- Name: suns_falls_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX suns_falls_idx1 ON public.suns USING gist (falls);


--
-- Name: suns_falls_idx2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX suns_falls_idx2 ON public.suns USING gist (falls);


--
-- Name: suns_rise_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX suns_rise_idx1 ON public.suns USING btree (rise);


--
-- Name: suns_unix_cumsum_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX suns_unix_cumsum_idx ON public.suns USING gist (unix_cumsum);


--
-- Name: suns_year_cumsum_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX suns_year_cumsum_idx ON public.suns USING gist (year_cumsum);


--
-- Name: suns_year_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX suns_year_idx1 ON public.suns USING btree (year);


--
-- Name: unix_day_bases_loc_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX unix_day_bases_loc_id_idx ON public.unix_day_bases USING btree (loc_id);


--
-- Name: suns suns_loc_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.suns
    ADD CONSTRAINT suns_loc_id_fkey1 FOREIGN KEY (loc_id) REFERENCES public.locs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: unix_day_bases unix_day_bases_loc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unix_day_bases
    ADD CONSTRAINT unix_day_bases_loc_id_fkey FOREIGN KEY (loc_id) REFERENCES public.locs(id);


--
-- PostgreSQL database dump complete
--

