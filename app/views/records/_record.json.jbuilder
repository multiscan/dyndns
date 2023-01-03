json.extract! record, :id, :name, :ip, :created_at, :updated_at
json.url record_url(record, format: :json)
