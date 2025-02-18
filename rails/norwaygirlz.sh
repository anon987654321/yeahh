#!/usr/bin/env zsh
set -e

# pappas.sh - Pappas Favorite: A Video-Sharing Platform

app_name="pappas_favorite"
source __shared.sh

initialize_app() {
  initialize_setup "$app_name"
  create_rails_app "$app_name"
  install_common_gems
  setup_devise
  setup_frontend
  generate_video_model
  generate_video_controller
  setup_routes
  generate_video_views
  generate_scss "$app_name"
  seed_database
  log "$app_name setup completed"
}

generate_video_model() {
  generate_model "Video" "title:string description:text user:references views_count:integer" \
    "validates :title, :description, presence: true" \
    "belongs_to :user\nhas_many :comments, dependent: :destroy\nhas_many :likes, dependent: :destroy"
}

generate_video_controller() {
  generate_controller "Videos"
}

setup_routes() {
  log "Configuring routes for $app_name"
  cat <<EOF > config/routes.rb
Rails.application.routes.draw do
  root 'videos#index'
  devise_for :users
  resources :videos do
    resources :comments, only: [:create, :destroy]
    resources :likes, only: [:create, :destroy]
  end
end
EOF
}

generate_video_views() {
  log "Generating minimal views for Videos"

  mkdir -p app/views/videos

  # Index view for Videos
  cat <<EOF > app/views/videos/index.html.erb
<h1>Your Videos</h1>
<%= link_to 'Add New Video', new_video_path if user_signed_in? %>

<div class="videos">
  <% @videos.each do |video| %>
    <div class="video">
      <h2><%= link_to video.title, video_path(video) %></h2>
      <p><%= video.description.truncate(100) %></p>
      <%= link_to 'Edit', edit_video_path(video) if user_signed_in? %>
      <%= link_to 'Delete', video_path(video), method: :delete, data: { confirm: 'Are you sure?' } if user_signed_in? %>
    </div>
  <% end %>
</div>
EOF

  # Form partial for Videos
  cat <<EOF > app/views/videos/_form.html.erb
<%= form_with(model: video, local: true) do |form| %>
  <div>
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>
  <div>
    <%= form.label :description %>
    <%= form.text_area :description %>
  </div>
  <div>
    <%= form.submit 'Save' %>
  </div>
<% end %>
EOF
}

seed_database() {
  log "Seeding database for $app_name"
  create_seed_data
  bin/rails db:create db:migrate db:seed || error_exit "Failed to seed the database"
}

main() {
  log "Starting $app_name setup"
  initialize_app
  log "$app_name setup finished"
}

main "$@"

