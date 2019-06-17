# frozen_string_literal: true

module Nominare
  class << self
    def url
      ENV['NOMINARE_URL'] || 'https://nominare.cogitare.nz'
    end

    def request(path, opts = {})
      opts[:accept_encoding] = 'gzip'
      JSON.parse Typhoeus::Request.new((url + path), opts).run.body
    end

    def random(n = 1)
      request('/random', params: { n: n })
    end

    def search(q)
      request('/search', params: { q: q })
    end

    def details(name)
      request('/details', params: { name: name })
    end

    def stats
      request('/stats')
    end
  end
end
