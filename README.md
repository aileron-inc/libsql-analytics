# libsql-analytics

Analytics gem for [Turso](https://turso.tech) (libSQL) — visit and event tracking built natively for Rails.

Inspired by [ahoy](https://github.com/ankane/ahoy), redesigned for Turso's Embedded Replica model.

## Features

- **Embedded Replica** — writes go to a local SQLite file instantly, synced to Turso Cloud automatically
- **ULID primary keys** — time-ordered, no UUID dependency
- **ActiveRecord models** — `Visit` and `Event` are AR models on a separate connection, isolated from your main DB
- **Zero impact on app** — analytics failures are rescued and logged, never propagate to users
- **Configurable skip paths** — skip tracking for assets, health checks, webhooks, etc.

## Installation

Add to your Gemfile:

```ruby
gem 'activerecord-libsql'
gem 'libsql-analytics'
```

## Setup

Create an initializer:

```ruby
# config/initializers/libsql_analytics.rb
Libsql::Analytics.configure do |config|
  config.url           = ENV["TURSO_URL"]    # libsql://your-db.turso.io
  config.token         = ENV["TURSO_TOKEN"]
  config.replica_path  = "storage/analytics.db"  # local replica file
  config.sync_interval = 60                  # sync to Turso every 60 seconds

  # Identify the logged-in account (optional)
  config.account_identity = ->(controller) { controller.current_user&.id }

  # Skip tracking for these path prefixes (default: ['/assets', '/favicon'])
  config.skip_paths = ['/assets', '/favicon', '/health', '/api/webhooks']
end
```

## Tables

`libsql-analytics` creates its own tables automatically on boot via `Migrator`.

### `libsql_analytics_visits`

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | ULID primary key |
| `visitor_id` | TEXT | Cookie-based visitor identifier |
| `account_identity` | TEXT | Logged-in account identifier (nullable) |
| `referrer` | TEXT | HTTP Referer header |
| `host` | TEXT | Request host (e.g. `example.com`) |
| `url` | TEXT | Full URL |
| `path` | TEXT | Request path |
| `query` | TEXT | Raw query string |
| `query_params` | TEXT | Query string as JSON |
| `metadata` | TEXT | JSON (ip, user_agent, etc.) |
| `started_at` | TEXT | ISO8601 timestamp |

### `libsql_analytics_events`

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | ULID primary key |
| `visit_id` | TEXT | Associated visit ID (nullable) |
| `name` | TEXT | Event name |
| `properties` | TEXT | JSON properties |
| `event_at` | TEXT | ISO8601 timestamp |

## Usage

### Visit tracking

Visits are tracked automatically via a `before_action` included in `ApplicationController`.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # automatically included by Railtie — nothing to do
end
```

### Event tracking

Track events from any controller action:

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create!(order_params)
    track_event("Order Placed", plan: @order.plan, amount: @order.total)
  end
end
```

### Querying data

`Visit` and `Event` are standard ActiveRecord models:

```ruby
# Recent visits
Libsql::Analytics::Visit.order(started_at: :desc).limit(10)

# Events by name
Libsql::Analytics::Event.where(name: "Order Placed")

# Visits with UTM source
Libsql::Analytics::Visit.where("query_params LIKE ?", "%utm_source%")
```

## Configuration reference

| Option | Default | Description |
|--------|---------|-------------|
| `url` | — | Turso database URL (`libsql://...`) |
| `token` | — | Turso auth token |
| `replica_path` | `"storage/analytics.db"` | Local replica file path |
| `sync_interval` | `60` | Sync interval in seconds (0 = manual only) |
| `account_identity` | `nil` | Lambda to extract account identifier from controller |
| `skip_paths` | `['/assets', '/favicon']` | Path prefixes to skip tracking |

## License

MIT
