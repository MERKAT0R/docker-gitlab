# Author: cyberviking@darkwolf.team aka @pavelwolfdark

require 'getoptlong'
require 'date'
require 'uri'

opts = GetoptLong.new(
  ['--help', GetoptLong::NO_ARGUMENT],
  ['--name', GetoptLong::REQUIRED_ARGUMENT],
  ['--company', GetoptLong::REQUIRED_ARGUMENT],
  ['--email', GetoptLong::REQUIRED_ARGUMENT],
  ['--plan', GetoptLong::OPTIONAL_ARGUMENT],
  ['--active-user-count', GetoptLong::OPTIONAL_ARGUMENT],
  ['--starts-at', GetoptLong::OPTIONAL_ARGUMENT],
  ['--expires-at', GetoptLong::OPTIONAL_ARGUMENT],
  ['--export', GetoptLong::OPTIONAL_ARGUMENT]
)

PREMIUM_PLAN = 'premium'
ULTIMATE_PLAN = 'ultimate'

MAX_ACTIVE_USER_COUNT = 10000

DEFAULT_PLAN = ULTIMATE_PLAN
DEFAULT_ACTIVE_USER_COUNT = MAX_ACTIVE_USER_COUNT
DEFAULT_START_DATE = Date.today
DEFAULT_EXPIRATION_DATE = Date.new(9999, 12, 31)

name = nil
company = nil
email = nil
plan = ULTIMATE_PLAN
active_user_count = DEFAULT_ACTIVE_USER_COUNT
starts_at = DEFAULT_START_DATE
expires_at = DEFAULT_EXPIRATION_DATE
export = false
filename = nil

opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
GitLab license.

Usage:
  gitlab_license.rb [options]
  gitlab_license.rb --name <name> --company <company> --email <email>

Options:
  --help                         Show this screen.
  --name=<name>                  Licensee name.
  --company=<company>            Licensee company.
  --email=<email>                Licensee email.
  --plan=[premium|ultimate]      License plan [default: ultimate].
  --active-user-count=[<count>]  License active user count [default: 10000].
  --starts-at=[<date>]           License start date in format YYYY-MM-DD. If not set, the current date will be used.
  --expires-at=[<date>]          License expiration date in format YYYY-MM-DD [default: 9999-12-31].
  --export=[<file>]              Export license key to file. If not set, it will be exported to stdout.
      EOF
      exit 0
    when '--name'
      name = arg
    when '--company'
      company = arg
    when '--email'
      unless arg =~ URI::MailTo::EMAIL_REGEXP
        puts 'Invalid licensee email.'
        exit 2
      end

      email = arg
    when '--plan'
      if arg == ''
        plan = DEFAULT_PLAN
      else
        unless arg == PREMIUM_PLAN || arg == ULTIMATE_PLAN
          puts 'Invalid license plan.'
          exit 2
        end

        plan = arg
      end
    when '--active-user-count'
      if arg == ''
        active_user_count = DEFAULT_ACTIVE_USER_COUNT
      else
        count = arg.to_i

        unless count < 1 || count > MAX_ACTIVE_USER_COUNT
          puts 'Invalid license active user count.'
          exit 2
        end

        active_user_count = count
      end
    when '--starts-at'
      if arg == ''
        starts_at = DEFAULT_START_DATE
      else
        begin
          date = Date.parse(arg)
        rescue ArgumentError
          puts 'Invalid license start date.'
          exit 2
        end

        starts_at = date
      end
    when '--expires-at'
      if arg == ''
        expires_at = nil
      else
        begin
          date = Date.parse(arg)
        rescue ArgumentError
          puts 'Invalid license expiration date.'
          exit 2
        end

        expires_at = date
      end
    when '--export'
      export = true
      filename = arg == '' || arg == '-' ? nil : arg
  end
end

unless expires_at > starts_at
  puts 'Invalid license expiration date.'
  exit 2
end

require 'openssl'
require 'gitlab/license'

private_key = OpenSSL::PKey::RSA.new File.read('license_key')

Gitlab::License.encryption_key = private_key

license = Gitlab::License.new
license.licensee = {
  Name: name,
  Company: company,
  Email: email
}
license.starts_at = starts_at
license.expires_at = expires_at
license.restrictions = {
  plan: plan,
  active_user_count: active_user_count
}
license.cloud_licensing_enabled = true
license.offline_cloud_licensing_enabled = true

license_key = license.export

if export
  if filename
    File.write("/etc/gitlab/#{filename}", license_key)
  else
    puts license_key
  end
else
  puts <<-EOF
License:
  Name: #{name}
  Company: #{company}
  Email: #{email}
  Plan: #{plan.capitalize}
  Active User Count: #{active_user_count}
  Start Date: #{starts_at}
  Expiration Date: #{expires_at}

License Key:
#{license_key}
  EOF
end
