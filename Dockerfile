# syntax = docker/dockerfile:1
FROM docker.io/library/ruby:3.4.5

ARG RUBY_VERSION=3.4.5

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    EXECJS_RUNTIME="Node" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    RAILS_SERVE_STATIC_FILES="true" \
    DB_USER="/rails/.rbenv-vars" \
    DB_PASSWORD="/rails/.rbenv-vars" \
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="/rails/.rbenv-vars" \
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="/rails/.rbenv-vars" \
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="/rails/.rbenv-vars"

ENV TZ="UTC"
RUN echo "Etc/UTC" > /etc/timezone

# Install packages needed to build gems
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential git pkg-config

RUN apt-get install -y nodejs npm libpq-dev
RUN npm install --global yarn

# Install application gems
RUN gem update bundler -N
RUN gem update --system -N
RUN gem install execjs brakeman rubocop -N

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .
RUN rm -rf .git
RUN rm -f log/*.log
RUN rm -f .rbenv-vars

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

RUN echo "dummy-data" > .rbenv-vars

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN yarn install
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log tmp public/uploads

USER rails:rails
RUN mkdir -p tmp/pdf public/assets
RUN chmod -R 755 files log tmp public/assets

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/docker-entrypoint"]
