# Efficiency Report: shopify-app-template-ruby

## 1. HomeController reads index.html from disk on every request

**File:** `web/app/controllers/home_controller.rb:15`

Every request to the root path calls `File.read(...)` and `String#sub!` to inject the API key. In production the file and the API key never change, so this disk I/O and string processing is repeated unnecessarily on every single page load.

**Recommendation:** Memoize the rendered HTML in a class-level variable so the file is read and processed only once in production.

---

## 2. ProductCreator instantiates a new GraphQL client per product

**File:** `web/app/services/product_creator.rb:29`

Inside the `count.times` loop, a new `ShopifyAPI::Clients::Graphql::Admin` object is allocated on every iteration. When creating 5 products (the default), this means 5 identical client objects are constructed instead of 1.

**Recommendation:** Create the client once before the loop and reuse it across iterations.

---

## 3. Duplicated shop-lookup guard clause across all webhook jobs

**Files:** `web/app/jobs/app_uninstalled_job.rb`, `app_scopes_update_job.rb`, `customers_data_request_job.rb`, `customers_redact_job.rb`, `shop_redact_job.rb`

Every webhook job repeats the same four-line pattern:

```ruby
shop = Shop.find_by(shopify_domain: shop_domain)
if shop.nil?
  logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
  return
end
```

**Recommendation:** Extract this into a shared concern (e.g., `ShopLookup`) or a base `WebhookJob` class so the logic lives in one place.

---

## 4. Identical `api_version` method in Shop and User models

**Files:** `web/app/models/shop.rb:6-8`, `web/app/models/user.rb:6-8`

Both models define the exact same method:

```ruby
def api_version
  ShopifyApp.configuration.api_version
end
```

**Recommendation:** Extract into a shared `Configurable` concern that both models include.

---

## 5. Duplicated webhook controller receive logic

**Files:** All five controllers under `web/app/controllers/webhooks/`

Each webhook controller has an identical `receive` method that only differs in the job class it dispatches to. This is five copies of the same code.

**Recommendation:** Extract a shared `WebhookReceivable` concern that accepts the job class as a parameter, or use a single controller with a routing parameter.

---

## Fix Applied

This PR addresses **Issue #1** (HomeController disk I/O on every request) as it impacts every page load in production.
