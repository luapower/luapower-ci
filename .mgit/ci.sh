# CI servers controller script

die() { echo "$@" >&2; exit 1; }

conf=".mgit/ci_servers.conf"
[ -f "$conf" ] || die "$conf not found."
servers="$(cat "$conf")"

each_server() {
	echo "$servers" | while read server luajit; do
		if [ "$server" ]; then
			printf "%-14s %-10s : " "$server" "$luajit"
			$@
		fi
	done
}

os="$(mgit platform -o)"
plat="$(mgit platform)"

ci_ssh() {
	if [ "$server" == local ]; then
		bash -s
	else
		(echo "cd luapower 2>/dev/null || cd /x/luapower 2>/dev/null || exit 1; "
		cat) | ssh -o ConnectTimeout=4 "$server" 'bash --login -s'
	fi
}

status_one() { echo "$luajit luapower_cli.lua platform" | ci_ssh; }
status() { each_server status_one; }

update_db_one() {
	echo "$luajit luapower_cli.lua update-db $@ && \
		echo '$@ ok' || echo '$@ failed'" | ci_ssh
}
update-db() { each_server update_db_one "$@"; }

upload-db() {
	scp luapower_db.lua cosmin@luapower.com:/home/cosmin/luapower/
	curl -k https://luapower.com/clear_cache
}

help() { echo; cat .mgit/luapower-ci.help | sed 's/ ci /mgit ci '; }

cmd="$1"
shift
[ "$cmd" ] || die "Usage: mgit ci status | update-db [PACKAGE] | upload-db | help"
$cmd "$@"
