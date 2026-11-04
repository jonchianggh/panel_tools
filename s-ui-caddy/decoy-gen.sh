#!/bin/bash
# Write a one-off decoy site into $1 (default ./decoy-gen): a random name,
# colour and layout, so no two deployments serve the same page.
set -euo pipefail
OUT="${1:-./decoy-gen}"
mkdir -p "$OUT"

ago() { date -d "@$(( $(date +%s) - (RANDOM % $1 + $2) * 86400 ))" '+%d %B %Y' 2>/dev/null || date +%Y; }
pick() { local a=("$@"); echo "${a[RANDOM % ${#a[@]}]}"; }

A=(Amber Alder Birch Bramble Cedar Cinder Cobalt Copper Driftwood Elm Ember Fern
   Flint Granite Harbor Hazel Heron Indigo Juniper Kestrel Lark Linden Maple Marble
   Meadow Moss Oak Onyx Orchid Pebble Pine Quarry Raven Rowan Saffron Slate Sparrow
   Spruce Thistle Tidal Umber Willow Wren Yarrow)
B=(Labs Works Studio Digital Systems Collective Partners Analytics Cloud Logistics
   Supply Media Design Software Group Ventures Data Health Foundry Robotics)
C=(Bay Brook Field Ford Gate Hill Line Point Ridge Stone Vale Wood)

case $((RANDOM % 3)) in
  0) NAME="$(pick "${A[@]}") $(pick "${B[@]}")" ;;
  1) NAME="$(pick "${A[@]}")$(pick "${C[@]}" | tr 'A-Z' 'a-z')" ;;
  *) NAME="$(pick "${A[@]}") & $(pick "${A[@]}")" ;;
esac
PLAIN="$NAME"
NAME="$(printf %s "$NAME" | sed 's/&/\&amp;/g')"
HUE=$((RANDOM % 360))
ACC="hsl($HUE 60% 42%)"
SOFT="hsl($HUE 50% 96%)"
FONT="$(pick "-apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif" \
             "Georgia, 'Times New Roman', serif" \
             "'Inter', system-ui, sans-serif" \
             "ui-rounded, 'SF Pro Rounded', system-ui, sans-serif")"
YEAR="$(date +%Y)"
FOUNDED=$((YEAR - 1 - RANDOM % 12))
CITY="$(pick Leeds Bristol Lyon Porto Utrecht Ghent Aarhus Graz Bologna Tampere Kraków Osaka Fukuoka Adelaide Halifax Portland Boise)"

