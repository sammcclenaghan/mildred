FROM ruby:3.3-slim

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY run.rb ./
COPY src/ ./src/

ENTRYPOINT ["ruby", "run.rb"]
