# File: __shared.sh
#!/usr/bin/env zsh
set -e

# __shared.sh: Shared setup functions for Ruby on Rails 8 apps.
#
# This file contains all common logic used by multiple apps:
# • Logging and error handling
# • Directory initialization, Yarn installation, and Rails creation
# • Installation of common gems (Devise, StimulusReflex, Merit, etc.)
# • Setup for Active Storage, Tiptap editor, Stripe, and Mapbox
# • Generation of social models:
#     - Post: includes title, content, likes_count, shares_count, star_rating, and user association
#     - Reaction: supports polymorphic social actions with an emoji field for gemoticons
#     - Merit integration for reputation, badges, and points
# • Generation of Reflexes for infinite scroll and live search (using Post model)
# • Minimal SCSS generation and seed data injection using Faker

# Logging & Error Handling
log() {
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

error_exit() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
  exit 1
}

commit_to_git() {
  git add -A
  git commit -m "$1"
  log "Git commit: $1"
}

# Directory Setup
initialize_setup() {
  local app_name="$1"
  log "Initializing setup for $app_name"
  mkdir -p "$app_name" && cd "$app_name" || error_exit "Failed to navigate to application directory for $app_name"
  log "Setup directory for $app_name created."
}

# Yarn & Rails Creation
setup_yarn() {
  if ! command -v yarn &>/dev/null; then
    doas npm install yarn -g || error_exit "Yarn installation failed"
  fi
  log "Yarn is installed."
}

create_rails_app() {
  local app_name="$1"
  log "Creating Rails app: $app_name"
  gem install --user-install bundler rails railties || error_exit "Gem install failed"
  rails new . --database=sqlite3 --assets=propshaft --javascript=esbuild --skip-test || error_exit "Rails creation failed"
  log "Rails app $app_name created."
}

# Common Gems & Devise Setup
install_common_gems() {
  log "Installing common gems: Devise, StimulusReflex, etc."
  bundle add devise redis pg stimulus_reflex friendly_id acts_as_votable pundit name_of_person noticed ahoy_matey pg_search pagy || error_exit "Common gems installation failed"
}

setup_devise() {
  log "Setting up Devise for authentication"
  bin/rails generate devise:install || error_exit "Devise install failed"
  bin/rails generate devise User || error_exit "Devise user model generation failed"
}

# Merit Setup (for reputation and badges)
setup_merit() {
  log "Installing Merit gem for reputation and badges"
  bundle add merit || error_exit "Merit gem installation failed"
  bin/rails generate merit:install || error_exit "Merit installation generator failed"
  log "Merit is installed and configured."
}

# StimulusReflex & Frontend Packages
setup_frontend() {
  log "Installing StimulusReflex and frontend packages"
  bin/rails stimulus_reflex:install || error_exit "StimulusReflex installation failed"
  yarn add \
    @stimulus-components/stimulus-carousel \
    @stimulus-components/auto-submit \
    @stimulus-components/character-counter \
    @stimulus-components/textarea-autogrow \
    @stimulus-components/file-preview \
    @stimulus-components/lightbox \
    lightgallery \
    packery \
    || error_exit "Frontend package installation failed"
}

# Active Storage Setup
setup_active_storage() {
  log "Installing Active Storage for file uploads"
  bin/rails active_storage:install || error_exit "Active Storage installation failed"
}

# Social Models Generation (with Merit integration and gemoticons)
generate_social_models() {
  log "Generating social models: Post and Reaction with Merit support"
  bin/rails generate model Post title:string content:text likes_count:integer shares_count:integer star_rating:float user:references || error_exit "Post model creation failed"
  bin/rails generate model Reaction reaction_type:string emoji:string user:references reactable:references{polymorphic} || error_exit "Reaction model creation failed"
  log "Social models generated. (Remember to integrate Merit in your Post model if desired.)"
}

# Stripe Setup
setup_stripe() {
  log "Installing Stripe gem for payment processing"
  bundle add stripe || error_exit "Stripe gem installation failed"
  cat <<EOF > config/initializers/stripe.rb
Stripe.api_key = ENV["STRIPE_API_KEY"]
EOF
  log "Stripe initializer created."
}

# Tiptap Editor Setup (Medium-style editor)
setup_mediumstyle_editor() {
  log "Installing Tiptap-based Medium-style editor"
  yarn add \
    @tiptap/core \
    @tiptap/starter-kit \
    @tiptap/extension-link \
    @tiptap/extension-placeholder \
    @tiptap/extension-underline \
    @tiptap/extension-bold \
    @tiptap/extension-italic \
    || error_exit "Tiptap editor installation failed"
}

