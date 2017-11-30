#!/usr/bin/env ruby

require_relative '../vendor/bundler/setup'

require "graphql"
require "graphql/client/http"
require "graphql/client"

GITHUB_USERNAME = 'rclaassens'

class GithubPlugin

  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(_context)
      { "Authorization" => "bearer <access-token>" }
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
        nodes {
          createdAt
          number
          title
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
  GRAPHQL

  def initialize(username)
    @username = username
    @output = nil
  end

  def query
    Client.query Query
  end

  def execute
    data = query.data
    count_review_requests = data.organization.repositories.nodes.map(&:pull_requests).flat_map(&:edges).map(&:node).flat_map(&:review_requests).flat_map(&:nodes).map(&:reviewer).map(&:login).count{ |login| login == 'rclaassens' }
    puts "Review requests: #{count_review_requests}"
    puts "Open PRs: #{data.user.pull_requests.total_count}"
  end
end

plugin = GithubPlugin.new(GITHUB_USERNAME)
plugin.execute
