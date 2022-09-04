FROM gitlab/gitlab-ee

LABEL maintainer="cyberviking@darkwolf.team aka @pavelwolfdark"

# Replacing the GitLab license verification public key with our own
COPY ./gitlab-license/license_key.pub /opt/gitlab/embedded/service/gitlab-rails/.license_encryption_key.pub