css() {
cat <<CSS
:root { color-scheme: light; --acc: $ACC; --soft: $SOFT; }
* { box-sizing: border-box; }
body { font-family: $FONT; margin: 0; color: #1f2933; line-height: 1.6; background: #fff; }
.wrap { max-width: $(pick 40 44 48 52)rem; margin: 0 auto; padding: $(pick 3 4 5)rem 1.25rem; }
a { color: var(--acc); }
h1 { font-size: $(pick 1.6 1.8 2.1 2.4)rem; line-height: 1.2; margin: 0 0 .5rem; }
.muted { color: #6b7280; }
footer { margin-top: 3rem; font-size: .85rem; color: #6b7280; }
CSS
}

page_status() {
  local items=() n s
  for s in "$(pick API Gateway 'Public API')" "$(pick Dashboard 'Web app' Console)" \
           "$(pick 'Background jobs' Workers Scheduler)" "$(pick 'Object storage' 'File uploads' CDN)" \
           "$(pick Webhooks Notifications Email Search)"; do items+=("$s"); done
  n=$((3 + RANDOM % 3))
  cat <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$NAME Status</title><style>$(css)
.ok { color: #16a34a; font-weight: 600; }
ul { list-style: none; padding: 0; } li { display: flex; justify-content: space-between; border-bottom: 1px solid #e5e7eb; padding: .65rem 0; }
.banner { background: var(--soft); border-left: 4px solid var(--acc); padding: .8rem 1rem; border-radius: 6px; }
</style></head><body><div class="wrap">
<h1>$NAME</h1><p class="banner">All systems operational.</p><ul>
$(for s in "${items[@]:0:$n}"; do echo "<li><span>$s</span><span class=\"ok\">Operational</span></li>"; done)
</ul><p class="muted">Uptime over the past $(pick 30 60 90) days: $(pick 99.98 99.99 99.95 100.00)%.</p>
<footer>&copy; $YEAR $NAME</footer></div></body></html>
HTML
}

page_landing() {
  cat <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$NAME</title><style>$(css)
.hero { background: var(--soft); border-radius: 14px; padding: 2.5rem 2rem; }
.btn { display: inline-block; background: var(--acc); color: #fff; padding: .6rem 1.1rem; border-radius: 8px; text-decoration: none; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(12rem, 1fr)); gap: 1.25rem; margin-top: 2rem; }
</style></head><body><div class="wrap">
<div class="hero"><h1>$(pick "Something new is on the way." "We're building quietly." "Coming $(pick spring summer autumn winter) $YEAR." "A better way to $(pick "plan your week" "track shipments" "share files" "book rooms" "run your shop").")</h1>
<p class="muted">$NAME is a small team based in $CITY. $(pick "We're in private beta." "Early access is invite-only for now." "Sign-ups open soon.")</p>
<a class="btn" href="mailto:hello@example.com">$(pick "Get in touch" "Request access" "Join the waitlist")</a></div>
<div class="grid">
<div><h3>$(pick Simple Fast Private Reliable)</h3><p class="muted">$(pick "No setup, no clutter." "Built for small teams." "Your data stays yours." "Works on any device.")</p></div>
<div><h3>$(pick Open Friendly Honest Focused)</h3><p class="muted">$(pick "Clear pricing when we launch." "We answer every email." "Made with care since $FOUNDED.")</p></div>
</div><footer>&copy; $YEAR $NAME &middot; $CITY</footer></div></body></html>
HTML
}

page_blog() {
  local t1 t2 t3
  t1="$(pick "Notes on moving to a smaller flat" "What I learned from a year of running" "A slow weekend in $CITY" "Fixing an old bicycle" "Sourdough, attempt twelve")"
  t2="$(pick "Books I finished this season" "On keeping a paper notebook" "Rainy-day photo walk" "Why I stopped using so many apps")"
  t3="$(pick "Hello again" "Back to writing" "A short update" "Small changes")"
  cat <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$NAME — notes</title><style>$(css)
article { border-bottom: 1px solid #eee; padding: 1.2rem 0; } h2 { font-size: 1.15rem; margin: 0; }
</style></head><body><div class="wrap">
<h1>$NAME</h1><p class="muted">$(pick "Occasional writing." "A personal notebook." "Notes and small projects.")</p>
<article><h2><a href="#">$t1</a></h2><p class="muted">$(ago 40 3)</p></article>
<article><h2><a href="#">$t2</a></h2><p class="muted">$(ago 90 45)</p></article>
<article><h2><a href="#">$t3</a></h2><p class="muted">$(ago 200 140)</p></article>
<footer>&copy; $YEAR</footer></div></body></html>
HTML
}

page_maint() {
  cat <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$NAME</title><style>$(css)
.box { margin-top: 18vh; text-align: center; } .dot { display: inline-block; width: .7rem; height: .7rem; border-radius: 50%; background: var(--acc); margin-right: .4rem; }
</style></head><body><div class="wrap box">
<h1><span class="dot"></span>$NAME</h1>
<p class="muted">$(pick "This site is undergoing scheduled maintenance." "We're upgrading our systems and will be back shortly." "The client portal is temporarily unavailable.")</p>
<p class="muted">$(pick "Existing customers can reach support by email." "Thanks for your patience." "Please check back later today.")</p>
<footer>&copy; $FOUNDED–$YEAR $NAME</footer></div></body></html>
HTML
}

case $((RANDOM % 4)) in
  0) page_status ;; 1) page_landing ;; 2) page_blog ;; *) page_maint ;;
esac >"$OUT/index.html"
printf 'User-agent: *\nDisallow:\n' >"$OUT/robots.txt"
echo "$PLAIN" >"$OUT/.name"
