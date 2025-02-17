#!/usr/bin/env zsh
set -euo pipefail

# --- Root Privilege Check ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# --- Global Settings ---
main_ip="46.23.95.45"
ext_if="vio0"
unique_port_min=40000
unique_port_max=49999

# --- Domain and App Mappings ---
typeset -A all_domains
all_domains=(
  "brgen.no"       "markedsplass,playlist,dating,tv,takeaway,maps"
  "oshlo.no"       "markedsplass,playlist,dating,tv,takeaway,maps"
  "trndheim.no"    "markedsplass,playlist,dating,tv,takeaway,maps"
  "stvanger.no"    "markedsplass,playlist,dating,tv,takeaway,maps"
  "trmso.no"       "markedsplass,playlist,dating,tv,takeaway,maps"
  "longyearbyn.no" "markedsplass,playlist,dating,tv,takeaway,maps"
  "reykjavk.is"    "markadur,playlist,dating,tv,takeaway,maps"
  "kobenhvn.dk"    "markedsplads,playlist,dating,tv,takeaway,maps"
  "stholm.se"      "marknadsplats,playlist,dating,tv,takeaway,maps"
  "gteborg.se"     "marknadsplats,playlist,dating,tv,takeaway,maps"
  "mlmoe.se"       "marknadsplats,playlist,dating,tv,takeaway,maps"
  "hlsinki.fi"     "markkinapaikka,playlist,dating,tv,takeaway,maps"
  "lndon.uk"       "marketplace,playlist,dating,tv,takeaway,maps"
  "mnchester.uk"   "marketplace,playlist,dating,tv,takeaway,maps"
  "brmingham.uk"   "marketplace,playlist,dating,tv,takeaway,maps"
  "edinbrgh.uk"    "marketplace,playlist,dating,tv,takeaway,maps"
  "glasgw.uk"      "marketplace,playlist,dating,tv,takeaway,maps"
  "lverpool.uk"    "marketplace,playlist,dating,tv,takeaway,maps"
  "amstrdam.nl"    "marktplaats,playlist,dating,tv,takeaway,maps"
  "rottrdam.nl"    "marktplaats,playlist,dating,tv,takeaway,maps"
  "utrcht.nl"      "marktplaats,playlist,dating,tv,takeaway,maps"
  "brssels.be"     "marche,playlist,dating,tv,takeaway,maps"
  "zrich.ch"       "marktplatz,playlist,dating,tv,takeaway,maps"
  "lchtenstein.li" "marktplatz,playlist,dating,tv,takeaway,maps"
  "frankfrt.de"    "marktplaats,playlist,dating,tv,takeaway,maps"
  "mrseille.fr"    "marche,playlist,dating,tv,takeaway,maps"
  "mlan.it"        "mercato,playlist,dating,tv,takeaway,maps"
  "lsbon.pt"       "mercado,playlist,dating,tv,takeaway,maps"
  "lsangeles.com"  "marketplace,playlist,dating,tv,takeaway,maps"
  "newyrk.us"      "marketplace,playlist,dating,tv,takeaway,maps"
  "chcago.us"      "marketplace,playlist,dating,tv,takeaway,maps"
  "dtroit.us"      "marketplace,playlist,dating,tv,takeaway,maps"
  "houstn.us"      "marketplace,playlist,dating,tv,takeaway,maps"
  "dllas.us"       "marketplace,playlist,dating,tv,takeaway,maps"
  "austn.us"       "marketplace,playlist,dating,tv,takeaway,maps"
  "prtland.com"    "marketplace,playlist,dating,tv,takeaway,maps"
  "mnneapolis.com" "marketplace,playlist,dating,tv,takeaway,maps"
  "pub.healthcare" ""
  "pub.attorney"   ""
  "bsdports.org"   ""
)

typeset -A all_apps
all_apps=(
  "brgen"    "brgen.no"
  "bsdports" "bsdports.org"
  "amber"    "amberapp.com"
)

# --- Unique Port Generation ---
typeset -a used_ports
used_ports=()

generate_unique_port() {
  while true; do
    port=$(( unique_port_min + RANDOM % (unique_port_max - unique_port_min + 1) ))
    if ! netstat -an | grep -q ":$port "; then
      used_ports+=( "$port" )
      echo "$port"
      return
    fi
  done
}

