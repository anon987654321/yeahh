# OpenBSD: Rails Apps Hosting with Multi-Domain Support

OpenBSD is renowned for its simplicity and security. This repository provides an automated setup for hosting Ruby on Rails applications (Falcon) on multiple domains using native OpenBSD tools.

## Overview

This repository contains a setup script that configures:

- **pf(8):** Secure, stateful packet filtering.
- **NSD(8) with DNSSEC:** Automatic generation of DNS zone files for multiple domains with proper SOA, NS, A, MX, and CAA records.  
  - NS records are set to `ns.brgen.no.` (NS1) and `ns.hyp.net.` (NS2) for all domains.
  - For the `brgen.no` zone, an extra A record for `ns.brgen.no.` is added.
- **relayd(8):** A reverse proxy configuration that supports ACME challenge handling and forwards traffic to your Falcon (Rails) server running on a unique port.
- **ACME and HTTPD(8):** Configuration for serving ACME challenges and redirecting HTTP to HTTPS.
- **Dynamic Rails (Falcon) Startup Scripts:** Automatically generated rc.d scripts to launch your Falcon (Rails) applications with security enhancements using OpenBSD’s `pledge(2)` and `unveil(2)`.

## Requirements

- OpenBSD 6.x or newer
- Domains properly pointed to your server’s IP address
- NSD delegation (glue records for nameservers)
- zsh (the script uses zsh-specific syntax)
- doas for privilege escalation

## Conclusion

This production-ready setup follows OpenBSD best practices and is designed for ease of maintenance. For troubleshooting, consult `/var/log/openbsd_setup.log`.

Happy Hosting!

