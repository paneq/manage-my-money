CREATE TABLE "categories" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255) NOT NULL, "description" varchar(255), "category_type_int" integer, "user_id" integer, "parent_id" integer, "lft" integer, "rgt" integer);
CREATE TABLE "currencies" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "symbol" varchar(255) NOT NULL, "long_symbol" varchar(255) NOT NULL, "name" varchar(255) NOT NULL, "long_name" varchar(255) NOT NULL, "user_id" integer);
CREATE TABLE "exchanges" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "currency_a" integer NOT NULL, "currency_b" integer NOT NULL, "left_to_right" float NOT NULL, "right_to_left" float NOT NULL, "day" date NOT NULL, "user_id" integer);
CREATE TABLE "goals" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" varchar(255), "include_subcategories" boolean, "period_type_int" integer, "goal_type_int" integer, "goal_completion_condition_int" integer, "value" float, "category_id" integer NOT NULL, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "sessions" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "session_id" varchar(255), "data" text, "updated_at" datetime);
CREATE TABLE "transfer_items" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" text NOT NULL, "value" integer NOT NULL, "transfer_id" integer NOT NULL, "category_id" integer NOT NULL, "currency_id" integer DEFAULT 3 NOT NULL);
CREATE TABLE "transfers" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" text NOT NULL, "day" date NOT NULL, "user_id" integer NOT NULL);
CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "login" varchar(40), "name" varchar(100) DEFAULT '', "email" varchar(100), "crypted_password" varchar(40), "salt" varchar(40), "created_at" datetime, "updated_at" datetime, "remember_token" varchar(40), "remember_token_expires_at" datetime, "activation_code" varchar(40), "activated_at" datetime, "active" boolean DEFAULT 'f' NOT NULL, "transaction_amount_limit_type_int" integer DEFAULT 0 NOT NULL, "transaction_amount_limit_value" integer, "include_transactions_from_subcategories" boolean DEFAULT 'f' NOT NULL, "multi_currency_balance_calculating_algorithm_int" integer DEFAULT 0 NOT NULL);
CREATE INDEX "index_sessions_on_session_id" ON "sessions" ("session_id");
CREATE INDEX "index_sessions_on_updated_at" ON "sessions" ("updated_at");
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