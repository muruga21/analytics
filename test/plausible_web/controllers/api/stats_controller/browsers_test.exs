defmodule PlausibleWeb.Api.StatsController.BrowsersTest do
  use PlausibleWeb.ConnCase

  describe "GET /api/stats/:domain/browsers" do
    setup [:create_user, :log_in, :create_new_site, :create_site_import]

    test "returns top browsers by unique visitors", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, browser: "Chrome"),
        build(:pageview, browser: "Chrome"),
        build(:pageview, browser: "Firefox")
      ])

      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Chrome", "visitors" => 2, "percentage" => 66.7},
               %{"name" => "Firefox", "visitors" => 1, "percentage" => 33.3}
             ]
    end

    test "returns top browsers with :is filter on custom pageview props", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          user_id: 123,
          browser: "Chrome"
        ),
        build(:pageview,
          user_id: 123,
          browser: "Chrome",
          "meta.key": ["author"],
          "meta.value": ["John Doe"]
        ),
        build(:pageview,
          browser: "Firefox",
          "meta.key": ["author"],
          "meta.value": ["other"]
        ),
        build(:pageview,
          browser: "Safari"
        )
      ])

      filters = Jason.encode!(%{props: %{"author" => "John Doe"}})
      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day&filters=#{filters}")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Chrome", "visitors" => 1, "percentage" => 100}
             ]
    end

    test "returns top browsers with :is_not filter on custom pageview props", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          user_id: 123,
          browser: "Chrome",
          "meta.key": ["author"],
          "meta.value": ["John Doe"]
        ),
        build(:pageview,
          user_id: 123,
          browser: "Chrome",
          "meta.key": ["author"],
          "meta.value": ["John Doe"]
        ),
        build(:pageview,
          browser: "Firefox",
          "meta.key": ["author"],
          "meta.value": ["other"]
        ),
        build(:pageview,
          browser: "Safari"
        )
      ])

      filters = Jason.encode!(%{props: %{"author" => "!John Doe"}})
      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day&filters=#{filters}")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Firefox", "visitors" => 1, "percentage" => 50},
               %{"name" => "Safari", "visitors" => 1, "percentage" => 50}
             ]
    end

    test "calculates conversion_rate when filtering for goal", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, user_id: 1, browser: "Chrome"),
        build(:pageview, user_id: 2, browser: "Chrome"),
        build(:event, user_id: 1, name: "Signup")
      ])

      filters = Jason.encode!(%{"goal" => "Signup"})

      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day&filters=#{filters}")

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "Chrome",
                 "total_visitors" => 2,
                 "visitors" => 1,
                 "conversion_rate" => 50.0
               }
             ]
    end

    test "returns top browsers including imported data", %{
      conn: conn,
      site: site,
      site_import: site_import
    } do
      populate_stats(site, site_import.id, [
        build(:pageview, browser: "Chrome"),
        build(:imported_browsers, browser: "Chrome"),
        build(:imported_browsers, browser: "Firefox"),
        build(:imported_visitors, visitors: 2)
      ])

      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Chrome", "visitors" => 1, "percentage" => 100}
             ]

      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day&with_imported=true")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Chrome", "visitors" => 2, "percentage" => 66.7},
               %{"name" => "Firefox", "visitors" => 1, "percentage" => 33.3}
             ]
    end

    test "skips breakdown when visitors=0 (possibly due to 'Enable Users Metric' in GA)", %{
      conn: conn,
      site: site,
      site_import: site_import
    } do
      populate_stats(site, site_import.id, [
        build(:imported_browsers, browser: "Chrome", visitors: 0, visits: 14),
        build(:imported_browsers, browser: "Firefox", visitors: 0, visits: 14),
        build(:imported_browsers,
          browser: "''",
          visitors: 0,
          visits: 14,
          visit_duration: 0,
          bounces: 14
        )
      ])

      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day&with_imported=true")

      assert json_response(conn, 200)["results"] == []
    end

    test "returns (not set) when appropriate", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          user_id: 123,
          browser: ""
        )
      ])

      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "(not set)", "visitors" => 1, "percentage" => 100.0}
             ]
    end

    test "select empty imported_browsers as (not set), merging with the native (not set)", %{
      conn: conn,
      site: site,
      site_import: site_import
    } do
      populate_stats(site, site_import.id, [
        build(:pageview, user_id: 123),
        build(:imported_browsers, visitors: 1),
        build(:imported_visitors, visitors: 1)
      ])

      conn = get(conn, "/api/stats/#{site.domain}/browsers?period=day&with_imported=true")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "(not set)", "visitors" => 2, "percentage" => 100.0}
             ]
    end
  end

  describe "GET /api/stats/:domain/browser-versions" do
    setup [:create_user, :log_in, :create_new_site, :create_legacy_site_import]

    test "returns correct conversion_rate when browser_version clashes across browsers", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:event, browser: "Chrome", browser_version: "110", name: "Signup"),
        build(:event, browser: "Chrome", browser_version: "110", name: "Signup"),
        build(:pageview, browser: "Chrome", browser_version: "110"),
        build(:pageview, browser: "Chrome", browser_version: "121"),
        build(:pageview, browser: "Chrome", browser_version: "121"),
        build(:event, browser: "Firefox", browser_version: "121", name: "Signup"),
        build(:pageview, browser: "Firefox", browser_version: "110"),
        build(:pageview, browser: "Firefox", browser_version: "110"),
        build(:pageview, browser: "Firefox", browser_version: "110"),
        build(:pageview, browser: "Firefox", browser_version: "110")
      ])

      insert(:goal, site: site, event_name: "Signup")
      filters = Jason.encode!(%{goal: "Signup"})

      json_response =
        get(
          conn,
          "/api/stats/#{site.domain}/browser-versions?period=day&filters=#{filters}"
        )
        |> json_response(200)
        |> Map.get("results")

      assert %{
               "browser" => "Chrome",
               "conversion_rate" => 66.7,
               "name" => "110",
               "total_visitors" => 3,
               "visitors" => 2
             } == List.first(json_response)

      assert %{
               "browser" => "Firefox",
               "conversion_rate" => 100.0,
               "name" => "121",
               "total_visitors" => 1,
               "visitors" => 1
             } == List.last(json_response)
    end

    test "returns top browser versions by unique visitors", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, browser: "Chrome", browser_version: "78.0"),
        build(:pageview, browser: "Chrome", browser_version: "78.0"),
        build(:pageview, browser: "Chrome", browser_version: "77.0"),
        build(:pageview, browser: "Firefox", browser_version: "88.0")
      ])

      filters = Jason.encode!(%{browser: "Chrome"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/browser-versions?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{"name" => "78.0", "visitors" => 2, "percentage" => 66.7, "browser" => "Chrome"},
               %{"name" => "77.0", "visitors" => 1, "percentage" => 33.3, "browser" => "Chrome"}
             ]
    end

    test "returns results for (not set)", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, browser: "", browser_version: "")
      ])

      filters = Jason.encode!(%{browser: "(not set)"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/browser-versions?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "(not set)",
                 "visitors" => 1,
                 "percentage" => 100,
                 "browser" => "(not set)"
               }
             ]
    end

    test "with imported data", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          browser: "Chrome",
          browser_version: "121",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          browser: "Chrome",
          browser_version: "110",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:imported_browsers,
          date: ~D[2021-01-01],
          browser: "Chrome",
          browser_version: "121",
          visitors: 5
        ),
        build(:imported_browsers,
          date: ~D[2021-01-01],
          browser: "Firefox",
          browser_version: "121",
          visitors: 3
        ),
        build(:imported_browsers, date: ~D[2021-01-01], visitors: 10),
        build(:imported_visitors, date: ~D[2021-01-01], visitors: 18)
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/browser-versions?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "browser" => "(not set)",
                 "name" => "(not set)",
                 "visitors" => 10,
                 "percentage" => 50.0
               },
               %{"browser" => "Chrome", "name" => "121", "visitors" => 6, "percentage" => 30.0},
               %{"browser" => "Firefox", "name" => "121", "visitors" => 3, "percentage" => 15.0},
               %{"browser" => "Chrome", "name" => "110", "visitors" => 1, "percentage" => 5.0}
             ]
    end
  end
end
