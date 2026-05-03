Code.require_file("test/support/test_helpers.ex")

# Configure tzdata so per-context `:timezone` overrides (other than UTC) work.
# Erlang's `:calendar.local_time/0` reads the host TZ at boot, so to make the
# integration suite deterministic across machines, run with `TZ=UTC mix test`
# (or whatever zone you prefer -- the integration runner forwards the same
# `TZ` to the Ruby subprocess, so both engines stay in sync).
{:ok, _} = Application.ensure_all_started(:tzdata)
Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)

ExUnit.start()
