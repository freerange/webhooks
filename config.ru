require './app'
require './force_json_content_type_middleware'

use ForceJsonContentTypeMiddleware
run WebhooksApp.new(harmonia: Harmonia.new)
