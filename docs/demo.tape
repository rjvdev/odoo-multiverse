# Demo GIF for the README, recorded with charmbracelet/vhs:
#   vhs docs/demo.tape        (run from the repository root, Odoo 16 image already pulled)
# It uses a throwaway Compose project (odoomv-demo), reset before and removed after the
# recording, so it never touches your own odoo16 database. Port 8016 must be free.

Output docs/demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 1300
Set Height 620
Set Padding 16
Set Framerate 10
Set TypingSpeed 45ms
Set Theme "Catppuccin Mocha"

Hide
Type "export COMPOSE_PROJECT_NAME=odoomv-demo PATH=$PWD:$PATH PS1='$ '" Enter
Type "docker compose --profile '*' down -v >/dev/null 2>&1" Enter
Sleep 5s
Type "clear" Enter
Show

Type "odoomv up 16"
Sleep 400ms
Enter
Wait+Screen /Odoo 16: http/
Sleep 1.5s

Type "odoomv init 16 2>&1 | tail -n 3"
Sleep 400ms
Enter
Wait+Screen@3m /database odoo16 ready/
Sleep 2s

Type "odoomv test 16 lab_selftest 2>&1 | tail -n 5"
Sleep 400ms
Enter
Wait+Screen@5m /full log:/
Sleep 3s

Type "clear" Enter
Type "odoomv status"
Sleep 400ms
Enter
Wait+Screen /Ports:/
Sleep 5s

Hide
Type "docker compose --profile '*' down -v >/dev/null 2>&1" Enter
Sleep 10s
