FROM ruby:3.3.4

WORKDIR /code

RUN apt-get update && apt-get install -y \
  build-essential \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

COPY Gemfile Gemfile.lock /code/
RUN bundle install

COPY . /code

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