# Mapbox Setup
setup_mapbox() {
  log "Installing mapbox-gl for cluster-based maps"
  yarn add mapbox-gl || error_exit "mapbox-gl installation failed"
}

# Minimal SCSS Generation
setup_common_scss() {
  log "Setting up minimal SCSS (base styles)"
  if [ ! -f app/assets/stylesheets/application.scss ]; then
    cat <<EOF > app/assets/stylesheets/application.scss
/* Minimal SCSS Reset & Base Style */
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #fff; color: #000; font-family: sans-serif; }
EOF
    log "application.scss created."
  else
    log "application.scss already exists, skipping."
  fi
}

# Infinite Scroll Reflex Setup (using Post model)
setup_infinite_scroll() {
  log "Generating InfiniteScrollReflex"
  bin/rails generate reflex InfiniteScrollReflex || error_exit "InfiniteScrollReflex generation failed"
  cat <<'EOF' > app/reflexes/infinite_scroll_reflex.rb
class InfiniteScrollReflex < ApplicationReflex
  def load_more
    page = element.dataset["next_page"].to_i
    @pagy, @posts = pagy(Post.order(created_at: :desc), page: page)
    cable_ready["#posts-container"].insert_adjacent_html(
      selector: "#sentinel",
      html: ApplicationController.render(
        partial: "posts/post", collection: @posts, as: :post
      ),
      position: "beforebegin"
    ).broadcast
  end
end
EOF
}

# Live Search Reflex Setup (using Post model)
setup_live_search() {
  log "Generating LiveSearchReflex"
  bin/rails generate reflex LiveSearchReflex || error_exit "LiveSearchReflex generation failed"
  cat <<'EOF' > app/reflexes/live_search_reflex.rb
class LiveSearchReflex < ApplicationReflex
  def search(query = "")
    @results = Post.where("title ILIKE ? OR content ILIKE ?", "%#{query}%", "%#{query}%")
    morph "#search-results", ApplicationController.render(
      partial: "posts/search_results", locals: { posts: @results }
    )
  end
end
EOF
}

# Seed Data Injection using Faker
setup_social_seed_data() {
  log "Seeding basic data using Faker"
  mkdir -p db/seeds
  cat <<'EOF' > db/seeds/extra_seeds.rb
require 'faker'
Post.create!(
  title: Faker::Lorem.sentence(word_count: 3),
  content: Faker::Lorem.paragraph(sentence_count: 2),
  likes_count: 0,
  shares_count: 0,
  star_rating: 0.0,
  user_id: 1
)
EOF
  cat db/seeds/extra_seeds.rb >> db/seeds.rb
  log "Seed data appended to db/seeds.rb"
}

# End of __shared.sh

# File: amber.sh
#!/bin/zsh
set -e

# amber.sh - Sets up "Amber", an AI-enhanced social network for fashion.
# Features: wardrobe management, style assistance, a Medium-like rich text editor,
# infinite scroll, live search, Stripe integration, and social interactions.

APP_NAME="amber"
BASE_DIR="$HOME/dev/rails_apps"

source "$BASE_DIR/__shared.sh"

log "Starting Amber setup (AI-based fashion network)"

initialize_setup "$APP_NAME"
setup_yarn
create_rails_app "$APP_NAME"

cd "$APP_NAME"

install_common_gems
setup_devise
setup_frontend
setup_active_storage
generate_social_models
setup_stripe
setup_mediumstyle_editor
setup_mapbox
setup_common_scss
setup_infinite_scroll
setup_live_search

bin/rails db:migrate

log "Generating WardrobeItem model for clothing management"
bin/rails generate model WardrobeItem name:string color:string size:string description:text user:references || error_exit "WardrobeItem model creation failed"
bin/rails db:migrate

setup_social_seed_data "$APP_NAME"

commit_to_git "Amber is fully set up (AI-enhanced fashion network)."
echo "Amber setup complete. Run 'bin/rails server' to start local development."

# End of amber.sh

# File: amber_README.md
cat <<'EOF'
# Amber

Amber is an AI-enhanced social network for fashion. It helps users organize their wardrobes, receive style suggestions, mix & match outfits, and stay updated with the latest trends.

## Features

- **Wardrobe Management**: Upload and manage clothing items.
- **Style Assistant (AI)**: Get daily outfit recommendations.
- **Mix & Match**: Experiment with outfit combinations.
- **Fashion Feed**: Stay updated on trends.
- **Stripe Integration**: Process payments and purchases.
- **Real-Time Interaction**: Infinite scroll and live search powered by StimulusReflex.
- **Rich Text Editing**: Enjoy a Medium-like Tiptap editor for composing posts.
- **Social Interactions**: Posts support likes, shares, and star ratings; reactions (with gemoticons) are tracked.
- **Reputation System**: Integrated with Merit for badges and points.

