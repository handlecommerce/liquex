FROM elixir:1.14

ENV LIQUID_VERSION 5.5.0

# Install ruby. Since we are only using this to install Liquid,
# we don't really care which version
RUN apt-get update \
  && apt-get install -y ruby

RUN mix local.rebar --force \
  && mix local.hex --force

RUN gem install --no-document --version ${LIQUID_VERSION} liquid
WORKDIR /workspaces/liquex
