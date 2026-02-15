# frozen_string_literal: true

class HomeController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::EnsureInstalled
  include ShopifyApp::ShopAccessScopesVerification

  DEV_INDEX_PATH = Rails.root.join("frontend")
  PROD_INDEX_PATH = Rails.public_path.join("dist")

  def index
    if ShopifyAPI::Context.embedded? && (!params[:embedded].present? || params[:embedded] != "1")
      redirect_to(ShopifyAPI::Auth.embedded_app_url(params[:host]), allow_other_host: true)
    else
      render(plain: rendered_index_html, content_type: "text/html", layout: false)
    end
  end

  private

  def rendered_index_html
    if Rails.env.production?
      self.class.production_index_html
    else
      read_and_render_index_html
    end
  end

  def read_and_render_index_html
    contents = File.read(File.join(DEV_INDEX_PATH, "index.html"))
    contents.sub("%VITE_SHOPIFY_API_KEY%", ShopifyApp.configuration.api_key)
  end

  def self.production_index_html
    @production_index_html ||= begin
      contents = File.read(File.join(PROD_INDEX_PATH, "index.html"))
      contents.sub("%VITE_SHOPIFY_API_KEY%", ShopifyApp.configuration.api_key).freeze
    end
  end
end
