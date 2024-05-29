defmodule PlausibleWeb.Api.StatsController.SourcesTest do
  use PlausibleWeb.ConnCase

  @user_id 123

  describe "GET /api/stats/:domain/sources" do
    setup [:create_user, :log_in, :create_new_site, :create_legacy_site_import]

    test "returns top sources by unique user ids", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        ),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com"
        ),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com"
        ),
        build(:pageview)
      ])

      conn = get(conn, "/api/stats/#{site.domain}/sources")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 3},
               %{"name" => "DuckDuckGo", "visitors" => 2},
               %{"name" => "Direct / None", "visitors" => 1}
             ]
    end

    test "returns top sources with :is filter on custom pageview props", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          user_id: 123,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          "meta.key": ["author"],
          "meta.value": ["John Doe"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:01:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["author"],
          "meta.value": ["John Doe"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["author"],
          "meta.value": ["John Doe"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Facebook",
          referrer: "facebook.com",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      filters = Jason.encode!(%{props: %{"author" => "John Doe"}})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 2},
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]
    end

    test "returns top sources with :is_not filter on custom pageview props", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          "meta.key": ["author"],
          "meta.value": ["John Doe"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          "meta.key": ["author"],
          "meta.value": ["other"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:01:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["author"],
          "meta.value": ["other"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Facebook",
          referrer: "facebook.com",
          "meta.key": ["author"],
          "meta.value": ["John Doe"],
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      filters = Jason.encode!(%{props: %{"author" => "!John Doe"}})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 2},
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]
    end

    test "returns top sources with :is (none) filter on custom pageview props", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          "meta.key": ["author"],
          "meta.value": ["John Doe"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: 123,
          timestamp: ~N[2021-01-01 00:01:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["author"],
          "meta.value": ["other"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Facebook",
          referrer: "facebook.com",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Facebook",
          referrer: "facebook.com",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      filters = Jason.encode!(%{props: %{"author" => "(none)"}})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Facebook", "visitors" => 2},
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]
    end

    test "returns top sources with :is_not (none) filter on custom pageview props", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          "meta.key": ["logged_in"],
          "meta.value": ["true"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          "meta.key": ["author"],
          "meta.value": ["other"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:01:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["author"],
          "meta.value": ["other"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["author"],
          "meta.value": ["another"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Facebook",
          referrer: "facebook.com",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      filters = Jason.encode!(%{props: %{"author" => "!(none)"}})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 2},
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]
    end

    test "returns top sources with imported data", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, referrer_source: "Google", referrer: "google.com"),
        build(:pageview, referrer_source: "Google", referrer: "google.com"),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com"
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          source: "Google",
          visitors: 2
        ),
        build(:imported_sources,
          source: "DuckDuckGo",
          visitors: 1
        )
      ])

      conn = get(conn, "/api/stats/#{site.domain}/sources")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 2},
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]

      conn = get(conn, "/api/stats/#{site.domain}/sources?with_imported=true")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 4},
               %{"name" => "DuckDuckGo", "visitors" => 2}
             ]
    end

    test "calculates bounce rate and visit duration for sources", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&detailed=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "DuckDuckGo",
                 "visitors" => 1,
                 "bounce_rate" => 100,
                 "visit_duration" => 0
               },
               %{
                 "name" => "Google",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]
    end

    test "calculates bounce rate and visit duration for sources with imported data", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          source: "Google",
          date: ~D[2021-01-01],
          visitors: 2,
          visits: 3,
          bounces: 1,
          visit_duration: 900
        ),
        build(:imported_sources,
          source: "DuckDuckGo",
          date: ~D[2021-01-01],
          visitors: 1,
          visits: 1,
          visit_duration: 100,
          bounces: 0
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&detailed=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "DuckDuckGo",
                 "visitors" => 1,
                 "bounce_rate" => 100,
                 "visit_duration" => 0
               },
               %{
                 "name" => "Google",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&detailed=true&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "Google",
                 "visitors" => 3,
                 "bounce_rate" => 25,
                 "visit_duration" => 450.0
               },
               %{
                 "name" => "DuckDuckGo",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 50
               }
             ]
    end

    test "returns top sources in realtime report", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          timestamp: relative_time(minutes: -3)
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com",
          timestamp: relative_time(minutes: -2)
        ),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          timestamp: relative_time(minutes: -1)
        )
      ])

      conn = get(conn, "/api/stats/#{site.domain}/sources?period=realtime")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 2},
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]
    end

    test "can paginate the results", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        ),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com"
        ),
        build(:imported_sources,
          source: "DuckDuckGo"
        )
      ])

      conn = get(conn, "/api/stats/#{site.domain}/sources?limit=1&page=2")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]

      conn = get(conn, "/api/stats/#{site.domain}/sources?limit=1&page=2&with_imported=true")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "DuckDuckGo", "visitors" => 2}
             ]
    end

    test "shows sources for a page", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, pathname: "/page1", referrer_source: "Google"),
        build(:pageview, pathname: "/page1", referrer_source: "Google"),
        build(:pageview,
          user_id: 1,
          pathname: "/page2",
          referrer_source: "DuckDuckGo"
        ),
        build(:pageview,
          user_id: 1,
          pathname: "/page1",
          referrer_source: "DuckDuckGo"
        )
      ])

      filters = Jason.encode!(%{"page" => "/page1"})
      conn = get(conn, "/api/stats/#{site.domain}/sources?filters=#{filters}")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "Google", "visitors" => 2},
               %{"name" => "DuckDuckGo", "visitors" => 1}
             ]
    end
  end

  describe "UTM parameters with hostname filter" do
    setup [:create_user, :log_in, :create_new_site]

    for {resource, attr} <- [
          utm_campaigns: :utm_campaign,
          utm_sources: :utm_source,
          utm_terms: :utm_term,
          utm_contents: :utm_content
        ] do
      test "returns #{resource} when filtered by hostname", %{conn: conn, site: site} do
        populate_stats(site, [
          # session starts at two.example.com with utm_param=ad
          build(
            :pageview,
            [
              {unquote(attr), "ad"},
              {:user_id, @user_id},
              {:hostname, "two.example.com"},
              {:timestamp, ~N[2021-01-01 00:00:00]}
            ]
          ),
          # session continues on one.example.com without any utm_params
          build(
            :pageview,
            [
              {:user_id, @user_id},
              {:hostname, "one.example.com"},
              {:timestamp, ~N[2021-01-01 00:15:00]}
            ]
          )
        ])

        filters = Jason.encode!(%{hostname: "one.example.com"})

        conn =
          get(
            conn,
            "/api/stats/#{site.domain}/#{unquote(resource)}?period=day&date=2021-01-01&filters=#{filters}"
          )

        # nobody landed on one.example.com from utm_param=ad
        assert json_response(conn, 200)["results"] == []
      end
    end
  end

  describe "GET /api/stats/:domain/utm_mediums" do
    setup [:create_user, :log_in, :create_new_site, :create_legacy_site_import]

    test "returns top utm_mediums by unique user ids", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_medium: "social",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_medium: "social",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_medium: "email",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_medium: "social",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_medium: "email",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 100
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_mediums?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "social",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               },
               %{
                 "name" => "email",
                 "visitors" => 1,
                 "bounce_rate" => 100,
                 "visit_duration" => 0
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_mediums?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "social",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               },
               %{
                 "name" => "email",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 50
               }
             ]
    end

    test "filters out entries without utm_medium present", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_medium: "social",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_medium: "social",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_medium: "",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_medium: "social",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_medium: "",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 100
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_mediums?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "social",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_mediums?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "social",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               }
             ]
    end
  end

  describe "GET /api/stats/:domain/utm_campaigns" do
    setup [:create_user, :log_in, :create_new_site, :create_legacy_site_import]

    test "returns top utm_campaigns by unique user ids", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_campaign: "profile",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_campaign: "profile",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_campaign: "august",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_campaign: "august",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_campaign: "profile",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_campaign: "august",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 900
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_campaigns?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "august",
                 "visitors" => 2,
                 "bounce_rate" => 100,
                 "visit_duration" => 0
               },
               %{
                 "name" => "profile",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_campaigns?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "august",
                 "visitors" => 3,
                 "bounce_rate" => 67,
                 "visit_duration" => 300
               },
               %{
                 "name" => "profile",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               }
             ]
    end

    test "filters out entries without utm_campaign present", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_campaign: "profile",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_campaign: "profile",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_campaign: "",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_campaign: "",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_campaign: "profile",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_campaign: "",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 900
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_campaigns?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "profile",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_campaigns?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "profile",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               }
             ]
    end
  end

  describe "GET /api/stats/:domain/utm_sources" do
    setup [:create_user, :log_in, :create_new_site, :create_legacy_site_import]

    test "returns top utm_sources by unique user ids", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_source: "Twitter",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_source: "Twitter",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_source: "newsletter",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_source: "newsletter",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_sources?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "newsletter",
                 "visitors" => 2,
                 "bounce_rate" => 100,
                 "visit_duration" => 0
               },
               %{
                 "name" => "Twitter",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]
    end
  end

  describe "GET /api/stats/:domain/utm_terms" do
    setup [:create_user, :log_in, :create_new_site, :create_legacy_site_import]

    test "returns top utm_terms by unique user ids", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_term: "oat milk",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_term: "oat milk",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_term: "Sweden",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_term: "Sweden",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_term: "oat milk",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_term: "Sweden",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 900
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_terms?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "Sweden",
                 "visitors" => 2,
                 "bounce_rate" => 100,
                 "visit_duration" => 0
               },
               %{
                 "name" => "oat milk",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_terms?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "Sweden",
                 "visitors" => 3,
                 "bounce_rate" => 67,
                 "visit_duration" => 300
               },
               %{
                 "name" => "oat milk",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               }
             ]
    end

    test "filters out entries without utm_term present", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_term: "oat milk",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_term: "oat milk",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_term: "",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_term: "",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_term: "oat milk",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_term: "",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 900
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_terms?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "oat milk",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_terms?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "oat milk",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               }
             ]
    end
  end

  describe "GET /api/stats/:domain/utm_contents" do
    setup [:create_user, :log_in, :create_new_site, :create_legacy_site_import]

    test "returns top utm_contents by unique user ids", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_content: "ad",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_content: "ad",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_content: "blog",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_content: "blog",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_content: "ad",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_content: "blog",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 900
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_contents?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "blog",
                 "visitors" => 2,
                 "bounce_rate" => 100,
                 "visit_duration" => 0
               },
               %{
                 "name" => "ad",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_contents?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "blog",
                 "visitors" => 3,
                 "bounce_rate" => 67,
                 "visit_duration" => 300
               },
               %{
                 "name" => "ad",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               }
             ]
    end

    test "filters out entries without utm_content present", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          utm_content: "ad",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_content: "ad",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          utm_content: "",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          utm_content: "",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      populate_stats(site, [
        build(:imported_sources,
          utm_content: "ad",
          date: ~D[2021-01-01],
          visit_duration: 700,
          bounces: 1,
          visits: 1,
          visitors: 1
        ),
        build(:imported_sources,
          utm_content: "",
          date: ~D[2021-01-01],
          bounces: 0,
          visits: 1,
          visitors: 1,
          visit_duration: 900
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_contents?period=day&date=2021-01-01"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "ad",
                 "visitors" => 1,
                 "bounce_rate" => 0,
                 "visit_duration" => 900
               }
             ]

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/utm_contents?period=day&date=2021-01-01&with_imported=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "ad",
                 "visitors" => 2,
                 "bounce_rate" => 50,
                 "visit_duration" => 800.0
               }
             ]
    end
  end

  describe "GET /api/stats/:domain/sources - with goal filter" do
    setup [:create_user, :log_in, :create_new_site]

    test "returns top referrers for a custom goal including conversion_rate", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "Twitter",
          user_id: @user_id
        ),
        build(:event,
          name: "Signup",
          user_id: @user_id
        ),
        build(:pageview,
          referrer_source: "Twitter"
        )
      ])

      # Imported data is ignored when filtering
      populate_stats(site, [
        build(:imported_sources, source: "Twitter")
      ])

      filters = Jason.encode!(%{goal: "Signup"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "Twitter",
                 "total_visitors" => 2,
                 "visitors" => 1,
                 "conversion_rate" => 50.0
               }
             ]
    end

    test "returns no top referrers for a custom goal and filtered by hostname",
         %{
           conn: conn,
           site: site
         } do
      populate_stats(site, [
        build(:pageview,
          hostname: "blog.example.com",
          referrer_source: "Facebook",
          user_id: @user_id
        ),
        build(:pageview,
          hostname: "app.example.com",
          pathname: "/register",
          user_id: @user_id
        ),
        build(:event,
          name: "Signup",
          hostname: "app.example.com",
          pathname: "/register",
          user_id: @user_id
        )
      ])

      filters = Jason.encode!(%{goal: "Signup", hostname: "app.example.com"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == []
    end

    test "returns top referrers for a custom goal and filtered by hostname (2)",
         %{
           conn: conn,
           site: site
         } do
      populate_stats(site, [
        build(:pageview,
          hostname: "app.example.com",
          referrer_source: "Facebook",
          pathname: "/register",
          user_id: @user_id
        ),
        build(:event,
          name: "Signup",
          hostname: "app.example.com",
          pathname: "/register",
          user_id: @user_id
        )
      ])

      filters = Jason.encode!(%{goal: "Signup", hostname: "app.example.com"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "conversion_rate" => 100.0,
                 "name" => "Facebook",
                 "total_visitors" => 1,
                 "visitors" => 1
               }
             ]
    end

    test "returns top referrers with goal filter + :is prop filter", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          user_id: 123,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:event,
          name: "Download",
          "meta.key": ["method", "logged_in"],
          "meta.value": ["HTTP", "true"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:01:00]
        ),
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          "meta.key": ["logged_in"],
          "meta.value": ["true"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:event,
          referrer_source: "Facebook",
          referrer: "facebook.com",
          name: "Download",
          "meta.key": ["method", "logged_in"],
          "meta.value": ["HTTP", "false"],
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      filters = Jason.encode!(%{goal: "Download", props: %{"logged_in" => "true"}})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "DuckDuckGo",
                 "visitors" => 1,
                 "conversion_rate" => 50.0,
                 "total_visitors" => 2
               }
             ]
    end

    test "returns top referrers with goal filter + prop :is_not filter", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com",
          user_id: 123,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:event,
          name: "Download",
          "meta.key": ["method"],
          "meta.value": ["HTTP"],
          user_id: 123,
          timestamp: ~N[2021-01-01 00:01:00]
        ),
        build(:event,
          name: "Download",
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["method", "logged_in"],
          "meta.value": ["HTTP", "true"],
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:event,
          name: "Download",
          referrer_source: "Google",
          referrer: "google.com",
          "meta.key": ["method", "logged_in"],
          "meta.value": ["HTTP", "false"],
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      filters = Jason.encode!(%{goal: "Download", props: %{"logged_in" => "!true"}})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&date=2021-01-01&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "DuckDuckGo",
                 "visitors" => 1,
                 "conversion_rate" => 100.0,
                 "total_visitors" => 1
               },
               %{
                 "name" => "Google",
                 "visitors" => 1,
                 "conversion_rate" => 50.0,
                 "total_visitors" => 2
               }
             ]
    end

    test "returns top referrers for a pageview goal including conversion_rate", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "Twitter",
          user_id: @user_id
        ),
        build(:pageview,
          pathname: "/register",
          user_id: @user_id
        ),
        build(:pageview,
          referrer_source: "Twitter"
        )
      ])

      filters = Jason.encode!(%{goal: "Visit /register"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/sources?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "Twitter",
                 "total_visitors" => 2,
                 "visitors" => 1,
                 "conversion_rate" => 50.0
               }
             ]
    end
  end

  describe "GET /api/stats/:domain/referrer-drilldown" do
    setup [:create_user, :log_in, :create_new_site]

    test "returns top referrers for a particular source", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com"
        ),
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com"
        ),
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com/page1"
        ),
        build(:pageview,
          referrer_source: "ignored",
          referrer: "ignored"
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/referrers/10words?period=day"
        )

      assert json_response(conn, 200)["results"] == [
               %{"name" => "10words.com", "visitors" => 2},
               %{"name" => "10words.com/page1", "visitors" => 1}
             ]
    end

    test "returns top referrers for a particular source filtered by hostname", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "example",
          referrer: "example.com",
          hostname: "two.example.com"
        ),
        build(:pageview,
          referrer_source: "example",
          referrer: "example.com",
          hostname: "two.example.com",
          user_id: @user_id
        ),
        build(:pageview,
          hostname: "one.example.com",
          user_id: @user_id
        ),
        build(:pageview,
          referrer_source: "example",
          referrer: "example.com/page1",
          hostname: "one.example.com"
        ),
        build(:pageview,
          referrer_source: "ignored",
          referrer: "ignored",
          hostname: "two.example.com"
        )
      ])

      filters = Jason.encode!(%{hostname: "one.example.com"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/referrers/example?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{"name" => "example.com/page1", "visitors" => 1}
             ]
    end

    test "calculates bounce rate and visit duration for referrer urls", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com",
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com",
          timestamp: ~N[2021-01-01 00:15:00]
        ),
        build(:pageview,
          referrer_source: "ignored",
          referrer: "ignored",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/referrers/10words?period=day&date=2021-01-01&detailed=true"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "10words.com",
                 "visitors" => 2,
                 "bounce_rate" => 50.0,
                 "visit_duration" => 450
               }
             ]
    end

    test "gets keywords from Google", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com"
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        )
      ])

      conn = get(conn, "/api/stats/#{site.domain}/referrers/Google?period=day")
      {:ok, terms} = Plausible.Google.API.Mock.fetch_stats(nil, nil, nil)

      assert json_response(conn, 200) == %{"search_terms" => terms}
    end

    test "works when filter expression is provided for source", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "DuckDuckGo",
          referrer: "duckduckgo.com"
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        ),
        build(:pageview,
          referrer_source: "Google",
          referrer: "google.com"
        )
      ])

      conn = get(conn, "/api/stats/#{site.domain}/referrers/!Google?period=day")

      assert json_response(conn, 200)["results"] == [
               %{"name" => "duckduckgo.com", "visitors" => 1}
             ]

      conn = get(conn, "/api/stats/#{site.domain}/referrers/Google|DuckDuckGo?period=day")

      assert [entry1, entry2] = json_response(conn, 200)["results"]
      assert %{"name" => "google.com", "visitors" => 2} in [entry1, entry2]
      assert %{"name" => "duckduckgo.com", "visitors" => 1} in [entry1, entry2]
    end

    test "returns top referring urls for a custom goal", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com"
        ),
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com",
          user_id: @user_id
        ),
        build(:event,
          name: "Signup",
          user_id: @user_id
        ),
        build(:event,
          name: "Signup"
        )
      ])

      filters = Jason.encode!(%{goal: "Signup"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/referrers/10words?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "10words.com",
                 "total_visitors" => 2,
                 "conversion_rate" => 50.0,
                 "visitors" => 1
               }
             ]
    end

    test "returns top referring urls for a pageview goal", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com"
        ),
        build(:pageview,
          referrer_source: "10words",
          referrer: "10words.com",
          user_id: @user_id
        ),
        build(:pageview,
          pathname: "/register",
          user_id: @user_id
        ),
        build(:pageview,
          pathname: "/register"
        )
      ])

      filters = Jason.encode!(%{goal: "Visit /register"})

      conn =
        get(
          conn,
          "/api/stats/#{site.domain}/referrers/10words?period=day&filters=#{filters}"
        )

      assert json_response(conn, 200)["results"] == [
               %{
                 "name" => "10words.com",
                 "total_visitors" => 2,
                 "conversion_rate" => 50.0,
                 "visitors" => 1
               }
             ]
    end
  end
end
