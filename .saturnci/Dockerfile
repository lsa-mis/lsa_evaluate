FROM ruby:3.3.4

WORKDIR /code

RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock /code/
RUN bundle install

COPY . .

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