# --- NSD Configuration ---
setup_nsd() {
  cat > /etc/nsd/nsd.conf <<EOF
server:
    ip-address: "$main_ip"
    port: 53
    zonefile-directory: "/var/nsd/zones/master"
    username: _nsd
    logfile: "/var/log/nsd.log"
    verbosity: 1

zonelistfile: "/var/nsd/db/zone.list"
EOF

  for domain in "${(@k)all_domains}"; do
    local file="/var/nsd/zones/master/${domain}.zone"
    local subs=${all_domains[$domain]}
    serial=$(date +%Y%m%d)00

    cat <<EOF > "$file"
\$ORIGIN ${domain}.
\$TTL 86400
@ IN SOA ns.brgen.no. hostmaster.${domain//./@}. (
    ${serial} ; serial
    3600      ; refresh
    900       ; retry
    604800    ; expire
    180       ; minimum
)
@ IN NS ns.brgen.no.
@ IN NS ns.hyp.net.
@ IN A $main_ip
@ IN MX 10 mail.${domain}.
@ IN CAA 0 issuewild "letsencrypt.org"
EOF

    if [ -n "$subs" ]; then
      for sub in ${(s:,:)subs}; do
        echo "${sub} IN A $main_ip" >> "$file"
      done
    fi

    nsd-checkzone "$domain" "$file" || {
      echo "Zone file $domain failed syntax check, skipping."
      continue
    }

    ldns-keygen -a RSASHA256 -b 2048 -k "$domain"
    ldns-keygen -a RSASHA256 -b 1024 "$domain"
    
    keys=($(ls /var/nsd/zones/master/K${domain}*.private 2>/dev/null))
    if [ ${#keys[@]} -eq 0 ]; then
      echo "DNSSEC keys missing for $domain, skipping signing."
      continue
    fi

    chmod 600 /var/nsd/zones/master/K${domain}*.private
    chown _nsd:_nsd /var/nsd/zones/master/K${domain}*.private
    ldns-signzone -o "$domain" "$file" "${keys[@]}"
  done

  zap -f nsd
  rcctl enable nsd
  rcctl restart nsd || {
    echo "NSD restart failed, check logs." >&2
    exit 1
  }
}

# --- PF Configuration ---
setup_pf() {
  cat > /etc/pf.conf <<EOF
ext_if = "$ext_if"
set skip on lo
block in log all
pass out all keep state
pass in quick on \$ext_if proto tcp to port 22 keep state
pass in quick on \$ext_if proto { udp tcp } to port 53 keep state
pass in quick on \$ext_if proto tcp to port { 80, 443 } keep state
anchor "relayd/*"
anchor "sshguard/*"
EOF
  pfctl -f /etc/pf.conf
  pfctl -e || true
}

# --- ACME and HTTPD Setup ---
setup_letsencrypt() {
  cat > /etc/acme-client.conf <<EOF
authority letsencrypt {
  api url "https://acme-v02.api.letsencrypt.org/directory"
  account key "/etc/ssl/private/letsencrypt.key"
}
EOF
  for app in "${(@k)all_apps}"; do
    domain="${all_apps[${app}]}"
    cat >> /etc/acme-client.conf <<EOF

domain ${domain} {
  alternative names { www.${domain} }
  domain key "/etc/ssl/private/${domain}.key"
  domain full chain certificate "/etc/ssl/${domain}.crt"
  sign with letsencrypt
}
EOF
  done
  rcctl enable httpd
  rcctl restart httpd
}

# --- Rails App Setup ---
setup_apps() {
  for app in "${(@k)all_apps}"; do
    local port=$(generate_unique_port)
    app_ports["$app"]="$port"
    cat > "/etc/rc.d/${app}" <<EOF
#!/bin/ksh
daemon="/home/${app}/bin/rails server"
daemon_user="${app}"
daemon_flags="-p ${port} -e production"
pledge "stdio rpath wpath cpath inet unveil"
unveil "/home/${app}" r
unveil "/var/www/${app}/public" r
if [ -x "\$daemon" ]; then
  exec \$daemon \$daemon_flags
else
  echo "Warning: \$daemon not found, skipping startup." >&2
  exit 0
fi
EOF
    chmod +x "/etc/rc.d/${app}"
    rcctl enable "$app"
    rcctl start "$app"
  done
  rcctl enable relayd
  rcctl stop relayd
  rcctl start relayd
}

# --- Main Execution ---
pkg_add zsh ruby-3.3.5 ldns-utils postgresql-server redis sshguard zap
setup_pf
setup_nsd
setup_apps
setup_letsencrypt