## Setup

1. Run `./amber.sh`
2. Change directory: `cd amber && bin/rails db:setup`
3. Start the server: `bin/rails server`
4. Visit `http://localhost:3000`

## Future Plans

- Virtual fitting room
- Mood-based outfit recommendations
- Detailed AI-powered style analytics

Enjoy building your AI-powered fashion community with Amber!
EOF

# End of amber_README.md

# File: brgen.sh
#!/bin/zsh
set -e

# brgen.sh - Sets up "Brgen", a hyper-local social network spanning multiple cities.
# Features include multi-tenancy (via acts_as_tenant), infinite scroll, live search,
# real-time interactions, and social engagement.
#
# Each city runs on its own subdomain with tenant isolation.

APP_NAME="brgen"
BASE_DIR="$HOME/dev/rails_apps"

source "$BASE_DIR/__shared.sh"

log "Starting Brgen setup (multi-city social network)"

initialize_setup "$APP_NAME"
setup_yarn
create_rails_app "$APP_NAME"

cd "$APP_NAME"

install_common_gems
setup_devise
setup_frontend
setup_active_storage
generate_social_models
setup_stripe
setup_mediumstyle_editor
setup_mapbox
setup_common_scss
setup_infinite_scroll
setup_live_search

# Add multi-tenancy support using acts_as_tenant
log "Adding acts_as_tenant for multi-tenancy"
bundle add acts_as_tenant

bin/rails db:migrate

log "Generating City model for tenant management"
bin/rails generate model City name:string subdomain:string country:string city:string language:string favicon:string block_foreign_ips:boolean analytics:string || error_exit "City model creation failed"
bin/rails db:migrate

setup_social_seed_data "$APP_NAME"

commit_to_git "Brgen multi-city social network setup complete."
echo "Brgen setup complete. Run 'bin/rails server' to start local development."

# End of brgen.sh

# File: brgen_README.md
cat <<'EOF'
# Brgen

Brgen is a hyper-local social network built for multiple cities. Each city runs on its own subdomain using acts_as_tenant, ensuring that every local community enjoys a tailored experience while sharing a common database infrastructure.

## Key Features

- **Multi-Tenancy**: Each city subdomain is isolated using acts_as_tenant.
- **Real-Time Interactions**: Infinite scroll and live search powered by StimulusReflex.
- **Local Discovery**: Explore posts, events, and content unique to your city.
- **Mapbox Integration**: View local feeds with cluster-based maps.
- **Stripe Integration**: Process payments or subscriptions.
- **Rich Text Editing**: Compose posts with a modern Tiptap editor.
- **Social Interactions**: Posts include likes, shares, and star ratings; reactions (with gemoticons) are tracked.
- **Reputation System**: Merit integration for badges and points.

## Database & Models

- **City Model**: Contains fields such as `name`, `subdomain`, `country`, `city`, `language`, `favicon`, `block_foreign_ips`, and `analytics`.

## Setup

1. Run `./brgen.sh`
2. Change directory: `cd brgen && bin/rails db:setup`
3. Start the server: `bin/rails server`
4. Visit your local subdomain (e.g., `oshlo.localhost:3000`)

## Future Ideas

- Local event aggregators
- Enhanced multi-lingual support and custom branding per site
- Integration with local business APIs

Brgen merges city-level insights with robust, real-time social networking.
EOF

# End of brgen_README.md

# File: app/javascript/controllers/infinite_scroll_controller.js
cat <<'EOF'
import { Controller } from "stimulus";
import { useIntersection } from "stimulus-use";

export default class extends Controller {
  static targets = ["sentinel"];

  connect() {
    useIntersection(this, { element: this.sentinelTarget });
  }

  appear() {
    // Disable the sentinel and show a spinner icon
    this.sentinelTarget.disabled = true;
    this.sentinelTarget.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    this.stimulate("InfiniteScrollReflex#load_more");
  }
}
EOF

# End of infinite_scroll_controller.js

# File: app/javascript/controllers/live_search_controller.js
cat <<'EOF'
import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["input"];

  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.stimulate("LiveSearchReflex#search", this.inputTarget.value);
    }, 200);
  }

  reset(event) {
    event.preventDefault();
    this.inputTarget.value = "";
    this.stimulate("LiveSearchReflex#search", "");
  }
}
EOF

# End of live_search_controller.js

