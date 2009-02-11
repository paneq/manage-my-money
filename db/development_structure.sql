CREATE TABLE "bdrb_job_queues" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "args" blob, "worker_name" varchar(255), "worker_method" varchar(255), "job_key" varchar(255), "taken" int, "finished" int, "timeout" int, "priority" int, "submitted_at" datetime, "started_at" datetime, "finished_at" datetime, "archived_at" datetime, "tag" varchar(255), "submitter_info" varchar(255), "runner_info" varchar(255), "worker_key" varchar(255), "scheduled_at" datetime);
CREATE TABLE "categories" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255) NOT NULL, "description" varchar(255), "category_type_int" integer, "user_id" integer, "parent_id" integer, "lft" integer, "rgt" integer, "import_guid" varchar(255), "imported" boolean DEFAULT 'f');
CREATE TABLE "category_report_options" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "inclusion_type_int" integer DEFAULT 0 NOT NULL, "report_id" integer NOT NULL, "category_id" integer NOT NULL, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "currencies" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "symbol" varchar(255) NOT NULL, "long_symbol" varchar(255) NOT NULL, "name" varchar(255) NOT NULL, "long_name" varchar(255) NOT NULL, "user_id" integer);
CREATE TABLE "exchanges" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "currency_a" decimal(8,4) NOT NULL, "currency_b" decimal(8,4) NOT NULL, "left_to_right" float NOT NULL, "right_to_left" float NOT NULL, "day" date NOT NULL, "user_id" integer);
CREATE TABLE "goals" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" varchar(255), "include_subcategories" boolean, "period_type_int" integer, "goal_type_int" integer, "goal_completion_condition_int" integer, "value" float, "category_id" integer NOT NULL, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "reports" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "type" varchar(255), "name" varchar(255) NOT NULL, "period_type_int" integer NOT NULL, "period_start" date, "period_end" date, "report_view_type_int" integer NOT NULL, "is_predefined" boolean DEFAULT 'f' NOT NULL, "user_id" integer, "created_at" datetime, "updated_at" datetime, "depth" integer DEFAULT 0, "max_categories_values_count" integer DEFAULT 0, "category_id" integer, "period_division_int" integer DEFAULT 2, "temporary" boolean DEFAULT 'f' NOT NULL);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "sessions" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "session_id" varchar(255), "data" text, "updated_at" datetime);
CREATE TABLE "transfer_items" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" text NOT NULL, "value" decimal(8,2) NOT NULL, "transfer_id" integer NOT NULL, "category_id" integer NOT NULL, "currency_id" integer DEFAULT 3 NOT NULL, "import_guid" varchar(255));
CREATE TABLE "transfers" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" text NOT NULL, "day" date NOT NULL, "user_id" integer NOT NULL, "import_guid" varchar(255));
CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "login" varchar(40), "name" varchar(100) DEFAULT '', "email" varchar(100), "crypted_password" varchar(40), "salt" varchar(40), "created_at" datetime, "updated_at" datetime, "remember_token" varchar(40), "remember_token_expires_at" datetime, "activation_code" varchar(40), "activated_at" datetime, "transaction_amount_limit_type_int" integer DEFAULT 2 NOT NULL, "transaction_amount_limit_value" integer, "include_transactions_from_subcategories" boolean DEFAULT 'f' NOT NULL, "multi_currency_balance_calculating_algorithm_int" integer DEFAULT 0 NOT NULL, "default_currency_id" integer DEFAULT 1 NOT NULL, "invert_saldo_for_income" boolean DEFAULT 't' NOT NULL);
CREATE INDEX "index_categories_on_id_and_user_id_and_category_type_int" ON "categories" ("id", "user_id", "category_type_int");
CREATE INDEX "index_categories_on_lft_and_rgt" ON "categories" ("lft", "rgt");
CREATE INDEX "index_categories_on_rgt" ON "categories" ("rgt");
CREATE INDEX "index_category_report_options_on_report_id_and_category_id" ON "category_report_options" ("report_id", "category_id");
CREATE INDEX "index_currencies_on_id_and_user_id" ON "currencies" ("id", "user_id");
CREATE INDEX "index_exchanges_on_day" ON "exchanges" ("day");
CREATE INDEX "index_goals_on_category_id" ON "goals" ("category_id");
CREATE INDEX "index_goals_on_id" ON "goals" ("id");
CREATE INDEX "index_reports_on_category_id" ON "reports" ("category_id");
CREATE INDEX "index_reports_on_id" ON "reports" ("id");
CREATE INDEX "index_reports_on_user_id" ON "reports" ("user_id");
CREATE INDEX "index_sessions_on_session_id" ON "sessions" ("session_id");
CREATE INDEX "index_sessions_on_updated_at" ON "sessions" ("updated_at");
CREATE INDEX "index_transfer_items_on_category_id" ON "transfer_items" ("category_id");
CREATE INDEX "index_transfer_items_on_currency_id" ON "transfer_items" ("currency_id");
CREATE INDEX "index_transfer_items_on_id" ON "transfer_items" ("id");
CREATE INDEX "index_transfer_items_on_transfer_id" ON "transfer_items" ("transfer_id");
CREATE INDEX "index_transfers_on_day" ON "transfers" ("day");
CREATE INDEX "index_transfers_on_id_and_user_id" ON "transfers" ("id", "user_id");
CREATE INDEX "index_transfers_on_user_id" ON "transfers" ("user_id");
CREATE UNIQUE INDEX "index_users_on_id" ON "users" ("id");
CREATE UNIQUE INDEX "index_users_on_login" ON "users" ("login");
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
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