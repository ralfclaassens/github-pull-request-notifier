#!/usr/bin/env ruby

require_relative '../vendor/bundler/setup'

require "graphql"
require "graphql/client/http"
require "graphql/client"

class GithubPlugin

  GITHUB_USERNAME = 'rclaassens'
  PERSONAL_ACCESS_TOKEN = '<access-token>'

  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(_context)
      { "Authorization" => "bearer #{PERSONAL_ACCESS_TOKEN}" }
    end
  end

  Schema = GraphQL::Client.load_schema(HTTP)

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  Query = Client.parse <<-'GRAPHQL'
  {
    organization(login: "cgservices") {
      repositories(first: 100) {
        nodes {
          pullRequests(first: 50, states: OPEN) {
            edges {
              node {
                id,
                reviewRequests(first: 10) {
                  nodes {
                    reviewer {
                      login
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    user(login: "rclaassens") {
      pullRequests(first: 100, states: OPEN) {
        totalCount
      }
    }
  }
  GRAPHQL

  def execute
    data = Client.query(Query).data
    count_review_requests = data.organization.repositories.nodes.map(&:pull_requests).flat_map(&:edges).map(&:node).flat_map(&:review_requests).flat_map(&:nodes).map(&:reviewer).map(&:login).count{ |login| login == "#{GITHUB_USERNAME}" }
    puts "Review requests: #{count_review_requests}"
    puts "Open PRs: #{data.user.pull_requests.total_count}"
  end
end

GithubPlugin.new.execute
