require 'graphql/client'
require 'graphql/client/http'

module Dicere
  HTTP = GraphQL::Client::HTTP.new(ENV['DICERE_URL'] + '/graphql')
  Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  Random = Dicere::Client.parse <<-'RANDOM'
    query {
      random {
        id text
      }
    }
  RANDOM

  Search = Dicere::Client.parse <<-'SEARCH'
    query ($query: String!) {
      search(query: $query) {
        item { id text }
      }
    }
  SEARCH

  ItemById = Dicere::Client.parse <<-'ITEM'
    query ($id: ID!) {
      items(id: $id) {
        id text
      }
    }
  ITEM
  
  class << self
    def random
      its = Dicere::Client.query(Dicere::Random)
      Item.new(its.data.random.first.id, its.data.random.first.text)
    end

    def item(id)
      its = Dicere::Client.query(Dicere::ItemById, variables: { id: id })
      Item.new(its.data.items.first.id, its.data.items.first.text)
    end

    def search(query)
      its = Dicere::Client.query(Dicere::Search, variables: { query: query })
      its.data.search.map do |result|
        Item.new(result.item.id, result.item.text)
      end
    end
  end

  class Item
    def initialize(id, text)
      @id = id
      @text = text
    end

    def to_s
      "#{@id}: #{@text}"
    end

    def to_href
      "https://cogitare.nz/item/#{@id}"
    end
  end
end