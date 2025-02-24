#!/bin/env zsh
set -e

# bsdports.sh - BSD Ports Management Platform

APP_NAME="bsdports"
BASE_DIR="$HOME/dev/rails_apps"

source "$BASE_DIR/__shared.sh"

initialize_app() {
  initialize_setup "$APP_NAME"
  create_rails_app "$APP_NAME"
  install_common_gems
  setup_devise
  setup_frontend
  generate_social_models
  setup_routes
  generate_scss "$APP_NAME"  # This generates a default SCSS; we'll override with BSDPorts styles next.
  log "$APP_NAME setup completed"
}

setup_routes() {
  log "Configuring routes for $APP_NAME"
  cat <<EOF > config/routes.rb
Rails.application.routes.draw do
  root 'ports#index'
  devise_for :users
  resources :ports do
    resources :port_dependencies
  end
end
EOF
}

# Write BSDPorts-specific SCSS (refined and streamlined) to a file
write_bsdports_scss() {
  log "Writing BSDPorts-specific SCSS"
  cat <<'EOF' > app/assets/stylesheets/bsdports.scss
:root {
  --white: #ffffff;
  --black: #000000;
  --blue: #000084;
  --light-blue: #5623ee;
  --extra-light-grey: #f0f0f0;
  --light-grey: #ababab;
  --grey: #999999;
  --dark-grey: #666666;
  --warning-red: #b04243;
}

.dark_mode_link {
  --white: #000000;
  --black: #ffffff;
  --blue: #5623ee;
  --light-blue: #000084;
  --extra-light-grey: #666666;
  --light-grey: #999999;
  --grey: #ababab;
  --dark-grey: #f0f0f0;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  height: 100%;
}

body {
  font-family: sans-serif;
  font-size: 14px;
  color: var(--black);
  background-color: var(--white);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

a {
  color: var(--light-blue);
  text-decoration: underline;
}

header {
  display: flex;
  justify-content: flex-end;
  .tabs {
    display: flex;
    margin-top: 18px;
    color: var(--light-grey);
    border-bottom: 1px solid var(--extra-light-grey);
    p {
      padding: 0 3px 8px;
      margin-right: 28px;
    }
    p.active {
      color: var(--black);
      border-bottom: 1px solid var(--black);
    }
  }
}

main {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: -20px 0 20px;
  .logo {
    text-indent: -9999px;
    margin: 12px 0 22px;
  }
  .logo, .logo:before {
    width: 182px;
    height: 44px;
  }
  .logo:before {
    content: "";
    position: absolute;
    background-image: url("bsdports_182x44.svg");
    background-repeat: no-repeat;
    display: block;
  }
}

#search {
  width: 90%;
  max-width: 584px;
  border: 1px solid var(--extra-light-grey);
  border-radius: 30px;
  font-size: 18px;
  transition: all 100ms ease-in-out;
  background-color: var(--white);
  input {
    background: transparent;
    border: none;
    width: 100%;
    padding: 16px 20px 15px;
    font-size: 16px;
    outline: none;
    ::placeholder {
      color: var(--dark-grey);
    }
  }
  #live_results {
    overflow: hidden;
    max-height: 220px;
    padding: 9px 19px;
    font-weight: bold;
    line-height: 29px;
    border-top: 1px solid var(--extra-light-grey);
    a {
      display: block;
    }
  }
}

.browse_link {
  margin: 44px 0 12px;
  font-size: 13px;
}

footer {
  color: var(--light-grey);
  font-size: 13px;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
  .references {
    display: flex;
    gap: 2.6rem;
    align-items: center;
    margin-bottom: 72px;
    a {
      text-indent: -99999px;
      opacity: 0.2;
      position: relative;
      display: block;
    }
    a:last-child {
      opacity: 0.3;
    }
    a:before {
      content: "";
      position: absolute;
      background-repeat: no-repeat;
      display: block;
    }
    .ror, .ror:before { width: 72px; height: 24px; }
    .ror:before { background-image: url("logo_ror_72x24.svg"); background-position: 0 -4px; }
    .puma, .puma:before { width: 108px; height: 25px; }
    .puma:before { background-image: url("logo_puma_108x25.svg"); background-position: 0 2px; }
    .nuug, .nuug:before { width: 79px; height: 27px; }
    .nuug:before { background-image: url("logo_nuug_79x27.svg"); }
    .bergen, .bergen:before { width: 81px; height: 36px; }
    .bergen:before { background-image: url("logo_bergen_kommune_86x36.svg"); }
  }
  .copyright,
  .dark_mode_link,
  .light_mode_link {
    position: absolute;
    bottom: 10px;
  }
  .copyright {
    left: 10px;
  }
  .dark_mode_link,
  .light_mode_link {
    right: 10px;
    opacity: 0.7;
  }
  .dark_mode_link:before {
    background-image: url("moon_16x16.svg");
    width: 16px;
    height: 16px;
  }
  .light_mode_link:before {
    background-image: url("sun_20x20.svg");
    width: 20px;
    height: 20px;
  }
}

@media screen and (min-width: 320px) and (max-width: 480px) {
  footer * {
    transform: scale(0.8);
  }
  footer .references {
    gap: 1.6rem;
  }
  footer .copyright {
    left: 0;
    bottom: 6px;
  }
}
EOF
  log "BSDPorts-specific SCSS written to app/assets/stylesheets/bsdports.scss"
}

# MAIN EXECUTION
log "Starting $APP_NAME setup"
initialize_app

# Write BSDPorts-specific styles
write_bsdports_scss

# Run the BSD Ports import seed
bin/rails db:seed || error_exit "Database seeding failed for BSD Ports"

commit_to_git "Imported BSD Ports data via db/seed.rb and applied BSDPorts-specific styling."

log "$APP_NAME setup finished"

