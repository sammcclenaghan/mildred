FROM ruby:3.3-slim

RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY run.rb ./
COPY src/ ./src/

ENTRYPOINT ["ruby", "run.rb"]
