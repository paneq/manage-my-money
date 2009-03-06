--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bdrb_job_queues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bdrb_job_queues (
    id integer NOT NULL,
    args bytea,
    worker_name character varying(255),
    worker_method character varying(255),
    job_key character varying(255),
    taken integer,
    finished integer,
    timeout integer,
    priority integer,
    submitted_at timestamp without time zone,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    archived_at timestamp without time zone,
    tag character varying(255),
    submitter_info character varying(255),
    runner_info character varying(255),
    worker_key character varying(255),
    scheduled_at timestamp without time zone
);


--
-- Name: bdrb_job_queues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bdrb_job_queues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bdrb_job_queues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bdrb_job_queues_id_seq OWNED BY bdrb_job_queues.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE categories (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    category_type_int integer,
    user_id integer,
    parent_id integer,
    lft integer,
    rgt integer,
    import_guid character varying(255),
    imported boolean DEFAULT false,
    type character varying(255),
    email character varying(255),
    bankinfo text,
    bank_account_number character varying(255)
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;


--
-- Name: category_report_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE category_report_options (
    id integer NOT NULL,
    inclusion_type_int integer DEFAULT 0 NOT NULL,
    report_id integer NOT NULL,
    category_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: category_report_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE category_report_options_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: category_report_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE category_report_options_id_seq OWNED BY category_report_options.id;


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE currencies (
    id integer NOT NULL,
    symbol character varying(255) NOT NULL,
    long_symbol character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    long_name character varying(255) NOT NULL,
    user_id integer
);


--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE currencies_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: currencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE currencies_id_seq OWNED BY currencies.id;


--
-- Name: exchanges; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE exchanges (
    id integer NOT NULL,
    currency_a numeric(8,4) NOT NULL,
    currency_b numeric(8,4) NOT NULL,
    left_to_right double precision NOT NULL,
    right_to_left double precision NOT NULL,
    day date NOT NULL,
    user_id integer
);


--
-- Name: exchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE exchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: exchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE exchanges_id_seq OWNED BY exchanges.id;


--
-- Name: goals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE goals (
    id integer NOT NULL,
    description character varying(255),
    include_subcategories boolean,
    period_type_int integer,
    goal_type_int integer DEFAULT 0,
    goal_completion_condition_int integer DEFAULT 0,
    value double precision,
    category_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    currency_id integer,
    period_start date,
    period_end date,
    is_cyclic boolean DEFAULT false NOT NULL,
    is_finished boolean DEFAULT false NOT NULL,
    cycle_group integer,
    user_id integer NOT NULL
);


--
-- Name: goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE goals_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE goals_id_seq OWNED BY goals.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reports (
    id integer NOT NULL,
    type character varying(255),
    name character varying(255) NOT NULL,
    period_type_int integer NOT NULL,
    period_start date,
    period_end date,
    report_view_type_int integer NOT NULL,
    is_predefined boolean DEFAULT false NOT NULL,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    depth integer DEFAULT 0,
    max_categories_values_count integer DEFAULT 0,
    category_id integer,
    period_division_int integer DEFAULT 5,
    temporary boolean DEFAULT false NOT NULL,
    relative_period boolean DEFAULT false NOT NULL
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reports_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(255),
    data text,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: transfer_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transfer_items (
    id integer NOT NULL,
    description text NOT NULL,
    value numeric(12,2) NOT NULL,
    transfer_id integer NOT NULL,
    category_id integer NOT NULL,
    currency_id integer DEFAULT 3 NOT NULL,
    import_guid character varying(255)
);


--
-- Name: transfer_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transfer_items_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: transfer_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transfer_items_id_seq OWNED BY transfer_items.id;


--
-- Name: transfers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transfers (
    id integer NOT NULL,
    description text NOT NULL,
    day date NOT NULL,
    user_id integer NOT NULL,
    import_guid character varying(255)
);


--
-- Name: transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transfers_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transfers_id_seq OWNED BY transfers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(40),
    name character varying(100) DEFAULT ''::character varying,
    email character varying(100),
    crypted_password character varying(40),
    salt character varying(40),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    remember_token character varying(40),
    remember_token_expires_at timestamp without time zone,
    activation_code character varying(40),
    activated_at timestamp without time zone,
    transaction_amount_limit_type_int integer DEFAULT 2 NOT NULL,
    transaction_amount_limit_value integer,
    include_transactions_from_subcategories boolean DEFAULT false NOT NULL,
    multi_currency_balance_calculating_algorithm_int integer DEFAULT 0 NOT NULL,
    default_currency_id integer DEFAULT 1 NOT NULL,
    invert_saldo_for_income boolean DEFAULT true NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bdrb_job_queues ALTER COLUMN id SET DEFAULT nextval('bdrb_job_queues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE category_report_options ALTER COLUMN id SET DEFAULT nextval('category_report_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE currencies ALTER COLUMN id SET DEFAULT nextval('currencies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE exchanges ALTER COLUMN id SET DEFAULT nextval('exchanges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE goals ALTER COLUMN id SET DEFAULT nextval('goals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE transfer_items ALTER COLUMN id SET DEFAULT nextval('transfer_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE transfers ALTER COLUMN id SET DEFAULT nextval('transfers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: bdrb_job_queues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bdrb_job_queues
    ADD CONSTRAINT bdrb_job_queues_pkey PRIMARY KEY (id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: category_report_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY category_report_options
    ADD CONSTRAINT category_report_options_pkey PRIMARY KEY (id);


--
-- Name: currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: exchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY exchanges
    ADD CONSTRAINT exchanges_pkey PRIMARY KEY (id);


--
-- Name: goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: transfer_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transfer_items
    ADD CONSTRAINT transfer_items_pkey PRIMARY KEY (id);


--
-- Name: transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_categories_on_id_and_user_id_and_category_type_int; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_categories_on_id_and_user_id_and_category_type_int ON categories USING btree (id, user_id, category_type_int);


--
-- Name: index_categories_on_lft_and_rgt; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_categories_on_lft_and_rgt ON categories USING btree (lft, rgt);


--
-- Name: index_categories_on_rgt; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_categories_on_rgt ON categories USING btree (rgt);


--
-- Name: index_category_report_options_on_report_id_and_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_category_report_options_on_report_id_and_category_id ON category_report_options USING btree (report_id, category_id);


--
-- Name: index_currencies_on_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_currencies_on_id_and_user_id ON currencies USING btree (id, user_id);


--
-- Name: index_exchanges_on_day; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_exchanges_on_day ON exchanges USING btree (day);


--
-- Name: index_goals_on_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_goals_on_category_id ON goals USING btree (category_id);


--
-- Name: index_goals_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_goals_on_id ON goals USING btree (id);


--
-- Name: index_reports_on_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_reports_on_category_id ON reports USING btree (category_id);


--
-- Name: index_reports_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_reports_on_id ON reports USING btree (id);


--
-- Name: index_reports_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_reports_on_user_id ON reports USING btree (user_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_transfer_items_on_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transfer_items_on_category_id ON transfer_items USING btree (category_id);


--
-- Name: index_transfer_items_on_currency_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transfer_items_on_currency_id ON transfer_items USING btree (currency_id);


--
-- Name: index_transfer_items_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transfer_items_on_id ON transfer_items USING btree (id);


--
-- Name: index_transfer_items_on_transfer_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transfer_items_on_transfer_id ON transfer_items USING btree (transfer_id);


--
-- Name: index_transfers_on_day; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transfers_on_day ON transfers USING btree (day);


--
-- Name: index_transfers_on_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transfers_on_id_and_user_id ON transfers USING btree (id, user_id);


--
-- Name: index_transfers_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transfers_on_user_id ON transfers USING btree (user_id);


--
-- Name: index_users_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_id ON users USING btree (id);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_login ON users USING btree (login);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');

INSERT INTO schema_migrations (version) VALUES ('20081110145518');

INSERT INTO schema_migrations (version) VALUES ('20081206132610');

INSERT INTO schema_migrations (version) VALUES ('20081208212007');

INSERT INTO schema_migrations (version) VALUES ('20081208215053');

INSERT INTO schema_migrations (version) VALUES ('20090104123107');

INSERT INTO schema_migrations (version) VALUES ('20090124132402');

INSERT INTO schema_migrations (version) VALUES ('20090124144600');

INSERT INTO schema_migrations (version) VALUES ('20090201170116');

INSERT INTO schema_migrations (version) VALUES ('20090206222509');

INSERT INTO schema_migrations (version) VALUES ('20090207121136');

INSERT INTO schema_migrations (version) VALUES ('20090207162724');

INSERT INTO schema_migrations (version) VALUES ('20090208112934');

INSERT INTO schema_migrations (version) VALUES ('20090211155039');

INSERT INTO schema_migrations (version) VALUES ('20090216182617');

INSERT INTO schema_migrations (version) VALUES ('20090219102055');

INSERT INTO schema_migrations (version) VALUES ('20090219104138');

INSERT INTO schema_migrations (version) VALUES ('20090221110740');

INSERT INTO schema_migrations (version) VALUES ('20090226180602');

INSERT INTO schema_migrations (version) VALUES ('20090226214904');

INSERT INTO schema_migrations (version) VALUES ('20090227165910');

INSERT INTO schema_migrations (version) VALUES ('20090301162726');

INSERT INTO schema_migrations (version) VALUES ('20090306160304');