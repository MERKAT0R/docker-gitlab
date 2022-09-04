FROM ruby:alpine

LABEL maintainer="cyberviking@darkwolf.team aka @pavelwolfdark"

ENV GITLAB_CONFIG=/etc/gitlab

COPY ./license_key /
COPY ./license_key.pub /
COPY ./gitlab_license.rb /

RUN gem install gitlab-license

VOLUME $GITLAB_CONFIG

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["gitlab-license"]
