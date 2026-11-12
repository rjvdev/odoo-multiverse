# Demo GIF for the README, recorded with charmbracelet/vhs from the repository root:
#   vhs docs/demo.tape
# Recorded with zsh + Starship (vhs starts zsh without rc files, so the prompt is
# initialised in the hidden part) and JetBrainsMono Nerd Font; any shell works if you adapt
# Set Shell, Set FontFamily and Set WaitPattern (it waits for the prompt character).
# Requirements: the odoo:19.0 image already pulled and port 8019 free.
# It runs in a throwaway Compose project (odoomv-demo), reset at the start, so it never
# touches an existing odoo19 database. The odoo19 database is created off camera and waits
# are cut; Starship's duration segment still shows how long each command really took.

Output docs/demo.gif

Set Shell "zsh"
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 20
Set Width 1200
Set Height 520
Set Padding 20
Set Framerate 12
Set TypingSpeed 25ms
Set Theme "TokyoNight"
Set WaitPattern /❯\s*$/

# --- hidden preparation: odoo19 database with demo data, a module from "another project" ---
Hide
Type "export COMPOSE_PROJECT_NAME=odoomv-demo" Enter
Type `eval "$(starship init zsh)"` Enter
Type `docker compose --profile '*' down -v >/dev/null 2>&1; echo RESET_''DONE` Enter
Wait+Screen@2m /RESET_DONE/
Type "clear" Enter
Type `./odoomv up 19 >/dev/null 2>&1 && ./odoomv init 19 >/dev/null 2>&1 && ./odoomv down >/dev/null 2>&1; echo PREP_''DONE $?` Enter
Wait+Screen@10m /PREP_DONE \d+/
Type "clear" Enter
Type `rm -rf /tmp/acme-project && mkdir -p /tmp/acme-project && cp -r addons/19/lab_selftest /tmp/acme-project/acme_sale_extras; echo MOD_''DONE` Enter
Wait+Screen /MOD_DONE/
Type "clear" Enter
Sleep 500ms
Show

# 1. start Postgres + Odoo 19
Type "./odoomv up 19"
Enter
Hide
Wait@2m
Show
Sleep 1.5s

Hide
Type `until ./odoomv status 2>/dev/null | grep -q 'odoo19.*(healthy)'; do sleep 2; done; clear` Enter
Wait@3m
Show

# 2. status
Type "./odoomv status"
Enter
Wait+Screen /Ports:/
Sleep 2.5s

Hide
Type "clear" Enter
Sleep 300ms
Show

# 3. bring in a module from another project
Type "./odoomv link 19 /tmp/acme-project/acme_sale_extras"
Enter
Wait
Sleep 2s

Hide
Type "clear" Enter
Sleep 300ms
Show

# 4. a simple query on the demo data
Type `echo "select name, city from res_partner where is_company order by name limit 5;" | ./odoomv psql 19 2>/dev/null`
Enter
Wait+Screen /\(5 rows\)/
Sleep 2.5s

Hide
Type "clear" Enter
Sleep 300ms
Show

# 5. remove the linked copy (the source project is untouched)
Type "./odoomv unlink 19 acme_sale_extras"
Enter
Wait
Sleep 1.5s

# 6. stop the lab (volumes are kept)
Type "./odoomv down"
Enter
Hide
Wait@1m
Show
Sleep 2s

# --- hidden cleanup ---
Hide
Type "rm -rf /tmp/acme-project" Enter
Wait
